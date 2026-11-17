import '../../features/convocatorias/model/convocatoria_partido_model.dart';
import '../../features/ficha_partido/models/ficha_partido_model.dart';
import '../../features/matches/models/match_model.dart';
import '../../l10n/gen/app_localizations.dart';

/// Un evento de calendario ya montado (lo que se le pasa al calendario del sistema).
class EventoCalendario {
  final String titulo;
  final String? descripcion;
  final String? lugar;

  /// El instante de inicio. Con [todoElDia], la medianoche UTC de ese día.
  final DateTime inicio;
  final DateTime fin;
  final bool todoElDia;

  /// La zona del evento (hora de España); null en los eventos de todo el día.
  final String? zonaHoraria;

  const EventoCalendario({
    required this.titulo,
    required this.inicio,
    required this.fin,
    required this.todoElDia,
    this.descripcion,
    this.lugar,
    this.zonaHoraria,
  });
}

/// Lo que se añade a las notas del evento de quien tiene convocatoria al partido (nunca datos de otros jugadores).
class NotasConvocatoria {
  final String? horaCitacion;
  final String? lugarCitacion;
  final String? equipaje;

  const NotasConvocatoria({
    this.horaCitacion,
    this.lugarCitacion,
    this.equipaje,
  });

  factory NotasConvocatoria.desde(ConvocatoriaPartidoModel convocatoria) {
    return NotasConvocatoria(
      horaCitacion: convocatoria.horaCitacion,
      lugarCitacion: convocatoria.lugarCitacion,
      equipaje: convocatoria.equipacion?.nombre,
    );
  }
}

/// Monta el evento de calendario de un partido que todavía no se ha jugado.
class EventoPartido {
  EventoPartido._();

  static const String club = 'Mutxamel C.F.';
  static const String zona = 'Europe/Madrid';

  /// La modalidad (F11, F8 o F5): la que mande el backend y, si no la manda, la que corresponde al nombre del equipo.
  static String modalidadDe(String? modalidad, String equipo) {
    final m = modalidad?.trim().toUpperCase();

    if (m == 'F11' || m == 'F8' || m == 'F5') return m!;

    final nombre = equipo.toLowerCase();

    if (nombre.contains('prebenjam') ||
        nombre.contains('benjam') ||
        nombre.contains('alev')) {
      return 'F8';
    }

    if (nombre.contains('chupet') || nombre.contains('esc')) return 'F5';

    return 'F11';
  }

  /// 2 h en Fútbol 11; 1 h 30 en Fútbol 8 y Fútbol 5.
  static Duration duracion(String modalidad) => modalidad == 'F11'
      ? const Duration(hours: 2)
      : const Duration(minutes: 90);

  /// El título: "Mutxamel C.F. - Rival" (o "Rival - Mutxamel C.F." si se juega fuera) y, si no es el Primer Equipo, con
  /// el equipo después del club: "Mutxamel C.F. Infantil A - Rival".
  static String titulo({
    required String equipo,
    required String rival,
    required bool local,
  }) {
    final nuestro = _esPrimerEquipo(equipo) || equipo.trim().isEmpty
        ? club
        : '$club ${equipo.trim()}';

    return local ? '$nuestro - $rival' : '$rival - $nuestro';
  }

  static bool _esPrimerEquipo(String equipo) =>
      equipo.trim().toLowerCase() == 'primer equipo';

  /// El evento de un partido de las listas. Sin hora, de todo el día.
  static EventoCalendario? desdeMatch(
    MatchModel partido,
    AppLocalizations t, {
    NotasConvocatoria? convocatoria,
    String? modalidad,
    int? jornada,
    String? competicion,
  }) {
    final dia = partido.dia;

    if (dia == null) return null;

    return montar(
      t,
      equipo: partido.equipo,
      rival: partido.rival,
      local: partido.local,
      dia: dia,
      hora: partido.hora,
      campo: partido.campo,
      competicion: competicion ?? partido.tipo,
      jornada: jornada,
      modalidad: modalidad,
      convocatoria: convocatoria,
    );
  }

  /// El evento de la ficha de un partido del Primer Equipo.
  static EventoCalendario? desdeFicha(
    CabeceraFicha cabecera,
    AppLocalizations t,
  ) {
    final dia = cabecera.dia;

    if (dia == null) return null;

    final local = cabecera.mutxamelLocal ?? true;

    return montar(
      t,
      equipo: 'Primer Equipo',
      rival: local ? cabecera.equipoVisitante : cabecera.equipoLocal,
      local: local,
      dia: dia,
      hora: cabecera.hora,
      campo: cabecera.campo,
      competicion: cabecera.competicion,
      jornada: cabecera.jornada,
    );
  }

  static EventoCalendario montar(
    AppLocalizations t, {
    required String equipo,
    required String rival,
    required bool local,
    required DateTime dia,
    String? hora,
    String? campo,
    String? competicion,
    int? jornada,
    String? modalidad,
    NotasConvocatoria? convocatoria,
  }) {
    final notas = <String>[
      if (competicion?.trim().isNotEmpty == true) competicion!.trim(),
      if (jornada != null && jornada > 0) t.calendarNoteRound(jornada),
      if (convocatoria?.horaCitacion?.trim().isNotEmpty == true)
        t.calendarNoteMeetTime(convocatoria!.horaCitacion!.trim()),
      if (convocatoria?.lugarCitacion?.trim().isNotEmpty == true)
        t.calendarNoteMeetPlace(convocatoria!.lugarCitacion!.trim()),
      if (convocatoria?.equipaje?.trim().isNotEmpty == true)
        t.calendarNoteKit(convocatoria!.equipaje!.trim()),
    ];

    final titulo = EventoPartido.titulo(
      equipo: equipo,
      rival: rival,
      local: local,
    );
    final lugar = campo?.trim().isNotEmpty == true ? campo!.trim() : null;
    final descripcion = notas.isEmpty ? null : notas.join('\n');
    final partesHora = _leerHora(hora);

    // Sin hora: evento de todo el día.
    if (partesHora == null) {
      final medianoche = DateTime.utc(dia.year, dia.month, dia.day);

      return EventoCalendario(
        titulo: titulo,
        descripcion: descripcion,
        lugar: lugar,
        inicio: medianoche,
        fin: medianoche,
        todoElDia: true,
      );
    }

    final inicio = instanteEnEspana(
      dia.year,
      dia.month,
      dia.day,
      partesHora.hora,
      partesHora.minuto,
    );

    return EventoCalendario(
      titulo: titulo,
      descripcion: descripcion,
      lugar: lugar,
      inicio: inicio,
      fin: inicio.add(duracion(modalidadDe(modalidad, equipo))),
      todoElDia: false,
      zonaHoraria: zona,
    );
  }

  static ({int hora, int minuto})? _leerHora(String? hora) {
    final texto = hora?.trim() ?? '';
    final partes = texto.split(':');

    if (partes.length < 2) return null;

    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);

    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }

    return (hora: h, minuto: m);
  }

  /// El instante (en UTC) en que son las [hora]:[minuto] del [dia] en España peninsular: UTC+1 en invierno y UTC+2 en
  /// verano (del último domingo de marzo al último de octubre, a la 01:00 UTC).
  static DateTime instanteEnEspana(
    int ano,
    int mes,
    int dia,
    int hora,
    int minuto,
  ) {
    final comoUtc = DateTime.utc(ano, mes, dia, hora, minuto);
    // Si fuera verano serian 2 horas menos: se comprueba que ese instante cae dentro del horario de verano.
    final candidato = comoUtc.subtract(const Duration(hours: 2));
    final enVerano =
        !candidato.isBefore(_ultimoDomingo(ano, DateTime.march)) &&
        candidato.isBefore(_ultimoDomingo(ano, DateTime.october));

    return comoUtc.subtract(Duration(hours: enVerano ? 2 : 1));
  }

  /// El último domingo del mes a la 01:00 UTC (cuando cambia la hora en la Unión Europea).
  static DateTime _ultimoDomingo(int ano, int mes) {
    var d = DateTime.utc(ano, mes + 1, 0, 1); // último día del mes

    while (d.weekday != DateTime.sunday) {
      d = d.subtract(const Duration(days: 1));
    }

    return d;
  }
}
