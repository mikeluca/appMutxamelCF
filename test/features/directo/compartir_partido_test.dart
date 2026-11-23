import 'dart:typed_data';

import 'package:app_mutxamel_cf/features/directo/pages/compartir_vista_previa_page.dart';
import 'package:app_mutxamel_cf/features/directo/widgets/compartir_partido.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/reloj_directo.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/pages/ficha_partido_page.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/services/ficha_partido_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'harness.dart';

const _hashtags = '#somMTX #mareaAzul #MutxamelCF https://mutxamelcf.es';

List<FormaFicha> _forma([String resultados = 'GGEPG']) => [
  // Del más reciente al más antiguo, como llega del backend.
  for (var i = 0; i < resultados.length; i++)
    FormaFicha(partidoId: 40 + i, rival: 'R$i', resultado: resultados[i]),
];

FichaPartido _ficha({
  EstadoFicha estado = EstadoFicha.proximo,
  bool local = true,
  int? favor,
  int? contra,
  RelojDirecto? reloj,
  String? hora = '18:00',
  DateTime? dia,
  List<GoleadorFicha> goleadores = const [],
  List<FormaFicha>? forma,
  String? campo,
  String rival = 'Pego',
  bool? mutxamelLocal,
  String? escudoRivalUrl,
  String nombreClub = 'Mutxamel CF',
}) => FichaPartido(
  cabecera: CabeceraFicha(
    partidoId: 30,
    equipoLocal: local ? nombreClub : rival,
    equipoVisitante: local ? rival : nombreClub,
    dia: dia ?? DateTime(2026, 11, 14),
    hora: hora,
    golesFavor: favor,
    golesContra: contra,
    estado: estado,
    competicion: 'Preferente Valenciana · Jornada 9',
    reloj: reloj,
    mutxamelLocal: mutxamelLocal,
    goleadores: goleadores,
    campo: campo,
    jornada: 9,
    escudoRivalUrl: escudoRivalUrl,
  ),
  forma: forma ?? _forma(),
);

FichaPartido _final(int favor, int contra, {bool local = true}) => _ficha(
  estado: EstadoFicha.finalizado,
  favor: favor,
  contra: contra,
  local: local,
);

RelojDirecto _reloj(DateTime ahora, {int minutosJugados = 22}) => RelojDirecto(
  fase: FaseReloj.segundaParte,
  inicioParteEpochMs: ahora
      .subtract(Duration(minutes: minutosJugados, seconds: 30))
      .millisecondsSinceEpoch,
  minutoBase: 45,
  ahoraServidorEpochMs: ahora.millisecondsSinceEpoch,
  recibidoEn: ahora,
);

const _pepe = GoleadorFicha(nombre: 'Pepe', goles: 2, minutos: [23, 67]);
const _juanma = GoleadorFicha(nombre: 'Juanma', goles: 1, minutos: [80]);

/// Los datos de compartir de [ficha] con los textos en [locale].
Future<DatosCompartir> _datos(
  WidgetTester tester,
  FichaPartido ficha, {
  Locale locale = const Locale('es'),
  DateTime? ahora,
}) async {
  late DatosCompartir datos;

  await tester.pumpWidget(
    appCon(
      Builder(
        builder: (context) {
          datos = DatosCompartir.desdeFicha(
            ficha,
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

Future<void> _pintar(
  WidgetTester tester,
  DatosCompartir datos, {
  OpcionesCompartir opciones = const OpcionesCompartir(),
  Locale locale = const Locale('es'),
}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    appCon(
      Center(
        child: TarjetaCompartir(datos: datos, opciones: opciones),
      ),
      locale: locale,
    ),
  );
}

String _texto(WidgetTester tester, String clave) =>
    tester.widget<Text>(find.byKey(ValueKey(clave))).data!;

Finder _clave(String clave) => find.byKey(ValueKey(clave));

void main() {
  group('lo que lleva la imagen y el texto, en cada estado', () {
    testWidgets(
      'final ganado: marcador, FINAL, victoria y el texto con los hashtags',
      (tester) async {
        final d = await _datos(tester, _final(2, 1));

        expect(d.marcador, '2 - 1');
        expect(d.etiqueta, 'FINAL');
        expect(d.fase, FaseCompartir.finalizado);
        expect(d.resultado, ResultadoCompartir.victoria);
        expect(d.competicion, 'Preferente Valenciana · Jornada 9');
        expect(d.fecha, '14/11/2026');
        // El nombre del club sale siempre con puntos, aunque el backend mande "Mutxamel CF".
        expect(d.local, 'Mutxamel C.F.');
        expect(d.textoCompartir(), 'Mutxamel C.F. 2-1 Pego · Final $_hashtags');
      },
    );

    testWidgets(
      'el texto lleva los goleadores si los hay: "⚽ Pepe (2), Juanma"',
      (tester) async {
        final d = await _datos(
          tester,
          _ficha(
            estado: EstadoFicha.finalizado,
            favor: 3,
            contra: 1,
            goleadores: [_pepe, _juanma],
          ),
        );

        expect(
          d.textoCompartir(),
          'Mutxamel C.F. 3-1 Pego · Final ⚽ Pepe (2), Juanma $_hashtags',
        );
        // Con el interruptor de goleadores apagado, sin ellos.
        expect(
          d.textoCompartir(conGoleadores: false),
          'Mutxamel C.F. 3-1 Pego · Final $_hashtags',
        );
      },
    );

    testWidgets('de visitante el marcador va con el local a la izquierda', (
      tester,
    ) async {
      final d = await _datos(tester, _final(2, 1, local: false));

      expect(d.marcador, '1 - 2');
      expect(d.textoCompartir(), 'Pego 1-2 Mutxamel C.F. · Final $_hashtags');
      expect(d.mutxamelEsLocal, isFalse);
      expect(d.visitante, 'Mutxamel C.F.');
      expect(d.resultado, ResultadoCompartir.victoria);
    });

    testWidgets('empate y derrota', (tester) async {
      expect(
        (await _datos(tester, _final(1, 1))).resultado,
        ResultadoCompartir.empate,
      );
      expect(
        (await _datos(tester, _final(0, 3))).resultado,
        ResultadoCompartir.derrota,
      );
      expect(
        (await _datos(tester, _final(3, 0, local: false))).resultado,
        ResultadoCompartir.victoria,
      );
      // Sin terminar no hay resultado.
      expect(
        (await _datos(
          tester,
          _ficha(estado: EstadoFicha.descanso, favor: 1, contra: 0),
        )).resultado,
        isNull,
      );
    });

    testWidgets('descanso', (tester) async {
      final d = await _datos(
        tester,
        _ficha(estado: EstadoFicha.descanso, favor: 1, contra: 1),
      );

      expect(d.etiqueta, 'DESCANSO');
      expect(
        d.textoCompartir(),
        'Mutxamel C.F. 1-1 Pego · Descanso $_hashtags',
      );
    });

    testWidgets('en juego: "EN DIRECTO · 67\'" con el reloj del momento', (
      tester,
    ) async {
      final ahora = DateTime(2026, 11, 14, 19);

      final d = await _datos(
        tester,
        _ficha(
          estado: EstadoFicha.enJuego,
          favor: 2,
          contra: 1,
          reloj: _reloj(ahora),
        ),
        ahora: ahora,
      );

      expect(d.etiqueta, "EN DIRECTO · 67'");
      expect(d.textoCompartir(), "Mutxamel C.F. 2-1 Pego · 67' $_hashtags");

      // Un rato después, otro minuto.
      final despues = await _datos(
        tester,
        _ficha(
          estado: EstadoFicha.enJuego,
          favor: 2,
          contra: 1,
          reloj: _reloj(ahora),
        ),
        ahora: ahora.add(const Duration(minutes: 5)),
      );

      expect(despues.etiqueta, "EN DIRECTO · 72'");
    });

    testWidgets('en juego sin reloj (backend antiguo): solo "EN DIRECTO"', (
      tester,
    ) async {
      final d = await _datos(
        tester,
        _ficha(estado: EstadoFicha.enJuego, favor: 0, contra: 0),
      );

      expect(d.etiqueta, 'EN DIRECTO');
      expect(d.marcador, '0 - 0');
    });

    testWidgets('antes del partido, el mismo día: "DÍA DE PARTIDO"', (
      tester,
    ) async {
      final d = await _datos(tester, _ficha());

      expect(d.fase, FaseCompartir.hoy);
      expect(d.etiqueta, 'DÍA DE PARTIDO');
      expect(d.marcador, isNull);
      expect(d.hora, '18:00');
      expect(
        d.textoCompartir(),
        'Mutxamel C.F. - Pego · 14/11/2026 · 18:00 $_hashtags',
      );
    });

    testWidgets('antes del partido, otro día: "PRÓXIMO PARTIDO"', (
      tester,
    ) async {
      final d = await _datos(
        tester,
        _ficha(),
        ahora: DateTime(2026, 11, 10, 9),
      );

      expect(d.fase, FaseCompartir.proximo);
      expect(d.etiqueta, 'PRÓXIMO PARTIDO');
    });

    testWidgets('antes del partido sin hora: solo el día', (tester) async {
      final d = await _datos(tester, _ficha(hora: null));

      expect(d.hora, isNull);
      expect(d.estadoTexto, '14/11/2026');
    });

    testWidgets('cancelado', (tester) async {
      final d = await _datos(tester, _ficha(estado: EstadoFicha.cancelado));

      expect(d.etiqueta, 'CANCELADO');
      expect(d.marcador, isNull);
    });

    testWidgets('en inglés y en catalán', (tester) async {
      final f = _final(2, 1);

      final en = await _datos(tester, f, locale: const Locale('en'));
      expect(en.etiqueta, 'FULL TIME');
      expect(
        en.textoCompartir(),
        'Mutxamel C.F. 2-1 Pego · Full time $_hashtags',
      );

      final ca = await _datos(tester, f, locale: const Locale('ca'));
      expect(ca.etiqueta, 'FINAL');
      expect(ca.textoCompartir(), 'Mutxamel C.F. 2-1 Pego · Final $_hashtags');

      expect(
        (await _datos(tester, _ficha(), locale: const Locale('en'))).etiqueta,
        'MATCH DAY',
      );
      expect(
        (await _datos(tester, _ficha(), locale: const Locale('ca'))).etiqueta,
        'DIA DE PARTIT',
      );
    });

    testWidgets('la racha va del más antiguo al más reciente y como mucho 5', (
      tester,
    ) async {
      final d = await _datos(tester, _final(1, 0));

      // Del backend: GGEPG (el primero es el más reciente) → en la imagen, al revés.
      expect(d.racha.map((f) => f.resultado).join(), 'GPEGG');

      final seis = await _datos(tester, _ficha(forma: _forma('GGGGGPPP')));
      expect(seis.racha, hasLength(5));
    });

    testWidgets(
      'la línea de cada goleador: minutos, "x2" sin minutos o solo el nombre',
      (tester) async {
        expect(DatosCompartir.lineaGoleador(_pepe), "⚽ Pepe 23' 67'");
        expect(DatosCompartir.lineaGoleador(_juanma), "⚽ Juanma 80'");
        expect(
          DatosCompartir.lineaGoleador(
            const GoleadorFicha(nombre: 'Pepe', goles: 2),
          ),
          '⚽ Pepe x2',
        );
        expect(
          DatosCompartir.lineaGoleador(
            const GoleadorFicha(nombre: 'Luis', goles: 1),
          ),
          '⚽ Luis',
        );
      },
    );
  });

  group('la tarjeta', () {
    testWidgets('mide 1080x1350 (publicación) o 1080x1920 (historia)', (
      tester,
    ) async {
      final d = await _datos(tester, _final(2, 1));

      await _pintar(tester, d);
      expect(
        tester.getSize(_clave('tarjeta-compartir')),
        const Size(1080, 1350),
      );

      await _pintar(
        tester,
        d,
        opciones: const OpcionesCompartir(formato: FormatoCompartir.historia),
      );
      expect(
        tester.getSize(_clave('tarjeta-compartir')),
        const Size(1080, 1920),
      );
    });

    testWidgets(
      'final ganado: escudos, nombres, marcador, etiqueta, cinta, competición, pie y marca de agua',
      (tester) async {
        await _pintar(tester, await _datos(tester, _final(2, 1)));

        expect(_texto(tester, 'compartir-marcador'), '2 - 1');
        expect(_texto(tester, 'compartir-estado'), 'FINAL');
        expect(
          _texto(tester, 'compartir-competicion'),
          'Preferente Valenciana · Jornada 9',
        );
        expect(_texto(tester, 'compartir-fecha'), '14/11/2026');
        expect(
          _texto(tester, 'compartir-pie'),
          '#somMTX #mareaAzul #MutxamelCF',
        );
        expect(_texto(tester, 'compartir-local'), 'Mutxamel C.F.');
        expect(_texto(tester, 'compartir-visitante'), 'Pego');
        expect(_clave('compartir-cinta-victoria'), findsOneWidget);
        expect(find.text('¡VICTORIA!'), findsOneWidget);
        expect(_clave('compartir-marca-de-agua'), findsOneWidget);
        expect(_clave('compartir-escudo-pie'), findsOneWidget);
        expect(_clave('compartir-punto-rojo'), findsNothing);

        final escudo = tester.getCenter(_clave('escudo-mutxamel'));
        final generico = tester.getCenter(_clave('escudo-rival'));

        expect(escudo.dx, lessThan(generico.dx));
      },
    );

    testWidgets('de visitante el escudo del Mutxamel va a la derecha', (
      tester,
    ) async {
      await _pintar(tester, await _datos(tester, _final(2, 1, local: false)));

      final escudo = tester.getCenter(_clave('escudo-mutxamel'));
      final generico = tester.getCenter(_clave('escudo-rival'));

      expect(escudo.dx, greaterThan(generico.dx));
      expect(_texto(tester, 'compartir-marcador'), '1 - 2');
      expect(_texto(tester, 'compartir-local'), 'Pego');
      expect(_texto(tester, 'compartir-visitante'), 'Mutxamel C.F.');
    });

    testWidgets('cinta: victoria, empate y, si perdemos, ninguna', (
      tester,
    ) async {
      await _pintar(tester, await _datos(tester, _final(1, 1)));
      expect(_clave('compartir-cinta-empate'), findsOneWidget);
      expect(find.text('EMPATE'), findsOneWidget);
      expect(_clave('compartir-cinta-victoria'), findsNothing);

      await _pintar(tester, await _datos(tester, _final(0, 2)));
      expect(_clave('compartir-cinta-empate'), findsNothing);
      expect(_clave('compartir-cinta-victoria'), findsNothing);
      expect(_texto(tester, 'compartir-estado'), 'FINAL');

      // Sin terminar tampoco hay cinta.
      await _pintar(
        tester,
        await _datos(
          tester,
          _ficha(estado: EstadoFicha.descanso, favor: 3, contra: 0),
        ),
      );
      expect(_clave('compartir-cinta-victoria'), findsNothing);
    });

    testWidgets('en juego: punto rojo, etiqueta con el minuto y marcador', (
      tester,
    ) async {
      final ahora = DateTime(2026, 11, 14, 19);

      await _pintar(
        tester,
        await _datos(
          tester,
          _ficha(
            estado: EstadoFicha.enJuego,
            favor: 1,
            contra: 0,
            reloj: _reloj(ahora),
          ),
          ahora: ahora,
        ),
      );

      expect(_texto(tester, 'compartir-estado'), "EN DIRECTO · 67'");
      expect(_texto(tester, 'compartir-marcador'), '1 - 0');
      expect(_clave('compartir-punto-rojo'), findsOneWidget);
    });

    testWidgets('descanso', (tester) async {
      await _pintar(
        tester,
        await _datos(
          tester,
          _ficha(estado: EstadoFicha.descanso, favor: 1, contra: 1),
        ),
      );

      expect(_texto(tester, 'compartir-estado'), 'DESCANSO');
      expect(_texto(tester, 'compartir-marcador'), '1 - 1');
      expect(_clave('compartir-punto-rojo'), findsNothing);
    });

    testWidgets(
      'antes del partido (hoy): hora grande y "VS", "¡Te esperamos!" sin línea de campo debajo, sin marcador ni goleadores',
      (tester) async {
        await _pintar(
          tester,
          await _datos(
            tester,
            _ficha(campo: 'Camp Municipal', goleadores: [_pepe]),
          ),
        );

        expect(_texto(tester, 'compartir-estado'), 'DÍA DE PARTIDO');
        expect(_texto(tester, 'compartir-hora'), '18:00');
        expect(_texto(tester, 'compartir-vs'), 'VS');
        expect(_clave('compartir-marcador'), findsNothing);
        expect(_clave('compartir-te-esperamos'), findsOneWidget);
        expect(find.text('¡Te esperamos!'), findsOneWidget);
        // La línea del campo de debajo ya no existe: el campo solo va arriba.
        expect(_clave('compartir-campo'), findsNothing);
        expect(find.text('Camp Municipal'), findsNothing);
        expect(
          _texto(tester, 'compartir-fecha'),
          '14/11/2026 · Camp Municipal',
        );
        expect(_clave('compartir-goleadores'), findsNothing);
      },
    );

    testWidgets('antes del partido otro día y sin hora ni campo', (
      tester,
    ) async {
      await _pintar(
        tester,
        await _datos(tester, _ficha(hora: null), ahora: DateTime(2026, 11, 10)),
      );

      expect(_texto(tester, 'compartir-estado'), 'PRÓXIMO PARTIDO');
      expect(_clave('compartir-hora'), findsNothing);
      expect(_texto(tester, 'compartir-vs'), 'VS');
      expect(_clave('compartir-campo'), findsNothing);
    });

    testWidgets(
      'goleadores: con minutos, sin minutos y la racha de cinco círculos',
      (tester) async {
        await _pintar(
          tester,
          await _datos(
            tester,
            _ficha(
              estado: EstadoFicha.finalizado,
              favor: 3,
              contra: 1,
              goleadores: [
                _pepe,
                _juanma,
                const GoleadorFicha(nombre: 'Luis', goles: 2),
              ],
            ),
          ),
        );

        expect(find.text("⚽ Pepe 23' 67'"), findsOneWidget);
        expect(find.text("⚽ Juanma 80'"), findsOneWidget);
        expect(find.text('⚽ Luis x2'), findsOneWidget);
        expect(_clave('compartir-mas-goleadores'), findsNothing);

        expect(_clave('compartir-racha'), findsOneWidget);
        expect(find.text('Últimos 5'), findsOneWidget);

        final letras = [
          for (var i = 0; i < 5; i++)
            tester
                .widget<Text>(
                  find.descendant(
                    of: _clave('compartir-racha-$i'),
                    matching: find.byType(Text),
                  ),
                )
                .data,
        ];

        expect(letras, ['G', 'P', 'E', 'G', 'G']);

        Color color(int i) =>
            (tester.widget<Container>(_clave('compartir-racha-$i')).decoration!
                    as BoxDecoration)
                .color!;

        expect(color(0), const Color(0xFF2E9E4F));
        expect(color(1), const Color(0xFFD64545));
        expect(color(2), const Color(0xFF8A949B));
      },
    );

    testWidgets('más de seis goleadores: seis líneas y "y N más"', (
      tester,
    ) async {
      await _pintar(
        tester,
        await _datos(
          tester,
          _ficha(
            estado: EstadoFicha.finalizado,
            favor: 9,
            contra: 0,
            goleadores: [
              for (var i = 1; i <= 8; i++)
                GoleadorFicha(nombre: 'Jugador$i', goles: 1, minutos: [i * 5]),
            ],
          ),
        ),
      );

      for (var i = 1; i <= 6; i++) {
        expect(find.text("⚽ Jugador$i ${i * 5}'"), findsOneWidget);
      }

      expect(find.textContaining('Jugador7'), findsNothing);
      expect(_texto(tester, 'compartir-mas-goleadores'), 'y 2 más');

      // En inglés y en catalán.
      await _pintar(
        tester,
        await _datos(
          tester,
          _ficha(
            estado: EstadoFicha.finalizado,
            favor: 9,
            contra: 0,
            goleadores: [
              for (var i = 1; i <= 7; i++) GoleadorFicha(nombre: 'J$i'),
            ],
          ),
          locale: const Locale('en'),
        ),
        locale: const Locale('en'),
      );
      expect(_texto(tester, 'compartir-mas-goleadores'), 'and 1 more');
    });

    testWidgets(
      'sin goleadores o con el interruptor apagado no sale el bloque',
      (tester) async {
        final con = await _datos(
          tester,
          _ficha(
            estado: EstadoFicha.finalizado,
            favor: 2,
            contra: 0,
            goleadores: [_pepe],
          ),
        );

        await _pintar(tester, con);
        expect(_clave('compartir-goleadores'), findsOneWidget);

        await _pintar(
          tester,
          con,
          opciones: const OpcionesCompartir(goleadores: false),
        );
        expect(_clave('compartir-goleadores'), findsNothing);

        await _pintar(tester, await _datos(tester, _final(2, 0)));
        expect(_clave('compartir-goleadores'), findsNothing);
      },
    );

    testWidgets(
      'hashtags: por defecto salen; sin ellos no hay línea y el pie se recoloca sin hueco, en publicación e historia y en los tres estilos',
      (tester) async {
        for (final formato in FormatoCompartir.values) {
          for (final estilo in EstiloCompartir.values) {
            await _pintar(
              tester,
              await _datos(tester, _final(2, 1)),
              opciones: OpcionesCompartir(formato: formato, estilo: estilo),
            );

            expect(_texto(tester, 'compartir-pie'), DatosCompartir.hashtags);

            final escudoCon = tester.getBottomLeft(
              _clave('compartir-escudo-pie'),
            );
            final tarjetaCon = tester.getBottomLeft(
              _clave('tarjeta-compartir'),
            );

            await _pintar(
              tester,
              await _datos(tester, _final(2, 1)),
              opciones: OpcionesCompartir(
                formato: formato,
                estilo: estilo,
                hashtags: false,
              ),
            );

            expect(_clave('compartir-pie'), findsNothing);
            expect(find.textContaining('#somMTX'), findsNothing);
            expect(find.textContaining('#MutxamelCF'), findsNothing);

            // El escudo y el QR siguen pegados al borde inferior (mismo margen) y no queda hueco debajo del centro.
            final escudoSin = tester.getBottomLeft(
              _clave('compartir-escudo-pie'),
            );
            final tarjetaSin = tester.getBottomLeft(
              _clave('tarjeta-compartir'),
            );

            expect(
              tarjetaSin.dy - escudoSin.dy,
              closeTo(tarjetaCon.dy - escudoCon.dy, 0.01),
            );
            expect(_clave('compartir-marcador'), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        }
      },
    );

    testWidgets(
      'sin la línea del campo debajo de "¡Te esperamos!" también en historia y con resultado o sin racha',
      (tester) async {
        // Antes del partido, en historia, sin racha.
        await _pintar(
          tester,
          await _datos(
            tester,
            _ficha(campo: 'Camp Municipal', forma: const []),
          ),
          opciones: const OpcionesCompartir(formato: FormatoCompartir.historia),
        );

        expect(_clave('compartir-te-esperamos'), findsOneWidget);
        expect(_clave('compartir-campo'), findsNothing);
        expect(_clave('compartir-racha'), findsNothing);
        // El campo solo sale arriba, junto a la fecha.
        expect(find.textContaining('Camp Municipal'), findsOneWidget);

        // Con resultado: tampoco hay línea de campo.
        await _pintar(
          tester,
          await _datos(
            tester,
            _ficha(
              estado: EstadoFicha.finalizado,
              favor: 2,
              contra: 1,
              campo: 'Camp Municipal',
            ),
          ),
        );

        expect(_clave('compartir-campo'), findsNothing);
        expect(find.textContaining('Camp Municipal'), findsOneWidget);
      },
    );

    testWidgets('sin racha, o con el interruptor apagado, no sale', (
      tester,
    ) async {
      await _pintar(
        tester,
        await _datos(
          tester,
          _ficha(
            estado: EstadoFicha.finalizado,
            favor: 1,
            contra: 0,
            forma: const [],
          ),
        ),
      );
      expect(_clave('compartir-racha'), findsNothing);

      await _pintar(
        tester,
        await _datos(tester, _final(1, 0)),
        opciones: const OpcionesCompartir(racha: false),
      );
      expect(_clave('compartir-racha'), findsNothing);
    });

    testWidgets(
      'el QR (con fondo blanco y margen) y "Descarga la app", o sin QR',
      (tester) async {
        final d = await _datos(tester, _final(2, 1));

        await _pintar(tester, d);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(
          tester.widget<Container>(_clave('compartir-qr')).color,
          Colors.white,
        );
        expect(
          tester.widget<Container>(_clave('compartir-qr')).padding,
          isNotNull,
        );
        expect(_texto(tester, 'compartir-descarga'), 'Descarga la app');
        expect(DatosCompartir.web, 'https://mutxamelcf.es');

        await _pintar(tester, d, opciones: const OpcionesCompartir(qr: false));
        expect(find.byType(QrImageView), findsNothing);
        expect(
          _texto(tester, 'compartir-descarga'),
          'Síguelo en la app del Mutxamel C.F.',
        );
      },
    );

    testWidgets('en historia deja libres 250 px arriba y abajo', (
      tester,
    ) async {
      await _pintar(
        tester,
        await _datos(
          tester,
          _ficha(
            estado: EstadoFicha.finalizado,
            favor: 3,
            contra: 1,
            goleadores: [_pepe, _juanma],
            campo: 'Camp Municipal',
          ),
        ),
        opciones: const OpcionesCompartir(formato: FormatoCompartir.historia),
      );

      final origen = tester.getTopLeft(_clave('tarjeta-compartir'));

      final arriba =
          tester.getTopLeft(_clave('compartir-competicion')).dy - origen.dy;
      final abajo = tester.getBottomLeft(_clave('compartir-qr')).dy - origen.dy;

      expect(arriba, greaterThanOrEqualTo(250));
      expect(abajo, lessThanOrEqualTo(1920 - 250));
    });

    testWidgets('un rival con nombre muy largo cabe en dos líneas como máximo', (
      tester,
    ) async {
      const largo =
          'Club Deportivo Atlético Internacional Villafranca del Campo de la Sierra Alta';

      for (final formato in FormatoCompartir.values) {
        await _pintar(
          tester,
          await _datos(
            tester,
            _ficha(
              rival: largo,
              estado: EstadoFicha.finalizado,
              favor: 1,
              contra: 2,
            ),
          ),
          opciones: OpcionesCompartir(formato: formato),
        );

        final nombre = tester.widget<Text>(_clave('compartir-visitante'));

        expect(nombre.maxLines, 2);
        expect(nombre.style!.fontSize!, lessThan(40));
        expect(tester.takeException(), isNull);
      }

      // Y uno corto sale más grande.
      await _pintar(tester, await _datos(tester, _final(1, 0)));
      expect(
        tester.widget<Text>(_clave('compartir-visitante')).style!.fontSize!,
        greaterThanOrEqualTo(50),
      );
    });

    testWidgets('sin fotos de jugadores ni nada personal', (tester) async {
      await _pintar(
        tester,
        await _datos(
          tester,
          _ficha(
            estado: EstadoFicha.finalizado,
            favor: 2,
            contra: 1,
            goleadores: [_pepe],
          ),
        ),
      );

      expect(_clave('foto-jugador'), findsNothing);
      expect(_clave('avatar-jugador'), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets(
      'en inglés las letras de la racha son W, D y L y los textos van en inglés',
      (tester) async {
        await _pintar(
          tester,
          await _datos(tester, _final(2, 1), locale: const Locale('en')),
          locale: const Locale('en'),
        );

        expect(find.text('VICTORY!'), findsOneWidget);
        expect(find.text('Last 5'), findsOneWidget);
        expect(find.text('Download the app'), findsOneWidget);
        expect(find.text('W'), findsNWidgets(3));
        expect(find.text('L'), findsOneWidget);
        expect(find.text('D'), findsOneWidget);
      },
    );

    testWidgets('cada estado, formato y estilo se pinta sin errores y se lee', (
      tester,
    ) async {
      final ahora = DateTime(2026, 11, 14, 19);

      final fichas = <String, FichaPartido>{
        'hoy': _ficha(campo: 'Camp Municipal'),
        'otro día': _ficha(),
        'en juego': _ficha(
          estado: EstadoFicha.enJuego,
          favor: 2,
          contra: 1,
          reloj: _reloj(ahora),
          goleadores: [_pepe],
        ),
        'descanso': _ficha(estado: EstadoFicha.descanso, favor: 0, contra: 0),
        'ganado': _ficha(
          estado: EstadoFicha.finalizado,
          favor: 5,
          contra: 0,
          goleadores: [
            for (var i = 1; i <= 9; i++)
              GoleadorFicha(nombre: 'Jugador$i', minutos: [i]),
          ],
        ),
        'empatado': _final(2, 2),
        'perdido': _final(0, 4),
        'cancelado': _ficha(estado: EstadoFicha.cancelado),
      };

      for (final entrada in fichas.entries) {
        final d = await _datos(tester, entrada.value, ahora: ahora);

        for (final formato in FormatoCompartir.values) {
          for (final estilo in EstiloCompartir.values) {
            await _pintar(
              tester,
              d,
              opciones: OpcionesCompartir(formato: formato, estilo: estilo),
            );

            expect(
              tester.takeException(),
              isNull,
              reason: '${entrada.key} $formato $estilo',
            );
            expect(_clave('compartir-estado'), findsOneWidget);
            expect(_clave('compartir-pie'), findsOneWidget);
            expect(find.byType(QrImageView), findsOneWidget);
          }
        }
      }
    });

    testWidgets(
      'el color del texto cambia con el estilo: blanco en club y oscuro, azul oscuro en claro',
      (tester) async {
        final d = await _datos(tester, _final(2, 1));

        Color colorMarcador() =>
            tester.widget<Text>(_clave('compartir-marcador')).style!.color!;

        await _pintar(tester, d);
        expect(colorMarcador(), Colors.white);

        await _pintar(
          tester,
          d,
          opciones: const OpcionesCompartir(estilo: EstiloCompartir.oscuro),
        );
        expect(colorMarcador(), Colors.white);

        await _pintar(
          tester,
          d,
          opciones: const OpcionesCompartir(estilo: EstiloCompartir.claro),
        );
        expect(colorMarcador(), const Color(0xFF0B3D5C));
      },
    );
  });

  group('generar la imagen y compartirla', () {
    Future<BuildContext> contexto(WidgetTester tester) async {
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

      return contexto;
    }

    Future<Uint8List> generar(
      WidgetTester tester,
      BuildContext contexto,
      DatosCompartir datos,
      OpcionesCompartir opciones,
    ) async {
      late Future<Uint8List> futuro;

      await tester.runAsync(() async {
        futuro = CompartirPartido.generarPng(
          contexto,
          datos,
          opciones: opciones,
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });

      await tester.pump();

      return (await tester.runAsync(() => futuro))!;
    }

    testWidgets('la imagen sale como PNG de 1080x1350 y de 1080x1920', (
      tester,
    ) async {
      pantalla(tester);

      final datos = await _datos(tester, _final(2, 1));
      final ctx = await contexto(tester);

      for (final formato in FormatoCompartir.values) {
        final png = await generar(
          tester,
          ctx,
          datos,
          OpcionesCompartir(formato: formato),
        );

        // Firma de un PNG.
        expect(png.sublist(0, 8), [
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]);

        final imagen = (await tester.runAsync(() => decodeImageFromList(png)))!;

        expect(imagen.width, 1080);
        expect(imagen.height, formato.alto.toInt());
      }

      // La capa fuera de pantalla se quita.
      await tester.pump();
      expect(_clave('tarjeta-compartir'), findsNothing);
    });

    testWidgets(
      'compartir envía la imagen con el texto y respeta los interruptores',
      (tester) async {
        pantalla(tester);

        final compartidos = <(Uint8List, String)>[];
        final original = CompartirPartido.enviar;
        CompartirPartido.enviar = (png, texto, origen) async =>
            compartidos.add((png, texto));
        addTearDown(() => CompartirPartido.enviar = original);

        final datos = await _datos(
          tester,
          _ficha(
            estado: EstadoFicha.finalizado,
            favor: 3,
            contra: 1,
            goleadores: [_pepe, _juanma],
          ),
        );
        final ctx = await contexto(tester);

        Future<void> compartir(OpcionesCompartir opciones) async {
          late Future<void> futuro;

          await tester.runAsync(() async {
            futuro = CompartirPartido.compartir(ctx, datos, opciones: opciones);
            await Future<void>.delayed(const Duration(milliseconds: 300));
          });
          await tester.pump();
          await tester.runAsync(() => futuro);
        }

        await compartir(const OpcionesCompartir());
        await compartir(const OpcionesCompartir(goleadores: false));

        expect(compartidos, hasLength(2));
        expect(
          compartidos[0].$2,
          'Mutxamel C.F. 3-1 Pego · Final ⚽ Pepe (2), Juanma $_hashtags',
        );
        expect(compartidos[1].$2, 'Mutxamel C.F. 3-1 Pego · Final $_hashtags');
        expect(compartidos[0].$1.length, greaterThan(1000));
      },
    );
  });

  group('la vista previa', () {
    Future<void> abrir(
      WidgetTester tester,
      FichaPartido ficha, {
      Locale locale = const Locale('es'),
    }) async {
      pantalla(tester);

      await tester.pumpWidget(
        appCon(
          CompartirVistaPreviaPage(
            ficha: ficha,
            ahora: () => DateTime(2026, 11, 14, 19),
          ),
          locale: locale,
        ),
      );
      await tester.pump();
    }

    Size tarjeta(WidgetTester tester) =>
        tester.getSize(_clave('tarjeta-compartir'));

    testWidgets('enseña la imagen en vivo con sus controles', (tester) async {
      await abrir(
        tester,
        _ficha(
          estado: EstadoFicha.finalizado,
          favor: 2,
          contra: 1,
          goleadores: [_pepe],
        ),
      );

      expect(find.text('Compartir partido'), findsOneWidget);
      expect(_clave('compartir-vista-previa'), findsOneWidget);
      expect(_clave('tarjeta-compartir'), findsOneWidget);
      expect(_texto(tester, 'compartir-marcador'), '2 - 1');

      expect(find.text('Publicación'), findsOneWidget);
      expect(find.text('Historia'), findsOneWidget);
      expect(find.text('Azul club'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(_clave('compartir-opcion-goleadores'), findsOneWidget);
      expect(_clave('compartir-opcion-racha'), findsOneWidget);
      expect(_clave('compartir-opcion-qr'), findsOneWidget);
      expect(_clave('compartir-boton'), findsOneWidget);

      // Todo activo por defecto.
      expect(
        tester
            .widget<FilterChip>(_clave('compartir-opcion-goleadores'))
            .selected,
        isTrue,
      );
      expect(
        tester.widget<FilterChip>(_clave('compartir-opcion-racha')).selected,
        isTrue,
      );
      expect(
        tester.widget<FilterChip>(_clave('compartir-opcion-qr')).selected,
        isTrue,
      );
      expect(_clave('compartir-goleadores'), findsOneWidget);
      expect(_clave('compartir-racha'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('los interruptores sin datos se ocultan', (tester) async {
      await abrir(
        tester,
        _ficha(
          estado: EstadoFicha.finalizado,
          favor: 2,
          contra: 1,
          forma: const [],
        ),
      );

      expect(_clave('compartir-opcion-goleadores'), findsNothing);
      expect(_clave('compartir-opcion-racha'), findsNothing);
      expect(_clave('compartir-opcion-qr'), findsOneWidget);
    });

    testWidgets('el chip Hashtags empieza marcado y quita y pone la línea', (
      tester,
    ) async {
      await abrir(tester, _final(2, 1));

      expect(_clave('compartir-opcion-hashtags'), findsOneWidget);
      expect(
        tester.widget<FilterChip>(_clave('compartir-opcion-hashtags')).selected,
        isTrue,
      );
      expect(_clave('compartir-pie'), findsOneWidget);

      await tester.tap(_clave('compartir-opcion-hashtags'));
      await tester.pump();
      expect(_clave('compartir-pie'), findsNothing);

      await tester.tap(find.text('Historia'));
      await tester.pump();
      expect(_clave('compartir-pie'), findsNothing);

      await tester.tap(_clave('compartir-opcion-hashtags'));
      await tester.pump();
      expect(_clave('compartir-pie'), findsOneWidget);
    });

    testWidgets(
      'la elección de Hashtags no se guarda: al volver a abrir empieza marcado',
      (tester) async {
        await abrir(tester, _final(2, 1));
        await tester.tap(_clave('compartir-opcion-hashtags'));
        await tester.pump();
        expect(_clave('compartir-pie'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        await abrir(tester, _final(2, 1));

        expect(_clave('compartir-pie'), findsOneWidget);
      },
    );

    testWidgets('cambia el formato, el estilo y los interruptores en vivo', (
      tester,
    ) async {
      await abrir(
        tester,
        _ficha(
          estado: EstadoFicha.finalizado,
          favor: 2,
          contra: 1,
          goleadores: [_pepe],
        ),
      );

      // La tarjeta se escala para caber (vive dentro de un FittedBox): el tamaño lógico es el de la imagen.
      expect(tarjeta(tester), const Size(1080, 1350));

      await tester.tap(find.text('Historia'));
      await tester.pump();
      expect(tarjeta(tester), const Size(1080, 1920));

      await tester.tap(find.text('Publicación'));
      await tester.pump();
      expect(tarjeta(tester), const Size(1080, 1350));

      Color colorMarcador() =>
          tester.widget<Text>(_clave('compartir-marcador')).style!.color!;

      await tester.tap(find.text('Claro'));
      await tester.pump();
      expect(colorMarcador(), const Color(0xFF0B3D5C));

      await tester.tap(find.text('Azul club'));
      await tester.pump();
      expect(colorMarcador(), Colors.white);

      await tester.tap(_clave('compartir-opcion-goleadores'));
      await tester.pump();
      expect(_clave('compartir-goleadores'), findsNothing);

      await tester.tap(_clave('compartir-opcion-racha'));
      await tester.pump();
      expect(_clave('compartir-racha'), findsNothing);

      await tester.tap(_clave('compartir-opcion-qr'));
      await tester.pump();
      expect(find.byType(QrImageView), findsNothing);

      await tester.tap(_clave('compartir-opcion-qr'));
      await tester.pump();
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('"Compartir" envía la imagen con el texto y lo elegido', (
      tester,
    ) async {
      final compartidos = <(Uint8List, String)>[];
      final origenes = <Rect>[];
      final original = CompartirPartido.enviar;
      CompartirPartido.enviar = (png, texto, origen) async {
        origenes.add(origen);
        compartidos.add((png, texto));
      };
      addTearDown(() => CompartirPartido.enviar = original);

      await abrir(
        tester,
        _ficha(
          estado: EstadoFicha.finalizado,
          favor: 3,
          contra: 1,
          goleadores: [_pepe, _juanma],
        ),
      );

      await tester.tap(find.text('Historia'));
      await tester.pump();
      await tester.tap(_clave('compartir-opcion-goleadores'));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(_clave('compartir-boton'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();

      // El menú de compartir (iPad) se ancla al botón: su rectángulo, no la pantalla entera
      expect(origenes, hasLength(1));
      expect(origenes.single.isEmpty, isFalse);
      expect(
        origenes.single.height,
        lessThan(120),
      ); // el botón, no la pantalla entera
      expect(compartidos, hasLength(1));
      // Sin goleadores porque se apagó el interruptor.
      expect(
        compartidos.single.$2,
        'Mutxamel C.F. 3-1 Pego · Final $_hashtags',
      );

      final imagen = (await tester.runAsync(
        () => decodeImageFromList(compartidos.single.$1),
      ))!;

      expect(imagen.width, 1080);
      expect(imagen.height, 1920);
    });

    testWidgets('si falla, avisa y no se rompe nada', (tester) async {
      final original = CompartirPartido.enviar;
      CompartirPartido.enviar = (png, texto, origen) async =>
          throw Exception('sin menú');
      addTearDown(() => CompartirPartido.enviar = original);

      await abrir(tester, _final(2, 1));

      await tester.runAsync(() async {
        await tester.tap(_clave('compartir-boton'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump();

      expect(
        find.text('No se ha podido compartir el partido.'),
        findsOneWidget,
      );
      // El botón vuelve a estar disponible.
      expect(
        tester.widget<FilledButton>(_clave('compartir-boton')).onPressed,
        isNotNull,
      );
    });

    testWidgets('desde la ficha el botón de compartir abre la vista previa', (
      tester,
    ) async {
      pantalla(tester);

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

      expect(_clave('boton-compartir'), findsOneWidget);
      expect(find.byTooltip('Compartir partido'), findsOneWidget);

      await tester.tap(_clave('boton-compartir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CompartirVistaPreviaPage), findsOneWidget);
      expect(_clave('tarjeta-compartir'), findsOneWidget);
      expect(_texto(tester, 'compartir-marcador'), '2 - 1');
    });
  });
}

class _FichaFalsa extends FichaPartidoService {
  @override
  Future<FichaPartido> obtenerFicha(int partidoId, {String? idioma}) async {
    return _final(2, 1);
  }
}
