import 'package:flutter/material.dart';
import 'package:possystem/models/repository/session_manager.dart';
import 'package:possystem/models/repository/stock.dart';
import 'package:possystem/models/stock/ingredient.dart';
import 'package:possystem/translator.dart';

class BukaTokoPage extends StatefulWidget {
  const BukaTokoPage({super.key});

  @override
  State<BukaTokoPage> createState() => _BukaTokoPageState();
}

class _BukaTokoPageState extends State<BukaTokoPage> {
  final _formKey = GlobalKey<FormState>();
  final _cashController = TextEditingController();
  final _cashierController = TextEditingController();

  List<Ingredient> _lowStockItems = [];

  @override
  void initState() {
    super.initState();
    _checkStock();
  }

  void _checkStock() {
    final items = Stock.instance.itemList;
    // Assuming warning level is some threshold, for example 10.
    // Replace with your actual warning logic if you have one.
    _lowStockItems = items.where((e) => e.currentAmount < 10).toList();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _cashierController.dispose();
    super.dispose();
  }

  void _startSession() async {
    if (_formKey.currentState?.validate() == true) {
      final cash = double.tryParse(_cashController.text) ?? 0.0;
      final cashier = _cashierController.text;
      await SessionManager.instance.startSession(cash, cashier);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buka Toko'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mulai Sesi Kasir',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _cashierController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kasir',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value?.isEmpty == true ? 'Nama kasir tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _cashController,
                decoration: const InputDecoration(
                  labelText: 'Modal Kas Awal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Kas awal tidak boleh kosong';
                  if (double.tryParse(value) == null) return 'Masukkan angka yang valid';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              if (_lowStockItems.isNotEmpty) ...[
                Text(
                  '⚠️ Peringatan Stok Tipis',
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _lowStockItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.name, style: TextStyle(color: colorScheme.onErrorContainer)),
                              Text('${item.currentAmount}', style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              ElevatedButton(
                onPressed: _startSession,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Mulai Berjualan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
