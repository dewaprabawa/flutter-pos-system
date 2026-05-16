import 'package:flutter/material.dart';
import 'package:possystem/components/menu_actions.dart';
import 'package:possystem/components/style/route_buttons.dart';
import 'package:possystem/components/tutorial.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/constants/icons.dart';
import 'package:possystem/helpers/breakpoint.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/analysis/analysis.dart';
import 'package:possystem/models/analysis/chart.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/analysis/widgets/chart_card_view.dart';
import 'package:possystem/ui/analysis/widgets/chart_range_page.dart';

class AnalysisView extends StatefulWidget {
  const AnalysisView({super.key});

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> with AutomaticKeepAliveClientMixin {
  /// Range of the data to show in charts, it can updated by the user
  late ValueNotifier<DateTimeRange> range;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: Analysis.instance,
      builder: (context, child) {
        return LayoutBuilder(builder: (context, constraints) {
          final bp = Breakpoint.find(box: constraints);
          return CustomScrollView(slivers: <Widget>[
            // ── Gradient Header ──
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Text(
                    S.analysisHistoryTitle,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  centerTitle: false,
                  actions: const [_MoreButton()],
                ),
              ),
            ),
            _buildChartHeader(),
            _buildCharts(Analysis.instance.itemList, bp),
          ]);
        });
      },
    );
  }

  Widget _buildChartHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      primary: false,
      pinned: true,
      leading: Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.outline),
      centerTitle: false,
      title: ListenableBuilder(
        listenable: range,
        builder: (context, child) => TextButton(
          key: const Key('anal.chart_range'),
          onPressed: _goToChartRange,
          child: Text(range.value.format(S.localeName)),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _updateRange(Duration(days: -interval)),
          iconSize: 16,
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
        IconButton(
          onPressed: () => _updateRange(Duration(days: interval)),
          iconSize: 16,
          icon: const Icon(Icons.arrow_forward_ios_outlined),
        ),
      ],
    );
  }

  Widget _buildCharts(List<Chart> items, Breakpoint bp) {
    final col = bp.lookup<int>(compact: 1, medium: 2, expanded: 3, large: 4);
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: kFABSpacing),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: col,
          mainAxisExtent: 376,
        ),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == items.length) {
            return Align(
              alignment: col == 1 ? Alignment.topCenter : Alignment.center,
              child: SizedBox(
                width: 200,
                height: 200,
                child: Tutorial(
                  id: 'anal.add_chart',
                  title: S.analysisChartTutorialTitle,
                  message: S.analysisChartTutorialContent,
                  monitorVisibility: true,
                  child: RouteElevatedIconButton(
                    key: const Key('anal.add_chart'),
                    icon: const Icon(KIcons.add),
                    route: Routes.chartCreate,
                    label: S.analysisChartTitleCreate,
                  ),
                ),
              ),
            );
          }

          return Center(
            child: ChartCardView(
              chart: items.elementAt(index),
              range: range,
            ),
          );
        },
      ),
    );
  }

  int get interval => range.value.duration.inDays;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    range = ValueNotifier(Util.getDateRange(
      now: DateTime.now().subtract(const Duration(days: 7)),
      days: 7,
    ));

    super.initState();
  }

  void _goToChartRange() async {
    final val = await showDialog(
      context: context,
      builder: (context) => ChartRangePage(range: range.value),
    );

    if (val != null) {
      range.value = val;
    }
  }

  void _updateRange(Duration dur) {
    range.value = Util.getDateRange(
      now: range.value.start.add(dur),
      days: interval,
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('anal.more'),
      onPressed: () => showPositionedMenu<int>(
        context,
        actions: <MenuAction<int>>[
          MenuAction(
            title: Text(S.analysisChartTitleReorder),
            leading: const Icon(KIcons.reorder),
            route: Routes.chartReorder,
          ),
          MenuAction(
            title: Text(S.analysisChartTitleCreate),
            leading: const Icon(KIcons.add),
            route: Routes.chartCreate,
          ),
        ],
      ),
      enableFeedback: true,
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      icon: const Icon(Icons.settings_outlined, color: Colors.white),
    );
  }
}
