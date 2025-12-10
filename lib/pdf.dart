import 'dart:typed_data';
import 'package:intl/intl.dart';
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
                headers: ["ID", "QR", "Fecha","Punto","Estado","Linea"],
                data: data
                    .map(
                      (item) => [
                        item["id"].toString(),
                        item["qr"].toString(),
                        formatDate(item["fecha"].toString()),
                        item["punto"],
                        item["estado"],
                        item["nombre_linea"]
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12,
                   
                    ),
                cellStyle: pw.TextStyle(fontSize: 9),
                border: pw.TableBorder.all(),
                cellAlignment: pw.Alignment.center,
                              
                
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}

// Función para formatear la fecha
String formatDate(String dateStr) {
  try {
    DateTime dateTime = DateTime.parse(dateStr);  // Parsear la fecha
    return DateFormat('dd/MM/yyyy').format(dateTime);  // Formatear en el formato deseado
  } catch (e) {
    return dateStr;  // Si falla el parseo, devolver la fecha original
  }
}