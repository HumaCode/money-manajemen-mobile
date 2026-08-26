import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:money_manajemen/core/utils/formatters.dart';
import 'package:money_manajemen/data/models/transaction_model.dart';

class ExportService {
  /// Generate and open PDF Financial Report
  static Future<File> exportToPdf({
    required List<TransactionModel> transactions,
    required String periodName,
  }) async {
    final pdf = pw.Document();

    int totalIncome = 0;
    int totalExpense = 0;
    for (var tx in transactions) {
      if (tx.isIncome) {
        totalIncome += tx.amount.abs();
      } else if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount.abs();
      }
    }
    final netBalance = totalIncome - totalExpense;
    final nowStr = formatDate(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 16),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Dicetak dari Money Management Mobile • $nowStr',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Top Header & Brand Accent
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 4,
                          height: 22,
                          decoration: const pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFF10B981),
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'LAPORAN KEUANGAN',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF0F172A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Periode Laporan: $periodName',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Money Management',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF10B981),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Tanggal Cetak: $nowStr',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: const PdfColor.fromInt(0xFFE2E8F0)),
            pw.SizedBox(height: 14),

            // Summary Section - 3 Sleek Cards
            pw.Row(
              children: [
                // Total Income Card
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFF0FDF4),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFBBF7D0)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOTAL PEMASUKAN',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF166534),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          formatRupiah(totalIncome),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                // Total Expense Card
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFFEF2F2),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: const PdfColor.fromInt(0xFFFECACA)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TOTAL PENGELUARAN',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF991B1B),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          formatRupiah(totalExpense),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                // Net Balance Card
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: pw.BoxDecoration(
                      color: netBalance >= 0
                          ? const PdfColor.fromInt(0xFFEFF6FF)
                          : const PdfColor.fromInt(0xFFFEF2F2),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(
                        color: netBalance >= 0
                            ? const PdfColor.fromInt(0xFFBFDBFE)
                            : const PdfColor.fromInt(0xFFFECACA),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SELISIH NET',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: netBalance >= 0
                                ? const PdfColor.fromInt(0xFF1E40AF)
                                : const PdfColor.fromInt(0xFF991B1B),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          formatRupiah(netBalance),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: netBalance >= 0
                                ? const PdfColor.fromInt(0xFF1D4ED8)
                                : const PdfColor.fromInt(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Transactions Table Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Rincian Transaksi',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF0F172A),
                  ),
                ),
                pw.Text(
                  '${transactions.length} Transaksi',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            if (transactions.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 24),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Tidak ada transaksi pada periode ini.',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: ['No', 'Tanggal', 'Judul Transaksi', 'Kategori', 'Tipe', 'Jumlah'],
                data: List.generate(transactions.length, (index) {
                  final tx = transactions[index];
                  final typeStr = tx.isIncome
                      ? 'Pemasukan'
                      : (tx.type == TransactionType.expense ? 'Pengeluaran' : 'Transfer');
                  final amountStr = '${tx.isIncome ? '+' : '-'}${formatRupiah(tx.amount.abs())}';

                  return [
                    '${index + 1}',
                    formatDate(tx.date),
                    tx.title,
                    tx.category,
                    typeStr,
                    amountStr,
                  ];
                }),
                border: pw.TableBorder.all(
                  color: const PdfColor.fromInt(0xFFE2E8F0),
                  width: 0.5,
                ),
                headerStyle: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF0F172A),
                ),
                headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                cellStyle: const pw.TextStyle(fontSize: 9),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8FAFC),
                ),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerLeft,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FixedColumnWidth(75),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FixedColumnWidth(72),
                  5: const pw.FlexColumnWidth(2.5),
                },
              ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final fileName = 'Laporan_Keuangan_${DateTime.now().millisecondsSinceEpoch}.pdf';
    return await _saveAndOpenFile(bytes: pdfBytes, fileName: fileName);
  }

  static Future<File> _saveAndOpenFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    File file;
    try {
      Directory? targetDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        }
      }
      targetDir ??= await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(bytes);
    } catch (_) {
      final fallbackDir = await getApplicationDocumentsDirectory();
      file = File('${fallbackDir.path}/$fileName');
      await file.writeAsBytes(bytes);
    }

    // Attempt to open file immediately for preview, fallback to system Share if channel is missing
    try {
      final openResult = await OpenFilex.open(file.path);
      if (openResult.type != ResultType.done) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Laporan Keuangan - Money Management',
        );
      }
    } catch (_) {
      try {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Laporan Keuangan - Money Management',
        );
      } catch (_) {}
    }

    return file;
  }
}
