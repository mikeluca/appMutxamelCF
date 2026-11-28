import 'dart:convert';

import 'package:app_mutxamel_cf/core/notifications/services/permiso_notificaciones.dart';
import 'package:app_mutxamel_cf/features/auth/pages/activar_cuenta_page.dart';
import 'package:app_mutxamel_cf/features/auth/pages/login_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/auth/services/funciones_app_service.dart';
import 'package:app_mutxamel_cf/features/familia/pages/codigo_familia_page.dart';
import 'package:app_mutxamel_cf/features/familia/pages/registro_familia_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../../support/http_test_helpers.dart';
import 'soporte_familia.dart';

/// Backend simulado del registro de familias: apunta las peticiones y responde según lo configurado.
class _Backend {
  final peticiones = <String>[];
  final cuerpos = <String, Map<String, dynamic>>{};

  http.Response Function() registro = () => json({'estado': 'CODIGO_ENVIADO'});
  http.Response Function() verificar = () => json({
    'token': 'jwt-familia',
    'usuarioId': 9,
    'email': 'ana@example.com',
    'roles': <String>[],
  });
  http.Response Function() reenviar = () => http.Response('', 204);

  Future<http.Response> responder(http.Request request) async {
    final ruta = request.url.path;

    peticiones.add('${request.method} $ruta');

    if (request.body.isNotEmpty) {
      cuerpos[ruta] = jsonDecode(request.body) as Map<String, dynamic>;
    }

    switch (ruta) {
      case '/api/public/solicitudes-familia':
        return registro();
      case '/api/public/solicitudes-familia/verificar':
        return verificar();
      case '/api/public/solicitudes-familia/reenviar-codigo':
        return reenviar();
      case '/api/app/auth/me':
        return json({'usuarioId': 9, 'email': 'ana@example.com', 'roles': []});
    }

    return http.Response('no esperado: $ruta', 404);
  }

  int veces(String ruta) => peticiones.where((p) => p.endsWith(ruta)).length;
}

Finder _clave(String clave) => find.byKey(ValueKey(clave));

Future<void> _paso0(
  WidgetTester tester, {
  String nombre = 'Ana',
  String apellidos = 'Pérez Gil',
  String email = 'Ana@Example.com',
  String telefono = '623 17 68 18',
  String parentesco = 'Madre',
}) async {
  await tester.enterText(_clave('familia-nombre'), nombre);
  await tester.enterText(_clave('familia-apellidos'), apellidos);
  await tester.enterText(_clave('familia-email'), email);
  await tester.enterText(_clave('familia-telefono'), telefono);

  if (parentesco.isNotEmpty) {
    await tester.ensureVisible(_clave('familia-parentesco'));
    await tester.tap(_clave('familia-parentesco'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(parentesco).last);
    await tester.pumpAndSettle();
  }
}

Future<void> _siguiente(WidgetTester tester) async {
  await tester.tap(_clave('familia-principal'));
  await tester.pumpAndSettle();
}

Future<void> _hijo(
  WidgetTester tester,
  int i, {
  String nombre = 'Luis',
  String apellidos = 'Pérez',
  String equipo = 'Alevín B',
}) async {
  await tester.enterText(_clave('familia-hijo-nombre-$i'), nombre);
  await tester.enterText(_clave('familia-hijo-apellidos-$i'), apellidos);

  if (equipo.isNotEmpty) {
    await tester.enterText(find.byType(TextFormField).at(2 + i * 3), equipo);
  }
}

Future<void> _marcarCasillas(WidgetTester tester) async {
  await tester.tap(_clave('familia-casilla-representante'));
  await tester.tap(_clave('familia-casilla-privacidad'));
  await tester.pumpAndSettle();
}

/// Rellena los tres pasos y llega al de las casillas.
Future<void> _hastaCasillas(WidgetTester tester) async {
  await _paso0(tester);
  await _siguiente(tester);
  await _hijo(tester, 0);
  await _siguiente(tester);
}

void main() {
  late _Backend backend;

  setUp(() {
    prepararAlmacenamiento();
    backend = _Backend();
    PermisoNotificaciones.leerEstado = () async =>
        EstadoPermisoAvisos.concedido;
  });

  Future<void> conRegistro(
    WidgetTester tester,
    Future<void> Function() cuerpo, {
    Size tamano = const Size(375, 667),
    double escala = 1.0,
    bool oscuro = false,
  }) async {
    await conMockHttp(backend.responder, () async {
      await pintarFamilia(
        tester,
        const RegistroFamiliaPage(),
        tamano: tamano,
        escala: escala,
        oscuro: oscuro,
        rutas: {'/login': (_) => const LoginPage()},
      );
      await cuerpo();
    });
  }

  group('entrada', () {
    testWidgets(
      'el login ofrece "Soy familiar de un jugador" junto a Activar cuenta',
      (tester) async {
        final original = FuncionesApp.leerDelServidor;
        FuncionesApp.leerDelServidor = () async => {
          'registroFamiliasHabilitado': true,
        };
        addTearDown(() => FuncionesApp.leerDelServidor = original);

        await pintarFamilia(
          tester,
          const LoginPage(),
          tamano: const Size(390, 900),
        );
        await tester.pumpAndSettle();

        expect(_clave('login-soy-familiar'), findsOneWidget);
        expect(find.text('Soy familiar de un jugador'), findsOneWidget);
        expect(find.text('Activar cuenta'), findsOneWidget);

        await tester.ensureVisible(_clave('login-soy-familiar'));
        await tester.tap(_clave('login-soy-familiar'));
        await tester.pumpAndSettle();

        expect(find.byType(RegistroFamiliaPage), findsOneWidget);
      },
    );
  });

  group('paso 1: tus datos', () {
    testWidgets('empieza en el paso 1 de 3 con los cinco campos', (
      tester,
    ) async {
      await conRegistro(tester, () async {
        expect(find.text('Paso 1 de 3'), findsOneWidget);
        expect(find.text('Tus datos'), findsOneWidget);
        expect(_clave('familia-nombre'), findsOneWidget);
        expect(_clave('familia-apellidos'), findsOneWidget);
        expect(_clave('familia-email'), findsOneWidget);
        expect(find.text('Teléfono (opcional)'), findsOneWidget);
        expect(_clave('familia-parentesco'), findsOneWidget);
        expect(_clave('familia-atras'), findsNothing);
      });
    });

    testWidgets('valida los campos obligatorios y no avanza', (tester) async {
      await conRegistro(tester, () async {
        await _siguiente(tester);

        expect(find.text('Escribe tu nombre'), findsOneWidget);
        expect(find.text('Escribe tus apellidos'), findsOneWidget);
        expect(find.text('Introduce tu email'), findsOneWidget);
        expect(find.text('Elige tu parentesco'), findsOneWidget);
        expect(find.text('Paso 1 de 3'), findsOneWidget);
      });
    });

    testWidgets(
      'rechaza un email mal escrito y un teléfono raro, y el teléfono es opcional',
      (tester) async {
        await conRegistro(tester, () async {
          await _paso0(tester, email: 'no-es-email', telefono: 'abc');
          await _siguiente(tester);

          expect(find.text('Introduce un email válido'), findsOneWidget);
          expect(find.text('El teléfono no es válido'), findsOneWidget);
          expect(find.text('Paso 1 de 3'), findsOneWidget);

          await tester.enterText(_clave('familia-email'), 'ana@example.com');
          await tester.enterText(_clave('familia-telefono'), '');
          await _siguiente(tester);

          expect(find.text('Paso 2 de 3'), findsOneWidget);
        });
      },
    );

    testWidgets('los cuatro parentescos', (tester) async {
      await conRegistro(tester, () async {
        await tester.tap(_clave('familia-parentesco'));
        await tester.pumpAndSettle();

        expect(find.text('Madre'), findsWidgets);
        expect(find.text('Padre'), findsOneWidget);
        expect(find.text('Tutor/a legal'), findsOneWidget);
        expect(find.text('Otro familiar autorizado'), findsOneWidget);
      });
    });
  });

  group('paso 2: tus hijos', () {
    testWidgets('exige nombre y apellidos del jugador; el equipo es opcional', (
      tester,
    ) async {
      await conRegistro(tester, () async {
        await _paso0(tester);
        await _siguiente(tester);

        expect(find.text('Paso 2 de 3'), findsOneWidget);

        await _siguiente(tester);

        expect(find.text('Escribe el nombre del jugador'), findsOneWidget);
        expect(find.text('Escribe los apellidos del jugador'), findsOneWidget);
        expect(find.text('Paso 2 de 3'), findsOneWidget);

        await _hijo(tester, 0, equipo: '');
        await _siguiente(tester);

        expect(find.text('Paso 3 de 3'), findsOneWidget);
      });
    });

    testWidgets('se pueden añadir hijos hasta cinco y quitarlos', (
      tester,
    ) async {
      await conRegistro(tester, () async {
        await _paso0(tester);
        await _siguiente(tester);

        expect(_clave('familia-quitar-hijo-0'), findsNothing);

        for (var i = 1; i < 5; i++) {
          await tester.ensureVisible(_clave('familia-anadir-hijo'));
          await tester.tap(_clave('familia-anadir-hijo'));
          await tester.pumpAndSettle();
        }

        expect(find.text('Hijo o hija 5'), findsOneWidget);
        // Con cinco ya no se puede añadir otro y se explica.
        expect(_clave('familia-anadir-hijo'), findsNothing);
        expect(find.textContaining('máximo de 5 jugadores'), findsOneWidget);

        await tester.ensureVisible(_clave('familia-quitar-hijo-4'));
        await tester.tap(_clave('familia-quitar-hijo-4'));
        await tester.pumpAndSettle();

        expect(find.text('Hijo o hija 5'), findsNothing);
        expect(_clave('familia-anadir-hijo'), findsOneWidget);
      });
    });

    testWidgets('sugiere categorías como chips y nunca nombres de jugadores', (
      tester,
    ) async {
      await conRegistro(tester, () async {
        await _paso0(tester);
        await _siguiente(tester);

        for (final categoria in [
          'Escuelita',
          'Prebenjamín',
          'Benjamín',
          'Alevín',
          'Infantil',
          'Cadete',
          'Juvenil',
        ]) {
          expect(
            _clave('familia-sugerencia-0-$categoria'),
            findsOneWidget,
            reason: categoria,
          );
        }

        // Tocar una rellena el campo (texto libre: se puede seguir escribiendo).
        await tester.ensureVisible(_clave('familia-sugerencia-0-Alevín'));
        await tester.tap(_clave('familia-sugerencia-0-Alevín'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextFormField, 'Alevín'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField).at(2), 'Alevín C');

        expect(find.widgetWithText(TextFormField, 'Alevín C'), findsOneWidget);

        // Nada de la red: no se ha pedido ningún jugador.
        expect(backend.peticiones, isEmpty);
      });
    });

    testWidgets('al volver atrás no se pierde lo escrito', (tester) async {
      await conRegistro(tester, () async {
        await _paso0(tester);
        await _siguiente(tester);
        await _hijo(tester, 0);
        await _siguiente(tester);
        await tester.tap(_clave('familia-atras'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextFormField, 'Luis'), findsOneWidget);

        await tester.tap(_clave('familia-atras'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextFormField, 'Ana'), findsOneWidget);
      });
    });
  });

  group('paso 3: casillas y envío', () {
    testWidgets('sin las dos casillas no se envía nada y se avisa', (
      tester,
    ) async {
      await conRegistro(tester, () async {
        await _hastaCasillas(tester);

        expect(find.text('Paso 3 de 3'), findsOneWidget);
        expect(find.text('Enviar solicitud'), findsOneWidget);

        await _siguiente(tester);

        expect(
          find.text('Marca esta casilla para continuar'),
          findsNWidgets(2),
        );
        expect(backend.peticiones, isEmpty);

        await tester.tap(_clave('familia-casilla-representante'));
        await tester.pumpAndSettle();
        await _siguiente(tester);

        expect(find.text('Marca esta casilla para continuar'), findsOneWidget);
        expect(backend.peticiones, isEmpty);
      });
    });

    testWidgets(
      'las casillas dicen lo pedido y hay enlace a la política de privacidad',
      (tester) async {
        await conRegistro(tester, () async {
          await _hastaCasillas(tester);

          expect(
            find.text(
              'Declaro ser su representante legal o estar autorizado por él',
            ),
            findsOneWidget,
          );
          expect(find.text('Acepto la política de privacidad'), findsOneWidget);
          expect(_clave('familia-leer-privacidad'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'el registro completo manda los datos, los hijos y las casillas',
      (tester) async {
        await conRegistro(tester, () async {
          await _paso0(tester);
          await _siguiente(tester);
          await _hijo(
            tester,
            0,
            nombre: ' Luis ',
            apellidos: 'Pérez',
            equipo: 'Alevín B',
          );

          await tester.ensureVisible(_clave('familia-anadir-hijo'));
          await tester.tap(_clave('familia-anadir-hijo'));
          await tester.pumpAndSettle();
          await _hijo(tester, 1, nombre: 'Eva', apellidos: 'Pérez', equipo: '');
          await _siguiente(tester);

          await _marcarCasillas(tester);
          await _siguiente(tester);

          final cuerpo = backend.cuerpos['/api/public/solicitudes-familia']!;

          expect(cuerpo['nombre'], 'Ana');
          expect(cuerpo['apellidos'], 'Pérez Gil');
          expect(cuerpo['email'], 'ana@example.com');
          expect(cuerpo['telefono'], '623 17 68 18');
          expect(cuerpo['parentesco'], 'MADRE');
          expect(cuerpo['aceptaPrivacidad'], isTrue);
          expect(cuerpo['declaraRepresentante'], isTrue);
          expect(cuerpo['idioma'], 'es');
          expect(cuerpo['hijos'], [
            {'nombre': 'Luis', 'apellidos': 'Pérez', 'equipo': 'Alevín B'},
            {'nombre': 'Eva', 'apellidos': 'Pérez'},
          ]);

          // Sin fecha de nacimiento ni otros datos del menor.
          expect(jsonEncode(cuerpo), isNot(contains('nacimiento')));

          // Y sigue en la pantalla del código, con el email.
          expect(find.byType(CodigoFamiliaPage), findsOneWidget);
          expect(find.textContaining('ana@example.com'), findsOneWidget);
          expect(find.textContaining('Caduca en 5 días'), findsOneWidget);
        });
      },
    );
  });

  group('errores del backend', () {
    testWidgets('email con cuenta: mensaje y botón a Iniciar sesión', (
      tester,
    ) async {
      backend.registro = () =>
          json({'estado': 'CUENTA_EXISTENTE', 'mensaje': 'x'});

      await conRegistro(tester, () async {
        await _hastaCasillas(tester);
        await _marcarCasillas(tester);
        await _siguiente(tester);

        expect(_clave('familia-bloqueo-cuenta'), findsOneWidget);
        expect(
          find.text(
            'Ya tienes una cuenta con ese email. Inicia sesión y pide el acceso desde Área Club.',
          ),
          findsOneWidget,
        );
        expect(find.byType(CodigoFamiliaPage), findsNothing);

        await tester.ensureVisible(_clave('familia-bloqueo-boton'));
        await tester.tap(_clave('familia-bloqueo-boton'));
        await tester.pumpAndSettle();

        expect(find.byType(LoginPage), findsOneWidget);
        // Con el email ya puesto.
        expect(
          find.widgetWithText(TextFormField, 'ana@example.com'),
          findsOneWidget,
        );
      });
    });

    testWidgets(
      'email con invitación pendiente: mensaje y botón a Activar cuenta',
      (tester) async {
        backend.registro = () =>
            json({'estado': 'INVITACION_PENDIENTE', 'mensaje': 'x'});

        await conRegistro(tester, () async {
          await _hastaCasillas(tester);
          await _marcarCasillas(tester);
          await _siguiente(tester);

          expect(_clave('familia-bloqueo-invitacion'), findsOneWidget);
          expect(
            find.textContaining(
              'Usa «Activar cuenta» con el código que te enviamos',
            ),
            findsOneWidget,
          );

          await tester.ensureVisible(_clave('familia-bloqueo-boton'));
          await tester.tap(_clave('familia-bloqueo-boton'));
          await tester.pumpAndSettle();

          expect(find.byType(ActivarCuentaPage), findsOneWidget);
          expect(
            find.widgetWithText(TextFormField, 'ana@example.com'),
            findsOneWidget,
          );
        });
      },
    );

    testWidgets(
      'un 403 REGISTRO_NO_DISPONIBLE enseña su mensaje, sin pasos siguientes',
      (tester) async {
        const mensaje =
            'El registro de familias estará disponible próximamente. Mientras tanto, pide la invitación a tu entrenador o al club.';
        backend.registro = () =>
            json({'estado': 'REGISTRO_NO_DISPONIBLE', 'mensaje': mensaje}, 403);
        await conRegistro(tester, () async {
          await _hastaCasillas(tester);
          await _marcarCasillas(tester);
          await _siguiente(tester);
          expect(find.text(mensaje), findsOneWidget);
          expect(find.text('No tienes permiso para hacer esto.'), findsNothing);
          expect(find.byType(CodigoFamiliaPage), findsNothing);
          expect(backend.veces('/solicitudes-familia'), 1);
        });
      },
    );
    testWidgets('demasiados intentos', (tester) async {
      backend.registro = () => json({
        'codigo': 'DEMASIADOS_INTENTOS',
        'mensaje': 'Demasiados intentos. Inténtalo de nuevo en unos minutos.',
      }, 429);

      await conRegistro(tester, () async {
        await _hastaCasillas(tester);
        await _marcarCasillas(tester);
        await _siguiente(tester);

        expect(
          find.text('Demasiados intentos. Inténtalo de nuevo en unos minutos.'),
          findsOneWidget,
        );
        expect(find.byType(CodigoFamiliaPage), findsNothing);
      });
    });

    testWidgets('un 400 enseña el mensaje claro del backend', (tester) async {
      backend.registro = () =>
          json({'mensaje': 'Indica al menos un hijo o hija'}, 400);

      await conRegistro(tester, () async {
        await _hastaCasillas(tester);
        await _marcarCasillas(tester);
        await _siguiente(tester);

        expect(find.text('Indica al menos un hijo o hija'), findsOneWidget);
      });
    });

    testWidgets(
      'si el email no ha salido (503) sigue al código y avisa de reenviarlo',
      (tester) async {
        backend.registro = () =>
            json({'estado': 'ENVIO_FALLIDO', 'mensaje': 'x'}, 503);

        await conRegistro(tester, () async {
          await _hastaCasillas(tester);
          await _marcarCasillas(tester);
          await _siguiente(tester);

          expect(find.byType(CodigoFamiliaPage), findsOneWidget);
          expect(_clave('familia-envio-fallido'), findsOneWidget);
        });
      },
    );

    testWidgets('sin red sale el error de conexión y se puede reintentar', (
      tester,
    ) async {
      var llamadas = 0;

      await conMockHttp(
        (request) async {
          llamadas++;
          throw http.ClientException('sin red');
        },
        () async {
          await pintarFamilia(tester, const RegistroFamiliaPage());
          await _hastaCasillas(tester);
          await _marcarCasillas(tester);
          await _siguiente(tester);

          expect(_clave('familia-error'), findsOneWidget);
          expect(llamadas, 1);

          await _siguiente(tester);

          expect(llamadas, 2);
        },
      );
    });
  });

  group('código y contraseña', () {
    Future<void> irAlCodigo(WidgetTester tester) async {
      await _hastaCasillas(tester);
      await _marcarCasillas(tester);
      await _siguiente(tester);
    }

    testWidgets('valida el código y la contraseña como Activar cuenta', (
      tester,
    ) async {
      await conRegistro(tester, () async {
        await irAlCodigo(tester);
        await tester.tap(_clave('familia-confirmar-entrar'));
        await tester.pumpAndSettle();

        expect(
          find.text('Introduce el código que te enviamos por email'),
          findsOneWidget,
        );
        expect(find.text('Elige una contraseña'), findsOneWidget);

        await tester.enterText(_clave('familia-codigo'), '123');
        await tester.enterText(_clave('familia-password'), 'corta');
        await tester.enterText(_clave('familia-confirmar'), 'otra');
        await tester.tap(_clave('familia-confirmar-entrar'));
        await tester.pumpAndSettle();

        expect(find.text('El código debe tener 6 dígitos'), findsOneWidget);
        expect(find.text('Debe tener al menos 8 caracteres'), findsOneWidget);
        expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
        expect(backend.veces('/verificar'), 0);
      });
    });

    testWidgets(
      'con todo bien verifica, inicia sesión sin roles y entra en el Área Club',
      (tester) async {
        await conRegistro(tester, () async {
          await irAlCodigo(tester);

          await tester.enterText(_clave('familia-codigo'), '123456');
          await tester.enterText(_clave('familia-password'), 'clave-segura-1');
          await tester.enterText(_clave('familia-confirmar'), 'clave-segura-1');
          await tester.tap(_clave('familia-confirmar-entrar'));
          await tester.pumpAndSettle();

          final cuerpo =
              backend.cuerpos['/api/public/solicitudes-familia/verificar']!;

          expect(cuerpo['email'], 'ana@example.com');
          expect(cuerpo['codigo'], '123456');
          expect(cuerpo['password'], 'clave-segura-1');
          expect(AuthManager.usuarioActual?.roles, isEmpty);
          expect(find.text('AREA CLUB'), findsOneWidget);
        });
      },
    );

    testWidgets('un código incorrecto se explica y no entra', (tester) async {
      backend.verificar = () =>
          json({'mensaje': 'El código no es válido o ha caducado.'}, 400);

      await conRegistro(tester, () async {
        await irAlCodigo(tester);

        await tester.enterText(_clave('familia-codigo'), '000000');
        await tester.enterText(_clave('familia-password'), 'clave-segura-1');
        await tester.enterText(_clave('familia-confirmar'), 'clave-segura-1');
        await tester.tap(_clave('familia-confirmar-entrar'));
        await tester.pumpAndSettle();

        expect(
          find.text('El código no es válido o ha caducado.'),
          findsOneWidget,
        );
        expect(AuthManager.usuarioActual, isNull);
        expect(find.text('AREA CLUB'), findsNothing);
      });
    });

    testWidgets('reenviar el código pide uno nuevo y respeta el límite', (
      tester,
    ) async {
      await conRegistro(tester, () async {
        await irAlCodigo(tester);

        await tester.tap(_clave('familia-reenviar'));
        await tester.pumpAndSettle();

        expect(backend.veces('/reenviar-codigo'), 1);
        expect(
          backend
              .cuerpos['/api/public/solicitudes-familia/reenviar-codigo']!['email'],
          'ana@example.com',
        );
        expect(_clave('familia-codigo-reenviado'), findsOneWidget);

        backend.reenviar = () =>
            json({'codigo': 'DEMASIADOS_INTENTOS', 'mensaje': 'x'}, 429);

        await tester.tap(_clave('familia-reenviar'));
        await tester.pumpAndSettle();

        expect(
          find.text('Demasiados intentos. Inténtalo de nuevo en unos minutos.'),
          findsOneWidget,
        );
      });
    });

    testWidgets('el código solo admite dígitos y seis como máximo', (
      tester,
    ) async {
      await conRegistro(tester, () async {
        await irAlCodigo(tester);

        await tester.enterText(_clave('familia-codigo'), '12ab34567');

        expect(
          tester
              .widget<TextFormField>(_clave('familia-codigo'))
              .controller!
              .text,
          '123456',
        );
      });
    });
  });

  group('pantalla pequeña, letra grande y modo oscuro', () {
    testWidgets(
      'los tres pasos caben en un iPhone SE con letra al 200 % y en oscuro',
      (tester) async {
        await conRegistro(
          tester,
          () async {
            await _paso0(tester);

            expect(tester.takeException(), isNull);
            await _siguiente(tester);
            await _hijo(tester, 0);
            expect(tester.takeException(), isNull);
            await _siguiente(tester);
            expect(tester.takeException(), isNull);

            // El botón principal sigue a la vista.
            expect(
              tester.getRect(_clave('familia-principal')).bottom,
              lessThanOrEqualTo(667),
            );
            expect(
              tester.getRect(_clave('familia-principal')).top,
              greaterThanOrEqualTo(0),
            );
          },
          tamano: const Size(320, 568),
          escala: 2.0,
          oscuro: true,
        );
      },
    );

    testWidgets(
      'con el teclado abierto el botón principal queda por encima del teclado',
      (tester) async {
        await conRegistro(tester, () async {
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();

          await tester.tap(_clave('familia-nombre'));
          await tester.pumpAndSettle();

          final boton = tester.getRect(_clave('familia-principal'));

          // Pantalla de 667 de alto y teclado de 300: el botón tiene que acabar antes de la línea del teclado.
          expect(boton.bottom, lessThanOrEqualTo(667 - 300));
          expect(tester.takeException(), isNull);

          // Y se puede pulsar.
          await tester.tap(_clave('familia-principal'));
          await tester.pumpAndSettle();

          expect(find.text('Escribe tu nombre'), findsOneWidget);
        });
      },
    );

    testWidgets('también en catalán y en inglés', (tester) async {
      for (final (idioma, boton, paso) in [
        ('ca', 'Següent', 'Pas 1 de 3'),
        ('en', 'Next', 'Step 1 of 3'),
      ]) {
        await conMockHttp(backend.responder, () async {
          await pintarFamilia(
            tester,
            const RegistroFamiliaPage(),
            idioma: idioma,
          );

          expect(find.text(boton), findsOneWidget);
          expect(find.text(paso), findsOneWidget);
        });
      }
    });
  });

  test('el código se limita a 6 dígitos con el formateador de dígitos', () {
    expect(
      FilteringTextInputFormatter.digitsOnly
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '1a2'),
          )
          .text,
      '12',
    );
  });
}
