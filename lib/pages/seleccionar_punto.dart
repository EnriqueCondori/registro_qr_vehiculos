import 'package:flutter/material.dart';
import 'package:registro_qr_vehiculos/historial_registros.dart';
import 'package:registro_qr_vehiculos/pages/admin_puntos_page.dart';
import 'scanner_page.dart';

class SeleccionarPuntoPage extends StatelessWidget {
  final int idLinea;
  final String nombreLinea;
  const SeleccionarPuntoPage({
    super.key,
    required this.idLinea,
    required this.nombreLinea,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Seleccionar Punto 'Linea -$nombreLinea'",
          maxLines: 2,
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: ListView(
        children: [
          _buildPuntoButton(context, "A", Colors.green),
          _buildPuntoButton(context, "B", Colors.amber),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistorialRegistros()),
              );
            },
            child: const Text("Ver historial"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminPuntosPage(
                    idLinea: idLinea,
                    nombreLinea: nombreLinea,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize
                  .min, // Para que el tamaño del botón sea ajustado al contenido
              children: const [
                Icon(
                  Icons.settings,
                  color: Colors.black,
                ), // Cambia el ícono aquí
                SizedBox(width: 8), // Espacio entre el ícono y el texto
                Text(
                  "Administrar Puntos",
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuntoButton(BuildContext context, String punto, Color color) {
    return Card(
      margin: const EdgeInsets.all(12),
      color: color,
      child: ListTile(
        title: Text(
          "Registrar en Punto $punto",
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        trailing: const Icon(Icons.qr_code_scanner, color: Colors.white),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScannerPage(
                idLinea: idLinea,
                punto: punto,
                nombreLinea: nombreLinea,
              ),
            ),
          );
        },
      ),
    );
  }
}
