import '../data/app_database.dart';

/// 免打扰时间窗口（本地时间，单位：当日分钟数，允许跨午夜）。
class DndWindow {
  final bool enabled;
  final int startMinutes;
  final int endMinutes;

  const DndWindow({
    required this.enabled,
    this.startMinutes = 0,
    this.endMinutes = 0,
  });

  /// 空窗口视为未启用。
  bool get isEmpty => !enabled || startMinutes == endMinutes;

  /// 时刻是否落在免打扰窗口内。
  bool contains(DateTime time) => containsTimeOfDay(time.hour * 60 + time.minute);

  /// 每日分钟数是否落在免打扰窗口内（与日期无关，用于判断某固定时间点是否会被打断）。
  bool containsTimeOfDay(int minutesOfDay) {
    if (isEmpty) return false;
    if (startMinutes < endMinutes) {
      return minutesOfDay >= startMinutes && minutesOfDay < endMinutes;
    }
    // 跨午夜：如 22:00–07:00
    return minutesOfDay >= startMinutes || minutesOfDay < endMinutes;
  }
}

/// 从设置键值对解析免打扰窗口。
/// 键：dndEnabled('1'/'0') dndStart('HH:mm') dndEnd('HH:mm')
DndWindow parseDndWindow(Map<String, String> settings) {
  if (settings['dndEnabled'] != '1') return const DndWindow(enabled: false);
  int minOf(String v) {
    final parts = v.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return 0;
    return h.clamp(0, 23) * 60 + m.clamp(0, 59);
  }

  return DndWindow(
    enabled: true,
    startMinutes: minOf(settings['dndStart'] ?? '00:00'),
    endMinutes: minOf(settings['dndEnd'] ?? '00:00'),
  );
}

/// 某年某月的天数（含闰年处理）。
int daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

/// 推算 [windowStart, windowEnd) 内某条提醒的全部触发时刻。
///
/// 规则：
/// - 一次性：仅 triggerAt（未来且命中窗口）
/// - 每天：每日该时:分
/// - 每周：仅选中的星期几（weekdays 为 1..7，1=周一）
/// - 每月：每月第 monthDay 日，当月不足该数则取当月最后一天
/// 所有触发点均跳过已过去时刻与落在免打扰窗口内的时刻。
List<DateTime> computeOccurrences({
  required int repeatType,
  required int hour,
  required int minute,
  required List<int> weekdays,
  required int? monthDay,
  required DateTime? triggerAt,
  required DateTime windowStart,
  required DateTime windowEnd,
  required DndWindow dnd,
  DateTime? now,
}) {
  final results = <DateTime>[];
  final current = now ?? DateTime.now();

  if (repeatType == repeatOnce) {
    final t = triggerAt;
    if (t == null) return results;
    if (t.isAfter(current) &&
        !t.isBefore(windowStart) &&
        t.isBefore(windowEnd) &&
        !dnd.contains(t)) {
      results.add(t);
    }
    return results;
  }

  // 一次性以外的类型从窗口起始日逐日推进
  var day = DateTime(windowStart.year, windowStart.month, windowStart.day);
  while (day.isBefore(windowEnd)) {
    final candidate = DateTime(day.year, day.month, day.day, hour, minute, 0);
    if (candidate.isAfter(current) && candidate.isBefore(windowEnd)) {
      var matches = false;
      switch (repeatType) {
        case repeatDaily:
          matches = true; // 每天
        case repeatWeekly:
          matches = weekdays.contains(day.weekday);
        case repeatMonthly:
          final lastDay = daysInMonth(day.year, day.month);
          final target = (monthDay == null) ? 0 : (monthDay.clamp(1, lastDay));
          matches = day.day == target;
        default:
          matches = false;
      }
      if (matches && !dnd.contains(candidate)) {
        results.add(candidate);
      }
    }
    // 无论是否匹配都必须推进到次日，否则会死循环
    day = DateTime(day.year, day.month, day.day + 1);
  }
  results.sort();
  return results;
}

/// 判断某条提醒在某天是否有触发时刻，有则返回该时刻（本地 DateTime），无则 null。
DateTime? occurrenceOnDay({
  required int repeatType,
  required int hour,
  required int minute,
  required List<int> weekdays,
  required int? monthDay,
  required DateTime? triggerAt,
  required DateTime day,
}) {
  switch (repeatType) {
    case repeatOnce:
      final t = triggerAt;
      if (t == null) return null;
      return toDateString(t) == toDateString(day) ? t : null;
    case repeatDaily:
      return DateTime(day.year, day.month, day.day, hour, minute);
    case repeatWeekly:
      return weekdays.contains(day.weekday)
          ? DateTime(day.year, day.month, day.day, hour, minute)
          : null;
    case repeatMonthly:
      final lastDay = daysInMonth(day.year, day.month);
      final target = (monthDay == null) ? 0 : (monthDay.clamp(1, lastDay));
      return day.day == target
          ? DateTime(day.year, day.month, day.day, hour, minute)
          : null;
  }
  return null;
}

/// 格式化为 YYYY-MM-DD（本地日期字符串）
String toDateString(DateTime t) {
  final m = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  return '${t.year}-$m-$d';
}