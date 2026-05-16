import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:possystem/components/linkify.dart';
import 'package:possystem/components/menu_actions.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/components/tutorial.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/menu/combo_product.dart';
import 'package:possystem/models/menu/product.dart';
import 'package:possystem/models/repository/cart.dart';
import 'package:possystem/models/repository/combos_manager.dart';
import 'package:possystem/models/repository/menu.dart';
import 'package:possystem/models/repository/notifications.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/settings/checkout_warning.dart';
import 'package:possystem/settings/order_awakening_setting.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/order/widgets/cart_summary_widget.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'widgets/order_catalog_list_view.dart';
import 'widgets/order_product_list_view.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late final PageController _pageController;

  /// Change the catalog index and pass to [OrderProductListView] and [OrderCatalogListView]
  late final ValueNotifier<int> _catalogIndexNotifier;

  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Watch Menu to refresh when categories or products are added
    context.watch<Menu>();

    final catalogs = Menu.instance.notEmptyItems;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TutorialWrapper(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF8F9FA), // Light grey background
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Row(
                      children: [
                        Icon(Icons.storefront, color: Colors.teal.shade900),
                        const SizedBox(width: 8),
                        Text(
                          'MokkonPOS',
                          style: TextStyle(
                              color: Colors.teal.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                      ],
                    ),
                    centerTitle: false,
                    actions: [
                      IconButton(
                        icon: Consumer<Notifications>(
                          builder: (context, notifs, child) {
                            return Icon(
                              notifs.unreadCount > 0
                                  ? Icons.notifications_active_outlined
                                  : Icons.notifications_none_outlined,
                              color: Colors.teal.shade900,
                            );
                          },
                        ),
                        onPressed: () => _showNotifications(context),
                      ),
                      IconButton(
                        icon: Icon(Icons.lock_outline,
                            color: Colors.teal.shade900),
                        tooltip: 'Tutup Toko',
                        onPressed: () => context.pushNamed(Routes.tutupToko),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF80F0E0),
                        child: Text(
                          'BU',
                          style: TextStyle(
                              color: Colors.teal.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF004D40), // Dark Teal
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search for products, ingredients, q...',
                          hintStyle:
                              TextStyle(color: Colors.black, fontSize: 14),
                          prefixIcon: const Icon(Icons.search,
                              size: 20, color: Colors.black),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      if (_searchQuery.isNotEmpty)
                        Expanded(
                          child: OrderProductListView(
                            products: Menu.instance
                                .searchProducts(text: _searchQuery)
                                .map((e) => e.product)
                                .toList(),
                          ),
                        )
                      else if (catalogs.isEmpty)
                        Expanded(
                          child:
                              _buildEmptyMenuState(context, colorScheme, theme),
                        )
                      else ...[
                        OrderCatalogListView(
                          catalogs: catalogs,
                          indexNotifier: _catalogIndexNotifier,
                          onSelected: (index) => _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) =>
                                _catalogIndexNotifier.value = index,
                            itemCount: catalogs.length,
                            itemBuilder: (context, index) =>
                                OrderProductListView(
                              products: catalogs[index].itemList,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Paket / Combo quick-access button (only when combos exist)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 80,
                    child: Consumer<CombosManager>(
                      builder: (context, manager, _) {
                        if (manager.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GestureDetector(
                            onTap: () => _showPaketSheet(context, manager),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF004D40), Color(0xFF00695C)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF004D40).withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_offer, color: Colors.white, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${manager.combos.length} Paket Tersedia — Tap untuk lihat',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: CartSummaryWidget(
                      onCheckout: _handleCheckout,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _pageController.dispose();
    _catalogIndexNotifier.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    WakelockPlus.toggle(enable: OrderAwakeningSetting.instance.value);
    Cart.instance.rebind();

    _pageController = PageController();
    _catalogIndexNotifier = ValueNotifier<int>(0);
    _searchController = TextEditingController();
    super.initState();
  }

  void _showPaketSheet(BuildContext context, CombosManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaketSheet(manager: manager),
    );
  }

  Widget _buildEmptyMenuState(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Menu Masih Kosong',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan kategori dan produk untuk mulai menerima pesanan',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.pushNamed(Routes.menuCatalogCreate),
                icon: const Icon(Icons.add),
                label: const Text('Buat Kategori Baru'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.goNamed(Routes.menu),
                icon: const Icon(Icons.grid_view_outlined),
                label: const Text('Kelola Menu'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCheckout() async {
    final status =
        await context.pushNamed<CheckoutStatus>(Routes.orderCheckout);
    if (status != null && mounted) {
      handleCheckoutStatus(context, status);
    }
  }

  void _showNotifications(BuildContext context) {
    Notifications.instance.markAllAsRead();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Consumer<Notifications>(
          builder: (context, notifs, child) {
            if (notifs.items.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('No recent activity')),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Activity History',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          notifs.clearAll();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: notifs.items.length,
                    itemBuilder: (context, index) {
                      final item = notifs.items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.check_circle,
                              color: Colors.blue),
                        ),
                        title: Text(item.title),
                        subtitle: Text(item.body),
                        trailing: Text(
                          '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showActions(BuildContext context) async {
    final result = await showPositionedMenu<_Action>(
      context,
      actions: [
        MenuAction(
          key: const Key('order.action.exchange'),
          title: Text(S.orderActionExchange),
          leading: const Icon(Icons.change_circle_outlined),
          returnValue: const _Action(route: Routes.cashierChanger),
        ),
        MenuAction(
          key: const Key('order.action.stash'),
          title: Text(S.orderActionStash),
          leading: const Icon(Icons.archive_outlined),
          returnValue: _Action(action: _handleStash),
        ),
        MenuAction(
          key: const Key('order.action.history'),
          title: Text(S.orderActionReview),
          leading: const Icon(Icons.history_outlined),
          returnValue: const _Action(route: Routes.history),
        ),
      ],
    );

    if (context.mounted && result != null) {
      final success = await result.exec(context);

      if (success == true && context.mounted) {
        showSnackBar(S.actSuccess, context: context);
      }
    }
  }

  Future<bool?> _handleStash() {
    DraggableScrollableActuator.reset(context);
    return Cart.instance.stash();
  }
}

class _PaketSheet extends StatelessWidget {
  final CombosManager manager;

  const _PaketSheet({required this.manager});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.local_offer, color: Color(0xFF004D40)),
                const SizedBox(width: 12),
                const Text(
                  'Daftar Paket & Combo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: manager.combos.length,
              itemBuilder: (context, index) {
                return _PaketCard(combo: manager.combos[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaketCard extends StatelessWidget {
  final ComboProduct combo;

  const _PaketCard({required this.combo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        combo.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF004D40),
                        ),
                      ),
                      if (combo.description.isNotEmpty)
                        Text(
                          combo.description,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                Text(
                  combo.price.toCurrency(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF004D40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final item in combo.items)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Text(
                      '${item.qty}x ${item.productName}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addToCart(context),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Tambah Paket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    int added = 0;
    for (final item in combo.items) {
      final product = _findProduct(item.productId);
      if (product != null) {
        for (int i = 0; i < item.qty; i++) {
          Cart.instance.add(product);
          added++;
        }
      }
    }

    if (added > 0) {
      Navigator.pop(context);
      showSnackBar('${combo.name} ditambahkan!', context: context);
    }
  }

  Product? _findProduct(String id) {
    for (final catalog in Menu.instance.itemList) {
      for (final p in catalog.itemList) {
        if (p.id == id) return p;
      }
    }
    return null;
  }
}

void handleCheckoutStatus(BuildContext context, CheckoutStatus status) {
  status = CheckoutWarningSetting.instance.shouldShow(status);

  if (status == CheckoutStatus.ok || status == CheckoutStatus.restore) {
    Notifications.instance.add(
      'Transaction Complete',
      'An order has been successfully completed and recorded.',
    );
  }

  return switch (status) {
    CheckoutStatus.ok ||
    CheckoutStatus.stash ||
    CheckoutStatus.restore =>
      showSnackBar(
        'Transaksi Berhasil',
        context: context,
        backgroundColor: Colors.blue.shade700,
        icon: Icons.check_circle_outline,
      ),
    CheckoutStatus.cashierNotEnough =>
      showSnackBar(S.orderSnackbarCashierNotEnough, context: context),
    CheckoutStatus.cashierUsingSmall => showMoreInfoSnackBar(
        S.orderSnackbarCashierUsingSmallMoney,
        Linkify.fromString(S.orderSnackbarCashierUsingSmallMoneyHelper(
            Routes.getRoute('settings/checkoutWarning'))),
        context: context,
      ),
    _ => null,
  };
}

/// [DraggableScrollableActuator] will trigger `animateTo` while building widget
/// which will cause `setState` to be called during build.
///
/// This notifier is used to avoid this issue.
class _Notifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

class _Action {
  final Future<bool?> Function()? action;

  final String? route;

  const _Action({this.action, this.route});

  Future<bool?> exec(BuildContext context) {
    return route == null ? action!() : context.pushNamed(route!);
  }
}
