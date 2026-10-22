import 'dart:convert';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/core/utils/como_llegar.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_partido_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_familia_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_partido_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';

import '../../support/http_test_helpers.dart';

class _FakeServicio extends ConvocatoriaPartidoService {
  final Map<int, ConvocatoriaPartidoModel> porJugador;
  final Object? error;
  final List<({int partido, int jugador})> consultas = [];

  _FakeServicio({this.porJugador = const {}, this.error});

  @override
  Future<ConvocatoriaPartidoModel> obtener({
    required int partidoId,
    required int jugadorId,
  }) async {
    consultas.add((partido: partidoId, jugador: jugadorId));

    if (error != null) {
      throw error!;
    }

    final convocatoria = porJugador[jugadorId];

    if (convocatoria == null) {
      throw const ApiException('otro equipo', statusCode: 403);
    }

    return convocatoria;
  }
}

ConvocatoriaPartidoModel _convocatoria({
  bool convocado = true,
  bool local = true,
  String? campo = 'Campo Municipal',
  String? lugarCitacion = 'Vestuarios',
}) => ConvocatoriaPartidoModel(
  convocatoriaId: 20,
  rival: 'Pego C.F.',
  fecha: DateTime(2026, 10, 24),
  hora: '11:00',
  campo: campo,
  local: local,
  horaCitacion: '09:30',
  lugarCitacion: lugarCitacion,
  convocado: convocado,
  convocados: const [
    ConvocadoPartidoModel(nombre: 'Ana', apellidos: 'Ruiz', dorsal: 1),
    ConvocadoPartidoModel(nombre: 'Pablo', apellidos: 'Garcia', dorsal: 9),
    ConvocadoPartidoModel(nombre: 'Luis', apellidos: 'Lopez'),
  ],
);

Future<void> _pintar(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Widget _pagina(_FakeServicio servicio) => ConvocatoriaFamiliaPage(
  partidoId: 30,
  jugadorId: 100,
  jugadorNombre: 'Pablo',
  jugadorApellidos: 'Garcia',
  service: servicio,
);

PerfilApp _perfil(List<int> jugadores) => PerfilApp(
  usuarioId: 1,
  email: 'a@b.c',
  roles: const ['FAMILIAR'],
  jugadores: [
    for (final id in jugadores)
      PerfilJugador(
        id: id,
        nombre: 'Jugador$id',
        apellidos: 'Apellido',
        equipo: 'Cadete A',
        equipoId: 5,
      ),
  ],
  equipos: const [],
);

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  group('modelo y servicio', () {
    test('el modelo lee el JSON del backend', () {
      final modelo = ConvocatoriaPartidoModel.fromJson({
        'convocatoriaId': 20,
        'rival': 'Pego C.F.',
        'fecha': '2026-10-24',
        'hora': '11:00',
        'campo': 'Municipal',
        'local': false,
        'horaCitacion': '09:30',
        'lugarCitacion': 'Vestuarios',
        'convocado': true,
        'convocados': [
          {'nombre': 'Ana', 'apellidos': 'Ruiz', 'dorsal': 1},
          {'nombre': 'Luis', 'apellidos': 'Lopez', 'dorsal': null},
        ],
      });

      expect(modelo.rival, 'Pego C.F.');
      expect(modelo.fecha, DateTime(2026, 10, 24));
      expect(modelo.local, isFalse);
      expect(modelo.convocado, isTrue);
      expect(modelo.convocados.map((c) => c.dorsal), [1, null]);
      expect(modelo.convocados.first.nombreCompleto, 'Ana Ruiz');
      expect(modelo.convocados.first.esJugador(' ana ', 'RUIZ'), isTrue);
      expect(modelo.convocados.first.esJugador('Ana', 'Lopez'), isFalse);
    });

    test('el servicio pide GET /app/partidos/{id}/convocatoria?jugadorId=', () async {
      FlutterSecureStoragePlatform.instance =
          TestFlutterSecureStoragePlatform(<String, String>{});
      await AuthSession.guardarSesion(
        LoginResponse(
          token: 'tok',
          usuarioId: 1,
          email: 'a@a.com',
          roles: const [],
        ),
      );

      final modelo = await conMockHttp((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/app/partidos/30/convocatoria'));
        expect(request.url.queryParameters['jugadorId'], '100');
        expect(request.headers['Authorization'], 'Bearer tok');

        return http.Response(
          jsonEncode({
            'convocatoriaId': 20,
            'rival': 'Pego',
            'convocado': false,
            'convocados': [],
          }),
          200,
        );
      }, () => ConvocatoriaPartidoService().obtener(partidoId: 30, jugadorId: 100));

      expect(modelo.rival, 'Pego');
      expect(modelo.convocado, isFalse);
    });
  });

  group('pantalla Convocatoria', () {
    testWidgets('cabecera, citación, estado y lista con el jugador resaltado', (
      tester,
    ) async {
      await _pintar(
        tester,
        _pagina(_FakeServicio(porJugador: {100: _convocatoria()})),
      );

      // Cabecera: rival, fecha y hora, y local.
      expect(find.text('Pego C.F.'), findsOneWidget);
      expect(find.textContaining('11:00'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('Campo Municipal'), findsOneWidget);

      // Citación: hora y lugar.
      expect(find.text('Citación'), findsOneWidget);
      expect(find.text('Hora de citación: 09:30'), findsOneWidget);
      expect(find.text('Lugar: Vestuarios'), findsOneWidget);

      // Estado del jugador.
      expect(find.text('Pablo: Convocado'), findsOneWidget);

      // Lista de convocados (3), con el jugador del usuario resaltado.
      expect(find.text('3 convocados'), findsOneWidget);
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(find.text('Luis Lopez'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.byKey(const ValueKey('convocado-propio')), findsOneWidget);
      expect(find.text('Tu jugador'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('convocado-propio')),
          matching: find.text('Pablo Garcia'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('visitante y no convocado', (tester) async {
      await _pintar(
        tester,
        _pagina(
          _FakeServicio(
            porJugador: {100: _convocatoria(convocado: false, local: false)},
          ),
        ),
      );

      expect(find.text('Visitante'), findsOneWidget);
      expect(find.text('Pablo: No convocado'), findsOneWidget);
    });

    testWidgets('"Cómo llegar" en el campo y en la citación', (tester) async {
      final abiertas = <Uri>[];
      ComoLlegar.esIos = () => false;
      ComoLlegar.abrirUrl = (url) async {
        abiertas.add(url);
        return true;
      };

      await _pintar(
        tester,
        _pagina(_FakeServicio(porJugador: {100: _convocatoria()})),
      );

      expect(find.byIcon(Icons.directions), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.directions).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.directions).last);
      await tester.pump();

      expect(abiertas.map((u) => u.queryParameters['query']), [
        'Campo Municipal, Alicante',
        'Vestuarios, Alicante',
      ]);
    });

    testWidgets('sin campo ni lugar de citación no hay "Cómo llegar"', (
      tester,
    ) async {
      await _pintar(
        tester,
        _pagina(
          _FakeServicio(
            porJugador: {100: _convocatoria(campo: '', lugarCitacion: null)},
          ),
        ),
      );

      expect(find.byIcon(Icons.directions), findsNothing);
    });

    testWidgets('sin convocatoria (404) dice que ya no está disponible', (
      tester,
    ) async {
      await _pintar(
        tester,
        _pagina(
          _FakeServicio(
            error: const ApiException('no existe', statusCode: 404),
          ),
        ),
      );

      expect(find.text('Esta convocatoria ya no está disponible'),
          findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('un fallo de red permite reintentar', (tester) async {
      await _pintar(
        tester,
        _pagina(_FakeServicio(error: const ApiException('sin red'))),
      );

      expect(
        find.text('No se ha podido cargar la convocatoria.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('el aviso de convocatoria abre la pantalla', () {
    setUp(() async {
      await AuthManager.establecerUsuario(
        AuthUser(usuarioId: 1, email: 'a@b.c', roles: const ['FAMILIAR']),
      );
    });

    tearDown(() {
      AppNavigator.fabricaConvocatoriaPartidoService = null;
      AppNavigator.cargarPerfilParaAviso = null;
      AppNavigator.constructorConvocatoriaFamilia = null;
      AppNavigator.constructorCalendario = null;
    });

    test('con partidoId en el aviso el destino es el detalle', () {
      expect(
        destinoDeAvisoConvocatoria(
          tipo: 'CONVOCATORIA',
          datos: {'partidoId': '30', 'fechaPartido': '2026-10-24'},
        ),
        AbrirDetalleConvocatoria(30, DateTime(2026, 10, 24)),
      );
    });

    test('la convocatoria anulada solo lleva al calendario', () {
      expect(
        destinoDeAvisoConvocatoria(
          tipo: 'CONVOCATORIA_ANULADA',
          datos: {'fechaPartido': '2026-10-24', 'partidoId': '30'},
        ),
        AbrirCalendario(DateTime(2026, 10, 24)),
      );
      expect(esAvisoDeConvocatoria(tipo: 'CONVOCATORIA_ANULADA'), isTrue);
    });

    test('el payload de la notificación local ida y vuelta', () {
      for (final destino in <DestinoConvocatoria>[
        AbrirDetalleConvocatoria(30, DateTime(2026, 10, 24)),
        const AbrirDetalleConvocatoria(30),
      ]) {
        expect(destinoDePayload(payloadDeDestino(destino)), destino);
      }

      expect(destinoDePayload('CONVOCATORIA_PARTIDO:abc:2026-10-24'), isNull);
    });

    testWidgets('con un solo jugador convocado se abre su pantalla', (
      tester,
    ) async {
      await _pintar(tester, const Scaffold(body: Text('home')));

      final servicio = _FakeServicio(
        porJugador: {
          100: _convocatoria(),
          101: _convocatoria(convocado: false),
        },
      );

      AppNavigator.fabricaConvocatoriaPartidoService = () => servicio;
      AppNavigator.cargarPerfilParaAviso = () async => _perfil([100, 101]);
      AppNavigator.constructorConvocatoriaFamilia = (partidoId, jugador) =>
          Text('pantalla ${jugador.id} partido $partidoId');

      // El Future de abrir la pantalla no termina hasta cerrarla: no se espera.
      AppNavigator.abrirDestinoConvocatoria(
        AbrirDetalleConvocatoria(30, DateTime(2026, 10, 24)),
      );
      await tester.pumpAndSettle();

      expect(find.text('pantalla 100 partido 30'), findsOneWidget);
      expect(servicio.consultas.map((c) => c.jugador), [100, 101]);
    });

    testWidgets('con varios jugadores convocados se abre el calendario en ese '
        'día', (tester) async {
      await _pintar(tester, const Scaffold(body: Text('home')));

      AppNavigator.fabricaConvocatoriaPartidoService = () => _FakeServicio(
        porJugador: {100: _convocatoria(), 101: _convocatoria()},
      );
      AppNavigator.cargarPerfilParaAviso = () async => _perfil([100, 101]);
      AppNavigator.constructorConvocatoriaFamilia = (partidoId, jugador) =>
          const Text('pantalla');

      DateTime? diaCalendario;
      AppNavigator.constructorCalendario = (dia) {
        diaCalendario = dia;
        return const Text('calendario');
      };

      // El Future de abrir la pantalla no termina hasta cerrarla: no se espera.
      AppNavigator.abrirDestinoConvocatoria(
        AbrirDetalleConvocatoria(30, DateTime(2026, 10, 24)),
      );
      await tester.pumpAndSettle();

      expect(find.text('calendario'), findsOneWidget);
      expect(find.text('pantalla'), findsNothing);
      expect(diaCalendario, DateTime(2026, 10, 24));
    });

    testWidgets('si el jugador no está convocado o falla el perfil, '
        'calendario', (tester) async {
      await _pintar(tester, const Scaffold(body: Text('home')));

      AppNavigator.fabricaConvocatoriaPartidoService = () => _FakeServicio(
        porJugador: {100: _convocatoria(convocado: false)},
      );
      AppNavigator.cargarPerfilParaAviso = () async => _perfil([100]);
      AppNavigator.constructorCalendario = (dia) => const Text('calendario');

      // El Future de abrir la pantalla no termina hasta cerrarla: no se espera.
      AppNavigator.abrirDestinoConvocatoria(
        const AbrirDetalleConvocatoria(30),
      );
      await tester.pumpAndSettle();

      expect(find.text('calendario'), findsOneWidget);
    });
  });
}
