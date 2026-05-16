import 'dart:io';

import 'package:flutter/material.dart';
import 'package:possystem/components/style/outlined_text.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/objects/order_object.dart';
import 'package:possystem/translator.dart';

class OrderObjectView extends StatelessWidget {
  final OrderObject order;
  final double bottomPadding;
  final void Function(int index)? onDelete;
  final void Function(int index, int count)? onIncrement;

  const OrderObjectView({
    super.key,
    required this.order,
    this.bottomPadding = 16.0,
    this.onDelete,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'TOTAL TRANSAKSI',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  order.price.toCurrency(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ReceiptSection(
            title: S.orderObjectViewDividerProduct,
            child: Column(
              children: [
                for (var i = 0; i < order.products.length; i++)
                  _ProductItem(
                    order.products[i],
                    onDelete: onDelete == null ? null : () => onDelete!(i),
                    onIncrement: onIncrement == null
                        ? null
                        : (count) => onIncrement!(i, count),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(height: 1),
                ),
                _TotalRow(
                  label: S.orderObjectViewPriceProducts,
                  value: order.productsPrice.toCurrency(),
                ),
                if (order.attributesPrice != 0)
                  _TotalRow(
                    label: S.orderObjectViewPriceAttributes,
                    value: order.attributesPrice.toCurrency(),
                  ),
              ],
            ),
          ),
          if (order.attributes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ReceiptSection(
              title: S.orderObjectViewDividerAttribute,
              child: Column(
                children: [
                  for (final attribute in order.attributes)
                    _AttributeItem(attribute),
                ],
              ),
            ),
          ],
          if (order.note.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ReceiptSection(
              title: S.orderObjectViewNote,
              child: Text(
                order.note,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
          if (order.imagePath != null && order.imagePath!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ReceiptSection(
              title: 'Bukti Pembayaran',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(
                  File(order.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    color: theme.colorScheme.errorContainer,
                    child: Center(
                      child: Icon(Icons.broken_image,
                          color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }
}

class _ReceiptSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReceiptSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final OrderProductObject data;
  final VoidCallback? onDelete;
  final void Function(int count)? onIncrement;
  const _ProductItem(this.data, {this.onDelete, this.onIncrement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.productName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  data.totalPrice.toCurrency(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (onIncrement != null) ...[
            _QuantityBtn(
              icon: Icons.remove,
              onTap: () {
                if (data.count > 1) {
                  onIncrement!(data.count - 1);
                } else if (onDelete != null) {
                  onDelete!();
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${data.count}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            _QuantityBtn(
              icon: Icons.add,
              onTap: () => onIncrement!(data.count + 1),
            ),
          ] else
            Text(
              'x${data.count}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

class _QuantityBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: theme.colorScheme.primary),
      ),
    );
  }
}

class _AttributeItem extends StatelessWidget {
  final OrderSelectedAttributeObject attribute;
  const _AttributeItem(this.attribute);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            attribute.name,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              attribute.optionName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final double? fontSize;
  final Color? color;

  const _TotalRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
