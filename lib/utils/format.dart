import '../data/app_database.dart';

const weekNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

String two(int v) => v.toString().padLeft(2, '0');

String formatTime(int hour, int minute) => '${two(hour)}:${two(minute)}';

/// 统计周期标签（周/月）
String formatDayShort(DateTime d) => '${d.month}/${d.day}';

/// 提醒规则的摘要文案，如「每天 08:00」「周一、三、五 09:30」「每月5号 10:00」
String formatRule(Reminder r) {
  final time = formatTime(r.hour, r.minute);
  return switch (r.repeatType) {
    repeatOnce => '仅一次 $time',
    repeatDaily => '每天 $time',
    repeatWeekly => '每${formatWeekdays(AppDatabase.decodeWeekdays(r.weekdays))} $time',
    repeatMonthly => '每月${r.monthDay ?? ''}号 $time',
    _ => time,
  };
}

String formatWeekdays(List<int> days) {
  if (days.isEmpty) return '每日';
  if (days.length == 7) return '天';
  return days.map((d) => weekNames[d - 1]).join('、');
}

/// 时间段（统计页用）
String periodOf(DateTime t) {
  final h = t.hour;
  if (h >= 5 && h < 12) return '早';
  if (h >= 12 && h < 18) return '午';
  if (h >= 18 && h < 24) return '晚';
  return '夜';
}

/// 格式化日期显示（明细/日历钻取用）
String formatDate(DateTime d) => '${d.year}年${d.month}月${d.day}日';

/// 从 YYYY-MM-DD 解析为本地日期
DateTime parseDate(String s) {
  final parts = s.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}