import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:possystem/components/meta_block.dart';
import 'package:possystem/components/models/order_loader.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/objects/order_object.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/translator.dart';

class HistoryOrderList extends StatelessWidget {
  final ValueNotifier<DateTimeRange> notifier;

  const HistoryOrderList({
    super.key,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return OrderLoader(
      builder: _buildOrder,
      ranger: notifier,
    );
  }

  Widget _buildOrder(BuildContext context, OrderObject order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        key: Key('history.order.${order.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat.Hm(S.localeName).format(order.createdAt),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            order.products.map((p) => p.count == 1 ? p.productName : '${p.productName} (x${p.count})').join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, size: 14, color: colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  S.analysisHistoryOrderListMetaNo(order.periodSeq.toString()),
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                ),
                const SizedBox(width: 12),
                Icon(Icons.payments_outlined, size: 14, color: colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  order.price.toCurrency(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.pushNamed(
          Routes.historyOrder,
          pathParameters: {'id': order.id?.toString() ?? ''},
        ),
      ),
    );
  }
}
