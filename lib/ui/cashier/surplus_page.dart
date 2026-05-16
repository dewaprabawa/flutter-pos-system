import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/dialog/responsive_dialog.dart';
import 'package:possystem/components/dialog/single_text_dialog.dart';
import 'package:possystem/components/style/hint_text.dart';
import 'package:possystem/components/style/info_popup.dart';
import 'package:possystem/constants/constant.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/helpers/validator.dart';
import 'package:possystem/models/repository/cashier.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/cashier/widgets/surplus_report_dialog.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CashierSurplus extends StatelessWidget {
  const CashierSurplus({super.key});

  @override
  Widget build(BuildContext context) {
    final cashier = context.watch<Cashier>();
    final theme = Theme.of(context);

    final columns = <DataColumn>[
      DataColumn(label: Text(S.cashierSurplusColumnName('unit')), numeric: true),
      DataColumn(label: Text(S.cashierSurplusColumnName('currentCount')), numeric: true),
      DataColumn(label: Text(S.cashierSurplusColumnName('diffCount'))),
      DataColumn(label: Text(S.cashierSurplusColumnName('defaultCount')), numeric: true),
    ];

    final rows = <DataRow>[
      for (final e in cashier.getDifference())
        DataRow(cells: <DataCell>[
          DataCell(Text(e.unit.toCurrency())),
          generateCell(e.currentCount, onTap: () => _handleTap(context, e)),
          generateCell(e.diffCount, withSign: true),
          generateCell(e.defaultCount),
        ]),
    ];

    return ResponsiveDialog(
      title: Text(S.cashierSurplusButton),
      action: TextButton(
        key: const Key('cashier_surplus.confirm'),
        onPressed: () async {
          await Cashier.instance.surplus();
          if (context.mounted && context.canPop()) {
            context.pop(true);
          }
        },
        child: Text(MaterialLocalizations.of(context).okButtonLabel),
      ),
      content: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(children: [
            Expanded(
              child: _SummaryCard(
                title: cashier.currentTotal.toCurrency(),
                subtitle: S.cashierSurplusCurrentTotalLabel,
                color: theme.colorScheme.primary,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: (cashier.currentTotal - cashier.defaultTotal).toCurrency(),
                subtitle: S.cashierSurplusDiffTotalLabel,
                color: (cashier.currentTotal - cashier.defaultTotal) == 0 
                    ? Colors.green 
                    : Colors.orange,
                icon: Icons.difference_outlined,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => SurplusReportDialog(cashier: cashier),
            ),
            icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
            label: const Text('Kirim Laporan Tutup Toko'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.cashierSurplusTableHint,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainerHighest),
                    columnSpacing: 24,
                    columns: columns, 
                    rows: rows,
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  DataCell generateCell(
    int value, {
    bool withSign = false,
    VoidCallback? onTap,
  }) {
    return DataCell(
      Text(
        withSign ? '${value > 0 ? '+' : ''}$value' : value.toString(),
        textAlign: withSign ? TextAlign.left : TextAlign.right,
      ),
      showEditIcon: onTap != null,
      onTap: onTap,
    );
  }

  void _handleTap(BuildContext context, CashierDiffItem item) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => SingleTextDialog(
        validator: Validator.positiveInt(S.cashierSurplusCounterShortLabel),
        keyboardType: TextInputType.number,
        selectAll: true,
        initialValue: item.currentCount.toString(),
        title: Text(S.cashierSurplusCounterLabel(item.unit.toCurrency())),
      ),
    );

    if (result is String) {
      final value = int.parse(result);
      await Cashier.instance.setCurrentByUnit(item.unit, value);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
