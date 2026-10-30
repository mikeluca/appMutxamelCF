import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/models/club_menu.dart';
import 'package:flutter_test/flutter_test.dart';

AuthUser _usuario(List<String> roles) =>
    AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles);

List<SeccionClubId> _ids(List<SeccionClub> s) => s.map((e) => e.id).toList();

List<OpcionClub> _opciones(List<SeccionClub> s, SeccionClubId id) =>
    s.firstWhere((e) => e.id == id).opciones;

List<OpcionClub> _todas(List<SeccionClub> s) =>
    s.expand((e) => e.opciones).toList();

void main() {
  List<SeccionClub> de(List<String> roles, {bool cuotas = false}) {
    final secciones = construirSeccionesClub(
      _usuario(roles),
      cuotasDisponibles: cuotas,
    );

    // Ninguna opción repetida.
    final todas = _todas(secciones);
    expect(todas.toSet().length, todas.length, reason: 'repetida: $todas');

    // Ninguna sección vacía y siempre en el orden fijado.
    expect(secciones.every((s) => s.opciones.isNotEmpty), isTrue);
    final indices = secciones
        .map((s) => SeccionClubId.values.indexOf(s.id))
        .toList();
    expect([...indices]..sort(), indices);

    return secciones;
  }

  // Orden de Club: Comunicaciones, Calendario, Partidos, Clasificaciones.
  const club = [
    OpcionClub.comunicaciones,
    OpcionClub.calendario,
    OpcionClub.partidos,
  ];
  const cuenta = [OpcionClub.miPerfil, OpcionClub.cerrarSesion];

  test('el orden de las secciones es el acordado', () {
    expect(SeccionClubId.values, [
      SeccionClubId.club,
      SeccionClubId.jugador,
      SeccionClubId.familia,
      SeccionClubId.entrenador,
      SeccionClubId.coordinacion,
      SeccionClubId.administracion,
      SeccionClubId.retransmision,
      SeccionClubId.cuenta,
    ]);
  });

  group('un solo rol', () {
    test('JUGADOR: Club con clasificaciones, Jugador (Mi ficha) y cuenta', () {
      final s = de(['JUGADOR']);

      expect(_ids(s), [
        SeccionClubId.club,
        SeccionClubId.jugador,
        SeccionClubId.cuenta,
      ]);
      expect(_opciones(s, SeccionClubId.club), [
        ...club,
        OpcionClub.clasificaciones,
      ]);
      expect(_opciones(s, SeccionClubId.jugador), [OpcionClub.miFicha]);
      expect(_opciones(s, SeccionClubId.cuenta), cuenta);
    });

    test('FAMILIAR: Familia con Mis jugadores; Cuotas solo si el flag lo '
        'permite', () {
      final s = de(['FAMILIAR']);

      expect(_ids(s), [
        SeccionClubId.club,
        SeccionClubId.familia,
        SeccionClubId.cuenta,
      ]);
      expect(_opciones(s, SeccionClubId.familia), [OpcionClub.misJugadores]);

      final conCuotas = de(['FAMILIAR'], cuotas: true);
      expect(_opciones(conCuotas, SeccionClubId.familia), [
        OpcionClub.misJugadores,
        OpcionClub.cuotas,
      ]);
    });

    test('ENTRENADOR: sección Entrenador con Mis equipos', () {
      final s = de(['ENTRENADOR']);

      expect(_ids(s), [
        SeccionClubId.club,
        SeccionClubId.entrenador,
        SeccionClubId.cuenta,
      ]);
      expect(_opciones(s, SeccionClubId.entrenador), [OpcionClub.misEquipos]);
      expect(
        _opciones(s, SeccionClubId.club),
        contains(OpcionClub.clasificaciones),
      );
    });

    test('COORDINADOR: Coordinación en su orden, sin Entrenador ni '
        'Administración', () {
      final s = de(['COORDINADOR']);

      expect(_ids(s), [
        SeccionClubId.club,
        SeccionClubId.coordinacion,
        SeccionClubId.cuenta,
      ]);
      expect(_opciones(s, SeccionClubId.coordinacion), [
        OpcionClub.todosLosEquipos,
        OpcionClub.finDeSemana,
        OpcionClub.seguimientoJugadores,
        OpcionClub.repartoEquipos,
        OpcionClub.altaPrueba,
        OpcionClub.invitaciones,
      ]);
    });

    test('ADMIN_APP: Coordinación + Administración (Moderación, Cuentas '
        'pendientes)', () {
      final s = de(['ADMIN_APP']);

      expect(_ids(s), [
        SeccionClubId.club,
        SeccionClubId.coordinacion,
        SeccionClubId.administracion,
        SeccionClubId.cuenta,
      ]);
      expect(_opciones(s, SeccionClubId.administracion), [
        OpcionClub.moderacion,
        OpcionClub.cuentasPendientes,
        OpcionClub.estadoApp,
      ]);
    });

    test('RETRANSMISION sola: Club (sin clasificaciones) + Retransmisión + '
        'cuenta', () {
      final s = de(['RETRANSMISION']);

      expect(_ids(s), [
        SeccionClubId.club,
        SeccionClubId.retransmision,
        SeccionClubId.cuenta,
      ]);
      expect(_opciones(s, SeccionClubId.club), club);
      expect(_opciones(s, SeccionClubId.retransmision), [
        OpcionClub.partidoEnDirecto,
      ]);
    });

    test('SOCIO solo: Club (sin clasificaciones) + cuenta', () {
      final s = de(['SOCIO']);

      expect(_ids(s), [SeccionClubId.club, SeccionClubId.cuenta]);
      expect(_opciones(s, SeccionClubId.club), club);
    });
  });

  group('combinaciones', () {
    test('JUGADOR+FAMILIAR: solo Familia, sin Jugador', () {
      final s = de(['JUGADOR', 'FAMILIAR']);

      expect(_ids(s), [
        SeccionClubId.club,
        SeccionClubId.familia,
        SeccionClubId.cuenta,
      ]);
      expect(_opciones(s, SeccionClubId.familia), [OpcionClub.misJugadores]);
      expect(_todas(s), isNot(contains(OpcionClub.miFicha)));
    });

    test('ENTRENADOR+FAMILIAR: Familia y Entrenador', () {
      final s = de(['ENTRENADOR', 'FAMILIAR']);

      expect(_ids(s), [
        SeccionClubId.club,
        SeccionClubId.familia,
        SeccionClubId.entrenador,
        SeccionClubId.cuenta,
      ]);
    });

    test('ENTRENADOR+COORDINADOR: Coordinación sin Entrenador, un solo '
        'listado de equipos', () {
      final s = de(['ENTRENADOR', 'COORDINADOR']);

      expect(_ids(s), isNot(contains(SeccionClubId.entrenador)));
      expect(_todas(s), contains(OpcionClub.todosLosEquipos));
      expect(_todas(s), isNot(contains(OpcionClub.misEquipos)));
    });

    test('todos los roles juntos: sin duplicados y en orden', () {
      final s = de([
        'JUGADOR',
        'FAMILIAR',
        'ENTRENADOR',
        'COORDINADOR',
        'ADMIN_APP',
        'RETRANSMISION',
        'SOCIO',
      ], cuotas: true);

      expect(_ids(s), [
        SeccionClubId.club,
        SeccionClubId.familia,
        SeccionClubId.coordinacion,
        SeccionClubId.administracion,
        SeccionClubId.retransmision,
        SeccionClubId.cuenta,
      ]);
    });
  });

  test('sin usuario solo hay Club y cuenta', () {
    final s = construirSeccionesClub(null);

    expect(_ids(s), [SeccionClubId.club, SeccionClubId.cuenta]);
  });

  test('Cuotas no sale con el flag actual de AppConfig', () {
    final s = construirSeccionesClub(_usuario(['FAMILIAR']));

    expect(_todas(s), isNot(contains(OpcionClub.cuotas)));
  });

  test('cada opción con ruta navega a la de siempre', () {
    expect(rutaDeOpcionClub(OpcionClub.comunicaciones), '/communication');
    expect(rutaDeOpcionClub(OpcionClub.calendario), '/calendar');
    expect(rutaDeOpcionClub(OpcionClub.partidos), '/my-matches');
    expect(rutaDeOpcionClub(OpcionClub.clasificaciones), '/my-standings');
    expect(rutaDeOpcionClub(OpcionClub.miFicha), '/my-card');
    expect(rutaDeOpcionClub(OpcionClub.misJugadores), '/players');
    expect(rutaDeOpcionClub(OpcionClub.misEquipos), '/my-teams');
    expect(rutaDeOpcionClub(OpcionClub.todosLosEquipos), '/my-teams');
    expect(rutaDeOpcionClub(OpcionClub.finDeSemana), '/coordination/weekend');
    expect(
      rutaDeOpcionClub(OpcionClub.seguimientoJugadores),
      '/coordination/player-tracking',
    );
    expect(
      rutaDeOpcionClub(OpcionClub.repartoEquipos),
      '/coordination/roster',
    );
    expect(
      rutaDeOpcionClub(OpcionClub.altaPrueba),
      '/coordination/trial-player',
    );
    expect(
      rutaDeOpcionClub(OpcionClub.invitaciones),
      '/coordination/invitations',
    );
    expect(rutaDeOpcionClub(OpcionClub.moderacion), '/admin/moderation');
    expect(
      rutaDeOpcionClub(OpcionClub.cuentasPendientes),
      '/admin/pending-accounts',
    );
    expect(rutaDeOpcionClub(OpcionClub.estadoApp), '/admin/app-status');
    expect(rutaDeOpcionClub(OpcionClub.partidoEnDirecto), '/live-match');
    expect(rutaDeOpcionClub(OpcionClub.miPerfil), '/profile');
    expect(rutaDeOpcionClub(OpcionClub.cuotas), isNull);
    expect(rutaDeOpcionClub(OpcionClub.cerrarSesion), isNull);
  });
}
