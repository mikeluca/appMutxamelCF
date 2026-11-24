import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/juego/estado_mutxigol.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/pages/mutxigol_page.dart';
import 'package:app_mutxamel_cf/features/juego/pages/partida_juego_page.dart';
import 'package:app_mutxamel_cf/features/juego/pages/ranking_juego_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/juego_helpers.dart';

String _parado(Equipacion e) =>
    ImagenesMutxigol.pose(e, PoseMutxigol.parado);

Future<void> _iniciarSesion() => AuthManager.establecerUsuario(
  AuthUser(usuarioId: 1, email: 'ana@example.com', roles: ['JUGADOR']),
);

PerfilJuego _perfil({
  String? alias,
  Equipacion equipacion = Equipacion.azul,
  int atrapa = 0,
  int parejasMs = 0,
}) => PerfilJuego(
  alias: alias,
  equipacion: equipacion,
  juegos: {
    if (atrapa > 0)
      Juego.atrapa: MarcasDeJuego(
        historico: MarcaJuego(puntos: atrapa, posicion: 4),
      ),
    if (parejasMs > 0)
      Juego.parejas: MarcasDeJuego(
        esTiempo: true,
        historico: MarcaJuego(puntos: 8, tiempoMs: parejasMs, posicion: 2),
      ),
  },
);

void main() {
  setUp(() {
    EstadoMutxigol.reiniciar();
    AuthManager.olvidarUsuario();
  });

  tearDown(() {
    EstadoMutxigol.reiniciar();
    AuthManager.olvidarUsuario();
  });

  group('sin sesión', () {
    testWidgets('Mutxigol parado con la equipación azul, las 3 tarjetas en orden y el botón Ranking', (tester) async {
      pantallaDeMovil(tester, alto: 2000);
      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: JuegoServiceFalso())));
      await tester.pump();

      expect(imagenDe(_parado(Equipacion.azul)), findsOneWidget);

      const codigos = ['ATRAPA', 'CABEZAZOS', 'PAREJAS'];

      for (final c in codigos) {
        expect(find.byKey(ValueKey('tarjeta-$c')), findsOneWidget, reason: c);
      }

      // En este orden, de arriba abajo.
      final ys = [for (final c in codigos) tester.getTopLeft(find.byKey(ValueKey('tarjeta-$c'))).dy];

      expect(ys, [...ys]..sort());
      expect(find.text('Atrapa balones'), findsOneWidget);
      expect(find.text('Cabezazos'), findsOneWidget);
      expect(find.text('Parejas de escudos'), findsOneWidget);
      expect(find.text('Penaltis'), findsNothing);
      expect(find.text('Toques'), findsNothing);
      expect(find.text('Regatea'), findsNothing);
      expect(find.byKey(const ValueKey('tarjeta-REGATEA')), findsNothing);
      expect(find.byKey(const ValueKey('boton-ranking')), findsOneWidget);

      // Cada tarjeta lleva su pose.
      expect(imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.atrapando)), findsOneWidget);
      expect(imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.salto)), findsOneWidget);
      expect(imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.cara)), findsOneWidget);
    });

    testWidgets('la tarjeta de Atrapa tiene el botón "¿Cómo se juega?" con la leyenda', (tester) async {
      pantallaDeMovil(tester, alto: 2000);
      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: JuegoServiceFalso())));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('como-se-juega-atrapa')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('leyenda-atrapa')), findsOneWidget);
      expect(find.text('Balón dorado: +5 puntos.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('cerrar-leyenda')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('leyenda-atrapa')), findsNothing);
    });

    testWidgets('dice que hay que iniciar sesión para guardar y no enseña récords', (tester) async {
      pantallaDeMovil(tester);
      final servicio = JuegoServiceFalso();

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pump();

      expect(
        find.text('Inicia sesión en el Área Club para guardar tus puntuaciones'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('record-ATRAPA')), findsNothing);
      expect(servicio.perfilesPedidos, 0);
    });

    testWidgets('el selector cambia la equipación (carpeta rosa) y no llama al backend', (tester) async {
      pantallaDeMovil(tester);
      final servicio = JuegoServiceFalso();

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pump();

      await tester.tap(find.text('Rosa'));
      await tester.pump();

      expect(imagenDe(_parado(Equipacion.rosa)), findsOneWidget);
      expect(imagenDe(_parado(Equipacion.azul)), findsNothing);
      expect(EstadoMutxigol.equipacion.value, Equipacion.rosa);
      expect(servicio.actualizaciones, isEmpty);

      await tester.tap(find.text('Azul'));
      await tester.pump();

      expect(imagenDe(_parado(Equipacion.azul)), findsOneWidget);
    });

    testWidgets('la equipación elegida vale mientras la app está abierta (si se vuelve a la pantalla)', (tester) async {
      pantallaDeMovil(tester);
      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: JuegoServiceFalso())));
      await tester.tap(find.text('Rosa'));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: JuegoServiceFalso())));
      await tester.pump();

      expect(imagenDe(_parado(Equipacion.rosa)), findsOneWidget);
    });
  });

  group('con sesión', () {
    testWidgets('carga el perfil: la equipación guardada, el alias y los récords', (tester) async {
      pantallaDeMovil(tester);
      await _iniciarSesion();

      final servicio = JuegoServiceFalso(
        perfilInicial: _perfil(
          alias: 'Mutxigol10',
          equipacion: Equipacion.rosa,
          atrapa: 12,
          parejasMs: 83450,
        ),
      );

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(imagenDe(_parado(Equipacion.rosa)), findsOneWidget);
      expect(find.text('Tu alias: Mutxigol10'), findsOneWidget);
      expect(find.text('Tu récord: 12'), findsOneWidget);
      // En Parejas el récord es el mejor tiempo.
      expect(find.text('Tu mejor tiempo: 1:23,4'), findsOneWidget);
      expect(find.byKey(const ValueKey('record-PAREJAS')), findsOneWidget);
      expect(find.text('Aún sin récord'), findsOneWidget);
      expect(
        find.text('Inicia sesión en el Área Club para guardar tus puntuaciones'),
        findsNothing,
      );
    });

    testWidgets('el selector guarda la equipación en el perfil del juego', (tester) async {
      pantallaDeMovil(tester);
      await _iniciarSesion();

      final servicio = JuegoServiceFalso(
        perfilInicial: _perfil(alias: 'Ana'),
      );

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rosa'));
      await tester.pumpAndSettle();

      expect(servicio.actualizaciones, [(null, Equipacion.rosa)]);
      expect(imagenDe(_parado(Equipacion.rosa)), findsOneWidget);

      await tester.tap(find.text('Azul'));
      await tester.pumpAndSettle();

      expect(servicio.actualizaciones.last, (null, Equipacion.azul));
    });

    testWidgets('si no se puede guardar la equipación, avisa (y se sigue viendo)', (tester) async {
      pantallaDeMovil(tester);
      await _iniciarSesion();

      final servicio = JuegoServiceFalso(perfilInicial: _perfil(alias: 'Ana'))
        ..errorAlActualizar = const ApiException('No hay conexión a internet.');

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rosa'));
      await tester.pumpAndSettle();

      expect(find.text('No se ha podido guardar la equipación'), findsOneWidget);
      expect(imagenDe(_parado(Equipacion.rosa)), findsOneWidget);
    });

    testWidgets('sin alias: aviso para elegirlo y el diálogo lo guarda', (tester) async {
      pantallaDeMovil(tester);
      await _iniciarSesion();

      final servicio = JuegoServiceFalso(perfilInicial: _perfil());

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(find.text('Elige tu alias para salir en el ranking'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('accion-aviso')));
      await tester.pumpAndSettle();

      // Las reglas del backend, a la vista.
      expect(find.textContaining('De 3 a 15 caracteres'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('campo-alias')), 'Mutxigol10');
      await tester.tap(find.byKey(const ValueKey('guardar-alias')));
      await tester.pumpAndSettle();

      expect(servicio.actualizaciones, [('Mutxigol10', null)]);
      expect(find.text('Tu alias: Mutxigol10'), findsOneWidget);
      expect(find.text('Elige tu alias para salir en el ranking'), findsNothing);
    });

    testWidgets('si el servidor rechaza el alias, el diálogo enseña su mensaje y sigue abierto', (tester) async {
      pantallaDeMovil(tester);
      await _iniciarSesion();

      final servicio = JuegoServiceFalso(perfilInicial: _perfil(alias: 'Ana'))
        ..errorAlActualizar = errorHttp(409, 'Ese alias ya está en uso', codigoJuego: 'ALIAS_EN_USO');

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('accion-aviso')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('campo-alias')), 'Beto');
      await tester.tap(find.byKey(const ValueKey('guardar-alias')));
      await tester.pumpAndSettle();

      expect(find.text('Ese alias ya está en uso'), findsOneWidget);
      expect(find.byKey(const ValueKey('campo-alias')), findsOneWidget);

      servicio.errorAlActualizar = errorHttp(400, 'Ese alias no está permitido, elige otro');

      await tester.tap(find.byKey(const ValueKey('guardar-alias')));
      await tester.pumpAndSettle();

      expect(find.text('Ese alias no está permitido, elige otro'), findsOneWidget);
    });

    testWidgets('una cuenta sin permiso para el juego (403) se trata como sin sesión', (tester) async {
      pantallaDeMovil(tester);
      await _iniciarSesion();

      final servicio = JuegoServiceFalso()
        ..errorDePerfil = errorHttp(403, 'No tienes permiso');

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(
        find.text('Inicia sesión en el Área Club para guardar tus puntuaciones'),
        findsOneWidget,
      );
    });

    testWidgets('si falla la carga del perfil, avisa y deja reintentar', (tester) async {
      pantallaDeMovil(tester);
      await _iniciarSesion();

      final servicio = JuegoServiceFalso()
        ..errorDePerfil = const ApiException('No hay conexión a internet.');

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(find.text('No se ha podido cargar tu perfil del juego'), findsOneWidget);

      servicio.errorDePerfil = null;
      servicio.perfilActual = _perfil(alias: 'Ana');

      await tester.tap(find.byKey(const ValueKey('accion-aviso')));
      await tester.pumpAndSettle();

      expect(find.text('Tu alias: Ana'), findsOneWidget);
    });

    testWidgets('al cerrar sesión desaparecen el perfil y los récords', (tester) async {
      pantallaDeMovil(tester);
      await _iniciarSesion();

      final servicio = JuegoServiceFalso(
        perfilInicial: _perfil(alias: 'Ana', atrapa: 5),
      );

      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: servicio)));
      await tester.pumpAndSettle();

      expect(find.text('Tu récord: 5'), findsOneWidget);

      AuthManager.olvidarUsuario();
      AuthManager.cambios.value++;
      await tester.pumpAndSettle();

      expect(find.text('Tu récord: 5'), findsNothing);
      expect(
        find.text('Inicia sesión en el Área Club para guardar tus puntuaciones'),
        findsOneWidget,
      );
    });
  });

  group('navegación', () {
    testWidgets('una tarjeta abre su partida y el botón Ranking, el ranking', (tester) async {
      pantallaDeMovil(tester);
      await tester.pumpWidget(appDePrueba(MutxigolPage(servicio: JuegoServiceFalso())));
      await tester.pump();

      await tester.ensureVisible(find.byKey(const ValueKey('boton-ranking')));
      await tester.tap(find.byKey(const ValueKey('boton-ranking')));
      await tester.pumpAndSettle();

      expect(find.byType(RankingJuegoPage), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tarjeta-CABEZAZOS')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PartidaJuegoPage), findsOneWidget);

      // Al salir de la pantalla el juego se para (el Ticker se libera sin errores).
      await tester.tap(find.byKey(const ValueKey('salir')));
      await tester.pumpAndSettle();

      expect(find.byType(PartidaJuegoPage), findsNothing);
    });
  });
}
