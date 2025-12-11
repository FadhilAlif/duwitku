import 'dart:io';
import 'package:csv/csv.dart';
import 'package:duwitku/models/category.dart';
import 'package:duwitku/models/transaction.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportHelper {
  static Future<void> exportToCsv(
    List<Transaction> transactions,
    Map<int, Category> categoryMap,
  ) async {
    final List<List<dynamic>> rows = [];

    // Header
    rows.add(['Tanggal', 'Kategori', 'Deskripsi', 'Tipe', 'Jumlah']);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    for (var trx in transactions) {
      final category = categoryMap[trx.categoryId];
      rows.add([
        dateFormat.format(trx.transactionDate),
        category?.name ?? 'Tanpa Kategori',
        trx.description ?? '',
        trx.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran',
        trx.amount,
      ]);
    }

    final String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/transaksi_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csvData);

    // ignore: deprecated_member_use
    // await Share.shareXFiles([XFile(file.path)], text: 'Export Transaksi CSV');
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Export Transaksi CSV',
        subject: 'Laporan Transaksi CSV Duwitku',
      ),
    );
  }

  static Future<void> exportToPdf(
    List<Transaction> transactions,
    Map<int, Category> categoryMap,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laporan Transaksi',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Tanggal', 'Kategori', 'Deskripsi', 'Tipe', 'Jumlah'],
              data: transactions.map((trx) {
                final category = categoryMap[trx.categoryId];
                return [
                  dateFormat.format(trx.transactionDate),
                  category?.name ?? '-',
                  trx.description ?? '-',
                  trx.type == TransactionType.income ? 'Masuk' : 'Keluar',
                  currencyFormat.format(trx.amount),
                ];
              }).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/transaksi_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    // ignore: deprecated_member_use
    // await Share.shareXFiles([XFile(file.path)], text: 'Export Transaksi PDF');
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Export Transaksi PDF',
        subject: 'Laporan Transaksi PDF Duwitku',
      ),
    );
  }
}
