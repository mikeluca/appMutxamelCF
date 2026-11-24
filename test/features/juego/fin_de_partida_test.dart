import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/juego/envio_puntuacion.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/widgets/fin_de_partida.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/juego_helpers.dart';

EnvioPuntuacion _envio(
  JuegoServiceFalso servicio, {
  int puntos = 5,
  Duration duracion = const Duration(seconds: 40),
  bool conSesion = true,
  String? alias = 'Ana',
  Juego juego = Juego.penaltis,
}) => EnvioPuntuacion(
  servicio: servicio,
  juego: juego,
  puntos: puntos,
  duracion: duracion,
  conSesion: conSesion,
  alias: alias,
);

void main() {
  group('EnvioPuntuacion', () {
    test('con sesión y alias envía juego, puntos y duración, y guarda la respuesta', () async {
      final servicio = JuegoServiceFalso()
        ..resultado = const ResultadoPuntuacion(
          recordSemana: true,
          posicionSemana: 3,
        );
      final envio = _envio(servicio, juego: Juego.toques, puntos: 12);

      await envio.iniciar();

      expect(servicio.guardadas, [(Juego.toques, 12, 40000)]);
      expect(envio.estado, EstadoEnvio.enviado);
      expect(envio.resultado!.recordSemana, isTrue);
      expect(envio.resultado!.posicionSemana, 3);
    });

    test('pasa por "enviando" mientras espera al servidor', () async {
      final envio = _envio(JuegoServiceFalso());
      final estados = <EstadoEnvio>[];

      envio.addListener(() => estados.add(envio.estado));

      await envio.iniciar();

      expect(estados, [EstadoEnvio.enviando, EstadoEnvio.enviado]);
    });

    test('una partida de menos de 3 s se envía como de 3 s (el mínimo que acepta el backend)', () async {
      final servicio = JuegoServiceFalso();

      await _envio(servicio, duracion: const Duration(milliseconds: 1200)).iniciar();

      expect(servicio.guardadas.single.$3, 3000);
    });

    test('sin sesión no se envía nada: se avisa de que hay que iniciar sesión', () async {
      final servicio = JuegoServiceFalso();
      final envio = _envio(servicio, conSesion: false, alias: null);

      await envio.iniciar();

      expect(envio.estado, EstadoEnvio.sinSesion);
      expect(servicio.guardadas, isEmpty);
    });

    test('con sesión pero sin alias se pide el alias y no se envía', () async {
      final servicio = JuegoServiceFalso();
      final envio = _envio(servicio, alias: null);

      await envio.iniciar();

      expect(envio.estado, EstadoEnvio.sinAlias);
      expect(servicio.guardadas, isEmpty);

      // Un alias en blanco es como no tenerlo.
      final enBlanco = _envio(servicio, alias: '  ');

      await enBlanco.iniciar();

      expect(enBlanco.estado, EstadoEnvio.sinAlias);
    });

    test('al elegir el alias se envía la puntuación', () async {
      final servicio = JuegoServiceFalso();
      final envio = _envio(servicio, alias: null);

      await envio.iniciar();
      await envio.aliasElegido('Mutxigol10');

      expect(envio.estado, EstadoEnvio.enviado);
      expect(servicio.guardadas, hasLength(1));
    });

    test('si el servidor dice que falta el alias (409), se pide el alias', () async {
      final servicio = JuegoServiceFalso()
        ..errorAlGuardar = errorHttp(
          409,
          'Elige un alias',
          codigoJuego: 'ALIAS_REQUERIDO',
        );
      final envio = _envio(servicio);

      await envio.iniciar();

      expect(envio.estado, EstadoEnvio.sinAlias);
    });

    test('0 puntos no se envían', () async {
      final servicio = JuegoServiceFalso();
      final envio = _envio(servicio, puntos: 0);

      await envio.iniciar();

      expect(envio.estado, EstadoEnvio.noAplica);
      expect(servicio.guardadas, isEmpty);
    });

    test('un fallo de red deja reintentar, sin cola', () async {
      final servicio = JuegoServiceFalso()
        ..errorAlGuardar = const ApiException('No hay conexión a internet.')
        ..errorUnaVez = true;
      final envio = _envio(servicio);

      await envio.iniciar();

      expect(envio.estado, EstadoEnvio.error);
      expect(envio.mensajeError, isNull);
      expect(servicio.guardadas, isEmpty);

      await envio.reintentar();

      expect(envio.estado, EstadoEnvio.enviado);
      expect(servicio.guardadas, hasLength(1));
    });

    test('un límite de envíos (429) enseña el motivo del servidor', () async {
      final servicio = JuegoServiceFalso()
        ..errorAlGuardar = errorHttp(429, 'Vas muy rápido');
      final envio = _envio(servicio);

      await envio.iniciar();

      expect(envio.estado, EstadoEnvio.error);
      expect(envio.mensajeError, 'Vas muy rápido');
    });
  });

  group('FinDePartida', () {
    Future<EnvioPuntuacion> pintar(
      WidgetTester tester,
      JuegoServiceFalso servicio, {
      int puntos = 5,
      int recordAnterior = 0,
      bool conSesion = true,
      String? alias = 'Ana',
      VoidCallback? onElegirAlias,
      VoidCallback? onOtraVez,
      VoidCallback? onRanking,
    }) async {
      final envio = _envio(
        servicio,
        puntos: puntos,
        conSesion: conSesion,
        alias: alias,
      );

      await tester.pumpWidget(
        appDePrueba(
          Scaffold(
            body: SingleChildScrollView(
              child: FinDePartida(
                equipacion: Equipacion.rosa,
                puntos: puntos,
                recordAnterior: recordAnterior,
                envio: envio,
                onOtraVez: onOtraVez ?? () {},
                onRanking: onRanking ?? () {},
                onElegirAlias: onElegirAlias ?? () {},
              ),
            ),
          ),
        ),
      );

      await envio.iniciar();
      await tester.pump();

      return envio;
    }

    testWidgets('récord personal: Mutxigol celebra y se dicen el récord y la posición', (tester) async {
      final servicio = JuegoServiceFalso()
        ..resultado = const ResultadoPuntuacion(
          recordSemana: true,
          recordHistorico: true,
          posicionSemana: 2,
          posicionHistorico: 7,
        );

      await pintar(tester, servicio, puntos: 9, recordAnterior: 4);

      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.rosa, PoseMutxigol.celebrando)),
        findsOneWidget,
      );
      expect(find.text('¡Nuevo récord!'), findsOneWidget);
      expect(find.text('9 puntos'), findsOneWidget);
      expect(find.byKey(const ValueKey('record-semana')), findsOneWidget);
      expect(find.byKey(const ValueKey('record-historico')), findsOneWidget);
      expect(find.text('Esta semana: puesto 2'), findsOneWidget);
      expect(find.text('Histórico: puesto 7'), findsOneWidget);
    });

    testWidgets('sin récord: Mutxigol está triste y se enseña el récord anterior y la posición', (tester) async {
      final servicio = JuegoServiceFalso()
        ..resultado = const ResultadoPuntuacion(
          posicionSemana: 12,
          posicionHistorico: 30,
        );

      await pintar(tester, servicio, puntos: 3, recordAnterior: 8);

      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.rosa, PoseMutxigol.triste)),
        findsOneWidget,
      );
      expect(find.text('¡Nuevo récord!'), findsNothing);
      expect(find.text('Fin de la partida'), findsOneWidget);
      expect(find.text('Tu récord: 8'), findsOneWidget);
      expect(find.byKey(const ValueKey('record-semana')), findsNothing);
      expect(find.text('Esta semana: puesto 12'), findsOneWidget);
    });

    testWidgets('sin sesión: celebra si supera lo conocido de esta sesión y pide iniciar sesión', (tester) async {
      final servicio = JuegoServiceFalso();

      await pintar(
        tester,
        servicio,
        puntos: 6,
        recordAnterior: 2,
        conSesion: false,
        alias: null,
      );

      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.rosa, PoseMutxigol.celebrando)),
        findsOneWidget,
      );
      expect(
        find.text('Inicia sesión en el Área Club para guardar tus puntuaciones'),
        findsOneWidget,
      );
      expect(servicio.guardadas, isEmpty);
    });

    testWidgets('con sesión pero sin alias: pide el alias y el botón lo abre', (tester) async {
      var abierto = 0;
      final servicio = JuegoServiceFalso();

      await pintar(
        tester,
        servicio,
        alias: null,
        onElegirAlias: () => abierto++,
      );

      expect(
        find.text('Elige un alias para guardar esta puntuación'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('elegir-alias')));

      expect(abierto, 1);
      expect(servicio.guardadas, isEmpty);
    });

    testWidgets('con sesión y alias la puntuación se envía sola', (tester) async {
      final servicio = JuegoServiceFalso();

      await pintar(tester, servicio, puntos: 7);

      expect(servicio.guardadas, [(Juego.penaltis, 7, 40000)]);
    });

    testWidgets('error de red: mensaje discreto y botón para reintentar', (tester) async {
      final servicio = JuegoServiceFalso()
        ..errorAlGuardar = const ApiException('No hay conexión a internet.')
        ..errorUnaVez = true;

      await pintar(tester, servicio);

      expect(find.text('No se ha podido guardar tu puntuación.'), findsOneWidget);
      expect(find.byKey(const ValueKey('reintentar-envio')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('reintentar-envio')));
      await tester.pump();

      expect(find.byKey(const ValueKey('reintentar-envio')), findsNothing);
      expect(servicio.guardadas, hasLength(1));
    });

    testWidgets('los botones Otra vez y Ranking avisan', (tester) async {
      var otraVez = 0;
      var ranking = 0;

      await pintar(
        tester,
        JuegoServiceFalso(),
        onOtraVez: () => otraVez++,
        onRanking: () => ranking++,
      );

      await tester.tap(find.byKey(const ValueKey('otra-vez')));
      await tester.tap(find.byKey(const ValueKey('ver-ranking')));

      expect(otraVez, 1);
      expect(ranking, 1);
    });
  });
}
