import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/dialog/confirm_dialog.dart';
import 'package:possystem/components/style/pop_button.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/components/tutorial.dart';
import 'package:possystem/constants/icons.dart';
import 'package:possystem/helpers/breakpoint.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/repository/seller.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/analysis/widgets/history_actions.dart';
import 'package:possystem/ui/transit/transit_station.dart';
import 'package:spotlight_ant/spotlight_ant.dart';

import 'widgets/history_calendar_view.dart';
import 'widgets/history_order_list.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final ValueNotifier<DateTimeRange> notifier;

  @override
  Widget build(BuildContext context) {
    final singleView =
        MediaQuery.sizeOf(context).width <= Breakpoint.medium.max;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TutorialWrapper(
      child: Scaffold(
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: Navigator.canPop(context)
                    ? PopButton(color: Colors.teal.shade900)
                    : null,
                title: Row(
                  children: [
                    Icon(Icons.storefront, color: Colors.teal.shade900),
                    const SizedBox(width: 8),
                    Text(
                      'Histori',
                      style: TextStyle(
                          color: Colors.teal.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ],
                ),
                actions: [
                  Tutorial(
                    id: 'history.action',
                    title: S.analysisHistoryActionTutorialTitle,
                    message: S.analysisHistoryActionTutorialContent,
                    spotlightBuilder:
                        const SpotlightRectBuilder(borderRadius: 8.0),
                    child: MenuAnchor(
                      builder: (context, controller, child) => IconButton(
                        key: const Key('history.action'),
                        onPressed: controller.open,
                        icon: Icon(KIcons.more, color: Colors.teal.shade900),
                      ),
                      menuChildren: [
                        SubmenuButton(
                          key: const Key('history.action.export'),
                          menuChildren: TransitMethod.values
                              .map((e) => MenuItemButton(
                                    onPressed: () => _onExport(e),
                                    child: Text(e.l10nName),
                                  ))
                              .toList(),
                          child: Text(S.analysisHistoryActionExport),
                        ),
                        MenuItemButton(
                          key: const Key('history.action.clear'),
                          onPressed: _onClear,
                          child: Text(S.analysisHistoryActionClear),
                        ),
                        MenuItemButton(
                          key: const Key('history.action.reset_no'),
                          onPressed: _onResetNo,
                          child: Text(S.analysisHistoryActionResetNo),
                        ),
                        MenuItemButton(
                          key: const Key('history.action.schedule_reset_no'),
                          onPressed: _onScheduleResetNo,
                          child: Text(S.analysisHistoryActionScheduleResetNo),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: singleView ? _buildSingleColumn() : _buildTwoColumns(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    notifier = ValueNotifier<DateTimeRange>(Util.getDateRange());
  }

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }

  Widget _buildTwoColumns() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildCalendar(shouldFillViewport: true)),
        Expanded(child: _buildOrderList()),
      ],
    );
  }

  Widget _buildSingleColumn() {
    return Column(children: [
      PhysicalModel(
        elevation: 0,
        color: Colors.white,
        child: _buildCalendar(shouldFillViewport: false),
      ),
      _buildMetricsSection(),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TRANSACTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            ValueListenableBuilder(
              valueListenable: notifier,
              builder: (context, range, _) {
                return FutureBuilder<OrderMetrics>(
                  future: Seller.instance.getMetrics(range.start, range.end),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.count ?? 0;
                    return Text(
                      '$count ${count > 1 ? "Items" : "Item"} Found',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Expanded(child: _buildOrderList()),
    ]);
  }

  Widget _buildMetricsSection() {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, range, _) {
        return FutureBuilder<OrderMetrics>(
          future: Seller.instance.getMetrics(range.start, range.end),
          builder: (context, snapshot) {
            final metrics = snapshot.data;
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Revenue:',
                      value: metrics?.revenue.toCurrency() ?? 0.toCurrency(),
                      dotColor: const Color(0xFF00796B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Cost:',
                      value: metrics?.cost.toCurrency() ?? 0.toCurrency(),
                      dotColor: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF004D40),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar({required bool shouldFillViewport}) {
    return Tutorial(
      id: 'history.calendar',
      title: S.analysisHistoryCalendarTutorialTitle,
      message: S.analysisHistoryCalendarTutorialContent,
      spotlightBuilder: const SpotlightRectBuilder(),
      child: HistoryCalendarView(
        shouldFillViewport: shouldFillViewport,
        notifier: notifier,
      ),
    );
  }

  Widget _buildOrderList() {
    return HistoryOrderList(notifier: notifier);
  }

  void _onExport(TransitMethod method) async {
    await context.pushNamed(
      Routes.transitStation,
      pathParameters: {'method': method.name, 'catalog': 'order'},
      queryParameters: {'range': serializeRange(notifier.value)},
    );
  }

  void _onClear() async {
    final dateTime = await HistoryCleanDialog.show(context);
    if (dateTime != null && context.mounted) {
      await Seller.instance.clear(dateTime);
      // ignore: use_build_context_synchronously
      showSnackBar(S.actSuccess, context: context);
    }
  }

  void _onResetNo() async {
    final ok = await ConfirmDialog.show(
      context,
      title: S.analysisHistoryActionResetNo,
      content: S.analysisHistoryActionResetNoHint,
    );
    if (ok) {
      await Seller.instance.resetId();
      // ignore: use_build_context_synchronously
      showSnackBar(S.actSuccess, context: context);
    }
  }

  void _onScheduleResetNo() async {
    final period = await HistoryScheduleResetNoDialog.show(context);
    if (period != null && context.mounted) {
      await Seller.instance.updateResetIdPeriod(period);
      // ignore: use_build_context_synchronously
      showSnackBar(S.actSuccess, context: context);
    }
  }
}
