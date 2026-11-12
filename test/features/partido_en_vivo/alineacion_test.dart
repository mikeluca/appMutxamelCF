import 'dart:convert';

import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/models/formaciones.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/models/partido_en_vivo_models.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/pages/alineacion_page.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/services/partido_en_vivo_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/http_test_helpers.dart';

class _ServicioFalso extends PartidoEnVivoService {
  final List<ConvocadoEnVivo> jugadores;
  final List<
    ({
      int partido,
      List<int> titulares,
      List<int> suplentes,
      String? formacion,
      bool avisar,
    })
  >
  envios = [];
  Object? errorAlEnviar;
  int cargas = 0;
  bool fallarCarga = false;

  _ServicioFalso(this.jugadores);

  @override
  Future<List<ConvocadoEnVivo>> obtenerConvocados(int partidoId) async {
    cargas++;
    if (fallarCarga) {
      fallarCarga = false;
      throw Exception('sin red');
    }

    return jugadores;
  }

  @override
  Future<void> enviarAlineacion(
    int partidoId, {
    required List<int> titulares,
    List<int> suplentes = const [],
    String? formacion,
    bool avisar = false,
  }) async {
    final error = errorAlEnviar;
    if (error != null) throw error;

    envios.add((
      partido: partidoId,
      titulares: titulares,
      suplentes: suplentes,
      formacion: formacion,
      avisar: avisar,
    ));
  }
}

List<ConvocadoEnVivo> _plantilla({String origen = 'CONVOCATORIA'}) => [
  ConvocadoEnVivo(
    jugadorId: 1,
    dorsal: 9,
    nombre: 'Pablo Garcia',
    nombreRetransmision: 'Pepe',
    origen: origen,
  ),
  ConvocadoEnVivo(
    jugadorId: 2,
    dorsal: 1,
    nombre: 'Luis Lopez',
    nombreRetransmision: 'Luis Lopez',
    origen: origen,
  ),
  ConvocadoEnVivo(
    jugadorId: 3,
    dorsal: 4,
    nombre: 'Juan Manuel Ruiz',
    nombreRetransmision: 'Juanma',
    origen: origen,
  ),
  ConvocadoEnVivo(
    jugadorId: 4,
    dorsal: null,
    nombre: 'Sin Dorsal Perez',
    nombreRetransmision: 'Sin Dorsal Perez',
    origen: origen,
  ),
  ConvocadoEnVivo(
    jugadorId: 5,
    dorsal: 7,
    nombre: 'Ana Ruiz',
    nombreRetransmision: 'Ana Ruiz',
    origen: origen,
  ),
];

Future<void> _pintar(
  WidgetTester tester,
  _ServicioFalso servicio, {
  PartidoEnVivoDisponible partido = const PartidoEnVivoDisponible(
    id: 30,
    rival: 'Pego C.F.',
  ),
  Locale locale = const Locale('es'),
  bool yaEnviada = false,

  /// Salta el paso de la formaciÃ³n (se queda en "Sin formaciÃ³n"), que es el primero.
  bool saltarFormacion = true,
}) async {
  // Una pantalla alta: la lista es perezosa y con la vista previa del campo queda poco sitio.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (_) => AlineacionPage(
                    service: servicio,
                    partido: partido,
                    yaEnviada: yaEnviada,
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();

  if (saltarFormacion) {
    await tester.tap(find.byKey(const ValueKey('paso-formacion')));
    await tester.pumpAndSettle();
  }
}

Finder _jugador(int id) => find.byKey(ValueKey('jugador-$id'));

Finder _orden(int id) => find.byKey(ValueKey('orden-$id'));

String _numeroDeOrden(WidgetTester tester, int id) =>
    tester.widget<Text>(find.descendant(of: _orden(id), matching: find.byType(Text))).data!;

Future<void> _tocar(WidgetTester tester, int id) async {
  await tester.ensureVisible(_jugador(id));
  await tester.pump();
  await tester.tap(_jugador(id));
  await tester.pump();
}

Future<void> _siguiente(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('paso-siguiente')));
  await tester.pumpAndSettle();
}

String _texto(WidgetTester tester, String clave) =>
    tester.widget<Text>(find.byKey(ValueKey(clave))).data!;

void main() {
  group('lista de jugadores', () {
    testWidgets('indica arriba si son de la convocatoria o de toda la plantilla',
        (tester) async {
      await _pintar(tester, _ServicioFalso(_plantilla()));

      expect(_texto(tester, 'origen-jugadores'), 'De la convocatoria');
    });

    testWidgets('sin convocatoria dice "De toda la plantilla"', (tester) async {
      await _pintar(tester, _ServicioFalso(_plantilla(origen: 'PLANTILLA')));

      expect(_texto(tester, 'origen-jugadores'), 'De toda la plantilla');
    });

    testWidgets('en valenciano y en inglés el origen sale traducido', (tester) async {
      await _pintar(
        tester,
        _ServicioFalso(_plantilla(origen: 'PLANTILLA')),
        locale: const Locale('ca'),
      );
      expect(_texto(tester, 'origen-jugadores'), 'De tota la plantilla');
    });

    testWidgets('un backend antiguo sin origen no enseña la línea de origen',
        (tester) async {
      await _pintar(
        tester,
        _ServicioFalso(const [
          ConvocadoEnVivo(jugadorId: 1, dorsal: 9, nombre: 'Pablo Garcia'),
        ]),
      );

      expect(find.byKey(const ValueKey('origen-jugadores')), findsNothing);
      expect(find.text('Pablo Garcia'), findsOneWidget);
    });

    testWidgets('cada jugador muestra dorsal, nombre completo y, si lo tiene, el de retransmisión',
        (tester) async {
      await _pintar(tester, _ServicioFalso(_plantilla()));

      expect(find.text('Pablo Garcia'), findsOneWidget);
      expect(find.text('Pepe'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      // Sin nombre propio de retransmisión no se repite el nombre debajo.
      expect(find.text('Luis Lopez'), findsOneWidget);
    });

    testWidgets('si falla la carga se puede reintentar', (tester) async {
      final servicio = _ServicioFalso(_plantilla())..fallarCarga = true;

      await _pintar(tester, servicio, saltarFormacion: false);

      expect(find.text('No se han podido cargar los jugadores.'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('paso-formacion')));
      await tester.pumpAndSettle();

      expect(find.text('Pablo Garcia'), findsOneWidget);
      expect(servicio.cargas, 2);
    });
  });

  group('once inicial', () {
    testWidgets('cada jugador tocado muestra su número de orden', (tester) async {
      await _pintar(tester, _ServicioFalso(_plantilla()));

      await _tocar(tester, 3);
      await _tocar(tester, 1);
      await _tocar(tester, 5);

      expect(_numeroDeOrden(tester, 3), '1');
      expect(_numeroDeOrden(tester, 1), '2');
      expect(_numeroDeOrden(tester, 5), '3');
      expect(_orden(2), findsNothing);
    });

    testWidgets('tocar de nuevo lo quita y reordena a los siguientes', (tester) async {
      await _pintar(tester, _ServicioFalso(_plantilla()));

      await _tocar(tester, 3);
      await _tocar(tester, 1);
      await _tocar(tester, 5);
      await _tocar(tester, 3);

      expect(_orden(3), findsNothing);
      expect(_numeroDeOrden(tester, 1), '1');
      expect(_numeroDeOrden(tester, 5), '2');
      expect(_texto(tester, 'contador-titulares'), '2/11');
    });

    testWidgets('el contador avisa si el once no está completo, pero deja continuar',
        (tester) async {
      await _pintar(tester, _ServicioFalso(_plantilla()));

      expect(_texto(tester, 'contador-titulares'), '0/11');
      expect(find.byKey(const ValueKey('aviso-incompleto')), findsOneWidget);

      // Sin ningún titular no se puede continuar.
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('paso-siguiente')))
            .onPressed,
        isNull,
      );

      await _tocar(tester, 1);

      expect(_texto(tester, 'contador-titulares'), '1/11');
      expect(
        _texto(tester, 'aviso-incompleto'),
        'El once no está completo (1/11). Puedes continuar igualmente.',
      );

      await _siguiente(tester);

      expect(_texto(tester, 'titulo-paso'), 'Suplentes');
    });

    testWidgets('el máximo depende de la modalidad del partido y no deja pasarse', (tester) async {
      final jugadores = [
        for (var i = 1; i <= 7; i++)
          ConvocadoEnVivo(
            jugadorId: i,
            dorsal: i,
            nombre: 'Jugador $i',
            origen: 'PLANTILLA',
          ),
      ];

      await _pintar(
        tester,
        _ServicioFalso(jugadores),
        partido: const PartidoEnVivoDisponible(
          id: 30,
          rival: 'Pego C.F.',
          modalidad: 'F5',
        ),
      );

      expect(_texto(tester, 'contador-titulares'), '0/5');

      for (var i = 1; i <= 6; i++) {
        await _tocar(tester, i);
      }

      expect(_texto(tester, 'contador-titulares'), '5/5');
      expect(_orden(6), findsNothing);
      expect(find.byKey(const ValueKey('aviso-incompleto')), findsNothing);
      expect(find.textContaining('Ya hay 5 titulares'), findsOneWidget);
    });

    testWidgets('F8 admite 8 y sin modalidad se asumen 11', (tester) async {
      expect(
        const PartidoEnVivoDisponible(id: 1, rival: 'x', modalidad: 'F8')
            .maximoTitulares,
        8,
      );
      expect(const PartidoEnVivoDisponible(id: 1, rival: 'x').maximoTitulares, 11);
    });
  });

  group('suplentes y envío', () {
    testWidgets('los titulares no salen entre los suplentes', (tester) async {
      await _pintar(tester, _ServicioFalso(_plantilla()));

      await _tocar(tester, 1);
      await _siguiente(tester);

      expect(_jugador(1), findsNothing);
      expect(_jugador(2), findsOneWidget);
    });

    testWidgets('se puede enviar sin suplentes: la vista previa lo dice y se manda lista vacía',
        (tester) async {
      final servicio = _ServicioFalso(_plantilla());
      await _pintar(tester, servicio);

      await _tocar(tester, 3);
      await _tocar(tester, 1);
      await _siguiente(tester);

      expect(_texto(tester, 'vista-previa-once'), 'Once inicial: Juanma, Pepe');
      expect(_texto(tester, 'vista-previa-suplentes'), 'Sin suplentes');

      await tester.tap(find.byKey(const ValueKey('enviar-alineacion')));
      await tester.pumpAndSettle();

      expect(servicio.envios.single.partido, 30);
      expect(servicio.envios.single.titulares, [3, 1]);
      expect(servicio.envios.single.suplentes, isEmpty);
      // Se cierra la pantalla.
      expect(find.byType(AlineacionPage), findsNothing);
    });

    testWidgets('los suplentes van en el orden elegido, con los nombres de retransmisión',
        (tester) async {
      final servicio = _ServicioFalso(_plantilla());
      await _pintar(tester, servicio);

      await _tocar(tester, 1);
      await _siguiente(tester);

      await _tocar(tester, 5);
      await _tocar(tester, 3);

      expect(_numeroDeOrden(tester, 5), '1');
      expect(_numeroDeOrden(tester, 3), '2');
      expect(_texto(tester, 'vista-previa-once'), 'Once inicial: Pepe');
      expect(
        _texto(tester, 'vista-previa-suplentes'),
        'Suplentes: Ana Ruiz, Juanma',
      );

      await tester.tap(find.byKey(const ValueKey('enviar-alineacion')));
      await tester.pumpAndSettle();

      expect(servicio.envios.single.titulares, [1]);
      expect(servicio.envios.single.suplentes, [5, 3]);
    });

    testWidgets('"Añadir el resto de convocados" añade a los demás por dorsal, sin dorsal al final',
        (tester) async {
      final servicio = _ServicioFalso(_plantilla());
      await _pintar(tester, servicio);

      await _tocar(tester, 1);
      await _siguiente(tester);
      // El 5 ya está elegido como suplente: el resto se añade detrás.
      await _tocar(tester, 5);

      await tester.tap(find.byKey(const ValueKey('anadir-resto')));
      await tester.pump();

      expect(
        _texto(tester, 'vista-previa-suplentes'),
        'Suplentes: Ana Ruiz, Luis Lopez, Juanma, Sin Dorsal Perez',
      );
    });

    testWidgets('sin convocatoria (toda la plantilla) no hay "Añadir el resto"', (tester) async {
      await _pintar(tester, _ServicioFalso(_plantilla(origen: 'PLANTILLA')));

      await _tocar(tester, 1);
      await _siguiente(tester);

      expect(find.byKey(const ValueKey('anadir-resto')), findsNothing);
    });

    testWidgets('volver y elegir como titular a un suplente lo saca del banquillo', (tester) async {
      final servicio = _ServicioFalso(_plantilla());
      await _pintar(tester, servicio);

      await _tocar(tester, 1);
      await _siguiente(tester);
      await _tocar(tester, 2);

      await tester.tap(find.text('Atrás'));
      await tester.pumpAndSettle();
      await _tocar(tester, 2);
      await _siguiente(tester);

      expect(_texto(tester, 'vista-previa-once'), 'Once inicial: Pepe, Luis Lopez');
      expect(_texto(tester, 'vista-previa-suplentes'), 'Sin suplentes');
    });

    testWidgets('un error 400 del servidor se enseña en texto claro y se puede corregir',
        (tester) async {
      final servicio = _ServicioFalso(_plantilla())
        ..errorAlEnviar = Exception(
          'Un jugador no puede aparecer dos veces en la alineación',
        );
      await _pintar(tester, servicio);

      await _tocar(tester, 1);
      await _siguiente(tester);
      await tester.tap(find.byKey(const ValueKey('enviar-alineacion')));
      await tester.pump();

      expect(
        find.textContaining('Un jugador no puede aparecer dos veces'),
        findsOneWidget,
      );
      // Sigue en la pantalla, con el envío otra vez habilitado.
      expect(find.byType(AlineacionPage), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('enviar-alineacion')))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('servicio y modelos', () {
    setUp(() async {
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
        <String, String>{},
      );
      await AuthSession.guardarSesion(
        LoginResponse(
          token: 'tok',
          usuarioId: 1,
          email: 'a@a.com',
          roles: const ['RETRANSMISION'],
        ),
      );
    });

    test('la alineación se manda a /{partidoId}/alineacion con los ids en orden', () async {
      http.Request? peticion;

      await conMockHttp((request) async {
        peticion = request;
        return http.Response('', 200);
      }, () => PartidoEnVivoService().enviarAlineacion(
        30,
        titulares: [3, 1, 5],
        suplentes: [2],
      ));

      expect(peticion!.method, 'POST');
      expect(peticion!.url.path, endsWith('/app/partido-en-vivo/30/alineacion'));
      expect(jsonDecode(peticion!.body), {
        'titulares': [3, 1, 5],
        'suplentes': [2],
        'formacion': null,
        'avisar': false,
      });
    });

    test('sin suplentes se manda la lista vacía', () async {
      http.Request? peticion;

      await conMockHttp((request) async {
        peticion = request;
        return http.Response('', 200);
      }, () => PartidoEnVivoService().enviarAlineacion(30, titulares: [1]));

      expect(jsonDecode(peticion!.body)['suplentes'], isEmpty);
    });

    test('un convocado lee nombreCompleto, nombreRetransmision y origen', () {
      final jugador = ConvocadoEnVivo.fromJson({
        'jugadorId': 10,
        'dorsal': 9,
        'nombre': 'Pablo Garcia',
        'nombreCompleto': 'Pablo Garcia',
        'nombreRetransmision': 'Pepe',
        'origen': 'CONVOCATORIA',
      });

      expect(jugador.nombre, 'Pablo Garcia');
      expect(jugador.nombreRetransmision, 'Pepe');
      expect(jugador.nombreEnDirecto, 'Pepe');
      expect(jugador.tieneNombreRetransmision, isTrue);
      expect(jugador.origen, ConvocadoEnVivo.origenConvocatoria);
    });

    test('si el nombre de retransmisión es igual al completo o no viene, no se enseña aparte', () {
      final igual = ConvocadoEnVivo.fromJson({
        'jugadorId': 1,
        'nombre': 'Luis Lopez',
        'nombreCompleto': 'Luis Lopez',
        'nombreRetransmision': 'Luis Lopez',
      });
      final antiguo = ConvocadoEnVivo.fromJson({
        'jugadorId': 2,
        'dorsal': 4,
        'nombre': 'Ana Ruiz',
      });

      expect(igual.tieneNombreRetransmision, isFalse);
      expect(antiguo.tieneNombreRetransmision, isFalse);
      expect(antiguo.nombreEnDirecto, 'Ana Ruiz');
      expect(antiguo.origen, isNull);
    });
  });

  group('formación y vista previa del campo', () {
    List<ConvocadoEnVivo> once() => [
      for (var i = 1; i <= 12; i++)
        ConvocadoEnVivo(
          jugadorId: i,
          dorsal: i,
          nombre: 'Jugador $i',
          origen: 'PLANTILLA',
        ),
    ];

    Future<void> elegirFormacion(WidgetTester tester, String formacion) async {
      await tester.tap(find.byKey(ValueKey('formacion-$formacion')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('paso-formacion')));
      await tester.pumpAndSettle();
    }

    Finder posicion(int fila, int columna) =>
        find.byKey(ValueKey('posicion-$fila-$columna'));

    testWidgets('el primer paso es la formación, con "Sin formación" elegida por defecto', (
      tester,
    ) async {
      await _pintar(tester, _ServicioFalso(once()), saltarFormacion: false);

      expect(_texto(tester, 'titulo-paso'), 'Formación');

      for (final formacion in [
        '4-4-2', '4-3-3', '4-2-3-1', '4-5-1', '4-1-4-1', '3-5-2', '3-4-3', '5-3-2', '5-4-1',
      ]) {
        expect(find.byKey(ValueKey('formacion-$formacion')), findsOneWidget);
      }

      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('formacion-ninguna')))
            .selected,
        isTrue,
      );
      // Aún no se han pedido jugadores para elegir: se ve la lista de formaciones.
      expect(find.byKey(ValueKey('jugador-1')), findsNothing);
    });

    testWidgets('las formaciones salen según la modalidad del equipo', (tester) async {
      await _pintar(
        tester,
        _ServicioFalso(once()),
        saltarFormacion: false,
        partido: const PartidoEnVivoDisponible(
          id: 30,
          rival: 'Pego C.F.',
          modalidad: 'F8',
        ),
      );

      expect(find.byKey(const ValueKey('formacion-3-3-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('formacion-4-4-2')), findsNothing);
    });

    testWidgets('sin formación no hay vista previa del campo', (tester) async {
      await _pintar(tester, _ServicioFalso(once()));

      expect(find.byKey(const ValueKey('vista-previa-campo')), findsNothing);
      expect(_texto(tester, 'contador-titulares'), '0/11');
    });

    testWidgets('con 4-4-2 el orden de elección rellena portero, defensas, medios y delanteros', (
      tester,
    ) async {
      await _pintar(tester, _ServicioFalso(once()), saltarFormacion: false);
      await elegirFormacion(tester, '4-4-2');

      expect(find.byKey(const ValueKey('vista-previa-campo')), findsOneWidget);
      expect(_texto(tester, 'campo-formacion'), '4-4-2');
      expect(_texto(tester, 'contador-titulares'), '0/11');

      // El campo se va llenando: de momento vacío.
      expect(find.byKey(const ValueKey('posicion-1-1')), findsNothing);

      await _tocar(tester, 7); // portero
      await _tocar(tester, 3); // defensa izquierdo
      expect(posicion(1, 1), findsOneWidget);
      expect(posicion(2, 1), findsOneWidget);
      expect(posicion(2, 2), findsNothing);

      for (final id in [1, 2, 4, 5, 6, 8, 9, 10, 11]) {
        await _tocar(tester, id);
      }

      // 1 portero + 4 defensas + 4 medios + 2 delanteros.
      expect(posicion(1, 1), findsOneWidget);
      for (var c = 1; c <= 4; c++) {
        expect(posicion(2, c), findsOneWidget);
        expect(posicion(3, c), findsOneWidget);
      }
      expect(posicion(4, 1), findsOneWidget);
      expect(posicion(4, 2), findsOneWidget);
      expect(posicion(4, 3), findsNothing);

      // El 7 (1.º) es el portero; el 3 (2.º) el primer defensa; el 10 y el 11 los delanteros.
      expect(
        find.descendant(of: posicion(1, 1), matching: find.text('7')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: posicion(2, 1), matching: find.text('3')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: posicion(4, 1), matching: find.text('10')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: posicion(4, 2), matching: find.text('11')),
        findsOneWidget,
      );

      // Portero abajo y delanteros arriba; de izquierda a derecha.
      expect(tester.getCenter(posicion(1, 1)).dy,
          greaterThan(tester.getCenter(posicion(2, 1)).dy));
      expect(tester.getCenter(posicion(2, 1)).dy,
          greaterThan(tester.getCenter(posicion(4, 1)).dy));
      expect(tester.getCenter(posicion(4, 1)).dx,
          lessThan(tester.getCenter(posicion(4, 2)).dx));
    });

    testWidgets('con 4-5-1 salen cinco medios y un delantero', (tester) async {
      await _pintar(tester, _ServicioFalso(once()), saltarFormacion: false);
      await elegirFormacion(tester, '4-5-1');

      for (var id = 1; id <= 11; id++) {
        await _tocar(tester, id);
      }

      expect(_texto(tester, 'campo-formacion'), '4-5-1');
      for (var c = 1; c <= 5; c++) {
        expect(posicion(3, c), findsOneWidget);
      }
      expect(posicion(4, 1), findsOneWidget);
      expect(posicion(4, 2), findsNothing);
    });

    testWidgets('quitar a un jugador recoloca a los siguientes', (tester) async {
      await _pintar(tester, _ServicioFalso(once()), saltarFormacion: false);
      await elegirFormacion(tester, '4-4-2');

      await _tocar(tester, 1);
      await _tocar(tester, 2);
      await _tocar(tester, 3);
      expect(posicion(2, 2), findsOneWidget);

      await _tocar(tester, 2);

      expect(posicion(2, 2), findsNothing);
      expect(
        find.descendant(of: posicion(2, 1), matching: find.text('3')),
        findsOneWidget,
      );
    });

    testWidgets('con formación hace falta el once exacto y se avisa de cuántos', (
      tester,
    ) async {
      await _pintar(tester, _ServicioFalso(once()), saltarFormacion: false);
      await elegirFormacion(tester, '4-4-2');

      await _tocar(tester, 1);

      expect(
        _texto(tester, 'aviso-incompleto'),
        'Con esta formación hacen falta 11 titulares (portero incluido).',
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('paso-siguiente')))
            .onPressed,
        isNull,
      );

      for (var id = 2; id <= 11; id++) {
        await _tocar(tester, id);
      }

      expect(_texto(tester, 'contador-titulares'), '11/11');
      expect(find.byKey(const ValueKey('aviso-incompleto')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('paso-siguiente')))
            .onPressed,
        isNotNull,
      );

      // Un duodécimo no cabe.
      await _tocar(tester, 12);
      expect(_orden(12), findsNothing);
      expect(find.textContaining('Ya hay 11 titulares'), findsOneWidget);
    });

    testWidgets('se envía con la formación y los titulares en el orden elegido', (
      tester,
    ) async {
      final servicio = _ServicioFalso(once());
      await _pintar(tester, servicio, saltarFormacion: false);
      await elegirFormacion(tester, '4-3-3');

      final orden = [5, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11];
      for (final id in orden) {
        await _tocar(tester, id);
      }
      await _siguiente(tester);
      await _tocar(tester, 12);

      await tester.tap(find.byKey(const ValueKey('enviar-alineacion')));
      await tester.pumpAndSettle();

      final envio = servicio.envios.single;
      expect(envio.formacion, '4-3-3');
      expect(envio.titulares, orden);
      expect(envio.suplentes, [12]);
    });

    testWidgets('volver a la formación y dejarla en "Sin formación" manda null', (
      tester,
    ) async {
      final servicio = _ServicioFalso(once());
      await _pintar(tester, servicio, saltarFormacion: false);
      await elegirFormacion(tester, '4-4-2');
      await _tocar(tester, 1);

      await tester.tap(find.text('Atrás'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('formacion-ninguna')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('paso-formacion')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vista-previa-campo')), findsNothing);
      // Lo elegido se conserva.
      expect(_numeroDeOrden(tester, 1), '1');

      await _siguiente(tester);
      await tester.tap(find.byKey(const ValueKey('enviar-alineacion')));
      await tester.pumpAndSettle();

      expect(servicio.envios.single.formacion, isNull);
    });
  });

  group('casilla "Enviar aviso"', () {
    Future<void> hastaSuplentes(WidgetTester tester) async {
      await _tocar(tester, 1);
      await _siguiente(tester);
    }

    bool marcada(WidgetTester tester) => tester
        .widget<CheckboxListTile>(find.byKey(const ValueKey('enviar-aviso')))
        .value!;

    testWidgets('la primera vez viene marcada y se envía con aviso', (tester) async {
      final servicio = _ServicioFalso(_plantilla());
      await _pintar(tester, servicio);
      await hastaSuplentes(tester);

      expect(find.text('Enviar aviso'), findsOneWidget);
      expect(marcada(tester), isTrue);

      await tester.tap(find.byKey(const ValueKey('enviar-alineacion')));
      await tester.pumpAndSettle();

      expect(servicio.envios.single.avisar, isTrue);
    });

    testWidgets('si ya se envió una alineación viene desmarcada y no avisa', (
      tester,
    ) async {
      final servicio = _ServicioFalso(_plantilla());
      await _pintar(tester, servicio, yaEnviada: true);
      await hastaSuplentes(tester);

      expect(marcada(tester), isFalse);

      await tester.tap(find.byKey(const ValueKey('enviar-alineacion')));
      await tester.pumpAndSettle();

      expect(servicio.envios.single.avisar, isFalse);
    });

    testWidgets('se puede marcar o desmarcar a mano', (tester) async {
      final servicio = _ServicioFalso(_plantilla());
      await _pintar(tester, servicio, yaEnviada: true);
      await hastaSuplentes(tester);

      await tester.tap(find.byKey(const ValueKey('enviar-aviso')));
      await tester.pump();
      expect(marcada(tester), isTrue);

      await tester.tap(find.byKey(const ValueKey('enviar-alineacion')));
      await tester.pumpAndSettle();

      expect(servicio.envios.single.avisar, isTrue);
    });

    testWidgets('el texto sale en valenciano y en inglés', (tester) async {
      await _pintar(tester, _ServicioFalso(_plantilla()), locale: const Locale('ca'));
      await hastaSuplentes(tester);
      expect(find.text('Enviar avís'), findsOneWidget);
    });
  });

  group('formaciones', () {
    test('las listas cerradas de cada modalidad', () {
      expect(Formaciones.paraModalidad(null), Formaciones.f11);
      expect(Formaciones.paraModalidad('F11'), Formaciones.f11);
      expect(Formaciones.paraModalidad('F8'), Formaciones.f8);
      expect(Formaciones.paraModalidad('F5'), Formaciones.f5);
      expect(Formaciones.f11, hasLength(9));
    });

    test('los titulares son 1 + la suma de la formación', () {
      expect(Formaciones.titulares('4-4-2'), 11);
      expect(Formaciones.titulares('4-2-3-1'), 11);
      expect(Formaciones.titulares('3-3-1'), 8);
      expect(Formaciones.titulares('2-2'), 5);

      for (final formacion in Formaciones.f11) {
        expect(Formaciones.titulares(formacion), 11);
      }
      for (final formacion in Formaciones.f8) {
        expect(Formaciones.titulares(formacion), 8);
      }
      for (final formacion in Formaciones.f5) {
        expect(Formaciones.titulares(formacion), 5);
      }
    });

    test('la posición sale del orden: portero, líneas de atrás adelante y de izquierda a derecha', () {
      ({int fila, int columna})? p(int orden) => Formaciones.posicion('4-2-3-1', orden);

      expect(p(1), (fila: 1, columna: 1));
      expect(p(2), (fila: 2, columna: 1));
      expect(p(5), (fila: 2, columna: 4));
      expect(p(6), (fila: 3, columna: 1));
      expect(p(7), (fila: 3, columna: 2));
      expect(p(8), (fila: 4, columna: 1));
      expect(p(10), (fila: 4, columna: 3));
      expect(p(11), (fila: 5, columna: 1));
      expect(p(12), isNull);
      expect(p(0), isNull);
      expect(Formaciones.filas('4-2-3-1'), 5);
    });
  });

  group('servicio: formación, aviso, cambio y tarjeta', () {
    setUp(() async {
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
        <String, String>{},
      );
      await AuthSession.guardarSesion(
        LoginResponse(
          token: 'tok',
          usuarioId: 1,
          email: 'a@a.com',
          roles: const ['RETRANSMISION'],
        ),
      );
    });

    test('la alineación manda formacion y avisar', () async {
      http.Request? peticion;

      await conMockHttp((request) async {
        peticion = request;
        return http.Response('', 200);
      }, () => PartidoEnVivoService().enviarAlineacion(
        30,
        titulares: [3, 1, 5],
        suplentes: [2],
        formacion: '4-4-2',
        avisar: true,
      ));

      expect(jsonDecode(peticion!.body), {
        'titulares': [3, 1, 5],
        'suplentes': [2],
        'formacion': '4-4-2',
        'avisar': true,
      });
    });

    test('el cambio va a POST /{partidoId}/cambio con quién sale, quién entra y el minuto', () async {
      http.Request? peticion;

      final estado = await conMockHttp((request) async {
        peticion = request;
        return http.Response(
          '{"partidoId":30,"fase":"PRIMERA_PARTE","eventos":[]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }, () => PartidoEnVivoService().enviarCambio(
        30,
        jugadorSaleId: 10,
        jugadorEntraId: 12,
        minuto: 60,
      ));

      expect(peticion!.method, 'POST');
      expect(peticion!.url.path, endsWith('/app/partido-en-vivo/30/cambio'));
      expect(jsonDecode(peticion!.body), {
        'jugadorSaleId': 10,
        'jugadorEntraId': 12,
        'minuto': 60,
      });
      expect(peticion!.headers['Authorization'], 'Bearer tok');
      expect(estado.partidoId, 30);
    });

    test('la tarjeta va a POST /{partidoId}/tarjeta con jugador, color y minuto', () async {
      http.Request? peticion;

      await conMockHttp((request) async {
        peticion = request;
        return http.Response(
          '{"partidoId":30,"fase":"PRIMERA_PARTE","eventos":[]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }, () => PartidoEnVivoService().enviarTarjeta(
        30,
        jugadorId: 10,
        color: 'ROJA',
      ));

      expect(peticion!.url.path, endsWith('/app/partido-en-vivo/30/tarjeta'));
      expect(jsonDecode(peticion!.body), {
        'jugadorId': 10,
        'color': 'ROJA',
        'minuto': null,
      });
    });
  });
}
