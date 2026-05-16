import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/style/image_holder.dart';
import 'package:possystem/models/xfile.dart';
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

class _MobileMoreViewState extends State<MobileMoreView>
    with AutomaticKeepAliveClientMixin {
  late String _userName;
  late String _userRole;
  String? _userImage;

  @override
  void initState() {
    super.initState();
    _userName = Cache.instance.get<String>('profile.name') ?? 'Nama Toko';
    _userRole = Cache.instance.get<String>('profile.role') ?? 'Owner';
    _userImage = Cache.instance.get<String>('profile.image');
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
                child: Column(
                  children: [
                    // White Top Bar
                    Container(
                      color: Colors.white,
                      child: AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        automaticallyImplyLeading: false,
                        title: Row(
                          children: [
                            Icon(Icons.storefront, color: Colors.teal.shade900),
                            const SizedBox(width: 8),
                            Text(
                              'Profile Toko',
                              style: TextStyle(
                                  color: Colors.teal.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ],
                        ),
                        actions: [
                          IconButton(
                            icon: Icon(Icons.notifications_outlined,
                                color: Colors.teal.shade900),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    // Teal Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      decoration: const BoxDecoration(
                        color: Color(0xFF327E73), // Specific Teal
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Lainnya',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.settings,
                                      color: Colors.white, size: 20),
                                  onPressed: () =>
                                      context.pushNamed(Routes.settings),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Profile Card
                          InkWell(
                            onTap: () => _showEditProfileSheet(context),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _userImage != null &&
                                            _userImage!.isNotEmpty
                                        ? FileImage(File(_userImage!))
                                        : null,
                                    child: _userImage == null
                                        ? Text(
                                            _userName.isNotEmpty
                                                ? _userName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                color: Color(0xFF327E73),
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _userName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          _userRole,
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.edit_outlined,
                                      color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _HeaderInfoList(),
                        ],
                      ),
                    ),
                  ],
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
                    const SizedBox(height: 16),
                    _buildUpgradeBanner(),
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
    String? tempImage = _userImage;

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
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              StatefulBuilder(
                builder: (context, setState) => Center(
                  child: EditImageHolder(
                    path: tempImage,
                    onSelected: (path) => setState(() => tempImage = path),
                    size: 100,
                  ),
                ),
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
                    await Cache.instance
                        .set<String>('profile.name', nameController.text);
                    await Cache.instance
                        .set<String>('profile.role', roleController.text);
                    await Cache.instance
                        .set<String>('profile.image', tempImage ?? '');
                    if (mounted) {
                      setState(() {
                        _userName = nameController.text;
                        _userRole = roleController.text;
                        _userImage =
                            (tempImage?.isEmpty ?? true) ? null : tempImage;
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
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Colors.grey.shade600,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        key: Key('home.$id'),
        onTap: () => context.goNamed(route),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
        trailing:
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildUpgradeBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E524D), // Dark Teal
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MokkonPOS Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Unlock multi-outlet reports and advanced inventory analytics.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E524D),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text(
              'Upgrade Now',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
      height: 90,
      child: Row(
        children: [
          Expanded(
            child: _buildItem(
              id: 'products',
              context: context,
              title: menu.items.fold<int>(0, (v, e) => e.length + v),
              subtitle: 'Products',
              route: Routes.menu,
              query: {'mode': 'products'},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildItem(
              id: 'printers',
              context: context,
              title: printers.length,
              subtitle: 'Printers',
              route: Routes.printer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildItem(
              id: 'order_attrs',
              context: context,
              title: attrs.length,
              subtitle: 'Customer Settings',
              route: Routes.orderAttr,
            ),
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

    return InkWell(
      onTap: () => context.goNamed(route, queryParameters: query),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
