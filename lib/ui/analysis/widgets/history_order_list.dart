import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          Routes.historyOrder,
          pathParameters: {'id': order.id?.toString() ?? ''},
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1), // Light teal
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Color(0xFF00695C)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat.Hm(S.localeName).format(order.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF00695C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${order.periodSeq}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.outline,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF80F0E0), // Teal badge
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.paymentMethod.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF00695C),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.products
                          .map((p) => p.count == 1
                              ? p.productName
                              : '${p.productName} (x${p.count})')
                          .join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    order.price.toCurrency(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF004D40), // Dark Teal
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: colorScheme.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
