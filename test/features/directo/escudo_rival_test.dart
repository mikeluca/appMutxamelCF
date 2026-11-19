import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';

import 'package:app_mutxamel_cf/core/config/app_config.dart';
import 'package:app_mutxamel_cf/core/widget/escudo_rival.dart';
import 'package:app_mutxamel_cf/features/directo/widgets/compartir_partido.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/widgets/ficha_cabecera.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/widgets/ficha_forma.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/pages/matches_page.dart';
import 'package:app_mutxamel_cf/features/matches/widgets/match_card.dart';
import 'package:app_mutxamel_cf/features/teams/models/standings_model.dart';
import 'package:app_mutxamel_cf/features/teams/widgets/team_standings_section.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _generico = ValueKey('escudo-rival');
const _nuestro = ValueKey('escudo-mutxamel');

/// La URL completa de una ruta del backend.
String _completa(String ruta) => '${AppConfig.mediaBaseUrl}$ruta';

const _ruta7 = '/api/public/escudos-rivales/7?v=3';

/// Sustituye la imagen de red por una marca con la URL, para ver qué escudo se pide sin ir a la red.
void _marcarRed() {
  final anterior = EscudoRival.constructorDeRed;

  EscudoRival.constructorDeRed = (url, tamano, generico) =>
      SizedBox(key: ValueKey('red:$url'), width: tamano, height: tamano);

  addTearDown(() => EscudoRival.constructorDeRed = anterior);
}

Finder _red(String ruta) => find.byKey(ValueKey('red:${_completa(ruta)}'));

Finder _algunaRed() => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('red:'),
);

void main() {
  group('EscudoRival', () {
    test('la ruta del backend se completa con la URL base del servidor', () {
      expect(
        EscudoRival.urlCompleta('/api/public/escudos-rivales/7?v=3'),
        '${AppConfig.mediaBaseUrl}/api/public/escudos-rivales/7?v=3',
      );
      expect(
        EscudoRival.urlCompleta('api/public/escudos-rivales/7'),
        '${AppConfig.mediaBaseUrl}/api/public/escudos-rivales/7',
      );
      expect(
        EscudoRival.urlCompleta('https://otro.es/e.png'),
        'https://otro.es/e.png',
      );
      expect(EscudoRival.urlCompleta(null), isNull);
      expect(EscudoRival.urlCompleta('  '), isNull);
    });

    testWidgets('propio: nuestro escudo, aunque haya URL', (tester) async {
      pantalla(tester);
      _marcarRed();

      await tester.pumpWidget(
        appCon(const EscudoRival(url: _ruta7, esPropio: true, tamano: 40)),
      );

      expect(find.byKey(_nuestro), findsOneWidget);
      expect(find.byKey(_generico), findsNothing);
      expect(_algunaRed(), findsNothing);

      final imagen = tester.widget<Image>(find.byKey(_nuestro));
      expect(imagen.fit, BoxFit.contain);
      expect(imagen.width, 40);
    });

    testWidgets('sin URL: el genérico', (tester) async {
      pantalla(tester);
      _marcarRed();

      await tester.pumpWidget(appCon(const EscudoRival(tamano: 40)));

      expect(find.byKey(_generico), findsOneWidget);
      expect(find.byKey(_nuestro), findsNothing);
      expect(_algunaRed(), findsNothing);

      await tester.pumpWidget(appCon(const EscudoRival(url: '', tamano: 40)));
      expect(find.byKey(_generico), findsOneWidget);
    });

    testWidgets(
      'con URL: la imagen de la red con la URL completa y el tamaño pedido',
      (tester) async {
        pantalla(tester);
        _marcarRed();

        await tester.pumpWidget(
          appCon(const EscudoRival(url: _ruta7, tamano: 48)),
        );

        expect(_red(_ruta7), findsOneWidget);
        expect(tester.getSize(_red(_ruta7)), const Size(48, 48));
      },
    );

    testWidgets(
      'la imagen de red es cached_network_image, entera, con caché y sin fundidos',
      (tester) async {
        pantalla(tester);

        await tester.pumpWidget(
          appCon(const EscudoRival(url: _ruta7, tamano: 48)),
        );

        final imagen = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );

        expect(imagen.imageUrl, _completa(_ruta7));
        expect(imagen.fit, BoxFit.contain);
        expect(imagen.fadeInDuration, Duration.zero);
        expect(imagen.fadeOutDuration, Duration.zero);

        // Mientras carga se ve el genérico.
        expect(find.byKey(_generico), findsOneWidget);
      },
    );

    testWidgets('con error: el genérico', (tester) async {
      pantalla(tester);

      // En los tests no hay red: la carga falla y se queda el genérico.
      await tester.pumpWidget(
        appCon(const EscudoRival(url: _ruta7, tamano: 48)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();

      expect(find.byKey(_generico), findsOneWidget);
      expect(find.byKey(_nuestro), findsNothing);
    });

    testWidgets(
      'al reconstruirse con la misma URL no cambia de imagen (no parpadea)',
      (tester) async {
        pantalla(tester);

        Widget app() => appCon(const EscudoRival(url: _ruta7, tamano: 48));

        await tester.pumpWidget(app());
        final antes = tester.element(find.byType(CachedNetworkImage));

        await tester.pumpWidget(app());
        final despues = tester.element(find.byType(CachedNetworkImage));

        // El mismo elemento: no se recrea la imagen.
        expect(identical(antes, despues), isTrue);
      },
    );
  });

  group('en cada pantalla', () {
    MatchModel partido({
      String? url,
      bool propio = false,
      bool local = true,
      bool enJuego = false,
      String equipo = 'Primer Equipo',
    }) => MatchModel(
      id: 30,
      categoria: equipo,
      equipo: equipo,
      rival: 'Pego C.F.',
      local: local,
      dia: DateTime(2030, 11, 14),
      hora: '18:00',
      enJuego: enJuego,
      golesFavor: enJuego ? 1 : null,
      golesContra: enJuego ? 0 : null,
      escudoRivalUrl: url,
      rivalEsPropio: propio,
    );

    testWidgets('portada (Primer Equipo): el escudo del rival en su lado', (
      tester,
    ) async {
      pantalla(tester);
      _marcarRed();

      await tester.pumpWidget(
        appCon(
          SingleChildScrollView(
            child: MatchCard(
              match: partido(url: _ruta7),
              mostrarPrimerEquipo: true,
            ),
          ),
        ),
      );

      expect(_red(_ruta7), findsOneWidget);
      expect(find.byKey(_generico), findsNothing);

      // De local, el rival va a la derecha del nuestro.
      expect(
        tester.getCenter(_red(_ruta7)).dx,
        greaterThan(tester.getCenter(find.byType(Image).first).dx),
      );
    });

    testWidgets('portada en directo y de visitante', (tester) async {
      pantalla(tester);
      // La fuente de los tests ocupa más que la real: se da ancho.
      tester.view.physicalSize = const Size(700, 900);
      _marcarRed();

      await tester.pumpWidget(
        appCon(
          SingleChildScrollView(
            child: MatchCard(
              match: partido(url: _ruta7, local: false, enJuego: true),
              mostrarPrimerEquipo: true,
            ),
          ),
        ),
      );

      expect(_red(_ruta7), findsOneWidget);
      // De visitante, el rival va a la izquierda del nuestro.
      expect(
        tester.getCenter(_red(_ruta7)).dx,
        lessThan(tester.getCenter(find.byType(Image).first).dx),
      );
    });

    testWidgets(
      'las demás tarjetas de partido de la portada (cualquier equipo)',
      (tester) async {
        pantalla(tester);
        _marcarRed();

        await tester.pumpWidget(
          appCon(
            SingleChildScrollView(
              child: MatchCard(
                match: partido(url: _ruta7, equipo: 'Cadete A'),
              ),
            ),
          ),
        );

        expect(_red(_ruta7), findsOneWidget);
      },
    );

    testWidgets('rival de nuestro club: nuestro escudo en los dos lados', (
      tester,
    ) async {
      pantalla(tester);
      _marcarRed();

      await tester.pumpWidget(
        appCon(
          SingleChildScrollView(
            child: MatchCard(
              match: partido(propio: true),
              mostrarPrimerEquipo: true,
            ),
          ),
        ),
      );

      expect(find.byKey(_nuestro), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
      expect(find.byKey(_generico), findsNothing);
    });

    testWidgets('backend antiguo (sin los campos): el genérico de siempre', (
      tester,
    ) async {
      pantalla(tester);
      _marcarRed();

      final p = MatchModel.fromJson({
        'id': 30,
        'equipo': 'Primer Equipo',
        'rival': 'Pego C.F.',
      });

      expect(p.escudoRivalUrl, isNull);
      expect(p.rivalEsPropio, isFalse);

      await tester.pumpWidget(
        appCon(
          SingleChildScrollView(
            child: MatchCard(match: p, mostrarPrimerEquipo: true),
          ),
        ),
      );

      expect(find.byKey(_generico), findsOneWidget);
      expect(_algunaRed(), findsNothing);
    });

    testWidgets('el modelo lee escudoRivalUrl y rivalEsPropio', (tester) async {
      final p = MatchModel.fromJson({
        'equipo': 'Cadete A',
        'rival': 'Pego C.F.',
        'escudoRivalUrl': _ruta7,
        'rivalEsPropio': false,
      });
      final q = MatchModel.fromJson({
        'equipo': 'Cadete A',
        'rival': 'Mutxamel C.F. B',
        'rivalEsPropio': true,
      });

      expect(p.escudoRivalUrl, _ruta7);
      expect(q.rivalEsPropio, isTrue);
      expect(q.escudoRivalUrl, isNull);
    });

    CabeceraFicha cabecera({
      bool local = true,
      String? url,
      bool propio = false,
    }) => CabeceraFicha(
      partidoId: 30,
      equipoLocal: local ? 'Mutxamel CF' : 'Pego C.F.',
      equipoVisitante: local ? 'Pego C.F.' : 'Mutxamel CF',
      dia: DateTime(2026, 11, 14),
      estado: EstadoFicha.finalizado,
      golesFavor: 1,
      golesContra: 0,
      escudoRivalUrl: url,
      rivalEsPropio: propio,
    );

    testWidgets(
      'cabecera de la ficha: el escudo del rival a la derecha de local y a la izquierda de visitante',
      (tester) async {
        pantalla(tester);
        _marcarRed();

        await tester.pumpWidget(
          appCon(FichaCabecera(cabecera: cabecera(url: _ruta7))),
        );
        final nuestro = tester.getCenter(find.byKey(_nuestro));

        expect(_red(_ruta7), findsOneWidget);
        expect(tester.getCenter(_red(_ruta7)).dx, greaterThan(nuestro.dx));
        // Mismo tamaño que el del Mutxamel.
        expect(
          tester.getSize(_red(_ruta7)),
          tester.getSize(find.byKey(_nuestro)),
        );

        await tester.pumpWidget(
          appCon(FichaCabecera(cabecera: cabecera(local: false, url: _ruta7))),
        );

        expect(
          tester.getCenter(_red(_ruta7)).dx,
          lessThan(tester.getCenter(find.byKey(_nuestro)).dx),
        );
      },
    );

    testWidgets(
      'cabecera: sin escudo, el genérico; contra un filial, nuestro escudo dos veces',
      (tester) async {
        pantalla(tester);
        _marcarRed();

        await tester.pumpWidget(appCon(FichaCabecera(cabecera: cabecera())));
        expect(find.byKey(_generico), findsOneWidget);

        await tester.pumpWidget(
          appCon(FichaCabecera(cabecera: cabecera(propio: true))),
        );
        expect(find.byKey(_nuestro), findsNWidgets(2));
        expect(find.byKey(_generico), findsNothing);
      },
    );

    testWidgets('cabecera: se lee del JSON de la ficha', (tester) async {
      final c = CabeceraFicha.fromJson({
        'partidoId': 30,
        'equipoLocal': 'Mutxamel CF',
        'equipoVisitante': 'Pego C.F.',
        'escudoRivalUrl': _ruta7,
        'rivalEsPropio': false,
      });

      expect(c.escudoRivalUrl, _ruta7);
      expect(CabeceraFicha.fromJson({}).escudoRivalUrl, isNull);
      expect(CabeceraFicha.fromJson({}).rivalEsPropio, isFalse);
    });

    testWidgets(
      'forma del equipo: el escudo del rival de cada partido, en su lado',
      (tester) async {
        pantalla(tester);
        _marcarRed();

        await tester.pumpWidget(
          appCon(
            FichaForma(
              alTocar: (_) {},
              forma: [
                FormaFicha(
                  partidoId: 1,
                  local: true,
                  rival: 'Pego C.F.',
                  golesFavor: 2,
                  resultado: 'G',
                  escudoRivalUrl: _ruta7,
                ),
                const FormaFicha(
                  partidoId: 2,
                  local: false,
                  rival: 'Mutxamel C.F. B',
                  resultado: 'E',
                  rivalEsPropio: true,
                ),
                const FormaFicha(
                  partidoId: 3,
                  rival: 'Orba C.F.',
                  resultado: 'P',
                ),
              ],
            ),
          ),
        );

        // 1: escudo de red; 2: nuestro en los dos lados (más el nuestro del primero y tercero); 3: genérico.
        expect(_red(_ruta7), findsOneWidget);
        expect(find.byKey(_generico), findsOneWidget);
        expect(find.byKey(_nuestro), findsNWidgets(4));

        final filaForma = FormaFicha.fromJson({
          'partidoId': 9,
          'rival': 'X',
          'escudoRivalUrl': _ruta7,
          'rivalEsPropio': true,
        });

        expect(filaForma.escudoRivalUrl, _ruta7);
        expect(filaForma.rivalEsPropio, isTrue);
      },
    );

    testWidgets(
      'lista de partidos y resultados (cualquier equipo): escudo pequeño delante del nombre',
      (tester) async {
        pantalla(tester);
        _marcarRed();

        Widget lista() => appCon(
          ListView(
            children: [
              PartidoListaCard(
                partido: MatchModel(
                  equipo: 'Cadete A',
                  categoria: 'Cadete A',
                  rival: 'Pego C.F.',
                  resultado: '2-1',
                  dia: DateTime(2026, 11, 1),
                  escudoRivalUrl: _ruta7,
                ),
              ),
              PartidoListaCard(
                partido: MatchModel(
                  equipo: 'Cadete A',
                  categoria: 'Cadete A',
                  rival: 'Orba C.F.',
                  dia: DateTime(2030, 11, 1),
                ),
              ),
              PartidoListaCard(
                partido: MatchModel(
                  equipo: 'Cadete A',
                  categoria: 'Cadete A',
                  rival: 'Mutxamel C.F. B',
                  dia: DateTime(2030, 11, 8),
                  rivalEsPropio: true,
                ),
              ),
            ],
          ),
        );

        await tester.pumpWidget(lista());

        expect(_red(_ruta7), findsOneWidget);
        // Pequeño, no el grande de las tarjetas de la portada.
        expect(tester.getSize(_red(_ruta7)).width, lessThanOrEqualTo(32));
        // Orba, sin escudo: genérico. El filial y los dos nuestros: el del Mutxamel.
        expect(find.byKey(_generico), findsOneWidget);
        expect(find.byKey(_nuestro), findsNWidgets(4));
        // Delante del nombre.
        expect(
          tester.getCenter(_red(_ruta7)).dx,
          lessThan(tester.getCenter(find.text('Pego C.F.')).dx),
        );
      },
    );

    testWidgets(
      'clasificación: un escudo pequeño delante del nombre de cada equipo',
      (tester) async {
        pantalla(tester);
        _marcarRed();

        StandingsRowModel fila(
          int pos,
          String equipo, {
          bool nuestro = false,
          String? url,
        }) => StandingsRowModel(
          posicion: pos,
          equipo: equipo,
          esNuestro: nuestro,
          puntos: 10,
          pj: 5,
          pg: 3,
          pe: 1,
          pp: 1,
          gf: 8,
          gc: 4,
          escudoUrl: url,
        );

        await tester.pumpWidget(
          appCon(
            SingleChildScrollView(
              child: TeamStandingsSection(
                future: Future.value(
                  StandingsModel(
                    competicion: 'Liga',
                    jornada: 5,
                    fechaImportacion: null,
                    filas: [
                      fila(1, 'Pego C.F.', url: _ruta7),
                      fila(2, 'Mutxamel C.F.', nuestro: true),
                      fila(3, 'Orba C.F.'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(_red(_ruta7), findsOneWidget);
        expect(find.byKey(_nuestro), findsOneWidget);
        expect(find.byKey(_generico), findsOneWidget);
        expect(tester.getSize(_red(_ruta7)).width, lessThanOrEqualTo(24));
        expect(
          tester.getCenter(_red(_ruta7)).dx,
          lessThan(tester.getCenter(find.text('Pego C.F.')).dx),
        );
      },
    );

    testWidgets(
      'clasificación: una fila con esPropio (un filial) lleva nuestro escudo aunque no sea esNuestro',
      (tester) async {
        pantalla(tester);
        _marcarRed();

        StandingsRowModel fila(
          int pos,
          String equipo, {
          bool nuestro = false,
          bool propio = false,
          String? url,
        }) => StandingsRowModel(
          posicion: pos,
          equipo: equipo,
          esNuestro: nuestro,
          puntos: 10,
          pj: 5,
          pg: 3,
          pe: 1,
          pp: 1,
          gf: 8,
          gc: 4,
          escudoUrl: url,
          esPropio: propio,
        );

        await tester.pumpWidget(
          appCon(
            SingleChildScrollView(
              child: TeamStandingsSection(
                future: Future.value(
                  StandingsModel(
                    competicion: 'Liga',
                    jornada: 5,
                    fechaImportacion: null,
                    filas: [
                      fila(1, 'Pego C.F.', url: _ruta7),
                      fila(2, 'Mutxamel C.F.', nuestro: true, propio: true),
                      fila(3, "C.F. Mutxamel 'B'", propio: true),
                      fila(4, 'Orba C.F.'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        // Nuestro escudo en nuestra fila y en la del filial; el del rival y el genérico en las demás.
        expect(find.byKey(_nuestro), findsNWidgets(2));
        expect(_red(_ruta7), findsOneWidget);
        expect(find.byKey(_generico), findsOneWidget);
      },
    );

    testWidgets('clasificación: el modelo lee esPropio (false si no viene)', (
      tester,
    ) async {
      final con = StandingsRowModel.fromJson({
        'posicion': 3,
        'equipo': "C.F. Mutxamel 'B'",
        'esNuestro': false,
        'esPropio': true,
      });
      final sin = StandingsRowModel.fromJson({'posicion': 2, 'equipo': 'X'});

      expect(con.esPropio, isTrue);
      expect(con.esNuestro, isFalse);
      expect(sin.esPropio, isFalse);
    });

    testWidgets('clasificación: el modelo lee escudoUrl y sin él sigue igual', (
      tester,
    ) async {
      final con = StandingsRowModel.fromJson({
        'posicion': 1,
        'equipo': 'Pego C.F.',
        'escudoUrl': _ruta7,
      });
      final sin = StandingsRowModel.fromJson({'posicion': 2, 'equipo': 'X'});

      expect(con.escudoUrl, _ruta7);
      expect(sin.escudoUrl, isNull);
    });
  });

  group('imagen de compartir', () {
    DatosCompartir datos({String? url, bool propio = false}) => DatosCompartir(
      local: 'Mutxamel C.F.',
      visitante: 'Pego C.F.',
      mutxamelEsLocal: true,
      golesLocal: 2,
      golesVisitante: 1,
      fase: FaseCompartir.finalizado,
      etiqueta: 'FINAL',
      competicion: 'Liga',
      fecha: '14/11/2026',
      textoBase: 'Mutxamel C.F. 2-1 Pego C.F. · Final',
      escudoRivalUrl: url,
      rivalEsPropio: propio,
    );

    Future<void> pintarTarjeta(WidgetTester tester, DatosCompartir d) async {
      tester.view.physicalSize = const Size(1200, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        appCon(Center(child: TarjetaCompartir(datos: d))),
      );
    }

    testWidgets('con escudo: el del rival; sin escudo: el genérico', (
      tester,
    ) async {
      _marcarRed();

      await pintarTarjeta(tester, datos(url: _ruta7));
      expect(_red(_ruta7), findsOneWidget);
      expect(find.byKey(_generico), findsNothing);
      // Del mismo tamaño que el del Mutxamel.
      expect(
        tester.getSize(_red(_ruta7)),
        tester.getSize(find.byKey(_nuestro)),
      );

      await pintarTarjeta(tester, datos());
      expect(find.byKey(_generico), findsOneWidget);
      expect(_algunaRed(), findsNothing);
    });

    testWidgets('contra un filial: nuestro escudo en los dos lados', (
      tester,
    ) async {
      await pintarTarjeta(tester, datos(propio: true));

      expect(find.byKey(_nuestro), findsNWidgets(2));
    });

    testWidgets('los datos salen del escudo de la cabecera', (tester) async {
      late DatosCompartir d;

      await tester.pumpWidget(
        appCon(
          Builder(
            builder: (context) {
              d = DatosCompartir.desdeFicha(
                const FichaPartido(
                  cabecera: CabeceraFicha(
                    partidoId: 30,
                    equipoLocal: 'Mutxamel CF',
                    equipoVisitante: 'Pego C.F.',
                    escudoRivalUrl: _ruta7,
                  ),
                ),
                AppLocalizations.of(context),
                ahora: DateTime(2026, 11, 14),
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(d.escudoRivalUrl, _ruta7);
      expect(d.conEscudoRival(null).escudoRivalUrl, isNull);
      expect(d.conEscudoRival(null).textoCompartir(), d.textoCompartir());
    });

    /// Genera el PNG con el escudo precargado (o no) y devuelve los datos con los que se pintó la tarjeta.
    Future<List<String?>> generar(
      WidgetTester tester,
      DatosCompartir d, {
      required Future<bool> Function(BuildContext, String, Duration) precarga,
    }) async {
      pantalla(tester);
      _marcarRed();

      final anterior = CompartirPartido.precargarEscudo;
      CompartirPartido.precargarEscudo = precarga;
      addTearDown(() => CompartirPartido.precargarEscudo = anterior);

      late BuildContext contexto;

      await tester.pumpWidget(
        appCon(
          Builder(
            builder: (c) {
              contexto = c;
              return const SizedBox();
            },
          ),
        ),
      );

      late Future<Uint8List> futuro;

      await tester.runAsync(() async {
        futuro = CompartirPartido.generarPng(contexto, d);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      // Lo que está pintado fuera de la pantalla en este momento.
      final rojo = _algunaRed().evaluate().isNotEmpty;
      final generico = find.byKey(_generico).evaluate().isNotEmpty;

      final png = await tester.runAsync(() => futuro);
      await tester.pump();

      expect(png, isNotNull);
      return [rojo ? 'red' : null, generico ? 'generico' : null];
    }

    testWidgets(
      'espera al escudo antes de generarla: si se carga, sale con él',
      (tester) async {
        String? urlPedida;
        Duration? esperaPedida;

        final pintado = await generar(
          tester,
          datos(url: _ruta7),
          precarga: (contexto, url, espera) async {
            urlPedida = url;
            esperaPedida = espera;
            return true;
          },
        );

        expect(urlPedida, _completa(_ruta7));
        expect(esperaPedida, const Duration(seconds: 3));
        expect(pintado, ['red', null]);
      },
    );

    testWidgets('si falla o tarda más de 3 s, usa el genérico', (tester) async {
      final pintado = await generar(
        tester,
        datos(url: _ruta7),
        precarga: (contexto, url, espera) async => false,
      );

      expect(pintado, [null, 'generico']);
    });

    testWidgets('sin escudo no espera a nada', (tester) async {
      var llamadas = 0;

      final pintado = await generar(
        tester,
        datos(),
        precarga: (c, u, e) async {
          llamadas++;
          return true;
        },
      );

      expect(llamadas, 0);
      expect(pintado, [null, 'generico']);
    });

    testWidgets('contra un filial tampoco espera: es nuestro escudo', (
      tester,
    ) async {
      var llamadas = 0;

      await generar(
        tester,
        datos(url: _ruta7, propio: true),
        precarga: (c, u, e) async {
          llamadas++;
          return true;
        },
      );

      expect(llamadas, 0);
    });

    testWidgets(
      'la espera por defecto es de 3 s y sin red cae al genérico enseguida',
      (tester) async {
        expect(CompartirPartido.esperaMaxima, const Duration(seconds: 3));

        pantalla(tester);
        late BuildContext contexto;

        await tester.pumpWidget(
          appCon(
            Builder(
              builder: (c) {
                contexto = c;
                return const SizedBox();
              },
            ),
          ),
        );

        final cargado = await tester.runAsync(
          () => CompartirPartido.precargarEscudo(
            contexto,
            _completa(_ruta7),
            const Duration(milliseconds: 500),
          ),
        );

        expect(cargado, isFalse);
      },
    );
  });
}
