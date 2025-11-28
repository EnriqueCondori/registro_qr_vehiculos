import 'package:flutter/material.dart';
import 'package:registro_qr_vehiculos/database/db_ayuda.dart';

class HistorialPage extends StatefulWidget {
  @override
  _HistorialPageState createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  List<Map<String, dynamic>> registros = [];

  @override
  void initState() {
    super.initState();
    cargarRegistros();
  }

  Future<void> cargarRegistros() async {
    final data = await DBAyuda.obtenerRegistros();
    setState(() {
      registros = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Historial de QR")),
      body: registros.isEmpty
          ? Center(child: Text("No hay registros aún"))
          : ListView.builder(
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final item = registros[index];
                return Card(
                  child: ListTile(
                    title: Text(item["qr"]),
                    subtitle: Text(item["fecha"]),
                  ),
                );
              },
            ),
    );
  }
}
