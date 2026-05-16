import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka WhatsApp')));
      }
    }
  }

  void _tutupToko(double actualCash) async {
    await SessionManager.instance.closeSession(actualCash);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toko berhasil ditutup')));
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
      appBar: AppBar(
        title: const Text('Tutup Toko'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Summary
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Ringkasan Sesi', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatBox('Penjualan', formatCurrency.format(_totalSales), colorScheme),
                        _buildStatBox('Transaksi', '$_transactionCount', colorScheme),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Breakdown
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Metode Pembayaran', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildPaymentRow('Tunai', _totalTunai, formatCurrency),
                    const Divider(),
                    _buildPaymentRow('QRIS', _totalQRIS, formatCurrency),
                    const Divider(),
                    _buildPaymentRow('Kartu', _totalKartu, formatCurrency),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cash Reconciliation
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rekonsiliasi Kas', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Modal Awal'),
                        Text(formatCurrency.format(session.startCash)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Tunai Masuk'),
                        Text('+ ${formatCurrency.format(_totalTunai)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kas Diharapkan', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(formatCurrency.format(expectedCash), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _actualCashController,
                      decoration: const InputDecoration(
                        labelText: 'Kas Aktual (Uang Laci)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => setState(() {}),
                    ),
                    if (_actualCashController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Selisih', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            formatCurrency.format(selisih),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selisih < 0 ? colorScheme.error : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _kirimLaporan(expectedCash, actualCash),
                    icon: const Icon(Icons.send),
                    label: const Text('Kirim Laporan'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _actualCashController.text.isEmpty
                        ? null
                        : () => _tutupToko(actualCash),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Tutup Toko'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPaymentRow(String label, double amount, NumberFormat formatter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(formatter.format(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
