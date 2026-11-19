import 'dart:async';

import 'package:app_mutxamel_cf/features/home/home_page.dart';
import 'package:app_mutxamel_cf/features/home/models/patrocinador.dart';
import 'package:app_mutxamel_cf/features/home/services/patrocinador_service.dart';
import 'package:app_mutxamel_cf/features/home/widgets/patrocinadores_seccion.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/features/news/models/news_model.dart';
import 'package:app_mutxamel_cf/features/news/services/news_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Partidos extends MatchService {
  @override
  Future<MatchModel?> obtenerResultadoPrimerEquipo() async => const MatchModel(
    categoria: 'Primer Equipo',
    equipo: 'Primer Equipo',
    rival: 'Pego C.F.',
    hora: '17:00',
  );
}

class _Noticias extends NewsService {
  @override
  Future<List<NewsModel>> obtenerNoticias({
    int? antesId,
    int limite = 5,
  }) async => const [];
}

class _Patrocinadores extends PatrocinadorService {
  List<Patrocinador> lista;
  bool fallar = false;
  int llamadas = 0;
  Completer<void>? espera;

  _Patrocinadores(this.lista);

  @override
  Future<List<Patrocinador>> obtenerPatrocinadores() async {
    llamadas++;
    await espera?.future;
    if (fallar) throw Exception('sin red');
    return lista;
  }
}

const _siete = [
  Patrocinador(
    nombre: 'Frutas y verduras Juanete',
    imagenUrl: '/images/frutasJuanete.jpg',
    url: 'https://www.instagram.com/frutasjuanete/',
  ),
  Patrocinador(
    nombre: 'Unlimited Developments',
    imagenUrl: '/images/unlimited.jpg',
    url: 'https://www.unlimiteddevelopments.es/',
  ),
  Patrocinador(
    nombre: 'Ayto Mutxamel',
    imagenUrl: '/images/aytoMutxamel.jpg',
    url: 'https://ayto.mutxamel.org/',
  ),
  Patrocinador(
    nombre: 'La bodega de Elias',
    imagenUrl: '/images/laBodega.jpg',
    url: 'https://www.instagram.com/labodegaelias/',
    circular: true,
  ),
  Patrocinador(nombre: 'Aresala', imagenUrl: '/images/aresala.jpg'),
  Patrocinador(
    nombre: 'AA Energy',
    imagenUrl: '/images/aaenergy.jpeg',
    url: 'https://www.aaenergyenriquez.es',
  ),
  Patrocinador(
    nombre: 'Dental Company Mutxamel',
    imagenUrl: '/images/dentalcompany.jpg',
    url: 'https://clinicas.dentalcompany.es/',
  ),
];

final _urlsPedidas = <String>[];

Future<void> _pintar(
  WidgetTester tester,
  _Patrocinadores servicio, {
  Brightness brillo = Brightness.light,
  double letra = 1,
  Size tamano = const Size(390, 2400),
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  _urlsPedidas.clear();
  PatrocinadoresSeccion.constructorDeRed = (url, circular, alternativa) {
    _urlsPedidas.add(url);
    return Container(
      key: ValueKey('logo-$url'),
      color: const Color(0xFF123456),
    );
  };
  addTearDown(() => PatrocinadoresSeccion.constructorDeRed = null);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brillo),
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(letra)),
        child: child!,
      ),
      home: HomePage(
        matchService: _Partidos(),
        newsService: _Noticias(),
        patrocinadorService: servicio,
        avisosDeResultados: const Stream<void>.empty(),
      ),
    ),
  );

  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
}

void main() {
  _seccionSola();

  testWidgets('carga la lista y la pinta en orden con el nombre de cada uno', (
    tester,
  ) async {
    await _pintar(tester, _Patrocinadores(_siete));

    expect(find.text('Nuestros patrocinadores'), findsOneWidget);
    expect(find.textContaining('Pulsa en un patrocinador'), findsOneWidget);

    for (final p in _siete) {
      expect(find.text(p.nombre), findsOneWidget);
    }

    // La URL de imagen lleva la base del servidor delante y sale en el orden de la lista.
    expect(_urlsPedidas.length, _siete.length);
    for (var i = 0; i < _siete.length; i++) {
      expect(_urlsPedidas[i], endsWith(_siete[i].imagenUrl));
      expect(_urlsPedidas[i], startsWith('https://'));
    }

    final posiciones = _siete
        .map((p) => tester.getTopLeft(find.text(p.nombre)))
        .toList();
    for (var i = 1; i < posiciones.length; i++) {
      final a = posiciones[i - 1];
      final b = posiciones[i];
      expect(
        b.dy > a.dy || (b.dy == a.dy && b.dx > a.dx),
        isTrue,
        reason: 'orden roto en $i',
      );
    }
  });

  testWidgets('sin url no es navegable y con url sí', (tester) async {
    await _pintar(tester, _Patrocinadores(_siete));

    InkWell tocable(String nombre) => tester.widget<InkWell>(
      find.ancestor(of: find.text(nombre), matching: find.byType(InkWell)),
    );

    expect(
      find.ancestor(of: find.text('Aresala'), matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(tocable('Ayto Mutxamel').onTap, isNotNull);
    expect(tocable('La bodega de Elias').onTap, isNotNull);
  });

  testWidgets(
    'solo el circular se recorta en círculo y hay etiqueta de accesibilidad',
    (tester) async {
      final semantica = tester.ensureSemantics();

      await _pintar(tester, _Patrocinadores(_siete));

      double radio(String nombre) {
        final tile = find.ancestor(
          of: find.text(nombre),
          matching: find.byType(Card),
        );
        final clip = tester.widget<ClipRRect>(
          find.descendant(of: tile, matching: find.byType(ClipRRect)).first,
        );
        return (clip.borderRadius as BorderRadius).topLeft.x;
      }

      expect(radio('La bodega de Elias'), 100);
      expect(radio('Ayto Mutxamel'), 8);
      expect(radio('Aresala'), 8);

      expect(find.bySemanticsLabel('Aresala'), findsOneWidget);
      expect(find.bySemanticsLabel('AA Energy'), findsOneWidget);

      semantica.dispose();
    },
  );

  testWidgets('mientras carga hay un hueco y no se ve el subtítulo', (
    tester,
  ) async {
    final servicio = _Patrocinadores(_siete)..espera = Completer<void>();

    await _pintar(tester, servicio);

    expect(
      find.byKey(const ValueKey('patrocinadores-cargando')),
      findsOneWidget,
    );
    expect(find.text('Ayto Mutxamel'), findsNothing);

    servicio.espera!.complete();
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }

    expect(find.byKey(const ValueKey('patrocinadores-cargando')), findsNothing);
    expect(find.text('Ayto Mutxamel'), findsOneWidget);
  });

  testWidgets('si falla, la sección no se muestra y no hay mensajes de error', (
    tester,
  ) async {
    await _pintar(tester, _Patrocinadores(_siete)..fallar = true);

    expect(find.text('Nuestros patrocinadores'), findsNothing);
    expect(find.textContaining('Pulsa en un patrocinador'), findsNothing);
    expect(find.byKey(const ValueKey('patrocinadores-cargando')), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('si la lista viene vacía, la sección no se muestra', (
    tester,
  ) async {
    await _pintar(tester, _Patrocinadores(const []));

    expect(find.text('Nuestros patrocinadores'), findsNothing);
    expect(find.textContaining('Pulsa en un patrocinador'), findsNothing);
  });

  testWidgets('tirar para refrescar vuelve a pedir la lista', (tester) async {
    final servicio = _Patrocinadores(_siete.sublist(0, 2));

    await _pintar(tester, servicio);

    expect(servicio.llamadas, 1);
    expect(find.text('Ayto Mutxamel'), findsNothing);

    servicio.lista = _siete;

    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, 400),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(servicio.llamadas, 2);
    expect(find.text('Ayto Mutxamel'), findsOneWidget);
  });

  testWidgets('modo oscuro, letra grande y iPhone pequeño sin desbordes', (
    tester,
  ) async {
    await _pintar(
      tester,
      _Patrocinadores(_siete),
      brillo: Brightness.dark,
      letra: 1.5,
      tamano: const Size(375, 4000),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Aresala'), findsOneWidget);
  });
}

void _seccionSola() {
  testWidgets('la sección sola a letra x2 en 320 px no desborda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    PatrocinadoresSeccion.constructorDeRed = (u, c, a) => Container();
    addTearDown(() => PatrocinadoresSeccion.constructorDeRed = null);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: PatrocinadoresSeccion(
              cargando: false,
              patrocinadores: _siete,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
