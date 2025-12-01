import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:registro_qr_vehiculos/database/db_ayuda.dart';
import 'package:registro_qr_vehiculos/pdf.dart';
import 'package:intl/intl.dart';


class HistorialRegistros extends StatefulWidget {
  const HistorialRegistros({super.key});

  @override
  State<HistorialRegistros> createState() => _HistorialRegistrosState();
}

class _HistorialRegistrosState extends State<HistorialRegistros> {
  List<Map<String, dynamic>> registros = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarRegistros();
  }

  Future<void> cargarRegistros() async {
    final datos = await DBAyuda.obtenerRegistros();
    setState(() {
      registros = datos;
      cargando = false;
    });
  }

  Future<void> eliminarRegistro(int id) async {
    await DBAyuda.eliminarRegistro(id);
    cargarRegistros();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Registro eliminado")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de QR Escaneados"),
        backgroundColor: Colors.deepOrangeAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final pdfData = await PDF.generarPDF(registros);

              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => pdfData,
              );
            },
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : registros.isEmpty
          ? const Center(
              child: Text(
                "No hay registros aún",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final item = registros[index];

                return Card(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black38,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(
                      item["qr"],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('Punto:${item['punto']} ${item['estado']} - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['fecha']))} '),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => eliminarRegistro(item["id"]),
                    ),
                  ),
                  
                );
              },
            ),
    );
  }
}
