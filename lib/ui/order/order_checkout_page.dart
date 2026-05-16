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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const PopButton(color: Color(0xFF004D40)),
        title: const Text(
          'Bayar',
          style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront, color: Color(0xFF004D40)),
            onPressed: () {},
          ),
          if (!Cart.instance.isEmpty) const _StashButton(),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Cart.instance.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                            const Text(
                              'Price:',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Text(
                              value.toCurrency(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF327E73),
                              ),
                            ),
                            Text(
                              'Total Price: ${widget.price.value.toCurrency()}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
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
                              paid: widget.paid.value, paymentMethod: widget.paymentMethod.value),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004D40),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Konfirmasi (${Cart.instance.productCount})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payment Method Selector
          ValueListenableBuilder<String>(
            valueListenable: widget.paymentMethod,
            builder: (context, method, child) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildPaymentChip('TUNAI', method),
                        _buildPaymentChip('QRIS', method),
                        _buildPaymentChip('KARTU', method),
                      ],
                    ),
                  ),
                  if (method.toUpperCase() != 'TUNAI') ...[
                    const SizedBox(height: 12),
                    ListenableBuilder(
                      listenable: Cart.instance,
                      builder: (context, child) {
                        final hasImage = Cart.instance.imagePath != null;
                        return GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.camera);
                            if (image != null) {
                              Cart.instance.updateImagePath(image.path);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: hasImage ? const Color(0xFFE0F2F1) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: hasImage ? const Color(0xFF004D40) : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  hasImage ? Icons.check_circle : Icons.camera_alt_outlined,
                                  color: hasImage ? const Color(0xFF004D40) : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  hasImage ? 'Bukti Pembayaran Terlampir' : 'Ambil Bukti Pembayaran',
                                  style: TextStyle(
                                    color: hasImage ? const Color(0xFF004D40) : Colors.grey.shade600,
                                    fontWeight: hasImage ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                if (hasImage)
                                  GestureDetector(
                                    onTap: () => Cart.instance.updateImagePath(null),
                                    child: const Icon(Icons.close, size: 18, color: Color(0xFF004D40)),
                                  )
                                else
                                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Note Section
          const Text(
            'CATATAN',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Beberapa instruksi untuk pesanan ini',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
                Text(
                  '0/200',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Total Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL TRANSAKSI',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF327E73),
                      letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder(
                  valueListenable: widget.paid,
                  builder: (context, value, child) => Text(
                    value.toCurrency(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF327E73),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Product Information
          const Text(
            'PRODUCT INFORMATION',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: ListenableBuilder(
              listenable: Cart.instance,
              builder: (context, child) => Column(
                children: Cart.instance.products.asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        product.singlePrice.toCurrency(),
                                        style: const TextStyle(
                                            color: Color(0xFF327E73),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          if (product.count > 1) {
                                            product.count--;
                                            Cart.instance.priceChanged();
                                            widget.price.value = Cart.instance.price;
                                          } else {
                                            Cart.instance.removeAt(index);
                                            if (Cart.instance.isEmpty) context.pop();
                                          }
                                        },
                                        icon: const Icon(Icons.remove, size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          '${product.count}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          product.count++;
                                          Cart.instance.priceChanged();
                                          widget.price.value = Cart.instance.price;
                                        },
                                        icon: const Icon(Icons.add, size: 16, color: Color(0xFF327E73)),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Product Price',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                Text(
                                  product.totalPrice.toCurrency(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (index != Cart.instance.products.length - 1) const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPaymentChip(String label, String currentMethod) {
    final isSelected = currentMethod.toUpperCase() == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.paymentMethod.value =
            label[0] + label.substring(1).toLowerCase(), // Tunai, Qris, Kartu
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                const Icon(Icons.check, size: 14, color: Color(0xFF004D40)),
              if (isSelected) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF004D40) : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
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
