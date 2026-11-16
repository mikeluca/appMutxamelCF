import 'dart:typed_data';

import 'package:app_mutxamel_cf/features/directo/widgets/compartir_partido.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/reloj_directo.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/pages/ficha_partido_page.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/services/ficha_partido_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

CabeceraFicha _cabecera({
  EstadoFicha estado = EstadoFicha.proximo,
  bool local = true,
  int? favor,
  int? contra,
  RelojDirecto? reloj,
  String? hora = '18:00',
}) => CabeceraFicha(
  partidoId: 30,
  equipoLocal: local ? 'Mutxamel CF' : 'Pego C.F.',
  equipoVisitante: local ? 'Pego C.F.' : 'Mutxamel CF',
  dia: DateTime(2026, 11, 14),
  hora: hora,
  golesFavor: favor,
  golesContra: contra,
  estado: estado,
  competicion: 'Preferente Valenciana · Jornada 9',
  reloj: reloj,
);

/// Los datos de compartir de [c] con los textos en [locale].
Future<DatosCompartir> _datos(
  WidgetTester tester,
  CabeceraFicha c, {
  Locale locale = const Locale('es'),
  DateTime? ahora,
}) async {
  late DatosCompartir datos;

  await tester.pumpWidget(
    appCon(
      Builder(
        builder: (context) {
          datos = DatosCompartir.desdeCabecera(
            c,
            AppLocalizations.of(context),
            ahora: ahora ?? DateTime(2026, 11, 14, 19),
          );
          return const SizedBox();
        },
      ),
      locale: locale,
    ),
  );

  return datos;
}

Future<void> _pintarTarjeta(WidgetTester tester, DatosCompartir datos) async {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    appCon(Center(child: TarjetaCompartir(datos: datos))),
  );
}

String _texto(WidgetTester tester, String clave) =>
    tester.widget<Text>(find.byKey(ValueKey(clave))).data!;

void main() {
  group('lo que lleva la imagen y el texto, en cada estado', () {
    testWidgets('final: marcador, "Final" y el texto corto', (tester) async {
      final d = await _datos(
        tester,
        _cabecera(estado: EstadoFicha.finalizado, favor: 2, contra: 1),
      );

      expect(d.marcador, '2 - 1');
      expect(d.estado, 'Final');
      expect(d.texto, 'Mutxamel CF 2-1 Pego C.F. · Final');
      expect(d.competicion, 'Preferente Valenciana · Jornada 9');
      expect(d.fecha, '14/11/2026');
    });

    testWidgets('de visitante, el marcador va con el local a la izquierda', (
      tester,
    ) async {
      final d = await _datos(
        tester,
        _cabecera(
          estado: EstadoFicha.finalizado,
          local: false,
          favor: 2,
          contra: 1,
        ),
      );

      expect(d.marcador, '1 - 2');
      expect(d.texto, 'Pego C.F. 1-2 Mutxamel CF · Final');
      expect(d.mutxamelEsLocal, isFalse);
    });

    testWidgets('descanso', (tester) async {
      final d = await _datos(
        tester,
        _cabecera(estado: EstadoFicha.descanso, favor: 1, contra: 1),
      );

      expect(d.estado, 'Descanso');
      expect(d.texto, 'Mutxamel CF 1-1 Pego C.F. · Descanso');
    });

    testWidgets('en juego: el minuto del reloj ("67\'")', (tester) async {
      final ahora = DateTime(2026, 11, 14, 19);
      final reloj = RelojDirecto(
        fase: FaseReloj.segundaParte,
        inicioParteEpochMs: ahora
            .subtract(const Duration(minutes: 22, seconds: 30))
            .millisecondsSinceEpoch,
        minutoBase: 45,
        ahoraServidorEpochMs: ahora.millisecondsSinceEpoch,
        recibidoEn: ahora,
      );

      final d = await _datos(
        tester,
        _cabecera(
          estado: EstadoFicha.enJuego,
          favor: 2,
          contra: 1,
          reloj: reloj,
        ),
        ahora: ahora,
      );

      expect(d.estado, "67'");
      expect(d.texto, "Mutxamel CF 2-1 Pego C.F. · 67'");
    });

    testWidgets('en juego sin reloj (backend antiguo): "En directo"', (
      tester,
    ) async {
      final d = await _datos(
        tester,
        _cabecera(estado: EstadoFicha.enJuego, favor: 0, contra: 0),
      );

      expect(d.estado, 'En directo');
      expect(d.marcador, '0 - 0');
    });

    testWidgets('antes del partido: día y hora, y "VS" en lugar del marcador', (
      tester,
    ) async {
      final d = await _datos(tester, _cabecera());

      expect(d.marcador, 'VS');
      expect(d.estado, '14/11/2026 · 18:00');
      expect(d.texto, 'Mutxamel CF - Pego C.F. · 14/11/2026 · 18:00');
    });

    testWidgets('antes del partido sin hora: solo el día', (tester) async {
      final d = await _datos(tester, _cabecera(hora: null));

      expect(d.estado, '14/11/2026');
    });

    testWidgets('cancelado', (tester) async {
      final d = await _datos(
        tester,
        _cabecera(estado: EstadoFicha.cancelado),
      );

      expect(d.estado, 'Cancelado');
      expect(d.marcador, 'VS');
    });

    testWidgets('el texto va en el idioma de la app', (tester) async {
      final c = _cabecera(estado: EstadoFicha.finalizado, favor: 2, contra: 1);

      expect(
        (await _datos(tester, c, locale: const Locale('en'))).texto,
        'Mutxamel CF 2-1 Pego C.F. · Full time',
      );
      expect(
        (await _datos(tester, c, locale: const Locale('ca'))).texto,
        'Mutxamel CF 2-1 Pego C.F. · Final',
      );
    });
  });

  group('la tarjeta', () {
    testWidgets('es cuadrada de 1080x1080', (tester) async {
      await _pintarTarjeta(tester, await _datos(tester, _cabecera()));
      await _pintarTarjeta(
        tester,
        await _datos(
          tester,
          _cabecera(estado: EstadoFicha.finalizado, favor: 2, contra: 1),
        ),
      );

      final tamano = tester.getSize(find.byKey(const ValueKey('tarjeta-compartir')));

      expect(tamano, const Size(1080, 1080));
    });

    testWidgets('final: escudo del Mutxamel a la izquierda y genérico a la derecha, marcador, estado, competición y pie', (
      tester,
    ) async {
      await _pintarTarjeta(
        tester,
        await _datos(
          tester,
          _cabecera(estado: EstadoFicha.finalizado, favor: 2, contra: 1),
        ),
      );

      expect(_texto(tester, 'compartir-marcador'), '2 - 1');
      expect(_texto(tester, 'compartir-estado'), 'Final');
      expect(
        _texto(tester, 'compartir-competicion'),
        'Preferente Valenciana · Jornada 9 · 14/11/2026',
      );
      expect(_texto(tester, 'compartir-pie'), 'Síguelo en la app del Mutxamel CF');
      expect(find.text('Mutxamel CF'), findsOneWidget);
      expect(find.text('Pego C.F.'), findsOneWidget);

      final escudo = tester.getCenter(find.byKey(const ValueKey('escudo-mutxamel')));
      final generico = tester.getCenter(find.byKey(const ValueKey('escudo-rival')));

      expect(escudo.dx, lessThan(generico.dx));
    });

    testWidgets('de visitante el escudo del Mutxamel va a la derecha', (
      tester,
    ) async {
      await _pintarTarjeta(
        tester,
        await _datos(
          tester,
          _cabecera(
            estado: EstadoFicha.finalizado,
            local: false,
            favor: 2,
            contra: 1,
          ),
        ),
      );

      final escudo = tester.getCenter(find.byKey(const ValueKey('escudo-mutxamel')));
      final generico = tester.getCenter(find.byKey(const ValueKey('escudo-rival')));

      expect(escudo.dx, greaterThan(generico.dx));
      expect(_texto(tester, 'compartir-marcador'), '1 - 2');
    });

    testWidgets('en juego, descanso y antes del partido', (tester) async {
      final ahora = DateTime(2026, 11, 14, 19);
      final reloj = RelojDirecto(
        fase: FaseReloj.primeraParte,
        inicioParteEpochMs: ahora
            .subtract(const Duration(minutes: 12))
            .millisecondsSinceEpoch,
        ahoraServidorEpochMs: ahora.millisecondsSinceEpoch,
        recibidoEn: ahora,
      );

      await _pintarTarjeta(
        tester,
        await _datos(
          tester,
          _cabecera(
            estado: EstadoFicha.enJuego,
            favor: 1,
            contra: 0,
            reloj: reloj,
          ),
          ahora: ahora,
        ),
      );
      expect(_texto(tester, 'compartir-estado'), "12'");
      expect(_texto(tester, 'compartir-marcador'), '1 - 0');

      await _pintarTarjeta(
        tester,
        await _datos(
          tester,
          _cabecera(estado: EstadoFicha.descanso, favor: 1, contra: 1),
        ),
      );
      expect(_texto(tester, 'compartir-estado'), 'Descanso');

      await _pintarTarjeta(tester, await _datos(tester, _cabecera()));
      expect(_texto(tester, 'compartir-marcador'), 'VS');
      expect(_texto(tester, 'compartir-estado'), '14/11/2026 · 18:00');
    });

    testWidgets('sin fotos de jugadores ni nada personal: solo nombres de equipos, marcador y textos', (
      tester,
    ) async {
      await _pintarTarjeta(
        tester,
        await _datos(
          tester,
          _cabecera(estado: EstadoFicha.finalizado, favor: 2, contra: 1),
        ),
      );

      expect(find.byKey(const ValueKey('foto-jugador')), findsNothing);
      expect(find.byKey(const ValueKey('avatar-jugador')), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('en inglés el pie y el estado van en inglés', (tester) async {
      await _pintarTarjeta(
        tester,
        await _datos(
          tester,
          _cabecera(estado: EstadoFicha.finalizado, favor: 2, contra: 1),
          locale: const Locale('en'),
        ),
      );
      // La tarjeta se pinta en español (la app de test); el pie sale del idioma de la app.
      expect(find.byKey(const ValueKey('compartir-pie')), findsOneWidget);
    });
  });

  group('generar la imagen y compartirla', () {
    testWidgets('la imagen sale como PNG de 1080x1080', (tester) async {
      pantalla(tester);
      late BuildContext contexto;

      await tester.pumpWidget(
        appCon(
          Builder(
            builder: (context) {
              contexto = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final datos = await _datos(
        tester,
        _cabecera(estado: EstadoFicha.finalizado, favor: 2, contra: 1),
      );

      await tester.pumpWidget(
        appCon(
          Builder(
            builder: (context) {
              contexto = context;
              return const SizedBox();
            },
          ),
        ),
      );

      late Future<Uint8List> futuro;

      await tester.runAsync(() async {
        futuro = CompartirPartido.generarPng(contexto, datos);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });

      await tester.pump();

      final png = await tester.runAsync(() => futuro);

      expect(png, isNotNull);
      // Firma de un PNG.
      expect(png!.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

      final imagen = await tester.runAsync(() => decodeImageFromList(png));

      expect(imagen!.width, 1080);
      expect(imagen.height, 1080);

      // La capa fuera de pantalla se quita.
      await tester.pump();
      expect(find.byKey(const ValueKey('tarjeta-compartir')), findsNothing);
    });

    testWidgets('el botón de la ficha comparte la imagen con el texto corto', (
      tester,
    ) async {
      pantalla(tester);

      final compartidos = <(Uint8List, String)>[];
      final original = CompartirPartido.enviar;
      CompartirPartido.enviar = (png, texto) async => compartidos.add((png, texto));
      addTearDown(() => CompartirPartido.enviar = original);

      await tester.pumpWidget(
        appCon(
          FichaPartidoPage(
            partidoId: 30,
            service: _FichaFalsa(),
            avisosDeResultados: const Stream<void>.empty(),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byKey(const ValueKey('boton-compartir')), findsOneWidget);
      expect(find.byTooltip('Compartir partido'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('boton-compartir')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(compartidos, hasLength(1));
      expect(compartidos.single.$2, 'Mutxamel CF 2-1 Pego C.F. · Final');
      expect(compartidos.single.$1.length, greaterThan(1000));

    });

    testWidgets('si falla, avisa y no se rompe nada', (tester) async {
      pantalla(tester);

      final original = CompartirPartido.enviar;
      CompartirPartido.enviar = (png, texto) async => throw Exception('sin menú');
      addTearDown(() => CompartirPartido.enviar = original);

      await tester.pumpWidget(
        appCon(
          FichaPartidoPage(
            partidoId: 30,
            service: _FichaFalsa(),
            avisosDeResultados: const Stream<void>.empty(),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('boton-compartir')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.text('No se ha podido compartir el partido.'), findsOneWidget);
    });
  });
}

class _FichaFalsa extends FichaPartidoService {
  @override
  Future<FichaPartido> obtenerFicha(int partidoId, {String? idioma}) async {
    return FichaPartido(
      cabecera: _cabecera(estado: EstadoFicha.finalizado, favor: 2, contra: 1),
    );
  }
}
