import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:possystem/components/linkify.dart';
import 'package:possystem/components/menu_actions.dart';
import 'package:possystem/components/style/buttons.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/components/tutorial.dart';
import 'package:possystem/helpers/breakpoint.dart';
import 'package:possystem/models/repository/cart.dart';
import 'package:possystem/models/repository/menu.dart';
import 'package:possystem/models/repository/notifications.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/settings/checkout_warning.dart';
import 'package:possystem/settings/order_awakening_setting.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/order/cart/cart_metadata_view.dart';
import 'package:possystem/ui/order/cart/cart_product_list.dart';
import 'package:possystem/ui/order/cart/cart_product_selector.dart';
import 'package:possystem/ui/order/widgets/printer_button_view.dart';
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
        body: Column(
          children: [
            Container(
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
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: Text(
                      S.title('order'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    centerTitle: false,
                    actions: [
                      IconButton(
                        icon: Consumer<Notifications>(
                          builder: (context, notifs, child) {
                            if (notifs.unreadCount > 0) {
                              return Badge(
                                label: Text(notifs.unreadCount.toString()),
                                child: const Icon(Icons.notifications, color: Colors.white),
                              );
                            }
                            return const Icon(Icons.notifications_none_outlined, color: Colors.white);
                          },
                        ),
                        onPressed: () => _showNotifications(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.lock_outline, color: Colors.white),
                        tooltip: 'Tutup Toko',
                        onPressed: () => context.pushNamed(Routes.tutupToko),
                      ),
                      const SizedBox(width: 8),
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                        child: Text('BU', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: S.menuSearchHint,
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.white),
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        filled: true,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
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
                            products: Menu.instance.searchProducts(text: _searchQuery).map((e) => e.product).toList(),
                          ),
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
                            onPageChanged: (index) => _catalogIndexNotifier.value = index,
                            itemCount: catalogs.length,
                            itemBuilder: (context, index) => OrderProductListView(
                              products: catalogs[index].itemList,
                            ),
                          ),
                        ),
                      ],
                    ],
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
    // rebind menu/attributes if changed
    Cart.instance.rebind();

    _pageController = PageController();
    _catalogIndexNotifier = ValueNotifier<int>(0);
    _searchController = TextEditingController();
    super.initState();
  }

  void _handleCheckout() async {
    final status = await context.pushNamed<CheckoutStatus>(Routes.orderCheckout);
    if (status != null && mounted) {
      handleCheckoutStatus(context, status);
    }
  }

  void _showNotifications(BuildContext context) {
    Notifications.instance.markAllAsRead();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                      const Text('Activity History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          child: const Icon(Icons.check_circle, color: Colors.blue),
                        ),
                        title: Text(item.title),
                        subtitle: Text(item.body),
                        trailing: Text(
                          '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
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

void handleCheckoutStatus(BuildContext context, CheckoutStatus status) {
  status = CheckoutWarningSetting.instance.shouldShow(status);

  if (status == CheckoutStatus.ok || status == CheckoutStatus.restore) {
    Notifications.instance.add(
      'Transaction Complete',
      'An order has been successfully completed and recorded.',
    );
  }

  return switch (status) {
    CheckoutStatus.ok || CheckoutStatus.stash || CheckoutStatus.restore => showSnackBar(
        'Transaksi Berhasil',
        context: context,
        backgroundColor: Colors.blue.shade700,
        icon: Icons.check_circle_outline,
      ),
    CheckoutStatus.cashierNotEnough => showSnackBar(S.orderSnackbarCashierNotEnough, context: context),
    CheckoutStatus.cashierUsingSmall => showMoreInfoSnackBar(
        S.orderSnackbarCashierUsingSmallMoney,
        Linkify.fromString(S.orderSnackbarCashierUsingSmallMoneyHelper(Routes.getRoute('settings/checkoutWarning'))),
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


