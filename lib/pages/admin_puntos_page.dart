
import 'package:flutter/material.dart';
import 'package:registro_qr_vehiculos/config/punto.dart';
import 'package:registro_qr_vehiculos/database/db_ayuda.dart';

class AdministrarPuntosPage extends StatefulWidget {
  const AdministrarPuntosPage({super.key});

  @override
  State<AdministrarPuntosPage> createState() => _AdministrarPuntosPageState();
}

class _AdministrarPuntosPageState extends State<AdministrarPuntosPage> {
  int? idLineaSeleccionada;
  List<Map<String, dynamic>> puntos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Administrar Puntos")),
      floatingActionButton: idLineaSeleccionada == null
          ? null
          : FloatingActionButton(
              onPressed: () => mostrarFormulario(),
              child: const Icon(Icons.add),
            ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _selectorLinea(),
            const SizedBox(height: 16),
            Expanded(child: _listaPuntos()),
          ],
        ),
      ),
    );
  }

  Widget _selectorLinea() {
    return DropdownButtonFormField<int>(
      hint: const Text("Seleccionar línea"),
      value: idLineaSeleccionada,
      items: const [
        DropdownMenuItem(value: 1, child: Text("Línea 30")),
        DropdownMenuItem(value: 2, child: Text("Línea 9")),
        DropdownMenuItem(value: 3, child: Text("Línea 158")),
        DropdownMenuItem(value: 4, child: Text("Línea 31")),
      ],
      onChanged: (value) async {
        idLineaSeleccionada = value;
        puntos = await DBAyuda.obtenerPuntosPorLinea(value!);
        setState(() {});
      },
    );
  }

  Widget _listaPuntos() {
    if (idLineaSeleccionada == null) {
      return const Center(child: Text("Seleccione una línea"));
    }

    if (puntos.isEmpty) {
      return const Center(child: Text("No hay puntos registrados"));
    }

    return ListView.builder(
      itemCount: puntos.length,
      itemBuilder: (_, i) {
        final p = puntos[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(p['orden'].toString())),
            title: Text(p['nombre']),
            subtitle:
                Text("Tiempo al siguiente: ${p['tiempo_hasta_siguiente']} min"),
          ),
        );
      },
    );
  }

  void mostrarFormulario() {
    final nombreCtrl = TextEditingController();
    final ordenCtrl = TextEditingController();
    final tiempoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nuevo Punto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: ordenCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Posición")),
            TextField(controller: tiempoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Tiempo (min)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              await DBAyuda.insertarPunto(
                Punto(
                  idLinea: idLineaSeleccionada!,
                  nombre: nombreCtrl.text,
                  orden: int.parse(ordenCtrl.text),
                  tiempoHastaSiguiente: int.parse(tiempoCtrl.text),
                ),
              );
              puntos = await DBAyuda.obtenerPuntosPorLinea(idLineaSeleccionada!);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}
