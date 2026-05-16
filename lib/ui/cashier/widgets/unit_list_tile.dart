import 'package:flutter/material.dart';
import 'package:possystem/components/dialog/slider_text_dialog.dart';
import 'package:possystem/components/style/percentile_bar.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/helpers/validator.dart';
import 'package:possystem/models/objects/cashier_object.dart';
import 'package:possystem/models/repository/cashier.dart';
import 'package:possystem/translator.dart';

class UnitListTile extends StatelessWidget {
  final CashierUnitObject item;
  final int index;

  const UnitListTile({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = Cashier.instance.defaultAt(index)?.count ?? 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFFE0F2F1), // Light teal
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _setUnitCount(context, item.unit, max, item.count),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.unit.toCurrency(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00695C),
                        ),
                      ),
                    ),
                    Text(
                      '${item.count} / $max',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: max == 0 ? 0 : item.count / max,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF004D40)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setUnitCount(
    BuildContext context,
    num unit,
    num max,
    int value,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => SliderTextDialog(
        value: value,
        max: max.toDouble(),
        title: Text(S.cashierUnitLabel(unit.toCurrency())),
        validator: Validator.positiveInt(S.cashierCounterLabel),
        decoration: InputDecoration(label: Text(S.cashierCounterLabel)),
      ),
    );

    if (result != null) {
      await Cashier.instance.setUnitCount(unit, int.tryParse(result) ?? 0);
    }
  }
}
