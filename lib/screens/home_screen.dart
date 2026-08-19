import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../services/occurrence_calculator.dart';
import '../state/app_notifier.dart';
import '../utils/format.dart';
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _future = _load();
    // 每分钟刷新状态（待提醒 → 未响应 等时间驱动的状态迁移）
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _reload());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
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
    await app.recordDrinkNow();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已记录一杯水 💧')),
      );
      _reload();
    }
  }

  Future<void> _openAdd() async {
    final saved = await ReminderFormDialog.show(context);
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提醒已保存')),
      );
      _reload();
    }
  }

  Future<void> _openEdit(Reminder reminder) async {
    final saved = await ReminderFormDialog.show(context, reminder: reminder);
    if (saved && mounted) _reload();
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
                    return const _EmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return _TimelineTile(
                        entry: e,
                        occurDate: toDateString(_day),
                        onTap: e.manual ? null : () => _openEdit(e.reminder!),
                        onLongPress: e.manual ? null : () => _confirmDelete(e.reminder!),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          // 仅「今天」视图在列表底部展示一键喝水按钮
          if (_isToday)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _recordDrink,
                  icon: const Icon(Icons.water_drop),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('喝水', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // 保证空状态也能下拉刷新
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop_outlined, size: 64, color: Colors.blueGrey),
                SizedBox(height: 12),
                Text('当天暂无喝水提醒\n点右上角 + 新建', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
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
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _TimelineTile({
    required this.entry,
    required this.occurDate,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppNotifier>();
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final time = entry.time;

    // 状态判定
    String statusText;
    Color statusColor;
    IconData statusIcon;
    if (entry.log != null) {
      final drank = entry.log!.isDrank;
      statusText = drank ? '已喝水' : '未喝水';
      statusColor = drank ? Colors.green : Colors.orange;
      statusIcon = drank ? Icons.check_circle : Icons.cancel;
    } else if (time.isAfter(now)) {
      if (entry.inDnd) {
        statusText = '免打扰';
        statusColor = Colors.blueGrey;
        statusIcon = Icons.nightlight_round;
      } else {
        statusText = '待提醒';
        statusColor = colorScheme.primary;
        statusIcon = Icons.alarm;
      }
    } else {
      if (entry.inDnd) {
        statusText = '已跳过';
        statusColor = Colors.blueGrey;
        statusIcon = Icons.nightlight_round;
      } else {
        statusText = '未响应';
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        // IntrinsicHeight 保证竖直时间线（Column 内的 Expanded）有界，避免 ListView 无界高度报错
        child: IntrinsicHeight(
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
                      child: _dot(entry.log?.isDrank == true ? Colors.green : colorScheme.primary),
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
                          if (!entry.manual) ...[
                            const SizedBox(height: 4),
                            Text(
                              formatRule(entry.reminder!),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (entry.reminder!.body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                entry.reminder!.body,
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _ActionButton(
                                  label: '已喝',
                                  icon: Icons.water_drop,
                                  color: Colors.green,
                                  onPressed: () => app.mark(
                                    reminderId: entry.reminder!.id,
                                    isDrank: true,
                                    occurDate: occurDate,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  label: '未喝',
                                  icon: Icons.close,
                                  color: Colors.orange,
                                  onPressed: () => app.mark(
                                    reminderId: entry.reminder!.id,
                                    isDrank: false,
                                    occurDate: occurDate,
                                  ),
                                ),
                              ],
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({required this.label, required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
    );
  }
}