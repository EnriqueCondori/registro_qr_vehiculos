
import 'package:flutter/material.dart';
import 'package:registro_qr_vehiculos/database/db_ayuda.dart';

class AdminPuntosPage extends StatefulWidget {
  final int idLinea;
  final String nombreLinea;

  const AdminPuntosPage({
    super.key,
    required this.idLinea,
    required this.nombreLinea,
  });

  @override
  State<AdminPuntosPage> createState() => _AdminPuntosPageState();
}

class _AdminPuntosPageState extends State<AdminPuntosPage> {
  List<Map<String, dynamic>> puntos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarPuntos();
  }

  Future<void> cargarPuntos() async {
    final data = await DBAyuda.obtenerPuntosPorLinea(widget.idLinea);
    setState(() {
      puntos = List<Map<String, dynamic>>.from(data);
      cargando = false;
    });
  }

  // ---------------- AGREGAR PUNTO ----------------
  Future<void> agregarPunto() async {
    String nombre = '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo punto'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Nombre del punto'),
          onChanged: (v) => nombre = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombre.trim().isEmpty) return;

              await DBAyuda.crearPunto(
                widget.idLinea,
                nombre.trim(),
                puntos.length,
              );

              Navigator.pop(context);
              cargarPuntos();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // ---------------- EDITAR ----------------
  Future<void> editarPunto(Map<String, dynamic> punto) async {
    String nombre = punto['nombre'];

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar punto'),
        content: TextField(
          controller: TextEditingController(text: nombre),
          onChanged: (v) => nombre = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await DBAyuda.editarPunto(punto['id'], nombre.trim());
              Navigator.pop(context);
              cargarPuntos();
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  // ---------------- ELIMINAR ----------------
  Future<void> eliminarPunto(int idPunto) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('¿Eliminar este punto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí')),
        ],
      ),
    );

    if (ok == true) {
      await DBAyuda.eliminarPunto(idPunto);
      cargarPuntos();
    }
  }

  // ---------------- REORDENAR ----------------
  Future<void> reordenar(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final item = puntos.removeAt(oldIndex);
    puntos.insert(newIndex, item);

    await DBAyuda.actualizarOrdenPuntos(puntos);
    setState(() {});
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Puntos • Línea ${widget.nombreLinea}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: agregarPunto,
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : puntos.isEmpty
              ? const Center(child: Text('No hay puntos registrados'))
              : ReorderableListView(
                  onReorder: reordenar,
                  children: [
                    for (final punto in puntos)
                      ListTile(
                        key: ValueKey(punto['id']),
                        title: Text(punto['nombre']),
                        leading: const Icon(Icons.place),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => editarPunto(punto),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => eliminarPunto(punto['id']),
                            ),
                            const Icon(Icons.drag_handle),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}