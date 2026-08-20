import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/app_notifier.dart';
import '../utils/format.dart';
import 'reminder_form_dialog.dart';

/// 提醒页：展示全部提醒规则（含暂停/一次性已发生），支持新建/编辑/暂停/删除。
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late final AppNotifier _app;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppNotifier>();
    _app.addListener(_onChanged);
  }

  @override
  void dispose() {
    _app.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openAdd() async {
    await ReminderFormDialog.show(context, manageMode: true);
  }

  Future<void> _openDetail(Reminder r) async {
    await ReminderFormDialog.show(context, reminder: r, manageMode: true);
  }

  String _statusText(Reminder r) {
    if (!r.enabled) return '已暂停';
    if (r.repeatType == repeatOnce &&
        r.triggerAt != null &&
        !DateTime.fromMillisecondsSinceEpoch(r.triggerAt!).isAfter(DateTime.now())) {
      return '已发生';
    }
    return '已开启';
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final reminders = _app.reminders;
    final sorted = [...reminders]..sort((a, b) {
        if (a.enabled != b.enabled) return a.enabled ? -1 : 1;
        return a.createdAt.compareTo(b.createdAt);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('提醒'),
        actions: [
          IconButton(
            tooltip: '添加提醒',
            icon: const Icon(Icons.add),
            onPressed: _openAdd,
          ),
        ],
      ),
      body: sorted.isEmpty
          ? _empty(context)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final r = sorted[i];
                final status = _statusText(r);
                final isGrey = status != '已开启';
                final statusColor =
                    status == '已开启' ? color.primary : Colors.grey;
                return _RuleCard(
                  reminder: r,
                  status: status,
                  statusColor: statusColor,
                  enabled: r.enabled,
                  isGrey: isGrey,
                  onTap: () => _openDetail(r),
                );
              },
            ),
    );
  }

  Widget _empty(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Center(
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
            child: Icon(Icons.alarm_add, size: 34, color: color),
          ),
          const SizedBox(height: 14),
          const Text('暂无提醒规则',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('点击右上角 + 添加第一条喝水提醒',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final Reminder reminder;
  final String status;
  final Color statusColor;
  final bool enabled;
  final bool isGrey;
  final VoidCallback onTap;

  const _RuleCard({
    required this.reminder,
    required this.status,
    required this.statusColor,
    required this.enabled,
    required this.isGrey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Opacity(
      opacity: isGrey ? 0.62 : 1,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Text(drinkEmoji(reminder.hour), style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reminder.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(formatRule(reminder),
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}