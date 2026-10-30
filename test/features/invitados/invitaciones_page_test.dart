import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/invitados/models/invitacion_model.dart';
import 'package:app_mutxamel_cf/features/invitados/pages/invitaciones_page.dart';
import 'package:app_mutxamel_cf/features/invitados/services/invitados_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeInvitados extends InvitadosService {
  List<InvitacionPendienteModel> pendientes;
  final List<String> llamadas = [];
  Object? fallo;
  EstadoInvitacion estadoAlAprobar = EstadoInvitacion.autorizado;
  int cargas = 0;

  _FakeInvitados(this.pendientes);

  @override
  Future<List<InvitacionPendienteModel>> obtenerPendientes() async {
    cargas++;

    if (fallo != null && cargas == 1 && fallo is! ApiException) {
      throw fallo!;
    }

    return List.of(pendientes);
  }

  void _quitar(int id) =>
      pendientes = pendientes.where((p) => p.id != id).toList();

  @override
  Future<InvitacionResultadoModel> aprobar(int invitacionId) async {
    llamadas.add('aprobar:$invitacionId');

    if (fallo != null) throw fallo!;

    _quitar(invitacionId);

    return InvitacionResultadoModel(id: invitacionId, estado: estadoAlAprobar);
  }

  @override
  Future<InvitacionResultadoModel> rechazar(
    int invitacionId, {
    String? motivo,
  }) async {
    llamadas.add('rechazar:$invitacionId:${motivo?.trim() ?? ''}');

    if (fallo != null) throw fallo!;

    _quitar(invitacionId);

    return InvitacionResultadoModel(
      id: invitacionId,
      estado: EstadoInvitacion.rechazado,
    );
  }

  @override
  Future<InvitacionResultadoModel> liberar(int invitacionId) async {
    llamadas.add('liberar:$invitacionId');

    if (fallo != null) throw fallo!;

    _quitar(invitacionId);

    return InvitacionResultadoModel(
      id: invitacionId,
      estado: EstadoInvitacion.autorizado,
    );
  }
}

InvitacionPendienteModel _pendiente(
  int id, {
  EstadoInvitacion estado = EstadoInvitacion.pendienteCoordinacion,
  String jugador = 'Ana Pérez',
  List<PartidoSolapadoModel> solapamiento = const [],
  bool convocadoEnOrigen = false,
  OtraInvitacionModel? otra,
  bool plazoVencido = false,
}) => InvitacionPendienteModel(
  id: id,
  estado: estado,
  jugador: jugador,
  equipoOrigen: 'Cadete B',
  equipoDestino: 'Cadete A',
  fechaPartido: DateTime(2026, 11, 14),
  horaPartido: '11:00',
  rival: 'Pego',
  convoca: 'Cuerpo técnico de Cadete A',
  solapamiento: solapamiento,
  jugadorConvocadoEnOrigen: convocadoEnOrigen,
  otraInvitacion: otra,
  plazoVencido: plazoVencido,
);

Future<void> _pintar(WidgetTester tester, InvitadosService servicio) async {
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
      home: InvitacionesPage(service: servicio),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  testWidgets('sin invitaciones lo dice', (tester) async {
    await _pintar(tester, _FakeInvitados([]));

    expect(find.byKey(const ValueKey('invitaciones-vacio')), findsOneWidget);
    expect(find.text('No hay invitaciones pendientes'), findsOneWidget);
  });

  testWidgets(
    'cada invitación muestra jugador, equipos, partido, quién convoca y estado',
    (tester) async {
      await _pintar(
        tester,
        _FakeInvitados([
          _pendiente(
            31,
            solapamiento: const [
              PartidoSolapadoModel(
                partidoId: 11,
                hora: '09:30',
                rival: 'Denia',
              ),
            ],
          ),
        ]),
      );

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('Cadete B → Cadete A'), findsOneWidget);
      expect(find.textContaining('11:00 · contra Pego'), findsOneWidget);
      expect(find.text('Convoca: Cuerpo técnico de Cadete A'), findsOneWidget);
      expect(find.text('Pendiente de coordinación'), findsOneWidget);
      expect(find.text('Su equipo juega ese día: 09:30 Denia'), findsOneWidget);
      expect(find.byKey(const ValueKey('otra-invitacion-31')), findsNothing);
      expect(find.byKey(const ValueKey('plazo-vencido-31')), findsNothing);
    },
  );

  testWidgets('sin partido de su equipo ese día lo dice', (tester) async {
    await _pintar(tester, _FakeInvitados([_pendiente(31)]));

    expect(find.text('Su equipo no juega ese día'), findsOneWidget);
  });

  testWidgets(
    'marca el solapamiento con convocatoria, la otra invitación y las 12 horas',
    (tester) async {
      await _pintar(
        tester,
        _FakeInvitados([
          _pendiente(
            31,
            estado: EstadoInvitacion.pendienteEntrenador,
            solapamiento: const [
              PartidoSolapadoModel(
                partidoId: 11,
                hora: '09:30',
                rival: 'Denia',
              ),
            ],
            convocadoEnOrigen: true,
            otra: const OtraInvitacionModel(
              convocatoriaJugadorId: 40,
              equipoDestino: 'Cadete C',
              rival: 'Javea',
              estado: EstadoInvitacion.pendienteCoordinacion,
            ),
            plazoVencido: true,
          ),
        ]),
      );

      expect(
        find.text('Pendiente de que su entrenador lo autorice'),
        findsOneWidget,
      );
      expect(find.text('Su entrenador lo tiene convocado'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('otra-invitacion-31')),
          matching: find.text('Tiene otra invitación ese día: Cadete C'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('plazo-vencido-31')),
          matching: find.text('Más de 12 h esperando a su entrenador'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'las pendientes de coordinación se aprueban o rechazan; las de su entrenador, se liberan',
    (tester) async {
      await _pintar(
        tester,
        _FakeInvitados([
          _pendiente(31),
          _pendiente(
            32,
            estado: EstadoInvitacion.pendienteEntrenador,
            jugador: 'Biel Gil',
          ),
        ]),
      );

      expect(
        find.byKey(const ValueKey('invitacion-aprobar-31')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('invitacion-rechazar-31')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('invitacion-liberar-31')), findsNothing);

      expect(
        find.byKey(const ValueKey('invitacion-liberar-32')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('invitacion-aprobar-32')), findsNothing);
      expect(
        find.byKey(const ValueKey('invitacion-rechazar-32')),
        findsNothing,
      );
    },
  );

  testWidgets('aprobar llama al servidor, avisa y recarga la lista', (
    tester,
  ) async {
    final servicio = _FakeInvitados([
      _pendiente(31),
      _pendiente(32, jugador: 'Biel Gil'),
    ]);

    await _pintar(tester, servicio);

    await tester.tap(find.byKey(const ValueKey('invitacion-aprobar-31')));
    await tester.pumpAndSettle();

    expect(servicio.llamadas, ['aprobar:31']);
    expect(find.text('Invitación aprobada'), findsOneWidget);
    expect(find.byKey(const ValueKey('invitacion-31')), findsNothing);
    expect(find.byKey(const ValueKey('invitacion-32')), findsOneWidget);
    expect(servicio.cargas, 2);
  });

  testWidgets('si al aprobar queda pendiente de su entrenador, lo dice', (
    tester,
  ) async {
    final servicio = _FakeInvitados([_pendiente(31)])
      ..estadoAlAprobar = EstadoInvitacion.pendienteEntrenador;

    await _pintar(tester, servicio);

    await tester.tap(find.byKey(const ValueKey('invitacion-aprobar-31')));
    await tester.pumpAndSettle();

    expect(
      find.text('Aprobada: queda pendiente de su entrenador'),
      findsOneWidget,
    );
  });

  testWidgets('rechazar pide un motivo opcional y lo envía', (tester) async {
    final servicio = _FakeInvitados([_pendiente(31)]);

    await _pintar(tester, servicio);

    await tester.tap(find.byKey(const ValueKey('invitacion-rechazar-31')));
    await tester.pumpAndSettle();

    expect(find.text('Rechazar invitación'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('invitacion-motivo')),
      'Ese día juega con su equipo',
    );
    await tester.tap(
      find.byKey(const ValueKey('invitacion-rechazar-confirmar')),
    );
    await tester.pumpAndSettle();

    expect(servicio.llamadas, ['rechazar:31:Ese día juega con su equipo']);
    expect(find.text('Invitación rechazada'), findsOneWidget);
    expect(find.byKey(const ValueKey('invitacion-31')), findsNothing);
  });

  testWidgets('rechazar sin motivo es válido', (tester) async {
    final servicio = _FakeInvitados([_pendiente(31)]);

    await _pintar(tester, servicio);

    await tester.tap(find.byKey(const ValueKey('invitacion-rechazar-31')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('invitacion-rechazar-confirmar')),
    );
    await tester.pumpAndSettle();

    expect(servicio.llamadas, ['rechazar:31:']);
  });

  testWidgets('cancelar el diálogo de rechazar no llama al servidor', (
    tester,
  ) async {
    final servicio = _FakeInvitados([_pendiente(31)]);

    await _pintar(tester, servicio);

    await tester.tap(find.byKey(const ValueKey('invitacion-rechazar-31')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(servicio.llamadas, isEmpty);
    expect(find.byKey(const ValueKey('invitacion-31')), findsOneWidget);
  });

  testWidgets(
    'liberar pide confirmación y avisa de que se quita de la convocatoria de origen',
    (tester) async {
      final servicio = _FakeInvitados([
        _pendiente(
          32,
          estado: EstadoInvitacion.pendienteEntrenador,
          jugador: 'Biel Gil',
        ),
      ]);

      await _pintar(tester, servicio);

      await tester.tap(find.byKey(const ValueKey('invitacion-liberar-32')));
      await tester.pumpAndSettle();

      expect(find.text('¿Liberar a Biel Gil?'), findsOneWidget);
      expect(
        find.text(
          'Se quitará de la convocatoria de Cadete B ese día y se avisará a su entrenador.',
        ),
        findsOneWidget,
      );
      expect(servicio.llamadas, isEmpty);

      await tester.tap(
        find.byKey(const ValueKey('invitacion-liberar-confirmar')),
      );
      await tester.pumpAndSettle();

      expect(servicio.llamadas, ['liberar:32']);
      expect(find.text('Jugador liberado'), findsOneWidget);
      expect(find.byKey(const ValueKey('invitacion-32')), findsNothing);
    },
  );

  testWidgets(
    'un 409 al aprobar se explica con el jugador y el equipo, no con el texto',
    (tester) async {
      final servicio = _FakeInvitados([_pendiente(31)])
        ..fallo = const ApiException(
          'texto que no se usa',
          statusCode: 409,
          datos: {
            'codigo': 'JUGADOR_YA_INVITADO_ESE_DIA',
            'jugadorId': 1,
            'equipoDestino': 'Cadete C',
          },
        );

      await _pintar(tester, servicio);

      await tester.tap(find.byKey(const ValueKey('invitacion-aprobar-31')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Ana Pérez ya está autorizado como invitado con Cadete C ese día. '
          'Elige a otro jugador.',
        ),
        findsOneWidget,
      );
      expect(find.text('texto que no se usa'), findsNothing);
      // La invitación sigue en la lista.
      expect(find.byKey(const ValueKey('invitacion-31')), findsOneWidget);
    },
  );

  testWidgets('un 400 al aprobar muestra el motivo del servidor', (
    tester,
  ) async {
    final servicio = _FakeInvitados([_pendiente(31)])
      ..fallo = const ApiException(
        'La invitación ya no está pendiente',
        statusCode: 400,
      );

    await _pintar(tester, servicio);

    await tester.tap(find.byKey(const ValueKey('invitacion-aprobar-31')));
    await tester.pumpAndSettle();

    expect(find.text('La invitación ya no está pendiente'), findsOneWidget);
  });

  testWidgets('un 403 al cargar es "No tienes permiso" y se puede reintentar', (
    tester,
  ) async {
    final servicio = _FallaAlCargar();

    await _pintar(tester, servicio);

    expect(find.text('No tienes permiso'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}

class _FallaAlCargar extends InvitadosService {
  @override
  Future<List<InvitacionPendienteModel>> obtenerPendientes() async {
    throw const ApiException('prohibido', statusCode: 403);
  }
}
