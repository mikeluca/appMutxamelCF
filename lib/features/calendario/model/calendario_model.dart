import '../../matches/models/match_model.dart';
import 'sesion_entrenamiento_model.dart';

enum TipoItemCalendario { entrenamiento, partido }

/// Elemento genérico del calendario (una sesión de entrenamiento o un
/// partido) normalizado para poder pintarlos juntos en una misma lista,
/// ordenados cronológicamente.
class ItemCalendario {
  final TipoItemCalendario tipo;
  final DateTime fecha;
  final String? hora;
  final bool cancelado;
  final SesionEntrenamientoModel? sesion;
  final MatchModel? partido;

  const ItemCalendario._({
    required this.tipo,
    required this.fecha,
    this.hora,
    required this.cancelado,
    this.sesion,
    this.partido,
  });

  factory ItemCalendario.deSesion(SesionEntrenamientoModel sesion) {
    return ItemCalendario._(
      tipo: TipoItemCalendario.entrenamiento,
      fecha: sesion.fecha,
      hora: sesion.hora,
      cancelado: sesion.cancelada,
      sesion: sesion,
    );
  }

  factory ItemCalendario.dePartido(MatchModel partido) {
    return ItemCalendario._(
      tipo: TipoItemCalendario.partido,
      fecha: partido.dia ?? DateTime.now(),
      hora: partido.hora,
      cancelado: partido.cancelado,
      partido: partido,
    );
  }

  bool get esEntrenamiento => tipo == TipoItemCalendario.entrenamiento;

  /// true si la fecha (sin tener en cuenta la hora) es hoy o posterior.
  bool esFuturoRespectoA(DateTime hoy) {
    final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
    final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);

    return !soloFecha.isBefore(soloHoy);
  }
}

/// Respuesta combinada del calendario de un equipo: sesiones de
/// entrenamiento y partidos dentro de un mismo rango de fechas.
class CalendarioModel {
  final List<SesionEntrenamientoModel> sesiones;
  final List<MatchModel> partidos;

  const CalendarioModel({required this.sesiones, required this.partidos});

  factory CalendarioModel.fromJson(Map<String, dynamic> json) {
    final sesionesJson = json['sesiones'] as List<dynamic>? ?? [];
    final partidosJson = json['partidos'] as List<dynamic>? ?? [];

    return CalendarioModel(
      sesiones: sesionesJson
          .map(
            (item) => SesionEntrenamientoModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      partidos: partidosJson
          .map((item) => MatchModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Todos los elementos (sesiones + partidos) combinados y ordenados
  /// cronológicamente (y, a igual fecha, por hora).
  List<ItemCalendario> get itemsOrdenados {
    final items = <ItemCalendario>[
      ...sesiones.map(ItemCalendario.deSesion),
      ...partidos.map(ItemCalendario.dePartido),
    ];

    items.sort((a, b) {
      final comparacionFecha = a.fecha.compareTo(b.fecha);

      if (comparacionFecha != 0) return comparacionFecha;

      return (a.hora ?? '').compareTo(b.hora ?? '');
    });

    return items;
  }
}
