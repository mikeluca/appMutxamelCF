import 'dart:async';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/club/models/pendientes.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_service.dart';
import 'package:app_mutxamel_cf/features/entrenamientos/model/entrenamiento_model.dart';
import 'package:app_mutxamel_cf/features/entrenamientos/services/entrenamiento_service.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/pages/ficha_partido_page.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/services/ficha_partido_service.dart';
import 'package:app_mutxamel_cf/features/home/models/proximo_partido.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _ConvocatoriasFalsas extends ConvocatoriaService {
  @override
  Future<ConvocatoriaModel> obtenerPorId(int convocatoriaId) async =>
      ConvocatoriaModel(
        id: convocatoriaId,
        equipoId: 10,
        equipo: 'Alevín B',
        partidoId: 30,
        rival: 'Pego',
        campo: 'Campo',
        fechaPartido: '2026-11-28',
        horaPartido: '11:00',
        horaConvocatoria: '10:00',
        lugarConvocatoria: 'Vestuarios',
        usuarioEntrenadorId: 1,
        jugadores: const [],
      );
}

class _EntrenamientosFalsos extends EntrenamientoService {
  @override
  Future<EntrenamientoModel> obtenerPorId(int entrenamientoId) async =>
      EntrenamientoModel(
        id: entrenamientoId,
        equipoId: 10,
        equipo: 'Alevín B',
        fecha: '2026-11-23',
        usuarioEntrenadorId: 1,
        asistencias: const [],
        listaRevisada: false,
      );
}

class _FichaFalsa extends FichaPartidoService {
  @override
  Future<FichaPartido> obtenerFicha(int partidoId, {String? idioma}) =>
      Completer<FichaPartido>().future;
}

PerfilApp _perfil() => PerfilApp(
  usuarioId: 1,
  email: 'a@b.c',
  roles: const ['FAMILIAR'],
  jugadores: [
    PerfilJugador(
      id: 100,
      nombre: 'Pablo',
      apellidos: 'García',
      equipo: 'Alevín B',
      equipoId: 10,
    ),
  ],
  equipos: const [],
);

MatchModel _partido({String equipo = 'Alevín B', int id = 30}) => MatchModel(
  id: id,
  equipoId: 10,
  categoria: 'Alevín',
  equipo: equipo,
  rival: 'Pego',
  dia: DateTime(2026, 11, 28),
  hora: '11:00',
);

ProximoPartido _entrada({
  String tipo = 'FAMILIAR',
  MatchModel? partido,
  ConvocatoriaProximoPartido? convocatoria,
}) => ProximoPartido(
  tipo: tipo,
  jugadorId: tipo == 'ENTRENADOR' ? null : 100,
  nombreJugador: tipo == 'ENTRENADOR' ? null : 'Pablo García',
  equipoId: 10,
  nombreEquipo: 'Alevín B',
  partido: partido ?? _partido(),
  convocatoria: convocatoria,
);

Future<void> _pintar(WidgetTester tester) async {
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
      home: const Scaffold(body: Text('HOME')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late List<DateTime?> calendarios;
  late List<String> aperturas;

  setUp(() {
    calendarios = [];
    aperturas = [];

    AuthManager.olvidarUsuario();

    AppNavigator.cargarPerfilParaAviso = () async => _perfil();
    AppNavigator.fabricaConvocatoriaService = _ConvocatoriasFalsas.new;
    AppNavigator.fabricaEntrenamientoService = _EntrenamientosFalsos.new;
    AppNavigator.servicioFichaPartido = _FichaFalsa();
    AppNavigator.constructorCalendario = (dia) {
      calendarios.add(dia);
      return const Scaffold(body: Text('CALENDARIO'));
    };
    AppNavigator.constructorEdicion = (c) {
      aperturas.add('EDICION ${c.id}');
      return const Scaffold(body: Text('EDICION'));
    };
    AppNavigator.constructorFormularioConvocatoria = (partidoId, equipo) {
      aperturas.add(
        'FORM_CONVOCATORIA $partidoId ${equipo.id} ${equipo.nombre}',
      );
      return const Scaffold(body: Text('FORM_CONVOCATORIA'));
    };
    AppNavigator.constructorFormularioResultado = (p) {
      aperturas.add(
        'FORM_RESULTADO ${p.id} ${p.equipoId} ${p.equipo} ${p.rival}',
      );
      return const Scaffold(body: Text('FORM_RESULTADO'));
    };
    AppNavigator.constructorAsistencia = (e) {
      aperturas.add('ASISTENCIA ${e.id}');
      return const Scaffold(body: Text('ASISTENCIA'));
    };
    AppNavigator.constructorConvocatoriaProximoPartido = (e, j) {
      aperturas.add('CONVOCATORIA ${e.partido!.id} ${j!.id} ${j.nombre}');
      return const Scaffold(body: Text('CONVOCATORIA'));
    };
    AppNavigator.constructorSolicitudesFamilia = () {
      aperturas.add('SOLICITUDES');
      return const Scaffold(body: Text('SOLICITUDES'));
    };
    AppNavigator.constructorInvitaciones = () {
      aperturas.add('INVITACIONES');
      return const Scaffold(body: Text('INVITACIONES'));
    };
    AppNavigator.constructorModeracion = () {
      aperturas.add('MODERACION');
      return const Scaffold(body: Text('MODERACION'));
    };
    AppNavigator.constructorUsuariosCaducadas = () {
      aperturas.add('USUARIOS_CADUCADAS');
      return const Scaffold(body: Text('USUARIOS_CADUCADAS'));
    };
    AppNavigator.constructorImagenesRedes = (desde, tipo) {
      aperturas.add(
        'IMAGENES $tipo ${desde?.toIso8601String().substring(0, 10)}',
      );
      return const Scaffold(body: Text('IMAGENES'));
    };
  });

  tearDown(() {
    AppNavigator.cargarPerfilParaAviso = null;
    AppNavigator.fabricaConvocatoriaService = null;
    AppNavigator.fabricaEntrenamientoService = null;
    AppNavigator.servicioFichaPartido = null;
    AppNavigator.constructorCalendario = null;
    AppNavigator.constructorEdicion = null;
    AppNavigator.constructorFormularioConvocatoria = null;
    AppNavigator.constructorFormularioResultado = null;
    AppNavigator.constructorAsistencia = null;
    AppNavigator.constructorConvocatoriaProximoPartido = null;
    AppNavigator.constructorSolicitudesFamilia = null;
    AppNavigator.constructorInvitaciones = null;
    AppNavigator.constructorModeracion = null;
    AppNavigator.constructorUsuariosCaducadas = null;
    AppNavigator.constructorImagenesRedes = null;
    AuthManager.olvidarUsuario();
  });

  group('tocar "Tu próximo partido"', () {
    testWidgets('jugador o familia con convocatoria: su detalle', (
      tester,
    ) async {
      await _pintar(tester);

      unawaited(
        AppNavigator.abrirProximoPartido(
          _entrada(
            convocatoria: const ConvocatoriaProximoPartido(estado: 'CONVOCADO'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(aperturas, ['CONVOCATORIA 30 100 Pablo']);
      expect(find.text('CONVOCATORIA'), findsOneWidget);
    });

    testWidgets('un invitado también abre el detalle de la convocatoria', (
      tester,
    ) async {
      await _pintar(tester);

      unawaited(
        AppNavigator.abrirProximoPartido(
          _entrada(
            convocatoria: const ConvocatoriaProximoPartido(
              estado: 'INVITADO',
              equipoInvita: 'Alevín A',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONVOCATORIA'), findsOneWidget);
    });

    for (final estado in ['SIN_CONVOCATORIA', 'AUSENCIA_JUSTIFICADA']) {
      testWidgets('$estado: el calendario en el día del partido', (
        tester,
      ) async {
        await _pintar(tester);

        unawaited(
          AppNavigator.abrirProximoPartido(
            _entrada(convocatoria: ConvocatoriaProximoPartido(estado: estado)),
          ),
        );
        await tester.pumpAndSettle();

        expect(calendarios, [DateTime(2026, 11, 28)]);
        expect(find.text('CALENDARIO'), findsOneWidget);
        expect(aperturas, isEmpty);
      });
    }

    testWidgets('si no se puede cargar el perfil, el calendario', (
      tester,
    ) async {
      AppNavigator.cargarPerfilParaAviso = () async =>
          throw Exception('sin red');
      await _pintar(tester);

      unawaited(
        AppNavigator.abrirProximoPartido(
          _entrada(
            convocatoria: const ConvocatoriaProximoPartido(estado: 'CONVOCADO'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CALENDARIO'), findsOneWidget);
    });

    testWidgets('entrenador con la convocatoria publicada: la edición', (
      tester,
    ) async {
      await _pintar(tester);

      unawaited(
        AppNavigator.abrirProximoPartido(
          _entrada(
            tipo: 'ENTRENADOR',
            convocatoria: const ConvocatoriaProximoPartido(
              estado: 'PUBLICADA',
              convocatoriaId: 5,
              numeroConvocados: 14,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(aperturas, ['EDICION 5']);
    });

    testWidgets('entrenador sin convocatoria: el formulario para crearla', (
      tester,
    ) async {
      await _pintar(tester);

      unawaited(
        AppNavigator.abrirProximoPartido(
          _entrada(
            tipo: 'ENTRENADOR',
            convocatoria: const ConvocatoriaProximoPartido(
              estado: 'SIN_CONVOCATORIA',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(aperturas, ['FORM_CONVOCATORIA 30 10 Alevín B']);
    });

    testWidgets('un partido del Primer Equipo con ficha: la ficha', (
      tester,
    ) async {
      await _pintar(tester);

      unawaited(
        AppNavigator.abrirProximoPartido(
          ProximoPartido(
            tipo: 'ENTRENADOR',
            equipoId: 1,
            nombreEquipo: 'Primer Equipo',
            partido: _partido(equipo: 'Primer Equipo', id: 77),
            convocatoria: const ConvocatoriaProximoPartido(
              estado: 'SIN_CONVOCATORIA',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(FichaPartidoPage), findsOneWidget);
      expect(aperturas, isEmpty);
    });

    testWidgets('un descanso (sin partido) no abre nada', (tester) async {
      await _pintar(tester);

      await AppNavigator.abrirProximoPartido(
        const ProximoPartido(
          tipo: 'JUGADOR',
          jugadorId: 100,
          nombreEquipo: 'Alevín B',
          descansa: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
      expect(calendarios, isEmpty);
    });
  });

  group('tocar un elemento de Pendientes', () {
    Future<void> abrir(WidgetTester tester, ElementoPendiente elemento) async {
      await _pintar(tester);

      unawaited(AppNavigator.abrirPendiente(elemento));
      await tester.pumpAndSettle();
    }

    testWidgets('PASAR_LISTA abre la lista de ese entrenamiento', (
      tester,
    ) async {
      await abrir(
        tester,
        const ElementoPendiente(id: 12, texto: 't', destino: 'PASAR_LISTA:12'),
      );

      expect(aperturas, ['ASISTENCIA 12']);
    });

    testWidgets('CONVOCATORIA_NUEVA abre el formulario de ese partido', (
      tester,
    ) async {
      await abrir(
        tester,
        const ElementoPendiente(
          id: 30,
          texto: 't',
          destino: 'CONVOCATORIA_NUEVA:30',
          equipoId: 10,
          equipo: 'Alevín B',
          rival: 'Pego',
          hora: '11:00',
        ),
      );

      expect(aperturas, ['FORM_CONVOCATORIA 30 10 Alevín B']);
    });

    testWidgets('RESULTADO abre el formulario de resultado', (tester) async {
      await abrir(
        tester,
        ElementoPendiente(
          id: 34,
          texto: 't',
          destino: 'RESULTADO:34',
          fecha: DateTime(2026, 11, 21),
          diasRetraso: 4,
          equipoId: 10,
          equipo: 'Alevín B',
          rival: 'Pego',
          hora: '11:00',
        ),
      );

      expect(aperturas, ['FORM_RESULTADO 34 10 Alevín B Pego']);
    });

    testWidgets('SOLICITUDES_FAMILIA', (tester) async {
      await abrir(
        tester,
        const ElementoPendiente(texto: 't', destino: 'SOLICITUDES_FAMILIA'),
      );

      expect(aperturas, ['SOLICITUDES']);
    });

    testWidgets('INVITACIONES', (tester) async {
      await abrir(
        tester,
        const ElementoPendiente(texto: 't', destino: 'INVITACIONES'),
      );

      expect(aperturas, ['INVITACIONES']);
    });

    testWidgets('MODERACION', (tester) async {
      await abrir(
        tester,
        const ElementoPendiente(texto: 't', destino: 'MODERACION'),
      );

      expect(aperturas, ['MODERACION']);
    });

    testWidgets('USUARIOS_CADUCADAS', (tester) async {
      await abrir(
        tester,
        const ElementoPendiente(texto: 't', destino: 'USUARIOS_CADUCADAS'),
      );

      expect(aperturas, ['USUARIOS_CADUCADAS']);
    });

    for (final (destino, pestana) in [
      ('IMAGENES_PREVIA:2026-11-27', 'PREVIA'),
      ('IMAGENES_RESULTADOS:2026-11-27', 'RESULTADOS'),
    ]) {
      testWidgets(destino, (tester) async {
        AuthManager.establecerUsuario(
          AuthUser(usuarioId: 1, email: 'a@b.c', roles: const ['RRSS']),
        );

        await abrir(tester, ElementoPendiente(texto: 't', destino: destino));

        expect(aperturas, ['IMAGENES $pestana 2026-11-27']);
      });
    }

    testWidgets('un destino que no se conoce no hace nada', (tester) async {
      await abrir(
        tester,
        const ElementoPendiente(texto: 't', destino: 'DESTINO_NUEVO:1'),
      );

      expect(find.text('HOME'), findsOneWidget);
      expect(aperturas, isEmpty);
    });
  });
}
