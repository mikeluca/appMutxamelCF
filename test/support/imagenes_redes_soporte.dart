import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_mutxamel_cf/features/imagenes_redes/models/imagenes_redes_model.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/models/partido_primer_equipo_model.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/services/imagenes_redes_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

/// Un PNG de 1x1 píxel.
final Uint8List pngDePrueba = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

final DateTime viernesDePrueba = DateTime(2026, 11, 13);

ImagenRedesModel imagenDePrueba(
  int id,
  String tipo,
  String modalidad,
  int pagina,
  int total, {
  int version = 1,
}) {
  return ImagenRedesModel(
    id: id,
    tipo: tipo,
    modalidad: modalidad,
    pagina: pagina,
    totalPaginas: total,
    version: version,
  );
}

ImagenesRedesModel modeloDePrueba(
  List<ImagenRedesModel> imagenes, {
  DateTime? desde,
}) {
  final inicio = desde ?? viernesDePrueba;

  return ImagenesRedesModel(
    desde: inicio,
    hasta: DateTime(inicio.year, inicio.month, inicio.day + 2),
    imagenes: imagenes,
    textoPrevia: 'Texto previa #somMTX #mareaAzul #MutxamelCF',
    textoResultados: 'Texto resultados #somMTX #mareaAzul #MutxamelCF',
  );
}

const String textoEsDePrueba =
    'Próximo partido: Mutxamel C.F. – Salesianos. Sábado 21/11 a las 17:30, Camp Nou Los Olmos (Mutxamel). '
    '¡Os esperamos! #somMTX #mareaAzul #MutxamelCF';
const String textoCaDePrueba =
    'Pròxim partit: Mutxamel C.F. – Salesianos. Dissabte 21/11 a les 17:30, Camp Nou Los Olmos (Mutxamel). '
    'Us esperem! #somMTX #mareaAzul #MutxamelCF';

PartidoPrimerEquipoModel partidoDePrueba({bool local = true}) {
  return PartidoPrimerEquipoModel(
    disponible: true,
    partidoId: 30,
    local: local,
    rival: 'Salesianos Alicante',
    dia: DateTime(2026, 11, 21),
    hora: '17:30',
    campo: 'Camp Nou Los Olmos (Mutxamel)',
    competicion: 'Primera FFCV, Grup 4',
    jornada: 11,
    textoEs: textoEsDePrueba,
    textoCa: textoCaDePrueba,
  );
}

/// Un servicio de imágenes para redes sin red, configurable.
class ServicioImagenesFalso extends ImagenesRedesService {
  ImagenesRedesModel actual;
  ImagenesRedesModel? trasRegenerar;
  PartidoPrimerEquipoModel partido;

  /// Lo del cartel del Filial (lo de arriba es el del Primer Equipo).
  PartidoPrimerEquipoModel partidoFilial = partidoDePrueba();
  final List<OpcionesCartel> cartelesFilial = [];
  final List<Object> fallosCartelFilial = [];
  Object? falloPartidoFilial;
  int partidosPedidosFilial = 0;

  /// Todas las peticiones de partido y de PNG, en orden, con su equipo.
  final List<({String que, CartelEquipo equipo})> peticiones = [];

  final List<DateTime?> consultadas = [];
  final List<({String tipo, DateTime? fecha})> regeneradas = [];
  final List<String> descargadas = [];
  final List<OpcionesCartel> carteles = [];

  /// Se lanza al pedir las imágenes del fin de semana (se vacía al usarse si [falloUnico]).
  Object? falloObtener;
  Object? falloRegenerar;
  Object? falloPartido;

  /// Fallos de los próximos PNG del cartel, uno por llamada.
  final List<Object> fallosCartel = [];
  Completer<void>? espera;
  Completer<void>? esperaCartel;
  int partidosPedidos = 0;

  ServicioImagenesFalso({
    ImagenesRedesModel? actual,
    PartidoPrimerEquipoModel? partido,
  }) : actual = actual ?? modeloDePrueba(const []),
       partido = partido ?? partidoDePrueba();

  @override
  Future<ImagenesRedesModel> obtener({DateTime? fecha}) async {
    consultadas.add(fecha);

    if (falloObtener != null) throw falloObtener!;

    return actual;
  }

  @override
  Future<Uint8List> descargarPng(ImagenRedesModel imagen) async {
    descargadas.add('${imagen.id}:${imagen.version}');

    return pngDePrueba;
  }

  @override
  Future<ImagenesRedesModel> regenerar({
    required String tipo,
    DateTime? fecha,
  }) async {
    regeneradas.add((tipo: tipo, fecha: fecha));

    await espera?.future;

    if (falloRegenerar != null) throw falloRegenerar!;

    actual = trasRegenerar ?? actual;

    return actual;
  }

  @override
  Future<PartidoPrimerEquipoModel> obtenerPartido(CartelEquipo equipo) async {
    peticiones.add((que: 'partido', equipo: equipo));

    if (equipo == CartelEquipo.filial) {
      partidosPedidosFilial++;

      if (falloPartidoFilial != null) throw falloPartidoFilial!;

      return partidoFilial;
    }

    partidosPedidos++;

    if (falloPartido != null) throw falloPartido!;

    return partido;
  }

  @override
  Future<Uint8List> generarCartel(
    CartelEquipo equipo,
    OpcionesCartel opciones,
  ) async {
    peticiones.add((que: 'png', equipo: equipo));

    if (equipo == CartelEquipo.filial) {
      cartelesFilial.add(opciones);

      if (fallosCartelFilial.isNotEmpty) throw fallosCartelFilial.removeAt(0);

      return pngDePrueba;
    }

    carteles.add(opciones);

    await esperaCartel?.future;

    if (fallosCartel.isNotEmpty) throw fallosCartel.removeAt(0);

    return pngDePrueba;
  }
}

Widget appDePrueba(Widget hijo, {String idioma = 'es', ThemeData? tema}) {
  return MaterialApp(
    locale: Locale(idioma),
    theme: tema,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: hijo,
  );
}
