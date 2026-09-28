/// Temporada del club (configurada por el administrador en la web),
/// usada para acotar "partidos pasados" del calendario a la temporada
/// en curso en vez de a una ventana de fechas fija.
class TemporadaModel {
  final int id;
  final String nombre;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  const TemporadaModel({
    required this.id,
    required this.nombre,
    this.fechaInicio,
    this.fechaFin,
  });

  factory TemporadaModel.fromJson(Map<String, dynamic> json) {
    return TemporadaModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      fechaInicio: _parseFecha(json['fechaInicio']),
      fechaFin: _parseFecha(json['fechaFin']),
    );
  }

  // La temporada usa java.util.Date en el backend (igual que Partido.dia):
  // llega como epoch en milisegundos, no como texto ISO.
  static DateTime? _parseFecha(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.tryParse(value.toString());
  }
}
