import 'package:flutter/material.dart';
import 'package:registro_qr_vehiculos/pages/seleccionar_linea.dart';
import 'package:registro_qr_vehiculos/pages/seleccionar_punto.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro Vehículos',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const SeleccionarLineaPage(),
    );
  }
}




