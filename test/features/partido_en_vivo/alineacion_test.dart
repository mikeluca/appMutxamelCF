import 'dart:convert';

import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
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
  final List<({int partido, List<int> titulares, List<int> suplentes})> envios =
      [];
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
  }) async {
    final error = errorAlEnviar;
    if (error != null) throw error;

    envios.add((partido: partidoId, titulares: titulares, suplentes: suplentes));
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
}) async {
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
                  builder: (_) =>
                      AlineacionPage(service: servicio, partido: partido),
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
}

Finder _jugador(int id) => find.byKey(ValueKey('jugador-$id'));

Finder _orden(int id) => find.byKey(ValueKey('orden-$id'));

String _numeroDeOrden(WidgetTester tester, int id) =>
    tester.widget<Text>(find.descendant(of: _orden(id), matching: find.byType(Text))).data!;

Future<void> _tocar(WidgetTester tester, int id) async {
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

      await _pintar(tester, servicio);

      expect(find.text('No se han podido cargar los jugadores.'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
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
}
