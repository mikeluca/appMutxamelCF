import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/equipacion_model.dart';
import 'package:app_mutxamel_cf/features/home/home_page.dart';
import 'package:app_mutxamel_cf/features/home/models/proximo_partido.dart';
import 'package:app_mutxamel_cf/features/home/services/proximos_partidos_service.dart';
import 'package:app_mutxamel_cf/features/home/widgets/proximo_partido_seccion.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/features/news/models/news_model.dart';
import 'package:app_mutxamel_cf/features/news/services/news_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

class _PartidosFalsos extends MatchService {
  @override
  Future<MatchModel?> obtenerResultadoPrimerEquipo() async => const MatchModel(
    categoria: 'Primer Equipo',
    equipo: 'Primer Equipo',
    rival: 'Pego',
    hora: '17:00',
  );
}

class _NoticiasFalsas extends NewsService {
  @override
  Future<List<NewsModel>> obtenerNoticias({
    int? antesId,
    int limite = 5,
  }) async => const [];
}

class _ProximosFalsos extends ProximosPartidosService {
  final List<ProximoPartido> entradas;
  bool fallar = false;
  int llamadas = 0;

  _ProximosFalsos([this.entradas = const []]);

  @override
  Future<List<ProximoPartido>> obtener() async {
    llamadas++;

    if (fallar) throw Exception('servidor caído');

    return entradas;
  }
}

MatchModel _partido({
  int id = 30,
  String equipo = 'Alevín B',
  String rival = 'C.D. Pego',
  String campo = 'Camp Nou Los Olmos',
  bool local = true,
}) => MatchModel(
  id: id,
  equipoId: 10,
  categoria: 'Alevín',
  equipo: equipo,
  rival: rival,
  dia: DateTime(2026, 11, 28),
  hora: '11:00',
  campo: campo,
  tipo: 'LIGA',
  local: local,
);

ProximoPartido _entrada({
  String tipo = 'FAMILIAR',
  String? nombre = 'Pablo García',
  ConvocatoriaProximoPartido? convocatoria,
  MatchModel? partido,
  bool descansa = false,
}) => ProximoPartido(
  tipo: tipo,
  jugadorId: tipo == 'ENTRENADOR' ? null : 100,
  nombreJugador: tipo == 'ENTRENADOR' ? null : nombre,
  equipoId: 10,
  nombreEquipo: 'Alevín B',
  partido: descansa ? null : (partido ?? _partido()),
  convocatoria: descansa ? null : convocatoria,
  descansa: descansa,
);

const _primera = EquipacionModel(
  id: 1,
  nombre: 'Primera',
  colorHex: '#00AA00',
  camiseta: 'verde',
);
const _segunda = EquipacionModel(id: 2, nombre: 'Segunda', colorHex: '#FFFFFF');

const _delegados = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Widget _app(
  Widget home, {
  Locale locale = const Locale('es'),
  ThemeData? tema,
}) => MaterialApp(
  locale: locale,
  theme: tema,
  localizationsDelegates: _delegados,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Future<void> _pintarHome(
  WidgetTester tester,
  _ProximosFalsos proximos, {
  void Function(ProximoPartido)? alTocar,
}) async {
  await tester.pumpWidget(
    _app(
      HomePage(
        matchService: _PartidosFalsos(),
        newsService: _NoticiasFalsas(),
        proximosPartidosService: proximos,
        alTocarProximoPartido: alTocar,
        avisosDeResultados: const Stream<void>.empty(),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

Future<void> _pintarTarjeta(
  WidgetTester tester,
  ProximoPartido entrada, {
  Locale locale = const Locale('es'),
}) async {
  await tester.pumpWidget(
    _app(
      Scaffold(
        body: SingleChildScrollView(
          child: TarjetaProximoPartido(entrada: entrada, onTocar: () {}),
        ),
      ),
      locale: locale,
    ),
  );
  await tester.pump();
}

Future<void> _conSesion() => AuthManager.establecerUsuario(
  AuthUser(usuarioId: 1, email: 'a@b.c', roles: const ['FAMILIAR']),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await initializeDateFormatting('ca');
    await initializeDateFormatting('en');
  });

  setUp(AuthManager.olvidarUsuario);
  tearDown(AuthManager.olvidarUsuario);

  group('la sección en Inicio', () {
    testWidgets('sin sesión no aparece y ni se pide', (tester) async {
      final proximos = _ProximosFalsos([_entrada()]);

      await _pintarHome(tester, proximos);

      expect(find.text('Tu próximo partido'), findsNothing);
      expect(
        find.byKey(const ValueKey('proximo-partido-seccion')),
        findsNothing,
      );
      expect(proximos.llamadas, 0);
    });

    testWidgets('con sesión y la lista vacía no aparece', (tester) async {
      await _conSesion();

      await _pintarHome(tester, _ProximosFalsos());

      expect(find.text('Tu próximo partido'), findsNothing);
    });

    testWidgets('con una entrada, una tarjeta sin carrusel ni puntos', (
      tester,
    ) async {
      await _conSesion();

      await _pintarHome(tester, _ProximosFalsos([_entrada()]));

      expect(find.text('Tu próximo partido'), findsOneWidget);
      expect(find.byType(TarjetaProximoPartido), findsOneWidget);
      expect(
        find.byKey(const ValueKey('proximo-partido-carrusel')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('proximo-partido-puntos')),
        findsNothing,
      );
      expect(find.text('Pablo García · Alevín B'), findsOneWidget);
    });

    testWidgets('con tres entradas, carrusel con tres puntos', (tester) async {
      await _conSesion();

      await _pintarHome(
        tester,
        _ProximosFalsos([
          _entrada(nombre: 'Pablo García'),
          _entrada(nombre: 'Lucía García'),
          _entrada(tipo: 'ENTRENADOR'),
        ]),
      );

      expect(
        find.byKey(const ValueKey('proximo-partido-carrusel')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('proximo-partido-puntos')),
          matching: find.byType(AnimatedContainer),
        ),
        findsNWidgets(3),
      );
      final carrusel = find.byKey(const ValueKey('proximo-partido-carrusel'));

      expect(
        find.descendant(
          of: carrusel,
          matching: find.text('Pablo García · Alevín B'),
        ),
        findsOneWidget,
      );

      await tester.drag(
        find.byKey(const ValueKey('proximo-partido-carrusel')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: carrusel,
          matching: find.text('Lucía García · Alevín B'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: carrusel,
          matching: find.text('Pablo García · Alevín B'),
        ),
        findsNothing,
      );
    });

    testWidgets('al tocar la tarjeta se avisa con esa entrada', (tester) async {
      await _conSesion();

      final tocadas = <ProximoPartido>[];
      final entrada = _entrada();

      await _pintarHome(
        tester,
        _ProximosFalsos([entrada]),
        alTocar: tocadas.add,
      );

      await tester.tap(find.byType(TarjetaProximoPartido));
      await tester.pump();

      expect(tocadas, [entrada]);
    });

    testWidgets('un error del servidor no enseña ningún mensaje', (
      tester,
    ) async {
      await _conSesion();

      final proximos = _ProximosFalsos([_entrada()])..fallar = true;

      await _pintarHome(tester, proximos);

      expect(proximos.llamadas, 1);
      expect(find.text('Tu próximo partido'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('servidor caído'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tirar para actualizar vuelve a pedirlo', (tester) async {
      await _conSesion();

      final proximos = _ProximosFalsos([_entrada()]);

      await _pintarHome(tester, proximos);

      expect(proximos.llamadas, 1);

      await tester.fling(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(proximos.llamadas, 2);
    });

    testWidgets('al cambiar la sesión se pide, y al cerrarla desaparece', (
      tester,
    ) async {
      final proximos = _ProximosFalsos([_entrada()]);

      await _pintarHome(tester, proximos);

      expect(find.text('Tu próximo partido'), findsNothing);

      await _conSesion();
      await tester.pump();
      await tester.pump();

      expect(proximos.llamadas, 1);
      expect(find.text('Tu próximo partido'), findsOneWidget);

      AuthManager.olvidarUsuario();
      AuthManager.cambios.value++;
      await tester.pump();
      await tester.pump();

      expect(find.text('Tu próximo partido'), findsNothing);
    });

    testWidgets('al volver a la app se vuelve a pedir', (tester) async {
      await _conSesion();

      final proximos = _ProximosFalsos([_entrada()]);

      await _pintarHome(tester, proximos);
      expect(proximos.llamadas, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();

      expect(proximos.llamadas, 2);
    });
  });

  group('el estado de la convocatoria', () {
    testWidgets('CONVOCADO: citación, equipaje con su muestra y mochila', (
      tester,
    ) async {
      await _pintarTarjeta(
        tester,
        _entrada(
          convocatoria: const ConvocatoriaProximoPartido(
            estado: 'CONVOCADO',
            horaCitacion: '9:15',
            lugarCitacion: 'Camp Nou Los Olmos',
            equipaje: _primera,
            equipajeMochila: _segunda,
          ),
        ),
      );

      expect(
        find.textContaining(
          'Convocado · Citación 9:15 en Camp Nou Los Olmos · Equipaje Primera',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('En la mochila: Segunda'), findsOneWidget);
      // Las dos muestras de color (equipaje y mochila).
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('CONVOCADO sin mochila: una sola línea de estado', (
      tester,
    ) async {
      await _pintarTarjeta(
        tester,
        _entrada(
          convocatoria: const ConvocatoriaProximoPartido(
            estado: 'CONVOCADO',
            horaCitacion: '9:15',
            lugarCitacion: 'Camp Nou Los Olmos',
            equipaje: _primera,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('proximo-partido-estado')),
        findsOneWidget,
      );
      expect(find.textContaining('mochila'), findsNothing);
    });

    testWidgets('INVITADO: con qué equipo y la citación', (tester) async {
      await _pintarTarjeta(
        tester,
        _entrada(
          convocatoria: const ConvocatoriaProximoPartido(
            estado: 'INVITADO',
            horaCitacion: '9:30',
            lugarCitacion: 'Campo 2',
            equipoInvita: 'Alevín A',
          ),
        ),
      );

      expect(
        find.textContaining('Invitado con Alevín A · Citación 9:30 en Campo 2'),
        findsOneWidget,
      );
    });

    final simples = <String, (ProximoPartido, String)>{
      'NO_CONVOCADO': (
        _entrada(
          convocatoria: const ConvocatoriaProximoPartido(
            estado: 'NO_CONVOCADO',
          ),
        ),
        'No convocado',
      ),
      'AUSENCIA_JUSTIFICADA': (
        _entrada(
          convocatoria: const ConvocatoriaProximoPartido(
            estado: 'AUSENCIA_JUSTIFICADA',
          ),
        ),
        'Ausencia justificada',
      ),
      'SIN_CONVOCATORIA': (
        _entrada(
          convocatoria: const ConvocatoriaProximoPartido(
            estado: 'SIN_CONVOCATORIA',
          ),
        ),
        'Convocatoria aún no publicada',
      ),
      'entrenador PUBLICADA': (
        _entrada(
          tipo: 'ENTRENADOR',
          convocatoria: const ConvocatoriaProximoPartido(
            estado: 'PUBLICADA',
            numeroConvocados: 14,
            convocatoriaId: 5,
          ),
        ),
        'Convocatoria publicada · 14 convocados',
      ),
      'entrenador SIN_CONVOCATORIA': (
        _entrada(
          tipo: 'ENTRENADOR',
          convocatoria: const ConvocatoriaProximoPartido(
            estado: 'SIN_CONVOCATORIA',
          ),
        ),
        'Convocatoria sin publicar',
      ),
    };

    for (final caso in simples.entries) {
      testWidgets(caso.key, (tester) async {
        await _pintarTarjeta(tester, caso.value.$1);

        expect(find.text(caso.value.$2), findsOneWidget);
      });
    }

    testWidgets('la del entrenador dice "Tu equipo" en vez de un nombre', (
      tester,
    ) async {
      await _pintarTarjeta(tester, _entrada(tipo: 'ENTRENADOR'));

      expect(find.text('Tu equipo · Alevín B'), findsOneWidget);
    });

    testWidgets('descansa: sin partido, solo el aviso', (tester) async {
      await _pintarTarjeta(tester, _entrada(descansa: true));

      expect(find.text('Descansa esta jornada'), findsOneWidget);
      expect(find.text('Pablo García · Alevín B'), findsOneWidget);
      expect(find.text('vs'), findsNothing);
      expect(
        find.byKey(const ValueKey('proximo-partido-estado')),
        findsNothing,
      );
    });

    testWidgets(
      'el partido: rival sin siglas, fecha y hora en una línea y el campo',
      (tester) async {
        await _pintarTarjeta(
          tester,
          _entrada(
            convocatoria: const ConvocatoriaProximoPartido(
              estado: 'SIN_CONVOCATORIA',
            ),
          ),
        );

        expect(find.text('Pego'), findsOneWidget);
        expect(find.text('Alevín B'), findsWidgets);
        expect(find.textContaining('28/11/2026 · 11:00'), findsOneWidget);
        expect(find.text('Camp Nou Los Olmos'), findsOneWidget);
        expect(find.byIcon(Icons.directions), findsWidgets);
      },
    );

    testWidgets('en valenciano y en inglés', (tester) async {
      const convocado = ConvocatoriaProximoPartido(
        estado: 'CONVOCADO',
        horaCitacion: '9:15',
        lugarCitacion: 'Camp',
      );

      await _pintarTarjeta(
        tester,
        _entrada(convocatoria: convocado),
        locale: const Locale('ca'),
      );
      expect(
        find.textContaining('Convocat · Citació 9:15 a Camp'),
        findsOneWidget,
      );

      await _pintarTarjeta(
        tester,
        _entrada(convocatoria: convocado),
        locale: const Locale('en'),
      );
      expect(
        find.textContaining('Called up · Meet at 9:15 at Camp'),
        findsOneWidget,
      );
    });
  });

  group('que se vea bien', () {
    for (final oscuro in [false, true]) {
      testWidgets(
        'iPhone pequeño, letra grande y ${oscuro ? 'modo oscuro' : 'modo claro'}: tres tarjetas sin desbordar',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(2),
              ),
              child: _app(
                Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ProximoPartidoSeccion(
                      onTocar: (_) {},
                      entradas: [
                        _entrada(
                          partido: _partido(
                            equipo: 'Alevín B Provincial Grupo Norte',
                            rival: 'Club Deportivo Muy Largo De Verdad',
                            campo: 'Polideportivo Municipal Los Olmos Mutxamel',
                          ),
                          convocatoria: const ConvocatoriaProximoPartido(
                            estado: 'CONVOCADO',
                            horaCitacion: '9:15',
                            lugarCitacion: 'Camp Nou Los Olmos Mutxamel',
                            equipaje: _primera,
                            equipajeMochila: _segunda,
                          ),
                        ),
                        _entrada(descansa: true),
                        _entrada(tipo: 'ENTRENADOR'),
                      ],
                    ),
                  ),
                ),
                tema: oscuro ? ThemeData.dark() : ThemeData.light(),
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
