import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:possystem/components/style/hint_text.dart';
import 'package:possystem/components/style/pop_button.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/helpers/breakpoint.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/repository/cart.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/order/checkout/checkout_cashier_calculator.dart';
import 'package:possystem/ui/order/checkout/checkout_cashier_snapshot.dart';
import 'package:possystem/ui/order/checkout/stashed_order_list_view.dart';
import 'package:possystem/ui/order/widgets/order_object_view.dart';

import 'checkout/checkout_attribute_view.dart';

class OrderCheckoutPage extends StatefulWidget {
  const OrderCheckoutPage({super.key});

  @override
  State<OrderCheckoutPage> createState() => _OrderCheckoutPageState();
}

class _OrderCheckoutPageState extends State<OrderCheckoutPage> {
  late final ValueNotifier<num> paid;

  late final ValueNotifier<num> price;

  final ValueNotifier<int> viewIndex = ValueNotifier(0);

  final ValueNotifier<String> paymentMethod = ValueNotifier('Tunai');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      return Breakpoint.find(width: constraint.maxWidth) <= Breakpoint.medium
          ? _Mobile(
              paid: paid,
              price: price,
              viewIndex: viewIndex,
              paymentMethod: paymentMethod,
            )
          : _Desktop(
              paid: paid,
              price: price,
              viewIndex: viewIndex,
              paymentMethod: paymentMethod,
            );
    });
  }

  @override
  void initState() {
    super.initState();

    price = ValueNotifier(Cart.instance.price);
    paid = ValueNotifier(price.value);
    price.addListener(() => paid.value = price.value);
  }

  @override
  void dispose() {
    price.dispose();
    paid.dispose();
    super.dispose();
  }
}

class _Mobile extends StatefulWidget {
  final ValueNotifier<num> paid;

  final ValueNotifier<num> price;

  final ValueNotifier<int> viewIndex;

  final ValueNotifier<String> paymentMethod;

  const _Mobile({
    required this.paid,
    required this.price,
    required this.viewIndex,
    required this.paymentMethod,
  });

  @override
  State<_Mobile> createState() => _MobileState();
}

class _MobileState extends State<_Mobile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const PopButton(),
        title: Text(S.orderActionCheckout),
        actions: Cart.instance.isEmpty
            ? null
            : <Widget>[
                const _StashButton(),
              ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Cart.instance.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: widget.paid,
                        builder: (context, value, child) => Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.orderCartMetaTotalPrice(value.toCurrency()),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              S.orderObjectViewPriceTotal(
                                  widget.price.value.toCurrency()),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ListenableBuilder(
                      listenable: Cart.instance,
                      builder: (context, child) {
                        return ElevatedButton(
                          onPressed: () => _ConfirmButton.confirm(context,
                              paid: widget.paid.value,
                              paymentMethod: widget.paymentMethod.value),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            minimumSize: const Size(160, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            '${S.orderCheckoutActionConfirm} (${Cart.instance.productCount})',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (Cart.instance.isEmpty) {
      return Center(child: HintText(S.orderCheckoutEmptyCart));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ValueListenableBuilder<String>(
              valueListenable: widget.paymentMethod,
              builder: (context, method, child) {
                return Column(
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Tunai', label: Text('Tunai')),
                        ButtonSegment(value: 'QRIS', label: Text('QRIS')),
                        ButtonSegment(value: 'Kartu', label: Text('Kartu')),
                      ],
                      selected: {method},
                      onSelectionChanged: (set) =>
                          widget.paymentMethod.value = set.first,
                    ),
                    if (method != 'Tunai') ...[
                      const SizedBox(height: 12),
                      ListenableBuilder(
                        listenable: Cart.instance,
                        builder: (context, child) {
                          final hasImage = Cart.instance.imagePath != null;
                          return OutlinedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                  source: ImageSource.camera);
                              if (image != null) {
                                Cart.instance.updateImagePath(image.path);
                              }
                            },
                            icon: Icon(
                                hasImage
                                    ? Icons.check_circle
                                    : Icons.camera_alt,
                                color: hasImage ? Colors.green : null),
                            label: Text(hasImage
                                ? 'Bukti Tersimpan'
                                : 'Ambil Bukti Pembayaran'),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          CheckoutAttributeView(price: widget.price),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(),
          ),
          ListenableBuilder(
            listenable: Cart.instance,
            child: null,
            builder: (context, child) => ValueListenableBuilder(
              valueListenable: widget.paid,
              builder: (context, value, child) => OrderObjectView(
                order: Cart.instance.toObject(paid: value),
                bottomPadding: 100, // Extra space for the sticky bottom bar
                onDelete: (index) {
                  Cart.instance.removeAt(index);
                  if (Cart.instance.isEmpty) {
                    context.pop();
                  } else {
                    widget.price.value = Cart.instance.price;
                  }
                },
                onIncrement: (index, count) {
                  Cart.instance.products[index].count = count;
                  Cart.instance.priceChanged();
                  widget.price.value = Cart.instance.price;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class _Desktop extends StatelessWidget {
  final ValueNotifier<num> paid;

  final ValueNotifier<num> price;

  final ValueNotifier<int> viewIndex;

  final ValueNotifier<String> paymentMethod;

  const _Desktop({
    required this.paid,
    required this.price,
    required this.viewIndex,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    Widget? child;
    if (!Cart.instance.isEmpty) {
      child = SizedBox(
        width: 360,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kHorizontalSpacing,
                kTopSpacing,
                kHorizontalSpacing,
                kInternalSpacing,
              ),
              child: SizedBox(
                height: 36,
                child: CheckoutCashierSnapshot(
                    price: price, paid: paid, showChange: false),
              ),
            ),
            Expanded(
              child: CheckoutCashierCalculator(
                onSubmit: () => _ConfirmButton.confirm(context,
                    paid: paid.value, paymentMethod: paymentMethod.value),
                price: price,
                paid: paid,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const PopButton(),
        actions: Cart.instance.isEmpty
            ? null
            : [
                const _StashButton(),
                _ConfirmButton(
                    price: price, paid: paid, paymentMethod: paymentMethod),
              ],
      ),
      body: ListenableBuilder(
        listenable: viewIndex,
        builder: (context, calculator) {
          return Row(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(children: [
                      _buildSwitcher(),
                      Expanded(child: _buildBody(context)),
                    ]),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              if (calculator != null) calculator,
            ],
          );
        },
        child: child,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (viewIndex.value == 0) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ValueListenableBuilder<String>(
              valueListenable: paymentMethod,
              builder: (context, method, child) {
                return Column(
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Tunai', label: Text('Tunai')),
                        ButtonSegment(value: 'QRIS', label: Text('QRIS')),
                        ButtonSegment(value: 'Kartu', label: Text('Kartu')),
                      ],
                      selected: {method},
                      onSelectionChanged: (set) =>
                          paymentMethod.value = set.first,
                    ),
                    if (method != 'Tunai') ...[
                      const SizedBox(height: 12),
                      ListenableBuilder(
                        listenable: Cart.instance,
                        builder: (context, child) {
                          final hasImage = Cart.instance.imagePath != null;
                          return OutlinedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                  source: ImageSource.camera);
                              if (image != null) {
                                Cart.instance.updateImagePath(image.path);
                              }
                            },
                            icon: Icon(
                                hasImage
                                    ? Icons.check_circle
                                    : Icons.camera_alt,
                                color: hasImage ? Colors.green : null),
                            label: Text(hasImage
                                ? 'Bukti Tersimpan'
                                : 'Ambil Bukti Pembayaran'),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          Expanded(child: CheckoutAttributeView(price: price)),
        ],
      );
    }

    if (viewIndex.value == 1) {
      if (Cart.instance.isEmpty) {
        return Center(child: HintText(S.orderCheckoutEmptyCart));
      }

      return ListenableBuilder(
        listenable: Cart.instance,
        child: null,
        builder: (context, child) => ValueListenableBuilder(
          valueListenable: paid,
          builder: (context, value, child) => OrderObjectView(
            order: Cart.instance.toObject(paid: value),
            onDelete: (index) {
              Cart.instance.removeAt(index);
              if (Cart.instance.isEmpty) {
                viewIndex.value = 0;
              }
              price.value = Cart.instance.price;
            },
            onIncrement: (index, count) {
              Cart.instance.products[index].count = count;
              Cart.instance.priceChanged();
              price.value = Cart.instance.price;
            },
          ),
        ),
      );
    }

    return const StashedOrderListView();
  }

  Widget _buildSwitcher() {
    return SegmentedButton<int>(
      selected: {viewIndex.value},
      onSelectionChanged: (value) => viewIndex.value = value.first,
      segments: [
        ButtonSegment(value: 0, label: Text(S.orderCheckoutAttributeTab)),
        ButtonSegment(value: 1, label: Text(S.orderCheckoutDetailsTab)),
        ButtonSegment(value: 2, label: Text(S.orderCheckoutStashTab)),
      ],
    );
  }
}

class _StashButton extends StatelessWidget {
  const _StashButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('order.details.stash'),
      onPressed: () async {
        final ok = await Cart.instance.stash();
        if (context.mounted && ok && context.canPop()) {
          context.pop(CheckoutStatus.stash);
        }
      },
      tooltip: S.orderCheckoutActionStash,
      icon: const Icon(Icons.archive_outlined),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final ValueNotifier<num> paid;

  final ValueNotifier<num> price;

  final ValueNotifier<String> paymentMethod;

  const _ConfirmButton(
      {required this.price, required this.paid, required this.paymentMethod});

  static void confirm(BuildContext context,
      {required num paid, required String paymentMethod}) async {
    final future = Cart.instance
        .checkout(paid: paid, paymentMethod: paymentMethod, context: context);
    final status = await showSnackbarWhenFutureError(future, 'order_checkout',
        context: context);

    if (context.mounted && status != null) {
      if (status == CheckoutStatus.paidNotEnough) {
        showSnackBar(S.orderCheckoutSnackbarPaidFailed, context: context);
      } else if (context.canPop()) {
        // send success message
        context.pop(status);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('order.details.confirm'),
      onPressed: () => confirm(context,
          paid: paid.value, paymentMethod: paymentMethod.value),
      tooltip: S.orderCheckoutActionConfirm,
      icon: const Icon(Icons.check_outlined),
    );
  }
}
