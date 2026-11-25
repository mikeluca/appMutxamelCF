import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_service.dart';
import 'package:app_mutxamel_cf/features/juego/envio_puntuacion.dart';
import 'package:app_mutxamel_cf/features/juego/estado_mutxigol.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/pages/mutxigol_page.dart';
import 'package:app_mutxamel_cf/features/juego/widgets/dialogo_alias.dart';
import 'package:app_mutxamel_cf/features/juego/widgets/fin_de_partida.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/juego_helpers.dart';

const _avisoLogin =
    'Inicia sesión en el Área Club para guardar tus puntuaciones';
const _sesionCaducada =
    'Tu sesión ha caducado. Vuelve a iniciar sesión en el Área Club';
const _noDisponible =
    'El juego no está disponible ahora mismo. Inténtalo más tarde';
const _sinConexion =
    'No se ha podido conectar. Comprueba tu conexión e inténtalo de nuevo.';
const _noGuardada = 'No se ha podido guardar tu puntuación.';

final _usuario = AuthUser(
  usuarioId: 1,
  email: 'ana@example.com',
  roles: ['JUGADOR'],
);

EnvioPuntuacion _envio(JuegoServiceFalso servicio, {bool conSesion = true}) =>
    EnvioPuntuacion(
      servicio: servicio,
      juego: Juego.cabezazos,
      puntos: 5,
      duracion: const Duration(seconds: 40),
      conSesion: conSesion,
      alias: 'Ana',
    );

void main() {
  setUp(() {
    EstadoMutxigol.reiniciar();
    AuthManager.olvidarUsuario();
    FlutterSecureStorage.setMockInitialValues({});
    AuthManager.cargarUsuario = () async => _usuario;
  });

  tearDown(() {
    EstadoMutxigol.reiniciar();
    AuthManager.olvidarUsuario();
    AuthManager.cargarUsuario = AuthService.obtenerUsuarioActual;
  });

  group('restaurar la sesión sin pasar por "Área Club"', () {
    test('restaurarSesion avisa por cambios al pasar de sin usuario a usuario', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});

      final antes = AuthManager.cambios.value;

      expect(await AuthManager.restaurarSesion(), isTrue);

      expect(AuthManager.estaAutenticado, isTrue);
      expect(AuthManager.cambios.value, antes + 1);

      // Otra restauración con el mismo usuario no vuelve a avisar.
      await AuthManager.restaurarSesion();

      expect(AuthManager.cambios.value, antes + 1);
    });

    test('sin token no hay usuario ni aviso', () async {
      final antes = AuthManager.cambios.value;

      expect(await AuthManager.restaurarSesion(), isFalse);

      expect(AuthManager.estaAutenticado, isFalse);
      expect(AuthManager.cambios.value, antes);
    });

    test('un fallo de red no borra el token guardado', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
      AuthManager.cargarUsuario = () async =>
          throw const ApiException('No hay conexión a internet.');

      expect(await AuthManager.restaurarSesion(), isFalse);
      expect(await AuthManager.haySesionGuardada(), isTrue);
    });

    testWidgets('con token guardado, abrir la pestaña del juego carga el perfil y no pide iniciar sesión', (tester) async {
      pantallaDeMovil(tester);
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});

      final servicio = JuegoServiceFalso(
        perfilInicial: const PerfilJuego(alias: 'Ana'),
      );

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(servicio.perfilesPedidos, greaterThanOrEqualTo(1));
      expect(find.text(_avisoLogin), findsNothing);
      expect(find.text('Tu alias: Ana'), findsOneWidget);
    });

    testWidgets('sin token sale "Inicia sesión"', (tester) async {
      pantallaDeMovil(tester);

      final servicio = JuegoServiceFalso();

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(find.text(_avisoLogin), findsOneWidget);
      expect(servicio.perfilesPedidos, 0);
    });

    testWidgets('mientras se restaura la sesión no sale el aviso, solo un indicador', (tester) async {
      pantallaDeMovil(tester);
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});

      final servicio = JuegoServiceFalso(
        perfilInicial: const PerfilJuego(alias: 'Ana'),
      );

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text(_avisoLogin), findsNothing);

      await tester.pumpAndSettle();
    });
  });

  group('el mensaje de cada error del juego', () {
    Future<void> abrirDialogo(
      WidgetTester tester,
      JuegoServiceFalso servicio,
    ) async {
      await tester.pumpWidget(
        appDePrueba(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    DialogoAlias.mostrar(context, servicio: servicio),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('campo-alias')), 'Ana10');
      await tester.tap(find.byKey(const ValueKey('guardar-alias')));
      await tester.pumpAndSettle();
    }

    final casosAlias = <(String, Object, String)>[
      ('401', errorHttp(401, 'no vale'), _sesionCaducada),
      ('404', errorHttp(404, 'no existe'), _noDisponible),
      ('500', errorHttp(500, 'boom'), _noDisponible),
      ('409', errorHttp(409, 'Ese alias ya está en uso'), 'Ese alias ya está en uso'),
      ('403', errorHttp(403, 'x'), 'No tienes permiso'),
      ('sin red', const ApiException('No hay conexión a internet.'), _sinConexion),
    ];

    for (final (nombre, error, texto) in casosAlias) {
      testWidgets('alias: $nombre', (tester) async {
        pantallaDeMovil(tester);

        final servicio = JuegoServiceFalso()..errorAlActualizar = error;

        await abrirDialogo(tester, servicio);

        expect(find.text(texto), findsOneWidget);
        // Solo el 401 ofrece ir al login.
        expect(
          find.byKey(const ValueKey('ir-a-login')),
          nombre == '401' ? findsOneWidget : findsNothing,
        );
      });
    }

    final casosEnvio = <(String, Object, String)>[
      ('401', errorHttp(401, 'no vale'), _sesionCaducada),
      ('404', errorHttp(404, 'no existe'), _noDisponible),
      ('500', errorHttp(500, 'boom'), _noDisponible),
      ('409', errorHttp(409, 'Ya has enviado esta partida'), 'Ya has enviado esta partida'),
      ('sin red', const ApiException('No hay conexión a internet.'), _noGuardada),
    ];

    for (final (nombre, error, texto) in casosEnvio) {
      testWidgets('envío de la puntuación: $nombre', (tester) async {
        final servicio = JuegoServiceFalso()..errorAlGuardar = error;
        final envio = _envio(servicio);

        await tester.pumpWidget(
          appDePrueba(
            Scaffold(
              body: SingleChildScrollView(
                child: FinDePartida(
                  equipacion: Equipacion.rosa,
                  puntos: 5,
                  recordAnterior: 0,
                  envio: envio,
                  onOtraVez: () {},
                  onRanking: () {},
                  onElegirAlias: () {},
                ),
              ),
            ),
          ),
        );

        await envio.iniciar();
        await tester.pump();

        expect(find.text(texto), findsOneWidget);
        expect(
          find.byKey(const ValueKey('ir-a-login')),
          nombre == '401' ? findsOneWidget : findsNothing,
        );
        expect(
          find.byKey(const ValueKey('reintentar-envio')),
          nombre == '401' ? findsNothing : findsOneWidget,
        );
      });
    }

    test('el envío sin sesión pero con token guardado restaura la sesión y envía', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});

      final servicio = JuegoServiceFalso();
      final envio = _envio(servicio, conSesion: false);

      await envio.iniciar();

      expect(envio.estado, EstadoEnvio.enviado);
      expect(servicio.guardadas, hasLength(1));
    });

    test('el envío sin sesión ni token dice que hay que iniciar sesión', () async {
      final envio = _envio(JuegoServiceFalso(), conSesion: false);

      await envio.iniciar();

      expect(envio.estado, EstadoEnvio.sinSesion);
    });
  });
}
