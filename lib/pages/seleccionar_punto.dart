import 'package:flutter/material.dart';
import 'package:registro_qr_vehiculos/historial_registros.dart';
import 'scanner_page.dart';

class SeleccionarPuntoPage extends StatelessWidget {
  const SeleccionarPuntoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Punto"),
      ),
      body: ListView(
        children: [
          _buildPuntoButton(context, "A"),
          _buildPuntoButton(context, "B"),
          // Agrega más puntos si lo necesitas
          //_buildPuntoButton(context, "C"),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistorialRegistros()),
              );
            },
            child: const Text("Ver historial"),
          ),
        ],
      ),
    );
  }

  Widget _buildPuntoButton(BuildContext context, String punto) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        title: Text("Registrar en Punto $punto"),
        trailing: const Icon(Icons.qr_code_scanner),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScannerPage(punto: punto),
            ),
          );
        },
      ),
    );
  }
}
