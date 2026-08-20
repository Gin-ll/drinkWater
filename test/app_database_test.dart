import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drink_water/constants.dart';
import 'package:drink_water/data/app_database.dart';
import 'package:drink_water/services/notification_service.dart';
import 'package:drink_water/services/occurrence_calculator.dart';
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

    test('修改记录时间与删除单条记录（手动记录可编辑）', () async {
      final id = await db.insertDrinkLog(
        reminderId: null,
        actionTime: DateTime(2026, 8, 19, 10, 0),
        occurDate: '2026-08-19',
        isDrank: true,
      );
      await db.updateDrinkLogTime(id, DateTime(2026, 8, 19, 14, 30));
      final after = (await db.logsOfDay('2026-08-19')).single;
      expect(after.actionTime, DateTime(2026, 8, 19, 14, 30));

      await db.deleteDrinkLog(id);
      expect(await db.logsOfDay('2026-08-19'), isEmpty);
    });
  });

  group('统计聚合 drankCountsByDay', () {
    test('统计仅基于 DrinkLog，与提醒数量无关（P0-08）', () async {
      // 2 条提醒配置
      await addDailyReminder(hour: 8, minute: 0);
      await addDailyReminder(hour: 18, minute: 0);
      // 但只有 1 条实际喝水记录（手动）
      await db.insertDrinkLog(
          reminderId: null, actionTime: DateTime(2026, 8, 20, 9, 0), occurDate: '2026-08-20', isDrank: true);
      final counts = await db.drankCountsByDay('2026-08-20', '2026-08-21');
      // 提醒数量 ≠ 喝水次数：只有 1 次
      expect(counts['2026-08-20'], 1);
    });

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

  group('同刻去重 hasConflictAtTime', () {
    test('当天同刻冲突判定', () async {
      final now = DateTime.now();
      await db.insertReminder(
        RemindersCompanion.insert(
          title: const Value('9点'),
          repeatType: repeatDaily,
          hour: 9,
          minute: 0,
          weekdays: const Value(''),
          createdAt: now,
          updatedAt: now,
        ),
      );
      final reminders = await db.getAllReminders();
      final day = DateTime(now.year, now.month, now.day);
      expect(hasConflictAtTime(reminders, 9, 0, day), isTrue);
      expect(hasConflictAtTime(reminders, 10, 0, day), isFalse);
      expect(hasConflictAtTime(reminders, 9, 0, day, excludeId: reminders.first.id), isFalse);
    });

    test('每周型不含当天不冲突', () async {
      final now = DateTime.now();
      await db.insertReminder(
        RemindersCompanion.insert(
          title: const Value('周一9点'),
          repeatType: repeatWeekly,
          hour: 9,
          minute: 0,
          weekdays: Value(AppDatabase.encodeWeekdays([DateTime.monday])),
          createdAt: now,
          updatedAt: now,
        ),
      );
      final reminders = await db.getAllReminders();
      final monday = DateTime(2026, 8, 24); // 周一
      final tuesday = DateTime(2026, 8, 25); // 周二
      expect(hasConflictAtTime(reminders, 9, 0, monday), isTrue);
      expect(hasConflictAtTime(reminders, 9, 0, tuesday), isFalse);
    });
  });

  group('P0 数据语义', () {
    test('删除提醒保留历史喝水记录（P0-02）', () async {
      final rid = await addDailyReminder();
      await db.insertDrinkLog(
          reminderId: rid, actionTime: DateTime(2026, 8, 19, 10, 0), occurDate: '2026-08-19', isDrank: true);
      await db.deleteReminder(rid);
      final day = await db.logsOfDay('2026-08-19');
      expect(day.length, 1);
      expect(day.first.reminderId, rid);
      final counts = await db.drankCountsByDay('2026-08-19', '2026-08-20');
      expect(counts['2026-08-19'], 1);
    });

    test('编辑提醒不改历史记录（P0-03）', () async {
      final rid = await addDailyReminder(hour: 10, minute: 0);
      await db.insertDrinkLog(
          reminderId: rid, actionTime: DateTime(2026, 8, 19, 10, 0), occurDate: '2026-08-19', isDrank: true);
      final r = (await db.getReminder(rid))!;
      await db.updateReminder(r.copyWith(hour: 14, updatedAt: DateTime.now()));
      final after = await db.logsOfDay('2026-08-19');
      expect(after.single.actionTime.hour, 10);
      expect(after.single.reminderId, rid);
    });

    test('通知数据与 Reminder 明确关联（P0-04 payload 往返）', () {
      final payload = NotificationPayload(
        notificationId: 10001,
        reminderId: 1,
        occurDate: '2026-08-20',
        dbPath: '/x/drink_water.sqlite',
      );
      final restored = NotificationPayload.fromJson(payload.toJson());
      expect(restored, isNotNull);
      expect(restored!.notificationId, 10001);
      expect(restored.reminderId, 1);
      expect(restored.occurDate, '2026-08-20');
      expect(reminderMatchWindow, const Duration(minutes: 30));
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