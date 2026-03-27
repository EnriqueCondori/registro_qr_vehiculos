import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:registro_qr_vehiculos/database/db_ayuda.dart';
import 'package:registro_qr_vehiculos/historial_registros.dart';

class ScannerPage extends StatefulWidget {
  final int idLinea;
  final int puntoId;
  final String nombrePunto;

  const ScannerPage({
    super.key,
    required this.idLinea,
    required this.puntoId,
    required this.nombrePunto,
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
      appBar: AppBar(title: Text("Escanear • Punto ${widget.nombrePunto}")),
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

                  // 🔥 VALIDAR ESTADO DINÁMICO
                  final estado = await DBAyuda.validarRegistroPorPunto(
                    qr: qr,
                    idLinea: widget.idLinea,
                    idPuntoActual: widget.puntoId,
                  );

                  // ❌ Si no es válido → NO GUARDAR
                  if (estado.contains("Debe") ||
                      estado.contains("incorrecta") ||
                      estado.contains("no configurado") ||
                      estado.contains("Fuera")) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("❌ $estado")));

                    _isProcesando = false;
                    return;
                  }

                  // ✅ GUARDAR
                  await DBAyuda.insertarRegistro(
                    qr,
                    widget.idLinea,
                    widget.puntoId,
                    estado,
                  );

                  setState(() {
                    qrData = "$qr → $estado";
                  });

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("✅ $estado")));
                }

                await Future.delayed(const Duration(seconds: 3));
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
