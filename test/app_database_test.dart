import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drink_water/data/app_database.dart';
import 'package:drink_water/theme.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addDailyReminder({String title = '喝水', int hour = 9, int minute = 0}) async {
    final now = DateTime.now();
    return db.insertReminder(
      RemindersCompanion.insert(
        title: Value(title),
        repeatType: repeatDaily,
        hour: hour,
        minute: minute,
        weekdays: const Value(''),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('提醒 CRUD', () {
    test('插入后可读，更新后生效，删除后消失', () async {
      final id = await addDailyReminder(title: '早杯');
      final r = await db.getReminder(id);
      expect(r, isNotNull);
      expect(r!.title, '早杯');

      await db.updateReminder(r.copyWith(title: '晚杯', updatedAt: DateTime.now()));
      final updated = await db.getReminder(id);
      expect(updated!.title, '晚杯');

      await db.deleteReminder(id);
      expect(await db.getReminder(id), isNull);
    });

    test('enabled 开关切换', () async {
      final id = await addDailyReminder();
      await db.updateReminder(
        (await db.getReminder(id))!.copyWith(enabled: false, updatedAt: DateTime.now()),
      );
      expect((await db.getReminder(id))!.enabled, isFalse);
    });

    test('周几编码/解码往返', () {
      expect(AppDatabase.decodeWeekdays(AppDatabase.encodeWeekdays([1, 3, 5])), [1, 3, 5]);
      expect(AppDatabase.decodeWeekdays(''), isEmpty);
    });
  });

  group('喝水记录', () {
    test('插入与按日查询', () async {
      final rid = await addDailyReminder();
      await db.insertDrinkLog(reminderId: rid, actionTime: DateTime(2026, 8, 19, 10, 5), occurDate: '2026-08-19', isDrank: true);
      await db.insertDrinkLog(reminderId: rid, actionTime: DateTime(2026, 8, 19, 15, 0), occurDate: '2026-08-19', isDrank: false);

      final day = await db.logsOfDay('2026-08-19');
      expect(day.length, 2);
      expect(day.where((l) => l.isDrank).length, 1);
    });

    test('同一提醒同一天只保留最后一次（覆盖逻辑）', () async {
      final rid = await addDailyReminder();
      await db.insertDrinkLog(reminderId: rid, actionTime: DateTime(2026, 8, 19, 10, 0), occurDate: '2026-08-19', isDrank: true);
      await db.deleteLogOf(rid, '2026-08-19');
      await db.insertDrinkLog(reminderId: rid, actionTime: DateTime(2026, 8, 19, 10, 1), occurDate: '2026-08-19', isDrank: false);

      final day = await db.logsOfDay('2026-08-19');
      expect(day.length, 1);
      expect(day.first.isDrank, isFalse);
    });

    test('删除提醒级联删除其记录', () async {
      final rid = await addDailyReminder();
      await db.insertDrinkLog(reminderId: rid, actionTime: DateTime(2026, 8, 19), occurDate: '2026-08-19', isDrank: true);
      await db.deleteLogsOfReminder(rid);
      expect(await db.logsOfDay('2026-08-19'), isEmpty);
    });
  });

  group('统计聚合 drankCountsByDay', () {
    test('按归属日期分组、开区间过滤', () async {
      final rid = await addDailyReminder();
      await db.insertDrinkLog(reminderId: rid, actionTime: DateTime(2026, 8, 19, 10, 0, 0, 1), occurDate: '2026-08-19', isDrank: true);
      await db.insertDrinkLog(reminderId: rid, actionTime: DateTime(2026, 8, 19, 11, 0), occurDate: '2026-08-19', isDrank: true);
      await db.insertDrinkLog(reminderId: rid, actionTime: DateTime(2026, 8, 20, 9, 0), occurDate: '2026-08-20', isDrank: true);
      await db.insertDrinkLog(reminderId: rid, actionTime: DateTime(2026, 8, 20, 9, 30), occurDate: '2026-08-20', isDrank: false); // 未喝不计入
      await db.insertDrinkLog(reminderId: rid, actionTime: DateTime(2026, 8, 21, 9, 0), occurDate: '2026-08-21', isDrank: true); // 区间外(>=end)不计

      final counts = await db.drankCountsByDay('2026-08-19', '2026-08-21');
      expect(counts['2026-08-19'], 2);
      expect(counts['2026-08-20'], 1); // 未喝不计
      expect(counts.containsKey('2026-08-21'), isFalse);
    });
  });

  group('设置', () {
    test('读写下发，重复写覆盖', () async {
      expect(await db.getSetting('themeColor'), isNull);
      await db.setSetting('themeColor', themeColorYellow);
      expect(await db.getSetting('themeColor'), themeColorYellow);
      await db.setSetting('themeColor', themeColorBlue);
      expect(await db.getSetting('themeColor'), themeColorBlue);

      final all = await db.getAllSettings();
      expect(all['themeColor'], themeColorBlue);
    });
  });
}