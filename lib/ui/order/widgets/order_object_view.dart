import 'package:flutter/material.dart';
import 'package:possystem/components/style/outlined_text.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/objects/order_object.dart';
import 'package:possystem/translator.dart';

class OrderObjectView extends StatelessWidget {
  final OrderObject order;
  final double bottomPadding;

  const OrderObjectView({
    super.key,
    required this.order,
    this.bottomPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReceiptSection(
            title: S.orderObjectViewDividerProduct,
            child: Column(
              children: [
                for (final product in order.products) _ProductItem(product),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(),
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
                const SizedBox(height: 12),
                _TotalRow(
                  label: S.orderObjectViewPriceTotal(''),
                  value: order.price.toCurrency(),
                  isBold: true,
                  fontSize: 24,
                  color: colorScheme.primary,
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
                  for (final attribute in order.attributes) _AttributeItem(attribute),
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
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final OrderProductObject data;
  const _ProductItem(this.data);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${data.count}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.productName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (data.ingredients.isNotEmpty)
                  Text(
                    data.ingredients.map((e) => e.ingredientName).join(', '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            data.totalPrice.toCurrency(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
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
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
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
    this.isBold = false,
    this.fontSize,
    this.color,
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
