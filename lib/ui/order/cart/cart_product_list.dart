import 'package:flutter/material.dart';
import 'package:possystem/components/meta_block.dart';
import 'package:possystem/components/style/hint_text.dart';
import 'package:possystem/components/style/slide_to_delete.dart';
import 'package:possystem/constants/icons.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/order/cart_product.dart';
import 'package:possystem/models/repository/cart.dart';
import 'package:possystem/translator.dart';
import 'package:provider/provider.dart';

import 'cart_actions.dart';

class CartProductList extends StatefulWidget {
  final ScrollController? scrollController;

  final ValueNotifier<bool>? scrollable;

  const CartProductList({
    super.key,
    this.scrollController,
    this.scrollable,
  });

  @override
  State<CartProductList> createState() => _CartProductListState();
}

class _CartProductListState extends State<CartProductList> {
  late ScrollController scrollController;
  late final ValueNotifier<bool> scrollable;
  int lastLength = 0;

  @override
  Widget build(BuildContext context) {
    // if product length changed, rebuild it.
    final length = context.select<Cart, int>((cart) => cart.products.length);

    return ValueListenableBuilder(
      valueListenable: scrollable,
      builder: (context, value, child) {
        return ListView(
          key: const Key('cart.product_list'),
          controller: scrollController,
          physics: value ? null : const NeverScrollableScrollPhysics(),
          prototypeItem: const ListTile(title: Text('a'), subtitle: Text('a')),
          semanticChildCount: length,
          children: [
            if (length == 0)
              ListTile(
                title: Center(child: HintText(S.orderCartSnapshotEmpty)),
                subtitle: const Text(''),
              ),
            for (var i = 0; i < length; i++)
              SlideToDelete(
                item: Cart.instance.products[i],
                deleteCallback: () async => Cart.instance.removeAt(i),
                child: ChangeNotifierProvider<CartProduct>.value(
                  value: Cart.instance.products[i],
                  child: _CartProductListTile(i),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      scrollController.dispose();
    }
    Cart.instance.removeListener(scrollToBottomIfAdded);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    scrollable = widget.scrollable ?? ValueNotifier<bool>(true);
    scrollController = widget.scrollController ?? ScrollController();
    Cart.instance.addListener(scrollToBottomIfAdded);
  }

  Future<void> scrollToBottomIfAdded() async {
    final length = Cart.instance.products.length;
    final isAdded = lastLength < length;

    if (isAdded && mounted && lastLength != 0 || length != 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent - 30, // +80?
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    lastLength = length;
  }
}

class _CartProductListTile extends StatelessWidget {
  final int index;

  const _CartProductListTile(this.index);

  @override
  Widget build(BuildContext context) {
    final product = context.watch<CartProduct>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: product.product.image,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.totalPrice.toCurrency(),
                    style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _QuantityButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (product.count > 1) {
                      product.decrement();
                      Cart.instance.priceChanged();
                    } else {
                      Cart.instance.removeAt(index);
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    product.count.toString(),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add,
                  onTap: () {
                    product.increment();
                    Cart.instance.priceChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
    );
  }
}
