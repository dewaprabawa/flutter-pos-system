import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:possystem/components/menu_actions.dart';
import 'package:possystem/components/style/buttons.dart';
import 'package:possystem/constants/icons.dart';
import 'package:possystem/models/analysis/chart.dart';
import 'package:possystem/models/repository/seller.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/analysis/widgets/reloadable_card.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartCardView extends StatelessWidget {
  final Chart chart;
  final ValueNotifier<DateTimeRange> range;

  const ChartCardView({
    super.key,
    required this.chart,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    return ReloadableCard<List>(
      id: chart.id,
      wrappedByCard: true,
      notifiers: [range, chart, Seller.instance],
      builder: (context, metric) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    chart.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _MoreButton(chart),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: buildChart(context, metric),
            ),
          ],
        );
      },
      loader: () => chart.load(range.value),
    );
  }

  Widget buildChart(BuildContext context, List metrics) {
    if (metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 8),
            Text(
              S.analysisChartCardEmptyData,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return switch (chart.type) {
      AnalysisChartType.cartesian => _CartesianChart(
          chart: chart,
          metrics: metrics as List<OrderSummary>,
          interval: MetricsIntervalType.fromDays(range.value.duration.inDays),
        ),
      AnalysisChartType.circular => _CircularChart(
          chart: chart,
          metrics: metrics as List<OrderMetricPerItem>,
        ),
    };
  }
}

class _CartesianChart extends StatelessWidget {
  final Chart chart;
  final List<OrderSummary> metrics;
  final MetricsIntervalType interval;

  const _CartesianChart({
    required this.chart,
    required this.metrics,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      selectionType: SelectionType.point,
      selectionGesture: ActivationMode.singleTap,
      axes: chart.units
          .take(2)
          .mapIndexed((i, e) => NumericAxis(
                opposedPosition: i == 1,
                name: e.name,
                labelFormat: e.labelFormat,
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: TextStyle(color: colorScheme.outline, fontSize: 10),
              ))
          .toList(),
      primaryXAxis: DateTimeAxis(
        enableAutoIntervalOnZooming: false,
        dateFormat: DateFormat(interval.format, S.localeName),
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelStyle: TextStyle(color: colorScheme.outline, fontSize: 10),
      ),
      primaryYAxis: const NumericAxis(isVisible: false),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
        lineType: TrackballLineType.vertical,
        lineColor: colorScheme.primary.withValues(alpha: 0.3),
        tooltipSettings: InteractiveTooltip(
          format: 'series.name : point.y',
          color: colorScheme.surfaceContainerHighest,
          textStyle: TextStyle(color: colorScheme.onSurface),
        ),
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
        textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 12),
      ),
      series: chart.keyUnits().mapIndexed(
        (index, keyUnit) {
          final colors = [
            colorScheme.primary,
            colorScheme.secondary,
            colorScheme.tertiary,
            colorScheme.error,
          ];
          return AreaSeries<OrderSummary, DateTime>(
            name: chart.target == OrderMetricTarget.order ? S.analysisChartMetricName(keyUnit.key) : keyUnit.key,
            yAxisName: keyUnit.value.name,
            xValueMapper: (v, i) => v.at,
            yValueMapper: (v, i) => v.value(keyUnit.key),
            dataSource: metrics,
            color: colors[index % colors.length].withValues(alpha: 0.1),
            borderColor: colors[index % colors.length],
            borderWidth: 2,
            markerSettings: MarkerSettings(
              isVisible: true,
              height: 4,
              width: 4,
              color: colors[index % colors.length],
              borderWidth: 0,
            ),
          );
        },
      ).toList(),
    );
  }
}

class _CircularChart extends StatelessWidget {
  final Chart chart;
  final List<OrderMetricPerItem> metrics;

  const _CircularChart({
    required this.chart,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentFormat = NumberFormat.percentPattern(S.localeName);

    return SfCircularChart(
      margin: EdgeInsets.zero,
      tooltipBehavior: TooltipBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        animationDuration: 150,
        format: 'point.x : ${chart.units.first.tooltipFormat}',
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.right,
        overflowMode: LegendItemOverflowMode.wrap,
        textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 12),
      ),
      series: [
        DoughnutSeries<OrderMetricPerItem, String>(
          animationDuration: 1000,
          explode: true,
          explodeOffset: '10%',
          innerRadius: '60%',
          radius: '80%',
          name: chart.target.name,
          xValueMapper: (v, i) => v.name,
          yValueMapper: (v, i) => v.value == 0 && metrics.every((e) => e.value == 0) ? 1 : v.value,
          dataSource: metrics,
          dataLabelMapper: (v, i) => percentFormat.format(v.percent),
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _MoreButton extends StatelessWidget {
  final Chart chart;
  const _MoreButton(this.chart);

  @override
  Widget build(BuildContext context) {
    return MoreButton(
      key: Key('chart.${chart.id}.more'),
      onPressed: _showActions,
    );
  }

  void _showActions(BuildContext context) async {
    await MenuActionGroup.withDelete<int>(
      context,
      deleteCallback: chart.remove,
      deleteValue: 0,
      warningContent: S.dialogDeletionContent(chart.name, ''),
      actions: <MenuAction<int>>[
        MenuAction(
          title: Text(S.analysisChartCardTitleUpdate),
          leading: const Icon(KIcons.modal),
          route: Routes.chartUpdate,
          routePathParameters: {'id': chart.id},
        ),
      ],
    );
  }
}
