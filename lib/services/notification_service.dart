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
/// 与 Reminder 明确关联：notificationId / reminderId / occurDate(scheduledTime归属日)
class NotificationPayload {
  final int notificationId; // 系统通知 ID（可追溯）
  final int reminderId; // 关联提醒
  final String occurDate; // YYYY-MM-DD 本地日期（该次提醒的归属日）
  final String dbPath;

  const NotificationPayload({
    required this.notificationId,
    required this.reminderId,
    required this.occurDate,
    required this.dbPath,
  });

  String toJson() => jsonEncode({
        'notificationId': notificationId,
        'reminderId': reminderId,
        'occurDate': occurDate,
        'dbPath': dbPath,
      });

  static NotificationPayload? fromJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return NotificationPayload(
        notificationId: (map['notificationId'] as num?)?.toInt() ?? 0,
        reminderId: (map['reminderId'] as num).toInt(),
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

  /// 全量刷新：撤销旧闹钟 → 仅登记「当天」的触发闹钟。
  ///
  /// 规则（需求约定）：只有今天的触发点才注册为系统闹钟；
  /// 过去的触发点仅保留为历史数据、不设闹钟；未来日期不预排闹钟。
  /// 循环类提醒在新的一天重新打开 App（或开机广播恢复）后会重新登记当天闹钟。
  /// 任何调度失败只记录日志、不向上抛出，确保保存/增删改流程永不中断。
  static Future<void> rescheduleAll(AppDatabase db) async {
    if (skipScheduling) return;
    try {
      final reminders = await db.getAllReminders();
      final settings = await db.getAllSettings();
      final dnd = parseDndWindow(settings);
      final dbPath = await getDbPath();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final r in reminders) {
        await _cancelIdsOfReminder(r.id);
        if (!r.enabled) continue;

        // 计算「今天」的触发时刻（一次性提醒仅在其触发当天命中）
        final occurrence = occurrenceOnDay(
          repeatType: r.repeatType,
          hour: r.hour,
          minute: r.minute,
          weekdays: AppDatabase.decodeWeekdays(r.weekdays),
          monthDay: r.monthDay,
          triggerAt: r.triggerAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(r.triggerAt!),
          day: today,
          startOn: r.createdAt, // 新建循环从创建当天起算，创建前不设闹钟
        );
        if (occurrence == null) continue; // 今天不触发 → 不设闹钟
        // 按天临时调整/跳过：当天有 override 则用其时间；isSkipped 时当天不设闹钟
        var at = occurrence;
        final ov = await db.overrideFor(r.id, toDateString(today));
        if (ov != null) {
          if (ov.isSkipped) continue; // 当天被跳过（首页删除今天）
          at = DateTime(today.year, today.month, today.day, ov.hour, ov.minute);
        }
        if (!at.isAfter(now)) continue; // 已错过 → 仅保留数据
        if (dnd.contains(at)) continue; // 免打扰内 → 完全跳过

        await _schedule(_idFor(r.id, 0), r, at, dbPath);
      }
    } catch (e) {
      debugPrint('[notify] rescheduleAll 异常（已忽略，避免中断业务）: $e');
    }
  }

  /// 注册单个当天一次性闹钟。
  static Future<void> _schedule(int id, Reminder r, DateTime at, String dbPath) async {
    await _plugin.zonedSchedule(
      id: id,
      title: r.title,
      body: r.body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(android: _details),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: NotificationPayload(
        notificationId: id,
        reminderId: r.id,
        occurDate: toDateString(at),
        dbPath: dbPath,
      ).toJson(),
    );
  }

  /// 撤销单条提醒名下全部可能的历史 ID（含旧版本一次性窗口占用的槽位）。
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