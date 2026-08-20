import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../services/occurrence_calculator.dart';
import '../state/app_notifier.dart';
import '../utils/format.dart';

/// 统计页：周/月/年 三种时间范围，柱状图与折线图合并展示并可切换
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

enum _RangeMode { week, month }

enum _ChartKind { bar, line }

class _StatsScreenState extends State<StatsScreen> {
  _RangeMode _mode = _RangeMode.week; // 默认本周
  _ChartKind _chart = _ChartKind.bar;
  DateTime _anchor = DateTime.now(); // 周=该周任一日期 / 月=某月
  Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 当前统计区间（开区间 end 为区间后一天）
  (DateTime, DateTime) get _range {
    switch (_mode) {
      case _RangeMode.week:
        final weekStart = _anchor.subtract(Duration(days: _anchor.weekday - 1));
        return (weekStart, weekStart.add(const Duration(days: 7)));
      case _RangeMode.month:
        return (
          DateTime(_anchor.year, _anchor.month, 1),
          DateTime(_anchor.year, _anchor.month + 1, 1),
        );
    }
  }

  List<DateTime> get _days {
    final (start, end) = _range;
    final days = <DateTime>[];
    for (var d = start; d.isBefore(end); d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    return days;
  }

  String get _rangeLabel {
    final (start, end) = _range;
    return switch (_mode) {
      // 周：只显示第几周，不需要范围
      _RangeMode.week => '第${_isoWeekNumber(start)}周',
      _RangeMode.month => '${_anchor.year}年${_anchor.month}月',
    };
  }

  /// ISO 8601 年第几周
  int _isoWeekNumber(DateTime date) {
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final yearStart = DateTime(thursday.year, 1, 1);
    return (thursday.difference(yearStart).inDays / 7).floor() + 1;
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
      _anchor = switch (_mode) {
        _RangeMode.week => _anchor.add(Duration(days: 7 * step)),
        _RangeMode.month => DateTime(_anchor.year, _anchor.month + step, 1),
      };
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 顶部：周期切换 | ◀ 区间时间 ▶（时间位于两个切换按钮中间）
            Row(
              children: [
                SegmentedButton<_RangeMode>(
                  segments: const [
                    ButtonSegment(value: _RangeMode.week, label: Text('周')),
                    ButtonSegment(value: _RangeMode.month, label: Text('月')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) {
                    setState(() => _mode = s.first);
                    _load();
                  },
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => _shift(-1),
                        icon: const Icon(Icons.chevron_left),
                        tooltip: '上一区间',
                      ),
                      Flexible(
                        child: Text(
                          _rangeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shift(1),
                        icon: const Icon(Icons.chevron_right),
                        tooltip: '下一区间',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else ...[
              _SummaryCard(counts: _counts, mode: _mode),
              const SizedBox(height: 16),
              // 每日喝水统计：柱状/折线合并卡片，右上角切换
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          const Text('每日喝水统计',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          SegmentedButton<_ChartKind>(
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: _ChartKind.bar, icon: Icon(Icons.bar_chart, size: 18)),
                              ButtonSegment(value: _ChartKind.line, icon: Icon(Icons.show_chart, size: 18)),
                            ],
                            selected: {_chart},
                            onSelectionChanged: (s) => setState(() => _chart = s.first),
                          ),
                        ],
                      ),
                    ),
                    // 月/年视图下图表可横向滚动
                    LayoutBuilder(
                      builder: (context, cons) {
                        final days = _days;
                        final cellWidth = _mode == _RangeMode.month ? 36.0 : 20.0;
                        final totalWidth = (days.length * cellWidth)
                            .clamp(cons.maxWidth - 32, double.infinity)
                            .toDouble();
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: totalWidth,
                            height: 200,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                              child: _chart == _ChartKind.bar
                                  ? _BarChart(
                                      counts: _counts,
                                      days: days,
                                      barWidth: 10,
                                      mode: _mode,
                                    )
                                  : _LineChart(
                                      counts: _counts,
                                      days: days,
                                      showDots: days.length <= 40,
                                      mode: _mode,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('日历', style: _sectionStyle()),
              const SizedBox(height: 8),
              _CalendarCard(
                anchor: _anchor,
                mode: _mode,
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

  TextStyle _sectionStyle() {
    return const TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, int> counts;
  final _RangeMode mode;

  const _SummaryCard({required this.counts, required this.mode});

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final maxDay = counts.values.isEmpty ? 0 : counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final label = switch (mode) {
      _RangeMode.week => '本周喝水',
      _RangeMode.month => '本月喝水',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(label: label, value: '$total 次'),
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

/// X 轴刻度文案：周=周一~周日，月=几号
String _xAxisLabel(DateTime d, _RangeMode mode) {
  return switch (mode) {
    _RangeMode.week => weekNames[d.weekday - 1],
    _RangeMode.month => '${d.day}',
  };
}

/// 是否显示该 X 轴刻度
bool _shouldShowX(DateTime d, _RangeMode mode) {
  switch (mode) {
    case _RangeMode.week:
      return true; // 周一~周日全显示
    case _RangeMode.month:
      return true; // 几号几号（图表可横向滚动）
  }
}

/// 选中提示的日期文案
String _tooltipLabel(DateTime d, _RangeMode mode) {
  if (mode == _RangeMode.week) return weekNames[d.weekday - 1];
  return '${d.month}月${d.day}日';
}class _BarChart extends StatelessWidget {
  final Map<String, int> counts;
  final List<DateTime> days;
  final double barWidth;
  final _RangeMode mode;

  const _BarChart({required this.counts, required this.days, required this.barWidth, required this.mode});

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
              width: barWidth,
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ],
        ),
    ];
    return BarChart(
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
        // 点击某根柱子：显示当天日期 + 喝水次数
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = days[group.x];
              return BarTooltipItem(
                '${_tooltipLabel(d, mode)}\n${rod.toY.toInt()} 次',
                const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (maxVal == 0 ? 1 : maxVal).toDouble(),
              getTitlesWidget: (v, meta) =>
                  Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
            ),
          ),
          // 顶部不需要 X 轴
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                final d = days[i];
                if (!_shouldShowX(d, mode)) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_xAxisLabel(d, mode), style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
        ),
        barGroups: groups,
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final Map<String, int> counts;
  final List<DateTime> days;
  final bool showDots;
  final _RangeMode mode;

  const _LineChart({required this.counts, required this.days, required this.showDots, required this.mode});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final maxVal = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final spots = <FlSpot>[
      for (var i = 0; i < days.length; i++)
        FlSpot(i.toDouble(), (counts[toDateString(days[i])] ?? 0).toDouble()),
    ];
    return LineChart(
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
            dotData: FlDotData(
              show: showDots,
              getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 3, color: color),
            ),
          ),
        ],
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        // 点击折线上某点：显示当天日期 + 喝水次数
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => [
              for (final s in touchedSpots)
                LineTooltipItem(
                  '${_tooltipLabel(days[s.x.toInt()], mode)}\n${s.y.toInt()} 次',
                  const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (maxVal == 0 ? 1 : maxVal).toDouble(),
            ),
          ),
          // 顶部不需要 X 轴
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                final d = days[i];
                if (!_shouldShowX(d, mode)) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_xAxisLabel(d, mode), style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final DateTime anchor;
  final _RangeMode mode;
  final Map<String, int> counts;
  final ValueChanged<DateTime> onTapDay;

  const _CalendarCard({
    required this.anchor,
    required this.mode,
    required this.counts,
    required this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    // 周视图：只展示当周 7 天
    if (mode == _RangeMode.week) {
      final weekStart = anchor.subtract(Duration(days: anchor.weekday - 1));
      final cells = <Widget>[
        for (var i = 0; i < 7; i++) _dayCell(weekStart.add(Duration(days: i)), color),
      ];
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  for (final w in weekNames)
                    Expanded(
                        child: Center(
                            child:
                                Text(w, style: const TextStyle(fontSize: 12, color: Colors.grey)))),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: cells,
              ),
            ],
          ),
        ),
      );
    }

    // 月视图：整月
    final first = DateTime(anchor.year, anchor.month, 1);
    final daysInMonth = DateTime(anchor.year, anchor.month + 1, 0).day;
    final leadingBlanks = first.weekday - 1; // 周一开头
    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(_dayCell(DateTime(anchor.year, anchor.month, d), color));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                for (final w in weekNames)
                  Expanded(child: Center(child: Text(w, style: const TextStyle(fontSize: 12, color: Colors.grey)))),
              ],
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
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('次数越多颜色越深', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayCell(DateTime date, Color color) {
    final cnt = counts[toDateString(date)] ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onTapDay(date),
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cnt == 0
              ? Colors.transparent
              : color.withValues(alpha: (0.12 + 0.18 * (cnt.clamp(0, 4) / 4)).toDouble()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${date.day}', style: const TextStyle(fontSize: 12)),
            Text(cnt > 0 ? '$cnt' : '',
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
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
            Text(formatDate(parseDate(date)),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  leading: Icon(log.isDrank ? Icons.local_drink : Icons.close,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text(log.isDrank ? '已喝水' : '未喝水'),
                  subtitle: Text('${formatTime(t.hour, t.minute)} 记录'),
                  trailing: log.reminderId == null
                      ? null
                      : Text('提醒#${log.reminderId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                );
              }),
          ],
        ),
      ),
    );
  }
}