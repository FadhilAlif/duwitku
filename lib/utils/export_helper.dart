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
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final now = DateTime.now();

    // ── Calculate summary values ──
    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpense;

    // ── Category breakdown (expenses only, top 5) ──
    final Map<String, double> expenseByCategory = {};
    for (var trx in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      final catName = categoryMap[trx.categoryId]?.name ?? 'Lainnya';
      expenseByCategory[catName] =
          (expenseByCategory[catName] ?? 0) + trx.amount;
    }
    final sortedCategories = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(5).toList();

    // ── Colors ──
    const primaryColor = PdfColor.fromInt(0xFF1565C0);
    const primaryLight = PdfColor.fromInt(0xFFE3F2FD);
    const incomeColor = PdfColor.fromInt(0xFF2E7D32);
    const incomeBgColor = PdfColor.fromInt(0xFFE8F5E9);
    const expenseColor = PdfColor.fromInt(0xFFC62828);
    const expenseBgColor = PdfColor.fromInt(0xFFFFEBEE);
    const balanceBgColor = PdfColor.fromInt(0xFFF3E5F5);
    const balanceColor = PdfColor.fromInt(0xFF6A1B9A);
    const darkText = PdfColor.fromInt(0xFF212121);
    const subtleText = PdfColor.fromInt(0xFF757575);
    const tableHeaderBg = PdfColor.fromInt(0xFF1E88E5);
    const tableHeaderText = PdfColor.fromInt(0xFFFFFFFF);
    const tableStripeBg = PdfColor.fromInt(0xFFF5F5F5);
    const dividerColor = PdfColor.fromInt(0xFFE0E0E0);

    // ── Sort transactions by date descending ──
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    // ── Date range text ──
    String dateRangeText = '';
    if (sortedTransactions.isNotEmpty) {
      final earliest = sortedTransactions.last.transactionDate;
      final latest = sortedTransactions.first.transactionDate;
      dateRangeText =
          '${dateFormat.format(earliest)} — ${dateFormat.format(latest)}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: dividerColor, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Duwitku Laporan Transaksi',
                  style: pw.TextStyle(fontSize: 8, color: subtleText),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: subtleText),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // ═══════════════ HEADER ═══════════════
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Laporan Transaksi',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: tableHeaderText,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Duwitku Pengelola Keuangan Pribadi',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor.fromInt(0xFFBBDEFB),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        dateRangeText,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: tableHeaderText,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(now)}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColor.fromInt(0xFFBBDEFB),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '${sortedTransactions.length} transaksi',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColor.fromInt(0xFFBBDEFB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // ═══════════════ SUMMARY CARDS ═══════════════
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildSummaryBox(
                    label: 'Total Pemasukan',
                    value: currencyFormat.format(totalIncome),
                    bgColor: incomeBgColor,
                    textColor: incomeColor,
                    icon: '+',
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildSummaryBox(
                    label: 'Total Pengeluaran',
                    value: currencyFormat.format(totalExpense),
                    bgColor: expenseBgColor,
                    textColor: expenseColor,
                    icon: '-',
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildSummaryBox(
                    label: 'Saldo Bersih',
                    value: currencyFormat.format(netBalance),
                    bgColor: balanceBgColor,
                    textColor: balanceColor,
                    icon: '=',
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // ═══════════════ CATEGORY BREAKDOWN ═══════════════
            if (topCategories.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primaryLight,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: dividerColor, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Pengeluaran Teratas per Kategori',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    ...topCategories.map((entry) {
                      final percentage = totalExpense > 0
                          ? (entry.value / totalExpense * 100)
                          : 0.0;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Row(
                          children: [
                            pw.SizedBox(
                              width: 120,
                              child: pw.Text(
                                entry.key,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: darkText,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              child: pw.LayoutBuilder(
                                builder: (context, constraints) {
                                  final barWidth =
                                      (constraints?.maxWidth ?? 100) *
                                      (percentage / 100).clamp(0.0, 1.0);
                                  return pw.Stack(
                                    children: [
                                      pw.Container(
                                        height: 14,
                                        decoration: pw.BoxDecoration(
                                          color: dividerColor,
                                          borderRadius:
                                              pw.BorderRadius.circular(3),
                                        ),
                                      ),
                                      pw.Container(
                                        width: barWidth,
                                        height: 14,
                                        decoration: pw.BoxDecoration(
                                          color: expenseColor,
                                          borderRadius:
                                              pw.BorderRadius.circular(3),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.SizedBox(
                              width: 80,
                              child: pw.Text(
                                currencyFormat.format(entry.value),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: darkText,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.SizedBox(width: 6),
                            pw.SizedBox(
                              width: 35,
                              child: pw.Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: subtleText,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            // ═══════════════ SECTION TITLE ═══════════════
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
              child: pw.Text(
                'Detail Transaksi',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            // ═══════════════ TRANSACTION TABLE ═══════════════
            pw.TableHelper.fromTextArray(
              context: context,
              headers: [
                'No',
                'Tanggal',
                'Kategori',
                'Deskripsi',
                'Tipe',
                'Jumlah',
              ],
              headerCount: 1,
              data: List.generate(sortedTransactions.length, (i) {
                final trx = sortedTransactions[i];
                final category = categoryMap[trx.categoryId];
                return [
                  '${i + 1}',
                  dateFormat.format(trx.transactionDate),
                  category?.name ?? '-',
                  trx.description ?? '-',
                  trx.type == TransactionType.income ? 'Masuk' : 'Keluar',
                  '${trx.type == TransactionType.income ? '+' : '-'} ${currencyFormat.format(trx.amount)}',
                ];
              }),
              border: pw.TableBorder.all(color: dividerColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: tableHeaderText,
              ),
              headerDecoration: const pw.BoxDecoration(color: tableHeaderBg),
              headerAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellDecoration: (index, data, rowNum) {
                // rowNum 0 is header, so odd data rows get stripe
                if (rowNum % 2 == 0 && rowNum > 0) {
                  return const pw.BoxDecoration(color: tableStripeBg);
                }
                return const pw.BoxDecoration();
              },
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(28), // No
                1: const pw.FixedColumnWidth(72), // Tanggal
                2: const pw.FlexColumnWidth(1.2), // Kategori
                3: const pw.FlexColumnWidth(1.8), // Deskripsi
                4: const pw.FixedColumnWidth(42), // Tipe
                5: const pw.FixedColumnWidth(88), // Jumlah
              },
            ),

            pw.SizedBox(height: 12),

            // ═══════════════ TABLE FOOTER TOTALS ═══════════════
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: primaryLight,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: primaryColor, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  _buildFooterItem(
                    'Pemasukan',
                    currencyFormat.format(totalIncome),
                    incomeColor,
                  ),
                  pw.SizedBox(width: 20),
                  _buildFooterItem(
                    'Pengeluaran',
                    currencyFormat.format(totalExpense),
                    expenseColor,
                  ),
                  pw.SizedBox(width: 20),
                  _buildFooterItem(
                    'Saldo Bersih',
                    currencyFormat.format(netBalance),
                    primaryColor,
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final filenameDateFormat = DateFormat('dd-MM-yyyy');
    final filename =
        'Duwitku_Transaksi_${filenameDateFormat.format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Export Transaksi PDF',
        subject: 'Laporan Transaksi PDF Duwitku',
      ),
    );
  }

  // ── Helper: Summary box widget ──
  static pw.Widget _buildSummaryBox({
    required String label,
    required String value,
    required PdfColor bgColor,
    required PdfColor textColor,
    required String icon,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 18,
                height: 18,
                decoration: pw.BoxDecoration(
                  color: textColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Center(
                  child: pw.Text(
                    icon,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                label,
                style: pw.TextStyle(fontSize: 8, color: textColor),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Footer total item ──
  static pw.Widget _buildFooterItem(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 8, color: color)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
