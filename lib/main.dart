import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import 'data/app_database.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'services/notification_service.dart';
import 'state/app_notifier.dart';
import 'theme.dart';

/// 每日重排后台任务：即使不打开 App，也会由系统调度执行，把「今天」的闹钟排上。
/// 解决「仅当天设闹钟」跨天不打开即不响的问题。
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[workmanager] 后台任务执行: $task');
    try {
      if (task == 'dailyRearm') {
        await NotificationService.init();
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        NotificationService.setLocalLocation(tz.getLocation(tzInfo.identifier));
        final db = await openAppDatabase();
        await NotificationService.rescheduleAll(db);
        await db.close();
        debugPrint('[workmanager] 当天闹钟已重排完成');
      }
    } catch (e) {
      debugPrint('[workmanager] 重排异常: $e');
    }
    return true;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final timezoneInfo = await FlutterTimezone.getLocalTimezone();
  NotificationService.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

  // 每日自动重排当天闹钟（周期约 24h，规避“不打开 App 则不响”）
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    'dailyRearm',
    'dailyRearm',
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(hours: 2),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );

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
            // 全中文界面：内置组件（日期/时间选择器等）也使用中文
            locale: const Locale('zh'),
            supportedLocales: const [Locale('zh'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    // 点击通知主体时回到首页标签
    NotificationService.onOpenHome = (_) {
      if (mounted && _index != 0) setState(() => _index = 0);
    };
    // P0-07：回到前台时校准调度（用户改系统时间/时区后，按新本地时间重算当天闹钟）
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (mounted) context.read<AppNotifier>().recalibrate();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
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