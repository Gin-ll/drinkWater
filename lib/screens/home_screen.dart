import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../services/occurrence_calculator.dart';
import '../state/app_notifier.dart';
import '../utils/format.dart';
import '../utils/top_toast.dart';
import 'reminder_form_dialog.dart';

/// 首页：今日喝水时间轴 + 快捷标记
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<TodayEntry>> _future;
  late DateTime _day; // 当前查看的日期（仅日期部分）
  Timer? _ticker;

  late final AppNotifier _app;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppNotifier>();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _future = _load();
    // 状态变更（标记已喝、记录喝水、增删改等）时实时刷新时间轴
    _app.addListener(_onAppChanged);
    // 每分钟刷新状态（待提醒 → 未响应 等时间驱动的状态迁移）
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _reload());
  }

  @override
  void dispose() {
    _app.removeListener(_onAppChanged);
    _ticker?.cancel();
    super.dispose();
  }

  void _onAppChanged() {
    if (mounted) _reload();
  }

  Future<List<TodayEntry>> _load() async {
    final app = context.read<AppNotifier>();
    final list = await app.timelineFor(_day);
    // ignore: avoid_print
    debugPrint('[home] 时间轴 ${toDateString(_day)} 载入: ${list.map((e) => e.reminder?.title ?? '手动喝水').toList()}');
    return list;
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  bool get _isToday {
    final now = DateTime.now();
    return _day.year == now.year && _day.month == now.month && _day.day == now.day;
  }

  void _shiftDay(int delta) {
    setState(() {
      _day = _day.add(Duration(days: delta));
      _future = _load();
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _day = DateTime(now.year, now.month, now.day);
      _future = _load();
    });
  }

  Future<void> _recordDrink() async {
    final app = context.read<AppNotifier>();
    final id = await app.recordDrinkNow();
    if (mounted) {
      // P0-09：可撤销
      showTopToast(
        context,
        '已记录一杯水 💧',
        actionLabel: '撤销',
        onAction: () => app.deleteDrinkLog(id),
      );
      _reload();
    }
  }

  Future<void> _openAdd() async {
    final saved = await ReminderFormDialog.show(context);
    if (saved && mounted) {
      showTopToast(context, '提醒已保存');
      _reload();
    }
  }

  Future<void> _openEdit(Reminder reminder,
      {String? overriddenOn, TimeOfDay? initialTime}) async {
    final saved = await ReminderFormDialog.show(
      context,
      reminder: reminder,
      overriddenOn: overriddenOn,
      initialTime: initialTime,
    );
    if (saved && mounted) _reload();
  }

  /// 删除一条手动喝水记录（带确认）。
  Future<void> _deleteManualLog(TodayEntry entry) async {
    final log = entry.log;
    if (log == null) return;
    final app = context.read<AppNotifier>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除喝水记录'),
        content: const Text('确定删除这条喝水记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await app.deleteDrinkLog(log.id);
      if (mounted) _reload();
    }
  }

  /// 手动喝水记录可编辑：修改记录时间或删除。
  Future<void> _openEditManual(TodayEntry entry) async {
    final log = entry.log;
    if (log == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _ManualLogDialog(log: log),
    );
    _reload();
  }

  Future<void> _confirmDelete(Reminder r) async {
    final app = context.read<AppNotifier>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除提醒'),
        content: Text('确定删除「${r.title}」吗？相关喝水记录也会一并删除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await app.deleteReminder(r.id);
      if (mounted) _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('喝水'),
        actions: [
          IconButton(
            tooltip: '新建提醒',
            icon: const Icon(Icons.add),
            onPressed: _openAdd,
          ),
        ],
      ),
      body: Column(
        children: [
          _DateHeader(
            day: _day,
            isToday: _isToday,
            onPrev: () => _shiftDay(-1),
            onNext: () => _shiftDay(1),
            onToday: _goToday,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await app.refresh();
                _reload();
              },
              child: FutureBuilder<List<TodayEntry>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final entries = snapshot.data ?? const [];
                  if (entries.isEmpty) {
                    // P0-10 空状态：按场景提供文案 + 操作入口
                    final hasEnabled = app.reminders.any((r) => r.enabled);
                    if (_isToday) {
                      if (!hasEnabled) {
                        return _ThemedEmptyState(
                          icon: Icons.add_alarm,
                          title: '暂无启用中的喝水提醒',
                          subtitle: '设置你的第一条喝水提醒吧',
                          actionText: '添加提醒',
                          onAction: _openAdd,
                        );
                      }
                      return _ThemedEmptyState(
                        icon: Icons.local_drink,
                        title: '还没有喝水记录',
                        subtitle: '开始记录今天的第一杯水吧',
                        actionText: '喝一杯水',
                        onAction: _recordDrink,
                      );
                    }
                    return _ThemedEmptyState(
                      icon: Icons.water,
                      title: '暂无历史喝水记录',
                      subtitle: '这一天还没有喝水记录',
                      actionText: '回到今天',
                      onAction: _goToday,
                    );
                  }
                  // SlidableAutoCloseBehavior：保证同一时刻只允许一个卡片滑开
                  return SlidableAutoCloseBehavior(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        // 点击时间轴信息不打开编辑弹窗（编辑/删除均走左滑）
                        final tile = _TimelineTile(
                          entry: e,
                          occurDate: toDateString(_day),
                          canMark: _isToday, // 仅今天可标记已喝/记录喝水
                        );
                        // 手动喝水记录：左滑「编辑(改时间)/删除」
                        if (e.manual) {
                          return Slidable(
                            key: ValueKey(
                                'manual-${e.time.millisecondsSinceEpoch}'),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              extentRatio: 0.3,
                              children: [
                                SlidableAction(
                                  onPressed: (_) => _openEditManual(e),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: '编辑',
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                SlidableAction(
                                  onPressed: (_) => _deleteManualLog(e),
                                  backgroundColor: const Color(0xFFE5484D),
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete_outline,
                                  label: '删除',
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ],
                            ),
                            child: tile,
                          );
                        }
                        // 提醒记录：左滑「编辑/删除」；编辑携带当天生效时间与“仅当天”上下文
                        return Slidable(
                          key: ValueKey('tile-${e.reminder!.id}-${e.time.millisecondsSinceEpoch}'),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            extentRatio: 0.3,
                            children: [
                              SlidableAction(
                                onPressed: (_) => _openEdit(
                                  e.reminder!,
                                  overriddenOn: toDateString(_day),
                                  initialTime: TimeOfDay.fromDateTime(e.time),
                                ),
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: '编辑',
                                borderRadius: BorderRadius.circular(12),
                              ),
                              SlidableAction(
                                onPressed: (_) => _confirmDelete(e.reminder!),
                                backgroundColor: const Color(0xFFE5484D),
                                foregroundColor: Colors.white,
                                icon: Icons.delete_outline,
                                label: '删除',
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ],
                          ),
                          child: tile,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          // 仅「今天」视图在列表底部展示一键喝水按钮（定高 50，整合适中）
          if (_isToday)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _recordDrink,
                  icon: const Icon(Icons.local_drink),
                  label: const Text('喝水',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 首页顶部日期栏：可切换前一天/后一天，支持快速回到今天
class _DateHeader extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _DateHeader({
    required this.day,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: InkWell(
              onTap: isToday ? null : onToday,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  Text(
                    '${day.month}月${day.day}日 ${weekNames[day.weekday - 1]}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  isToday
                      ? Text('今天 · ${day.year}年', style: TextStyle(fontSize: 12, color: color))
                      : Text('${day.year}年 · 点击回到今天',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

/// 主题化空状态（P0-10）：图标 + 标题 + 副标题 + 操作按钮，跟随主题色。
class _ThemedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;

  const _ThemedEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // 保证空状态也能下拉刷新
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: color),
                ),
                const SizedBox(height: 14),
                Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final TodayEntry entry;
  final String occurDate;
  final bool canMark;

  const _TimelineTile({
    required this.entry,
    required this.occurDate,
    required this.canMark,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppNotifier>();
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final time = entry.time;

    // 状态判定（需求二值化）：有「已喝水」记录 → 已喝水；其余一律视为未喝水；未来时刻显示待提醒
    final drank = entry.log?.isDrank == true;
    String statusText;
    Color statusColor;
    IconData statusIcon;
    if (entry.manual || drank) {
      statusText = '已喝水';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (time.isAfter(now)) {
      statusText = '待提醒';
      statusColor = colorScheme.primary;
      statusIcon = Icons.alarm;
    } else {
      statusText = '未喝水';
      statusColor = Colors.orange;
      statusIcon = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      // 点击时间轴信息不打开编辑弹窗（编辑/删除走左滑）
      child: IntrinsicHeight(
        // IntrinsicHeight 保证竖直时间线（Column 内的 Expanded）有界，避免 ListView 无界高度报错
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              SizedBox(
                width: 56,
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text(
                    formatTime(time.hour, time.minute),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(
                width: 26,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _dot(colorScheme.primary),
                    ),
                    Expanded(child: Container(width: 2, color: Colors.black12)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.manual ? '喝水记录' : entry.reminder!.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(text: statusText, color: statusColor, icon: statusIcon),
                            ],
                          ),
                          // 需求：卡片只保留 标题 + 状态（左侧另有时间）；无副标题行
                          // 未喝水（含未来待提醒）时展示一个「已喝」图标；仅今天可标记，其他日期点击仅提示不改状态
                          if (!entry.manual && !drank) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                tooltip: '标记已喝',
                                iconSize: 28,
                                onPressed: () async {
                                  if (canMark) {
                                    final id = await app.mark(
                                      reminderId: entry.reminder!.id,
                                      isDrank: true,
                                      occurDate: occurDate,
                                    );
                                    // P0-09：可撤销
                                    if (context.mounted) {
                                      showTopToast(
                                        context,
                                        '已标记已喝',
                                        actionLabel: '撤销',
                                        onAction: () => app.deleteDrinkLog(id),
                                      );
                                    }
                                  } else {
                                    showTopToast(context, '仅今天可标记已喝');
                                  }
                                },
                                // 杯中有水的图标，颜色跟随主题
                                icon: Icon(Icons.local_drink, color: colorScheme.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _StatusChip({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// 手动喝水记录的编辑弹窗：可修改记录时间或删除该记录。
class _ManualLogDialog extends StatefulWidget {
  final DrinkLog log;

  const _ManualLogDialog({required this.log});

  @override
  State<_ManualLogDialog> createState() => _ManualLogDialogState();
}

class _ManualLogDialogState extends State<_ManualLogDialog> {
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final t = widget.log.actionTime;
    _time = TimeOfDay(hour: t.hour, minute: t.minute);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker24(context, _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final base = widget.log.actionTime;
    await context.read<AppNotifier>().updateManualLogTime(
          widget.log.id,
          DateTime(base.year, base.month, base.day, _time.hour, _time.minute),
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await context.read<AppNotifier>().deleteDrinkLog(widget.log.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('喝水记录'),
      content: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.schedule),
        title: const Text('记录时间'),
        trailing: Text(
          formatTime(_time.hour, _time.minute),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onTap: _pickTime,
      ),
      actions: [
        TextButton(
          onPressed: _delete,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('删除'),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: _save, child: const Text('保存')),
      ],
    );
  }
}