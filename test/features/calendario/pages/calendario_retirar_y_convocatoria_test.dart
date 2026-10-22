import 'package:app_mutxamel_cf/core/utils/como_llegar.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/calendario/model/calendario_model.dart';
import 'package:app_mutxamel_cf/features/calendario/model/sesion_entrenamiento_model.dart';
import 'package:app_mutxamel_cf/features/calendario/model/temporada_model.dart';
import 'package:app_mutxamel_cf/features/calendario/pages/calendario_page.dart';
import 'package:app_mutxamel_cf/features/calendario/services/calendario_service.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_familia_page.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/teams/models/team_model.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeCalendarioService extends CalendarioService {
  CalendarioModel calendario;
  final List<({int sesion, int jugador})> retiradas = [];
  bool fallaAlRetirar = false;

  _FakeCalendarioService(this.calendario);

  @override
  Future<TemporadaModel?> obtenerTemporadaActiva() async => null;

  @override
  Future<CalendarioModel> obtenerCalendario({
    required int equipoId,
    required DateTime desde,
    required DateTime hasta,
    int? jugadorId,
  }) async => calendario;

  @override
  Future<void> retirarJustificacion({
    required int sesionId,
    required int jugadorId,
  }) async {
    if (fallaAlRetirar) {
      throw Exception('fuera de plazo');
    }

    retiradas.add((sesion: sesionId, jugador: jugadorId));
  }
}

class _FakeTeamService extends TeamService {
  @override
  Future<List<TeamModel>> obtenerEquipos() async => [];
}

final _hoy = () {
  final ahora = DateTime.now();
  return DateTime(ahora.year, ahora.month, ahora.day);
}();

PerfilApp _perfil() => PerfilApp(
  usuarioId: 1,
  email: 'a@b.c',
  roles: const ['FAMILIAR'],
  jugadores: [
    PerfilJugador(
      id: 100,
      nombre: 'Pablo',
      apellidos: 'Garcia',
      equipo: 'Cadete A',
      equipoId: 5,
    ),
  ],
  equipos: const [],
);

CalendarioModel _calendario({
  bool justificada = true,
  bool puedeRetirar = true,
  String? campo = 'Campo Municipal de Pego',
  bool? convocado = true,
}) => CalendarioModel(
  sesiones: [
    SesionEntrenamientoModel(
      id: 7,
      equipoId: 5,
      equipo: 'Cadete A',
      fecha: _hoy,
      hora: '23:59',
      lugar: 'Pista 2',
      estado: 'PROGRAMADA',
      justificado: justificada,
      motivoJustificacion: justificada ? 'Examen' : null,
      puedeRetirarJustificacion: puedeRetirar,
    ),
  ],
  partidos: [
    MatchModel(
      id: 30,
      equipoId: 5,
      categoria: 'Cadete',
      equipo: 'Cadete A',
      rival: 'Pego C.F.',
      dia: _hoy,
      hora: '11:00',
      campo: campo,
      convocado: convocado,
    ),
  ],
);

Future<void> _pintar(
  WidgetTester tester,
  _FakeCalendarioService servicio,
) async {
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
      home: CalendarioPage(
        calendarioService: servicio,
        teamService: _FakeTeamService(),
        cargarPerfil: () async => _perfil(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  final retirar = find.byKey(const ValueKey('retirar-justificacion-sesion'));

  group('retirar la justificación de un entrenamiento', () {
    testWidgets('con plazo hay botón Retirar; confirma y llama al servicio', (
      tester,
    ) async {
      final servicio = _FakeCalendarioService(_calendario());

      await _pintar(tester, servicio);

      expect(retirar, findsOneWidget);

      await tester.tap(retirar);
      await tester.pumpAndSettle();

      expect(find.text('¿Retirar la justificación?'), findsOneWidget);
      expect(servicio.retiradas, isEmpty);

      await tester.tap(find.widgetWithText(FilledButton, 'Retirar'));
      await tester.pumpAndSettle();

      expect(servicio.retiradas.single, (sesion: 7, jugador: 100));
      expect(find.text('Justificación retirada.'), findsOneWidget);
    });

    testWidgets('cancelar el diálogo no retira nada', (tester) async {
      final servicio = _FakeCalendarioService(_calendario());

      await _pintar(tester, servicio);

      await tester.tap(retirar);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.retiradas, isEmpty);
    });

    testWidgets('fuera de plazo (puedeRetirarJustificacion = false) no hay '
        'botón', (tester) async {
      await _pintar(
        tester,
        _FakeCalendarioService(_calendario(puedeRetirar: false)),
      );

      expect(retirar, findsNothing);
    });

    testWidgets('sin justificar tampoco', (tester) async {
      await _pintar(
        tester,
        _FakeCalendarioService(_calendario(justificada: false)),
      );

      expect(retirar, findsNothing);
    });

    testWidgets('si el servidor lo rechaza se avisa sin detalles técnicos', (
      tester,
    ) async {
      final servicio = _FakeCalendarioService(_calendario())
        ..fallaAlRetirar = true;

      await _pintar(tester, servicio);

      await tester.tap(retirar);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Retirar'));
      await tester.pumpAndSettle();

      expect(find.text('No se ha podido retirar la justificación.'),
          findsOneWidget);
      expect(find.textContaining('fuera de plazo'), findsNothing);
    });
  });

  group('partido en el calendario', () {
    tearDown(() {
      ComoLlegar.esIos = () => false;
    });

    testWidgets('el campo lleva el botón Cómo llegar', (tester) async {
      Uri? abierta;
      ComoLlegar.esIos = () => false;
      ComoLlegar.abrirUrl = (url) async {
        abierta = url;
        return true;
      };

      await _pintar(tester, _FakeCalendarioService(_calendario()));

      expect(find.text('Campo Municipal de Pego'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.directions));
      await tester.pumpAndSettle();

      expect(
        abierta.toString(),
        'https://www.google.com/maps/search/?api=1&query='
        'Campo%20Municipal%20de%20Pego%2C%20Alicante',
      );
    });

    testWidgets('sin campo no hay botón Cómo llegar', (tester) async {
      await _pintar(tester, _FakeCalendarioService(_calendario(campo: '')));

      expect(find.byIcon(Icons.directions), findsNothing);
    });

    testWidgets('al pulsar un partido con convocatoria se abre la pantalla '
        'Convocatoria', (tester) async {
      await _pintar(tester, _FakeCalendarioService(_calendario()));

      await tester.tap(find.text('Convocatoria'));
      // La pantalla pide la convocatoria a la red y no termina de animar.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ConvocatoriaFamiliaPage), findsOneWidget);
    });

    testWidgets('un partido sin convocatoria no abre nada', (tester) async {
      await _pintar(
        tester,
        _FakeCalendarioService(_calendario(convocado: null)),
      );

      expect(find.byKey(const ValueKey('ver-convocatoria')), findsNothing);

      await tester.tap(find.text('Pego C.F.'));
      await tester.pumpAndSettle();

      expect(find.byType(ConvocatoriaFamiliaPage), findsNothing);
    });
  });
}
