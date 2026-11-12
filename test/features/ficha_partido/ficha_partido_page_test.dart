import 'dart:async';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/pages/ficha_partido_page.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/services/ficha_partido_service.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/widgets/ficha_forma.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/http_test_helpers.dart';

/// PNG de 1x1 píxel en base64: una "foto" válida.
const String _foto =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

class _ServicioFalso extends FichaPartidoService {
  /// Lo que contesta, por partido; se puede cambiar entre llamadas.
  final Map<int, FichaPartido> fichas;
  final List<int> llamadas = [];
  final List<String?> idiomas = [];
  Object? error;

  _ServicioFalso(this.fichas);

  @override
  Future<FichaPartido> obtenerFicha(int partidoId, {String? idioma}) async {
    llamadas.add(partidoId);
    idiomas.add(idioma);

    final e = error;
    if (e != null) throw e;

    return fichas[partidoId]!;
  }
}

CabeceraFicha _cabecera({
  EstadoFicha estado = EstadoFicha.proximo,
  bool local = true,
  int? favor,
  int? contra,
  String hora = '21:00',
  String competicion = 'Segona FFCV, Grup 7 · Jornada 9',
  int id = 30,
}) {
  return CabeceraFicha(
    partidoId: id,
    equipoLocal: local ? 'Mutxamel CF' : 'Pego C.F.',
    equipoVisitante: local ? 'Pego C.F.' : 'Mutxamel CF',
    dia: DateTime(2026, 11, 11),
    hora: hora,
    golesFavor: favor,
    golesContra: contra,
    estado: estado,
    competicion: competicion,
  );
}

FichaPartido _ficha({
  CabeceraFicha? cabecera,
  List<EventoFicha> eventos = const [],
  AlineacionFicha alineacion = const AlineacionFicha(),
  List<FormaFicha> forma = const [],
}) {
  return FichaPartido(
    cabecera: cabecera ?? _cabecera(),
    eventos: eventos,
    alineacion: alineacion,
    forma: forma,
  );
}

Future<void> _pintar(
  WidgetTester tester,
  _ServicioFalso servicio, {
  Stream<void>? avisos,
  Duration intervalo = const Duration(seconds: 30),
  Locale locale = const Locale('es'),
  int partidoId = 30,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
      home: FichaPartidoPage(
        partidoId: partidoId,
        service: servicio,
        avisosDeResultados: avisos ?? const Stream<void>.empty(),
        intervalo: intervalo,
      ),
    ),
  );

  await _asentar(tester);
}

/// Sin pumpAndSettle: el punto en directo parpadea para siempre.
Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Quita la pantalla: cancela el temporizador y el parpadeo.
Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

String _texto(WidgetTester tester, String clave) =>
    tester.widget<Text>(find.byKey(ValueKey(clave))).data!;

Future<void> _pestana(WidgetTester tester, String clave) async {
  await tester.tap(find.byKey(ValueKey(clave)));
  // Los tests que cambian de pestaña no tienen el punto parpadeante: se puede esperar a que termine.
  await tester.pumpAndSettle();
}

void main() {
  group('cabecera', () {
    testWidgets('antes de empezar: fecha y hora, sin marcador y la hora como estado', (
      tester,
    ) async {
      final servicio = _ServicioFalso({30: _ficha()});
      await _pintar(tester, servicio);

      expect(_texto(tester, 'ficha-fecha'), '11/11/2026 • 21:00');
      expect(_texto(tester, 'ficha-marcador'), '-');
      expect(_texto(tester, 'ficha-competicion'), 'Segona FFCV, Grup 7 · Jornada 9');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ficha-estado')),
          matching: find.text('21:00'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('punto-en-directo')), findsNothing);
      // Sin goleadores en la cabecera.
      expect(find.text('Goleadores'), findsNothing);
    });

    testWidgets('en directo: marcador, "En directo" y el punto rojo que parpadea', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          cabecera: _cabecera(estado: EstadoFicha.enJuego, favor: 2, contra: 1),
        ),
      });
      await _pintar(tester, servicio);

      expect(_texto(tester, 'ficha-marcador'), '2 - 1');
      expect(find.text('En directo'), findsOneWidget);

      final punto = find.byKey(const ValueKey('punto-en-directo'));
      expect(punto, findsOneWidget);

      // Parpadea: la opacidad cambia con el tiempo.
      final antes = tester.widget<FadeTransition>(punto).opacity.value;
      await tester.pump(const Duration(milliseconds: 400));
      final despues = tester.widget<FadeTransition>(punto).opacity.value;
      expect(despues, isNot(antes));

      await _cerrar(tester);
    });

    testWidgets('descanso, finalizado y cancelado', (tester) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          cabecera: _cabecera(estado: EstadoFicha.descanso, favor: 1, contra: 0),
        ),
      });
      await _pintar(tester, servicio);
      expect(find.text('Descanso'), findsWidgets);
      expect(find.byKey(const ValueKey('punto-en-directo')), findsNothing);
      await _cerrar(tester);

      servicio.fichas[30] = _ficha(
        cabecera: _cabecera(estado: EstadoFicha.finalizado, favor: 3, contra: 0),
      );
      await _pintar(tester, servicio);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ficha-estado')),
          matching: find.text('Finalizado'),
        ),
        findsOneWidget,
      );
      expect(_texto(tester, 'ficha-marcador'), '3 - 0');
      await _cerrar(tester);

      servicio.fichas[30] = _ficha(
        cabecera: _cabecera(estado: EstadoFicha.cancelado),
      );
      await _pintar(tester, servicio);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ficha-estado')),
          matching: find.text('Cancelado'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('el Mutxamel va a la izquierda de local y a la derecha de visitante, con el marcador en ese orden', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          cabecera: _cabecera(
            estado: EstadoFicha.finalizado,
            local: false,
            favor: 2,
            contra: 1,
          ),
        ),
      });
      await _pintar(tester, servicio);

      // Visitante: el marcador se pinta local - visitante, o sea rival - Mutxamel.
      expect(_texto(tester, 'ficha-marcador'), '1 - 2');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ficha-equipo-visitante')),
          matching: find.byKey(const ValueKey('escudo-mutxamel')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ficha-equipo-local')),
          matching: find.byKey(const ValueKey('escudo-rival')),
        ),
        findsOneWidget,
      );
      expect(find.text('Pego C.F.'), findsOneWidget);
      expect(find.text('Mutxamel CF'), findsOneWidget);
    });

    testWidgets('de local: escudo del club a la izquierda y genérico a la derecha', (
      tester,
    ) async {
      await _pintar(tester, _ServicioFalso({30: _ficha()}));

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ficha-equipo-local')),
          matching: find.byKey(const ValueKey('escudo-mutxamel')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ficha-equipo-visitante')),
          matching: find.byKey(const ValueKey('escudo-rival')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('la cabecera no se desplaza con las pestañas ni al bajar la lista', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          eventos: [
            for (var i = 0; i < 30; i++)
              EventoFicha(
                tipo: EventoFicha.golFavor,
                minuto: i,
                jugador: 'J$i',
                golesFavor: 1,
                golesContra: 0,
              ),
          ],
        ),
      });
      await _pintar(tester, servicio);

      final antes = tester.getTopLeft(find.byKey(const ValueKey('ficha-cabecera')));

      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump();
      await _pestana(tester, 'pestana-alineacion');

      expect(
        tester.getTopLeft(find.byKey(const ValueKey('ficha-cabecera'))),
        antes,
      );
    });
  });

  group('detalle', () {
    List<EventoFicha> eventos() => const [
      EventoFicha(
        tipo: EventoFicha.finalPartido,
        golesFavor: 6,
        golesContra: 0,
        texto: 'Marcador final',
      ),
      EventoFicha(
        tipo: EventoFicha.tarjetaRoja,
        minuto: 80,
        jugador: 'Ana Ruiz',
        dobleAmarilla: true,
      ),
      EventoFicha(
        tipo: EventoFicha.cambio,
        minuto: 60,
        jugador: 'Luis',
        jugadorEntra: 'Pablito',
      ),
      EventoFicha(
        tipo: EventoFicha.golContra,
        minuto: 50,
        golesFavor: 3,
        golesContra: 1,
      ),
      EventoFicha(
        tipo: EventoFicha.golFavor,
        minuto: 46,
        jugador: 'Pepe',
        golesFavor: 3,
        golesContra: 0,
      ),
      EventoFicha(
        tipo: EventoFicha.descanso,
        golesFavor: 2,
        golesContra: 0,
        texto: 'Marcador al descanso',
      ),
      EventoFicha(
        tipo: EventoFicha.tarjetaAmarilla,
        minuto: 30,
        jugador: 'Juanma',
      ),
      EventoFicha(
        tipo: EventoFicha.golFavor,
        minuto: 12,
        jugador: 'Ana',
        golesFavor: 1,
        golesContra: 0,
      ),
    ];

    testWidgets('lo último arriba, con los separadores a lo ancho y los marcadores', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          cabecera: _cabecera(estado: EstadoFicha.finalizado, favor: 6, contra: 0),
          eventos: eventos(),
        ),
      });
      await _pintar(tester, servicio);

      // El orden de arriba abajo es el de la lista.
      final y = [
        for (var i = 0; i < 6; i++)
          tester.getTopLeft(find.byKey(ValueKey('evento-$i'))).dy,
      ];
      expect(y, orderedEquals([...y]..sort()));

      expect(find.text('Final 6-0'), findsOneWidget);
      expect(find.text('Descanso 2-0'), findsOneWidget);

      // Los separadores ocupan todo el ancho.
      expect(
        tester.getSize(find.byKey(const ValueKey('evento-0'))).width,
        400,
      );

      // Marcador del gol en la píldora; el minuto a un lado.
      expect(find.text('3-0'), findsOneWidget);
      expect(find.text("46'"), findsOneWidget);
      expect(find.text('Pepe'), findsOneWidget);
    });

    testWidgets('los nuestros a la izquierda y el gol del rival a la derecha (de local)', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          cabecera: _cabecera(estado: EstadoFicha.finalizado),
          eventos: eventos(),
        ),
      });
      await _pintar(tester, servicio);

      final centro = 200.0;

      expect(tester.getCenter(find.text('Pepe')).dx, lessThan(centro));
      expect(tester.getCenter(find.text('Gol del rival')).dx, greaterThan(centro));
    });

    testWidgets('de visitante los lados se invierten y el marcador va local - visitante', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          cabecera: _cabecera(estado: EstadoFicha.finalizado, local: false),
          eventos: eventos(),
        ),
      });
      await _pintar(tester, servicio);

      expect(tester.getCenter(find.text('Pepe')).dx, greaterThan(200));
      expect(tester.getCenter(find.text('Gol del rival')).dx, lessThan(200));
      // 3-0 a favor del Mutxamel, que es visitante: 0-3.
      expect(find.text('0-3'), findsOneWidget);
      expect(find.text('Final 0-6'), findsOneWidget);
      expect(find.text('Descanso 0-2'), findsOneWidget);
    });

    testWidgets('iconos: balón, flechas del cambio con "entra" en negrita y "sale" en gris, tarjetas', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          cabecera: _cabecera(estado: EstadoFicha.finalizado),
          eventos: eventos(),
        ),
      });
      await _pintar(tester, servicio);

      expect(find.byKey(const ValueKey('icono-gol')), findsWidgets);
      expect(find.byKey(const ValueKey('icono-cambio')), findsOneWidget);
      expect(find.byKey(const ValueKey('tarjeta-roja')), findsOneWidget);
      // Una amarilla sola (la del jugador del minuto 30) y, en la doble amarilla, 2 amarillas + 1 roja juntas.
      expect(find.byKey(const ValueKey('tarjeta-amarilla')), findsNWidgets(3));
      expect(
        find.byKey(const ValueKey('tarjetas-doble-amarilla')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.sports), findsNWidgets(2));

      final entra = tester.widget<Text>(find.byKey(const ValueKey('cambio-entra')));
      final sale = tester.widget<Text>(find.byKey(const ValueKey('cambio-sale')));
      expect(entra.data, 'Pablito');
      expect(entra.style!.fontWeight, FontWeight.bold);
      expect(sale.data, 'Luis');
      expect(sale.style!.fontWeight, isNot(FontWeight.bold));
      expect(sale.style!.color, isNot(entra.style!.color));

      // La doble amarilla se ve como la expulsión.
      expect(find.text('Doble amarilla'), findsOneWidget);
    });

    testWidgets('sin eventos: "Este partido no se ha retransmitido"', (tester) async {
      await _pintar(tester, _ServicioFalso({30: _ficha()}));

      expect(find.text('Este partido no se ha retransmitido'), findsOneWidget);
    });
  });

  group('alineación', () {
    List<TitularFicha> once(List<(int, int)> posiciones) => [
      for (var i = 0; i < posiciones.length; i++)
        TitularFicha(
          dorsal: i + 1,
          nombre: 'Jugador ${i + 1}',
          fila: posiciones[i].$1,
          columna: posiciones[i].$2,
        ),
    ];

    final f442 = [
      (1, 1),
      (2, 1), (2, 2), (2, 3), (2, 4),
      (3, 1), (3, 2), (3, 3), (3, 4),
      (4, 1), (4, 2),
    ];
    final f451 = [
      (1, 1),
      (2, 1), (2, 2), (2, 3), (2, 4),
      (3, 1), (3, 2), (3, 3), (3, 4), (3, 5),
      (4, 1),
    ];

    Offset centro(WidgetTester tester, int fila, int columna) =>
        tester.getCenter(find.byKey(ValueKey('posicion-$fila-$columna')));

    testWidgets('4-4-2: el campo con el portero abajo, las líneas hacia arriba y la formación arriba a la derecha', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          alineacion: AlineacionFicha(formacion: '4-4-2', titulares: once(f442)),
        ),
      });
      await _pintar(tester, servicio);
      await _pestana(tester, 'pestana-alineacion');

      expect(find.byKey(const ValueKey('campo-pintado')), findsOneWidget);
      expect(_texto(tester, 'campo-formacion'), '4-4-2');

      // La formación sale arriba a la derecha del campo.
      final campo = tester.getRect(find.byKey(const ValueKey('campo-pintado')));
      final etiqueta = tester.getCenter(find.byKey(const ValueKey('campo-formacion')));
      expect(etiqueta.dx, greaterThan(campo.center.dx));
      expect(etiqueta.dy, lessThan(campo.center.dy));

      // Portero más abajo; cada línea más arriba que la anterior.
      expect(centro(tester, 1, 1).dy, greaterThan(centro(tester, 2, 1).dy));
      expect(centro(tester, 2, 1).dy, greaterThan(centro(tester, 3, 1).dy));
      expect(centro(tester, 3, 1).dy, greaterThan(centro(tester, 4, 1).dy));

      // La misma línea comparte altura y las columnas van de izquierda a derecha.
      for (var c = 1; c < 4; c++) {
        expect(centro(tester, 2, c).dy, centro(tester, 2, c + 1).dy);
        expect(centro(tester, 2, c).dx, lessThan(centro(tester, 2, c + 1).dx));
      }

      // 11 jugadores con su dorsal y su nombre en directo.
      expect(find.byKey(const ValueKey('titular-Jugador 1')), findsOneWidget);
      for (var i = 1; i <= 11; i++) {
        expect(find.text('Jugador $i'), findsOneWidget);
      }
      expect(find.text('11'), findsOneWidget);
    });

    testWidgets('4-5-1: cinco medios en la tercera fila y un solo delantero centrado', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          alineacion: AlineacionFicha(formacion: '4-5-1', titulares: once(f451)),
        ),
      });
      await _pintar(tester, servicio);
      await _pestana(tester, 'pestana-alineacion');

      expect(_texto(tester, 'campo-formacion'), '4-5-1');

      final medios = [for (var c = 1; c <= 5; c++) centro(tester, 3, c)];
      expect(medios.map((o) => o.dy).toSet(), hasLength(1));
      for (var i = 0; i < 4; i++) {
        expect(medios[i].dx, lessThan(medios[i + 1].dx));
      }

      // El delantero solo, en el centro del campo.
      final campo = tester.getRect(find.byKey(const ValueKey('campo-pintado')));
      expect(centro(tester, 4, 1).dx, closeTo(campo.center.dx, 1));
      expect(find.byKey(const ValueKey('posicion-4-2')), findsNothing);
    });

    testWidgets('sustituido y tarjetas: icono de cambio y tarjeta en el campo', (
      tester,
    ) async {
      final titulares = once(f442);
      titulares[1] = const TitularFicha(
        dorsal: 2,
        nombre: 'Jugador 2',
        fila: 2,
        columna: 1,
        sustituido: true,
        minutoSustitucion: 60,
      );
      titulares[2] = const TitularFicha(
        dorsal: 3,
        nombre: 'Jugador 3',
        fila: 2,
        columna: 2,
        tarjetas: [TarjetaFicha(color: 'ROJA', minuto: 70)],
      );

      final servicio = _ServicioFalso({
        30: _ficha(
          alineacion: AlineacionFicha(formacion: '4-4-2', titulares: titulares),
        ),
      });
      await _pintar(tester, servicio);
      await _pestana(tester, 'pestana-alineacion');

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('titular-Jugador 2')),
          matching: find.byKey(const ValueKey('insignia-cambio')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('titular-Jugador 3')),
          matching: find.byKey(const ValueKey('tarjeta-roja')),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('insignia-cambio')), findsOneWidget);
    });

    testWidgets('suplentes con y sin foto, y el que entró con su icono y su minuto', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          alineacion: AlineacionFicha(
            formacion: '4-4-2',
            titulares: once(f442),
            suplentes: const [
              SuplenteFicha(
                dorsal: 12,
                nombre: 'Mayor Con Foto',
                fotoBase64: _foto,
              ),
              SuplenteFicha(dorsal: 13, nombre: 'Menor Sin Foto'),
              SuplenteFicha(
                dorsal: 14,
                nombre: 'Entro Ya',
                entro: true,
                minutoEntrada: 60,
                tarjetas: [TarjetaFicha(color: 'AMARILLA', minuto: 75)],
              ),
            ],
          ),
        ),
      });
      await _pintar(tester, servicio);
      await _pestana(tester, 'pestana-alineacion');

      await tester.ensureVisible(find.byKey(const ValueKey('ficha-suplentes')));
      await tester.pump();

      expect(find.text('Suplentes'), findsOneWidget);

      Finder fila(String nombre) => find.byKey(ValueKey('jugador-$nombre'));

      expect(
        find.descendant(
          of: fila('Mayor Con Foto'),
          matching: find.byKey(const ValueKey('foto-jugador')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: fila('Menor Sin Foto'),
          matching: find.byKey(const ValueKey('avatar-jugador')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: fila('Menor Sin Foto'),
          matching: find.byKey(const ValueKey('foto-jugador')),
        ),
        findsNothing,
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Mayor Con Foto'), findsOneWidget);

      expect(
        find.descendant(
          of: fila('Entro Ya'),
          matching: find.byKey(const ValueKey('marca-entra')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: fila('Entro Ya'), matching: find.text("60'")),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: fila('Entro Ya'),
          matching: find.byKey(const ValueKey('tarjeta-amarilla')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: fila('Mayor Con Foto'),
          matching: find.byKey(const ValueKey('marca-entra')),
        ),
        findsNothing,
      );
    });

    testWidgets('titulares con foto de mayor de edad y avatar de menor en el campo', (
      tester,
    ) async {
      final titulares = once(f442);
      titulares[0] = const TitularFicha(
        dorsal: 1,
        nombre: 'Jugador 1',
        fila: 1,
        columna: 1,
        fotoBase64: _foto,
      );

      final servicio = _ServicioFalso({
        30: _ficha(
          alineacion: AlineacionFicha(formacion: '4-4-2', titulares: titulares),
        ),
      });
      await _pintar(tester, servicio);
      await _pestana(tester, 'pestana-alineacion');

      expect(find.byKey(const ValueKey('foto-jugador')), findsOneWidget);
      expect(find.byKey(const ValueKey('avatar-jugador')), findsNWidgets(10));
    });

    testWidgets('una foto que no se puede leer se sustituye por el avatar', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          alineacion: const AlineacionFicha(
            titulares: [TitularFicha(nombre: 'Roto', fotoBase64: '%%%no%%%')],
          ),
        ),
      });
      await _pintar(tester, servicio);
      await _pestana(tester, 'pestana-alineacion');

      expect(find.byKey(const ValueKey('avatar-jugador')), findsOneWidget);
    });

    testWidgets('sin formación no hay campo: los titulares salen en lista', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          alineacion: const AlineacionFicha(
            titulares: [
              TitularFicha(dorsal: 1, nombre: 'Uno'),
              TitularFicha(dorsal: 2, nombre: 'Dos'),
            ],
          ),
        ),
      });
      await _pintar(tester, servicio);
      await _pestana(tester, 'pestana-alineacion');

      expect(find.byKey(const ValueKey('campo-pintado')), findsNothing);
      expect(find.text('Uno'), findsOneWidget);
      expect(find.text('Dos'), findsOneWidget);
    });

    testWidgets('sin alineación: "Sin alineación"', (tester) async {
      await _pintar(tester, _ServicioFalso({30: _ficha()}));
      await _pestana(tester, 'pestana-alineacion');

      expect(find.text('Sin alineación'), findsOneWidget);
      expect(find.byKey(const ValueKey('campo-pintado')), findsNothing);
    });
  });

  group('doble amarilla', () {
    testWidgets('en el detalle: 2 amarillas y 1 roja juntas, en ese orden, con el texto debajo', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          eventos: const [
            EventoFicha(
              tipo: EventoFicha.tarjetaRoja,
              minuto: 80,
              jugador: 'Ana Ruiz',
              dobleAmarilla: true,
            ),
            EventoFicha(
              tipo: EventoFicha.tarjetaAmarilla,
              minuto: 40,
              jugador: 'Ana Ruiz',
            ),
          ],
        ),
      });
      await _pintar(tester, servicio);

      final grupo = find.byKey(const ValueKey('tarjetas-doble-amarilla'));
      expect(grupo, findsOneWidget);

      final colores = [
        for (final e in tester.widgetList<Container>(
          find.descendant(of: grupo, matching: find.byType(Container)),
        ))
          (e.decoration as BoxDecoration).color,
      ];
      expect(colores, [
        const Color(0xFFF2C500),
        const Color(0xFFF2C500),
        const Color(0xFFD62828),
      ]);
      expect(find.text('Doble amarilla'), findsOneWidget);

      // La primera amarilla sigue saliendo sola, en su minuto.
      expect(
        find.descendant(of: grupo, matching: find.byKey(const ValueKey('tarjeta-roja'))),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('tarjeta-amarilla')), findsNWidgets(3));
      expect(find.text("40'"), findsOneWidget);
    });

    testWidgets('en la alineación: el titular en el campo y el suplente, sin la amarilla suelta', (
      tester,
    ) async {
      const doble = [
        TarjetaFicha(color: 'AMARILLA', minuto: 20),
        TarjetaFicha(color: 'ROJA', minuto: 70, dobleAmarilla: true),
      ];
      final servicio = _ServicioFalso({
        30: _ficha(
          alineacion: const AlineacionFicha(
            formacion: '4-4-2',
            titulares: [
              TitularFicha(dorsal: 1, nombre: 'Jugador 1', fila: 1, columna: 1),
              TitularFicha(
                dorsal: 2,
                nombre: 'Jugador 2',
                fila: 2,
                columna: 1,
                tarjetas: doble,
              ),
            ],
            suplentes: [
              SuplenteFicha(dorsal: 12, nombre: 'Suplente Doble', tarjetas: doble),
            ],
          ),
        ),
      });
      await _pintar(tester, servicio);
      await _pestana(tester, 'pestana-alineacion');

      await tester.ensureVisible(find.byKey(const ValueKey('ficha-suplentes')));
      await tester.pump();

      final enCampo = find.descendant(
        of: find.byKey(const ValueKey('titular-Jugador 2')),
        matching: find.byKey(const ValueKey('tarjetas-doble-amarilla')),
      );
      final enLista = find.descendant(
        of: find.byKey(const ValueKey('jugador-Suplente Doble')),
        matching: find.byKey(const ValueKey('tarjetas-doble-amarilla')),
      );
      expect(enCampo, findsOneWidget);
      expect(enLista, findsOneWidget);

      // Ni una amarilla suelta ni una roja suelta: solo las del grupo (2 amarillas + 1 roja cada uno).
      expect(find.byKey(const ValueKey('tarjeta-amarilla')), findsNWidgets(4));
      expect(find.byKey(const ValueKey('tarjeta-roja')), findsNWidgets(2));
    });
  });

  group('nombre de la pestaña de los últimos partidos', () {
    testWidgets('es "Últ. partidos" en castellano', (tester) async {
      await _pintar(tester, _ServicioFalso({30: _ficha()}));

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pestana-forma')),
          matching: find.text('Últ. partidos'),
        ),
        findsOneWidget,
      );
      expect(find.text('Forma del equipo'), findsNothing);
    });

    test('en catalán e inglés', () {
      expect(lookupAppLocalizations(const Locale('ca')).fichaTabForm, 'Últ. partits');
      expect(lookupAppLocalizations(const Locale('en')).fichaTabForm, 'Last matches');
    });
  });

  group('forma del equipo', () {
    List<FormaFicha> forma() => [
      FormaFicha(
        partidoId: 44,
        dia: DateTime(2026, 11, 6),
        local: false,
        rival: 'Villena',
        golesFavor: 1,
        golesContra: 2,
        resultado: 'P',
      ),
      FormaFicha(
        partidoId: 43,
        dia: DateTime(2026, 10, 30),
        local: true,
        rival: 'Elche B',
        golesFavor: 4,
        golesContra: 1,
        resultado: 'G',
      ),
      FormaFicha(
        partidoId: 42,
        dia: DateTime(2026, 10, 23),
        local: true,
        rival: 'Torrevieja',
        golesFavor: 1,
        golesContra: 1,
        resultado: 'E',
      ),
    ];

    Color colorPildora(WidgetTester tester, int id) {
      final contenedor = tester.widget<Container>(
        find.byKey(ValueKey('forma-resultado-$id')),
      );
      return (contenedor.decoration as BoxDecoration).color!;
    }

    testWidgets('una fila por partido con la píldora verde, gris o roja según el resultado', (
      tester,
    ) async {
      final servicio = _ServicioFalso({30: _ficha(forma: forma())});
      await _pintar(tester, servicio);
      await _pestana(tester, 'pestana-forma');

      expect(colorPildora(tester, 43), FichaForma.verde);
      expect(colorPildora(tester, 42), FichaForma.gris);
      expect(colorPildora(tester, 44), FichaForma.rojo);

      // Más reciente arriba.
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('forma-44'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('forma-43'))).dy),
      );
    });

    testWidgets('el Mutxamel en casa o fuera según se jugó, con el marcador en ese orden', (
      tester,
    ) async {
      final servicio = _ServicioFalso({30: _ficha(forma: forma())});
      await _pintar(tester, servicio);
      await _pestana(tester, 'pestana-forma');

      Finder escudoClub(int id) => find.descendant(
        of: find.byKey(ValueKey('forma-$id')),
        matching: find.byKey(const ValueKey('escudo-mutxamel')),
      );

      // En casa (43): el escudo del club a la izquierda de la píldora, y 4-1.
      expect(
        tester.getCenter(escudoClub(43)).dx,
        lessThan(tester.getCenter(find.byKey(const ValueKey('forma-resultado-43'))).dx),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('forma-resultado-43')),
          matching: find.text('4 - 1'),
        ),
        findsOneWidget,
      );

      // Fuera (44): el escudo del club a la derecha y el marcador al revés: perdió 1-2 → 2 - 1.
      expect(
        tester.getCenter(escudoClub(44)).dx,
        greaterThan(tester.getCenter(find.byKey(const ValueKey('forma-resultado-44'))).dx),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('forma-resultado-44')),
          matching: find.text('2 - 1'),
        ),
        findsOneWidget,
      );

      // Debajo, la fecha y el rival en pequeño.
      expect(find.text('06/11/2026 · Villena'), findsOneWidget);
    });

    testWidgets('tocar una fila abre la ficha de ese partido', (tester) async {
      final servicio = _ServicioFalso({
        30: _ficha(forma: forma()),
        43: _ficha(
          cabecera: _cabecera(
            id: 43,
            estado: EstadoFicha.finalizado,
            favor: 4,
            contra: 1,
          ),
        ),
      });
      await _pintar(tester, servicio);
      await _pestana(tester, 'pestana-forma');

      await tester.tap(find.byKey(const ValueKey('forma-43')));
      await tester.pump(const Duration(milliseconds: 400));
      await _asentar(tester);

      expect(servicio.llamadas, [30, 43]);
      expect(find.byType(FichaPartidoPage), findsNWidgets(2));
      // La ficha nueva queda encima de la anterior.
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('ficha-marcador')).last)
            .data,
        '4 - 1',
      );
    });

    testWidgets('sin partidos con resultado lo dice', (tester) async {
      await _pintar(tester, _ServicioFalso({30: _ficha()}));
      await _pestana(tester, 'pestana-forma');

      expect(find.text('Todavía no hay partidos con resultado'), findsOneWidget);
    });
  });

  group('actualización', () {
    _ServicioFalso enJuego() => _ServicioFalso({
      30: _ficha(
        cabecera: _cabecera(estado: EstadoFicha.enJuego, favor: 1, contra: 0),
      ),
    });

    testWidgets('en juego se recarga cada 30 segundos', (tester) async {
      final servicio = enJuego();
      await _pintar(tester, servicio);

      expect(servicio.llamadas, hasLength(1));

      await tester.pump(const Duration(seconds: 30));
      expect(servicio.llamadas, hasLength(2));

      await tester.pump(const Duration(seconds: 30));
      expect(servicio.llamadas, hasLength(3));

      await _cerrar(tester);
    });

    testWidgets('el temporizador se para cuando el partido termina', (tester) async {
      final servicio = enJuego();
      await _pintar(tester, servicio);

      servicio.fichas[30] = _ficha(
        cabecera: _cabecera(estado: EstadoFicha.finalizado, favor: 2, contra: 0),
      );

      await tester.pump(const Duration(seconds: 30));
      await _asentar(tester);
      expect(servicio.llamadas, hasLength(2));
      expect(find.text('Finalizado'), findsOneWidget);

      await tester.pump(const Duration(seconds: 120));
      expect(servicio.llamadas, hasLength(2));
    });

    testWidgets('en el descanso también se recarga', (tester) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          cabecera: _cabecera(estado: EstadoFicha.descanso, favor: 1, contra: 0),
        ),
      });
      await _pintar(tester, servicio);

      await tester.pump(const Duration(seconds: 30));

      expect(servicio.llamadas, hasLength(2));

      await _cerrar(tester);
    });

    testWidgets('un partido que no se está jugando no arranca el temporizador', (
      tester,
    ) async {
      final servicio = _ServicioFalso({
        30: _ficha(
          cabecera: _cabecera(estado: EstadoFicha.finalizado, favor: 1, contra: 0),
        ),
      });
      await _pintar(tester, servicio);

      await tester.pump(const Duration(seconds: 90));

      expect(servicio.llamadas, hasLength(1));
    });

    testWidgets('al salir de la pantalla se para', (tester) async {
      final servicio = enJuego();
      await _pintar(tester, servicio);

      await _cerrar(tester);
      await tester.pump(const Duration(seconds: 90));

      expect(servicio.llamadas, hasLength(1));
    });

    testWidgets('en segundo plano no se pide nada y al volver se actualiza al momento', (
      tester,
    ) async {
      final servicio = enJuego();
      await _pintar(tester, servicio);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 90));
      expect(servicio.llamadas, hasLength(1));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _asentar(tester);
      expect(servicio.llamadas, hasLength(2));

      await tester.pump(const Duration(seconds: 30));
      expect(servicio.llamadas, hasLength(3));

      await _cerrar(tester);
    });

    testWidgets('un push del directo la recarga al momento mientras se juega', (
      tester,
    ) async {
      final avisos = StreamController<void>.broadcast();
      addTearDown(avisos.close);

      final servicio = enJuego();
      await _pintar(tester, servicio, avisos: avisos.stream);

      avisos.add(null);
      await _asentar(tester);

      expect(servicio.llamadas, hasLength(2));

      await _cerrar(tester);
    });

    testWidgets('un push con el partido terminado no recarga', (tester) async {
      final avisos = StreamController<void>.broadcast();
      addTearDown(avisos.close);

      final servicio = _ServicioFalso({
        30: _ficha(
          cabecera: _cabecera(estado: EstadoFicha.finalizado, favor: 1, contra: 0),
        ),
      });
      await _pintar(tester, servicio, avisos: avisos.stream);

      avisos.add(null);
      await _asentar(tester);

      expect(servicio.llamadas, hasLength(1));
    });

    testWidgets('si una recarga falla se queda lo que se veía', (tester) async {
      final servicio = enJuego();
      await _pintar(tester, servicio);

      servicio.error = const ApiException('sin red');
      await tester.pump(const Duration(seconds: 30));
      await _asentar(tester);

      expect(_texto(tester, 'ficha-marcador'), '1 - 0');
      expect(find.byKey(const ValueKey('ficha-error')), findsNothing);

      await _cerrar(tester);
    });

    testWidgets('tirar para refrescar vuelve a pedir la ficha', (tester) async {
      final servicio = _ServicioFalso({30: _ficha()});
      await _pintar(tester, servicio);

      await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(servicio.llamadas.length, greaterThanOrEqualTo(2));
    });

    testWidgets('pide la ficha en el idioma de la app', (tester) async {
      final servicio = _ServicioFalso({30: _ficha()});
      await _pintar(tester, servicio, locale: const Locale('ca'));

      expect(servicio.idiomas, ['ca']);
      expect(find.text('Detall'), findsOneWidget);
    });
  });

  group('errores', () {
    testWidgets('un 404 dice que la ficha es solo del Primer Equipo, sin reintento', (
      tester,
    ) async {
      final servicio = _ServicioFalso({})
        ..error = const ApiException('no', statusCode: 404);
      await _pintar(tester, servicio);

      expect(
        find.text('La ficha solo está disponible para los partidos del Primer Equipo.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('otro fallo permite reintentar', (tester) async {
      final servicio = _ServicioFalso({30: _ficha()})
        ..error = const ApiException('sin red');
      await _pintar(tester, servicio);

      expect(find.text('No se ha podido cargar la ficha del partido.'), findsOneWidget);

      servicio.error = null;
      await tester.tap(find.text('Reintentar'));
      await _asentar(tester);

      expect(find.byKey(const ValueKey('ficha-cabecera')), findsOneWidget);
    });
  });

  group('servicio y modelo', () {
    test('pide GET /public/partidos/{id}/ficha sin sesión y con Accept-Language', () async {
      http.Request? peticion;

      final ficha = await conMockHttp((request) async {
        peticion = request;
        return http.Response(
          '''{"cabecera":{"partidoId":30,"equipoLocal":"Mutxamel CF","equipoVisitante":"Pego C.F.",
              "dia":"2026-11-08","hora":"18:00","golesFavor":2,"golesContra":1,"estado":"EN_JUEGO",
              "competicion":"Preferente Valenciana · Jornada 9"},
             "eventos":[{"tipo":"GOL_FAVOR","minuto":12,"jugador":"Pablito","jugadorEntra":null,
                "golesFavor":1,"golesContra":0,"texto":null,"dobleAmarilla":false}],
             "alineacion":{"formacion":"4-4-2","titulares":[{"dorsal":1,"nombre":"Pablito","fila":1,
                "columna":1,"sustituido":true,"minutoSustitucion":60,
                "tarjetas":[{"color":"AMARILLA","minuto":20,"dobleAmarilla":false}],"fotoBase64":null}],
                "suplentes":[{"dorsal":20,"nombre":"Mayorcito","entro":true,"minutoEntrada":60,
                "tarjetas":[],"fotoBase64":"abc"}]},
             "forma":[{"partidoId":44,"dia":"2026-11-06","local":false,"rival":"R5","golesFavor":1,
                "golesContra":2,"resultado":"P"}]}''',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }, () => FichaPartidoService().obtenerFicha(30, idioma: 'ca'));

      expect(peticion!.method, 'GET');
      expect(peticion!.url.path, endsWith('/public/partidos/30/ficha'));
      expect(peticion!.headers['Accept-Language'], 'ca');
      expect(peticion!.headers.containsKey('Authorization'), isFalse);

      expect(ficha.cabecera.estado, EstadoFicha.enJuego);
      expect(ficha.cabecera.mutxamelEsLocal, isTrue);
      expect(ficha.cabecera.rival, 'Pego C.F.');
      expect(ficha.cabecera.dia, DateTime(2026, 11, 8));
      expect(ficha.eventos.single.jugador, 'Pablito');
      expect(ficha.alineacion.formacion, '4-4-2');
      expect(ficha.alineacion.tienePosiciones, isTrue);
      expect(ficha.alineacion.titulares.single.sustituido, isTrue);
      expect(ficha.alineacion.titulares.single.tarjetas.single.esRoja, isFalse);
      expect(ficha.alineacion.suplentes.single.entro, isTrue);
      expect(ficha.forma.single.resultado, 'P');
      expect(ficha.forma.single.golesLocal, 2);
      expect(ficha.forma.single.golesVisitante, 1);
    });

    test('sin idioma no se manda Accept-Language y un 404 llega como ApiException', () async {
      http.Request? peticion;

      await expectLater(
        conMockHttp((request) async {
          peticion = request;
          return http.Response('', 404);
        }, () => FichaPartidoService().obtenerFicha(31)),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );

      expect(peticion!.headers.containsKey('Accept-Language'), isFalse);
    });

    test('los campos que faltan no rompen la lectura', () {
      final ficha = FichaPartido.fromJson({
        'cabecera': {'partidoId': 1},
      });

      expect(ficha.eventos, isEmpty);
      expect(ficha.alineacion.vacia, isTrue);
      expect(ficha.cabecera.estado, EstadoFicha.proximo);
      expect(ficha.forma, isEmpty);
    });
  });
}

