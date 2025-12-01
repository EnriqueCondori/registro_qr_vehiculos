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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
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
