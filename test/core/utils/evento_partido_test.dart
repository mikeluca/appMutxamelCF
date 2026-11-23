import 'package:app_mutxamel_cf/core/utils/anadir_al_calendario.dart';
import 'package:app_mutxamel_cf/core/utils/evento_partido.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_partido_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/equipacion_model.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/pages/matches_page.dart';
import 'package:app_mutxamel_cf/features/matches/widgets/match_card.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget hijo, {String idioma = 'es'}) {
  return MaterialApp(
    locale: Locale(idioma),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: hijo)),
  );
}

MatchModel _partido({
  String equipo = 'Primer Equipo',
  String rival = 'Pego',
  bool local = true,
  DateTime? dia,
  String? hora = '17:00',
  String? campo = 'Camp Municipal',
  String? tipo = 'Liga',
  String? resultado,
  bool cancelado = false,
}) {
  return MatchModel(
    id: 7,
    categoria: 'Senior',
    equipo: equipo,
    rival: rival,
    local: local,
    dia: dia ?? DateTime(2099, 11, 14),
    hora: hora,
    campo: campo,
    tipo: tipo,
    resultado: resultado,
    cancelado: cancelado,
  );
}

void main() {
  late AppLocalizations es;
  late AppLocalizations ca;
  late AppLocalizations en;

  setUpAll(() async {
    es = await AppLocalizations.delegate.load(const Locale('es'));
    ca = await AppLocalizations.delegate.load(const Locale('ca'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('título', () {
    test(
      'local: "Mutxamel C.F. - Rival"; visitante: "Rival - Mutxamel C.F."',
      () {
        expect(
          EventoPartido.titulo(
            equipo: 'Primer Equipo',
            rival: 'Pego',
            local: true,
          ),
          'Mutxamel C.F. - Pego',
        );
        expect(
          EventoPartido.titulo(
            equipo: 'Primer Equipo',
            rival: 'Pego',
            local: false,
          ),
          'Pego - Mutxamel C.F.',
        );
      },
    );

    test('con el equipo si no es el Primer Equipo', () {
      expect(
        EventoPartido.titulo(equipo: 'Infantil A', rival: 'Pego', local: true),
        'Mutxamel C.F. Infantil A - Pego',
      );
      expect(
        EventoPartido.titulo(equipo: 'Infantil A', rival: 'Pego', local: false),
        'Pego - Mutxamel C.F. Infantil A',
      );
    });
  });

  group('hora y duración', () {
    test('la hora es la de España: UTC+1 en invierno', () {
      final e = EventoPartido.desdeMatch(
        _partido(dia: DateTime(2026, 11, 14), hora: '17:00'),
        es,
      )!;

      expect(e.todoElDia, isFalse);
      expect(e.zonaHoraria, 'Europe/Madrid');
      expect(e.inicio, DateTime.utc(2026, 11, 14, 16));
    });

    test('y UTC+2 en verano', () {
      final e = EventoPartido.desdeMatch(
        _partido(dia: DateTime(2027, 4, 11), hora: '17:00'),
        es,
      )!;

      expect(e.inicio, DateTime.utc(2027, 4, 11, 15));
    });

    test('los cambios de hora: el último domingo de marzo y de octubre', () {
      // 2027: 28 de marzo y 31 de octubre
      expect(
        EventoPartido.instanteEnEspana(2027, 3, 27, 12, 0),
        DateTime.utc(2027, 3, 27, 11),
      );
      expect(
        EventoPartido.instanteEnEspana(2027, 3, 28, 12, 0),
        DateTime.utc(2027, 3, 28, 10),
      );
      expect(
        EventoPartido.instanteEnEspana(2027, 10, 30, 12, 0),
        DateTime.utc(2027, 10, 30, 10),
      );
      expect(
        EventoPartido.instanteEnEspana(2027, 10, 31, 12, 0),
        DateTime.utc(2027, 10, 31, 11),
      );
    });

    test('2 h en Fútbol 11 y 1 h 30 en Fútbol 8 y Fútbol 5', () {
      EventoCalendario evento(String equipo, {String? modalidad}) =>
          EventoPartido.montar(
            es,
            equipo: equipo,
            rival: 'X',
            local: true,
            dia: DateTime(2026, 11, 14),
            hora: '10:00',
            modalidad: modalidad,
          );

      Duration dur(EventoCalendario e) => e.fin.difference(e.inicio);

      expect(dur(evento('Primer Equipo')), const Duration(hours: 2));
      expect(dur(evento('Cadete B')), const Duration(hours: 2));
      expect(dur(evento('Alevín A')), const Duration(minutes: 90));
      expect(dur(evento('Benjamín B')), const Duration(minutes: 90));
      expect(
        dur(evento('Cualquiera', modalidad: 'F8')),
        const Duration(minutes: 90),
      );
      expect(
        dur(evento('Cualquiera', modalidad: 'F5')),
        const Duration(minutes: 90),
      );
      // Lo que manda el backend gana al nombre del equipo
      expect(
        dur(evento('Alevín A', modalidad: 'F11')),
        const Duration(hours: 2),
      );
    });

    test('sin hora, evento de todo el día', () {
      for (final hora in [null, '', '  ', 'por confirmar']) {
        final e = EventoPartido.desdeMatch(_partido(hora: hora), es)!;

        expect(e.todoElDia, isTrue, reason: 'hora "$hora"');
        expect(e.inicio, DateTime.utc(2099, 11, 14));
        expect(e.zonaHoraria, isNull);
      }
    });
  });

  group('lugar y notas', () {
    test('el lugar es el campo tal cual', () {
      expect(
        EventoPartido.desdeMatch(
          _partido(campo: ' Camp Nou Los Olmos '),
          es,
        )!.lugar,
        'Camp Nou Los Olmos',
      );
      expect(
        EventoPartido.desdeMatch(_partido(campo: null), es)!.lugar,
        isNull,
      );
    });

    test('competición y jornada en las notas, si las hay', () {
      final completo = EventoPartido.desdeMatch(
        _partido(tipo: 'Liga'),
        es,
        jornada: 12,
      )!;
      final sinJornada = EventoPartido.desdeMatch(_partido(tipo: 'Liga'), es)!;
      final nada = EventoPartido.desdeMatch(_partido(tipo: null), es)!;

      expect(completo.descripcion, 'Liga\nJornada 12');
      expect(sinJornada.descripcion, 'Liga');
      expect(nada.descripcion, isNull);
    });

    test(
      'con convocatoria, la citación y el equipaje (y en el idioma de la app)',
      () {
        const notas = NotasConvocatoria(
          horaCitacion: '09:30',
          lugarCitacion: 'Vestuarios',
          equipaje: 'Segunda',
        );

        expect(
          EventoPartido.desdeMatch(
            _partido(),
            es,
            convocatoria: notas,
          )!.descripcion,
          'Liga\nHora de citación: 09:30\nLugar de citación: Vestuarios\nEquipaje: Segunda',
        );
        expect(
          EventoPartido.desdeMatch(
            _partido(),
            ca,
            convocatoria: notas,
          )!.descripcion,
          'Liga\nHora de citació: 09:30\nLloc de citació: Vestuarios\nEquipació: Segunda',
        );
        expect(
          EventoPartido.desdeMatch(
            _partido(),
            en,
            convocatoria: notas,
          )!.descripcion,
          'Liga\nMeeting time: 09:30\nMeeting place: Vestuarios\nKit: Segunda',
        );
      },
    );

    test(
      'solo lo que haya de la convocatoria, y nunca datos de otros jugadores',
      () {
        const soloHora = NotasConvocatoria(horaCitacion: '09:30');

        expect(
          EventoPartido.desdeMatch(
            _partido(tipo: null),
            es,
            convocatoria: soloHora,
          )!.descripcion,
          'Hora de citación: 09:30',
        );

        const completa = ConvocatoriaPartidoModel(
          convocatoriaId: 1,
          rival: 'Pego',
          convocado: true,
          horaCitacion: '09:30',
          lugarCitacion: 'Vestuarios',
          equipacion: EquipacionModel(id: 1, nombre: 'Segunda'),
          convocados: [
            ConvocadoPartidoModel(
              nombre: 'Otro',
              apellidos: 'Jugador',
              dorsal: 9,
            ),
          ],
        );
        final descripcion = EventoPartido.desdeMatch(
          _partido(tipo: null),
          es,
          convocatoria: NotasConvocatoria.desde(completa),
        )!.descripcion!;

        expect(descripcion, isNot(contains('Otro')));
        expect(descripcion, contains('Segunda'));
      },
    );

    test('un partido sin día no se puede añadir', () {
      expect(
        EventoPartido.desdeMatch(
          const MatchModel(categoria: 'C', equipo: 'Primer Equipo', rival: 'X'),
          es,
        ),
        isNull,
      );
    });
  });

  group('botón en las tarjetas', () {
    late List<EventoCalendario> anadidos;

    setUp(() {
      anadidos = [];

      final original = AnadirAlCalendario.enviar;
      AnadirAlCalendario.enviar = (e) async {
        anadidos.add(e);
        return true;
      };
      addTearDown(() => AnadirAlCalendario.enviar = original);
    });

    testWidgets('un partido por jugar lo lleva y añade el evento', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(MatchCard(match: _partido(equipo: 'Infantil A', local: false))),
      );

      expect(find.text('Añadir a mi calendario'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('anadir-calendario')));
      await tester.pumpAndSettle();

      expect(anadidos, hasLength(1));
      expect(anadidos.single.titulo, 'Pego - Mutxamel C.F. Infantil A');
      expect(anadidos.single.lugar, 'Camp Municipal');
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
      'un partido ya jugado, con resultado, cancelado o pasado no lo lleva',
      (tester) async {
        for (final partido in [
          _partido(resultado: '2-1'),
          _partido(cancelado: true),
          _partido(dia: DateTime(2020, 1, 1)),
        ]) {
          await tester.pumpWidget(_app(MatchCard(match: partido)));
          await tester.pump();

          expect(find.byKey(const ValueKey('anadir-calendario')), findsNothing);
        }
      },
    );

    testWidgets('en las listas públicas de partidos también', (tester) async {
      await tester.pumpWidget(_app(PartidoListaCard(partido: _partido())));

      expect(find.byKey(const ValueKey('anadir-calendario')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('anadir-calendario')));
      await tester.pumpAndSettle();

      expect(anadidos.single.titulo, 'Mutxamel C.F. - Pego');

      await tester.pumpWidget(
        _app(PartidoListaCard(partido: _partido(resultado: '2-1'))),
      );
      expect(find.byKey(const ValueKey('anadir-calendario')), findsNothing);
    });

    testWidgets(
      'en Mis partidos, con convocatoria, las notas llevan la citación y el equipaje',
      (tester) async {
        await tester.pumpWidget(
          _app(
            MatchCard(
              match: _partido(),
              notasConvocatoria: (partido) async => const NotasConvocatoria(
                horaCitacion: '09:30',
                lugarCitacion: 'Vestuarios',
                equipaje: 'Segunda',
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('anadir-calendario')));
        await tester.pumpAndSettle();

        expect(
          anadidos.single.descripcion,
          'Liga\nHora de citación: 09:30\nLugar de citación: Vestuarios\nEquipaje: Segunda',
        );
      },
    );

    testWidgets(
      'en Mis partidos, sin convocatoria, el evento va sin esas notas',
      (tester) async {
        await tester.pumpWidget(
          _app(
            MatchCard(
              match: _partido(),
              notasConvocatoria: (partido) async => null,
            ),
          ),
        );

        await tester.tap(find.byKey(const ValueKey('anadir-calendario')));
        await tester.pumpAndSettle();

        expect(anadidos.single.descripcion, 'Liga');
      },
    );
  });

  group('si el sistema no lo añade', () {
    late int ajustes;

    setUp(() {
      ajustes = 0;
      final abrir = AnadirAlCalendario.abrirAjustes;
      final ios = AnadirAlCalendario.esIos;
      final enviar = AnadirAlCalendario.enviar;
      AnadirAlCalendario.abrirAjustes = () async => ajustes++;
      addTearDown(() {
        AnadirAlCalendario.abrirAjustes = abrir;
        AnadirAlCalendario.esIos = ios;
        AnadirAlCalendario.enviar = enviar;
      });
    });

    testWidgets(
      'iOS: sin permiso (o al cancelar) un SnackBar con "Abrir ajustes", sin errores',
      (tester) async {
        AnadirAlCalendario.esIos = () => true;
        AnadirAlCalendario.enviar = (_) async => false;

        await tester.pumpWidget(_app(MatchCard(match: _partido())));
        await tester.tap(find.byKey(const ValueKey('anadir-calendario')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.textContaining('No se ha añadido el evento'),
          findsOneWidget,
        );

        await tester.tap(find.text('Abrir ajustes'));
        await tester.pumpAndSettle();

        expect(ajustes, 1);
      },
    );

    testWidgets('si falla el calendario del sistema, un aviso y nada más', (
      tester,
    ) async {
      AnadirAlCalendario.esIos = () => false;
      AnadirAlCalendario.enviar = (_) async =>
          throw Exception('sin calendario');

      await tester.pumpWidget(_app(MatchCard(match: _partido())));
      await tester.tap(find.byKey(const ValueKey('anadir-calendario')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('No se ha podido añadir el partido al calendario.'),
        findsOneWidget,
      );
    });

    testWidgets('Android: al añadir bien no sale ningún aviso', (tester) async {
      AnadirAlCalendario.esIos = () => false;
      AnadirAlCalendario.enviar = (_) async => true;

      await tester.pumpWidget(_app(MatchCard(match: _partido())));
      await tester.tap(find.byKey(const ValueKey('anadir-calendario')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
