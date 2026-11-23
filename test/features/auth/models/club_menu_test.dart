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
  const cuenta = [
    OpcionClub.pedirAccesoJugador,
    OpcionClub.miPerfil,
    OpcionClub.cerrarSesion,
  ];

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
      expect(_opciones(s, SeccionClubId.entrenador), [
        OpcionClub.misEquipos,
        OpcionClub.solicitudesFamilia,
      ]);
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
        OpcionClub.solicitudesFamilia,
      ]);
    });

    test('ADMIN_APP: Coordinación + Administración (Moderación, Cuentas '
        'pendientes)', () {
      final s = de(['ADMIN_APP']);

      expect(_ids(s), [
        SeccionClubId.club,
        SeccionClubId.coordinacion,
        SeccionClubId.administracion,
        SeccionClubId.retransmision,
        SeccionClubId.cuenta,
      ]);
      expect(_opciones(s, SeccionClubId.administracion), [
        OpcionClub.moderacion,
        OpcionClub.usuarios,
        OpcionClub.subirDatosFfcv,
        OpcionClub.estadoApp,
      ]);
      // Directo y RRSS: el administrador ve las dos opciones.
      expect(_opciones(s, SeccionClubId.retransmision), [
        OpcionClub.partidoEnDirecto,
        OpcionClub.imagenesRedes,
      ]);
    });

    test('RETRANSMISION sola: Partido en directo + Mi cuenta, sin Club ni '
        'pedir acceso a otro jugador ni Imágenes para redes', () {
      final s = de(['RETRANSMISION']);

      expect(_ids(s), [SeccionClubId.retransmision, SeccionClubId.cuenta]);
      expect(_opciones(s, SeccionClubId.retransmision), [
        OpcionClub.partidoEnDirecto,
      ]);
      expect(_opciones(s, SeccionClubId.cuenta), [
        OpcionClub.miPerfil,
        OpcionClub.cerrarSesion,
      ]);
      expect(_todas(s), isNot(contains(OpcionClub.imagenesRedes)));
      expect(_todas(s), isNot(contains(OpcionClub.comunicaciones)));
      expect(_todas(s), isNot(contains(OpcionClub.calendario)));
      expect(_todas(s), isNot(contains(OpcionClub.partidos)));
      expect(_todas(s), isNot(contains(OpcionClub.clasificaciones)));
      expect(_todas(s), isNot(contains(OpcionClub.pedirAccesoJugador)));
    });

    test('RRSS sola: Imágenes para redes + Mi cuenta, sin Club ni pedir '
        'acceso a otro jugador ni Partido en directo', () {
      final s = de(['RRSS']);

      expect(_ids(s), [SeccionClubId.retransmision, SeccionClubId.cuenta]);
      expect(_opciones(s, SeccionClubId.retransmision), [
        OpcionClub.imagenesRedes,
      ]);
      expect(_opciones(s, SeccionClubId.cuenta), [
        OpcionClub.miPerfil,
        OpcionClub.cerrarSesion,
      ]);
      expect(_todas(s), isNot(contains(OpcionClub.partidoEnDirecto)));
      expect(_todas(s), isNot(contains(OpcionClub.comunicaciones)));
      expect(_todas(s), isNot(contains(OpcionClub.pedirAccesoJugador)));
    });

    test('RRSS + RETRANSMISION: las dos opciones + Mi cuenta, sin Club', () {
      final s = de(['RRSS', 'RETRANSMISION']);

      expect(_ids(s), [SeccionClubId.retransmision, SeccionClubId.cuenta]);
      expect(_opciones(s, SeccionClubId.retransmision), [
        OpcionClub.partidoEnDirecto,
        OpcionClub.imagenesRedes,
      ]);
      expect(_opciones(s, SeccionClubId.cuenta), [
        OpcionClub.miPerfil,
        OpcionClub.cerrarSesion,
      ]);
      expect(_todas(s), isNot(contains(OpcionClub.pedirAccesoJugador)));
    });

    test('RETRANSMISION + FAMILIAR: el menú de siempre, con Club, pedir '
        'acceso y solo Partido en directo', () {
      final s = de(['RETRANSMISION', 'FAMILIAR']);

      expect(_opciones(s, SeccionClubId.club), containsAll(club));
      expect(_opciones(s, SeccionClubId.cuenta), cuenta);
      expect(_opciones(s, SeccionClubId.retransmision), [
        OpcionClub.partidoEnDirecto,
      ]);
    });

    test('RRSS + ENTRENADOR: Mis equipos y solo Imágenes para redes', () {
      final s = de(['RRSS', 'ENTRENADOR']);

      expect(_opciones(s, SeccionClubId.club), containsAll(club));
      expect(_opciones(s, SeccionClubId.cuenta), cuenta);
      expect(
        _opciones(s, SeccionClubId.entrenador),
        contains(OpcionClub.misEquipos),
      );
      expect(_opciones(s, SeccionClubId.retransmision), [
        OpcionClub.imagenesRedes,
      ]);
    });

    test(
      'RETRANSMISION + ENTRENADOR: Mis equipos y solo Partido en directo',
      () {
        final s = de(['RETRANSMISION', 'ENTRENADOR']);

        expect(
          _opciones(s, SeccionClubId.entrenador),
          contains(OpcionClub.misEquipos),
        );
        expect(_opciones(s, SeccionClubId.retransmision), [
          OpcionClub.partidoEnDirecto,
        ]);
      },
    );

    test('ADMIN_APP ve Partido en directo, Imágenes para redes, Coordinación '
        'y Administración', () {
      final s = de(['ADMIN_APP']);

      expect(
        _ids(s),
        containsAll([
          SeccionClubId.coordinacion,
          SeccionClubId.administracion,
          SeccionClubId.retransmision,
        ]),
      );
      expect(_opciones(s, SeccionClubId.retransmision), [
        OpcionClub.partidoEnDirecto,
        OpcionClub.imagenesRedes,
      ]);
      expect(
        _todas(s),
        containsAll([
          OpcionClub.todosLosEquipos,
          OpcionClub.solicitudesFamilia,
          OpcionClub.invitaciones,
          OpcionClub.moderacion,
          OpcionClub.usuarios,
          OpcionClub.subirDatosFfcv,
          OpcionClub.estadoApp,
        ]),
      );
    });

    test(
      'RETRANSMISION y ADMIN_APP a la vez: las dos opciones, una sola vez',
      () {
        final s = de(['RETRANSMISION', 'ADMIN_APP']);

        expect(_opciones(s, SeccionClubId.retransmision), [
          OpcionClub.partidoEnDirecto,
          OpcionClub.imagenesRedes,
        ]);
      },
    );

    test('puedeVerImagenesRedes y Partido en directo según el rol', () {
      const casos = {
        'RRSS': [true, false],
        'ADMIN_APP': [true, true],
        'RETRANSMISION': [false, true],
        'COORDINADOR': [false, false],
        'ENTRENADOR': [false, false],
        'FAMILIAR': [false, false],
        'JUGADOR': [false, false],
      };

      casos.forEach((rol, esperado) {
        expect(
          puedeVerImagenesRedesUsuario(_usuario([rol])),
          esperado[0],
          reason: 'imágenes $rol',
        );
        expect(
          puedeVerPartidoEnDirecto(_usuario([rol])),
          esperado[1],
          reason: 'directo $rol',
        );
      });
      expect(puedeVerImagenesRedesUsuario(null), isFalse);
      expect(puedeVerPartidoEnDirecto(null), isFalse);
    });

    test('esSoloDirectoYRrss: solo RETRANSMISION y/o RRSS', () {
      expect(esSoloDirectoYRrss(_usuario(['RRSS'])), isTrue);
      expect(esSoloDirectoYRrss(_usuario(['RETRANSMISION'])), isTrue);
      expect(esSoloDirectoYRrss(_usuario(['RRSS', 'RETRANSMISION'])), isTrue);
      expect(esSoloDirectoYRrss(_usuario(['RRSS', 'FAMILIAR'])), isFalse);
      expect(esSoloDirectoYRrss(_usuario(['ADMIN_APP'])), isFalse);
      expect(esSoloDirectoYRrss(_usuario([])), isFalse);
      expect(esSoloDirectoYRrss(null), isFalse);
    });

    test(
      'COORDINADOR sin Retransmisión ni administrador: sin Directo y RRSS',
      () {
        final s = de(['COORDINADOR']);

        expect(_ids(s), isNot(contains(SeccionClubId.retransmision)));
        expect(_todas(s), isNot(contains(OpcionClub.imagenesRedes)));
        expect(_todas(s), isNot(contains(OpcionClub.partidoEnDirecto)));
      },
    );

    test('la ruta de Imágenes para redes es la nueva pantalla', () {
      expect(rutaDeOpcionClub(OpcionClub.imagenesRedes), '/social-images');
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
    expect(rutaDeOpcionClub(OpcionClub.repartoEquipos), '/coordination/roster');
    expect(
      rutaDeOpcionClub(OpcionClub.altaPrueba),
      '/coordination/trial-player',
    );
    expect(
      rutaDeOpcionClub(OpcionClub.invitaciones),
      '/coordination/invitations',
    );
    expect(rutaDeOpcionClub(OpcionClub.moderacion), '/admin/moderation');
    expect(rutaDeOpcionClub(OpcionClub.usuarios), '/admin/users');
    expect(rutaDeOpcionClub(OpcionClub.subirDatosFfcv), '/admin/ffcv-upload');
    expect(rutaDeOpcionClub(OpcionClub.estadoApp), '/admin/app-status');
    expect(rutaDeOpcionClub(OpcionClub.partidoEnDirecto), '/live-match');
    expect(rutaDeOpcionClub(OpcionClub.miPerfil), '/profile');
    expect(rutaDeOpcionClub(OpcionClub.cuotas), isNull);
    expect(rutaDeOpcionClub(OpcionClub.cerrarSesion), isNull);
  });

  group('solicitudes de familia', () {
    test(
      'una cuenta sin roles solo ve cerrar sesión (la tarjeta de su solicitud va aparte)',
      () {
        final s = construirSeccionesClub(
          _usuario([]),
          cuotasDisponibles: false,
        );

        expect(_ids(s), [SeccionClubId.cuenta]);
        expect(_todas(s), [OpcionClub.cerrarSesion]);

        // Ni comunicaciones, ni calendario, ni partidos, ni perfil: nada privado.
        expect(_todas(s), isNot(contains(OpcionClub.comunicaciones)));
        expect(_todas(s), isNot(contains(OpcionClub.calendario)));
        expect(_todas(s), isNot(contains(OpcionClub.pedirAccesoJugador)));
      },
    );

    test(
      'coordinación y administradores ven "Solicitudes de familia" en Coordinación',
      () {
        for (final rol in ['COORDINADOR', 'ADMIN_APP']) {
          final s = de([rol]);

          expect(
            _opciones(s, SeccionClubId.coordinacion),
            contains(OpcionClub.solicitudesFamilia),
          );
        }
      },
    );

    test('un entrenador la ve en su sección y no en Coordinación', () {
      final s = de(['ENTRENADOR']);

      expect(
        _opciones(s, SeccionClubId.entrenador),
        contains(OpcionClub.solicitudesFamilia),
      );
      expect(_ids(s), isNot(contains(SeccionClubId.coordinacion)));
    });

    test(
      'un entrenador que además es coordinador la ve una sola vez, en Coordinación',
      () {
        final s = de(['ENTRENADOR', 'COORDINADOR']);

        expect(
          _todas(s).where((o) => o == OpcionClub.solicitudesFamilia),
          hasLength(1),
        );
        expect(
          _opciones(s, SeccionClubId.coordinacion),
          contains(OpcionClub.solicitudesFamilia),
        );
      },
    );

    test('jugadores y familiares no revisan nada', () {
      for (final rol in ['JUGADOR', 'FAMILIAR', 'RETRANSMISION']) {
        expect(
          _todas(de([rol])),
          isNot(contains(OpcionClub.solicitudesFamilia)),
        );
      }
    });

    test('cualquier cuenta con roles puede pedir acceso a otro jugador', () {
      for (final rol in ['JUGADOR', 'FAMILIAR', 'ENTRENADOR', 'COORDINADOR']) {
        expect(
          _opciones(de([rol]), SeccionClubId.cuenta),
          contains(OpcionClub.pedirAccesoJugador),
        );
      }
    });

    test('las rutas de las dos opciones nuevas', () {
      expect(
        rutaDeOpcionClub(OpcionClub.solicitudesFamilia),
        '/coordination/family-requests',
      );
      expect(
        rutaDeOpcionClub(OpcionClub.pedirAccesoJugador),
        '/ask-another-player',
      );
    });
  });
}
