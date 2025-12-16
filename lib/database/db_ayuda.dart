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
        await db.execute("""
      CREATE TABLE IF NOT EXISTS puntos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_linea INTEGER,
        nombre TEXT,
        orden INTEGER
      );
    """);

        await db.execute("""
      CREATE TABLE IF NOT EXISTS tiempos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_origen INTEGER,
        id_destino INTEGER,
        minutos INTEGER
      );
    """);
      },
    );
  }

  //Crear lineas
  // ----------------------- PUNTOS -----------------------
  static Future<int> crearPunto(int idLinea, String nombre, int orden) async {
    final dbClient = await db;
    return await dbClient.insert('puntos', {
      'id_linea': idLinea,
      'nombre': nombre,
      'orden': orden,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> obtenerPuntosPorLinea(
    int idLinea,
  ) async {
    final dbClient = await db;
    final rows = await dbClient.query(
      'puntos',
      where: 'id_linea = ?',
      whereArgs: [idLinea],
      orderBy: 'orden ASC',
    );
    return rows;
  }

 static Future<int> editarPunto(int idPunto, String nombre) async {
  final dbClient = await db;
  return await dbClient.update(
    'puntos',
    {'nombre': nombre},
    where: 'id = ?',
    whereArgs: [idPunto],
  );
}

  static Future<int> actualizarOrdenPuntos(
    List<Map<String, dynamic>> puntos,
  ) async {
    final dbClient = await db;
    final batch = dbClient.batch();
    for (var p in puntos) {
      batch.update(
        'puntos',
        {'orden': p['orden']},
        where: 'id = ?',
        whereArgs: [p['id']],
      );
    }
    await batch.commit(noResult: true);
    return 1;
  }

  static Future<int> eliminarPunto(int idPunto) async {
    final dbClient = await db;
    // eliminar tiempos relacionados
    await dbClient.delete(
      'tiempos',
      where: 'id_origen = ? OR id_destino = ?',
      whereArgs: [idPunto, idPunto],
    );
    return await dbClient.delete(
      'puntos',
      where: 'id = ?',
      whereArgs: [idPunto],
    );
  }

  // ----------------------- TIEMPOS -----------------------
  static Future<int> crearOActualizarTiempo(
    int idOrigen,
    int idDestino,
    int minutos,
  ) async {
    final dbClient = await db;
    // si ya existe, actualizar; si no, insertar
    final rows = await dbClient.query(
      'tiempos',
      where: 'id_origen = ? AND id_destino = ?',
      whereArgs: [idOrigen, idDestino],
      limit: 1,
    );

    if (rows.isEmpty) {
      return await dbClient.insert('tiempos', {
        'id_origen': idOrigen,
        'id_destino': idDestino,
        'minutos': minutos,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      return await dbClient.update(
        'tiempos',
        {'minutos': minutos},
        where: 'id_origen = ? AND id_destino = ?',
        whereArgs: [idOrigen, idDestino],
      );
    }
  }

  static Future<int?> obtenerTiempoEntrePuntos(
    int idOrigen,
    int idDestino,
  ) async {
    final dbClient = await db;
    final rows = await dbClient.query(
      'tiempos',
      where: 'id_origen = ? AND id_destino = ?',
      whereArgs: [idOrigen, idDestino],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['minutos'] as int;
  }

  static Future<List<Map<String, dynamic>>> obtenerTiemposPorLinea(
    int idLinea,
  ) async {
    // Devuelve los tiempos para tramos entre puntos de la misma línea
    final dbClient = await db;
    final puntos = await obtenerPuntosPorLinea(idLinea);
    if (puntos.isEmpty) return [];

    // construir lista de ids de puntos de la linea
    final ids = puntos.map((p) => p['id']).toList();
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await dbClient.rawQuery(
      '''
    SELECT t.id, t.id_origen, t.id_destino, t.minutos,
           po.nombre AS origen_nombre, pd.nombre AS destino_nombre
    FROM tiempos t
    LEFT JOIN puntos po ON t.id_origen = po.id
    LEFT JOIN puntos pd ON t.id_destino = pd.id
    WHERE t.id_origen IN ($placeholders) AND t.id_destino IN ($placeholders)
  ''',
      [...ids, ...ids],
    );
    return rows;
  }

  static Future<List<Map<String, dynamic>>> obtenerLineas() async {
    final dbClient = await db;
    return await dbClient.query('lineas', orderBy: 'id');
  }

  // Insertar un registro
  static Future<int> insertarRegistro(
    String qr,
    int idLinea,
    String punto,
  ) async {
    final dbClient = await db;
    //Validar que el registro cumple con la secuencia antes de insertarlo
    final resultado = await llegoATiempo(qr, punto, idLinea);
    if (resultado == "Debe iniciar en el Punto A" ||
        resultado == "Fuera de secuencia" ||
        resultado == "Ya marco en A" ||
        resultado == "Línea incorrecta — Última línea registrada%") {
      return -1; // Indica que no se pudo registrar porque no sigue la secuencia
    }

    return await dbClient.insert("registros", {
      "qr": qr,
      "fecha": DateTime.now().toIso8601String(),
      "id_linea": idLinea,
      "punto": punto,
      "estado": resultado,
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
    int idLineaActual,
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
    // if (result.isEmpty && puntoActual == PuntosConfig.puntosOrden[0]) {
    //   return "Primer registro"; // Solo se puede registrar el primer punto en A
    // }

    // Si el último registro existe, obtenemos el punto y la fecha
    //final ultimo = result.isNotEmpty ? result[0] : null;
    // Si no existe registro previo → solo permitir punto A
    if (result.isEmpty) {
      if (puntoActual == PuntosConfig.puntosOrden[0]) {
        return "Primer registro";
      }
      return "Debe iniciar en el Punto A";
    }
    //
    final ultimo = result.first;

    int ultimaLinea = ultimo["id_linea"] as int;

    if (ultimaLinea != idLineaActual) {
      return "Línea incorrecta — Última línea registrada: $ultimaLinea";
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
        final retardo = diferencia - PuntosConfig.tiempoPermitidoMinutos;
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
    String qr,
    int idLinea,
  ) async {
    final dbClient = await db;
    final rows = await dbClient.query(
      'registros',
      where: 'qr = ? AND id_linea = ?',
      whereArgs: [qr, idLinea],
      orderBy: 'id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }
}
