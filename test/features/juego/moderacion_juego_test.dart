import 'package:app_mutxamel_cf/features/admin/models/admin_model.dart';
import 'package:app_mutxamel_cf/features/admin/pages/moderacion_page.dart';
import 'package:app_mutxamel_cf/features/admin/services/admin_service.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/widgets/juego_moderacion_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/juego_helpers.dart';

const _ana = PerfilJuegoAdmin(
  usuarioId: 7,
  alias: 'Mutxigol10',
  nombre: 'Ana Pérez',
  email: 'ana@example.com',
  partidas: 5,
  mejorAtrapa: 9,
  mejorRegatea: 12,
  mejorCabezazos: 40,
  mejorParejasMs: 83450,
);

const _oculto = PerfilJuegoAdmin(
  usuarioId: 8,
  alias: 'Escondido',
  oculto: true,
  nombre: 'Beto Gil',
  email: 'beto@example.com',
);

class _AdminVacio extends AdminService {
  @override
  Future<List<ReporteModel>> obtenerReportes({bool resueltos = false}) async =>
      const [];
}

Future<JuegoServiceFalso> _pintar(
  WidgetTester tester, {
  List<PerfilJuegoAdmin> perfiles = const [_ana, _oculto],
}) async {
  pantallaDeMovil(tester, alto: 1200);

  final servicio = JuegoServiceFalso()..perfilesAdmin = perfiles;

  await tester.pumpWidget(
    appDePrueba(
      Scaffold(body: JuegoModeracionView(servicio: servicio)),
    ),
  );
  await tester.pumpAndSettle();

  return servicio;
}

void main() {
  group('la lista', () {
    testWidgets('enseña alias, cuenta (nombre y email), mejores marcas y estado', (tester) async {
      await _pintar(tester);

      expect(find.text('Mutxigol10'), findsOneWidget);
      expect(find.text('Ana Pérez · ana@example.com'), findsOneWidget);
      expect(find.text('Atrapa 9 · Regatea 12 · Cabezazos 40 · Parejas 1:23,4'), findsOneWidget);
      expect(find.text('Escondido'), findsOneWidget);
      expect(find.byKey(const ValueKey('oculto-8')), findsOneWidget);
      expect(find.byKey(const ValueKey('oculto-7')), findsNothing);

      // Ocultar o mostrar, según el estado.
      expect(find.descendant(of: find.byKey(const ValueKey('ocultar-7')), matching: find.text('Ocultar del ranking')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('ocultar-8')), matching: find.text('Mostrar en el ranking')), findsOneWidget);
    });

    testWidgets('buscar por alias vuelve a pedir la lista con el filtro', (tester) async {
      final servicio = await _pintar(tester);

      expect(servicio.busquedas, [null]);

      await tester.enterText(find.byKey(const ValueKey('buscar-alias')), 'mutx');
      await tester.tap(find.byKey(const ValueKey('boton-buscar-alias')));
      await tester.pumpAndSettle();

      expect(servicio.busquedas.last, 'mutx');
    });

    testWidgets('sin perfiles: mensaje', (tester) async {
      await _pintar(tester, perfiles: const []);

      expect(find.text('No hay perfiles del juego'), findsOneWidget);
    });

    testWidgets('sin permiso (403) no se enseña nada de la moderación', (tester) async {
      pantallaDeMovil(tester);

      final servicio = JuegoServiceFalso()
        ..errorAdmin = errorHttp(403, 'Solo un administrador puede moderar el juego');

      await tester.pumpWidget(
        appDePrueba(Scaffold(body: JuegoModeracionView(servicio: servicio))),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('error-juego-moderacion')), findsOneWidget);
      expect(find.text('No tienes permiso'), findsOneWidget);
      expect(find.text('Mutxigol10'), findsNothing);
    });
  });

  group('acciones', () {
    testWidgets('cambiar el alias', (tester) async {
      final servicio = await _pintar(tester);

      await tester.tap(find.byKey(const ValueKey('cambiar-alias-7')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('campo-nuevo-alias')), 'Nuevo10');
      await tester.tap(find.byKey(const ValueKey('guardar-nuevo-alias')));
      await tester.pumpAndSettle();

      expect(servicio.accionesAdmin, ['alias 7 Nuevo10']);
      expect(find.text('Hecho'), findsOneWidget);
    });

    testWidgets('un alias que el servidor rechaza enseña su motivo y deja corregirlo', (tester) async {
      final servicio = await _pintar(tester)
        ..errorAlCambiarAlias = errorHttp(409, 'Ese alias ya está en uso');

      await tester.tap(find.byKey(const ValueKey('cambiar-alias-7')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('campo-nuevo-alias')), 'Beto');
      await tester.tap(find.byKey(const ValueKey('guardar-nuevo-alias')));
      await tester.pumpAndSettle();

      expect(find.text('Ese alias ya está en uso'), findsOneWidget);
      expect(servicio.accionesAdmin, isEmpty);

      servicio.errorAlCambiarAlias = null;

      await tester.enterText(find.byKey(const ValueKey('campo-nuevo-alias')), 'Otro');
      await tester.tap(find.byKey(const ValueKey('guardar-nuevo-alias')));
      await tester.pumpAndSettle();

      expect(servicio.accionesAdmin, ['alias 7 Otro']);
    });

    testWidgets('ocultar pide confirmación; cancelar no hace nada', (tester) async {
      final servicio = await _pintar(tester);

      await tester.tap(find.byKey(const ValueKey('ocultar-7')));
      await tester.pumpAndSettle();

      expect(find.text('¿Ocultar a Mutxigol10 del ranking?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.accionesAdmin, isEmpty);

      await tester.tap(find.byKey(const ValueKey('ocultar-7')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar-juego')));
      await tester.pumpAndSettle();

      expect(servicio.accionesAdmin, ['oculto 7 true']);
    });

    testWidgets('mostrar un perfil oculto', (tester) async {
      final servicio = await _pintar(tester);

      await tester.tap(find.byKey(const ValueKey('ocultar-8')));
      await tester.pumpAndSettle();

      expect(find.text('¿Mostrar a Escondido en el ranking?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirmar-juego')));
      await tester.pumpAndSettle();

      expect(servicio.accionesAdmin, ['oculto 8 false']);
    });

    testWidgets('borrar una puntuación, con confirmación', (tester) async {
      final servicio = await _pintar(tester)
        ..puntuacionesAdmin = [
          PuntuacionAdmin(
            id: 11,
            juego: Juego.cabezazos,
            puntos: 12,
            fecha: DateTime(2026, 11, 24),
          ),
          const PuntuacionAdmin(id: 12, juego: Juego.regatea, puntos: 40),
        ];

      await tester.tap(find.byKey(const ValueKey('puntuaciones-7')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('puntuacion-11')), findsOneWidget);
      expect(find.byKey(const ValueKey('puntuacion-12')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('borrar-puntuacion-11')));
      await tester.pumpAndSettle();

      expect(find.text('¿Borrar esta puntuación?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirmar-juego')));
      await tester.pumpAndSettle();

      expect(servicio.accionesAdmin, ['borrar 11']);
    });

    testWidgets('en las puntuaciones de Parejas se ve el tiempo y no los 8 puntos', (tester) async {
      final servicio = await _pintar(tester);

      servicio.puntuacionesAdmin = const [
          PuntuacionAdmin(id: 21, juego: Juego.parejas, puntos: 8, duracionMs: 41300),
          PuntuacionAdmin(id: 22, juego: Juego.atrapa, puntos: 15, duracionMs: 30000),
      ];

      await tester.tap(find.byKey(const ValueKey('puntuaciones-7')));
      await tester.pumpAndSettle();

      expect(find.text('Parejas · 0:41,3'), findsOneWidget);
      expect(find.text('Atrapa · 15'), findsOneWidget);
    });

    testWidgets('borrar todas las puntuaciones del perfil, con confirmación', (tester) async {
      final servicio = await _pintar(tester)
        ..puntuacionesAdmin = const [
          PuntuacionAdmin(id: 11, juego: Juego.cabezazos, puntos: 12),
        ];

      await tester.tap(find.byKey(const ValueKey('puntuaciones-7')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('borrar-todas')));
      await tester.pumpAndSettle();

      expect(
        find.text('Se borrarán todas las puntuaciones de Mutxigol10. ¿Seguro?'),
        findsOneWidget,
      );

      // Cancelar no borra.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.accionesAdmin, isEmpty);

      await tester.tap(find.byKey(const ValueKey('borrar-todas')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar-juego')));
      await tester.pumpAndSettle();

      expect(servicio.accionesAdmin, ['borrarTodas 7']);
    });

    testWidgets('si el servidor lo rechaza (403), se avisa de que no hay permiso', (tester) async {
      final servicio = await _pintar(tester);

      servicio.errorAdmin = errorHttp(403, 'Solo un administrador puede moderar el juego');

      await tester.tap(find.byKey(const ValueKey('ocultar-7')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar-juego')));
      await tester.pumpAndSettle();

      expect(find.text('No tienes permiso'), findsOneWidget);
      expect(servicio.accionesAdmin, isEmpty);
    });
  });

  testWidgets('en Moderación hay un apartado "Juego Mutxigol" con estas acciones', (tester) async {
    pantallaDeMovil(tester, alto: 1200);

    final servicio = JuegoServiceFalso()..perfilesAdmin = const [_ana];

    await tester.pumpWidget(
      appDePrueba(
        ModeracionPage(servicio: _AdminVacio(), servicioJuego: servicio),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Resueltos'), findsOneWidget);
    expect(find.text('Juego Mutxigol'), findsOneWidget);

    // Hasta que se abre el apartado no se pide nada del juego.
    expect(servicio.busquedas, isEmpty);

    await tester.tap(find.text('Juego Mutxigol'));
    await tester.pumpAndSettle();

    expect(find.text('Mutxigol10'), findsOneWidget);
    expect(find.byKey(const ValueKey('cambiar-alias-7')), findsOneWidget);
  });
}
