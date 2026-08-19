import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'services/notification_service.dart';
import 'state/app_notifier.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final timezoneInfo = await FlutterTimezone.getLocalTimezone();
  NotificationService.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

  final notifier = AppNotifier();
  await notifier.init();

  runApp(DrinkWaterApp(notifier: notifier));
}

class DrinkWaterApp extends StatelessWidget {
  final AppNotifier notifier;

  const DrinkWaterApp({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: notifier,
      child: Consumer<AppNotifier>(
        builder: (context, app, _) {
          return MaterialApp(
            title: '喝水提醒',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(app.themeColor),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

/// 底部三标签框架
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // 点击通知主体时回到首页标签
    NotificationService.onOpenHome = (_) {
      if (mounted && _index != 0) setState(() => _index = 0);
    };
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}