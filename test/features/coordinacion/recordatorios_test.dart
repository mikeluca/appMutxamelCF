import 'dart:convert';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/coordinacion/models/coordinacion_model.dart';
import 'package:app_mutxamel_cf/features/coordinacion/pages/fin_de_semana_page.dart';
import 'package:app_mutxamel_cf/features/coordinacion/services/coordinacion_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';

import '../../support/http_test_helpers.dart';

class _Servicio extends CoordinacionService {
  final List<({int partido, String tipo})> enviados = [];

  /// Si no es null, el siguiente recordatorio falla con esto.
  Object? fallo;
  int destinatarios = 2;

  @override
  Future<FinDeSemanaModel> obtenerFinDeSemana({DateTime? fecha}) async {
    return FinDeSemanaModel(
      desde: DateTime(2026, 10, 23),
      hasta: DateTime(2026, 10, 25),
      sinConvocatoria: [_partido(2, 'Cadete A', 'Pego C.F.')],
      resultadosPendientes: [_partido(1, 'Primer Equipo', 'Elx')],
      descansan: const [],
      sinPartido: const [],
      ultimaImportacionFfcv: null,
    );
  }

  @override
  Future<RecordatorioEnviadoModel> recordar({
    required int partidoId,
    required String tipo,
  }) async {
    if (fallo != null) {
      final error = fallo!;
      fallo = null;
      throw error;
    }

    enviados.add((partido: partidoId, tipo: tipo));

    return RecordatorioEnviadoModel(
      destinatarios: destinatarios,
      fecha: DateTime(2026, 10, 23, 10),
    );
  }
}

PartidoPanelModel _partido(int id, String equipo, String rival) =>
    PartidoPanelModel(
      equipoId: id,
      equipo: equipo,
      partidoId: id * 10,
      rival: rival,
      dia: DateTime(2026, 10, 24),
      hora: '11:00',
      local: true,
      diasDeRetraso: 3,
    );

Future<void> _pintar(WidgetTester tester, _Servicio servicio) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: FinDeSemanaPage(servicio: servicio),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  final recordarConvocatoria = find.byKey(
    const ValueKey('recordar-CONVOCATORIA:20'),
  );
  final recordarResultado = find.byKey(
    const ValueKey('recordar-RESULTADO:10'),
  );

  group('botón Recordar del panel', () {
    testWidgets('hay uno en cada partido sin convocatoria y en cada resultado '
        'pendiente', (tester) async {
      await _pintar(tester, _Servicio());

      expect(recordarConvocatoria, findsOneWidget);
      expect(recordarResultado, findsOneWidget);
      expect(find.text('Recordar'), findsNWidgets(2));
      expect(
        find.byIcon(Icons.notifications_active_outlined),
        findsNWidgets(2),
      );
    });

    testWidgets('recordar la convocatoria avisa con el recuento y el botón '
        'pasa a "Recordado"', (tester) async {
      final servicio = _Servicio();

      await _pintar(tester, servicio);

      await tester.tap(recordarConvocatoria);
      await tester.pumpAndSettle();

      expect(servicio.enviados.single, (partido: 20, tipo: 'CONVOCATORIA'));
      expect(find.text('Recordatorio enviado a 2 entrenadores'), findsOneWidget);
      expect(find.text('Recordado'), findsOneWidget);

      // El otro sigue disponible, y el recordado ya no se puede pulsar.
      expect(find.text('Recordar'), findsOneWidget);

      final boton = tester.widget<TextButton>(recordarConvocatoria);
      expect(boton.onPressed, isNull);

      expect(servicio.enviados, hasLength(1));
    });

    testWidgets('recordar el resultado manda el tipo RESULTADO y, con un '
        'solo entrenador, el texto en singular', (tester) async {
      final servicio = _Servicio()..destinatarios = 1;

      await _pintar(tester, servicio);

      await tester.tap(recordarResultado);
      await tester.pumpAndSettle();

      expect(servicio.enviados.single, (partido: 10, tipo: 'RESULTADO'));
      expect(find.text('Recordatorio enviado a 1 entrenador'), findsOneWidget);
    });

    testWidgets('pulsar Recordar no abre el formulario del partido', (
      tester,
    ) async {
      await _pintar(tester, _Servicio());

      await tester.tap(recordarConvocatoria);
      await tester.pumpAndSettle();

      expect(find.byType(FinDeSemanaPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('409: el equipo no tiene entrenadores con cuenta, y se puede '
        'reintentar', (tester) async {
      final servicio = _Servicio()
        ..fallo = const ApiException(
          'El equipo no tiene entrenadores con cuenta en la app',
          statusCode: 409,
          datos: {'codigo': 'SIN_ENTRENADORES', 'mensaje': 'x'},
        );

      await _pintar(tester, servicio);

      await tester.tap(recordarConvocatoria);
      await tester.pumpAndSettle();

      expect(
        find.text('El equipo no tiene entrenadores con cuenta en la app.'),
        findsOneWidget,
      );
      expect(find.text('Recordado'), findsNothing);

      await tester.tap(recordarConvocatoria);
      await tester.pumpAndSettle();

      expect(servicio.enviados, hasLength(1));
    });

    testWidgets('409 UNICO_ENTRENADOR: eres el único entrenador del equipo', (
      tester,
    ) async {
      final servicio = _Servicio()
        ..fallo = const ApiException(
          'Eres el único entrenador con cuenta de este equipo',
          statusCode: 409,
          datos: {
            'codigo': 'UNICO_ENTRENADOR',
            'mensaje': 'Eres el único entrenador con cuenta de este equipo',
          },
        );

      await _pintar(tester, servicio);

      await tester.tap(recordarConvocatoria);
      await tester.pumpAndSettle();

      expect(
        find.text('Eres el único entrenador con cuenta de este equipo'),
        findsOneWidget,
      );
      expect(
        find.text('El equipo no tiene entrenadores con cuenta en la app.'),
        findsNothing,
      );
      expect(find.text('Recordado'), findsNothing);
    });

    testWidgets('429: ya se recordó hace poco, con la hora del último', (
      tester,
    ) async {
      final servicio = _Servicio()
        ..fallo = const ApiException(
          'Ya se recordó esto hace poco',
          statusCode: 429,
          datos: {
            'codigo': 'RECORDATORIO_REPETIDO',
            'ultimo': '2026-10-23T09:05:00',
          },
        );

      await _pintar(tester, servicio);

      await tester.tap(recordarResultado);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Ya se envió este recordatorio a las 09:05. '
          'Podrás repetirlo pasadas 2 horas.',
        ),
        findsOneWidget,
      );
      // Ya estaba recordado.
      expect(find.text('Recordado'), findsOneWidget);
    });

    testWidgets('403 y otros fallos tienen su texto', (tester) async {
      final servicio = _Servicio()
        ..fallo = const ApiException('Prohibido', statusCode: 403);

      await _pintar(tester, servicio);

      await tester.tap(recordarConvocatoria);
      await tester.pumpAndSettle();

      expect(find.text('No tienes permiso'), findsOneWidget);

      servicio.fallo = Exception('boom');

      await tester.tap(recordarConvocatoria);
      await tester.pumpAndSettle();

      expect(
        find.text('No se ha podido enviar el recordatorio.'),
        findsOneWidget,
      );
    });
  });

  group('CoordinacionService.recordar', () {
    setUp(() async {
      FlutterSecureStoragePlatform.instance =
          TestFlutterSecureStoragePlatform(<String, String>{});
      await AuthSession.guardarSesion(
        LoginResponse(
          token: 'tok',
          usuarioId: 1,
          email: 'a@a.com',
          roles: const ['COORDINADOR'],
        ),
      );
    });

    test('hace POST /app/coordinacion/recordatorios y lee la respuesta', () async {
      final enviado = await conMockHttp((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/app/coordinacion/recordatorios'));
        expect(request.headers['Authorization'], 'Bearer tok');
        expect(jsonDecode(request.body), {
          'partidoId': 30,
          'tipo': 'CONVOCATORIA',
        });

        return http.Response(
          jsonEncode({'destinatarios': 3, 'fecha': '2026-10-23T10:00:00'}),
          200,
        );
      }, () => CoordinacionService().recordar(partidoId: 30, tipo: 'CONVOCATORIA'));

      expect(enviado.destinatarios, 3);
      expect(enviado.fecha, DateTime(2026, 10, 23, 10));
    });

    test('el 429 conserva el cuerpo con el código y la hora del último', () async {
      await expectLater(
        conMockHttp(
          (request) async => http.Response(
            jsonEncode({
              'codigo': 'RECORDATORIO_REPETIDO',
              'mensaje': 'Ya se recordó esto hace poco',
              'ultimo': '2026-10-23T09:05:00',
            }),
            429,
          ),
          () => CoordinacionService().recordar(
            partidoId: 30,
            tipo: 'RESULTADO',
          ),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having(
                (e) => (e.datos as Map)['ultimo'],
                'ultimo',
                '2026-10-23T09:05:00',
              ),
        ),
      );
    });
  });
}
