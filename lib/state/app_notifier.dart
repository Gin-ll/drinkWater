import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../constants.dart';
import '../data/app_database.dart';
import '../services/notification_service.dart';
import '../services/occurrence_calculator.dart';
import '../theme.dart';

/// 首页时间轴单条记录
class TodayEntry {
  /// 关联提醒；手动喝水记录为 null
  final Reminder? reminder;
  final DateTime time;
  final bool inDnd;
  final DrinkLog? log;

  /// 是否由「该提醒对应 DrinkLog」之外的记录判定（如 ±窗口内手动喝水自动完成）
  final bool autoMatched;

  const TodayEntry({
    required this.reminder,
    required this.time,
    required this.inDnd,
    this.log,
    this.autoMatched = false,
  });

  bool get isFuture => time.isAfter(DateTime.now());

  /// 是否为「手动喝水」记录（无关联提醒）
  bool get manual => reminder == null;
}

/// 应用全局状态：提醒列表、设置、统计查询与所有增删改动作。
class AppNotifier extends ChangeNotifier {
  final AppDatabase? _injectedDb;
  late final AppDatabase db;

  AppNotifier({AppDatabase? db}) : _injectedDb = db;

  List<Reminder> reminders = const [];
  Map<String, String> settings = const {};

  bool get loaded => true; // 占位：始终视为就绪

  /// 初始化：打开库、装载数据、示例数据（首次）、注册调度。
  Future<void> init({bool schedule = true}) async {
    db = _injectedDb ?? await openAppDatabase();
    await refresh();
    NotificationService.onActionApplied = refresh;
    await _ensureSampleData();
    if (schedule) await NotificationService.rescheduleAll(db);
  }

  /// 首次启动（提醒列表为空）时写入一组合理的示例喝水提醒，仅一次。
  Future<void> _ensureSampleData() async {
    final seeded = (await db.getSetting('seeded')) == '1';
    final existing = await db.getAllReminders();
    if (!seeded && existing.isEmpty) {
      final now = DateTime.now();
      const samples = <(String, int, int)>[
        ('晨起第一杯', 8, 0),
        ('上午补水', 10, 0),
        ('餐前一杯', 12, 0),
        ('下午补水', 14, 30),
        ('下班前一杯', 17, 0),
        ('晚间补水', 20, 30),
      ];
      for (final s in samples) {
        await db.insertReminder(
          RemindersCompanion.insert(
            title: Value(s.$1),
            body: const Value(''),
            repeatType: repeatDaily,
            hour: s.$2,
            minute: s.$3,
            weekdays: const Value(''),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      await db.setSetting('seeded', '1');
      await refresh();
    } else if (existing.isNotEmpty && !seeded) {
      // 已有数据视为已初始化，不再写入示例
      await db.setSetting('seeded', '1');
    }
  }

  /// 重新装载数据并通知界面刷新。
  Future<void> refresh() async {
    reminders = await db.getAllReminders();
    settings = await db.getAllSettings();
    notifyListeners();
  }

  // ---------- 提醒 CRUD ----------

  Future<void> addReminder({
    required String title,
    required String body,
    required int repeatType,
    required int hour,
    required int minute,
    List<int> weekdays = const [],
    int? monthDay,
    DateTime? triggerAt,
  }) async {
    final now = DateTime.now();
    await db.insertReminder(
      RemindersCompanion.insert(
        title: Value(title),
        body: Value(body),
        repeatType: repeatType,
        hour: hour,
        minute: minute,
        weekdays: Value(AppDatabase.encodeWeekdays(weekdays)),
        monthDay: Value(monthDay),
        triggerAt: Value(triggerAt?.millisecondsSinceEpoch),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await refresh();
    await NotificationService.rescheduleAll(db);
  }

  Future<void> updateReminder(
    int id, {
    required String title,
    required String body,
    required int repeatType,
    required int hour,
    required int minute,
    List<int> weekdays = const [],
    int? monthDay,
    DateTime? triggerAt,
  }) async {
    final existing = await db.getReminder(id);
    if (existing == null) return;
    await db.updateReminder(
      existing.copyWith(
        title: title,
        body: body,
        repeatType: repeatType,
        hour: hour,
        minute: minute,
        weekdays: AppDatabase.encodeWeekdays(weekdays),
        monthDay: Value(monthDay),
        triggerAt: Value(triggerAt?.millisecondsSinceEpoch),
        updatedAt: DateTime.now(),
      ),
    );
    debugPrint('[edit] updateReminder 已保存 id=$id title=$title h=$hour m=$minute type=$repeatType');
    await refresh();
    debugPrint('[edit] refresh 后 reminders=${reminders.map((r) => r.title).toList()}');
    await NotificationService.rescheduleAll(db);
  }

  Future<void> deleteReminder(int id) async {
    // P0-02：删除提醒只删未来提醒配置（含按天调整），不删历史喝水记录，统计保持不变
    await db.deleteReminder(id);
    await refresh();
    await NotificationService.rescheduleAll(db);
  }

  // ---------- 按天临时调整（override） ----------

  /// 某提醒在某天的「生效时间」：若该天有按天调整则用之，否则用规则时间。
  Future<DateTime?> effectiveOccurrence(Reminder r, DateTime day) async {
    final dayDate = DateTime(day.year, day.month, day.day);
    final base = occurrenceOnDay(
      repeatType: r.repeatType,
      hour: r.hour,
      minute: r.minute,
      weekdays: AppDatabase.decodeWeekdays(r.weekdays),
      monthDay: r.monthDay,
      triggerAt: r.triggerAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.triggerAt!),
      day: dayDate,
      startOn: r.createdAt,
    );
    if (base == null) return null;
    final ov = await db.overrideFor(r.id, toDateString(dayDate));
    if (ov != null) {
      if (ov.isSkipped) return null; // 当天被跳过（删除当天实例）
      return DateTime(dayDate.year, dayDate.month, dayDate.day, ov.hour, ov.minute);
    }
    return base;
  }

  /// 仅调整某一天（不改未来规则）。时间与规则一致时等价于清除调整。
  Future<void> setDayOverride(int reminderId, String date, int hour, int minute,
      {int? baseHour, int? baseMinute}) async {
    if (baseHour != null && baseMinute != null && hour == baseHour && minute == baseMinute) {
      await db.clearOverride(reminderId, date);
    } else {
      await db.setOverride(reminderId, date, hour, minute);
    }
    await refresh();
    await NotificationService.rescheduleAll(db);
  }

  Future<void> clearDayOverride(int reminderId, String date) async {
    await db.clearOverride(reminderId, date);
    await refresh();
    await NotificationService.rescheduleAll(db);
  }

  /// 首页「删除今天」：跳过当天实例（当天不显示、不排当天闹钟）；
  /// 规则（循环与一次性）保留，历史喝水记录保留（P0-02）。
  Future<void> skipTodayInstance(int reminderId, String date) async {
    await db.skipDay(reminderId, date);
    await refresh();
    await NotificationService.rescheduleAll(db);
  }

  Future<void> toggleEnabled(int id) async {
    final r = await db.getReminder(id);
    if (r == null) return;
    await db.updateReminder(r.copyWith(enabled: !r.enabled, updatedAt: DateTime.now()));
    await refresh();
    await NotificationService.rescheduleAll(db);
  }

  // ---------- 喝水标记 ----------

  /// 标记已喝/未喝：同一提醒同一天只保留最后一次结果。返回新记录的 id（供撤销）。
  Future<int> mark({required int reminderId, required bool isDrank, String? occurDate}) async {
    final date = occurDate ?? toDateString(DateTime.now());
    await db.deleteLogOf(reminderId, date);
    final id = await db.insertDrinkLog(
      reminderId: reminderId,
      actionTime: DateTime.now(),
      occurDate: date,
      isDrank: isDrank,
    );
    notifyListeners();
    return id;
  }

  // ---------- 首页时间轴 ----------

  /// 指定日期的时间轴数据（按时间升序）。
  Future<List<TodayEntry>> timelineFor(DateTime day) async {
    final dayDate = DateTime(day.year, day.month, day.day);
    final dayStr = toDateString(dayDate);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 规则只在「未来 30 天」内生成提醒：超出 30 天的未来日期不再生成实例
    if (dayDate.isAfter(today.add(const Duration(days: 30)))) {
      return const [];
    }
    final dnd = parseDndWindow(settings);
    final logs = await db.logsOfDay(dayStr);
    final logById = <int, DrinkLog>{for (final l in logs) if (l.reminderId != null) l.reminderId! : l};

    final entries = <TodayEntry>[];
    // 当日手动喝水记录（reminderId 为空，独立记录）
    final manualLogs = logs.where((l) => l.reminderId == null).toList();

    for (final r in reminders) {
      if (!r.enabled) continue;
      // 按天生效时间：优先按天临时调整（override），否则用规则时间
      final time = await effectiveOccurrence(r, dayDate);
      if (time == null) continue;

      // 该提醒自己对应的 DrinkLog（存在 → 已喝水）
      DrinkLog? log = logById[r.id];
      var autoMatched = false;
      // 不存在对应记录时：提醒时间前后 reminderMatchWindow（默认 30 分钟）内
      // 存在手动喝水 → 自动判定为「已喝水」，避免刚喝完又提醒
      if (log == null) {
        for (final m in manualLogs) {
          if (m.isDrank && (m.actionTime.difference(time).abs() <= reminderMatchWindow)) {
            log = m;
            autoMatched = true;
            break;
          }
        }
      }

      entries.add(TodayEntry(
        reminder: r,
        time: time,
        inDnd: dnd.contains(time),
        log: log,
        autoMatched: autoMatched,
      ));
    }

    // 手动喝水记录（无关联提醒，按点按时间落时间轴）
    for (final l in manualLogs) {
      entries.add(TodayEntry(
        reminder: null,
        time: l.actionTime,
        inDnd: false,
        log: l,
      ));
    }

    entries.sort((a, b) => a.time.compareTo(b.time));
    return entries;
  }

  /// 今日时间轴数据。
  Future<List<TodayEntry>> todayTimeline() async {
    final now = DateTime.now();
    return timelineFor(DateTime(now.year, now.month, now.day));
  }

  /// 手动记录「现在喝了一杯水」。返回新记录 id（供撤销）。
  Future<int> recordDrinkNow() async {
    final now = DateTime.now();
    final id = await db.insertDrinkLog(
      reminderId: null,
      actionTime: now,
      occurDate: toDateString(now),
      isDrank: true,
    );
    notifyListeners();
    return id;
  }

  /// P0-07：进入前台时校准调度（时间/时区变化后重算当天闹钟）。
  /// cancel-first 保证不重复注册；仅当天未来时刻 → 不补发已错过历史。
  Future<void> recalibrate() async {
    await refresh();
    await NotificationService.rescheduleAll(db);
  }

  /// 编辑手动喝水记录的时间（保持归属日期不变）。
  Future<void> updateManualLogTime(int logId, DateTime actionTime) async {
    await db.updateDrinkLogTime(logId, actionTime);
    notifyListeners();
  }

  /// 删除一条喝水记录（手动记录或提醒标记均可）。
  Future<void> deleteDrinkLog(int logId) async {
    await db.deleteDrinkLog(logId);
    notifyListeners();
  }

  // ---------- 统计查询 ----------

  Future<Map<String, int>> drankCountsByDay(DateTime start, DateTime end) =>
      db.drankCountsByDay(toDateString(start), toDateString(end));

  Future<List<DrinkLog>> logsOfDay(String date) => db.logsOfDay(date);

  int countByType(int type) => reminders.where((r) => r.repeatType == type).length;

  int get enabledCount => reminders.where((r) => r.enabled).length;

  int get disabledCount => reminders.length - enabledCount;

  // ---------- 设置 ----------

  String get themeColor => settings['themeColor'] ?? themeColorBlue;

  bool get dndEnabled => settings['dndEnabled'] == '1';

  String get dndStart => settings['dndStart'] ?? '22:00';

  String get dndEnd => settings['dndEnd'] ?? '07:00';

  Future<void> setThemeColor(String color) async {
    await db.setSetting('themeColor', color);
    await refresh();
  }

  Future<void> setDnd({required bool enabled, String? start, String? end}) async {
    await db.setSetting('dndEnabled', enabled ? '1' : '0');
    await db.setSetting('dndStart', start ?? dndStart);
    await db.setSetting('dndEnd', end ?? dndEnd);
    await refresh();
    await NotificationService.rescheduleAll(db);
  }

  /// 是否已忽略电池优化（走系统通道）
  Future<bool> isBatteryOptimizationIgnored() async {
    final result = await NotificationService.systemChannel
        .invokeMethod('isIgnoringBatteryOptimizations');
    return result == true;
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }
}