import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/club_menu.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/calendario/model/calendario_model.dart';
import 'package:app_mutxamel_cf/features/calendario/model/temporada_model.dart';
import 'package:app_mutxamel_cf/features/calendario/pages/calendario_page.dart';
import 'package:app_mutxamel_cf/features/calendario/services/calendario_service.dart';
import 'package:app_mutxamel_cf/features/teams/models/team_model.dart';
import 'package:app_mutxamel_cf/features/teams/services/team_services.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Un entrenador sin equipo (tras el cierre de temporada, de julio a septiembre,
/// se desasigna a todo el cuerpo técnico salvo el de Primer Equipo, Filial y
/// Veteranos): las pantallas no se rompen ni piden nada al servidor; solo
/// muestran un mensaje vacío claro.

class _CalendarioQueNoDebeLlamarse extends CalendarioService {
  int llamadas = 0;

  @override
  Future<TemporadaModel?> obtenerTemporadaActiva() async => null;

  @override
  Future<CalendarioModel> obtenerCalendario({
    required int equipoId,
    required DateTime desde,
    required DateTime hasta,
    int? jugadorId,
  }) async {
    llamadas++;

    return CalendarioModel(sesiones: const [], partidos: const []);
  }
}

class _FakeTeamService extends TeamService {
  @override
  Future<List<TeamModel>> obtenerEquipos() async => [];
}

PerfilApp _entrenadorSinEquipo() => PerfilApp(
  usuarioId: 1,
  email: 'e@b.c',
  roles: const ['ENTRENADOR'],
  jugadores: const [],
  equipos: const [],
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets('el calendario del entrenador sin equipos dice que no tiene equipos '
      'y no pide nada', (tester) async {
    final servicio = _CalendarioQueNoDebeLlamarse();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CalendarioPage(
          calendarioService: servicio,
          teamService: _FakeTeamService(),
          cargarPerfil: () async => _entrenadorSinEquipo(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tienes equipos asociados.'), findsOneWidget);
    expect(servicio.llamadas, 0);
    expect(tester.takeException(), isNull);
  });

  test('el menú del entrenador sin equipos sigue teniendo "Mis equipos" (con su '
      'mensaje vacío) y el resto del Club', () {
    final secciones = construirSeccionesClub(
      AuthUser(usuarioId: 1, email: 'e@b.c', roles: const ['ENTRENADOR']),
      cuotasDisponibles: false,
    );
    final opciones = secciones.expand((s) => s.opciones).toList();

    expect(opciones, contains(OpcionClub.misEquipos));
    expect(opciones, contains(OpcionClub.comunicaciones));
    expect(opciones, contains(OpcionClub.miPerfil));
  });
}
