import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

class PDF {
  static Future<Uint8List> generarPDF(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Historial de QR Escaneados",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Tabla de registros
              pw.Table.fromTextArray(
                headers: ["ID", "QR", "Fecha","Punto"],
                data: data
                    .map(
                      (item) => [
                        item["id"].toString(),
                        item["qr"].toString(),
                        item["fecha"].toString(),
                        item["punto".toString()]
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 14),
                cellStyle: pw.TextStyle(fontSize: 12),
                border: pw.TableBorder.all(),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
