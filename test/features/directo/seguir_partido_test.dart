import 'package:app_mutxamel_cf/core/config/app_preferences.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/services/topics_anonimos.dart';
import 'package:app_mutxamel_cf/features/directo/services/seguir_partido_service.dart';
import 'package:app_mutxamel_cf/features/directo/widgets/partido_visible.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/pages/ficha_partido_page.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/services/ficha_partido_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

/// Todo lo que toca el servicio, apuntado: altas y bajas de topics, lo guardado, el idioma y el permiso.
class _Entorno {
  final List<String> altas = [];
  final List<String> bajas = [];
  final Map<int, DateTime> guardados = {};
  String idioma = 'es';
  bool permiso = true;
  bool? recibe = false;
  int permisosPedidos = 0;
  DateTime ahora = DateTime(2026, 11, 14, 12);

  late final SeguirPartidoService servicio = SeguirPartidoService(
    suscribir: (topic) async => altas.add(topic),
    desuscribir: (topic) async => bajas.add(topic),
    obtenerIdioma: () async => idioma,
    leer: () async => Map.of(guardados),
    guardar: (seguidos) async {
      guardados
        ..clear()
        ..addAll(seguidos);
    },
    pedirPermiso: () async {
      permisosPedidos++;
      return permiso;
    },
    recibeResultados: () async => recibe,
    ahora: () => ahora,
  );
}

class _FichaFalsa extends FichaPartidoService {
  EstadoFicha estado;

  _FichaFalsa(this.estado);

  @override
  Future<FichaPartido> obtenerFicha(int partidoId, {String? idioma}) async {
    return FichaPartido(
      cabecera: CabeceraFicha(
        partidoId: partidoId,
        equipoLocal: 'Mutxamel CF',
        equipoVisitante: 'Pego C.F.',
        dia: DateTime(2026, 11, 14),
        hora: '18:00',
        estado: estado,
        golesFavor: estado == EstadoFicha.proximo ? null : 1,
        golesContra: estado == EstadoFicha.proximo ? null : 0,
        competicion: 'Segona FFCV',
      ),
    );
  }
}

Future<void> _pintar(
  WidgetTester tester,
  _Entorno entorno, {
  EstadoFicha estado = EstadoFicha.proximo,
  Locale locale = const Locale('es'),
}) async {
  pantalla(tester);

  await tester.pumpWidget(
    appCon(
      FichaPartidoPage(
        partidoId: 30,
        service: _FichaFalsa(estado),
        seguirService: entorno.servicio,
        avisosDeResultados: const Stream<void>.empty(),
      ),
      locale: locale,
    ),
  );

  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const _seguir = ValueKey('boton-seguir');
const _siguiendo = ValueKey('boton-siguiendo');
const _yaRecibe = ValueKey('seguir-ya-recibe');

void main() {
  group('SeguirPartidoService', () {
    test('el topic es partido_{id}_{idioma}', () {
      expect(SeguirPartidoService.topicDe(30, 'es'), 'partido_30_es');
      expect(SeguirPartidoService.topicDe(7, 'ca'), 'partido_7_ca');
      expect(SeguirPartidoService.topicDe(7, 'en'), 'partido_7_en');
    });

    test('seguir: pide permiso, da de alta en el topic del idioma y guarda id y día', () async {
      final e = _Entorno()..idioma = 'ca';

      final resultado = await e.servicio.seguir(30, DateTime(2026, 11, 20, 18));

      expect(resultado, ResultadoSeguir.seguido);
      expect(e.permisosPedidos, 1);
      expect(e.altas, ['partido_30_ca']);
      expect(e.guardados, {30: DateTime(2026, 11, 20)});
      expect(await e.servicio.sigue(30), isTrue);
      expect(await e.servicio.sigue(31), isFalse);
    });

    test('sin fecha se guarda el día de hoy', () async {
      final e = _Entorno();

      await e.servicio.seguir(30, null);

      expect(e.guardados[30], DateTime(2026, 11, 14));
    });

    test('si se deniega el permiso no se da de alta ni se marca como seguido', () async {
      final e = _Entorno()..permiso = false;

      final resultado = await e.servicio.seguir(30, DateTime(2026, 11, 20));

      expect(resultado, ResultadoSeguir.permisoDenegado);
      expect(e.altas, isEmpty);
      expect(e.guardados, isEmpty);
      expect(await e.servicio.sigue(30), isFalse);
    });

    test('dejar de seguir: baja del topic y lo olvida', () async {
      final e = _Entorno();
      await e.servicio.seguir(30, DateTime(2026, 11, 20));

      await e.servicio.dejarDeSeguir(30);

      expect(e.bajas, contains('partido_30_es'));
      expect(e.guardados, isEmpty);
      expect(await e.servicio.sigue(30), isFalse);
    });

    test('dejar de seguir un partido que no se seguía no toca nada', () async {
      final e = _Entorno();

      await e.servicio.dejarDeSeguir(30);

      expect(e.bajas, isEmpty);
    });

    test('al cambiar de idioma mueve cada partido seguido al topic del idioma nuevo', () async {
      final e = _Entorno();
      await e.servicio.seguir(30, DateTime(2026, 11, 20));
      await e.servicio.seguir(31, DateTime(2026, 11, 21));
      e.altas.clear();

      await e.servicio.alCambiarIdioma('es', 'ca');

      expect(e.bajas, unorderedEquals(['partido_30_es', 'partido_31_es']));
      expect(e.altas, unorderedEquals(['partido_30_ca', 'partido_31_ca']));
    });

    test('con el mismo idioma o sin partidos seguidos no hace nada', () async {
      final e = _Entorno();

      await e.servicio.alCambiarIdioma('es', 'ca');
      await e.servicio.seguir(30, DateTime(2026, 11, 20));
      e.altas.clear();
      e.bajas.clear();
      await e.servicio.alCambiarIdioma('es', 'es');

      expect(e.altas, isEmpty);
      expect(e.bajas, isEmpty);
    });

    test('baja automática: los de más de 2 días, aunque no se haya cargado su ficha', () async {
      final e = _Entorno();
      e.guardados[1] = DateTime(2026, 11, 10); // hace 4 días
      e.guardados[2] = DateTime(2026, 11, 11); // hace 3 días
      e.guardados[3] = DateTime(2026, 11, 12); // hace 2 días: aún vale
      e.guardados[4] = DateTime(2026, 11, 14); // hoy
      e.guardados[5] = DateTime(2026, 11, 20); // futuro

      await e.servicio.bajaAutomatica();

      expect(e.guardados.keys, unorderedEquals([3, 4, 5]));
      expect(
        e.bajas,
        containsAll(['partido_1_es', 'partido_2_es']),
      );
      expect(e.bajas, isNot(contains('partido_3_es')));
    });

    test('si todos están vigentes no escribe nada', () async {
      final e = _Entorno();
      e.guardados[4] = DateTime(2026, 11, 14);

      await e.servicio.bajaAutomatica();

      expect(e.bajas, isEmpty);
      expect(e.guardados.keys, [4]);
    });

    test('al cargar un partido terminado se da de baja', () async {
      final e = _Entorno();
      await e.servicio.seguir(30, DateTime(2026, 11, 14));

      await e.servicio.bajaSiTermino(30);

      expect(e.bajas, contains('partido_30_es'));
      expect(e.guardados, isEmpty);
    });

    test('al arrancar: caducados fuera y, si ya recibe los resultados, todos fuera', () async {
      final e = _Entorno();
      e.guardados[1] = DateTime(2026, 11, 1);
      e.guardados[2] = DateTime(2026, 11, 14);

      await e.servicio.alArrancar();
      expect(e.guardados.keys, [2]);

      e.recibe = true;
      await e.servicio.alArrancar();
      expect(e.guardados, isEmpty);
      expect(e.bajas, contains('partido_2_es'));
    });

    test('si no se sabe si recibe los resultados, no se baja de nada', () async {
      final e = _Entorno()..recibe = null;
      e.guardados[2] = DateTime(2026, 11, 14);

      await e.servicio.alArrancar();

      expect(e.guardados.keys, [2]);
    });
  });

  group('botón "Seguir este partido" en la ficha', () {
    testWidgets('sin recibir los resultados: botón con campana; seguir da de alta y pasa a "Siguiendo"', (
      tester,
    ) async {
      final e = _Entorno();

      await _pintar(tester, e);

      expect(find.byKey(_seguir), findsOneWidget);
      expect(find.text('Seguir este partido'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);

      await tester.tap(find.byKey(_seguir));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(e.altas, ['partido_30_es']);
      expect(find.byKey(_siguiendo), findsOneWidget);
      expect(find.text('Siguiendo'), findsOneWidget);
      expect(find.text('Recibirás los avisos de este partido.'), findsOneWidget);
      expect(e.guardados.keys, [30]);
    });

    testWidgets('al tocar "Siguiendo" se deja de seguir', (tester) async {
      final e = _Entorno();
      await e.servicio.seguir(30, DateTime(2026, 11, 14));
      e.altas.clear();

      await _pintar(tester, e);

      // Ya se seguía: se abre directamente como "Siguiendo".
      expect(find.byKey(_siguiendo), findsOneWidget);
      expect(find.byKey(_seguir), findsNothing);

      await tester.tap(find.byKey(_siguiendo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(e.bajas, contains('partido_30_es'));
      expect(e.guardados, isEmpty);
      expect(find.byKey(_seguir), findsOneWidget);
      expect(find.text('Dejas de seguir este partido.'), findsOneWidget);
    });

    testWidgets('el topic es el del idioma de la app', (tester) async {
      final e = _Entorno()..idioma = 'en';

      await _pintar(tester, e, locale: const Locale('en'));

      expect(find.text('Follow this match'), findsOneWidget);

      await tester.tap(find.byKey(_seguir));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(e.altas, ['partido_30_en']);
      expect(find.text('Following'), findsOneWidget);
    });

    testWidgets('en catalán', (tester) async {
      final e = _Entorno()..idioma = 'ca';

      await _pintar(tester, e, locale: const Locale('ca'));

      expect(find.text('Seguir aquest partit'), findsOneWidget);

      await tester.tap(find.byKey(_seguir));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Seguint'), findsOneWidget);
    });

    testWidgets('si ya recibe los avisos de resultados no hay botón: solo el texto', (
      tester,
    ) async {
      final e = _Entorno()..recibe = true;

      await _pintar(tester, e);

      expect(find.byKey(_seguir), findsNothing);
      expect(find.byKey(_yaRecibe), findsOneWidget);
      expect(
        find.text('Ya recibes los avisos de todos los partidos'),
        findsOneWidget,
      );
    });

    testWidgets('si no se sabe si los recibe (sin red con cuenta) no se ofrece nada', (
      tester,
    ) async {
      final e = _Entorno()..recibe = null;

      await _pintar(tester, e);

      expect(find.byKey(_seguir), findsNothing);
      expect(find.byKey(_yaRecibe), findsNothing);
    });

    testWidgets('si se deniega el permiso: mensaje claro y no se marca como seguido', (
      tester,
    ) async {
      final e = _Entorno()..permiso = false;

      await _pintar(tester, e);
      await tester.tap(find.byKey(_seguir));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(e.permisosPedidos, 1);
      expect(e.altas, isEmpty);
      expect(e.guardados, isEmpty);
      expect(find.byKey(_siguiendo), findsNothing);
      expect(find.byKey(_seguir), findsOneWidget);
      expect(
        find.text(
          'Para seguir el partido activa las notificaciones de la app en los ajustes del móvil.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('en juego y en el descanso también se puede seguir', (tester) async {
      for (final estado in [EstadoFicha.enJuego, EstadoFicha.descanso]) {
        await _pintar(tester, _Entorno(), estado: estado);

        expect(find.byKey(_seguir), findsOneWidget, reason: '$estado');

        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('en un partido terminado no hay botón ni texto, y se da de baja', (
      tester,
    ) async {
      for (final estado in [EstadoFicha.finalizado, EstadoFicha.cancelado]) {
        final e = _Entorno();
        await e.servicio.seguir(30, DateTime(2026, 11, 14));

        await _pintar(tester, e, estado: estado);

        expect(find.byKey(_seguir), findsNothing, reason: '$estado');
        expect(find.byKey(_siguiendo), findsNothing);
        expect(find.byKey(_yaRecibe), findsNothing);
        expect(e.bajas, contains('partido_30_es'), reason: '$estado');
        expect(e.guardados, isEmpty);

        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('PushNotificationService y los partidos seguidos', () {
    late _Entorno e;
    late List<String> altasAnonimas;
    late List<String> bajasAnonimas;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PartidoVisible.reiniciar();

      e = _Entorno();
      altasAnonimas = [];
      bajasAnonimas = [];

      PushNotificationService.seguirPartidos = e.servicio;
      PushNotificationService.topicsAnonimos = TopicsAnonimos(
        suscribir: (t) async => altasAnonimas.add(t),
        desuscribir: (t) async => bajasAnonimas.add(t),
      );
    });

    test('al cambiar el idioma en Ajustes, los partidos seguidos pasan al topic del idioma nuevo', () async {
      await e.servicio.seguir(30, DateTime(2026, 11, 14));
      e.altas.clear();

      await PushNotificationService.alCambiarIdioma('es', 'ca');

      expect(e.bajas, contains('partido_30_es'));
      expect(e.altas, ['partido_30_ca']);
    });

    test('si el idioma cambió sin pasar por Ajustes, se corrige al arrancar', () async {
      await AppPreferences.guardarIdiomaTopics('es');
      await AppPreferences.guardarIdioma('en');
      await e.servicio.seguir(30, DateTime(2026, 11, 14));
      e.altas.clear();

      await PushNotificationService.sincronizarTopicsAnonimos();

      expect(e.bajas, contains('partido_30_es'));
      expect(e.altas, ['partido_30_en']);
    });

    test('activar los resultados anónimos da de baja de los partidos seguidos (no duplicar avisos)', () async {
      await e.servicio.seguir(30, DateTime(2026, 11, 14));

      await PushNotificationService.activarResultadosAnonimos(true);

      expect(altasAnonimas, ['resultados_es']);
      expect(e.guardados, isEmpty);
      expect(e.bajas, contains('partido_30_es'));
    });

    test('apagarlos no toca los partidos seguidos', () async {
      await e.servicio.seguir(30, DateTime(2026, 11, 14));

      await PushNotificationService.activarResultadosAnonimos(false);

      expect(e.guardados.keys, [30]);
    });

    test('al arrancar se dan de baja los caducados, y todos si ya recibe los resultados', () async {
      e.guardados[1] = DateTime(2026, 11, 1);
      e.guardados[2] = DateTime(2026, 11, 14);

      await PushNotificationService.sincronizarPartidosSeguidos();
      expect(e.guardados.keys, [2]);

      e.recibe = true;
      await PushNotificationService.sincronizarPartidosSeguidos();
      expect(e.guardados, isEmpty);
    });

    test('un fallo no se propaga', () async {
      PushNotificationService.seguirPartidos = SeguirPartidoService(
        suscribir: (_) async {},
        desuscribir: (_) async => throw Exception('sin red'),
        obtenerIdioma: () async => 'es',
        leer: () async => {1: DateTime(2020)},
        guardar: (_) async {},
      );

      await PushNotificationService.sincronizarPartidosSeguidos();
      await PushNotificationService.sinSeguirPartidos();
    });

    test('con la portada o la ficha del partido a la vista, el aviso del directo no sale como notificación local', () async {
      final mostradas = <Map<String, dynamic>>[];

      PushNotificationService.mostrarNotificacionLocal =
          ({
            required int comunicacionId,
            required String titulo,
            required String mensaje,
            int cantidadNoLeidas = 1,
            bool esPrivada = false,
            int? autorId,
            Map<String, dynamic> datos = const {},
          }) async {
            mostradas.add(datos);
          };

      RemoteMessage aviso(String partido) => RemoteMessage(
        data: {
          'tipo': 'RESULTADO',
          'pantalla': 'FICHA_PARTIDO',
          'partidoId': partido,
        },
        notification: RemoteNotification(title: 'Gol', body: '1-0'),
      );

      final dueno = Object();

      // Con el partido 30 a la vista (portada o ficha).
      PartidoVisible.actualizar(dueno, 30);
      await PushNotificationService.mostrarEnPrimerPlano(aviso('30'));
      expect(mostradas, isEmpty);

      // Otro partido sí sale.
      await PushNotificationService.mostrarEnPrimerPlano(aviso('31'));
      expect(mostradas, hasLength(1));

      // Y sin nada a la vista, también.
      PartidoVisible.actualizar(dueno, null);
      await PushNotificationService.mostrarEnPrimerPlano(aviso('30'));
      expect(mostradas, hasLength(2));
    });

    test('quien sigue un partido recibe su aviso una sola vez: el topic lleva los mismos datos y abre la ficha', () {
      // El aviso del topic del partido trae tipo RESULTADO y partidoId, como el de resultados: abre su ficha.
      expect(
        PushNotificationService.partidoDeAviso({
          'tipo': 'RESULTADO',
          'pantalla': 'FICHA_PARTIDO',
          'partidoId': '30',
        }),
        30,
      );
    });
  });
}
