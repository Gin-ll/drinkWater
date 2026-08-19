import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drink_water/data/app_database.dart';
import 'package:drink_water/main.dart';
import 'package:drink_water/services/notification_service.dart';
import 'package:drink_water/state/app_notifier.dart';

void main() {
  testWidgets('点击时间轴进入编辑并保存生效', (tester) async {
    NotificationService.skipScheduling = true;

    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();
    final rid = await db.insertReminder(
      RemindersCompanion.insert(
        title: const Value('早杯'),
        body: const Value('早上第一杯'),
        repeatType: repeatDaily,
        hour: 9,
        minute: 0,
        weekdays: const Value(''),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final notifier = AppNotifier(db: db)..addListener(() {});
    await notifier.init(schedule: false);

    await tester.pumpWidget(DrinkWaterApp(notifier: notifier));
    await tester.pumpAndSettle();

    // 时间轴应显示该提醒
    expect(find.text('早杯'), findsOneWidget);

    // 点击卡片进入编辑弹窗
    await tester.tap(find.text('早杯'));
    await tester.pumpAndSettle();
    expect(find.text('编辑提醒'), findsOneWidget); // 弹窗标题

    // 修改标题
    final titleField = find.widgetWithText(TextField, '早杯');
    expect(titleField, findsOneWidget);
    await tester.enterText(titleField, '晚杯');
    await tester.pump();

    // 保存
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 回首页后 DB 与界面都应更新，且旧标题消失
    final updated = await db.getReminder(rid);
    expect(updated, isNotNull);
    expect(updated!.title, '晚杯');
    expect(notifier.reminders.firstWhere((r) => r.id == rid).title, '晚杯');
    expect(find.text('晚杯'), findsOneWidget);
    expect(find.text('早杯'), findsNothing);

    await db.close();
    await tester.pumpWidget(const SizedBox());
  });
}