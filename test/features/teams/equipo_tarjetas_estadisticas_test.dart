import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/entrenamientos/model/entrenamiento_model.dart';
import 'package:app_mutxamel_cf/features/entrenamientos/widgets/entrenamiento_card.dart';
import 'package:app_mutxamel_cf/features/teams/models/estadisticas_equipo_model.dart';
import 'package:app_mutxamel_cf/features/teams/pages/estadisticas_equipo_page.dart';
import 'package:app_mutxamel_cf/features/teams/pages/tarjetas_equipo_page.dart';
import 'package:app_mutxamel_cf/features/teams/services/estadisticas_equipo_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeServicio extends EstadisticasEquipoService {
  List<TarjetasJugadorModel> tarjetas = [];
  EstadisticasEquipoModel? estadisticas;
  Object? fallo;

  @override
  Future<List<TarjetasJugadorModel>> obtenerTarjetas(int equipoId) async {
    if (fallo != null) throw fallo!;
    return tarjetas;
  }

  @override
  Future<EstadisticasEquipoModel> obtenerEstadisticas(int equipoId) async {
    if (fallo != null) throw fallo!;
    return estadisticas!;
  }
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('es'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

final _equipo = PerfilEquipo(id: 5, nombre: 'Cadete A');

TarjetasJugadorModel _tarjeta(
  int id,
  String nombre,
  int dorsal,
  int amarillas,
  int rojas,
  String estado,
) => TarjetasJugadorModel(
  jugadorId: id,
  nombre: nombre,
  dorsal: dorsal,
  amarillas: amarillas,
  rojas: rojas,
  estado: estado,
);

void main() {
  group('Tarjetas', () {
    testWidgets('lista dorsal, nombre, amarillas y rojas, con los chips de '
        'estado y la nota orientativa', (tester) async {
      final servicio = _FakeServicio()
        ..tarjetas = [
          _tarjeta(1, 'Pablo Garcia', 9, 5, 1, 'SANCION_POSIBLE'),
          _tarjeta(2, 'Luis Lopez', 4, 4, 0, 'A_UNA'),
          _tarjeta(3, 'Ana Ruiz', 7, 1, 0, 'OK'),
        ];

      await tester.pumpWidget(
        _app(TarjetasEquipoPage(equipo: _equipo, servicio: servicio)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pablo Garcia'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('Posible sanción'), findsOneWidget);
      expect(find.text('A una de sanción'), findsOneWidget);
      // Solo los jugadores con aviso llevan chip.
      expect(find.text('Ana Ruiz'), findsOneWidget);
      expect(
        find.text('Orientativo: la sanción la determina la FFCV.'),
        findsOneWidget,
      );

      // El chip de "a una" es ámbar y el de posible sanción, rojo.
      Color colorDe(String texto) =>
          (tester.widget<Text>(find.text(texto)).style!.color)!;

      expect(colorDe('A una de sanción'), const Color(0xFFF59E0B));
      expect(colorDe('Posible sanción'), const Color(0xFFDC2626));
    });

    testWidgets('con un error de red muestra el aviso y reintenta', (
      tester,
    ) async {
      final servicio = _FakeServicio()..fallo = Exception('sin red');

      await tester.pumpWidget(
        _app(TarjetasEquipoPage(equipo: _equipo, servicio: servicio)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No se ha podido conectar'), findsOneWidget);

      servicio
        ..fallo = null
        ..tarjetas = [_tarjeta(1, 'Pablo Garcia', 9, 0, 0, 'OK')];

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Pablo Garcia'), findsOneWidget);
    });
  });

  group('Estadísticas', () {
    EstadisticasEquipoModel datos() => const EstadisticasEquipoModel(
      goleadores: [
        JugadorDestacadoModel(
          jugadorId: 1,
          nombre: 'Pablo Garcia',
          dorsal: 9,
          goles: 7,
          asistencias: 2,
          partidos: 8,
        ),
      ],
      asistentes: [
        JugadorDestacadoModel(
          jugadorId: 2,
          nombre: 'Luis Lopez',
          dorsal: 4,
          goles: 1,
          asistencias: 5,
          partidos: 8,
        ),
      ],
      entrenamientos: EntrenamientosEquipoModel(
        sesiones: 10,
        asistenciaMedia: 82,
        porJugador: [
          AsistenciaJugadorModel(
            jugadorId: 3,
            nombre: 'Ana Ruiz',
            asistidos: 6,
            total: 10,
            porcentaje: 60,
          ),
          AsistenciaJugadorModel(
            jugadorId: 1,
            nombre: 'Pablo Garcia',
            asistidos: 10,
            total: 10,
            porcentaje: 100,
          ),
        ],
      ),
      partidos: PartidosEquipoModel(
        jugados: 8,
        ganados: 5,
        empatados: 1,
        perdidos: 2,
        golesFavor: 21,
        golesContra: 11,
      ),
    );

    testWidgets('muestra el resumen, los goleadores, los asistentes y la '
        'asistencia de menor a mayor, con ámbar por debajo del 75 %', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final servicio = _FakeServicio()..estadisticas = datos();

      await tester.pumpWidget(
        _app(EstadisticasEquipoPage(equipo: _equipo, servicio: servicio)),
      );
      await tester.pumpAndSettle();

      expect(find.text('PJ'), findsOneWidget);
      expect(find.text('21'), findsOneWidget); // GF
      expect(find.text('11'), findsOneWidget); // GC
      expect(find.text('82 %'), findsOneWidget); // asistencia media

      expect(find.text('7 goles'), findsOneWidget);
      expect(find.text('5 asistencias'), findsOneWidget);

      // Ana (60 %) va antes que Pablo (100 %).
      final ana = tester.getTopLeft(find.text('Ana Ruiz')).dy;
      final pabloAsistencia = tester.getTopLeft(find.text('10 de 10')).dy;

      expect(ana, lessThan(pabloAsistencia));

      Color colorDe(String texto) =>
          (tester.widget<Text>(find.text(texto)).style!.color)!;

      expect(colorDe('60 %'), const Color(0xFFF59E0B));
      expect(colorDe('100 %'), isNot(const Color(0xFFF59E0B)));
    });

    testWidgets('sin datos muestra los textos de vacío y los guiones', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final servicio = _FakeServicio()
        ..estadisticas = const EstadisticasEquipoModel(
          goleadores: [],
          asistentes: [],
          entrenamientos: EntrenamientosEquipoModel(
            sesiones: 0,
            asistenciaMedia: null,
            porJugador: [],
          ),
          partidos: PartidosEquipoModel(
            jugados: 0,
            ganados: 0,
            empatados: 0,
            perdidos: 0,
            golesFavor: 0,
            golesContra: 0,
          ),
        );

      await tester.pumpWidget(
        _app(EstadisticasEquipoPage(equipo: _equipo, servicio: servicio)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Todavía no hay datos'), findsNWidgets(3));
      expect(find.text('-'), findsOneWidget);
    });
  });

  group('Lista sin revisar', () {
    EntrenamientoModel entrenamiento(String fecha, bool revisada) =>
        EntrenamientoModel(
          id: 1,
          equipoId: 5,
          equipo: 'Cadete A',
          fecha: fecha,
          usuarioEntrenadorId: 1,
          asistencias: const [],
          listaRevisada: revisada,
        );

    testWidgets('aparece en un entrenamiento pasado sin revisar', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: EntrenamientoCard(
              entrenamiento: entrenamiento('2020-01-15', false),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Lista sin revisar'), findsOneWidget);
    });

    testWidgets('no aparece si está revisado ni si es futuro', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Column(
              children: [
                EntrenamientoCard(
                  entrenamiento: entrenamiento('2020-01-15', true),
                  onTap: () {},
                ),
                EntrenamientoCard(
                  entrenamiento: entrenamiento('2099-01-15', false),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Lista sin revisar'), findsNothing);
    });

    test('el modelo lee listaRevisada y la da por revisada si falta', () {
      final base = {
        'id': 1,
        'equipoId': 5,
        'equipo': 'Cadete A',
        'fecha': '2026-10-21',
        'asistencias': <dynamic>[],
      };

      expect(
        EntrenamientoModel.fromJson({
          ...base,
          'listaRevisada': false,
        }).listaRevisada,
        isFalse,
      );
      expect(EntrenamientoModel.fromJson(base).listaRevisada, isTrue);
    });
  });
}
