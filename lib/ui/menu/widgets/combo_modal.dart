import 'package:flutter/material.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/menu/combo_product.dart';
import 'package:possystem/models/menu/product.dart';
import 'package:possystem/models/repository/combos_manager.dart';
import 'package:possystem/models/repository/menu.dart';

/// Full-screen modal for creating or editing a Combo/Package item.
class ComboModal extends StatefulWidget {
  final ComboProduct? existing;

  const ComboModal({super.key, this.existing});

  @override
  State<ComboModal> createState() => _ComboModalState();
}

class _ComboModalState extends State<ComboModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;

  /// Draft items in the combo being built.
  final List<_DraftItem> _draftItems = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _priceCtrl = TextEditingController(
        text: e != null && e.specialPrice > 0 ? e.specialPrice.toString() : '');

    if (e != null) {
      // Pre-populate draft items from the existing combo, resolved against Menu
      for (final item in e.items) {
        final product = _findProduct(item.productId);
        if (product != null) {
          _draftItems.add(_DraftItem(product: product, qty: item.qty));
        }
      }
    }
  }

  Product? _findProduct(String id) {
    for (final catalog in Menu.instance.itemList) {
      for (final p in catalog.itemList) {
        if (p.id == id) return p;
      }
    }
    return null;
  }

  num get _calculatedTotal => _draftItems.fold<num>(
      0, (sum, item) => sum + (item.product.price * item.qty));

  num get _specialPrice {
    final raw = _priceCtrl.text.trim();
    return raw.isEmpty ? 0 : (num.tryParse(raw) ?? 0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_draftItems.isEmpty) {
      showSnackBar('Tambahkan minimal 1 produk ke dalam paket.', context: context);
      return;
    }

    setState(() => _saving = true);

    final combo = ComboProduct(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      specialPrice: _specialPrice,
      items: _draftItems
          .map((d) => ComboItem(
                productId: d.product.id,
                productName: d.product.name,
                price: d.product.price,
                qty: d.qty,
              ))
          .toList(),
    );

    if (widget.existing != null) {
      await CombosManager.instance.update(combo);
    } else {
      await CombosManager.instance.add(combo);
    }

    if (mounted) Navigator.pop(context, combo);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF004D40)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Edit Paket' : 'Buat Paket Baru',
          style: const TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(
                    'Simpan',
                    style: TextStyle(
                        color: Color(0xFF004D40), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            _sectionLabel('Nama Paket'),
            const SizedBox(height: 8),
            _inputField(
              controller: _nameCtrl,
              hint: 'contoh: Paket Geprek Hemat',
              validator: (v) => v == null || v.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),

            // Description
            _sectionLabel('Deskripsi (Opsional)'),
            const SizedBox(height: 8),
            _inputField(
              controller: _descCtrl,
              hint: 'contoh: Nasi geprek + es teh manis',
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Products in combo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('Produk dalam Paket'),
                TextButton.icon(
                  onPressed: _pickProduct,
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF004D40)),
                  label: const Text('Tambah', style: TextStyle(color: Color(0xFF004D40))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_draftItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    const Text('Belum ada produk. Tap "Tambah" untuk memilih.'),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: _draftItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(item.product.price.toCurrency(),
                                        style: const TextStyle(
                                            fontSize: 12, color: Color(0xFF327E73))),
                                  ],
                                ),
                              ),
                              // Qty control
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => setState(() {
                                      if (item.qty > 1) {
                                        _draftItems[i] = item.copyWith(qty: item.qty - 1);
                                      } else {
                                        _draftItems.removeAt(i);
                                      }
                                    }),
                                    icon: Icon(
                                        item.qty > 1 ? Icons.remove : Icons.delete_outline,
                                        size: 18,
                                        color: item.qty > 1
                                            ? Colors.grey
                                            : Colors.red.shade400),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text('${item.qty}',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(
                                        () => _draftItems[i] = item.copyWith(qty: item.qty + 1)),
                                    icon: const Icon(Icons.add,
                                        size: 18, color: Color(0xFF327E73)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (i < _draftItems.length - 1) const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

            // Price section
            _sectionLabel('Harga Paket'),
            const SizedBox(height: 4),
            Text(
              'Harga asli (jumlah satuan): ${_calculatedTotal.toCurrency()}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            _inputField(
              controller: _priceCtrl,
              hint: 'Kosongkan jika sama dengan harga asli',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Price preview card
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _specialPrice > 0 && _specialPrice < _calculatedTotal
                    ? const Color(0xFFE0F2F1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Harga Jual Paket',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        _specialPrice > 0
                            ? _specialPrice.toCurrency()
                            : _calculatedTotal.toCurrency(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF004D40)),
                      ),
                    ],
                  ),
                  if (_specialPrice > 0 && _specialPrice < _calculatedTotal) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Hemat ${(_calculatedTotal - _specialPrice).toCurrency()} (${((_calculatedTotal - _specialPrice) / _calculatedTotal * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF327E73),
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Future<void> _pickProduct() async {
    final all = Menu.instance.notEmptyItems
        .expand((c) => c.itemList)
        .toList();

    if (all.isEmpty) {
      showSnackBar('Belum ada produk di menu.', context: context);
      return;
    }

    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductPickerSheet(allProducts: all),
    );

    if (product != null) {
      setState(() {
        final existing = _draftItems.indexWhere((d) => d.product.id == product.id);
        if (existing != -1) {
          _draftItems[existing] =
              _draftItems[existing].copyWith(qty: _draftItems[existing].qty + 1);
        } else {
          _draftItems.add(_DraftItem(product: product, qty: 1));
        }
      });
    }
  }
}

/// Helper class for draft items in the combo builder.
class _DraftItem {
  final Product product;
  final int qty;
  const _DraftItem({required this.product, required this.qty});
  _DraftItem copyWith({int? qty}) => _DraftItem(product: product, qty: qty ?? this.qty);
}

/// Bottom sheet to pick a product from the menu.
class _ProductPickerSheet extends StatefulWidget {
  final List<Product> allProducts;
  const _ProductPickerSheet({required this.allProducts});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';

  List<Product> get _filtered => _query.isEmpty
      ? widget.allProducts
      : widget.allProducts
          .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Pilih Produk',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = _filtered[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.catalog.name,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  trailing: Text(p.price.toCurrency(),
                      style: const TextStyle(
                          color: Color(0xFF327E73), fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
