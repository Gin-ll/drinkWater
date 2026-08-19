import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/app_database.dart';
import 'occurrence_calculator.dart';

/// 操作动作 ID 常量
const String actionDrink = 'drink';
const String actionMiss = 'miss';

/// 通知渠道 ID
const String reminderChannelId = 'drink_reminders';

/// 通知 payload（嵌入每条通知，按钮回调据此写库）
class NotificationPayload {
  final int reminderId;
  final String occurDate; // YYYY-MM-DD 本地日期
  final String dbPath;

  const NotificationPayload({
    required this.reminderId,
    required this.occurDate,
    required this.dbPath,
  });

  String toJson() =>
      jsonEncode({'reminderId': reminderId, 'occurDate': occurDate, 'dbPath': dbPath});

  static NotificationPayload? fromJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return NotificationPayload(
        reminderId: map['reminderId'] as int,
        occurDate: map['occurDate'] as String,
        dbPath: map['dbPath'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}

/// 单个提醒的 ID 基数空间（reminderId * 10000 + offset）
const int idBase = 10000;

/// 调度核心：注册/撤销系统精确闹钟、处理通知按钮回调。
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// 测试环境跳过真实调度（测试中无平台通道）。
  static bool skipScheduling = false;

  /// 系统设置跳转通道（Android 原生实现，见 MainActivity）
  static final MethodChannel systemChannel = MethodChannel('ginll/drink_water/system');

  /// App 启动时设置：用户点击通知主体时回调（用于跳转首页）
  static void Function(NotificationResponse response)? onOpenHome;

  /// 通知操作按钮生效后回调（前台场景用于刷新 UI）
  static Future<void> Function()? onActionApplied;

  /// 初始化插件与时区数据（在 main() 中调用）。
  static Future<void> init() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_drink'),
      ),
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
    );
  }

  /// 设置 tz.local 为设备本地时区。
  static void setLocalLocation(tz.Location location) => tz.setLocalLocation(location);

  static Future<void> _onForegroundResponse(NotificationResponse response) async {
    // 前台（含后台存活，非终止）时的回调
    if (response.actionId == null) {
      onOpenHome?.call(response);
      return;
    }
    await _handleAction(response.actionId!, response.payload);
    await onActionApplied?.call();
  }

  static Future<void> _onBackgroundResponse(NotificationResponse response) async {
    // App 被终止时的后台回调（独立 isolate，仅 dart:io 可用）
    if (response.actionId == null) return;
    await _handleAction(response.actionId!, response.payload);
  }

  /// 写喝水记录：手机与手环点击同一链路。
  static Future<void> _handleAction(String actionId, String? payloadJson) async {
    if (actionId != actionDrink && actionId != actionMiss) return;
    final payload = NotificationPayload.fromJson(payloadJson);
    if (payload == null) return;

    final db = openAppDatabaseAt(payload.dbPath);
    try {
      await db.insertDrinkLog(
        reminderId: payload.reminderId,
        actionTime: DateTime.now(),
        occurDate: payload.occurDate,
        isDrank: actionId == actionDrink,
      );
    } finally {
      await db.close();
    }
  }

  /// 免打扰开启时的一次性调度窗口（天）。此模式每提醒会占多个闹钟槽位，
  /// 窗口设短以避免触碰安卓「每应用 500 个并发闹钟」上限。
  static const int dndWindowDays = 7;

  // 通知 ID 偏移表（base = reminderId * idBase）
  static const int _idOffsetOnce = 0; // 一次性
  static const int _idOffsetDaily = 1; // 每天（原生循环）
  static const int _idOffsetMonthly = 2; // 每月（原生循环）
  static const int _idOffsetWeeklyBase = 20; // 每周：20 + weekday(1..7)
  static const int _idOffsetExtrasBase = 100; // 每月月末兜底 / DND 窗口一次性

  /// 全量刷新：撤销旧闹钟 → 按提醒类型注册。
  ///
  /// 循环提醒（每天/每周/每月）默认用**系统原生循环闹钟**（每条 1 个），避免
  /// 每条提醒产生约 90 个一次性闹钟而触碰安卓「每应用 500 个并发闹钟」上限。
  /// 仅当开启免打扰时，才退化为短窗口一次性调度以支持「时段内完全跳过」。
  /// 任何调度失败只记录日志、不向上抛出，确保保存/增删改流程永不中断。
  static Future<void> rescheduleAll(AppDatabase db) async {
    if (skipScheduling) return;
    try {
      final reminders = await db.getAllReminders();
      final settings = await db.getAllSettings();
      final dnd = parseDndWindow(settings);
      final dbPath = await getDbPath();
      final now = DateTime.now();

      for (final r in reminders) {
        await _cancelIdsOfReminder(r.id);
        if (!r.enabled) continue;

        final triggerAt = r.triggerAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r.triggerAt!);

        // 循环类型：仅当该提醒的固定时间点本身会落在免打扰窗口内时，
        // 才退化为短窗口一次性调度（剔除 DND 内时刻）；否则用系统原生循环闹钟
        // （1 条 1 个，远离 500 并发上限）。
        if (r.repeatType != repeatOnce &&
            dnd.containsTimeOfDay(r.hour * 60 + r.minute)) {
          await _scheduleDndWindow(r, triggerAt, dnd, dbPath, now);
          continue;
        }
        switch (r.repeatType) {
          case repeatOnce:
            await _scheduleOnce(r, triggerAt, dnd, dbPath, now);
          case repeatDaily:
            await _scheduleRecurringDaily(r, dbPath, now);
          case repeatWeekly:
            await _scheduleRecurringWeekly(r, dbPath, now);
          case repeatMonthly:
            await _scheduleRecurringMonthly(r, dbPath, now);
        }
      }
    } catch (e) {
      debugPrint('[notify] rescheduleAll 异常（已忽略，避免中断业务）: $e');
    }
  }

  /// 注册单个通知（可带原生循环组件）。
  static Future<void> _schedule(
    int id,
    Reminder r,
    DateTime first,
    String dbPath, {
    DateTimeComponents? matchComponents,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: r.title,
      body: r.body,
      scheduledDate: tz.TZDateTime.from(first, tz.local),
      notificationDetails: const NotificationDetails(android: _details),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
      payload: NotificationPayload(
        reminderId: r.id,
        occurDate: toDateString(first),
        dbPath: dbPath,
      ).toJson(),
    );
  }

  /// 一次性提醒：单次注册，落在免打扰内则跳过。
  static Future<void> _scheduleOnce(
    Reminder r,
    DateTime? triggerAt,
    DndWindow dnd,
    String dbPath,
    DateTime now,
  ) async {
    if (triggerAt == null || !triggerAt.isAfter(now)) return;
    if (dnd.contains(triggerAt)) return;
    await _schedule(_idFor(r.id, _idOffsetOnce), r, triggerAt, dbPath);
  }

  /// 每天：原生循环闹钟。
  static Future<void> _scheduleRecurringDaily(Reminder r, String dbPath, DateTime now) async {
    var t = DateTime(now.year, now.month, now.day, r.hour, r.minute);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    await _schedule(
      _idFor(r.id, _idOffsetDaily),
      r,
      t,
      dbPath,
      matchComponents: DateTimeComponents.time,
    );
  }

  /// 每周：每个选中日一个原生循环闹钟。
  static Future<void> _scheduleRecurringWeekly(Reminder r, String dbPath, DateTime now) async {
    final days = AppDatabase.decodeWeekdays(r.weekdays);
    for (final wd in days) {
      for (var i = 0; i < 8; i++) {
        final d = now.add(Duration(days: i));
        if (d.weekday == wd) {
          var t = DateTime(d.year, d.month, d.day, r.hour, r.minute);
          if (!t.isAfter(now)) t = t.add(const Duration(days: 7));
          await _schedule(
            _idFor(r.id, _idOffsetWeeklyBase + wd),
            r,
            t,
            dbPath,
            matchComponents: DateTimeComponents.dayOfWeekAndTime,
          );
          break;
        }
      }
    }
  }

  /// 每月 + 月末兜底：
  /// - 主闹钟：按所选日期每月循环（在有该日期的月份触发）
  /// - 补充分发：未来 13 个月内「当月天数不足所选日期」的月份，各补一个一次性闹钟到月末
  static Future<void> _scheduleRecurringMonthly(Reminder r, String dbPath, DateTime now) async {
    final day = r.monthDay;
    if (day == null) return;

    DateTime? first;
    var m = DateTime(now.year, now.month, 1);
    for (var i = 0; i < 24 && first == null; i++) {
      if (day <= daysInMonth(m.year, m.month)) {
        final t = DateTime(m.year, m.month, day, r.hour, r.minute);
        if (t.isAfter(now)) first = t;
      }
      m = DateTime(m.year, m.month + 1, 1);
    }
    if (first != null) {
      await _schedule(
        _idFor(r.id, _idOffsetMonthly),
        r,
        first,
        dbPath,
        matchComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    }

    var idx = 0;
    m = DateTime(now.year, now.month, 1);
    for (var i = 0; i < 13; i++) {
      final lastDay = daysInMonth(m.year, m.month);
      if (day > lastDay) {
        final t = DateTime(m.year, m.month, lastDay, r.hour, r.minute);
        if (t.isAfter(now)) {
          await _schedule(_idFor(r.id, _idOffsetExtrasBase + idx), r, t, dbPath);
          idx++;
        }
      }
      m = DateTime(m.year, m.month + 1, 1);
    }
  }

  /// 免打扰短窗口：一次性闹钟（默认 30 天），剔除窗口内时刻。
  static Future<void> _scheduleDndWindow(
    Reminder r,
    DateTime? triggerAt,
    DndWindow dnd,
    String dbPath,
    DateTime now,
  ) async {
    final occ = computeOccurrences(
      repeatType: r.repeatType,
      hour: r.hour,
      minute: r.minute,
      weekdays: AppDatabase.decodeWeekdays(r.weekdays),
      monthDay: r.monthDay,
      triggerAt: triggerAt,
      windowStart: now,
      windowEnd: now.add(const Duration(days: dndWindowDays)),
      dnd: dnd,
      now: now,
    );
    for (var i = 0; i < occ.length; i++) {
      await _schedule(_idFor(r.id, _idOffsetExtrasBase + i), r, occ[i], dbPath);
    }
  }

  /// 撤销单条提醒名下全部可能的历史 ID（含旧版一次性窗口占用的槽位）。
  static Future<void> _cancelIdsOfReminder(int reminderId) async {
    final base = reminderId * idBase;
    final ids = <int>{for (var i = 0; i <= 250; i++) base + i};
    await Future.wait(ids.map((id) => _plugin.cancel(id: id)));
  }

  /// 通知 ID 派生：reminderId * 10000 + offset
  static int _idFor(int reminderId, int offset) => reminderId * idBase + offset;

  static const AndroidNotificationDetails _details = AndroidNotificationDetails(
    reminderChannelId,
    '喝水提醒',
    channelDescription: '到点提醒喝水，支持标记已喝/未喝',
    importance: Importance.high,
    priority: Priority.high,
    actions: [
      AndroidNotificationAction(
        actionDrink,
        '已喝水',
        showsUserInterface: false,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        actionMiss,
        '未喝水',
        showsUserInterface: false,
        cancelNotification: true,
      ),
    ],
  );

  // ---------- 权限 ----------

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  static Future<bool> hasNotificationsPermission() async =>
      await _android?.areNotificationsEnabled() ?? true;

  static Future<bool> hasExactAlarmPermission() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  static Future<void> requestNotificationsPermission() =>
      _android?.requestNotificationsPermission() ?? Future.value();

  static Future<void> requestExactAlarmPermission() =>
      _android?.requestExactAlarmsPermission() ?? Future.value();

  /// 打开系统通知设置页
  static Future<void> openAppNotificationSettings() =>
      _android?.openAppNotificationSettings() ?? Future.value();
}