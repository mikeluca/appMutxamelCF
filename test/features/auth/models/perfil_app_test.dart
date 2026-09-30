import 'package:flutter_test/flutter_test.dart';

import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';

void main() {
  group('PerfilApp.fromJson', () {
    test('parsea los campos basicos', () {
      final perfil = PerfilApp.fromJson({
        'usuarioId': 10,
        'email': 'ana@mutxamelcf.es',
        'roles': ['FAMILIAR'],
        'nombre': 'Ana',
        'apellidos': 'García',
        'telefono': '600111222',
        'jugadores': [],
        'equipos': [],
      });

      expect(perfil.usuarioId, 10);
      expect(perfil.email, 'ana@mutxamelcf.es');
      expect(perfil.roles, ['FAMILIAR']);
      expect(perfil.nombre, 'Ana');
      expect(perfil.apellidos, 'García');
      expect(perfil.telefono, '600111222');
    });

    test('roles/jugadores/equipos ausentes se convierten en listas vacias', () {
      final perfil = PerfilApp.fromJson({'usuarioId': 1, 'email': 'a@a.com'});

      expect(perfil.roles, isEmpty);
      expect(perfil.jugadores, isEmpty);
      expect(perfil.equipos, isEmpty);
    });

    test('mapea la lista de jugadores asociados', () {
      final perfil = PerfilApp.fromJson({
        'usuarioId': 1,
        'email': 'a@a.com',
        'jugadores': [
          {
            'id': 5,
            'nombre': 'Pablo',
            'apellidos': 'García',
            'equipo': 'Alevín A',
          },
        ],
      });

      expect(perfil.jugadores, hasLength(1));
      expect(perfil.jugadores.first.nombreCompleto, 'Pablo García');
      expect(perfil.jugadores.first.equipo, 'Alevín A');
    });

    group('fechas (fechaAlta/fechaActivacion/fechaUltimoAcceso)', () {
      test('texto ISO-8601 (formato habitual del backend)', () {
        final perfil = PerfilApp.fromJson({
          'usuarioId': 1,
          'email': 'a@a.com',
          'fechaAlta': '2026-01-15T10:30:00',
        });

        expect(perfil.fechaAlta, DateTime(2026, 1, 15, 10, 30, 0));
      });

      test('epoch en milisegundos', () {
        final fecha = DateTime(2026, 3, 1, 12);

        final perfil = PerfilApp.fromJson({
          'usuarioId': 1,
          'email': 'a@a.com',
          'fechaAlta': fecha.millisecondsSinceEpoch,
        });

        expect(perfil.fechaAlta, fecha);
      });

      test('array [year, month, day, hour, minute, second]', () {
        final perfil = PerfilApp.fromJson({
          'usuarioId': 1,
          'email': 'a@a.com',
          'fechaAlta': [2026, 9, 29, 18, 45, 0],
        });

        expect(perfil.fechaAlta, DateTime(2026, 9, 29, 18, 45, 0));
      });

      test('null se mantiene como null', () {
        final perfil = PerfilApp.fromJson({'usuarioId': 1, 'email': 'a@a.com'});

        expect(perfil.fechaAlta, isNull);
        expect(perfil.fechaActivacion, isNull);
        expect(perfil.fechaUltimoAcceso, isNull);
      });
    });
  });

  group('PerfilApp.nombreCompleto', () {
    test('concatena nombre y apellidos', () {
      final perfil = PerfilApp(
        usuarioId: 1,
        email: 'a@a.com',
        roles: const [],
        nombre: 'Ana',
        apellidos: 'García',
        jugadores: const [],
        equipos: const [],
      );

      expect(perfil.nombreCompleto, 'Ana García');
    });

    test('sin apellidos, no deja un espacio suelto', () {
      final perfil = PerfilApp(
        usuarioId: 1,
        email: 'a@a.com',
        roles: const [],
        nombre: 'Ana',
        jugadores: const [],
        equipos: const [],
      );

      expect(perfil.nombreCompleto, 'Ana');
    });

    test('sin nombre ni apellidos, es una cadena vacia', () {
      final perfil = PerfilApp(
        usuarioId: 1,
        email: 'a@a.com',
        roles: const [],
        jugadores: const [],
        equipos: const [],
      );

      expect(perfil.nombreCompleto, isEmpty);
    });
  });

  group('PerfilApp.tieneRol', () {
    test('devuelve true si el rol esta en la lista', () {
      final perfil = PerfilApp(
        usuarioId: 1,
        email: 'a@a.com',
        roles: const ['FAMILIAR', 'JUGADOR'],
        jugadores: const [],
        equipos: const [],
      );

      expect(perfil.tieneRol('FAMILIAR'), isTrue);
      expect(perfil.tieneRol('ENTRENADOR'), isFalse);
    });
  });
}
