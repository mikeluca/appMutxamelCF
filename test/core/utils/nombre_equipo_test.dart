import 'package:app_mutxamel_cf/core/utils/nombre_equipo.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/pages/matches_page.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('nombreEquipoCorto: quita las siglas de la entidad', () {
    const tabla = <String, String>{
      // Los ejemplos del encargo.
      'C.D. Salesianos Alicante': 'Salesianos Alicante',
      'Alicante Coty F.C.': 'Alicante Coty',
      'C. F. Gata "A"': 'Gata "A"',
      'U.D. Altea S.A.D.': 'Altea',
      // Con puntos, con o sin espacios.
      'C.F. Benidorm': 'Benidorm',
      'S.D. Xàbia': 'Xàbia',
      'U.E. Sant Joan': 'Sant Joan',
      'C.E. Mutxamel': 'Mutxamel',
      'A.C. Torrellano': 'Torrellano',
      'C.D.E. Ciudad de Alicante': 'Ciudad de Alicante',
      'Juventud C. D. E. "B"': 'Juventud "B"',
      // Sin puntos, como palabra aparte en mayúsculas.
      'CF Villena': 'Villena',
      'Elche FC': 'Elche',
      'CD Calpe': 'Calpe',
      'UD Alzira SAD': 'Alzira',
      'SD Teulada "A"': 'Teulada "A"',
      'Racing CDE San Vicente': 'Racing San Vicente',
      // Las comillas, tal como vengan (rectas o tipográficas).
      'C.D. Campello "B"': 'Campello "B"',
      'F.C. Jove Español “A”': 'Jove Español “A”',
      "C. F. Alacant 'C'": "Alacant 'C'",
      // Espacios sobrantes y guiones o comas sueltos.
      '  C.D.   Muchamiel  ': 'Muchamiel',
      'Gata, C.F.': 'Gata',
      '- U.D. Orihuela -': 'Orihuela',
      // Solo siglas: se deja el nombre original.
      'C.F.': 'C.F.',
      'S.A.D.': 'S.A.D.',
      'CF': 'CF',
      // Sin siglas: igual.
      'Hércules': 'Hércules',
      'Atlético Benidorm': 'Atlético Benidorm',
      'Real Murcia "B"': 'Real Murcia "B"',
      // Ni otras palabras ni letras sueltas sin punto ni palabras que solo contienen las letras.
      'Alicante Club de Fútbol': 'Alicante Club de Fútbol',
      'Cadete Facultad': 'Cadete Facultad',
      'Atl. Benidorm': 'Atl. Benidorm',
    };

    tabla.forEach((entrada, esperado) {
      test('«$entrada» → «$esperado»', () {
        expect(nombreEquipoCorto(entrada), esperado);
      });
    });
  });

  group('nombreRivalVisible: el Mutxamel y los equipos propios no cambian', () {
    test('el Mutxamel sigue como hoy', () {
      expect(nombreRivalVisible('Mutxamel C.F.'), 'Mutxamel C.F.');
      expect(nombreRivalVisible('Mutxamel CF'), 'Mutxamel CF');
      expect(nombreRivalVisible('MUTXAMEL C.F. "B"'), 'MUTXAMEL C.F. "B"');
    });

    test('un equipo propio (el filial) sigue como viene', () {
      expect(nombreRivalVisible('C.F. Filial', esPropio: true), 'C.F. Filial');
      expect(nombreRivalVisible('Filial'), 'Filial');
    });

    test('un rival normal pierde las siglas', () {
      expect(
        nombreRivalVisible('C.D. Salesianos Alicante'),
        'Salesianos Alicante',
      );
    });
  });

  testWidgets(
    'la tarjeta de la pestaña Partidos enseña el rival sin siglas, pero el dato no cambia',
    (tester) async {
      const partido = MatchModel(
        categoria: 'Alevín',
        equipo: 'Mutxamel C.F.',
        rival: 'U.D. Altea S.A.D.',
        dia: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: const Scaffold(body: PartidoListaCard(partido: partido)),
        ),
      );

      expect(find.text('Altea'), findsOneWidget);
      expect(find.text('U.D. Altea S.A.D.'), findsNothing);
      // El nombre que se manda y se guarda sigue siendo el original.
      expect(partido.rival, 'U.D. Altea S.A.D.');
    },
  );
}
