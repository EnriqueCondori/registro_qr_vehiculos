import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:registro_qr_vehiculos/database/db_ayuda.dart';
import 'package:registro_qr_vehiculos/historial_registros.dart';

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
      home: const MyHomePage(title: 'Registro Vehicular', punto: "A"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.punto});
  final String title;
  final String punto;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String qrData = "No se ha encontrado nada";
  bool _isProcesando = false;
  DateTime? _lastScanTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: MobileScanner(
              onDetect: (capture) async {
                final ahora = DateTime.now();

                if (_isProcesando) return;

                if (_lastScanTime != null &&
                    ahora.difference(_lastScanTime!) < Duration(seconds: 2)) {
                  return; // Ignorar si escaneó hace menos de 2 segundos
                }
                _isProcesando = true;
                _lastScanTime = ahora;

                final barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final qr = barcodes.first.rawValue ?? "QR vacío";
                  //verificar si llego a tiempó
                  String estado = await DBAyuda.llegoATiempo(qr, widget.punto);
                  // Guardar en BD
                  await DBAyuda.insertarRegistro(qr, widget.punto, estado);

                  setState(() {
                    qrData = "$qr → $estado";
                  });

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Estado: $estado")));
                }

                if (barcodes.isNotEmpty) {
                  final qr = barcodes.first.rawValue ?? "QR vacío";

                  await DBAyuda.insertarRegistro(qr, "P-A");

                  setState(() {
                    qrData = qr;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Registrado en el Punto A: $qr")),
                  );
                }
                // Rehabilitar el escaneo después de un pequeño delay
                await Future.delayed(Duration(seconds: 4));
                _isProcesando = false;
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistorialRegistros()),
              );
            },
            child: Text("Ver historial"),
          ),
          Expanded(
            child: Center(
              child: Text(
                "Resultado: $qrData",
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
