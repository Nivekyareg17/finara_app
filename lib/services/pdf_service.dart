import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> exportTransactionsPdf({
    required List transactions,
    required String name,
    required String email,
    required Function getCategoryName,
    required Function formatCurrency,
    required double balance,
    Function? getTransactionCurrency,
    String? baseCurrency,
    double? totalIngresos,
    double? totalGastos,
  }) async {

    final pdf = pw.Document();
    final generatedAt =
        DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());
    final ingresos = totalIngresos ??
        transactions
        .where((t) => t.type == "ingreso")
        .fold<double>(0, (sum, t) => sum + (t.amount as num).toDouble());
    final gastos = totalGastos ??
        transactions
        .where((t) => t.type == "gasto")
        .fold<double>(0, (sum, t) => sum + (t.amount as num).toDouble());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex("#064E3B"),
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Finara",
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Reporte de movimientos",
                      style: const pw.TextStyle(
                        color: PdfColor(0.78, 0.91, 0.84),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex("#10B981"),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(
                    baseCurrency == null ? "Balance" : "Balance $baseCurrency",
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              _summaryCard("Usuario", name, PdfColor.fromHex("#EFF6FF")),
              pw.SizedBox(width: 10),
              _summaryCard("Email", email, PdfColor.fromHex("#F0FDF4")),
              pw.SizedBox(width: 10),
              _summaryCard("Generado", generatedAt, PdfColor.fromHex("#FFF7ED")),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              _metricCard("Ingresos", formatCurrency(ingresos),
                  PdfColor.fromHex("#DCFCE7"), PdfColor.fromHex("#15803D")),
              pw.SizedBox(width: 10),
              _metricCard("Gastos", formatCurrency(gastos),
                  PdfColor.fromHex("#FEE2E2"), PdfColor.fromHex("#B91C1C")),
              pw.SizedBox(width: 10),
              _metricCard("Balance", formatCurrency(balance),
                  PdfColor.fromHex("#DBEAFE"), PdfColor.fromHex("#1D4ED8")),
            ],
          ),
          pw.SizedBox(height: 16),

          pw.Table.fromTextArray(
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex("#E8F5E9"),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            headerStyle: pw.TextStyle(
              color: PdfColor.fromHex("#064E3B"),
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(
                color: PdfColor.fromHex("#E2E8F0"),
                width: 0.5,
              ),
            ),
            headers: ["Fecha", "Tipo", "Categoria", "Descripcion", "Moneda", "Monto"],
            data: transactions.map((t) {
              final categoryName =
                  getCategoryName(int.tryParse(t.categoryId) ?? 0);
              final currency =
                  getTransactionCurrency == null ? (t.currency ?? "COP") : getTransactionCurrency(t);

              return [
                DateFormat("dd/MM/yyyy").format(t.date),
                t.type,
                categoryName,
                t.description,
                currency,
                _formatAmount(formatCurrency, t.amount, currency),
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 16),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Balance total: ${formatCurrency(balance)}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: "movimientos_finara.pdf",
    );
  }

  static String _formatAmount(
    Function formatter,
    double amount, [
    String? currency,
  ]) {
    try {
      if (currency != null) return formatter(amount, currency).toString();
    } catch (_) {
      // Some callers still provide a one-argument formatter.
    }
    return formatter(amount).toString();
  }

  static pw.Widget _summaryCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromHex("#64748B"),
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _metricCard(
    String title,
    String value,
    PdfColor background,
    PdfColor foreground,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: background,
          borderRadius: pw.BorderRadius.circular(14),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    color: foreground,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(value,
                style: pw.TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
