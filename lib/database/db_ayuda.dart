import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:registro_qr_vehiculos/config/puntos_config.dart';

class DBAyuda {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  static Future<Database> initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "registros.db");

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute("""
          CREATE TABLE registros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            qr TEXT,
            fecha TEXT,
            punto TEXT,
            estado TEXT
          )
        """);
      },
    );
  }

  // Insertar un registro
  static Future<int> insertarRegistro(String qr, String punto) async {
    final dbClient = await db;

    return await dbClient.insert("registros", {
      "qr": qr,
      "fecha": DateTime.now().toIso8601String(),
      "punto":punto
    });
  }

  // Obtener todos los registros
  static Future<List<Map<String, dynamic>>> obtenerRegistros() async {
    final dbClient = await db;
    return await dbClient.query("registros", orderBy: "id DESC");
  }

  //Eliminar
  static Future<int> eliminarRegistro(int id) async {
    final dbClient = await db;
    return await dbClient.delete("registros", where: "id = ?", whereArgs: [id]);
  }

  //funcion 
  static Future<String> llegoATiempo(String qrActual, String puntoActual) async {
    final dbClient = await db;

    // Buscar el último registro de ese QR
    final result = await dbClient.query(
      "registros",
      where: "qr = ?",
      whereArgs: [qrActual],
      orderBy: "id DESC",
      limit: 1,
    );

    // Si no existe un registro previo → es primer punto
    if (result.isEmpty) {
      return "Primer registro";
    }

    final ultimo = result[0];
    String puntoPrevio = ultimo["punto"].toString();
    DateTime fechaPrevio = DateTime.parse(ultimo["fecha"].toString());

    // Validar si el punto actual es el siguiente esperado
    int idxPrev = PuntosConfig.puntosOrden.indexOf(puntoPrevio);
    int idxActual = PuntosConfig.puntosOrden.indexOf(puntoActual);

    // Si no sigue la secuencia → no se evalúa
    if (idxActual != idxPrev + 1) {
      return "Punto fuera de secuencia";
    }

    // Calcular diferencia de tiempo
    final diferencia = DateTime.now().difference(fechaPrevio).inMinutes;

    if (diferencia <= PuntosConfig.tiempoPermitidoMinutos) {
      return "A tiempo";
    } else {
      return "Tarde";
    }
  }
}
