import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as excel_lib hide CellValue;
import 'package:possystem/helpers/util.dart';
import 'package:possystem/models/objects/order_object.dart';
import 'package:possystem/models/repository/cashier.dart';
import 'package:possystem/models/repository/seller.dart';
import 'package:possystem/translator.dart';
import 'package:possystem/ui/transit/formatter/order_formatter.dart';
import 'package:possystem/ui/transit/transit_station.dart';

class SurplusReportDialog extends StatefulWidget {
  final Cashier cashier;

  const SurplusReportDialog({super.key, required this.cashier});

  @override
  State<SurplusReportDialog> createState() => _SurplusReportDialogState();
}

class _SurplusReportDialogState extends State<SurplusReportDialog> {
  bool _includeSurplus = true;
  bool _includeOrders = true;
  TransitMethod _format = TransitMethod.excel;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kirim Laporan Toko'),
      content: _isLoading
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Menyiapkan laporan...'),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                  CheckboxListTile(
                    title: const Text('Ringkasan Kasir'),
                    value: _includeSurplus,
                    onChanged: (v) => setState(() => _includeSurplus = v!),
                    dense: true,
                  ),
                  CheckboxListTile(
                    title: const Text('Daftar Pesanan Hari Ini'),
                    value: _includeOrders,
                    onChanged: (v) => setState(() => _includeOrders = v!),
                    dense: true,
                  ),
                  const Divider(),
                  const Text('Pilih Format:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildFormatOption(
                    TransitMethod.excel,
                    'Excel (.xlsx)',
                    'Format tabel lengkap, bagus untuk Excel/Google Sheets.',
                    FontAwesomeIcons.fileExcel,
                    const Color(0xFF1D6F42),
                  ),
                  _buildFormatOption(
                    TransitMethod.csv,
                    'CSV (.csv)',
                    'Format teks sederhana, ringan & universal.',
                    FontAwesomeIcons.fileCsv,
                    const Color(0xFF00897B),
                  ),
                  _buildFormatOption(
                    TransitMethod.plainText,
                    'Teks Biasa',
                    'Langsung terbaca di pesan WhatsApp.',
                    FontAwesomeIcons.fileLines,
                    const Color(0xFF546E7A),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _sendReport,
          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
          label: const Text('Kirim Laporan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatOption(TransitMethod method, String title, String subtitle, IconData icon, Color iconColor) {
    return RadioListTile<TransitMethod>(
      value: method,
      groupValue: _format,
      onChanged: (v) => setState(() => _format = v!),
      title: Row(
        children: [
          FaIcon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Future<void> _sendReport() async {
    setState(() => _isLoading = true);

    try {
      final List<XFile> filesToShare = [];
      String message = '';

      if (_includeSurplus) {
        final sb = StringBuffer();
        sb.writeln('*LAPORAN TUTUP TOKO*');
        sb.writeln('Tanggal: ${DateTime.now().toString().split(' ')[0]}');
        sb.writeln('--------------------------');
        sb.writeln('Total Kasir: ${widget.cashier.currentTotal.toCurrency()}');
        sb.writeln('Selisih: ${(widget.cashier.currentTotal - widget.cashier.defaultTotal).toCurrency()}');
        sb.writeln('--------------------------');
        sb.writeln('*Rincian Unit:*');
        for (final e in widget.cashier.getDifference()) {
          if (e.currentCount > 0) {
            sb.writeln('${e.unit.toCurrency()}: ${e.currentCount} (Selisih: ${e.diffCount})');
          }
        }
        message = sb.toString();
      }

      if (_includeOrders) {
        final today = DateTime.now();
        final start = DateTime(today.year, today.month, today.day);
        final end = DateTime(today.year, today.month, today.day, 23, 59, 59);
        
        final orders = await Seller.instance.getDetailedOrders(start, end);
        
        if (orders.isNotEmpty) {
          switch (_format) {
            case TransitMethod.excel:
              final file = await _generateExcel(orders);
              filesToShare.add(XFile(file.path));
              break;
            case TransitMethod.csv:
              final file = await _generateCSV(orders);
              filesToShare.add(XFile(file.path));
              break;
            case TransitMethod.plainText:
              if (message.isNotEmpty) message += '\n\n';
              message += '*DAFTAR PESANAN:*';
              for (final o in orders) {
                message += '\n#${o.periodSeq} - ${o.price.toCurrency()} (${o.productsCount} item)';
              }
              break;
            default:
              break;
          }
        }
      }

      if (context.mounted) {
        if (filesToShare.isNotEmpty) {
          await Share.shareXFiles(filesToShare, text: message);
        } else if (message.isNotEmpty) {
          await Share.share(message);
        }
        if (context.mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim laporan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<File> _generateExcel(List<OrderObject> orders) async {
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Orders'];
    excel.delete('Sheet1');

    final headers = OrderFormatter.basicHeaders;
    for (var i = 0; i < headers.length; i++) {
      sheet.updateCell(
        excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        excel_lib.TextCellValue(headers[i]),
      );
    }

    for (var i = 0; i < orders.length; i++) {
      final row = OrderFormatter.formatBasic(orders[i])[0];
      for (var j = 0; j < row.length; j++) {
        final cellValue = row[j].string != null
            ? excel_lib.TextCellValue(row[j].string!)
            : row[j].number != null
                ? excel_lib.DoubleCellValue(row[j].number!.toDouble())
                : null;
        if (cellValue != null) {
          sheet.updateCell(
            excel_lib.CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1),
            cellValue,
          );
        }
      }
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Laporan_Pesanan_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  Future<File> _generateCSV(List<OrderObject> orders) async {
    final sb = StringBuffer();
    sb.writeln(OrderFormatter.basicHeaders.join(','));
    for (final o in orders) {
      final row = OrderFormatter.formatBasic(o)[0];
      sb.writeln(row.map((e) => '"${e.toString()}"').join(','));
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Laporan_Pesanan_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(sb.toString());
    return file;
  }
}
