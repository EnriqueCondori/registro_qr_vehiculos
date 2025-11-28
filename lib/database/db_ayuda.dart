import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
            fecha TEXT
          )
        """);
      },
    );
  }

  // Insertar un registro
  static Future<int> insertarRegistro(String qr) async {
    final dbClient = await db;

    return await dbClient.insert("registros", {
      "qr": qr,
      "fecha": DateTime.now().toIso8601String(),
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
}
