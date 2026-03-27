class Punto {
  final int? id;
  final int idLinea;
  final String nombre;
  final int orden;
  final int tiempoHastaSiguiente;

  Punto({
    this.id,
    required this.idLinea,
    required this.nombre,
    required this.orden,
    required this.tiempoHastaSiguiente,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_linea': idLinea,
      'nombre': nombre,
      'orden': orden,
      'tiempo_hasta_siguiente': tiempoHastaSiguiente,
    };
  }
}
