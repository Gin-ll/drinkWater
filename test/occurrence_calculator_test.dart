import 'package:flutter_test/flutter_test.dart';

import 'package:drink_water/data/app_database.dart';
import 'package:drink_water/services/occurrence_calculator.dart';

void main() {
  final now = DateTime(2026, 8, 19, 10, 0); // 周三

  group('一次性提醒', () {
    test('未来的触发点命中窗口', () {
      final t = DateTime(2026, 8, 20, 9, 0);
      final result = computeOccurrences(
        repeatType: repeatOnce,
        hour: 9,
        minute: 0,
        weekdays: const [],
        monthDay: null,
        triggerAt: t,
        windowStart: now,
        windowEnd: now.add(const Duration(days: 90)),
        dnd: const DndWindow(enabled: false),
        now: now,
      );
      expect(result, [t]);
    });

    test('过去的触发点被丢弃', () {
      final t = DateTime(2026, 8, 19, 9, 0);
      final result = computeOccurrences(
        repeatType: repeatOnce,
        hour: 9,
        minute: 0,
        weekdays: const [],
        monthDay: null,
        triggerAt: t,
        windowStart: now,
        windowEnd: now.add(const Duration(days: 90)),
        dnd: const DndWindow(enabled: false),
        now: now,
      );
      expect(result, isEmpty);
    });

    test('窗口外触发点被丢弃', () {
      final t = now.add(const Duration(days: 91));
      final result = computeOccurrences(
        repeatType: repeatOnce,
        hour: 9,
        minute: 0,
        weekdays: const [],
        monthDay: null,
        triggerAt: t,
        windowStart: now,
        windowEnd: now.add(const Duration(days: 90)),
        dnd: const DndWindow(enabled: false),
        now: now,
      );
      expect(result, isEmpty);
    });
  });

  group('每天提醒', () {
    test('90 天窗口内每天都触发', () {
      final result = computeOccurrences(
        repeatType: repeatDaily,
        hour: 9,
        minute: 0,
        weekdays: const [],
        monthDay: null,
        triggerAt: null,
        windowStart: now,
        windowEnd: now.add(const Duration(days: 90)),
        dnd: const DndWindow(enabled: false),
        now: now,
      );
      // 当天 10:00 已过 9:00，从明天起共 90 天（含窗口结束日当天 9:00）
      expect(result.length, 90);
      expect(result.first.day, 20);
    });

    test('当天还没到点时包含今天', () {
      final result = computeOccurrences(
        repeatType: repeatDaily,
        hour: 11,
        minute: 0,
        weekdays: const [],
        monthDay: null,
        triggerAt: null,
        windowStart: now,
        windowEnd: now.add(const Duration(days: 90)),
        dnd: const DndWindow(enabled: false),
        now: now,
      );
      expect(result.length, 90);
      expect(result.first.day, 19);
    });
  });

  group('每周提醒（周一、三、五）', () {
    test('只有选中星期几触发', () {
      final result = computeOccurrences(
        repeatType: repeatWeekly,
        hour: 9,
        minute: 30,
        weekdays: [1, 3, 5],
        monthDay: null,
        triggerAt: null,
        windowStart: now,
        windowEnd: now.add(const Duration(days: 30)),
        dnd: const DndWindow(enabled: false),
        now: now,
      );
      for (final t in result) {
        expect(const {DateTime.monday, DateTime.wednesday, DateTime.friday}.contains(t.weekday), isTrue);
        expect(t.hour, 9);
        expect(t.minute, 30);
      }
      // 30 天内应有约 12-13 个周一三五
      expect(result.length, greaterThanOrEqualTo(12));
      expect(result.length, lessThanOrEqualTo(14));
    });

    test('跨周边界正确', () {
      final sunday = DateTime(2026, 8, 23, 10, 0); // 周日
      final result = computeOccurrences(
        repeatType: repeatWeekly,
        hour: 8,
        minute: 0,
        weekdays: [7],
        monthDay: null,
        triggerAt: null,
        windowStart: sunday,
        windowEnd: sunday.add(const Duration(days: 8)),
        dnd: const DndWindow(enabled: false),
        now: sunday,
      );
      // 当天8:00已过（now=10:00），仅下一个周日 8/30
      expect(result.length, 1);
      expect(result.first.day, 30);
    });
  });

  group('每月提醒（固定日期 + 月末兜底）', () {
    test('31 号在不足 31 天的月份取月末兜底', () {
      final result = computeOccurrences(
        repeatType: repeatMonthly,
        hour: 9,
        minute: 0,
        weekdays: const [],
        monthDay: 31,
        triggerAt: null,
        windowStart: DateTime(2026, 8, 1),
        windowEnd: DateTime(2027, 6, 1),
        dnd: const DndWindow(enabled: false),
        now: DateTime(2026, 8, 1),
      );
      final byMonth = {for (final t in result) t.month: t.day};
      // 不足 31 天的月份取月末
      expect(byMonth[9], 30); // 9月无31 → 9/30
      expect(byMonth[11], 30); // 11月无31 → 11/30
      expect(byMonth[4], 30); // 4月无31 → 4/30
      expect(byMonth[2], 28); // 2027年2月无31 → 2/28
      // 有 31 天的月份正常取 31
      expect(byMonth[10], 31);
      expect(byMonth[12], 31);
      expect(byMonth[1], 31);
      expect(byMonth[3], 31);
      expect(byMonth[5], 31);
    });

    test('固定 15 号每月触发', () {
      final result = computeOccurrences(
        repeatType: repeatMonthly,
        hour: 10,
        minute: 0,
        weekdays: const [],
        monthDay: 15,
        triggerAt: null,
        windowStart: DateTime(2026, 1, 1),
        windowEnd: DateTime(2026, 4, 1),
        dnd: const DndWindow(enabled: false),
        now: DateTime(2026, 1, 1),
      );
      expect(result.map((t) => t.month).toList(), [1, 2, 3]);
      expect(result.every((t) => t.day == 15), isTrue);
    });

    test('闰年 2 月 29 号，普通年取 2/28 兜底', () {
      // 2028 年是闰年
      final result2028 = computeOccurrences(
        repeatType: repeatMonthly,
        hour: 8,
        minute: 0,
        weekdays: const [],
        monthDay: 29,
        triggerAt: null,
        windowStart: DateTime(2028, 2, 1),
        windowEnd: DateTime(2028, 4, 1),
        dnd: const DndWindow(enabled: false),
        now: DateTime(2028, 2, 1),
      );
      final feb2028 = result2028.where((t) => t.month == 2).toList();
      expect(feb2028.single.day, 29);

      // 2027 年非闰年，2 月取 28
      final result2027 = computeOccurrences(
        repeatType: repeatMonthly,
        hour: 8,
        minute: 0,
        weekdays: const [],
        monthDay: 29,
        triggerAt: null,
        windowStart: DateTime(2027, 2, 1),
        windowEnd: DateTime(2027, 4, 1),
        dnd: const DndWindow(enabled: false),
        now: DateTime(2027, 2, 1),
      );
      final feb2027 = result2027.where((t) => t.month == 2).toList();
      expect(feb2027.single.day, 28);
    });
  });

  group('免打扰窗口', () {
    test('窗口内跳过，窗口外保留', () {
      final dnd = const DndWindow(
        enabled: true,
        startMinutes: 22 * 60, // 22:00
        endMinutes: 7 * 60, // 07:00 跨午夜
      );
      final result = computeOccurrences(
        repeatType: repeatDaily,
        hour: 23,
        minute: 0,
        weekdays: const [],
        monthDay: null,
        triggerAt: null,
        windowStart: DateTime(2026, 8, 19, 10, 0),
        windowEnd: DateTime(2026, 8, 25, 12, 0),
        dnd: dnd,
        now: DateTime(2026, 8, 19, 10, 0),
      );
      expect(result, isEmpty); // 每天的 23:00 都在免打扰内
    });

    test('跨午夜窗口边界判定正确', () {
      final dnd = const DndWindow(enabled: true, startMinutes: 22 * 60, endMinutes: 7 * 60);
      expect(dnd.contains(DateTime(2026, 8, 19, 23, 0)), isTrue);
      expect(dnd.contains(DateTime(2026, 8, 19, 6, 59)), isTrue);
      expect(dnd.contains(DateTime(2026, 8, 19, 7, 0)), isFalse);
      expect(dnd.contains(DateTime(2026, 8, 19, 21, 59)), isFalse);
    });

    test('起点窗口（00:00-08:00）判定正确', () {
      final dnd = const DndWindow(enabled: true, startMinutes: 0, endMinutes: 8 * 60);
      expect(dnd.contains(DateTime(2026, 8, 19, 0, 0)), isTrue);
      expect(dnd.contains(DateTime(2026, 8, 19, 7, 59)), isTrue);
      expect(dnd.contains(DateTime(2026, 8, 19, 8, 0)), isFalse);
    });

    test('containsTimeOfDay 与日期无关，可判断固定时间点是否被豁免', () {
      final dnd = const DndWindow(enabled: true, startMinutes: 22 * 60, endMinutes: 7 * 60);
      expect(dnd.containsTimeOfDay(23 * 60), isTrue); // 23:00 在窗口内
      expect(dnd.containsTimeOfDay(6 * 60 + 30), isTrue); // 06:30 在窗口内
      expect(dnd.containsTimeOfDay(8 * 60), isFalse); // 08:00 窗口外
      expect(dnd.containsTimeOfDay(12 * 60), isFalse); // 12:00 窗口外
    });
  });

  group('occurrenceOnDay（首页时间轴用）', () {
    test('每天型当天必有触发时刻', () {
      final t = occurrenceOnDay(
        repeatType: repeatDaily,
        hour: 9,
        minute: 0,
        weekdays: const [],
        monthDay: null,
        triggerAt: null,
        day: DateTime(2026, 8, 20),
      );
      expect(t, DateTime(2026, 8, 20, 9, 0));
    });

    test('一次性型仅触发当天有', () {
      final trigger = DateTime(2026, 8, 21, 15, 30);
      expect(
        occurrenceOnDay(
          repeatType: repeatOnce,
          hour: 0,
          minute: 0,
          weekdays: const [],
          monthDay: null,
          triggerAt: trigger,
          day: DateTime(2026, 8, 21),
        ),
        trigger,
      );
      expect(
        occurrenceOnDay(
          repeatType: repeatOnce,
          hour: 0,
          minute: 0,
          weekdays: const [],
          monthDay: null,
          triggerAt: trigger,
          day: DateTime(2026, 8, 22),
        ),
        isNull,
      );
    });

    test('每周型只命中选中日', () {
      expect(
        occurrenceOnDay(
          repeatType: repeatWeekly,
          hour: 8,
          minute: 0,
          weekdays: [1, 5],
          monthDay: null,
          triggerAt: null,
          day: DateTime(2026, 8, 24), // 周一
        ),
        isNotNull,
      );
      expect(
        occurrenceOnDay(
          repeatType: repeatWeekly,
          hour: 8,
          minute: 0,
          weekdays: [1, 5],
          monthDay: null,
          triggerAt: null,
          day: DateTime(2026, 8, 25), // 周二
        ),
        isNull,
      );
    });

    test('startOn 生效起始日：创建当天及之后才触发，之前不回填', () {
      final created = DateTime(2026, 8, 20); // 8/20 创建
      expect(
        occurrenceOnDay(
          repeatType: repeatDaily,
          hour: 9,
          minute: 0,
          weekdays: const [],
          monthDay: null,
          triggerAt: null,
          day: DateTime(2026, 8, 21),
          startOn: created,
        ),
        isNotNull,
      );
      expect(
        occurrenceOnDay(
          repeatType: repeatDaily,
          hour: 9,
          minute: 0,
          weekdays: const [],
          monthDay: null,
          triggerAt: null,
          day: DateTime(2026, 8, 19), // 创建前
          startOn: created,
        ),
        isNull,
      );
      expect(
        occurrenceOnDay(
          repeatType: repeatDaily,
          hour: 9,
          minute: 0,
          weekdays: const [],
          monthDay: null,
          triggerAt: null,
          day: DateTime(2026, 8, 20), // 创建当天
          startOn: created,
        ),
        isNotNull,
      );
    });
  });

  group('toDateString / parseDndWindow', () {
    test('日期字符串格式', () {
      expect(toDateString(DateTime(2026, 1, 5)), '2026-01-05');
      expect(toDateString(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('免打扰窗口解析', () {
      final w = parseDndWindow({
        'dndEnabled': '1',
        'dndStart': '22:00',
        'dndEnd': '07:30',
      });
      expect(w.enabled, isTrue);
      expect(w.startMinutes, 22 * 60);
      expect(w.endMinutes, 7 * 60 + 30);
      expect(w.contains(DateTime(2026, 8, 19, 22, 0)), isTrue);
    });

    test('未启用的免打扰', () {
      final w = parseDndWindow({'dndEnabled': '0'});
      expect(w.enabled, isFalse);
      expect(w.contains(DateTime(2026, 8, 19, 0, 0)), isFalse);
    });
  });
}