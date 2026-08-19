import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../services/occurrence_calculator.dart';
import '../state/app_notifier.dart';
import '../utils/format.dart';

/// 统计页：周/月视图的柱状图、折线图与日历钻取
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _weekMode = true;
  DateTime _anchor = DateTime.now();
  Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 当前统计区间（开区间 end 为区间后一天）
  (DateTime, DateTime) get _range {
    if (_weekMode) {
      final weekStart = _anchor.subtract(Duration(days: _anchor.weekday - 1));
      return (weekStart, weekStart.add(const Duration(days: 7)));
    }
    return (
      DateTime(_anchor.year, _anchor.month, 1),
      DateTime(_anchor.year, _anchor.month + 1, 1),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final app = context.read<AppNotifier>();
    final (start, end) = _range;
    final counts = await app.drankCountsByDay(start, end);
    if (mounted) {
      setState(() {
        _counts = counts;
        _loading = false;
      });
    }
  }

  void _shift(int step) {
    setState(() {
      _anchor = _weekMode
          ? _anchor.add(Duration(days: 7 * step))
          : DateTime(_anchor.year, _anchor.month + step, 1);
    });
    _load();
  }

  Future<void> _showDayDetail(String date) async {
    final app = context.read<AppNotifier>();
    final logs = await app.logsOfDay(date);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _DayDetailSheet(date: date, logs: logs),
    );
  }

  String get _rangeLabel {
    final (start, end) = _range;
    final endDay = end.subtract(const Duration(days: 1));
    if (_weekMode) return '${start.month}月${start.day}日 - ${endDay.month}月${endDay.day}日';
    return '${_anchor.year}年${_anchor.month}月';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('周')),
                    ButtonSegment(value: false, label: Text('月')),
                  ],
                  selected: {_weekMode},
                  onSelectionChanged: (s) {
                    setState(() => _weekMode = s.first);
                    _load();
                  },
                ),
                // 区间标签弹性伸缩 + 省略号，避免窄屏/长文案溢出
                Expanded(
                  child: Center(
                    child: Text(
                      _rangeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
                IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else ...[
              _SummaryCard(counts: _counts, weekMode: _weekMode),
              const SizedBox(height: 16),
              Text('每日喝水次数（柱状图）', style: _sectionStyle()),
              const SizedBox(height: 8),
              _BarChartCard(counts: _counts, days: _daysOfRange),
              const SizedBox(height: 16),
              Text('每日喝水趋势（折线图）', style: _sectionStyle()),
              const SizedBox(height: 8),
              _LineChartCard(counts: _counts, days: _daysOfRange),
              const SizedBox(height: 16),
              Text('日历（点击查看当天明细）', style: _sectionStyle()),
              const SizedBox(height: 8),
              _CalendarCard(
                anchor: _anchor,
                counts: _counts,
                onTapDay: (date) => _showDayDetail(toDateString(date)),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<DateTime> get _daysOfRange {
    final (start, end) = _range;
    final days = <DateTime>[];
    for (var d = start; d.isBefore(end); d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    return days;
  }

  TextStyle _sectionStyle() {
    return const TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, int> counts;
  final bool weekMode;

  const _SummaryCard({required this.counts, required this.weekMode});

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final maxDay = counts.values.isEmpty ? 0 : counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(label: weekMode ? '本周喝水' : '本月喝水', value: '$total 次'),
            _StatItem(label: '单日最高', value: '$maxDay 次'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final Map<String, int> counts;
  final List<DateTime> days;

  const _BarChartCard({required this.counts, required this.days});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final maxVal = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final groups = <BarChartGroupData>[
      for (var i = 0; i < days.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (counts[toDateString(days[i])] ?? 0).toDouble(),
              width: days.length > 31 ? 3 : 8,
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ],
        ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: (maxVal == 0 ? 1 : maxVal).toDouble(),
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxVal == 0 ? 1 : maxVal).toDouble(),
                getDrawingHorizontalLine: (_) => const FlLine(color: Colors.black12, strokeWidth: 1),
              ),
              titlesData: _barTitles(maxVal),
              barGroups: groups,
            ),
          ),
        ),
      ),
    );
  }

  FlTitlesData _barTitles(int maxVal) {
    // 显示有限数量的横轴标签，避免过密
    final step = days.length > 16 ? 2 : 1;
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: (maxVal == 0 ? 1 : maxVal).toDouble(),
          getTitlesWidget: (v, meta) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: step.toDouble(),
          getTitlesWidget: (v, meta) {
            final i = v.toInt();
            if (i < 0 || i >= days.length) return const SizedBox.shrink();
            if (i % step != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${(days[i].month)}/${days[i].day}', style: const TextStyle(fontSize: 9)),
            );
          },
        ),
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  final Map<String, int> counts;
  final List<DateTime> days;

  const _LineChartCard({required this.counts, required this.days});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final maxVal = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final spots = <FlSpot>[
      for (var i = 0; i < days.length; i++)
        FlSpot(i.toDouble(), (counts[toDateString(days[i])] ?? 0).toDouble()),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (days.length - 1).toDouble(),
              minY: 0,
              maxY: (maxVal == 0 ? 1 : maxVal).toDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 2,
                  dotData: FlDotData(show: days.length <= 31, getDotPainter: (s, p, b, i) =>
                      FlDotCirclePainter(radius: 3, color: color)),
                ),
              ],
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: _lineTitles(maxVal),
            ),
          ),
        ),
      ),
    );
  }

  FlTitlesData _lineTitles(int maxVal) {
    final step = days.length > 16 ? 2 : 1;
    return FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: (maxVal == 0 ? 1 : maxVal).toDouble())),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: step.toDouble(),
          getTitlesWidget: (v, meta) {
            final i = v.toInt();
            if (i < 0 || i >= days.length) return const SizedBox.shrink();
            if (i % step != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${days[i].day}', style: const TextStyle(fontSize: 9)),
            );
          },
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime anchor;
  final Map<String, int> counts;
  final ValueChanged<DateTime> onTapDay;

  const _CalendarCard({required this.anchor, required this.counts, required this.onTapDay});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final first = DateTime(anchor.year, anchor.month, 1);
    final daysInMonth = DateTime(anchor.year, anchor.month + 1, 0).day;
    final leadingBlanks = first.weekday - 1; // 周一开头
    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(anchor.year, anchor.month, d);
      final cnt = counts[toDateString(date)] ?? 0;
      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onTapDay(date),
          child: Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: cnt == 0 ? Colors.transparent : color.withValues(alpha: (0.12 + 0.18 * (cnt.clamp(0, 4) / 4)).toDouble()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$d', style: const TextStyle(fontSize: 12)),
                Text(cnt > 0 ? '$cnt' : '', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [for (final w in weekNames) Expanded(child: Center(child: Text(w, style: const TextStyle(fontSize: 12, color: Colors.grey))))],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: cells,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('次数越多颜色越深', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDetailSheet extends StatelessWidget {
  final String date;
  final List<DrinkLog> logs;

  const _DayDetailSheet({required this.date, required this.logs});

  @override
  Widget build(BuildContext context) {
    final sorted = [...logs]..sort((a, b) => a.actionTime.compareTo(b.actionTime));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatDate(parseDate(date)), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (sorted.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('当天没有喝水记录', style: TextStyle(color: Colors.grey))),
              )
            else
              ...sorted.map((log) {
                final t = log.actionTime;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(log.isDrank ? Icons.water_drop : Icons.close, color: log.isDrank ? Colors.green : Colors.orange),
                  title: Text(log.isDrank ? '已喝水' : '未喝水'),
                  subtitle: Text('${formatTime(t.hour, t.minute)} 记录'),
                  trailing: log.reminderId == null ? null : Text('提醒#${log.reminderId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                );
              }),
          ],
        ),
      ),
    );
  }
}