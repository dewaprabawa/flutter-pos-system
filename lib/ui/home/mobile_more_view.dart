import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/style/footer.dart';
import 'package:possystem/components/tutorial.dart';
import 'package:possystem/constants/app_themes.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/models/printer.dart';
import 'package:possystem/models/repository/menu.dart';
import 'package:possystem/models/repository/order_attributes.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/translator.dart';
import 'package:provider/provider.dart';

class MobileMoreView extends StatefulWidget {
  const MobileMoreView({super.key});

  @override
  State<MobileMoreView> createState() => _MobileMoreViewState();
}

class _MobileMoreViewState extends State<MobileMoreView> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: localeNotifier,
      builder: (context, child) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, color: Colors.white, size: 30),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Budi Utomo',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Owner • Premium Plan',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _HeaderInfoList(),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('Management'),
                    _buildRouteCard(
                      id: 'menu',
                      icon: Icons.restaurant_menu_outlined,
                      color: Colors.orange,
                      route: Routes.menu,
                      title: S.menuTitle,
                      subtitle: S.menuSubtitle,
                    ),
                    _buildRouteCard(
                      id: 'stock',
                      icon: Icons.inventory_2_outlined,
                      color: Colors.blue,
                      route: Routes.stock,
                      title: S.stockTab,
                      subtitle: S.stockIngredientEmptyBody,
                    ),
                    _buildRouteCard(
                      id: 'orderAttributes',
                      icon: Icons.assignment_ind_outlined,
                      color: Colors.teal,
                      route: Routes.orderAttr,
                      title: S.orderAttributeTitle,
                      subtitle: S.orderAttributeDescription,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Tools & Reports'),
                    _buildRouteCard(
                      id: 'analysis',
                      icon: Icons.analytics_outlined,
                      color: Colors.purple,
                      route: Routes.anal,
                      title: S.analysisChartTitle,
                      subtitle: S.analysisChartTutorialTitle,
                    ),
                    _buildRouteCard(
                      id: 'printers',
                      icon: Icons.print_outlined,
                      color: Colors.grey,
                      route: Routes.printer,
                      title: S.printerTitle,
                      subtitle: S.printerDescription,
                    ),
                    _buildRouteCard(
                      id: 'transit',
                      icon: Icons.cloud_sync_outlined,
                      color: Colors.indigo,
                      route: Routes.transit,
                      title: S.transitTitle,
                      subtitle: S.transitDescription,
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader('System'),
                    _buildRouteCard(
                      id: 'settings',
                      icon: Icons.settings_outlined,
                      color: Colors.blueGrey,
                      route: Routes.settings,
                      title: S.settingFeatureTitle,
                      subtitle: S.settingFeatureDescription,
                    ),
                    _buildRouteCard(
                      id: 'elf',
                      icon: Icons.auto_awesome_outlined,
                      color: Colors.amber,
                      route: Routes.elf,
                      title: S.settingElfTitle,
                      subtitle: S.settingElfDescription,
                    ),
                    if (!isProd)
                      _buildRouteCard(
                        id: 'debug',
                        icon: Icons.bug_report_outlined,
                        color: Colors.red,
                        route: 'debug',
                        title: 'Debug',
                        subtitle: 'Developer tools',
                      ),
                    const SizedBox(height: 24),
                    const Footer(),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildRouteCard({
    required String id,
    required IconData icon,
    required Color color,
    required String route,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        key: Key('home.$id'),
        onTap: () => context.goNamed(route),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildRouteTile({
    required String id,
    required IconData icon,
    required String route,
    required String title,
    required String subtitle,
    // bool beta = false,
  }) {
    return ListTile(
      key: Key('home.$id'),
      leading: Icon(icon),
      trailing: const Icon(Icons.navigate_next_outlined),
      onTap: () => context.goNamed(route),
      title: Text(title),
      // title: beta
      //     ? Row(children: [
      //         Text(title),
      //         const SizedBox(width: 8),
      //         const Badge(label: Text('Beta')),
      //       ])
      //     : Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _HeaderInfoList extends StatelessWidget {
  const _HeaderInfoList();

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<Menu>();
    final printers = context.watch<Printers>();
    final attrs = context.watch<OrderAttributes>();

    return SizedBox(
      height: 152,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        children: [
          _buildItem(
            id: 'products',
            context: context,
            title: menu.items.fold<int>(0, (v, e) => e.length + v),
            subtitle: S.menuProductHeaderInfo,
            route: Routes.menu,
            query: {'mode': 'products'},
          ),
          const SizedBox(width: 16),
          _buildItem(
            id: 'printers',
            context: context,
            title: printers.length,
            subtitle: S.printerHeaderInfo,
            route: Routes.printer,
          ),
          const SizedBox(width: 16),
          _buildItem(
            id: 'order_attrs',
            context: context,
            title: attrs.length,
            subtitle: S.orderAttributeHeaderInfo,
            route: Routes.orderAttr,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String id,
    required BuildContext context,
    required int title,
    required String subtitle,
    required String route,
    Map<String, String> query = const <String, String>{},
  }) {
    const borderRadius = BorderRadius.all(Radius.circular(20));
    final theme = Theme.of(context);

    return ElevatedButton(
      key: Key('more_header.$id'),
      style: const ButtonStyle(
        fixedSize: WidgetStatePropertyAll(Size.square(128)),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        // shadowColor: WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: Colors.transparent),
        )),
      ),
      onPressed: () => context.goNamed(route, queryParameters: query),
      child: Ink(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: theme.gradientColors,
            tileMode: TileMode.clamp,
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title.toString(), style: theme.textTheme.headlineMedium),
          Flexible(child: Text(subtitle, textAlign: TextAlign.center)),
        ]),
      ),
    );
  }
}
