import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/style/footer.dart';
import 'package:possystem/components/tutorial.dart';
import 'package:possystem/constants/app_themes.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/services/cache.dart';
import 'package:possystem/translator.dart';
import 'package:spotlight_ant/spotlight_ant.dart';

class HomePage extends StatelessWidget {
  final StatefulNavigationShell shell;

  final ValueNotifier<HomeMode> mode;

  const HomePage({super.key, required this.shell, required this.mode});

  @override
  Widget build(BuildContext context) {
    return TutorialWrapper(
      child: ListenableBuilder(
        listenable: mode,
        builder: (context, _) {
          SpotlightShow.of(context).reset();
          return switch (mode.value) {
            HomeMode.bottomNavigationBar => _WithTab(shell: shell),
            HomeMode.drawer => _WithDrawer(shell: shell),
            HomeMode.rail => _WithRail(shell: shell),
          };
        },
      ),
    );
  }
}

class _WithTab extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _WithTab({required this.shell});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Scaffold(
          // appBar: AppBar(
          //   title: Text(S.appTitle),
          //   centerTitle: true,
          //   flexibleSpace: const _FlexibleSpace(),
          //   excludeHeaderSemantics: true,
          //   actions: [
          //     IconButton(
          //       key: const Key('home.settings'),
          //       icon: const Icon(Icons.settings_outlined),
          //       onPressed: () => context.pushNamed(Routes.settings),
          //       tooltip: S.title('settings'),
          //     ),
          //   ],
          // ),
          body: shell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: min(shell.currentIndex, 4),
            onDestinationSelected: (index) {
              SpotlightShow.of(context).reset();
              shell.goBranch(
                index,
                initialLocation: index == shell.currentIndex,
              );
            },
            destinations: [
              for (final _Tab e in _bottomNavTabs)
                NavigationDestination(
                  key: Key('home.${e.name}'),
                  icon: e.icon,
                  label: e == _Tab.analysis ? S.analysisHistoryTitle : S.title(e.name),
                  selectedIcon: e.selectedIcon,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WithDrawer extends StatefulWidget {
  final StatefulNavigationShell shell;

  const _WithDrawer({required this.shell});

  @override
  State<_WithDrawer> createState() => _WithDrawerState();
}

class _WithDrawerState extends State<_WithDrawer> {
  final scaffold = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final tab =
        _Tab.values.elementAtOrNull(widget.shell.currentIndex) ?? _Tab.order;
    final needNested = tab == _Tab.analysis;

    final settingsAction = IconButton(
      key: const Key('home.settings'),
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.pushNamed(Routes.settings),
      tooltip: S.title('settings'),
    );

    // Which means body have [CustomScrollView]
    if (needNested) {
      return Scaffold(
        key: scaffold,
        drawer: _buildDrawer(tab),
        body: _Nested(
            title: S.title(tab.name),
            body: widget.shell,
            actions: [settingsAction]),
      );
    }

    return Scaffold(
      key: scaffold,
      appBar: AppBar(
        title: Text(S.title(tab.name)),
        flexibleSpace: const _FlexibleSpace(),
        actions: [settingsAction],
      ),
      drawer: _buildDrawer(tab),
      body: widget.shell,
    );
  }

  Widget _buildDrawer(_Tab tab) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 48),
            for (final e in _drawerTabs)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
                child: e.wrap(
                  ListTile(
                    key: Key('home.${e.name}'),
                    leading: tab == e ? e.selectedIcon : e.icon,
                    title: Text(e == _Tab.analysis ? S.analysisHistoryTitle : S.title(e.name)),
                    selected: tab == e,
                    visualDensity: VisualDensity.compact,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    onTap: () => _navTo(e.index),
                  ),
                  _closeDrawer,
                ),
              ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    if (Cache.instance.get<bool>('tutorial.home.order') != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scaffold.currentState?.openDrawer();
      });
    }
    super.initState();
  }

  void _navTo(int index) {
    _closeDrawer();
    SpotlightShow.of(context).reset();
    widget.shell
        .goBranch(index, initialLocation: index == widget.shell.currentIndex);
  }

  void _closeDrawer() {
    scaffold.currentState?.closeDrawer();
  }
}

class _WithRail extends StatefulWidget {
  final StatefulNavigationShell shell;

  const _WithRail({required this.shell});

  @override
  State<_WithRail> createState() => _WithRailState();
}

class _WithRailState extends State<_WithRail> {
  late final ValueNotifier<bool> railExpanded;
  late final ValueNotifier<int> railSelected;

  @override
  Widget build(BuildContext context) {
    final tab =
        _Tab.values.elementAtOrNull(widget.shell.currentIndex) ?? _Tab.order;
    final needNested = tab == _Tab.analysis;

    final settingsAction = IconButton(
      key: const Key('home.settings'),
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.pushNamed(Routes.settings),
      tooltip: S.title('settings'),
    );

    // Which means body have [CustomScrollView]
    if (needNested) {
      return Scaffold(
        body: _Nested(
            title: S.title(tab.name),
            body: _buildBody(),
            actions: [settingsAction]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.title(tab.name)),
        flexibleSpace: const _FlexibleSpace(),
        actions: [settingsAction],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Row(children: [
      ListenableBuilder(
        listenable: railExpanded,
        builder: (context, child) => ListenableBuilder(
          listenable: railSelected,
          builder: (context, child) => _buildRail(),
        ),
      ),
      const VerticalDivider(),
      Expanded(child: widget.shell),
    ]);
  }

  Widget _buildRail() {
    return NavigationRail(
      extended: railExpanded.value,
      onDestinationSelected: (int index) {
        SpotlightShow.of(context).reset();
        widget.shell.goBranch(index,
            initialLocation: index == widget.shell.currentIndex);
        setState(() => railSelected.value = index);
      },
      leading: IconButton(
        icon: Icon(railExpanded.value ? Icons.close : Icons.menu),
        onPressed: () => railExpanded.value = !railExpanded.value,
      ),
      selectedIndex: min(railSelected.value, railExpanded.value ? 999 : 2),
      destinations: [
        for (final e in _drawerTabs)
          // Show all tabs if expanded, otherwise only show important tabs
          if (railExpanded.value || e.important)
            NavigationRailDestination(
              icon: e.icon,
              selectedIcon: e.selectedIcon,
              label: e.wrap(Text(e == _Tab.analysis ? S.analysisHistoryTitle : S.title(e.name))),
            ),
      ],
    );
  }

  @override
  void initState() {
    railExpanded =
        ValueNotifier(Cache.instance.get<bool>('tutorial.home.order') != true);
    railSelected = ValueNotifier(widget.shell.currentIndex);
    super.initState();
  }
}

class _Nested extends StatelessWidget {
  final String title;

  final Widget body;

  final List<Widget> actions;

  const _Nested(
      {required this.title, required this.body, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) => [
        SliverAppBar(
          pinned: true,
          title: Text(title),
          flexibleSpace: const _FlexibleSpace(),
          actions: actions,
        ),
      ],
      body: body,
    );
  }
}

class _FlexibleSpace extends StatelessWidget {
  const _FlexibleSpace();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).gradientColors,
          tileMode: TileMode.clamp,
        ),
      ),
    );
  }
}

const _bottomNavTabs = [
  _Tab.order,
  _Tab.cashier,
  _Tab.analysis,
  _Tab.more,
];

const _drawerTabs = [
  _Tab.order,
  _Tab.analysis,
  _Tab.stock,
  _Tab.cashier,
  _Tab.orderAttributes,
  _Tab.menu,
  _Tab.printers,
  _Tab.stockQuantities,
  _Tab.transit,
  _Tab.elf,
  if (!isProd) _Tab.debug,
];

enum _Tab {
  order(
    icon: Icon(Icons.shopping_bag_outlined),
    selectedIcon: Icon(Icons.shopping_bag),
    important: true,
  ),
  analysis(
    icon: Icon(Icons.receipt_long_outlined),
    selectedIcon: Icon(Icons.receipt_long),
    important: true,
  ),
  stock(
    icon: Icon(Icons.inventory_2_outlined),
    selectedIcon: Icon(Icons.inventory_2),
    important: true,
  ),
  cashier(
    icon: Icon(Icons.monetization_on_outlined),
    selectedIcon: Icon(Icons.monetization_on),
    important: true,
  ),
  orderAttributes(
    icon: Icon(Icons.assignment_ind_outlined),
    selectedIcon: Icon(Icons.assignment_ind),
  ),
  menu(
    icon: Icon(Icons.collections_outlined),
    selectedIcon: Icon(Icons.collections),
  ),
  printers(
    icon: Icon(Icons.print_outlined),
    selectedIcon: Icon(Icons.print),
  ),
  stockQuantities(
    icon: Icon(Icons.exposure_outlined),
    selectedIcon: Icon(Icons.exposure),
  ),
  transit(
    icon: Icon(Icons.local_shipping_outlined),
    selectedIcon: Icon(Icons.local_shipping),
  ),
  elf(
    icon: Icon(Icons.lightbulb_outlined),
    selectedIcon: Icon(Icons.lightbulb),
  ),
  debug(
    icon: Icon(Icons.bug_report_outlined),
    selectedIcon: Icon(Icons.bug_report),
  ),

  /// entrypoint for mobile screen
  more(
    icon: Icon(Icons.dehaze_outlined),
    selectedIcon: Icon(Icons.dehaze),
  );

  final Icon icon;
  final Icon selectedIcon;
  final bool important;

  const _Tab({
    required this.icon,
    required this.selectedIcon,
    this.important = false,
  });

  Widget wrap(Widget child, [void Function()? action]) {
    return switch (this) {
      _Tab.menu => MenuTutorial(child: child),
      // after finish this tutorial, we will close the drawer
      _Tab.orderAttributes =>
        OrderAttrTutorial(onDismissed: action, child: child),
      _ => child,
    };
  }
}
