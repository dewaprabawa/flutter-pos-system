import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:possystem/components/dialog/confirm_dialog.dart';
import 'package:possystem/components/style/route_buttons.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/helpers/breakpoint.dart';
import 'package:possystem/models/repository/cashier.dart';
import 'package:possystem/models/repository/session_manager.dart';
import 'package:possystem/routes.dart';
import 'package:possystem/translator.dart';
import 'package:provider/provider.dart';

import 'package:possystem/ui/analysis/widgets/goals_card_view.dart';
import 'widgets/unit_list_tile.dart';

class CashierView extends StatelessWidget {
  const CashierView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUnitDialog(context),
        label: const Text('Tambah Unit', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF004D40), // Dark Teal
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column(
        children: [
          // ── Gradient Header ──
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Icon(Icons.storefront, color: Colors.teal.shade900),
                  const SizedBox(width: 8),
                  Text(
                    'Kasir',
                    style: TextStyle(
                        color: Colors.teal.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ],
              ),
              centerTitle: false,
              actions: [
                Consumer<SessionManager>(
                  builder: (context, session, _) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                            const SizedBox(width: 6),
                            Text(
                              session.currentSession?.cashierName ?? 'dew',
                              style: TextStyle(
                                  color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // ── Body ──
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Breakpoint.medium.max),
                child: ListenableBuilder(
                  listenable: Cashier.instance,
                  builder: (context, _) {
                    var i = 0;
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 80, top: 16),
                      children: [
                        _buildQuickActions(context),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GoalsCardView(
                            title: "Today's Summary",
                            action: TextButton.icon(
                              onPressed: () => context.pushNamed(Routes.history),
                              icon: const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                              label: Text('Records', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'DENOMINASI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final item in Cashier.instance.currentUnits)
                          UnitListTile(
                            item: item,
                            index: i++,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              title: 'Setelan Awal',
              icon: Cashier.instance.defaultNotSet
                  ? Icons.star_border
                  : Icons.star,
              onTap: () => _handleSetDefault(context),
              color: colorScheme.secondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              context,
              title: 'Tukar',
              icon: Icons.sync_alt,
              onTap: () => context.pushNamed(Routes.cashierChanger),
              color: colorScheme.tertiaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              context,
              title: 'Selisih',
              icon: Icons.coffee_outlined,
              onTap: () => _handleSurplus(context),
              color: colorScheme.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA), // Light grey
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.teal.shade900, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUnitDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Unit Baru'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Denominasi (Contoh: 75000)',
            prefixText: 'Rp ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final value = num.tryParse(controller.text);
              if (value != null && value > 0) {
                Cashier.instance.addUnit(value);
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _handleSetDefault(BuildContext context) async {
    if (!Cashier.instance.defaultNotSet) {
      final result = await ConfirmDialog.show(
        context,
        title: S.cashierToDefaultDialogTitle,
        content: S.cashierToDefaultDialogContent,
      );

      if (!result) {
        return;
      }
    }

    await Cashier.instance.setDefault();

    if (context.mounted) {
      showSnackBar(S.actSuccess, context: context);
    }
  }

  void _handleSurplus(BuildContext context) async {
    if (Cashier.instance.defaultNotSet) {
      return showSnackBar(S.cashierSurplusErrorEmptyDefault, context: context);
    }

    final result = await context.pushNamed(Routes.cashierSurplus);
    if (result == true) {
      if (context.mounted) {
        showSnackBar(S.actSuccess, context: context);
      }
    }
  }
}
