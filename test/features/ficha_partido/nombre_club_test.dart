import 'dart:io';

import 'package:app_mutxamel_cf/core/constants/app_constants.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/models/ficha_partido_model.dart';
import 'package:app_mutxamel_cf/features/ficha_partido/widgets/ficha_cabecera.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../directo/harness.dart';

Map<String, dynamic> _json({
  String local = 'Mutxamel CF',
  String visitante = 'Pego C.F.',
  Object? mutxamelLocal = _sinCampo,
}) => {
  'partidoId': 30,
  'equipoLocal': local,
  'equipoVisitante': visitante,
  'estado': 'FINALIZADO',
  'golesFavor': 2,
  'golesContra': 1,
  if (!identical(mutxamelLocal, _sinCampo)) 'mutxamelLocal': mutxamelLocal,
};

const Object _sinCampo = Object();

void main() {
  group('el nombre del club es "Mutxamel C.F."', () {
    test('en las constantes y en los textos de la app (es, ca, en)', () {
      expect(AppConstants.appName, 'Mutxamel C.F.');
      expect(CabeceraFicha.nombreClub, 'Mutxamel C.F.');

      for (final idioma in ['es', 'ca', 'en']) {
        final texto = File('lib/l10n/app_$idioma.arb').readAsStringSync();

        expect(
          texto.contains('Mutxamel CF'),
          isFalse,
          reason: 'app_$idioma.arb',
        );
        expect(
          texto.contains('MUTXAMEL CF'),
          isFalse,
          reason: 'app_$idioma.arb',
        );
        expect(texto, contains('Mutxamel C.F.'), reason: 'app_$idioma.arb');
      }
    });

    testWidgets('los textos principales salen con puntos en los tres idiomas', (
      tester,
    ) async {
      for (final (idioma, pie, acerca) in [
        (
          'es',
          'Síguelo en la app del Mutxamel C.F.',
          'Acerca de Mutxamel C.F.',
        ),
        ('ca', "Segueix-lo a l'app del Mutxamel C.F.", 'Sobre Mutxamel C.F.'),
        ('en', 'Follow it in the Mutxamel C.F. app', 'About Mutxamel C.F.'),
      ]) {
        late AppLocalizations t;

        await tester.pumpWidget(
          appCon(
            Builder(
              builder: (context) {
                t = AppLocalizations.of(context);
                return const SizedBox();
              },
            ),
            locale: Locale(idioma),
          ),
        );

        expect(t.shareImageFooter, pie);
        expect(t.settingsAboutApp, acerca);
        expect(t.liveCardTeamClub, 'Mutxamel C.F.');
      }
    });

    test('el nombre bajo el icono (Android e iOS) lleva puntos', () {
      expect(
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
        contains('android:label="Mutxamel C.F."'),
      );

      final plist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(
        RegExp(
          r'<key>CFBundleDisplayName</key>\s*<string>Mutxamel C\.F\.</string>',
        ).hasMatch(plist),
        isTrue,
      );
      expect(
        RegExp(
          r'<key>CFBundleName</key>\s*<string>Mutxamel C\.F\.</string>',
        ).hasMatch(plist),
        isTrue,
      );
    });

    test('los identificadores no cambian', () {
      final gradle = File('android/app/build.gradle.kts').existsSync()
          ? File('android/app/build.gradle.kts').readAsStringSync()
          : File('android/app/build.gradle').readAsStringSync();

      expect(gradle.contains('Mutxamel C.F.'), isFalse);
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('version: 1.0.11+19'),
      );
    });
  });

  group('qué lado es el Mutxamel en la ficha', () {
    test(
      'con backend nuevo manda mutxamelLocal, aunque los nombres no digan nada',
      () {
        final local = CabeceraFicha.fromJson(
          _json(local: 'Mutxamel C.F.', mutxamelLocal: true),
        );
        expect(local.mutxamelLocal, isTrue);
        expect(local.mutxamelEsLocal, isTrue);

        final visitante = CabeceraFicha.fromJson(
          _json(
            local: 'Pego C.F.',
            visitante: 'Mutxamel CF',
            mutxamelLocal: false,
          ),
        );
        expect(visitante.mutxamelEsLocal, isFalse);

        // mutxamelLocal gana al nombre.
        final contradictorio = CabeceraFicha.fromJson(
          _json(local: 'Mutxamel CF', visitante: 'Otro', mutxamelLocal: false),
        );
        expect(contradictorio.mutxamelEsLocal, isFalse);
      },
    );

    test('con backend antiguo se compara el nombre, con o sin puntos', () {
      for (final nombre in [
        'Mutxamel CF',
        'Mutxamel C.F.',
        ' mutxamel c.f. ',
        'MUTXAMEL CF',
      ]) {
        final c = CabeceraFicha.fromJson(_json(local: nombre));

        expect(c.mutxamelLocal, isNull, reason: nombre);
        expect(c.mutxamelEsLocal, isTrue, reason: nombre);
        expect(c.golesLocal, 2);
      }

      final visitante = CabeceraFicha.fromJson(
        _json(local: 'Pego C.F.', visitante: 'Mutxamel CF'),
      );

      expect(visitante.mutxamelEsLocal, isFalse);
      expect(visitante.golesLocal, 1);
      expect(visitante.golesVisitante, 2);
    });

    test('un rival con Mutxamel en el nombre no es el club', () {
      expect(CabeceraFicha.esNombreClub('Atlético Mutxamel'), isFalse);
      expect(CabeceraFicha.esNombreClub('Mutxamel C.F. B'), isFalse);
      expect(CabeceraFicha.esNombreClub('Mutxamel CF'), isTrue);
      expect(CabeceraFicha.esNombreClub('Mutxamel C.F.'), isTrue);
    });

    test(
      'el nombre que se pinta es siempre "Mutxamel C.F." en nuestro lado',
      () {
        final local = CabeceraFicha.fromJson(_json());

        expect(local.nombreLocal, 'Mutxamel C.F.');
        expect(local.nombreVisitante, 'Pego C.F.');

        final visitante = CabeceraFicha.fromJson(
          _json(
            local: 'Pego C.F.',
            visitante: 'Mutxamel CF',
            mutxamelLocal: false,
          ),
        );

        expect(visitante.nombreLocal, 'Pego C.F.');
        expect(visitante.nombreVisitante, 'Mutxamel C.F.');
      },
    );

    testWidgets(
      'la cabecera de la ficha muestra "Mutxamel C.F." con el backend antiguo y con el nuevo',
      (tester) async {
        for (final json in [
          _json(),
          _json(local: 'Mutxamel C.F.', mutxamelLocal: true),
        ]) {
          await tester.pumpWidget(
            appCon(FichaCabecera(cabecera: CabeceraFicha.fromJson(json))),
          );

          expect(find.text('Mutxamel C.F.'), findsOneWidget);
          expect(find.text('Mutxamel CF'), findsNothing);
          expect(find.text('Pego C.F.'), findsOneWidget);
        }

        // De visitante, el nuestro a la derecha.
        await tester.pumpWidget(
          appCon(
            FichaCabecera(
              cabecera: CabeceraFicha.fromJson(
                _json(
                  local: 'Pego C.F.',
                  visitante: 'Mutxamel CF',
                  mutxamelLocal: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Mutxamel C.F.'), findsOneWidget);
        expect(
          tester.getCenter(find.byKey(const ValueKey('escudo-mutxamel'))).dx,
          greaterThan(
            tester.getCenter(find.byKey(const ValueKey('escudo-rival'))).dx,
          ),
        );
      },
    );
  });

  group('los datos nuevos de la cabecera', () {
    test('goleadores, campo y jornada', () {
      final c = CabeceraFicha.fromJson({
        ..._json(mutxamelLocal: true),
        'goleadores': [
          {
            'nombre': 'Pepe',
            'goles': 2,
            'minutos': [23, 67],
          },
          {'nombre': 'Juanma', 'goles': 1, 'minutos': <int>[]},
        ],
        'campo': ' Camp Municipal ',
        'jornada': 9,
      });

      expect(c.goleadores, hasLength(2));
      expect(c.goleadores[0].nombre, 'Pepe');
      expect(c.goleadores[0].goles, 2);
      expect(c.goleadores[0].minutos, [23, 67]);
      expect(c.goleadores[1].minutos, isEmpty);
      expect(c.campo, 'Camp Municipal');
      expect(c.jornada, 9);
    });

    test('sin ellos (backend antiguo) o vacíos: lista vacía y null', () {
      final c = CabeceraFicha.fromJson(_json());

      expect(c.goleadores, isEmpty);
      expect(c.campo, isNull);
      expect(c.jornada, isNull);
      expect(CabeceraFicha.fromJson({..._json(), 'campo': '  '}).campo, isNull);
    });
  });
}
