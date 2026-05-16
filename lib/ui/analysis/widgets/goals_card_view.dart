import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:possystem/components/style/info_popup.dart';
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
  final String? title;

  const GoalsCardView({
    super.key,
    this.calculator = const EMACalculator(20),
    this.action,
    this.title,
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
      title: widget.title ?? S.analysisGoalsTitle,
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _GoalItem(
            current: metric.count,
            name: 'ORDER COUNT',
            desc: S.analysisGoalsCountDescription,
            compact: compact,
            isCurrency: false,
          ),
          const SizedBox(height: 20),
          _GoalItem(
            current: metric.revenue,
            name: 'REVENUE',
            desc: S.analysisGoalsRevenueDescription,
            compact: compact,
            isTeal: true,
          ),
          const SizedBox(height: 20),
          _GoalItem(
            current: metric.profit,
            name: 'PROFIT',
            desc: S.analysisGoalsProfitDescription,
            compact: compact,
            isTeal: true,
          ),
        ],
      );
    });
  }

  Future<OrderSummary> _loader() async {
    final range = Util.getDateRange();
    final result = await Seller.instance.getMetricsInPeriod(
      goal == null
          ? range.start.subtract(const Duration(days: 40))
          : range.start,
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

    final todayData =
        result.firstOrNull?.at == range.end.subtract(const Duration(days: 1))
            ? result.removeAt(0)
            : OrderSummary(at: range.start);

    if (goal == null) {
      final reversed = result.take(20).toList().reversed;
      goal = OrderSummary(
        at: DateTime(0),
        values: {
          'count': widget.calculator.calculate(reversed.map((e) => e.count)),
          'revenue':
              widget.calculator.calculate(reversed.map((e) => e.revenue)),
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
  final bool compact;
  final bool isCurrency;
  final bool isTeal;

  const _GoalItem({
    required this.name,
    this.desc,
    required this.current,
    required this.compact,
    this.isCurrency = true,
    this.isTeal = false,
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
          style: textTheme.labelSmall?.copyWith(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        if (desc != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.help_outline, size: 14, color: Colors.grey.shade400),
        ],
      ],
    );

    final value = Text(
      isCurrency ? current.toCurrency() : current.toString(),
      style: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: isTeal ? const Color(0xFF004D40) : Colors.black87,
        letterSpacing: -1,
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
