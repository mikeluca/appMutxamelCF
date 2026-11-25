import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/pages/club_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/club/models/pendientes.dart';
import 'package:app_mutxamel_cf/features/club/services/pendientes_service.dart';
import 'package:app_mutxamel_cf/features/club/widgets/tarjeta_pendientes.dart';
import 'package:app_mutxamel_cf/features/entrenamientos/model/entrenamiento_model.dart';
import 'package:app_mutxamel_cf/features/entrenamientos/services/entrenamiento_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _PendientesFalso extends PendientesService {
  List<GrupoPendiente> grupos;
  bool fallar = false;
  int llamadas = 0;

  _PendientesFalso(this.grupos);

  @override
  Future<List<GrupoPendiente>> obtener() async {
    llamadas++;

    if (fallar) throw Exception('servidor caído');

    return grupos;
  }
}

ElementoPendiente _elemento(
  String destino, {
  int? id,
  String texto = 'Un pendiente',
}) => ElementoPendiente(
  id: id,
  texto: texto,
  fecha: DateTime(2026, 11, 23),
  destino: destino,
  equipoId: 10,
  equipo: 'Alevín B',
  rival: 'Pego',
  hora: '11:00',
);

GrupoPendiente _grupo(
  String codigo,
  String titulo,
  int cantidad,
  List<ElementoPendiente> elementos,
) => GrupoPendiente(
  codigo: codigo,
  titulo: titulo,
  cantidad: cantidad,
  elementos: elementos,
);

/// Una ruta por cada tipo de grupo, con un elemento que abre su pantalla.
final _gruposDeTodos = <GrupoPendiente>[
  _grupo('LISTAS_SIN_PASAR', 'Listas sin pasar', 1, [
    _elemento('PASAR_LISTA:12', id: 12),
  ]),
  _grupo('CONVOCATORIAS_SIN_PUBLICAR', 'Partidos sin convocatoria', 1, [
    _elemento('CONVOCATORIA_NUEVA:30', id: 30),
  ]),
  _grupo('RESULTADOS_PENDIENTES', 'Resultados pendientes', 1, [
    _elemento('RESULTADO:34', id: 34),
  ]),
  _grupo('SOLICITUDES_FAMILIA', 'Solicitudes de familia', 1, [
    _elemento('SOLICITUDES_FAMILIA', id: 1),
  ]),
  _grupo('INVITACIONES_POR_APROBAR', 'Invitaciones por aprobar', 1, [
    _elemento('INVITACIONES', id: 2),
  ]),
  _grupo('MODERACION', 'Reportes de moderación', 1, [
    _elemento('MODERACION', id: 3),
  ]),
  _grupo('USUARIOS_CADUCADAS', 'Invitaciones de cuenta caducadas', 1, [
    _elemento('USUARIOS_CADUCADAS', id: 4),
  ]),
  _grupo('IMAGENES_PREVIA', 'Previa del fin de semana sin generar', 1, [
    _elemento('IMAGENES_PREVIA:2026-11-27'),
  ]),
];

const _delegados = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Rutas con nombre a las que se ha navegado.
final _rutas = <String>[];
final _aperturas = <String>[];

Future<void> _pintar(
  WidgetTester tester,
  List<String> roles,
  _PendientesFalso servicio, {
  Size tamano = const Size(800, 3000),
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await AuthManager.establecerUsuario(
    AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles, nombre: 'Ana Ruiz'),
  );

  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      locale: const Locale('es'),
      localizationsDelegates: _delegados,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ClubPage(pendientesService: servicio),
          );
        }
        _rutas.add(settings.name!);
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(),
            body: Text('DESTINO ${settings.name}'),
          ),
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

void _prepararDestinos() {
  Widget pantalla(String nombre) {
    _aperturas.add(nombre);

    return Scaffold(appBar: AppBar(), body: Text(nombre));
  }

  AppNavigator.constructorAsistencia = (e) => pantalla('ASISTENCIA ${e.id}');
  AppNavigator.fabricaEntrenamientoService = _EntrenamientosFalsos.new;
  AppNavigator.constructorFormularioConvocatoria = (id, e) =>
      pantalla('FORM_CONVOCATORIA $id ${e.id}');
  AppNavigator.constructorFormularioResultado = (p) =>
      pantalla('FORM_RESULTADO ${p.id}');
  AppNavigator.constructorSolicitudesFamilia = () => pantalla('SOLICITUDES');
  AppNavigator.constructorInvitaciones = () => pantalla('INVITACIONES');
  AppNavigator.constructorModeracion = () => pantalla('MODERACION');
  AppNavigator.constructorUsuariosCaducadas = () =>
      pantalla('USUARIOS_CADUCADAS');
  AppNavigator.constructorImagenesRedes = (desde, tipo) =>
      pantalla('IMAGENES $tipo ${desde?.toIso8601String().substring(0, 10)}');
}

/// Para que abrir la lista de un entrenamiento no pida nada a la red.
class _EntrenamientosFalsos extends EntrenamientoService {
  @override
  Future<EntrenamientoModel> obtenerPorId(int entrenamientoId) async =>
      EntrenamientoModel(
        id: entrenamientoId,
        equipoId: 10,
        equipo: 'Alevín B',
        fecha: '2026-11-23',
        usuarioEntrenadorId: 1,
        asistencias: const [],
        listaRevisada: false,
      );
}

void main() {
  setUp(() {
    _rutas.clear();
    _aperturas.clear();
    AuthManager.olvidarUsuario();
    _prepararDestinos();
  });

  tearDown(() {
    AppNavigator.constructorAsistencia = null;
    AppNavigator.fabricaEntrenamientoService = null;
    AppNavigator.constructorFormularioConvocatoria = null;
    AppNavigator.constructorFormularioResultado = null;
    AppNavigator.constructorSolicitudesFamilia = null;
    AppNavigator.constructorInvitaciones = null;
    AppNavigator.constructorModeracion = null;
    AppNavigator.constructorUsuariosCaducadas = null;
    AppNavigator.constructorImagenesRedes = null;
    AuthManager.olvidarUsuario();
  });

  group('la tarjeta', () {
    testWidgets('una fila por grupo con su contador', (tester) async {
      await _pintar(
        tester,
        const ['ENTRENADOR'],
        _PendientesFalso([
          _grupo('LISTAS_SIN_PASAR', 'Listas sin pasar', 7, [
            _elemento('PASAR_LISTA:12', id: 12),
          ]),
          _grupo('RESULTADOS_PENDIENTES', 'Resultados pendientes', 2, [
            _elemento('RESULTADO:34', id: 34),
          ]),
        ]),
      );

      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Listas sin pasar'), findsOneWidget);
      expect(find.text('Resultados pendientes'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('contador-LISTAS_SIN_PASAR')),
          matching: find.text('7'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('contador-RESULTADOS_PENDIENTES')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      // Cerrados: todavía no se ven los elementos.
      expect(find.text('Un pendiente'), findsNothing);
    });

    testWidgets('va arriba del todo, debajo de la cabecera y antes del menú', (
      tester,
    ) async {
      await _pintar(tester, const [
        'ENTRENADOR',
      ], _PendientesFalso([_gruposDeTodos.first]));

      final cabecera = tester.getTopLeft(find.text('Ana Ruiz')).dy;
      final tarjeta = tester
          .getTopLeft(find.byKey(const ValueKey('tarjeta-pendientes')))
          .dy;
      final menu = tester.getTopLeft(find.text('Comunicaciones')).dy;

      expect(tarjeta, greaterThan(cabecera));
      expect(tarjeta, lessThan(menu));
    });

    testWidgets('desplegar enseña como mucho 5 elementos y "Ver todos"', (
      tester,
    ) async {
      await _pintar(
        tester,
        const ['ENTRENADOR'],
        _PendientesFalso([
          _grupo('LISTAS_SIN_PASAR', 'Listas sin pasar', 9, [
            for (var i = 1; i <= 5; i++)
              _elemento('PASAR_LISTA:$i', id: i, texto: 'Lista $i'),
          ]),
        ]),
      );

      await tester.tap(
        find.byKey(const ValueKey('abrir-grupo-LISTAS_SIN_PASAR')),
      );
      await tester.pumpAndSettle();

      for (var i = 1; i <= 5; i++) {
        expect(find.text('Lista $i'), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('ver-todos-LISTAS_SIN_PASAR')),
        findsOneWidget,
      );
      expect(find.text('Ver todos'), findsOneWidget);

      // Y se pliega al volver a tocarla.
      await tester.tap(
        find.byKey(const ValueKey('abrir-grupo-LISTAS_SIN_PASAR')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lista 1'), findsNothing);
    });

    testWidgets('sin pendientes: "Todo al día ✓"', (tester) async {
      await _pintar(tester, const ['COORDINADOR'], _PendientesFalso([]));

      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Todo al día ✓'), findsOneWidget);
    });

    for (final roles in [
      ['FAMILIAR'],
      ['JUGADOR'],
      ['JUGADOR', 'FAMILIAR'],
    ]) {
      testWidgets('${roles.join(' + ')}: sin tarjeta y sin pedir nada', (
        tester,
      ) async {
        final servicio = _PendientesFalso(_gruposDeTodos);

        await _pintar(tester, roles, servicio);

        expect(find.text('Pendientes'), findsNothing);
        expect(find.byType(TarjetaPendientes), findsNothing);
        expect(servicio.llamadas, 0);
      });
    }

    for (final rol in ['ENTRENADOR', 'COORDINADOR', 'ADMIN_APP', 'RRSS']) {
      testWidgets('$rol ve la tarjeta', (tester) async {
        await _pintar(tester, [rol], _PendientesFalso([_gruposDeTodos.first]));

        expect(find.byType(TarjetaPendientes), findsOneWidget);
      });
    }

    testWidgets('si falla la petición, ni tarjeta ni error', (tester) async {
      final servicio = _PendientesFalso(_gruposDeTodos)..fallar = true;

      await _pintar(tester, const ['ENTRENADOR'], servicio);

      expect(servicio.llamadas, 1);
      expect(find.byType(TarjetaPendientes), findsNothing);
      expect(find.text('Pendientes'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('servidor caído'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('con letra grande, iPhone pequeño y modo oscuro no desborda', (
      tester,
    ) async {
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
          child: MaterialApp(
            theme: ThemeData.dark(),
            locale: const Locale('es'),
            localizationsDelegates: _delegados,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: TarjetaPendientes(
                  grupos: _gruposDeTodos,
                  onAbrirElemento: (_) {},
                  onVerTodos: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('abrir-grupo-MODERACION')),
      );
      await tester.tap(find.byKey(const ValueKey('abrir-grupo-MODERACION')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('cada elemento abre su pantalla', () {
    final casos = <String, (String, String)>{
      'LISTAS_SIN_PASAR': ('PASAR_LISTA:12', 'ASISTENCIA 12'),
      'CONVOCATORIAS_SIN_PUBLICAR': (
        'CONVOCATORIA_NUEVA:30',
        'FORM_CONVOCATORIA 30 10',
      ),
      'RESULTADOS_PENDIENTES': ('RESULTADO:34', 'FORM_RESULTADO 34'),
      'SOLICITUDES_FAMILIA': ('SOLICITUDES_FAMILIA', 'SOLICITUDES'),
      'INVITACIONES_POR_APROBAR': ('INVITACIONES', 'INVITACIONES'),
      'MODERACION': ('MODERACION', 'MODERACION'),
      'USUARIOS_CADUCADAS': ('USUARIOS_CADUCADAS', 'USUARIOS_CADUCADAS'),
    };

    for (final caso in casos.entries) {
      testWidgets(caso.value.$1, (tester) async {
        await _pintar(
          tester,
          const ['ADMIN_APP'],
          _PendientesFalso([
            _gruposDeTodos.firstWhere((g) => g.codigo == caso.key),
          ]),
        );

        await tester.tap(find.byKey(ValueKey('abrir-grupo-${caso.key}')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byWidgetPredicate((w) {
            final key = w.key;

            return w is InkWell &&
                key is ValueKey<String> &&
                key.value.startsWith('elemento-pendiente-${caso.key}');
          }),
        );
        await tester.pumpAndSettle();

        expect(_aperturas, [caso.value.$2]);
      });
    }

    testWidgets('IMAGENES_PREVIA en esa pestaña y ese fin de semana', (
      tester,
    ) async {
      await _pintar(tester, const [
        'RRSS',
      ], _PendientesFalso([_gruposDeTodos.last]));

      await tester.tap(
        find.byKey(const ValueKey('abrir-grupo-IMAGENES_PREVIA')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Un pendiente'));
      await tester.pumpAndSettle();

      expect(_aperturas, ['IMAGENES PREVIA 2026-11-27']);
    });
  });

  group('"Ver todos" y refrescar', () {
    testWidgets('"Ver todos" abre la pantalla completa de esa función', (
      tester,
    ) async {
      await _pintar(
        tester,
        const ['ADMIN_APP'],
        _PendientesFalso([
          _gruposDeTodos.firstWhere((g) => g.codigo == 'SOLICITUDES_FAMILIA'),
        ]),
      );

      await tester.tap(
        find.byKey(const ValueKey('abrir-grupo-SOLICITUDES_FAMILIA')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('ver-todos-SOLICITUDES_FAMILIA')),
      );
      await tester.pumpAndSettle();

      expect(_rutas, ['/coordination/family-requests']);
    });

    testWidgets(
      'se pide al entrar y se vuelve a pedir al volver de un elemento',
      (tester) async {
        final servicio = _PendientesFalso([_gruposDeTodos.first]);

        await _pintar(tester, const ['ENTRENADOR'], servicio);

        expect(servicio.llamadas, 1);

        await tester.tap(
          find.byKey(const ValueKey('abrir-grupo-LISTAS_SIN_PASAR')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Un pendiente'));
        await tester.pumpAndSettle();

        expect(find.text('ASISTENCIA 12'), findsOneWidget);
        expect(servicio.llamadas, 1);

        // Ya está hecho: al volver, la tarjeta se actualiza.
        servicio.grupos = [];
        AppNavigator.navigator!.pop();
        await tester.pumpAndSettle();

        expect(servicio.llamadas, 2);
        expect(find.text('Todo al día ✓'), findsOneWidget);
      },
    );

    testWidgets('también al volver de una opción del menú', (tester) async {
      final servicio = _PendientesFalso([_gruposDeTodos.first]);

      await _pintar(tester, const ['ENTRENADOR'], servicio);

      await tester.tap(find.text('Calendario'));
      await tester.pumpAndSettle();

      expect(_rutas, ['/calendar']);
      expect(servicio.llamadas, 1);

      AppNavigator.navigator!.pop();
      await tester.pumpAndSettle();

      expect(servicio.llamadas, 2);
    });

    testWidgets('si al refrescar falla, la tarjeta se oculta sin error', (
      tester,
    ) async {
      final servicio = _PendientesFalso([_gruposDeTodos.first]);

      await _pintar(tester, const ['ENTRENADOR'], servicio);

      expect(find.byType(TarjetaPendientes), findsOneWidget);

      servicio.fallar = true;
      await tester.tap(find.text('Calendario'));
      await tester.pumpAndSettle();
      AppNavigator.navigator!.pop();
      await tester.pumpAndSettle();

      expect(find.byType(TarjetaPendientes), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
