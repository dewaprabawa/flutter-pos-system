import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:possystem/components/style/snackbar.dart';
import 'package:possystem/models/repository/seller.dart';
import 'package:possystem/models/repository/session_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class TutupTokoPage extends StatefulWidget {
  const TutupTokoPage({super.key});

  @override
  State<TutupTokoPage> createState() => _TutupTokoPageState();
}

class _TutupTokoPageState extends State<TutupTokoPage> {
  final _actualCashController = TextEditingController();
  
  bool _isLoading = true;
  double _totalSales = 0;
  int _transactionCount = 0;
  
  double _totalTunai = 0;
  double _totalQRIS = 0;
  double _totalKartu = 0;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    final session = SessionManager.instance.currentSession;
    if (session == null) {
      setState(() => _isLoading = false);
      return;
    }

    final end = DateTime.now();
    final orders = await Seller.instance.getDetailedOrders(session.startTime, end);
    
    final sessionOrders = orders.where((o) => o.sessionId == session.id).toList();

    double tunai = 0;
    double qris = 0;
    double kartu = 0;
    double total = 0;

    for (var o in sessionOrders) {
      total += o.price;
      if (o.paymentMethod == 'Tunai') tunai += o.price;
      if (o.paymentMethod == 'QRIS') qris += o.price;
      if (o.paymentMethod == 'Kartu') kartu += o.price;
    }

    setState(() {
      _transactionCount = sessionOrders.length;
      _totalSales = total;
      _totalTunai = tunai;
      _totalQRIS = qris;
      _totalKartu = kartu;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _actualCashController.dispose();
    super.dispose();
  }

  void _kirimLaporan(double expectedCash, double actualCash) async {
    final session = SessionManager.instance.currentSession;
    if (session == null) return;

    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final selisih = actualCash - expectedCash;
    final jamBuka = DateFormat('HH:mm').format(session.startTime);
    final jamTutup = DateFormat('HH:mm').format(DateTime.now());

    final message = '''
*Laporan Tutup Toko*
Kasir: ${session.cashierName}
Jam Buka: $jamBuka
Jam Tutup: $jamTutup

Total Penjualan: ${formatCurrency.format(_totalSales)}
Jumlah Transaksi: $_transactionCount

*Metode Pembayaran:*
Tunai: ${formatCurrency.format(_totalTunai)}
QRIS: ${formatCurrency.format(_totalQRIS)}
Kartu: ${formatCurrency.format(_totalKartu)}

*Rekonsiliasi Kas:*
Modal Awal: ${formatCurrency.format(session.startCash)}
Kas Diharapkan: ${formatCurrency.format(expectedCash)}
Kas Aktual: ${formatCurrency.format(actualCash)}
Selisih: ${formatCurrency.format(selisih)}
''';

    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        showSnackBar('Tidak dapat membuka WhatsApp', context: context);
      }
    }
  }

  void _tutupToko(double actualCash) async {
    await SessionManager.instance.closeSession(actualCash);
    if (mounted) {
      showSnackBar('Toko berhasil ditutup', context: context);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = SessionManager.instance.currentSession;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tutup Toko')),
        body: const Center(child: Text('Tidak ada sesi kasir aktif.')),
      );
    }

    final expectedCash = session.startCash + _totalTunai;
    final actualCash = double.tryParse(_actualCashController.text) ?? expectedCash;
    final selisih = actualCash - expectedCash;
    
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF004D40)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Tutup Toko',
          style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront, color: Color(0xFF004D40)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Summary
            // Session Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Penjualan',
                    formatCurrency.format(_totalSales),
                    const Color(0xFF004D40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Transaksi',
                    '$_transactionCount',
                    const Color(0xFF004D40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Metode Pembayaran',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildPaymentRow('Tunai', _totalTunai, formatCurrency),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildPaymentRow('QRIS', _totalQRIS, formatCurrency),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildPaymentRow('Kartu', _totalKartu, formatCurrency),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cash Reconciliation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rekonsiliasi Kas',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildInfoRow('Modal Awal', formatCurrency.format(session.startCash)),
                  const SizedBox(height: 12),
                  _buildInfoRow('Total Tunai Masuk', '+ ${formatCurrency.format(_totalTunai)}',
                      valueColor: const Color(0xFF327E73)),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildInfoRow('Kas Diharapkan', formatCurrency.format(expectedCash), isBold: true),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _actualCashController,
                      decoration: const InputDecoration(
                        hintText: 'Kas Aktual (Uang Laci)',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.money_outlined, color: Colors.grey),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  if (_actualCashController.text.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Selisih', formatCurrency.format(selisih),
                        isBold: true,
                        valueColor: selisih < 0 ? colorScheme.error : const Color(0xFF327E73)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            OutlinedButton.icon(
              onPressed: () => _kirimLaporan(expectedCash, actualCash),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Kirim Laporan'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: const Color(0xFF004D40),
                side: const BorderSide(color: Color(0xFF004D40)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _actualCashController.text.isEmpty ? null : () => _tutupToko(actualCash),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Tutup Toko'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFFD6D6D6), // Greyish as per image
                foregroundColor: Colors.grey.shade700,
                disabledBackgroundColor: Colors.grey.shade200,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, NumberFormat formatter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(formatter.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade600, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black87,
                fontSize: isBold ? 16 : 14)),
      ],
    );
  }
}
