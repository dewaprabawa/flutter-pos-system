import 'package:flutter/material.dart';
import 'package:possystem/components/style/pop_button.dart';
import 'package:possystem/components/style/status_banner.dart';
import 'package:possystem/models/repository/session_manager.dart';
import 'package:possystem/models/repository/stock.dart';
import 'package:possystem/models/stock/ingredient.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.storefront, color: Color(0xFF004D40)),
            const SizedBox(width: 8),
            const Text(
              'MokkonPOS',
              style: TextStyle(
                color: Color(0xFF004D40),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Buka Toko',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Mulai Sesi Kasir',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Siapkan register Anda untuk mulai menerima pembayaran hari ini.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Hero Image
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/buka_toko_hero.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Form Fields
              _buildSectionHeader('INFORMASI KASIR'),
              _buildTextField(
                controller: _cashierController,
                hint: 'Nama Kasir',
                icon: Icons.person_outline,
                validator: (val) => val?.isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('KAS AWAL'),
              _buildTextField(
                controller: _cashController,
                hint: 'Modal Kas Awal',
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                validator: (val) => val?.isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _startSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Mulai Berjualan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              // const SizedBox(height: 16),
              // const StatusBanner(
              //   message: 'Toko berhasil ditutup pada sesi sebelumnya',
              // ),

              const SizedBox(height: 48),
              Center(
                child: Text(
                  'POWERED BY MOKKONPOS TECHNOLOGY',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(height: 0),
        ),
      ),
    );
  }
}
