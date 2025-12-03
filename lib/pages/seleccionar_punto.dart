import 'package:flutter/material.dart';
import 'package:registro_qr_vehiculos/historial_registros.dart';
import 'scanner_page.dart';

class SeleccionarPuntoPage extends StatelessWidget {
  final int idLinea;
  final String nombreLinea;
 const SeleccionarPuntoPage({super.key,
  required this.idLinea, required this.nombreLinea});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Seleccionar Punto 'Linea -${nombreLinea}'",
        maxLines: 2,
        style: TextStyle(fontSize: 18),),
      ),
      body: ListView(
        children: [
          _buildPuntoButton(context, "A",Colors.green),
          _buildPuntoButton(context, "B", Colors.amber),
          SizedBox( height: 20,)
          ,ElevatedButton(
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

  Widget _buildPuntoButton(BuildContext context, String punto, Color color) {
    return Card(
      margin: const EdgeInsets.all(12),
      color: color,
      child: ListTile(
        title: Text("Registrar en Punto $punto",style: TextStyle(color: Colors.white,fontSize: 15),),
        trailing: const Icon(Icons.qr_code_scanner, color: Colors.white,),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScannerPage( idLinea: idLinea,punto: punto),
            ),
          );
        },
      ),
      
    );
  }
}
