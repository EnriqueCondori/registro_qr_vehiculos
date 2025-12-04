

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
        
        await db.execute('''
          CREATE TABLE lineas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT UNIQUE
            );
        ''');
        // Insertar líneas iniciales
        await db.insert("lineas", {"nombre": "30"});
        await db.insert("lineas", {"nombre": "9"});
        await db.insert("lineas", {"nombre": "158"});
        await db.insert("lineas", {"nombre": "31"});

        await db.execute("""
          CREATE TABLE registros (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            qr TEXT,
            fecha TEXT,
            id_linea INTEGER,
            punto TEXT,
            estado TEXT
          )
        """);
      },
    );
  }
  //Crear lineas
  // static Future<int> crearLinea(String nombre) async {
  //   final dbClient = await db;
  //   return await dbClient.insert('lineas', {'nombre': nombre},
  //       conflictAlgorithm: ConflictAlgorithm.ignore);
  // }






  static Future<List<Map<String, dynamic>>> obtenerLineas() async {
    final dbClient = await db;
    return await dbClient.query('lineas', orderBy: 'id');
  }

  // Insertar un registro
  static Future<int> insertarRegistro(
    String qr,
    int idLinea,
    String punto,
    String estado,
  ) async {
    final dbClient = await db;
    print("...................");
    print("Id LINEA $idLinea");

    return await dbClient.insert("registros", {
      "qr": qr,
      "fecha": DateTime.now().toIso8601String(),
      "id_linea": idLinea,
      "punto": punto,
      "estado": estado,
    });
  }

  // Obtener todos los registros
  static Future<List<Map<String, dynamic>>> obtenerRegistros() async {
    final dbClient = await db;
    return await dbClient.query("registros", orderBy: "id DESC");
  }
  //obtener por linea
 static Future<List<Map<String, dynamic>>> obtenerRegistrosConLinea() async {
  final dbClient = await db;

  final registros = await dbClient.rawQuery("""
    SELECT r.id, r.qr, r.fecha, r.punto, r.estado,
           l.nombre AS nombre_linea
    FROM registros r
    LEFT JOIN lineas l ON r.id_linea = l.id
    ORDER BY r.id DESC
  """);
  print("Registro $registros");

  return registros;
}

  //Eliminar
  static Future<int> eliminarRegistro(int id) async {
    final dbClient = await db;
    return await dbClient.delete("registros", where: "id = ?", whereArgs: [id]);
  }

  //funcion
  static Future<String> llegoATiempo(
    String qrActual,
    String puntoActual,
  ) async {
    final dbClient = await db;

    // Buscar el último registro de ese QR
    final result = await dbClient.query(
      "registros",
      where: "qr = ?",
      whereArgs: [qrActual],
      orderBy: "id DESC",
      limit: 1,
    );

    // Si no existe un registro previo → es primer punto (debe ser A)
    if (result.isEmpty && puntoActual == PuntosConfig.puntosOrden[0]) {
      return "Primer registro"; // Solo se puede registrar el primer punto en A
    }

    // Si el último registro existe, obtenemos el punto y la fecha
    final ultimo = result.isNotEmpty ? result[0] : null;
    if (ultimo == null) {
      return "Punto fuera de secuencia"; // Si no existe un registro previo, no se puede continuar.
    }

    String puntoPrevio = ultimo["punto"].toString();
    DateTime fechaPrevio = DateTime.parse(ultimo["fecha"].toString());

    // Caso 1: Si el último registro fue en A y el punto actual es A → marcar como fuera de secuencia.
    if (puntoActual == PuntosConfig.puntosOrden[0] &&
        puntoPrevio == PuntosConfig.puntosOrden[0]) {
      return "Ya marco en A"; // No puedes marcar en A sin haber pasado por B primero
    }

    // Caso 2: Si el último registro fue en A y el punto actual es B, verificar el tiempo de A a B.
    if (puntoActual == PuntosConfig.puntosOrden[1] &&
        puntoPrevio == PuntosConfig.puntosOrden[0]) {
      // Verificar el tiempo desde A a B
      final diferencia = DateTime.now().difference(fechaPrevio).inMinutes;
      
      // Si la diferencia es mayor que 15 minutos, devuelve "Tarde"
      if (diferencia > PuntosConfig.tiempoPermitidoMinutos) {
        final retardo=diferencia-PuntosConfig.tiempoPermitidoMinutos;
        return "Tarde - $retardo minutos";
      } else {
        return "A tiempo";
      }
    }

    // Caso 3: Si el último registro fue en B y el punto actual es A, reiniciar ciclo.
    if (puntoActual == PuntosConfig.puntosOrden[0] &&
        puntoPrevio == PuntosConfig.puntosOrden[1]) {
      return "Inicio"; // El ciclo A → B → A se ha completado, reinicia con "Inicio"
    }

    // Caso 4: Si el ciclo no sigue la secuencia de A → B → A, marcar como "Punto fuera de secuencia"
    return "Fuera de secuencia";
  }
  static Future<Map<String, dynamic>?> obtenerUltimoRegistroQRLinea(
      String qr, int idLinea) async {
    final dbClient = await db;
    final rows = await dbClient.query('registros',
        where: 'qr = ? AND id_linea = ?', whereArgs: [qr, idLinea], orderBy: 'id DESC', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }
}
