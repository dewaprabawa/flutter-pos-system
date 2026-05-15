import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/linkify.dart';
import 'package:possystem/components/menu_actions.dart';
import 'package:possystem/components/style/buttons.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/components/tutorial.dart';
import 'package:possystem/helpers/breakpoint.dart';
import 'package:possystem/models/repository/cart.dart';
import 'package:possystem/models/repository/menu.dart';
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

  @override
  Widget build(BuildContext context) {
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
                        icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                        onPressed: () {},
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
    super.dispose();
  }

  @override
  void initState() {
    WakelockPlus.toggle(enable: OrderAwakeningSetting.instance.value);
    // rebind menu/attributes if changed
    Cart.instance.rebind();

    _pageController = PageController();
    _catalogIndexNotifier = ValueNotifier<int>(0);
    super.initState();
  }

  void _handleCheckout() async {
    final status = await context.pushNamed<CheckoutStatus>(Routes.orderCheckout);
    if (status != null && mounted) {
      handleCheckoutStatus(context, status);
    }
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


