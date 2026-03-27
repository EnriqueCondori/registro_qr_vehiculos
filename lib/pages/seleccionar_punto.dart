import 'package:flutter/material.dart';
import 'package:registro_qr_vehiculos/database/db_ayuda.dart';
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
      body: //agregamos desde la base de datos los
      FutureBuilder<List<Map<String, dynamic>>>(
        future: DBAyuda.obtenerPuntosPorLinea(idLinea),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final puntos = snapshot.data!;

          return ListView(
            children: [
              ...puntos.map((punto) {
                return _buildPuntoButton(
                  context,
                  punto,
                  getColorByOrden(punto["orden"]),
                );
              }),
              if (puntos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("No hay puntos registrados")),
                ),

              const SizedBox(height: 20),
              if(puntos.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistorialRegistros(),
                    ),
                  );
                },
                child: const Text("Ver historial"),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdministrarPuntosPage()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.settings, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      "Administrar Puntos",
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPuntoButton(
    BuildContext context,
    Map<String, dynamic> punto,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.all(12),
      color: color,
      child: ListTile(
        title: Text(
          "Registrar en Punto ${punto["nombre"]}",
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        trailing: const Icon(Icons.qr_code_scanner, color: Colors.white),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScannerPage(
                idLinea: idLinea,
                puntoId: (punto['id']) as int,
                nombrePunto: (punto['nombre']) as String,
              ),
            ),
          );
        },
      ),
    );
  }

  Color getColorByOrden(int orden) {
    const colores = [Colors.green, Colors.blue, Colors.orange, Colors.purple];

    return colores[(orden - 1) % colores.length];
  }
}
