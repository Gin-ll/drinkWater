import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drink_water/data/app_database.dart';
import 'package:drink_water/state/app_notifier.dart';

/// 基础冒烟测试：使用内存库构建 AppNotifier，验证数据层与时间轴。
void main() {
  test('AppNotifier 可用内存数据库初始化并装载数据', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();
    await db.insertReminder(
      RemindersCompanion.insert(
        title: const Value('喝水提醒'),
        body: const Value('多喝水'),
        repeatType: repeatDaily,
        hour: now.hour,
        minute: now.minute,
        weekdays: Value(AppDatabase.encodeWeekdays(const [])),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final notifier = AppNotifier(db: db)..addListener(() {});
    await notifier.init(schedule: false);

    expect(notifier.reminders.length, 1);
    expect(notifier.reminders.first.title, '喝水提醒');

    final timeline = await notifier.todayTimeline();
    expect(timeline, isNotEmpty);

    // 标记已喝水
    final id = notifier.reminders.first.id;
    await notifier.mark(reminderId: id, isDrank: true);
    final day = await notifier.logsOfDay(toDateString(now));
    expect(day.length, 1);
    expect(day.first.isDrank, isTrue);

    await db.close();
  });

  test('recordDrinkNow 记录手动喝水并出现在时间轴与统计', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final notifier = AppNotifier(db: db)..addListener(() {});
    await notifier.init(schedule: false);

    await notifier.recordDrinkNow();
    final now = DateTime.now();
    final todayStr = toDateString(now);

    final day = await notifier.logsOfDay(todayStr);
    expect(day.length, 1);
    expect(day.first.reminderId, isNull); // 手动记录无关联提醒
    expect(day.first.isDrank, isTrue);

    final timeline = await notifier.todayTimeline();
    expect(timeline.where((e) => e.manual).length, 1);

    // 统计口径计入
    final counts = await notifier.drankCountsByDay(
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day + 1),
    );
    expect(counts[todayStr], 1);

    await db.close();
  });

  test('首次启动空库自动写入示例提醒，且只写一次', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final notifier = AppNotifier(db: db)..addListener(() {});
    await notifier.init(schedule: false);

    expect(notifier.reminders.length, 6);
    expect(await db.getSetting('seeded'), '1');
    // 示例标题合理
    expect(notifier.reminders.map((r) => r.title), contains('晨起第一杯'));

    // 二次初始化不再重复写入
    final n2 = AppNotifier(db: db)..addListener(() {});
    await n2.init(schedule: false);
    expect(n2.reminders.length, 6);

    await db.close();
  });

  test('±30 分钟手动喝水自动完成提醒（P0-01）', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();
    await db.insertReminder(
      RemindersCompanion.insert(
        title: const Value('自动完成'),
        repeatType: repeatDaily,
        hour: now.hour, // 与当前时刻相近的提醒时间
        minute: now.minute,
        weekdays: const Value(''),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final notifier = AppNotifier(db: db)..addListener(() {});
    await notifier.init(schedule: false);

    // 手动喝水（与提醒时间差 < 30 分钟）
    await notifier.recordDrinkNow();

    final timeline = await notifier.todayTimeline();
    final e = timeline.firstWhere((x) => x.reminder?.title == '自动完成');
    expect(e.autoMatched, isTrue);
    expect(e.log, isNotNull);

    await db.close();
  });
}

String toDateString(DateTime t) {
  final m = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  return '${t.year}-$m-$d';
}