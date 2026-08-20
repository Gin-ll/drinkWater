import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 重复类型
const int repeatOnce = 0;
const int repeatDaily = 1;
const int repeatWeekly = 2;
const int repeatMonthly = 3;

/// 喝水记录动作
const int actionDrank = 1;
const int actionMissed = 0;

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant('喝水提醒'))();
  TextColumn get body => text().withDefault(const Constant('该喝水啦 💧'))();
  IntColumn get repeatType => integer()(); // repeatOnce/Daily/Weekly/Monthly
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  // 每周型：JSON 数组 [1..7]，1=周一…7=周日；其余类型为空字符串
  TextColumn get weekdays => text().withDefault(const Constant(''))();
  // 每月型：1..31，其余类型为 null
  IntColumn get monthDay => integer().nullable()();
  // 一次性：绝对时间戳（epoch 毫秒），其余类型为 null
  IntColumn get triggerAt => integer().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class DrinkLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reminderId => integer().nullable().references(Reminders, #id)();
  DateTimeColumn get actionTime => dateTime()();
  TextColumn get occurDate => text()(); // YYYY-MM-DD（本地时区归属日期）
  BoolColumn get isDrank => boolean()();
}

class SettingsTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {key};
}

/// 每日喝水次数聚合结果
class DailyDrinkCount {
  final String date;
  final int count;

  DailyDrinkCount(this.date, this.count);
}

@DriftDatabase(tables: [Reminders, DrinkLogs, SettingsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // ---------- 提醒 ----------

  Stream<List<Reminder>> watchAllReminders() {
    final q = select(reminders)..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return q.watch();
  }

  Future<List<Reminder>> getAllReminders() {
    return select(reminders).get();
  }

  Future<Reminder?> getReminder(int id) {
    final q = select(reminders)..where((t) => t.id.equals(id));
    return q.getSingleOrNull();
  }

  Future<int> insertReminder(RemindersCompanion entry) {
    return into(reminders).insert(entry);
  }

  Future<bool> updateReminder(Reminder entry) {
    return update(reminders).replace(entry);
  }

  Future<void> deleteReminder(int id) {
    return (delete(reminders)..where((t) => t.id.equals(id))).go();
  }

  /// 将周几数组编码为 JSON 文本
  static String encodeWeekdays(List<int> days) => jsonEncode(days);

  /// 解码 JSON 文本为周几数组
  static List<int> decodeWeekdays(String json) {
    if (json.isEmpty) return const [];
    final decoded = jsonDecode(json);
    if (decoded is! List) return const [];
    return decoded.whereType<int>().toList();
  }

  // ---------- 喝水记录 ----------

  Future<int> insertDrinkLog({
    int? reminderId,
    required DateTime actionTime,
    required String occurDate,
    required bool isDrank,
  }) {
    return into(drinkLogs).insert(
      DrinkLogsCompanion.insert(
        reminderId: Value(reminderId),
        actionTime: actionTime,
        occurDate: occurDate,
        isDrank: isDrank,
      ),
    );
  }

  /// 区间内全部记录（按时间升序）
  Future<List<DrinkLog>> logsBetween(DateTime startInclusive, DateTime endExclusive) {
    final q = select(drinkLogs)
      ..where((t) =>
          t.actionTime.isBiggerOrEqualValue(startInclusive) &
          t.actionTime.isSmallerThanValue(endExclusive))
      ..orderBy([(t) => OrderingTerm(expression: t.actionTime)]);
    return q.get();
  }

  /// 日期区间内按日聚合（按归属日期 occurDate 分组，仅统计"已喝水"），
  /// 返回 {YYYY-MM-DD: 次数}。参数为开区间：[startDate, endDate)。
  Future<Map<String, int>> drankCountsByDay(String startDate, String endDate) async {
    final rows = await customSelect(
      'SELECT occur_date, COUNT(*) AS cnt FROM drink_logs '
      'WHERE is_drank = 1 AND occur_date >= ? AND occur_date < ? '
      'GROUP BY occur_date',
      variables: [
        Variable.withString(startDate),
        Variable.withString(endDate),
      ],
    ).get();

    return {
      for (final row in rows) row.read<String>('occur_date'): row.read<int>('cnt'),
    };
  }

  /// 删除某提醒在指定日期的旧记录（用于"最后一次点击生效"的覆盖逻辑）
  Future<void> deleteLogOf(int reminderId, String occurDate) {
    return (delete(drinkLogs)
          ..where((t) =>
              t.reminderId.equals(reminderId) & t.occurDate.equals(occurDate)))
        .go();
  }

  /// 修改一条喝水记录的时间（归属日期发生日期不变，仅更新点按时刻）。
  Future<void> updateDrinkLogTime(int id, DateTime actionTime) {
    return (update(drinkLogs)..where((t) => t.id.equals(id)))
        .write(DrinkLogsCompanion(actionTime: Value(actionTime)));
  }

  /// 删除一条喝水记录（手动记录或提醒标记均可）。
  Future<void> deleteDrinkLog(int id) {
    return (delete(drinkLogs)..where((t) => t.id.equals(id))).go();
  }

  /// 某天的喝水明细（按时间升序）
  Future<List<DrinkLog>> logsOfDay(String occurDate) {
    final q = select(drinkLogs)
      ..where((t) => t.occurDate.equals(occurDate))
      ..orderBy([(t) => OrderingTerm(expression: t.actionTime)]);
    return q.get();
  }

  /// 删除某提醒的全部喝水记录
  Future<void> deleteLogsOfReminder(int reminderId) {
    return (delete(drinkLogs)..where((t) => t.reminderId.equals(reminderId))).go();
  }

  // ---------- 设置 ----------

  Future<String?> getSetting(String key) async {
    final row = await (select(settingsTable)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) {
    return into(settingsTable).insertOnConflictUpdate(
      SettingsTableCompanion.insert(key: key, value: Value(value)),
    );
  }

  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(settingsTable).get();
    return {for (final row in rows) row.key: row.value};
  }
}

// ---------- 连接构造器 ----------

/// 数据库文件名
const String dbFileName = 'drink_water.sqlite';

/// 计算数据库文件绝对路径（主 isolate 使用）。
Future<String> getDbPath() async {
  final dir = await getApplicationSupportDirectory();
  return p.join(dir.path, dbFileName);
}

/// 打开主 isolate 数据库连接。
Future<AppDatabase> openAppDatabase() async {
  final path = await getDbPath();
  return AppDatabase(NativeDatabase(File(path)));
}

/// 在任意 isolate（含通知后台回调 isolate）中按已知路径打开数据库。
/// 主 isolate 会通过通知 payload 把 dbPath 传给后台回调，因此后台无需依赖平台通道。
AppDatabase openAppDatabaseAt(String dbPath) {
  return AppDatabase(NativeDatabase(File(dbPath)));
}

/// 测试用：内存数据库
AppDatabase openInMemoryDatabase() {
  return AppDatabase(NativeDatabase.memory());
}