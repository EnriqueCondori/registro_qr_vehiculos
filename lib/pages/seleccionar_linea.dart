import 'package:flutter/material.dart';
import 'package:registro_qr_vehiculos/pages/seleccionar_punto.dart';

class SeleccionarLineaPage extends StatelessWidget {
  const SeleccionarLineaPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista de líneas específicas con sus respectivos nombres
    final lineas = [
      {'id': 1, 'nombre': '30'},
      {'id': 2, 'nombre': '9'},
      {'id': 3, 'nombre': '158'},
      {'id': 4, 'nombre': '31'},
      // Puedes agregar más líneas aquí según sea necesario
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lineas de Transporte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: lineas.map((linea) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  // Al presionar el botón, navegar a la página de puntos
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeleccionarPuntoPage(
                        idLinea: linea['id'] as int,
                        nombreLinea: linea['nombre'] as String,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white
                ),
                child: Text("Línea ${linea['nombre']}",style: TextStyle(fontSize: 16),), // Muestra el nombre de la línea
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}