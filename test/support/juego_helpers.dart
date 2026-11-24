import 'dart:math' as math;

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/juego/logica/logica_juego.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/services/juego_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Un Random con los números que se le dan (da la vuelta al llegar al final): para que el azar del portero o de lo
/// que cae sea el que cada test quiere.
class AleatorioFalso implements math.Random {
  AleatorioFalso({this.reales = const [0.99], this.enteros = const [0]});

  final List<double> reales;
  final List<int> enteros;
  int _r = 0;
  int _e = 0;

  @override
  double nextDouble() => reales[_r++ % reales.length];

  @override
  int nextInt(int max) => enteros[_e++ % enteros.length] % max;

  @override
  bool nextBool() => nextDouble() >= 0.5;
}

/// Un JuegoService sin red: las respuestas y los fallos los pone cada test, y apunta lo que se le pide.
class JuegoServiceFalso extends JuegoService {
  JuegoServiceFalso({
    this.perfilInicial = const PerfilJuego(),
    this.filas = const {},
  }) : perfilActual = perfilInicial;

  final PerfilJuego perfilInicial;

  /// El ranking que devuelve, por juego y periodo.
  final Map<(Juego, PeriodoRanking), List<FilaRanking>> filas;

  PerfilJuego perfilActual;

  /// Si no es null, `perfil()` falla con él.
  Object? errorDePerfil;

  /// Si no es null, `guardarPuntuacion()` falla con él (y se pone a null tras fallar una vez si [errorUnaVez]).
  Object? errorAlGuardar;
  bool errorUnaVez = false;

  /// Si no es null, `actualizarPerfil()` falla con él.
  Object? errorAlActualizar;

  ResultadoPuntuacion resultado = const ResultadoPuntuacion();

  /// Los escudos que devuelve `escudos()` (Parejas) y, si no es null, el error con el que falla.
  List<EscudoJuego> escudosRespuesta = [];
  Object? errorDeEscudos;
  final List<int> escudosPedidos = [];

  final List<(Juego, int, int)> guardadas = [];
  final List<(String?, Equipacion?)> actualizaciones = [];
  final List<(Juego, PeriodoRanking)> rankingsPedidos = [];
  int perfilesPedidos = 0;

  @override
  Future<PerfilJuego> perfil() async {
    perfilesPedidos++;

    if (errorDePerfil != null) throw errorDePerfil!;

    return perfilActual;
  }

  @override
  Future<PerfilJuego> actualizarPerfil({
    String? alias,
    Equipacion? equipacion,
  }) async {
    actualizaciones.add((alias, equipacion));

    if (errorAlActualizar != null) throw errorAlActualizar!;

    perfilActual = PerfilJuego(
      alias: alias ?? perfilActual.alias,
      equipacion: equipacion ?? perfilActual.equipacion,
      oculto: perfilActual.oculto,
      juegos: perfilActual.juegos,
    );

    return perfilActual;
  }

  @override
  Future<ResultadoPuntuacion> guardarPuntuacion({
    required Juego juego,
    required int puntos,
    required int duracionMs,
  }) async {
    if (errorAlGuardar != null) {
      final error = errorAlGuardar!;

      if (errorUnaVez) errorAlGuardar = null;

      throw error;
    }

    guardadas.add((juego, puntos, duracionMs));

    return resultado;
  }

  @override
  Future<List<EscudoJuego>> escudos({int cantidad = 8}) async {
    escudosPedidos.add(cantidad);

    if (errorDeEscudos != null) throw errorDeEscudos!;

    return escudosRespuesta;
  }

  // ---- Moderación ----

  List<PerfilJuegoAdmin> perfilesAdmin = [];
  List<PuntuacionAdmin> puntuacionesAdmin = [];

  /// Si no es null, toda llamada de moderación falla con él.
  Object? errorAdmin;

  /// Si no es null, `cambiarAlias()` falla con él (solo ese).
  Object? errorAlCambiarAlias;

  final List<String?> busquedas = [];
  final List<String> accionesAdmin = [];

  @override
  Future<List<PerfilJuegoAdmin>> listarPerfiles({String? alias}) async {
    busquedas.add(alias);

    if (errorAdmin != null) throw errorAdmin!;

    return perfilesAdmin;
  }

  @override
  Future<List<PuntuacionAdmin>> puntuacionesDe(int usuarioId) async {
    if (errorAdmin != null) throw errorAdmin!;

    return puntuacionesAdmin;
  }

  @override
  Future<void> cambiarAlias(int usuarioId, String alias) async {
    if (errorAdmin != null) throw errorAdmin!;
    if (errorAlCambiarAlias != null) throw errorAlCambiarAlias!;

    accionesAdmin.add("alias $usuarioId $alias");
  }

  @override
  Future<void> ocultar(int usuarioId, {required bool oculto}) async {
    if (errorAdmin != null) throw errorAdmin!;

    accionesAdmin.add("oculto $usuarioId $oculto");
  }

  @override
  Future<void> borrarPuntuacion(int puntuacionId) async {
    if (errorAdmin != null) throw errorAdmin!;

    accionesAdmin.add("borrar $puntuacionId");
  }

  @override
  Future<void> borrarTodas(int usuarioId) async {
    if (errorAdmin != null) throw errorAdmin!;

    accionesAdmin.add("borrarTodas $usuarioId");
  }

  @override
  Future<List<FilaRanking>> ranking(Juego juego, PeriodoRanking periodo) async {
    rankingsPedidos.add((juego, periodo));

    return filas[(juego, periodo)] ?? const [];
  }
}

/// Un MaterialApp en castellano con las localizaciones de la app.
Widget appDePrueba(Widget home, {Locale locale = const Locale('es')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

/// Las imágenes (Image.asset) con esa ruta.
Finder imagenDe(String ruta) => find.byWidgetPredicate(
  (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == ruta,
  description: 'imagen $ruta',
);

ApiException errorHttp(int codigo, String mensaje, {String? codigoJuego}) =>
    ApiException(
      mensaje,
      statusCode: codigo,
      datos: {'error': mensaje, 'codigo': ?codigoJuego},
    );

/// Una pantalla de móvil alta (360 × 1500), para que quepan las listas sin desplazarlas: con 1 de ratio, un punto
/// de pantalla es una unidad de juego.
void pantallaDeMovil(WidgetTester tester, {double alto = 1500}) {
  tester.view.physicalSize = Size(360, alto);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Unos escudos de prueba para Parejas: `Club 1`, `Club 2`...
List<EscudoJuego> escudosDePrueba([int cuantos = 8]) => [
  for (var i = 1; i <= cuantos; i++)
    EscudoJuego(id: i, nombre: 'Club $i', escudoUrl: '/api/public/escudos-rivales/$i?v=1'),
];

/// Una lógica de juego mínima para probar la página de la partida sin depender de ningún juego: a los 0,5 s de partida
/// suma 1 punto (aviso de punto) y a los 2 s termina (aviso de fallo).
class LogicaDePrueba extends LogicaJuego {
  LogicaDePrueba({required super.alto, this.conVidas = false});

  final bool conVidas;

  int _puntos = 0;
  bool _terminado = false;

  @override
  int get puntos => _puntos;

  @override
  int? get vidas => conVidas ? 3 : null;

  @override
  bool get terminado => _terminado;

  @override
  void avanzar(Duration dt) {
    if (_puntos == 0 && segundos >= 0.5) {
      _puntos = 1;
      alEvento?.call(EventoJuego.punto);
    }

    if (segundos >= 2) {
      _terminado = true;
      alEvento?.call(EventoJuego.fallo);
    }
  }
}
