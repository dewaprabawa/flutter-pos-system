import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/style/footer.dart';
import 'package:possystem/constants/app_themes.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/models/printer.dart';
import 'package:possystem/models/repository/menu.dart';
import 'package:possystem/models/repository/order_attributes.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/services/cache.dart';
import 'package:possystem/translator.dart';
import 'package:provider/provider.dart';

class MobileMoreView extends StatefulWidget {
  const MobileMoreView({super.key});

  @override
  State<MobileMoreView> createState() => _MobileMoreViewState();
}

class _MobileMoreViewState extends State<MobileMoreView> with AutomaticKeepAliveClientMixin {
  late String _userName;
  late String _userRole;

  @override
  void initState() {
    super.initState();
    _userName = Cache.instance.get<String>('profile.name') ?? 'Nama Toko';
    _userRole = Cache.instance.get<String>('profile.role') ?? 'Owner';
  }

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
              // ── Gradient Header with Editable Profile ──
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
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
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        automaticallyImplyLeading: false,
                        title: const Text(
                          'Lainnya',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        centerTitle: false,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: InkWell(
                          onTap: () => _showEditProfileSheet(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white24,
                                  child: Text(
                                    _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userName,
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _userRole,
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
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

  void _showEditProfileSheet(BuildContext context) {
    final nameController = TextEditingController(text: _userName);
    final roleController = TextEditingController(text: _userRole);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Profil',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko / Pemilik',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                  labelText: 'Peran (e.g. Owner, Manager)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Cache.instance.set<String>('profile.name', nameController.text);
                    await Cache.instance.set<String>('profile.role', roleController.text);
                    if (mounted) {
                      setState(() {
                        _userName = nameController.text;
                        _userRole = roleController.text;
                      });
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Simpan'),
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.outline,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
        trailing: Icon(Icons.chevron_right, size: 20, color: colorScheme.outline),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _HeaderInfoList extends StatelessWidget {
  const _HeaderInfoList();

  @override
  Widget build(BuildContext context) {
    final menu = context.watch<Menu>();
    final printers = context.watch<Printers>();
    final attrs = context.watch<OrderAttributes>();

    return SizedBox(
      height: 110,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
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
        fixedSize: WidgetStatePropertyAll(Size(110, 90)),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: Colors.transparent),
        )),
      ),
      onPressed: () => context.goNamed(route, queryParameters: query),
      child: Ink(
        width: 110,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.95),
              Colors.white.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            title.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
