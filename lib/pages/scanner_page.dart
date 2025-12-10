import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:registro_qr_vehiculos/database/db_ayuda.dart';
import 'package:registro_qr_vehiculos/historial_registros.dart';

class ScannerPage extends StatefulWidget {
  final int idLinea;
  final String punto;
  final String nombreLinea;

  const ScannerPage({
    super.key,
    required this.idLinea,
    required this.punto,
    required this.nombreLinea,
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String qrData = "Esperando escaneo...";
  bool _isProcesando = false;
  DateTime? _lastScanTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Escanear • Punto ${widget.punto}")),
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

                  // Validación de tiempo
                  String estado = await DBAyuda.llegoATiempo(
                    qr,
                    widget.punto,
                    widget.idLinea,
                  );
                  

                  // Guardar en BD
                  await DBAyuda.insertarRegistro(
                    qr,
                    widget.idLinea,
                    widget.punto,
                  );

                 

                  setState(() {
                    qrData = "$qr → $estado";
                  });

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Estado: $estado")));
                }
                // Rehabilitar el escaneo después de un pequeño delay
                await Future.delayed(const Duration(milliseconds: 3500));
                _isProcesando = false;
              },
            ),
          ),
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

          Expanded(
            child: Center(
              child: Text(
                qrData,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
