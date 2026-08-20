import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../services/occurrence_calculator.dart';
import '../state/app_notifier.dart';
import '../utils/format.dart';
import '../utils/top_toast.dart';

/// 新建 / 修改提醒的弹窗
///
/// - 传入 [reminder] 为修改模式，否则为新建
/// - [overriddenOn]（YYYY-MM-DD）表示从某天时间轴发起的编辑：默认「仅当天调整」，
///   改动时间只作用于该日期，不改变未来提醒；关闭开关则永久修改基规则。
/// - [initialTime] 为发起编辑时该行当天生效的时间（含按天调整）。
/// - 保存成功会 `Navigator.pop(context, true)`；取消返回 false
class ReminderFormDialog extends StatefulWidget {
  final Reminder? reminder;
  final String? overriddenOn;
  final TimeOfDay? initialTime;

  const ReminderFormDialog({super.key, this.reminder, this.overriddenOn, this.initialTime});

  /// 便捷打开方式：返回是否保存成功
  static Future<bool> show(
    BuildContext context, {
    Reminder? reminder,
    String? overriddenOn,
    TimeOfDay? initialTime,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ReminderFormDialog(
        reminder: reminder,
        overriddenOn: overriddenOn,
        initialTime: initialTime,
      ),
    );
    return saved ?? false;
  }

  @override
  State<ReminderFormDialog> createState() => _ReminderFormDialogState();
}

class _ReminderFormDialogState extends State<ReminderFormDialog> {
  late final TextEditingController _title;
  late int _repeatType;
  late TimeOfDay _time;
  late List<int> _weekdays;
  int? _monthDay;
  DateTime? _oneTimeDate;
  late bool _onlyThisDay; // 从某天时间轴编辑时默认「仅当天调整」

  bool get _isEdit => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    // 标题默认「喝水提醒」，不手动修改即为该标题
    _title = TextEditingController(text: r?.title ?? '喝水提醒');
    _repeatType = r?.repeatType ?? repeatDaily;
    // 发起编辑时的当天生效时间（含按天调整）
    _time = widget.initialTime ??
        TimeOfDay(hour: r?.hour ?? 8, minute: r?.minute ?? 0);
    _weekdays = r == null ? [DateTime.now().weekday] : AppDatabase.decodeWeekdays(r.weekdays);
    _monthDay = r?.monthDay ?? DateTime.now().day;
    // 一次性提醒日期默认今天
    _oneTimeDate = (r != null && r.triggerAt != null)
        ? DateTime.fromMillisecondsSinceEpoch(r.triggerAt!)
        : DateTime.now();
    _onlyThisDay = widget.overriddenOn != null;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker24(context, _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _oneTimeDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _oneTimeDate = picked);
  }

  Future<void> _pickMonthDay() async {
    final current = _monthDay ?? DateTime.now().day;
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('选择每月日期'),
        children: [
          SizedBox(
            height: 320,
            width: 300,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 31,
              itemBuilder: (ctx, i) {
                final day = i + 1;
                return ChoiceChip(
                  label: Text('$day'),
                  selected: day == current,
                  onSelected: (_) => Navigator.pop(ctx, day),
                );
              },
            ),
          ),
        ],
      ),
    );
    if (picked != null) setState(() => _monthDay = picked);
  }

  void _setWeekday(int weekday, bool selected) {
    setState(() {
      if (selected) {
        if (!_weekdays.contains(weekday)) _weekdays.add(weekday);
        _weekdays.sort();
      } else {
        _weekdays.remove(weekday);
      }
    });
  }

  void _toast(String msg) {
    showTopToast(context, msg);
  }

  /// 同刻去重提示：若当天该时刻已有启用提醒，弹出「是否仍要添加」确认。
  /// 返回 true 表示可以继续保存。
  Future<bool> _ensureNoTimeConflict(int hour, int minute) async {
    final app = context.read<AppNotifier>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hasConflict = hasConflictAtTime(
      app.reminders,
      hour,
      minute,
      today,
      excludeId: _isEdit ? widget.reminder!.id : null,
    );
    if (!hasConflict) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重复提醒'),
        content: Text('当天 ${formatTime(hour, minute)} 已有喝水提醒\n是否仍要添加？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('仍要添加')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _save() async {
    final app = context.read<AppNotifier>();
    final nav = Navigator.of(context);
    final title = _title.text.trim();
    if (title.isEmpty) {
      _toast('请填写标题');
      return;
    }
    if (_repeatType == repeatOnce) {
      final date = _oneTimeDate;
      if (date == null) {
        _toast('请选择日期');
        return;
      }
      final triggerAt = DateTime(date.year, date.month, date.day, _time.hour, _time.minute);
      if (!triggerAt.isAfter(DateTime.now())) {
        _toast('一次性提醒时间必须晚于当前时间');
        return;
      }
      // 同刻去重提示
      if (!await _ensureNoTimeConflict(triggerAt.hour, triggerAt.minute)) return;
      if (_isEdit) {
        await app.updateReminder(widget.reminder!.id,
            title: title, body: widget.reminder!.body,
            repeatType: repeatOnce, hour: 0, minute: 0,
            triggerAt: triggerAt);
      } else {
        await app.addReminder(
            title: title, body: '',
            repeatType: repeatOnce, hour: 0, minute: 0,
            triggerAt: triggerAt);
      }
    } else {
      if (_repeatType == repeatWeekly && _weekdays.isEmpty) {
        _toast('每周循环请至少选择一天');
        return;
      }
      // 提醒时间不能早于当前时间
      final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
      if (_time.hour * 60 + _time.minute < nowMin) {
        _toast('提醒时间不能早于当前时间');
        return;
      }
      // 同刻去重提示
      if (!await _ensureNoTimeConflict(_time.hour, _time.minute)) return;
      if (_isEdit) {
        final rid = widget.reminder!.id;
        final baseHour = widget.reminder!.hour;
        final baseMinute = widget.reminder!.minute;
        final ov = widget.overriddenOn;
        if (ov != null && _onlyThisDay) {
          // 仅当天调整：基规则时间保持不变（未来提醒不变），只写当天的临时时间
          await app.updateReminder(rid,
              title: title, body: widget.reminder!.body,
              repeatType: _repeatType, hour: baseHour, minute: baseMinute,
              weekdays: _weekdays, monthDay: _monthDay);
          await app.setDayOverride(rid, ov, _time.hour, _time.minute,
              baseHour: baseHour, baseMinute: baseMinute);
        } else {
          // 永久修改：按新时间更新基规则，并清除该天的临时调整以免互相覆盖
          await app.updateReminder(rid,
              title: title, body: widget.reminder!.body,
              repeatType: _repeatType, hour: _time.hour, minute: _time.minute,
              weekdays: _weekdays, monthDay: _monthDay);
          if (ov != null) await app.clearDayOverride(rid, ov);
        }
      } else {
        await app.addReminder(
            title: title, body: '',
            repeatType: _repeatType, hour: _time.hour, minute: _time.minute,
            weekdays: _weekdays, monthDay: _monthDay);
      }
    }
    if (mounted) nav.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('yyyy年M月d日');
    return AlertDialog(
      title: Text(
        _isEdit ? '编辑提醒' : '新建提醒',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                // 默认「喝水提醒」：点击聚焦时全选，用户输入即替换为自定义内容
                onTap: () {
                  if (_title.text == '喝水提醒') {
                    _title.selection =
                        TextSelection(baseOffset: 0, extentOffset: _title.text.length);
                  }
                },
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '例如：喝水提醒',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: repeatOnce, label: Text('仅一次')),
                  ButtonSegment(value: repeatDaily, label: Text('每天')),
                  ButtonSegment(value: repeatWeekly, label: Text('每周')),
                  ButtonSegment(value: repeatMonthly, label: Text('每月')),
                ],
                selected: {_repeatType},
                onSelectionChanged: (s) => setState(() => _repeatType = s.first),
              ),
              if (widget.overriddenOn != null) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('仅当天调整', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('只改变所选日期，不影响未来提醒', style: TextStyle(fontSize: 11)),
                  value: _onlyThisDay,
                  onChanged: (v) => setState(() => _onlyThisDay = v),
                ),
              ],
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.schedule),
                title: const Text('提醒时间'),
                trailing: Text(
                  formatTime(_time.hour, _time.minute),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onTap: _pickTime,
              ),
              if (_repeatType == repeatOnce)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.event),
                  title: const Text('提醒日期'),
                  trailing: Text(
                    _oneTimeDate == null ? '请选择' : dateFmt.format(_oneTimeDate!),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onTap: _pickDate,
                ),
              if (_repeatType == repeatWeekly) ...[
                const SizedBox(height: 4),
                const Text('每周重复（至少选一天）', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      FilterChip(
                        label: Text(weekNames[d - 1]),
                        visualDensity: VisualDensity.compact,
                        selected: _weekdays.contains(d),
                        onSelected: (v) => _setWeekday(d, v),
                      ),
                  ],
                ),
              ],
              if (_repeatType == repeatMonthly)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('每月日期'),
                  trailing: Text(
                    '${_monthDay ?? '?'} 号（当月不足取月末）',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onTap: _pickMonthDay,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}