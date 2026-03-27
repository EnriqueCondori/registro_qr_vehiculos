import 'package:registro_qr_vehiculos/config/punto.dart';
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
      version: 2,
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
          id_punto INTEGER,
          estado TEXT
        )
      """);

      await db.execute("""
        CREATE TABLE puntos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_linea INTEGER,
          nombre TEXT,
          orden INTEGER,
          tiempo_hasta_siguiente INTEGER
        )
      """);

        await db.execute("""
      CREATE TABLE IF NOT EXISTS tiempos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_origen INTEGER,
        id_destino INTEGER,
        minutos INTEGER
      );
    """);
        await db.execute("""
      CREATE TABLE tiempos_tramo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_linea INTEGER,
        punto_origen_id INTEGER,
        punto_destino_id INTEGER,
        minutos INTEGER
      )
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

  static Future<int> insertarPunto(Punto punto) async {
    final dbClient = await db;
    return await dbClient.insert("puntos", punto.toMap());
  }

  // Obtener puntos por línea
  static Future<List<Map<String, dynamic>>> obtenerPuntosPorLinea(
    int idLinea,
  ) async {
    final dbClient = await db;
    return await dbClient.query(
      "puntos",
      where: "id_linea = ?",
      whereArgs: [idLinea],
      orderBy: "orden ASC",
    );
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

  //Tiempo
  static Future<int?> obtenerTiempoTramo(
    int idLinea,
    int puntoOrigenId,
    int puntoDestinoId,
  ) async {
    final dbClient = await db;

    final res = await dbClient.query(
      'tiempos_tramo',
      where: 'id_linea = ? AND punto_origen_id = ? AND punto_destino_id = ?',
      whereArgs: [idLinea, puntoOrigenId, puntoDestinoId],
      limit: 1,
    );

    if (res.isEmpty) return null;
    return res.first['minutos'] as int;
  }

  static Future<void> guardarTiempoTramo(
    int idLinea,
    int origenId,
    int destinoId,
    int minutos,
  ) async {
    final dbClient = await db;

    final existe = await dbClient.query(
      'tiempos_tramo',
      where: 'id_linea = ? AND punto_origen_id = ? AND punto_destino_id = ?',
      whereArgs: [idLinea, origenId, destinoId],
    );

    if (existe.isEmpty) {
      await dbClient.insert('tiempos_tramo', {
        'id_linea': idLinea,
        'punto_origen_id': origenId,
        'punto_destino_id': destinoId,
        'minutos': minutos,
      });
    } else {
      await dbClient.update(
        'tiempos_tramo',
        {'minutos': minutos},
        where: 'id_linea = ? AND punto_origen_id = ? AND punto_destino_id = ?',
        whereArgs: [idLinea, origenId, destinoId],
      );
    }
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
  int idPunto,
  String estado,
) async {
  final dbClient = await db;

  return await dbClient.insert("registros", {
    "qr": qr,
    "fecha": DateTime.now().toIso8601String(),
    "id_linea": idLinea,
    "id_punto": idPunto,
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

  return await dbClient.rawQuery("""
    SELECT r.id, r.qr, r.fecha, r.estado,
           l.nombre AS nombre_linea,
           p.nombre AS nombre_punto
    FROM registros r
    LEFT JOIN lineas l ON r.id_linea = l.id
    LEFT JOIN puntos p ON r.id_punto = p.id
    ORDER BY r.id DESC
  """);
}

  //Eliminar
  static Future<int> eliminarRegistro(int id) async {
    final dbClient = await db;
    return await dbClient.delete("registros", where: "id = ?", whereArgs: [id]);
  }

  //funcion
  // static Future<String> llegoATiempo(
  //   String qrActual,
  //   int puntoActualId,
  //   int idLineaActual,
  // ) async {
  //   final dbClient = await db;

  //   // Buscar el último registro de ese QR
  //   final result = await dbClient.query(
  //     "registros",
  //     where: "qr = ?",
  //     whereArgs: [qrActual],
  //     orderBy: "id DESC",
  //     limit: 1,
  //   );

  //   // Obtener puntos de la línea actual
  //   final puntosLinea = await dbClient.query(
  //     'puntos',
  //     where: 'id_linea = ?',
  //     whereArgs: [idLineaActual],
  //     orderBy: 'orden ASC',
  //   );

  //   // Validar que la línea tenga puntos
  //   if (puntosLinea.isEmpty) {
  //     return "Línea sin puntos configurados";
  //   }

  //   // Primer punto dinámico (A)
  //   final primerPunto = puntosLinea.first['nombre'] as String;

  //   // Si no hay registros previos
  //   if (result.isEmpty) {
  //     if (puntoActualId == primerPunto) {
  //       return "Primer registro";
  //     }
  //     return "Debe iniciar en $primerPunto";
  //   }

  //   final ultimo = result.first;

  //   int ultimaLinea = ultimo["id_linea"] as int;

  //   if (ultimaLinea != idLineaActual) {
  //     return "Línea incorrecta — Última línea registrada: $ultimaLinea";
  //   }

  //   int puntoPrevioId = ultimo["punto_id"] as int;
  //   DateTime fechaPrevio = DateTime.parse(ultimo["fecha"].toString());
  //   // Buscar los puntos de la línea actual
  //   final puntos = await dbClient.query(
  //     'puntos',
  //     where: 'id_linea = ?',
  //     whereArgs: [idLineaActual],
  //     orderBy: 'orden ASC',
  //   );
  //   // Buscar ID de los puntos origen y destino
  //   final puntoOrigen = puntos.firstWhere(
  //     (p) => p['id'] == puntoPrevioId,
  //     orElse: () => throw Exception("Punto de origen no encontrado"),
  //   );
  //   final puntoDestino = puntos.firstWhere(
  //     (p) => p['id'] == puntoActualId,
  //     orElse: () => throw Exception("Punto de destino no encontrado"),
  //   );
  //   // Obtener el tiempo configurado entre estos dos puntos
  //   final tiempoPermitido = await obtenerTiempoTramo(
  //     idLineaActual,
  //     puntoOrigen['id'] as int,
  //     puntoDestino['id'] as int,
  //   );

  //   if (tiempoPermitido == null) {
  //     return "Tiempo no configurado";
  //   }

  //   // Calcular la diferencia de tiempo
  //   final diferencia = DateTime.now().difference(fechaPrevio).inMinutes;

  //   // Verificar si llegó tarde
  //   if (diferencia > tiempoPermitido) {
  //     return "Tarde - ${diferencia - tiempoPermitido} min";
  //   }

  //   // Si está dentro del tiempo permitido
  //   return "A tiempo";
  // }

  static Future<String> validarRegistroPorPunto({
  required String qr,
  required int idLinea,
  required int idPuntoActual,
}) async {
  final dbClient = await db;

  final puntos = await dbClient.query(
    'puntos',
    where: 'id_linea = ?',
    whereArgs: [idLinea],
    orderBy: 'orden ASC',
  );

  if (puntos.isEmpty) {
    return "No hay puntos configurados";
  }

  final puntoActual = puntos.firstWhere(
    (p) => p['id'] == idPuntoActual,
  );

  final indexActual = puntos.indexOf(puntoActual);

  final result = await dbClient.query(
    'registros',
    where: 'qr = ? AND id_linea = ?',
    whereArgs: [qr, idLinea],
    orderBy: 'id DESC',
    limit: 1,
  );

  // 🟢 PRIMER REGISTRO
  if (result.isEmpty) {
    if (indexActual == 0) return "Primer registro";
    return "Debe iniciar en ${puntos.first['nombre']}";
  }

  final ultimo = result.first;

  final idPuntoPrevio = ultimo['id_punto'] as int;
  final fechaPrevio = DateTime.parse((ultimo['fecha']?? '').toString());

  final puntoPrevio = puntos.firstWhere((p) => p['id'] == idPuntoPrevio);
  final indexPrevio = puntos.indexOf(puntoPrevio);

  // 🔴 SECUENCIA
  if (indexActual != indexPrevio + 1) {
    return "Fuera de secuencia";
  }

  // 🟡 TIEMPO
  final tiempoPermitido =
      (puntoPrevio['tiempo_hasta_siguiente'] ?? 0) as int;

  final diferencia =
      DateTime.now().difference(fechaPrevio).inMinutes;

  if (diferencia > tiempoPermitido) {
    return "Tarde - ${diferencia - tiempoPermitido} min";
  }

  return "A tiempo";
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
