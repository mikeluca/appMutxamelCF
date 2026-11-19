import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../ficha_partido/models/ficha_partido_model.dart';

/// Los tamaños de la imagen: la publicación (1080x1350) y la historia (1080x1920).
enum FormatoCompartir {
  publicacion(1350),
  historia(1920);

  final double alto;

  const FormatoCompartir(this.alto);
}

/// El aspecto de la imagen: el azul del club (por defecto), oscuro o claro.
enum EstiloCompartir { club, oscuro, claro }

/// Lo que se puede activar o desactivar en la vista previa.
class OpcionesCompartir {
  final FormatoCompartir formato;
  final EstiloCompartir estilo;
  final bool goleadores;
  final bool racha;
  final bool qr;

  /// La línea "#somMTX #mareaAzul #MutxamelCF" de la imagen. Siempre empieza marcada (no se guarda la elección).
  final bool hashtags;

  const OpcionesCompartir({
    this.formato = FormatoCompartir.publicacion,
    this.estilo = EstiloCompartir.club,
    this.goleadores = true,
    this.racha = true,
    this.qr = true,
    this.hashtags = true,
  });

  OpcionesCompartir copiaCon({
    FormatoCompartir? formato,
    EstiloCompartir? estilo,
    bool? goleadores,
    bool? racha,
    bool? qr,
    bool? hashtags,
  }) {
    return OpcionesCompartir(
      formato: formato ?? this.formato,
      estilo: estilo ?? this.estilo,
      goleadores: goleadores ?? this.goleadores,
      racha: racha ?? this.racha,
      qr: qr ?? this.qr,
      hashtags: hashtags ?? this.hashtags,
    );
  }
}

/// En qué punto está el partido, para la etiqueta de la imagen.
enum FaseCompartir {
  /// Es hoy y todavía no ha empezado.
  hoy,

  /// Otro día.
  proximo,
  enJuego,
  descanso,
  finalizado,
  cancelado,
}

/// Cómo acabó el partido para nosotros.
enum ResultadoCompartir { victoria, empate, derrota }

/// Lo que lleva la imagen de compartir (y el texto que la acompaña): nombres de equipos, marcador, estado,
/// competición, fecha, campo, goleadores (solo el nombre en directo) y la racha. Nunca fotos de jugadores ni ningún
/// dato personal.
class DatosCompartir {
  static const String hashtags = '#somMTX #mareaAzul #MutxamelCF';
  static const String web = 'https://mutxamelcf.es';

  /// Cuántos goleadores caben en la imagen; el resto sale como "y N más".
  static const int maxGoleadores = 6;

  final String local;
  final String visitante;
  final bool mutxamelEsLocal;

  /// Goles del local y del visitante tal como se pintan; null si no hay marcador (antes del partido).
  final int? golesLocal;
  final int? golesVisitante;

  final FaseCompartir fase;

  /// La etiqueta destacada, ya en el idioma de la app y en mayúsculas: "FINAL", "EN DIRECTO · 67'", "DESCANSO",
  /// "DÍA DE PARTIDO", "PRÓXIMO PARTIDO"...
  final String etiqueta;

  /// La hora del partido ("18:00"); null si no la hay.
  final String? hora;

  /// "Preferente Valenciana · Jornada 9" o "Amistoso".
  final String competicion;

  /// "08/11/2026".
  final String fecha;

  /// El campo del partido; null si no hay.
  final String? campo;

  /// Nuestros goleadores y los últimos partidos (del más antiguo al más reciente).
  final List<GoleadorFicha> goleadores;
  final List<FormaFicha> racha;

  /// El estado en el texto corto que acompaña a la imagen: "Final", "67'", "Descanso" o, antes del partido, día y hora.
  final String estadoTexto;

  /// Los textos del marcador (y de "antes del partido") para el texto que acompaña a la imagen.
  final String _textoBase;

  /// Escudo del club rival (ruta relativa del backend) y si el rival es un equipo de nuestro club.
  final String? escudoRivalUrl;
  final bool rivalEsPropio;

  const DatosCompartir({
    required this.local,
    required this.visitante,
    required this.mutxamelEsLocal,
    this.golesLocal,
    this.golesVisitante,
    this.fase = FaseCompartir.proximo,
    this.etiqueta = '',
    this.hora,
    this.competicion = '',
    this.fecha = '',
    this.campo,
    this.goleadores = const [],
    this.racha = const [],
    this.estadoTexto = '',
    String textoBase = '',
    this.escudoRivalUrl,
    this.rivalEsPropio = false,
  }) : _textoBase = textoBase;

  /// Los mismos datos con otro escudo del rival (sin él, el genérico).
  DatosCompartir conEscudoRival(String? url) => DatosCompartir(
    local: local,
    visitante: visitante,
    mutxamelEsLocal: mutxamelEsLocal,
    golesLocal: golesLocal,
    golesVisitante: golesVisitante,
    fase: fase,
    etiqueta: etiqueta,
    hora: hora,
    competicion: competicion,
    fecha: fecha,
    campo: campo,
    goleadores: goleadores,
    racha: racha,
    estadoTexto: estadoTexto,
    textoBase: _textoBase,
    escudoRivalUrl: url,
    rivalEsPropio: rivalEsPropio,
  );

  /// Si el partido ya se ha jugado o se está jugando (hay marcador).
  bool get jugado =>
      fase == FaseCompartir.enJuego ||
      fase == FaseCompartir.descanso ||
      fase == FaseCompartir.finalizado;

  bool get antesDelPartido =>
      fase == FaseCompartir.hoy || fase == FaseCompartir.proximo;

  /// "2 - 1"; null antes del partido, cancelado o sin marcador.
  String? get marcador => jugado && golesLocal != null && golesVisitante != null
      ? '$golesLocal - $golesVisitante'
      : null;

  /// Hay goleadores que enseñar (el partido se ha jugado o se está jugando).
  bool get tieneGoleadores => jugado && goleadores.isNotEmpty;

  bool get tieneRacha => racha.isNotEmpty;

  /// Victoria, empate o derrota al final del partido; null si no ha terminado.
  ResultadoCompartir? get resultado {
    if (fase != FaseCompartir.finalizado ||
        golesLocal == null ||
        golesVisitante == null) {
      return null;
    }

    final nuestros = mutxamelEsLocal ? golesLocal! : golesVisitante!;
    final suyos = mutxamelEsLocal ? golesVisitante! : golesLocal!;

    return nuestros > suyos
        ? ResultadoCompartir.victoria
        : nuestros == suyos
        ? ResultadoCompartir.empate
        : ResultadoCompartir.derrota;
  }

  /// "⚽ Pepe 23' 67'"; sin minutos, "⚽ Pepe x2" (o solo "⚽ Pepe" con un gol).
  static String lineaGoleador(GoleadorFicha g) {
    if (g.minutos.isNotEmpty) {
      return "⚽ ${g.nombre} ${g.minutos.map((m) => "$m'").join(' ')}";
    }

    return g.goles > 1 ? '⚽ ${g.nombre} x${g.goles}' : '⚽ ${g.nombre}';
  }

  /// El texto que acompaña a la imagen: "Mutxamel C.F. 3-1 Rival · Final ⚽ Pepe (2), Juanma #somMTX #mareaAzul
  /// #MutxamelCF https://mutxamelcf.es". Sin goleadores si no hay (o si se han desactivado).
  String textoCompartir({bool conGoleadores = true}) {
    final partes = <String>[_textoBase];

    if (conGoleadores && tieneGoleadores) {
      partes.add(
        '⚽ ${goleadores.map((g) => g.goles > 1 ? '${g.nombre} (${g.goles})' : g.nombre).join(', ')}',
      );
    }

    partes.add(hashtags);
    partes.add(web);

    return partes.join(' ');
  }

  /// Los datos de la imagen a partir de la ficha. [ahora] pone el reloj de los partidos en juego y decide si es hoy.
  factory DatosCompartir.desdeFicha(
    FichaPartido ficha,
    AppLocalizations t, {
    required DateTime ahora,
  }) {
    final c = ficha.cabecera;
    final fecha = c.dia == null ? '' : DateFormat('dd/MM/yyyy').format(c.dia!);
    final hora = c.hora?.trim();
    final horaONull = hora == null || hora.isEmpty ? null : hora;
    final minutos = c.reloj?.tiempo(ahora)?.inMinutes;
    final descansando = c.reloj?.enDescanso ?? false;

    final esHoy =
        c.dia != null &&
        c.dia!.year == ahora.year &&
        c.dia!.month == ahora.month &&
        c.dia!.day == ahora.day;

    final fase = switch (c.estado) {
      EstadoFicha.enJuego =>
        descansando ? FaseCompartir.descanso : FaseCompartir.enJuego,
      EstadoFicha.descanso => FaseCompartir.descanso,
      EstadoFicha.finalizado => FaseCompartir.finalizado,
      EstadoFicha.cancelado => FaseCompartir.cancelado,
      EstadoFicha.proximo => esHoy ? FaseCompartir.hoy : FaseCompartir.proximo,
    };

    final etiqueta = switch (fase) {
      FaseCompartir.enJuego =>
        minutos == null ? t.shareLabelLive : "${t.shareLabelLive} · $minutos'",
      FaseCompartir.descanso => t.shareLabelHalftime,
      FaseCompartir.finalizado => t.shareLabelFinal,
      FaseCompartir.cancelado => t.shareLabelCancelled,
      FaseCompartir.hoy => t.shareLabelMatchDay,
      FaseCompartir.proximo => t.shareLabelNextMatch,
    };

    final estadoTexto = switch (fase) {
      FaseCompartir.enJuego =>
        minutos == null ? t.fichaStatusLive : "$minutos'",
      FaseCompartir.descanso => t.fichaStatusHalftime,
      FaseCompartir.finalizado => t.shareStatusFinal,
      FaseCompartir.cancelado => t.fichaStatusCancelled,
      _ => [fecha, ?horaONull].where((s) => s.isNotEmpty).join(' · '),
    };

    final jugado =
        fase == FaseCompartir.enJuego ||
        fase == FaseCompartir.descanso ||
        fase == FaseCompartir.finalizado;
    final tieneMarcador = c.golesLocal != null && c.golesVisitante != null;

    // Los parámetros van en orden alfabético (el de gen-l10n): estado, local, marcador, visitante.
    final textoBase = jugado && tieneMarcador
        ? t.shareTextScore(
            estadoTexto,
            c.nombreLocal,
            '${c.golesLocal}-${c.golesVisitante}',
            c.nombreVisitante,
          )
        : t.shareTextUpcoming(estadoTexto, c.nombreLocal, c.nombreVisitante);

    // La forma llega del más reciente al más antiguo; en la imagen va del más antiguo al más reciente.
    final racha = ficha.forma.take(5).toList().reversed.toList();

    return DatosCompartir(
      local: c.nombreLocal,
      visitante: c.nombreVisitante,
      mutxamelEsLocal: c.mutxamelEsLocal,
      golesLocal: c.golesLocal,
      golesVisitante: c.golesVisitante,
      fase: fase,
      etiqueta: etiqueta,
      hora: horaONull,
      competicion: c.competicion,
      fecha: fecha,
      campo: c.campo,
      goleadores: c.goleadores.where((g) => g.nombre.isNotEmpty).toList(),
      racha: racha,
      estadoTexto: estadoTexto,
      textoBase: textoBase,
      escudoRivalUrl: c.escudoRivalUrl,
      rivalEsPropio: c.rivalEsPropio,
    );
  }
}
