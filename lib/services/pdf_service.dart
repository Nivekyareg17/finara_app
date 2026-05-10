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
  }) async {

    final pdf = pw.Document();
    final generatedAt =
        DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            "Movimientos Finara",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text("Usuario: $name"),
          pw.Text("Email: $email"),
          pw.Text("Generado: $generatedAt"),
          pw.SizedBox(height: 16),

          pw.Table.fromTextArray(
            headers: ["Tipo", "Categoria", "Descripcion", "Monto"],
            data: transactions.map((t) {
              final categoryName =
                  getCategoryName(int.tryParse(t.categoryId) ?? 0);

              return [
                t.type,
                categoryName,
                t.description,
                formatCurrency(t.amount),
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
}