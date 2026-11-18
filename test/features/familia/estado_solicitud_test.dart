import 'dart:convert';

import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/pages/club_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/familia/pages/mi_solicitud_familia_page.dart';
import 'package:app_mutxamel_cf/features/familia/pages/pedir_acceso_jugador_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../../support/http_test_helpers.dart';
import 'soporte_familia.dart';

Map<String, dynamic> _hijo(
  int id,
  String nombre,
  String estado, {
  String equipo = 'Alevín B',
}) => {
  'id': id,
  'nombre': nombre,
  'apellidos': 'Pérez',
  'equipo': equipo,
  'estado': estado,
};

Map<String, dynamic> _solicitud(
  int id,
  String estado,
  List<Map<String, dynamic>> hijos, {
  String? motivo,
}) => {
  'id': id,
  'estado': estado,
  'parentesco': 'MADRE',
  'fechaSolicitud': '2026-11-18T10:15:00',
  'fechaRevision': null,
  'motivoRechazo': motivo,
  'hijos': hijos,
};

/// Backend simulado de la cuenta con sesión: apunta todo lo que se le pide.
class _Backend {
  final peticiones = <String>[];
  final cabeceras = <String, Map<String, String>>{};
  final cuerpos = <String, Map<String, dynamic>>{};

  List<Map<String, dynamic>> mias = [];
  List<String> roles = [];
  http.Response Function()? solicitar;

  Future<http.Response> responder(http.Request request) async {
    final ruta = request.url.path;

    peticiones.add('${request.method} $ruta');
    cabeceras[ruta] = request.headers;

    if (request.body.isNotEmpty) {
      cuerpos[ruta] = jsonDecode(request.body) as Map<String, dynamic>;
    }

    switch (ruta) {
      case '/api/app/solicitudes-familia/mias':
        return json(mias);
      case '/api/app/solicitudes-familia':
        return (solicitar ??
            () => json(
              _solicitud(5, 'PENDIENTE', [_hijo(1, 'Eva', 'PENDIENTE')]),
              201,
            ))();
      case '/api/app/auth/me':
        return json({
          'usuarioId': 7,
          'email': 'ana@example.com',
          'roles': roles,
        });
    }

    // Lo privado lo rechaza el backend a una cuenta sin roles.
    return json({'mensaje': 'No tienes permiso'}, 403);
  }

  int veces(String ruta) => peticiones.where((p) => p.endsWith(ruta)).length;

  /// Todo lo que se pidió que NO es de las solicitudes ni /me.
  List<String> get privadas => peticiones
      .where(
        (p) =>
            !p.contains('/api/app/solicitudes-familia') &&
            !p.contains('/api/app/auth/me'),
      )
      .toList();
}

Finder _clave(String clave) => find.byKey(ValueKey(clave));

void main() {
  late _Backend backend;

  setUp(() async {
    prepararAlmacenamiento();
    await iniciarSesionDePrueba();
    backend = _Backend();
  });

  Future<void> conBackend(Future<void> Function() cuerpo) =>
      conMockHttp(backend.responder, cuerpo);

  group('tarjeta de la solicitud', () {
    testWidgets('pendiente: título, aviso y los hijos con su estado', (
      tester,
    ) async {
      backend.mias = [
        _solicitud(5, 'PENDIENTE', [
          _hijo(1, 'Luis', 'PENDIENTE'),
          _hijo(2, 'Eva', 'APROBADO', equipo: ''),
        ]),
      ];

      await conBackend(() async {
        await pintarFamilia(tester, const MiSolicitudFamiliaPage());

        expect(find.text('Mi solicitud de acceso'), findsOneWidget);
        expect(
          find.text('Solicitud pendiente de revisión por el club'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Hasta entonces no tienes acceso'),
          findsOneWidget,
        );
        expect(find.text('Luis Pérez'), findsOneWidget);
        expect(find.text('Alevín B'), findsOneWidget);
        expect(find.text('Pendiente'), findsOneWidget);
        expect(find.text('Aprobado'), findsOneWidget);
      });
    });

    testWidgets('rechazado: enseña el motivo y deja pedir de nuevo', (
      tester,
    ) async {
      backend.mias = [
        _solicitud(5, 'RECHAZADA', [
          _hijo(1, 'Luis', 'RECHAZADO'),
        ], motivo: 'No lo encontramos en el club'),
      ];

      await conBackend(() async {
        await pintarFamilia(tester, const MiSolicitudFamiliaPage());

        expect(find.text('Solicitud rechazada'), findsOneWidget);
        expect(find.text('Rechazado'), findsOneWidget);
        expect(
          find.text('Motivo: No lo encontramos en el club'),
          findsOneWidget,
        );
        expect(_clave('familia-pedir-acceso'), findsOneWidget);
      });
    });

    testWidgets('sin ninguna solicitud lo dice y ofrece pedir acceso', (
      tester,
    ) async {
      await conBackend(() async {
        await pintarFamilia(tester, const MiSolicitudFamiliaPage());

        expect(
          find.text('No tienes ninguna solicitud de acceso.'),
          findsOneWidget,
        );
        expect(find.text('Pedir acceso a un jugador'), findsOneWidget);
      });
    });

    testWidgets('con una solicitud abierta no ofrece pedir otra', (
      tester,
    ) async {
      backend.mias = [
        _solicitud(5, 'PENDIENTE', [_hijo(1, 'Luis', 'PENDIENTE')]),
      ];

      await conBackend(() async {
        await pintarFamilia(tester, const MiSolicitudFamiliaPage());

        expect(_clave('familia-pedir-acceso'), findsNothing);
      });
    });

    testWidgets('en catalán, en inglés, con letra grande y en oscuro', (
      tester,
    ) async {
      backend.mias = [
        _solicitud(5, 'PENDIENTE', [_hijo(1, 'Luis', 'PENDIENTE')]),
      ];

      await conBackend(() async {
        await pintarFamilia(
          tester,
          const MiSolicitudFamiliaPage(),
          idioma: 'ca',
          tamano: const Size(320, 568),
          escala: 2.0,
          oscuro: true,
        );

        expect(
          find.text('Sol·licitud pendent de revisió pel club'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await pintarFamilia(
          tester,
          const MiSolicitudFamiliaPage(),
          idioma: 'en',
        );

        expect(find.text('Request pending review by the club'), findsOneWidget);
      });
    });
  });

  group('Área Club de una cuenta pendiente de aprobación', () {
    testWidgets(
      'solo ve la tarjeta de su solicitud y cerrar sesión, sin nada privado',
      (tester) async {
        await AuthManager.establecerUsuario(
          AuthUser(
            usuarioId: 7,
            email: 'ana@example.com',
            roles: [],
            nombre: 'Ana',
          ),
        );
        backend.mias = [
          _solicitud(5, 'PENDIENTE', [_hijo(1, 'Luis', 'PENDIENTE')]),
        ];

        await conBackend(() async {
          await pintarFamilia(
            tester,
            const ClubPage(),
            tamano: const Size(390, 1200),
          );

          expect(
            find.text('Solicitud pendiente de revisión por el club'),
            findsOneWidget,
          );
          expect(find.text('Luis Pérez'), findsOneWidget);
          expect(find.text('Cerrar sesión'), findsOneWidget);

          // Nada privado en el menú...
          for (final texto in [
            'Calendario',
            'Mis jugadores',
            'Mis equipos',
            'Mi perfil',
            'Pedir acceso a otro jugador',
          ]) {
            expect(find.text(texto), findsNothing, reason: texto);
          }

          // ...y ninguna petición privada: solo el estado de su solicitud.
          expect(
            backend.privadas,
            isEmpty,
            reason: backend.privadas.join(', '),
          );
          expect(backend.veces('/solicitudes-familia/mias'), 1);
        });
      },
    );

    testWidgets(
      'al aprobar el club se recargan los roles y aparecen Mis jugadores y el resto',
      (tester) async {
        await AuthManager.establecerUsuario(
          AuthUser(
            usuarioId: 7,
            email: 'ana@example.com',
            roles: [],
            nombre: 'Ana',
          ),
        );
        backend.mias = [
          _solicitud(5, 'APROBADA', [_hijo(1, 'Luis', 'APROBADO')]),
        ];
        backend.roles = ['FAMILIAR'];

        await conBackend(() async {
          await pintarFamilia(
            tester,
            const ClubPage(),
            tamano: const Size(390, 1600),
          );
          await tester.pumpAndSettle();

          // Se han vuelto a pedir los roles (como al iniciar sesión).
          expect(backend.veces('/auth/me'), 1);
          expect(AuthManager.usuarioActual?.roles, ['FAMILIAR']);

          // Y el Área Club se reconstruye con lo de la familia, sin cerrar sesión.
          expect(find.text('Mis jugadores'), findsOneWidget);
          expect(find.text('Calendario'), findsOneWidget);
          expect(find.text('Pedir acceso a otro jugador'), findsOneWidget);
          expect(
            find.text('Solicitud pendiente de revisión por el club'),
            findsNothing,
          );
        });
      },
    );

    testWidgets('mientras siga pendiente no se piden los roles', (
      tester,
    ) async {
      await AuthManager.establecerUsuario(
        AuthUser(usuarioId: 7, email: 'ana@example.com', roles: []),
      );
      backend.mias = [
        _solicitud(5, 'PENDIENTE', [_hijo(1, 'Luis', 'PENDIENTE')]),
      ];

      await conBackend(() async {
        await pintarFamilia(
          tester,
          const ClubPage(),
          tamano: const Size(390, 1200),
        );

        expect(backend.veces('/auth/me'), 0);
      });
    });

    testWidgets(
      'recargar el usuario avisa a quien escucha AuthManager.cambios',
      (tester) async {
        await AuthManager.establecerUsuario(
          AuthUser(usuarioId: 7, email: 'ana@example.com', roles: []),
        );
        backend.roles = ['FAMILIAR'];

        await conBackend(() async {
          final antes = AuthManager.cambios.value;

          final cambiaron = await AuthManager.recargarUsuario();

          expect(cambiaron, isTrue);
          expect(AuthManager.cambios.value, greaterThan(antes));

          // Sin cambios de roles no se declara cambio.
          expect(await AuthManager.recargarUsuario(), isFalse);
        });
      },
    );

    testWidgets(
      'si falla el servidor al recargar, el usuario se queda como está',
      (tester) async {
        await AuthManager.establecerUsuario(
          AuthUser(usuarioId: 7, email: 'ana@example.com', roles: []),
        );

        await conMockHttp(
          (request) async => http.Response('boom', 500),
          () async {
            expect(await AuthManager.recargarUsuario(), isFalse);
            expect(AuthManager.usuarioActual?.roles, isEmpty);
          },
        );
      },
    );
  });

  group('pedir acceso a otro jugador, con sesión', () {
    Future<void> rellenar(WidgetTester tester) async {
      await tester.tap(_clave('familia-parentesco'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Padre').last);
      await tester.pumpAndSettle();

      await tester.enterText(_clave('familia-hijo-nombre-0'), 'Eva');
      await tester.enterText(_clave('familia-hijo-apellidos-0'), 'Pérez');
    }

    testWidgets('valida el parentesco, el hijo y las dos casillas', (
      tester,
    ) async {
      await conBackend(() async {
        await pintarFamilia(
          tester,
          const PedirAccesoJugadorPage(),
          tamano: const Size(390, 1400),
        );

        await tester.tap(_clave('familia-principal'));
        await tester.pumpAndSettle();

        expect(find.text('Elige tu parentesco'), findsOneWidget);
        expect(find.text('Escribe el nombre del jugador'), findsOneWidget);
        expect(find.text('Escribe los apellidos del jugador'), findsOneWidget);
        expect(
          find.text('Marca esta casilla para continuar'),
          findsNWidgets(2),
        );
        expect(backend.peticiones, isEmpty);
      });
    });

    testWidgets(
      'envía la solicitud con la sesión, sin crear cuenta ni datos del familiar',
      (tester) async {
        await conBackend(() async {
          await pintarFamilia(
            tester,
            const PedirAccesoJugadorPage(),
            tamano: const Size(390, 1400),
          );

          await rellenar(tester);
          await tester.tap(_clave('familia-casilla-representante'));
          await tester.tap(_clave('familia-casilla-privacidad'));
          await tester.pumpAndSettle();
          await tester.tap(_clave('familia-principal'));
          await tester.pumpAndSettle();

          final cuerpo = backend.cuerpos['/api/app/solicitudes-familia']!;

          expect(cuerpo['parentesco'], 'PADRE');
          expect(cuerpo['hijos'], [
            {'nombre': 'Eva', 'apellidos': 'Pérez'},
          ]);
          expect(cuerpo['aceptaPrivacidad'], isTrue);
          expect(cuerpo['declaraRepresentante'], isTrue);

          // Con la sesión: no se manda el email ni los datos del familiar (son los de la cuenta).
          expect(cuerpo.containsKey('email'), isFalse);
          expect(cuerpo.containsKey('nombre'), isFalse);
          expect(
            backend.cabeceras['/api/app/solicitudes-familia']!['Authorization'],
            'Bearer jwt-prueba',
          );

          // Ni cuenta nueva ni verificación de email.
          expect(
            backend.peticiones.where((p) => p.contains('/public/')),
            isEmpty,
          );
        });
      },
    );

    testWidgets('con una solicitud ya pendiente (409) lo explica', (
      tester,
    ) async {
      backend.solicitar = () => json({
        'mensaje': 'Ya tienes una solicitud pendiente de revisar',
      }, 409);

      await conBackend(() async {
        await pintarFamilia(
          tester,
          const PedirAccesoJugadorPage(),
          tamano: const Size(390, 1400),
        );

        await rellenar(tester);
        await tester.tap(_clave('familia-casilla-representante'));
        await tester.tap(_clave('familia-casilla-privacidad'));
        await tester.pumpAndSettle();
        await tester.tap(_clave('familia-principal'));
        await tester.pumpAndSettle();

        expect(
          find.text('Ya tienes una solicitud pendiente de revisar.'),
          findsOneWidget,
        );
        expect(find.byType(PedirAccesoJugadorPage), findsOneWidget);
      });
    });

    testWidgets(
      'desde el Área Club de un familiar se abre y, al enviar, vuelve con el aviso',
      (tester) async {
        await AuthManager.establecerUsuario(
          AuthUser(usuarioId: 7, email: 'ana@example.com', roles: ['FAMILIAR']),
        );

        await conBackend(() async {
          await pintarFamilia(
            tester,
            const ClubPage(),
            tamano: const Size(390, 1600),
          );

          await tester.ensureVisible(find.text('Pedir acceso a otro jugador'));
          await tester.tap(find.text('Pedir acceso a otro jugador'));
          await tester.pumpAndSettle();

          expect(find.byType(PedirAccesoJugadorPage), findsOneWidget);

          await rellenar(tester);
          await tester.tap(_clave('familia-casilla-representante'));
          await tester.tap(_clave('familia-casilla-privacidad'));
          await tester.pumpAndSettle();
          await tester.tap(_clave('familia-principal'));
          await tester.pumpAndSettle();

          expect(find.byType(PedirAccesoJugadorPage), findsNothing);
          expect(
            find.text('Solicitud enviada. El club la revisará.'),
            findsOneWidget,
          );
        });
      },
    );

    testWidgets(
      'el botón sigue visible con el teclado abierto en un iPhone pequeño',
      (tester) async {
        await conBackend(() async {
          await pintarFamilia(
            tester,
            const PedirAccesoJugadorPage(),
            tamano: const Size(320, 568),
            escala: 1.5,
            oscuro: true,
          );

          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          await tester.pumpAndSettle();

          expect(
            tester.getRect(_clave('familia-principal')).bottom,
            lessThanOrEqualTo(568 - 260),
          );
          expect(tester.takeException(), isNull);
        });
      },
    );
  });
}
