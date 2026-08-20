import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

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

  const TodayEntry({
    required this.reminder,
    required this.time,
    required this.inDnd,
    this.log,
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

  /// 初始化：打开库、装载数据、注册调度。
  Future<void> init({bool schedule = true}) async {
    db = _injectedDb ?? await openAppDatabase();
    await refresh();
    NotificationService.onActionApplied = refresh;
    if (schedule) await NotificationService.rescheduleAll(db);
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
    await db.deleteLogsOfReminder(id);
    await db.deleteReminder(id);
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

  /// 标记已喝/未喝：同一提醒同一天只保留最后一次结果。
  Future<void> mark({required int reminderId, required bool isDrank, String? occurDate}) async {
    final date = occurDate ?? toDateString(DateTime.now());
    await db.deleteLogOf(reminderId, date);
    await db.insertDrinkLog(
      reminderId: reminderId,
      actionTime: DateTime.now(),
      occurDate: date,
      isDrank: isDrank,
    );
    notifyListeners();
  }

  // ---------- 首页时间轴 ----------

  /// 指定日期的时间轴数据（按时间升序）。
  Future<List<TodayEntry>> timelineFor(DateTime day) async {
    final dayDate = DateTime(day.year, day.month, day.day);
    final dayStr = toDateString(dayDate);
    final dnd = parseDndWindow(settings);
    final logs = await db.logsOfDay(dayStr);
    final logById = <int, DrinkLog>{for (final l in logs) if (l.reminderId != null) l.reminderId! : l};

    final entries = <TodayEntry>[];
    for (final r in reminders) {
      if (!r.enabled) continue;
      final time = occurrenceOnDay(
        repeatType: r.repeatType,
        hour: r.hour,
        minute: r.minute,
        weekdays: AppDatabase.decodeWeekdays(r.weekdays),
        monthDay: r.monthDay,
        triggerAt: r.triggerAt == null ? null : DateTime.fromMillisecondsSinceEpoch(r.triggerAt!),
        day: dayDate,
      );
      if (time == null) continue;
      entries.add(TodayEntry(
        reminder: r,
        time: time,
        inDnd: dnd.contains(time),
        log: logById[r.id],
      ));
    }

    // 手动喝水记录（无关联提醒，按点按时间落时间轴）
    for (final l in logs.where((l) => l.reminderId == null)) {
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

  /// 手动记录「现在喝了一杯水」。
  Future<void> recordDrinkNow() async {
    final now = DateTime.now();
    await db.insertDrinkLog(
      reminderId: null,
      actionTime: now,
      occurDate: toDateString(now),
      isDrank: true,
    );
    notifyListeners();
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