import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';
import '../state/app_notifier.dart';
import '../utils/format.dart';
import '../utils/top_toast.dart';
import '../theme.dart';

/// 设置（我的）页：主题色 / 免打扰 / 小米适配引导 / 关于
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickDndTime({required bool isStart}) async {
    final app = context.read<AppNotifier>();
    final current = isStart ? app.dndStart : app.dndEnd;
    final parts = current.split(':');
    final initial = TimeOfDay(hour: int.tryParse(parts[0]) ?? 22, minute: int.tryParse(parts[1]) ?? 0);
    final picked = await showTimePicker24(context, initial);
    if (picked == null) return;
    final value = formatTime(picked.hour, picked.minute);
    await app.setDnd(
      enabled: app.dndEnabled,
      start: isStart ? value : app.dndStart,
      end: isStart ? app.dndEnd : value,
    );
  }

  Future<void> _invoke(String method) async {
    try {
      await NotificationService.systemChannel.invokeMethod<void>(method);
    } catch (_) {
      if (mounted) {
        showTopToast(context, '无法打开系统设置，请手动前往系统设置操作');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppNotifier>();
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('外观'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('主题色'),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: themeColorBlue,
                    label: Text('蓝色'),
                    icon: Icon(Icons.circle, size: 14, color: Color(0xFF5B8DEF)),
                  ),
                  ButtonSegment(
                    value: themeColorGreen,
                    label: Text('绿色'),
                    icon: Icon(Icons.circle, size: 14, color: Color(0xFF4BBC8C)),
                  ),
                  ButtonSegment(
                    value: themeColorYellow,
                    label: Text('黄色'),
                    icon: Icon(Icons.circle, size: 14, color: Color(0xFFFFC457)),
                  ),
                ],
                selected: {app.themeColor},
                onSelectionChanged: (s) => app.setThemeColor(s.first),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('免打扰'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.nightlight_round),
                  title: const Text('开启免打扰'),
                  subtitle: const Text('时段内提醒完全跳过，不通知、不震动、不记录'),
                  value: app.dndEnabled,
                  onChanged: (v) => app.setDnd(enabled: v),
                ),
                if (app.dndEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('起止时间'),
                    subtitle: Text('${app.dndStart} – ${app.dndEnd}（支持跨午夜）'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDndTimePicker(app),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('小米适配（手环保真链路）'),
          Card(
            child: Column(
              children: [
                _GuideItem(
                  icon: Icons.notifications_active_outlined,
                  title: '通知权限',
                  subtitle: '允许本 App 发送通知',
                  action: () => _invoke('openAppNotificationSettings'),
                  statusFuture: NotificationService.hasNotificationsPermission(),
                ),
                _GuideItem(
                  icon: Icons.alarm_on,
                  title: '精确闹钟授权',
                  subtitle: '保证到点准时提醒',
                  action: () => _invoke('openExactAlarmSettings'),
                  statusFuture: NotificationService.hasExactAlarmPermission(),
                ),
                _GuideItem(
                  icon: Icons.battery_saver,
                  title: '电池优化 → 无限制',
                  subtitle: '避免后台被杀导致提醒丢失',
                  action: () => _invoke('openBatteryOptimizationSettings'),
                  statusFuture: app.isBatteryOptimizationIgnored(),
                ),
                _GuideItem(
                  icon: Icons.rocket_launch_outlined,
                  title: '自启动',
                  subtitle: 'MIUI/澎湃OS 需允许自启动（尽量直达应用详情页）',
                  action: () => _invoke('openAppDetailsForAutostart'),
                ),
                const ListTile(
                  leading: Icon(Icons.watch_outlined),
                  title: Text('小米运动健康设置'),
                  subtitle: Text('1. 绑定手环\n2. 消息通知中开启「喝水提醒」\n3. 确认手环未开勿扰'),
                  isThreeLine: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('排查顺序（为什么不震动）'),
          Card(
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '手机不响：通知渠道/音量 → 精确闹钟 → 电池优化 → 自启动\n'
                '手机响但手环不震：小米运动健康消息通知开关 → 手环勿扰 → 通知权限',
                style: TextStyle(fontSize: 13, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('关于'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('喝水提醒'),
              subtitle: const Text('版本 1.0.0'),
              trailing: const Text('本地存储 · 无需账号', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showDndTimePicker(AppNotifier app) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('免打扰时段', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('开始'),
                trailing: Text(app.dndStart, style: const TextStyle(fontSize: 16)),
                onTap: () { Navigator.pop(ctx); _pickDndTime(isStart: true); },
              ),
              ListTile(
                leading: const Icon(Icons.stop_circle_outlined),
                title: const Text('结束'),
                trailing: Text(app.dndEnd, style: const TextStyle(fontSize: 16)),
                onTap: () { Navigator.pop(ctx); _pickDndTime(isStart: false); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey)),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback action;
  final Future<bool>? statusFuture;

  const _GuideItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    this.statusFuture,
  });

  @override
  Widget build(BuildContext context) {
    if (statusFuture == null) {
      return ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline, color: Colors.grey, size: 16),
            Icon(Icons.chevron_right),
          ],
        ),
        onTap: action,
      );
    }
    return FutureBuilder<bool>(
      future: statusFuture,
      builder: (context, snap) {
        final ok = snap.data ?? false;
        return ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ok
                  ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                  : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: action,
        );
      },
    );
  }
}