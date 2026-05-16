import 'package:flutter/material.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/menu/combo_product.dart';
import 'package:possystem/models/repository/cart.dart';
import 'package:possystem/models/repository/combos_manager.dart';
import 'package:possystem/models/repository/menu.dart';
import 'package:provider/provider.dart';

import 'widgets/combo_modal.dart';

/// Page to manage all combos/packages from the Menu section.
class ComboListPage extends StatelessWidget {
  const ComboListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: CombosManager.instance,
      child: Consumer<CombosManager>(
        builder: (context, manager, _) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF004D40)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Paket & Combo',
                style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  onPressed: () => _openCreate(context),
                  icon: const Icon(Icons.add, color: Color(0xFF004D40)),
                  tooltip: 'Buat Paket Baru',
                ),
              ],
            ),
            body: manager.isEmpty
                ? _buildEmpty(context)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final combo in manager.combos)
                        _ComboCard(combo: combo),
                    ],
                  ),
            floatingActionButton: manager.isEmpty
                ? null
                : FloatingActionButton.extended(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    onPressed: () => _openCreate(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Paket Baru'),
                  ),
          );
        },
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ComboModal()),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF004D40).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_offer_outlined,
                  size: 56, color: Color(0xFF004D40)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Paket',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
            ),
            const SizedBox(height: 8),
            Text(
              'Buat paket/combo untuk mempermudah pemesanan produk bundel dengan harga spesial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ComboModal())),
              icon: const Icon(Icons.add),
              label: const Text('Buat Paket Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComboCard extends StatelessWidget {
  final ComboProduct combo;

  const _ComboCard({required this.combo});

  @override
  Widget build(BuildContext context) {
    final hasSavings = combo.savings > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF004D40).withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer, size: 20, color: Color(0xFF004D40)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(combo.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF004D40))),
                      if (combo.description.isNotEmpty)
                        Text(combo.description,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) => _handleAction(context, val),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Paket')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus', style: TextStyle(color: Colors.red))),
                  ],
                  child: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in combo.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF004D40).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('x${item.qty}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.productName)),
                        Text(item.price.toCurrency(),
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  ),

                const Divider(height: 20),

                // Price row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasSavings)
                          Text(
                            combo.originalPrice.toCurrency(),
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough),
                          ),
                        Text(
                          combo.price.toCurrency(),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004D40)),
                        ),
                      ],
                    ),
                    if (hasSavings)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          'Hemat ${combo.savings.toCurrency()}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _addToCart(context),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Tambah ke Keranjang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context) {
    int added = 0;
    for (final item in combo.items) {
      final product = _findProduct(item.productId);
      if (product != null) {
        for (int i = 0; i < item.qty; i++) {
          Cart.instance.add(product);
          added++;
        }
      }
    }

    if (added > 0) {
      showSnackBar('${combo.name} ditambahkan ke keranjang!', context: context);
    } else {
      showSnackBar('Produk tidak ditemukan di menu saat ini.', context: context);
    }
  }

  dynamic _findProduct(String id) {
    for (final catalog in Menu.instance.itemList) {
      for (final p in catalog.itemList) {
        if (p.id == id) return p;
      }
    }
    return null;
  }

  void _handleAction(BuildContext context, String action) async {
    if (action == 'edit') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ComboModal(existing: combo)),
      );
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hapus Paket?'),
          content: Text('Paket "${combo.name}" akan dihapus permanen.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await CombosManager.instance.delete(combo.id);
      }
    }
  }
}
