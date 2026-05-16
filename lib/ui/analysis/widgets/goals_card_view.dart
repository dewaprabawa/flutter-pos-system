import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:possystem/components/style/info_popup.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/helpers/analysis/ema_calculator.dart';
import 'package:possystem/helpers/breakpoint.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/repository/seller.dart';
import 'package:possystem/services/cache.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/analysis/widgets/reloadable_card.dart';

class GoalsCardView extends StatefulWidget {
  final EMACalculator calculator;
  final Widget? action;

  const GoalsCardView({
    super.key,
    this.calculator = const EMACalculator(20),
    this.action,
  });

  @override
  State<GoalsCardView> createState() => _GoalsCardViewState();
}

class _GoalsCardViewState extends State<GoalsCardView> {
  OrderSummary? goal;
  final formatter = NumberFormat.percentPattern();

  @override
  Widget build(BuildContext context) {
    return ReloadableCard<OrderSummary>(
      id: 'goals',
      title: S.analysisGoalsTitle,
      notifiers: [Seller.instance],
      action: widget.action,
      builder: _builder,
      loader: _loader,
    );
  }

  @override
  void initState() {
    final enabled = Cache.instance.get<bool>('analysis.goals');
    if (enabled != true) {
      goal = OrderSummary(at: DateTime(0));
    }
    super.initState();
  }

  Widget _builder(BuildContext context, OrderSummary metric) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(builder: (context, constraint) {
      final compact = constraint.maxWidth < Breakpoint.compact.max;
      final showChart = goal!.profit != 0;
      
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _GoalItem(
                  current: metric.count,
                  goal: goal!.count,
                  name: S.analysisGoalsCountTitle,
                  desc: S.analysisGoalsCountDescription,
                  compact: compact,
                  isCurrency: false,
                ),
                const SizedBox(height: 16),
                _GoalItem(
                  current: metric.revenue,
                  goal: goal!.revenue,
                  name: S.analysisGoalsRevenueTitle,
                  desc: S.analysisGoalsRevenueDescription,
                  compact: compact,
                ),
                const SizedBox(height: 16),
                _GoalItem(
                  current: metric.profit,
                  goal: goal!.profit,
                  name: S.analysisGoalsProfitTitle,
                  desc: S.analysisGoalsProfitDescription,
                  compact: compact,
                ),
              ],
            ),
          ),
          if (showChart) ...[
            const SizedBox(width: 24),
            SizedBox(
              width: compact ? 100 : 140,
              height: compact ? 100 : 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: metric.profit / goal!.profit,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatter.format(metric.profit / goal!.profit),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          S.analysisGoalsAchievedRate(''),
                          style: textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  Future<OrderSummary> _loader() async {
    final range = Util.getDateRange();
    final result = await Seller.instance.getMetricsInPeriod(
      goal == null ? range.start.subtract(const Duration(days: 40)) : range.start,
      range.end,
      types: [
        OrderMetricType.count,
        OrderMetricType.revenue,
        OrderMetricType.profit,
        OrderMetricType.cost,
      ],
      ignoreEmpty: true,
      limit: goal == null ? widget.calculator.length + 1 : 1,
      orderDirection: "desc",
    );

    final todayData = result.firstOrNull?.at == range.end.subtract(const Duration(days: 1))
        ? result.removeAt(0)
        : OrderSummary(at: range.start);

    if (goal == null) {
      final reversed = result.take(20).toList().reversed;
      goal = OrderSummary(
        at: DateTime(0),
        values: {
          'count': widget.calculator.calculate(reversed.map((e) => e.count)),
          'revenue': widget.calculator.calculate(reversed.map((e) => e.revenue)),
          'profit': widget.calculator.calculate(reversed.map((e) => e.profit)),
        },
      );
    }

    return todayData;
  }
}

class _GoalItem extends StatelessWidget {
  final String name;
  final String? desc;
  final num current;
  final num goal;
  final bool compact;
  final bool isCurrency;

  const _GoalItem({
    required this.name,
    this.desc,
    required this.current,
    required this.goal,
    required this.compact,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (desc != null) ...[
          const SizedBox(width: 4),
          InfoPopup(desc!),
        ],
      ],
    );

    final value = RichText(
      text: TextSpan(
        text: isCurrency ? current.toCurrency() : current.toString(),
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        children: goal != 0
            ? [
                TextSpan(
                  text: ' / ${isCurrency ? goal.toCurrency() : goal.toString()}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ]
            : null,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        const SizedBox(height: 4),
        value,
      ],
    );
  }
}
