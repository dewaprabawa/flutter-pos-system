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
        label: const Text('Tambah Unit'),
        icon: const Icon(Icons.add),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // ── Gradient Header ──
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Kasir',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: false,
              actions: [
                Consumer<SessionManager>(
                  builder: (context, session, _) {
                    if (session.hasActiveSession) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Chip(
                          avatar: const Icon(Icons.circle,
                              color: Colors.greenAccent, size: 10),
                          label: Text(
                            session.currentSession?.cashierName ?? 'Kasir',
                            style: const TextStyle(
                                color: Colors.green, fontSize: 12),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          side: BorderSide.none,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
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
                            action: RouteIconButton(
                              key: const Key('anal.history'),
                              route: Routes.history,
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: S.analysisHistoryBtn,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
