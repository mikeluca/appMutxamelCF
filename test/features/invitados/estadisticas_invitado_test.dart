import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
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

  @override
  Future<List<TarjetasJugadorModel>> obtenerTarjetas(int equipoId) async =>
      tarjetas;

  @override
  Future<EstadisticasEquipoModel> obtenerEstadisticas(int equipoId) async =>
      estadisticas!;
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

void main() {
  testWidgets(
    'en las tarjetas del equipo el invitado sale marcado "Invitado"',
    (tester) async {
      final servicio = _FakeServicio()
        ..tarjetas = const [
          TarjetasJugadorModel(
            jugadorId: 1,
            nombre: 'Pablo Garcia',
            dorsal: 9,
            amarillas: 1,
            rojas: 0,
            estado: 'OK',
          ),
          TarjetasJugadorModel(
            jugadorId: 2,
            nombre: 'Ana Pérez',
            dorsal: 7,
            amarillas: 2,
            rojas: 0,
            estado: 'OK',
            invitado: true,
          ),
        ];

      await tester.pumpWidget(
        _app(TarjetasEquipoPage(equipo: _equipo, servicio: servicio)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.byKey(const ValueKey('invitado-tarjetas-2')), findsOneWidget);
      expect(find.text('Invitado'), findsOneWidget);
      // El jugador del equipo no lleva etiqueta.
      expect(find.byKey(const ValueKey('invitado-tarjetas-1')), findsNothing);
    },
  );

  testWidgets(
    'en goleadores y asistentes el invitado sale marcado "Invitado"',
    (tester) async {
      final servicio = _FakeServicio()
        ..estadisticas = const EstadisticasEquipoModel(
          goleadores: [
            JugadorDestacadoModel(
              jugadorId: 1,
              nombre: 'Pablo Garcia',
              dorsal: 9,
              goles: 7,
              asistencias: 2,
              partidos: 8,
            ),
            JugadorDestacadoModel(
              jugadorId: 2,
              nombre: 'Ana Pérez',
              dorsal: 7,
              goles: 3,
              asistencias: 0,
              partidos: 1,
              invitado: true,
            ),
          ],
          asistentes: [],
          entrenamientos: EntrenamientosEquipoModel(
            sesiones: 0,
            asistenciaMedia: null,
            porJugador: [],
          ),
          partidos: PartidosEquipoModel(
            jugados: 1,
            ganados: 1,
            empatados: 0,
            perdidos: 0,
            golesFavor: 3,
            golesContra: 0,
          ),
        );

      await tester.pumpWidget(
        _app(EstadisticasEquipoPage(equipo: _equipo, servicio: servicio)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('destacado-2')),
          matching: find.text('Invitado'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('destacado-1')),
          matching: find.text('Invitado'),
        ),
        findsNothing,
      );
    },
  );
}
