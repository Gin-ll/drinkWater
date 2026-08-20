import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

/// 按时间自动分配的提醒图标：早🌅 午☀️ 晚🍚 夜🌙
String drinkEmoji(int hour) {
  if (hour >= 5 && hour < 12) return '🌅';
  if (hour >= 12 && hour < 18) return '☀️';
  if (hour >= 18 && hour < 24) return '🍚';
  return '🌙';
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

/// 24 小时制时间选择器（底部弹窗）：
/// - 默认展开为「输入」模式，可直接输入时分
/// - 同时提供滚轮（滚动选择），输入与滚轮双向同步
Future<TimeOfDay?> showTimePicker24(BuildContext context, TimeOfDay initialTime) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _TimePickerSheet(initial: initialTime),
  );
}

class _TimePickerSheet extends StatefulWidget {
  final TimeOfDay initial;

  const _TimePickerSheet({required this.initial});

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late TimeOfDay _selected;
  late final TextEditingController _hour;
  late final TextEditingController _minute;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _hour = TextEditingController(text: two(_selected.hour));
    _minute = TextEditingController(text: two(_selected.minute));
    _hour.addListener(_onHourText);
    _minute.addListener(_onMinuteText);
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  void _onHourText() => _syncFromInput(updateHour: true);
  void _onMinuteText() => _syncFromInput(updateHour: false);

  /// 输入框改动 → 更新选中值（同步滚轮）
  void _syncFromInput({required bool updateHour}) {
    if (_syncing) return;
    final h = int.tryParse(_hour.text);
    final m = int.tryParse(_minute.text);
    setState(() {
      _selected = TimeOfDay(
        hour: updateHour ? ((h ?? _selected.hour).clamp(0, 23)) : _selected.hour,
        minute: updateHour ? _selected.minute : ((m ?? _selected.minute).clamp(0, 59)),
      );
    });
  }

  /// 滚轮改动 → 更新输入框
  void _onWheelChanged(Duration d) {
    _syncing = true;
    _selected = TimeOfDay(hour: (d.inHours % 24), minute: (d.inMinutes % 60));
    _hour.text = two(_selected.hour);
    _minute.text = two(_selected.minute);
    setState(() {});
    _syncing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('选择时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          // 输入行：可直接输入 时:分（24 小时制）
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _hourField(),
              const Text(' : ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              _minuteField(),
            ],
          ),
          const SizedBox(height: 8),
          // 滚动选择：滚轮与输入同步
          SizedBox(
            height: 168,
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm,
              initialTimerDuration: Duration(hours: _selected.hour, minutes: _selected.minute),
              onTimerDurationChanged: _onWheelChanged,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, _selected),
                child: const Text('确定'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _hourField() {
    return SizedBox(
      width: 72,
      child: TextField(
        controller: _hour,
        keyboardType: TextInputType.number,
        maxLength: 2,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          counterText: '',
          hintText: '时',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _minuteField() {
    return SizedBox(
      width: 72,
      child: TextField(
        controller: _minute,
        keyboardType: TextInputType.number,
        maxLength: 2,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          counterText: '',
          hintText: '分',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}