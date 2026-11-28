import 'dart:ui' show Tristate;

import 'package:app_mutxamel_cf/features/auth/pages/login_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/funciones_app_service.dart';
import 'package:app_mutxamel_cf/features/familia/pages/registro_familia_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../familia/soporte_familia.dart';

const _boton = ValueKey('login-soy-familiar');
const _texto = ValueKey('login-soy-familiar-proximamente');

/// Lo que el servidor responde a GET /api/public/app/funciones en cada caso del test.
void _servidor(Future<Object?> Function() respuesta) {
  FuncionesApp.leerDelServidor = respuesta;
}

void main() {
  late Future<Object?> Function() original;

  setUp(() {
    prepararAlmacenamiento();
    original = FuncionesApp.leerDelServidor;
  });

  tearDown(() => FuncionesApp.leerDelServidor = original);

  Future<void> pintarLogin(WidgetTester tester, {String idioma = 'es'}) async {
    await pintarFamilia(
      tester,
      const LoginPage(),
      tamano: const Size(390, 900),
      idioma: idioma,
    );
    await tester.pumpAndSettle();
  }

  OutlinedButton boton(WidgetTester tester) =>
      tester.widget<OutlinedButton>(find.byKey(_boton));

  group('registro de familias deshabilitado', () {
    testWidgets('con false: botón deshabilitado y el texto debajo', (
      tester,
    ) async {
      _servidor(() async => {'registroFamiliasHabilitado': false});

      await pintarLogin(tester);

      expect(find.text('Soy familiar de un jugador'), findsOneWidget);
      expect(boton(tester).onPressed, isNull);
      expect(find.byKey(_texto), findsOneWidget);
      expect(
        find.text(
          'Próximamente. Mientras tanto, pide la invitación a tu entrenador o al club.',
        ),
        findsOneWidget,
      );

      // Tocarlo no abre el registro.
      await tester.ensureVisible(find.byKey(_boton));
      await tester.tap(find.byKey(_boton), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(RegistroFamiliaPage), findsNothing);
    });

    testWidgets('el texto va en los tres idiomas', (tester) async {
      _servidor(() async => {'registroFamiliasHabilitado': false});

      await pintarLogin(tester, idioma: 'ca');
      expect(
        find.text(
          'Pròximament. Mentrestant, demana la invitació al teu entrenador o al club.',
        ),
        findsOneWidget,
      );

      await pintarLogin(tester, idioma: 'en');
      expect(
        find.text(
          'Coming soon. In the meantime, ask your coach or the club for an invitation.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('con error de red: deshabilitado', (tester) async {
      _servidor(() async => throw Exception('sin red'));

      await pintarLogin(tester);

      expect(boton(tester).onPressed, isNull);
      expect(find.byKey(_texto), findsOneWidget);
    });

    testWidgets('sin el campo en la respuesta: deshabilitado', (tester) async {
      _servidor(() async => <String, dynamic>{});

      await pintarLogin(tester);

      expect(boton(tester).onPressed, isNull);
      expect(find.byKey(_texto), findsOneWidget);
    });

    testWidgets('el lector de pantalla lo anuncia como no disponible', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      _servidor(() async => {'registroFamiliasHabilitado': false});

      await pintarLogin(tester);

      final nodo = tester.getSemantics(find.byKey(_boton));
      expect(nodo.flagsCollection.isButton, isTrue);
      // Con onPressed null el botón se anuncia como deshabilitado.
      expect(nodo.flagsCollection.isEnabled, Tristate.isFalse);
      expect(
        tester.getSemantics(find.byKey(_texto)).label,
        contains('Próximamente'),
      );

      semantica.dispose();
    });
  });

  group('registro de familias habilitado', () {
    testWidgets('con true: botón activo, sin texto, y abre el registro', (
      tester,
    ) async {
      _servidor(() async => {'registroFamiliasHabilitado': true});

      await pintarLogin(tester);

      expect(boton(tester).onPressed, isNotNull);
      expect(find.byKey(_texto), findsNothing);

      await tester.ensureVisible(find.byKey(_boton));
      await tester.tap(find.byKey(_boton));
      await tester.pumpAndSettle();

      expect(find.byType(RegistroFamiliaPage), findsOneWidget);
    });
  });
}
