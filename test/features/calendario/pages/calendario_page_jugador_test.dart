import 'dart:async';

import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/calendario/model/calendario_model.dart';
import 'package:app_mutxamel_cf/features/calendario/model/justificacion_falta_model.dart';
import 'package:app_mutxamel_cf/features/calendario/model/sesion_entrenamiento_model.dart';
import 'package:app_mutxamel_cf/features/calendario/model/temporada_model.dart';
import 'package:app_mutxamel_cf/features/calendario/pages/calendario_page.dart';
import 'package:app_mutxamel_cf/features/calendario/services/calendario_service.dart';
import 'package:app_mutxamel_cf/features/matches/models/justificacion_partido_model.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/services/justificacion_partido_service.dart';
import 'package:app_mutxamel_cf/features/teams/models/team_model.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeCalendarioService extends CalendarioService {
  final CalendarioModel calendario;

  /// Calendario distinto por jugador (cada hijo tiene su propio estado).
  final Map<int, CalendarioModel> porJugador;
  final List<({int sesion, int jugador, String? motivo})> justificaciones = [];
  final List<int?> jugadoresConsultados = [];

  /// Si no es null, la siguiente consulta del calendario espera a que se complete.
  Completer<void>? bloquearSiguiente;

  /// Respuestas programadas para las consultas posteriores a la primera, en
  /// orden; cada una puede esperar a que se complete su [espera].
  final List<({Completer<void>? espera, CalendarioModel calendario})> cola = [];

  /// Si es true, las consultas posteriores a la primera fallan.
  bool falloAlCargar = false;

  _FakeCalendarioService(this.calendario, {this.porJugador = const {}});

  @override
  Future<TemporadaModel?> obtenerTemporadaActiva() async => null;

  @override
  Future<CalendarioModel> obtenerCalendario({
    required int equipoId,
    required DateTime desde,
    required DateTime hasta,
    int? jugadorId,
  }) async {
    jugadoresConsultados.add(jugadorId);

    final espera = bloquearSiguiente;

    if (cola.isNotEmpty && jugadoresConsultados.length > 1) {
      final siguiente = cola.removeAt(0);

      await siguiente.espera?.future;

      return siguiente.calendario;
    }

    if (falloAlCargar && jugadoresConsultados.length > 1) {
      throw Exception('sin red');
    }

    if (espera != null && jugadoresConsultados.length > 1) {
      bloquearSiguiente = null;
      await espera.future;
    }

    return porJugador[jugadorId] ?? calendario;
  }

  @override
  Future<JustificacionFaltaModel> justificarFalta({
    required int sesionId,
    required int jugadorId,
    String? motivo,
  }) async {
    justificaciones.add((sesion: sesionId, jugador: jugadorId, motivo: motivo));

    return JustificacionFaltaModel(
      id: 1,
      sesionId: sesionId,
      jugadorId: jugadorId,
      jugador: 'Pablo Garcia',
      usuarioAppId: 1,
      motivo: motivo,
    );
  }
}

/// Justificaciones de ausencia a partidos: anota las llamadas; con [error]
/// lanza una excepción en justificar/retirar.
class _FakeJustificacionPartidoService extends JustificacionPartidoService {
  final List<String> llamadas = [];
  String? error;

  @override
  Future<JustificacionPartidoModel> justificar({
    required int partidoId,
    required int jugadorId,
    required String motivo,
  }) async {
    if (error != null) {
      throw Exception(error);
    }

    llamadas.add('justificar:$partidoId:$jugadorId:$motivo');

    return JustificacionPartidoModel(
      partidoId: partidoId,
      jugadorId: jugadorId,
      jugador: 'Pablo Garcia',
      motivo: motivo,
    );
  }

  @override
  Future<void> retirar({required int partidoId, required int jugadorId}) async {
    if (error != null) {
      throw Exception(error);
    }

    llamadas.add('retirar:$partidoId:$jugadorId');
  }
}

class _FakeTeamService extends TeamService {
  @override
  Future<List<TeamModel>> obtenerEquipos() async => [];
}

/// El calendario muestra los eventos del día seleccionado, que al abrirlo es hoy.
DateTime _enDias(int dias) {
  final hoy = DateTime.now();
  return DateTime(hoy.year, hoy.month, hoy.day).add(Duration(days: dias));
}

PerfilApp _perfil(List<String> roles) => PerfilApp(
  usuarioId: 1,
  email: 'a@b.c',
  roles: roles,
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
  bool ausenciaJustificada = false,
  bool puedeJustificar = true,
  bool cancelado = false,
  String? motivoAusencia,
  DateTime? limite,
  DateTime? diaPartido,
}) => CalendarioModel(
  sesiones: [
    SesionEntrenamientoModel(
      id: 7,
      equipoId: 5,
      equipo: 'Cadete A',
      fecha: _enDias(0),
      hora: '18:00',
      lugar: 'Campo Municipal',
      estado: 'PROGRAMADA',
    ),
  ],
  partidos: [
    MatchModel(
      id: 30,
      equipoId: 5,
      categoria: 'Cadete',
      equipo: 'Cadete A',
      rival: 'Pego C.F.',
      dia: diaPartido ?? _enDias(0),
      hora: '11:00',
      convocado: true,
      cancelado: cancelado,
      ausenciaJustificada: ausenciaJustificada,
      motivoAusencia: motivoAusencia,
      puedeJustificar: puedeJustificar,
      limiteJustificacion: limite ?? DateTime(2026, 10, 24, 9, 30),
    ),
  ],
);

Future<void> _pintar(
  WidgetTester tester,
  _FakeCalendarioService servicio,
  List<String> roles, {
  JustificacionPartidoService? justificaciones,
  DateTime Function()? ahora,
  DateTime? diaInicial,
  PerfilApp? perfil,
}) async {
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
        justificacionPartidoService: justificaciones,
        diaInicial: diaInicial,
        calendarioService: servicio,
        teamService: _FakeTeamService(),
        cargarPerfil: () async => perfil ?? _perfil(roles),
        ahora: ahora,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  testWidgets(
    'un usuario solo JUGADOR ve su entrenamiento y puede justificar la falta',
    (tester) async {
      final servicio = _FakeCalendarioService(_calendario());

      await _pintar(tester, servicio, ['JUGADOR']);

      // El calendario se pide con SU jugador (igual que un familiar).
      expect(servicio.jugadoresConsultados, [100]);
      expect(find.text('Cadete A — Pablo Garcia'), findsWidgets);
      expect(find.text('Campo Municipal'), findsOneWidget);

      // Pulsar el entrenamiento abre el diálogo para justificar la falta.
      await tester.tap(find.text('Campo Municipal'));
      await tester.pumpAndSettle();

      expect(find.text('Justificar falta a entrenamiento'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Examen');
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(servicio.justificaciones.single.sesion, 7);
      expect(servicio.justificaciones.single.jugador, 100);
      expect(servicio.justificaciones.single.motivo, 'Examen');
    },
  );

  testWidgets('un FAMILIAR ve exactamente lo mismo que un JUGADOR', (
    tester,
  ) async {
    final servicio = _FakeCalendarioService(_calendario());

    await _pintar(tester, servicio, ['FAMILIAR']);

    expect(servicio.jugadoresConsultados, [100]);
    expect(find.text('Cadete A — Pablo Garcia'), findsWidgets);

    await tester.tap(find.text('Campo Municipal'));
    await tester.pumpAndSettle();

    expect(find.text('Justificar falta a entrenamiento'), findsOneWidget);
  });

  // ---- ausencia justificada a partidos ------------------------------------------------

  Future<_FakeJustificacionPartidoService> pintarPartido(
    WidgetTester tester, {
    bool justificada = false,
    bool puedeJustificar = true,
    bool cancelado = false,
    String? motivo,
    DateTime? limite,
    List<String> roles = const ['JUGADOR'],
    DateTime? dia,
    DateTime? diaInicial,
  }) async {
    final justificaciones = _FakeJustificacionPartidoService();

    await _pintar(
      tester,
      _FakeCalendarioService(
        _calendario(
          ausenciaJustificada: justificada,
          puedeJustificar: puedeJustificar,
          cancelado: cancelado,
          motivoAusencia: motivo,
          limite: limite,
          diaPartido: dia,
        ),
      ),
      roles,
      justificaciones: justificaciones,
      diaInicial: diaInicial,
    );

    return justificaciones;
  }

  testWidgets('un partido convocado sigue mostrando que está convocado', (
    tester,
  ) async {
    await pintarPartido(tester);

    expect(find.text('Convocado'), findsOneWidget);
    // Ya no hay respuesta "Va / No puede".
    expect(find.text('Va'), findsNothing);
    expect(find.text('No puede'), findsNothing);
    expect(find.text('Sin responder'), findsNothing);
  });

  testWidgets('con plazo se puede justificar la ausencia con un motivo', (
    tester,
  ) async {
    final servicio = await pintarPartido(tester);

    expect(find.text('Justificar ausencia'), findsOneWidget);
    expect(find.text('Ausencia justificada'), findsNothing);

    await tester.tap(find.text('Justificar ausencia'));
    await tester.pumpAndSettle();

    expect(find.text('Justificar ausencia al partido'), findsOneWidget);

    // El motivo es obligatorio: sin él no se envía nada.
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Indica el motivo (mínimo 3 caracteres)'), findsOneWidget);
    expect(servicio.llamadas, isEmpty);

    await tester.enterText(find.byType(TextField), 'Examen de mates');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    expect(servicio.llamadas, ['justificar:30:100:Examen de mates']);
    expect(find.text('Ausencia justificada'), findsOneWidget);
  });

  testWidgets('si el servidor rechaza la ausencia el diálogo lo dice', (
    tester,
  ) async {
    final servicio = await pintarPartido(tester);
    servicio.error = 'El plazo para justificar la ausencia terminó';

    await tester.tap(find.text('Justificar ausencia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Examen');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    // Mensaje genérico: ni la excepción ni el detalle del servidor en pantalla.
    expect(
      find.text('No se ha podido guardar. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('El plazo para justificar'), findsNothing);
    expect(find.text('Justificar ausencia al partido'), findsOneWidget);
  });

  testWidgets('si falla retirar, un aviso genérico y sin la excepción', (
    tester,
  ) async {
    final servicio = await pintarPartido(
      tester,
      justificada: true,
      motivo: 'Examen',
    );
    servicio.error = 'ORA-00942 tabla inexistente';

    await tester.tap(find.text('Retirar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Retirar'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se ha podido guardar. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.textContaining('ORA-00942'), findsNothing);
  });

  testWidgets('ya justificada: etiqueta, motivo y editar o retirar', (
    tester,
  ) async {
    final servicio = await pintarPartido(
      tester,
      justificada: true,
      motivo: 'Examen de mates',
    );

    expect(find.text('Ausencia justificada'), findsOneWidget);
    expect(find.text('Motivo: Examen de mates'), findsOneWidget);
    expect(find.text('Editar motivo'), findsOneWidget);
    expect(find.text('Retirar'), findsOneWidget);
    expect(find.text('Justificar ausencia'), findsNothing);

    // Editar: el diálogo ya trae el motivo.
    await tester.tap(find.text('Editar motivo'));
    await tester.pumpAndSettle();

    expect(find.text('Editar motivo de la ausencia'), findsOneWidget);
    expect(find.text('Examen de mates'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Otro motivo');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    expect(servicio.llamadas, ['justificar:30:100:Otro motivo']);
  });

  testWidgets('retirar pide confirmación y solo entonces retira', (
    tester,
  ) async {
    final servicio = await pintarPartido(
      tester,
      justificada: true,
      motivo: 'Examen',
    );

    await tester.tap(find.text('Retirar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Retirar la ausencia?'), findsOneWidget);

    // Cancelar no retira nada.
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(servicio.llamadas, isEmpty);

    await tester.tap(find.text('Retirar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Retirar'));
    await tester.pumpAndSettle();

    expect(servicio.llamadas, ['retirar:30:100']);
    expect(find.text('Ausencia retirada'), findsOneWidget);
  });

  testWidgets('fuera de plazo: plazo cerrado y sin botones', (tester) async {
    await pintarPartido(
      tester,
      puedeJustificar: false,
      limite: DateTime(2026, 10, 24, 9, 30),
    );

    expect(find.text('Plazo cerrado (24/10 09:30)'), findsOneWidget);
    expect(find.text('Justificar ausencia'), findsNothing);
    expect(find.text('Editar motivo'), findsNothing);
    expect(find.text('Retirar'), findsNothing);
  });

  testWidgets('justificada y fuera de plazo: se ve pero ya no se cambia', (
    tester,
  ) async {
    await pintarPartido(
      tester,
      justificada: true,
      motivo: 'Examen',
      puedeJustificar: false,
      limite: DateTime(2026, 10, 24, 9, 30),
    );

    expect(find.text('Ausencia justificada'), findsOneWidget);
    expect(find.text('Motivo: Examen'), findsOneWidget);
    expect(find.text('Plazo cerrado (24/10 09:30)'), findsOneWidget);
    expect(find.text('Editar motivo'), findsNothing);
    expect(find.text('Retirar'), findsNothing);
  });

  testWidgets('un partido cancelado no ofrece justificar', (tester) async {
    await pintarPartido(tester, cancelado: true);

    expect(find.text('Justificar ausencia'), findsNothing);
    expect(find.textContaining('Plazo cerrado'), findsNothing);
  });

  testWidgets('un FAMILIAR justifica la ausencia por cada hijo', (
    tester,
  ) async {
    final servicio = await pintarPartido(tester, roles: const ['FAMILIAR']);

    await tester.tap(find.text('Justificar ausencia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Viaje familiar');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    expect(servicio.llamadas, ['justificar:30:100:Viaje familiar']);
  });

  // ---- día inicial (al tocar el aviso de una convocatoria) --------------------------------

  testWidgets('abre en el día del partido cuando se le indica', (tester) async {
    await pintarPartido(tester, dia: _enDias(3), diaInicial: _enDias(3));

    expect(find.text('Pego C.F.'), findsOneWidget);
  });

  testWidgets('sin día inicial abre en hoy', (tester) async {
    await pintarPartido(tester, dia: _enDias(3));

    expect(find.text('Pego C.F.'), findsNothing);
    // El entrenamiento de hoy sí está.
    expect(find.text('Campo Municipal'), findsOneWidget);
  });

  // ---- varios hijos en el mismo partido ------------------------------------------------------

  PerfilApp perfilConDosHijos() => PerfilApp(
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
      PerfilJugador(
        id: 101,
        nombre: 'Lucia',
        apellidos: 'Garcia',
        equipo: 'Cadete A',
        equipoId: 5,
      ),
    ],
    equipos: const [],
  );

  testWidgets('dos hijos en el mismo partido: una ficha por hijo, cada una con '
      'su estado y sus botones', (tester) async {
    final justificaciones = _FakeJustificacionPartidoService();

    await _pintar(
      tester,
      _FakeCalendarioService(
        _calendario(),
        porJugador: {
          // Pablo ya ha justificado; Lucia todavía no.
          100: _calendario(ausenciaJustificada: true, motivoAusencia: 'Examen'),
          101: _calendario(),
        },
      ),
      const ['FAMILIAR'],
      perfil: perfilConDosHijos(),
      justificaciones: justificaciones,
    );

    // El mismo partido sale dos veces, una por hijo, con su nombre.
    expect(find.text('Pego C.F.'), findsNWidgets(2));
    expect(find.text('Cadete A — Pablo Garcia'), findsNWidgets(2));
    expect(find.text('Cadete A — Lucia Garcia'), findsNWidgets(2));

    // Cada ficha con su propio estado: Pablo justificado, Lucia con el botón.
    expect(find.text('Ausencia justificada'), findsOneWidget);
    expect(find.text('Motivo: Examen'), findsOneWidget);
    expect(find.text('Editar motivo'), findsOneWidget);
    expect(find.text('Justificar ausencia'), findsOneWidget);

    // Y justificar por Lucia lo hace con SU jugador, no con el de Pablo.
    await tester.tap(find.text('Justificar ausencia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Viaje');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    expect(justificaciones.llamadas, ['justificar:30:101:Viaje']);
  });

  testWidgets('retirar por un hijo solo afecta a ese hijo', (tester) async {
    final justificaciones = _FakeJustificacionPartidoService();

    await _pintar(
      tester,
      _FakeCalendarioService(
        _calendario(),
        porJugador: {
          100: _calendario(ausenciaJustificada: true, motivoAusencia: 'Examen'),
          101: _calendario(ausenciaJustificada: true, motivoAusencia: 'Viaje'),
        },
      ),
      const ['FAMILIAR'],
      perfil: perfilConDosHijos(),
      justificaciones: justificaciones,
    );

    expect(find.text('Retirar'), findsNWidgets(2));

    // El orden de las fichas es el de los hijos del perfil: la primera es Pablo.
    await tester.tap(find.text('Retirar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Retirar'));
    await tester.pumpAndSettle();

    expect(justificaciones.llamadas, ['retirar:30:101']);
  });

  testWidgets('el calendario de un entrenador sigue sin repetir el partido', (
    tester,
  ) async {
    // Entrenador de un equipo y también con un jugador del mismo equipo: su
    // partido no debe salir dos veces (la ficha del jugador ya lo incluye).
    final perfil = PerfilApp(
      usuarioId: 1,
      email: 'a@b.c',
      roles: const ['ENTRENADOR', 'FAMILIAR'],
      jugadores: [
        PerfilJugador(
          id: 100,
          nombre: 'Pablo',
          apellidos: 'Garcia',
          equipo: 'Cadete A',
          equipoId: 5,
        ),
      ],
      equipos: [PerfilEquipo(id: 5, nombre: 'Cadete A')],
    );

    await _pintar(tester, _FakeCalendarioService(_calendario()), const [
      'ENTRENADOR',
      'FAMILIAR',
    ], perfil: perfil);

    expect(find.text('Pego C.F.'), findsOneWidget);
  });

  // ---- pull-to-refresh y recargas solapadas ------------------------------------------------------

  testWidgets('el pull-to-refresh recarga en segundo plano: conserva el día '
      'seleccionado y no cambia el calendario por el indicador de carga', (
    tester,
  ) async {
    final calendario = _FakeCalendarioService(
      _calendario(diaPartido: _enDias(3)),
    );

    await _pintar(
      tester,
      calendario,
      const ['JUGADOR'],
      justificaciones: _FakeJustificacionPartidoService(),
      diaInicial: _enDias(3),
    );

    expect(find.text('Pego C.F.'), findsOneWidget);

    // La recarga tarda: mientras tanto el calendario sigue en su día.
    final espera = Completer<void>();
    calendario.cola.add((
      espera: espera,
      calendario: _calendario(diaPartido: _enDias(3), motivoAusencia: 'Nuevo'),
    ));

    await _tirarParaRecargar(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(calendario.jugadoresConsultados, hasLength(2));
    expect(find.text('Pego C.F.'), findsOneWidget);
    // Solo el indicador del propio pull-to-refresh, no la pantalla de carga.
    expect(find.byType(CalendarioPage), findsOneWidget);
    expect(find.text('Campo Municipal'), findsNothing);

    espera.complete();
    await tester.pumpAndSettle();

    // Terminada la recarga, sigue en el mismo día.
    expect(find.text('Pego C.F.'), findsOneWidget);
    expect(find.text('Campo Municipal'), findsNothing);
  });

  testWidgets('con dos recargas seguidas se ignora el resultado de la más '
      'antigua aunque llegue después', (tester) async {
    final calendario = _FakeCalendarioService(
      _calendario(diaPartido: _enDias(3)),
    );

    await _pintar(
      tester,
      calendario,
      const ['JUGADOR'],
      justificaciones: _FakeJustificacionPartidoService(),
      diaInicial: _enDias(3),
    );

    expect(find.text('Justificar ausencia'), findsOneWidget);
    expect(find.text('Ausencia justificada'), findsNothing);

    // 1.ª recarga (pull-to-refresh): lenta y con datos ya antiguos.
    final lenta = Completer<void>();
    calendario.cola.add((
      espera: lenta,
      calendario: _calendario(diaPartido: _enDias(3)),
    ));

    // 2.ª recarga (tras justificar): rápida y con el dato nuevo.
    calendario.cola.add((
      espera: null,
      calendario: _calendario(
        diaPartido: _enDias(3),
        ausenciaJustificada: true,
        motivoAusencia: 'Examen',
      ),
    ));

    await _tirarParaRecargar(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Justificar ausencia'));
    await tester.pump(
      const Duration(milliseconds: 500),
    ); // el indicador de recarga sigue girando
    await tester.enterText(find.byType(TextField), 'Examen');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Ya se ve el resultado de la 2.ª recarga.
    expect(find.text('Motivo: Examen'), findsOneWidget);
    expect(calendario.jugadoresConsultados, hasLength(3));

    // La 1.ª llega tarde con datos antiguos: no pisa lo nuevo.
    lenta.complete();
    await tester.pumpAndSettle();

    expect(find.text('Motivo: Examen'), findsOneWidget);
    expect(find.text('Justificar ausencia'), findsNothing);
  });

  testWidgets('si la recarga más antigua falla después, tampoco estropea lo '
      'nuevo', (tester) async {
    final calendario = _FakeCalendarioService(
      _calendario(diaPartido: _enDias(3)),
    );

    await _pintar(
      tester,
      calendario,
      const ['JUGADOR'],
      justificaciones: _FakeJustificacionPartidoService(),
      diaInicial: _enDias(3),
    );

    final lenta = Completer<void>();
    calendario.cola.add((
      espera: lenta,
      calendario: _calendario(diaPartido: _enDias(3)),
    ));
    calendario.cola.add((
      espera: null,
      calendario: _calendario(
        diaPartido: _enDias(3),
        ausenciaJustificada: true,
        motivoAusencia: 'Examen',
      ),
    ));

    await _tirarParaRecargar(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Justificar ausencia'));
    await tester.pump(
      const Duration(milliseconds: 500),
    ); // el indicador de recarga sigue girando
    await tester.enterText(find.byType(TextField), 'Examen');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    lenta.completeError(Exception('sin red'));
    await tester.pumpAndSettle();

    expect(find.text('Motivo: Examen'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  // ---- recargar sin perder el día --------------------------------------------------------------

  testWidgets('tras justificar se recarga sin perder el día seleccionado ni '
      'cambiar el calendario por el indicador de carga', (tester) async {
    final calendario = _FakeCalendarioService(
      _calendario(diaPartido: _enDias(3)),
    );
    final justificaciones = _FakeJustificacionPartidoService();

    await _pintar(
      tester,
      calendario,
      const ['JUGADOR'],
      justificaciones: justificaciones,
      diaInicial: _enDias(3),
    );

    expect(find.text('Pego C.F.'), findsOneWidget);
    expect(calendario.jugadoresConsultados, hasLength(1));

    // La recarga tras justificar se queda esperando al servidor...
    calendario.bloquearSiguiente = Completer<void>();

    await tester.tap(find.text('Justificar ausencia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Examen');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(justificaciones.llamadas, ['justificar:30:100:Examen']);
    expect(calendario.jugadoresConsultados, hasLength(2));

    // ...y mientras tanto el calendario sigue ahí, en su día, sin spinner.
    expect(find.text('Pego C.F.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    calendario.bloquearSiguiente?.complete();
    await tester.pumpAndSettle();

    // Al terminar, sigue en el mismo día (no vuelve a hoy).
    expect(find.text('Pego C.F.'), findsOneWidget);
    expect(find.text('Campo Municipal'), findsNothing);
  });

  testWidgets('si la recarga falla tras justificar se queda lo que había', (
    tester,
  ) async {
    final calendario = _FakeCalendarioService(
      _calendario(diaPartido: _enDias(3)),
    );

    await _pintar(
      tester,
      calendario,
      const ['JUGADOR'],
      justificaciones: _FakeJustificacionPartidoService(),
      diaInicial: _enDias(3),
    );

    calendario.falloAlCargar = true;

    await tester.tap(find.text('Justificar ausencia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Examen');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pumpAndSettle();

    // Sin pantalla de error: el calendario y su día siguen.
    expect(find.text('Pego C.F.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });
}

/// Gesto de pull-to-refresh sobre la lista del calendario.
Future<void> _tirarParaRecargar(WidgetTester tester) async {
  // El indicador pide arrastrar un cuarto del alto de la lista: con una
  // pantalla de 3000 px haría falta un gesto enorme.
  tester.view.physicalSize = const Size(800, 800);
  await tester.pumpAndSettle();

  final lista = find
      .descendant(
        of: find.byType(RefreshIndicator),
        matching: find.byType(Scrollable),
      )
      .first;

  await tester.drag(lista, const Offset(0, 700));
}
