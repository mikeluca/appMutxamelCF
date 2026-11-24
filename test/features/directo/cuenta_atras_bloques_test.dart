import 'dart:async';

import 'package:app_mutxamel_cf/features/directo/models/cuenta_atras.dart';
import 'package:app_mutxamel_cf/features/directo/widgets/cuenta_atras_bloques.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness.dart';

/// El partido es el 14-11-2026 a las 18:00 de Madrid = 17:00 UTC.
final DateTime _inicio = DateTime.utc(2026, 11, 14, 17);

class _Falso implements Timer {
  final Duration intervalo;
  final void Function(Timer) alTic;
  bool cancelado = false;

  _Falso(this.intervalo, this.alTic);

  void tic() => alTic(this);

  @override
  void cancel() => cancelado = true;

  @override
  bool get isActive => !cancelado;

  @override
  int get tick => 0;
}

void main() {
  DateTime ahora = DateTime.utc(2026, 11, 12, 12);
  final temporizadores = <_Falso>[];

  Widget cuenta({
    String? hora = '18:00',
    Locale locale = const Locale('es'),
    GlobalKey<NavigatorState>? navegador,
  }) => appCon(
    Padding(
      padding: const EdgeInsets.all(16),
      child: CuentaAtrasBloques(
        dia: DateTime(2026, 11, 14),
        hora: hora,
        ahora: () => ahora,
        crearTemporizador: (intervalo, alTic) {
          final t = _Falso(intervalo, alTic);
          temporizadores.add(t);
          return t;
        },
      ),
    ),
    locale: locale,
    navegador: navegador,
  );

  String numero(WidgetTester tester, String bloque) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(ValueKey('bloque-$bloque')),
          matching: find.byKey(const ValueKey('bloque-numero')),
        ),
      )
      .data!;

  setUp(temporizadores.clear);

  group('CuentaAtras con segundos', () {
    test('con días: días, horas, minutos y segundos', () {
      final c = CuentaAtras.calcular(
        _inicio,
        _inicio.subtract(
          const Duration(days: 2, hours: 4, minutes: 7, seconds: 9),
        ),
      );

      expect(c.fase, FaseCuentaAtras.dias);
      expect((c.dias, c.horas, c.minutos, c.segundos), (2, 4, 7, 9));
    });

    test('con menos de 24 h: horas, minutos y segundos', () {
      final c = CuentaAtras.calcular(
        _inicio,
        _inicio.subtract(const Duration(hours: 3, minutes: 15, seconds: 40)),
      );

      expect(c.fase, FaseCuentaAtras.horas);
      expect((c.horas, c.minutos, c.segundos), (3, 15, 40));
    });

    test('en "Calentando" y "A punto de empezar" no hay números', () {
      expect(
        CuentaAtras.calcular(
          _inicio,
          _inicio.subtract(const Duration(minutes: 20)),
        ).conNumeros,
        isFalse,
      );
      expect(
        CuentaAtras.calcular(
          _inicio,
          _inicio.add(const Duration(minutes: 5)),
        ).conNumeros,
        isFalse,
      );
    });
  });

  group('CuentaAtrasBloques', () {
    testWidgets('con días: cuatro bloques con su etiqueta', (tester) async {
      pantalla(tester);
      ahora = DateTime.utc(
        2026,
        11,
        12,
        12,
        52,
        51,
      ); // faltan 2 d 4 h 7 min 9 s

      await tester.pumpWidget(cuenta());

      expect(numero(tester, 'dias'), '2');
      expect(numero(tester, 'horas'), '04');
      expect(numero(tester, 'minutos'), '07');
      expect(numero(tester, 'segundos'), '09');
      expect(find.text('Días'), findsOneWidget);
      expect(find.text('Horas'), findsOneWidget);
      expect(find.text('Minutos'), findsOneWidget);
      expect(find.text('Segundos'), findsOneWidget);
    });

    testWidgets('con menos de 24 horas se oculta Días y quedan tres', (
      tester,
    ) async {
      pantalla(tester);
      ahora = DateTime.utc(2026, 11, 14, 13, 44, 20); // faltan 3 h 15 min 40 s

      await tester.pumpWidget(cuenta());

      expect(find.byKey(const ValueKey('bloque-dias')), findsNothing);
      expect(find.text('Días'), findsNothing);
      expect(numero(tester, 'horas'), '03');
      expect(numero(tester, 'minutos'), '15');
      expect(numero(tester, 'segundos'), '40');
    });

    testWidgets('los segundos bajan cada segundo al avanzar el reloj', (
      tester,
    ) async {
      pantalla(tester);
      ahora = DateTime.utc(2026, 11, 14, 13, 45); // faltan 3 h 15 min 0 s

      await tester.pumpWidget(cuenta());

      // Un solo temporizador, de un segundo.
      expect(temporizadores, hasLength(1));
      expect(temporizadores.single.intervalo, const Duration(seconds: 1));
      expect(
        (
          numero(tester, 'horas'),
          numero(tester, 'minutos'),
          numero(tester, 'segundos'),
        ),
        ('03', '15', '00'),
      );

      ahora = ahora.add(const Duration(seconds: 1));
      temporizadores.single.tic();
      await tester.pump();
      expect(
        (
          numero(tester, 'horas'),
          numero(tester, 'minutos'),
          numero(tester, 'segundos'),
        ),
        ('03', '14', '59'),
      );

      ahora = ahora.add(const Duration(seconds: 59));
      temporizadores.single.tic();
      await tester.pump();
      expect(
        (
          numero(tester, 'horas'),
          numero(tester, 'minutos'),
          numero(tester, 'segundos'),
        ),
        ('03', '14', '00'),
      );
    });

    testWidgets(
      'a 30 minutos pasa a "Calentando…" y luego a "A punto de empezar"',
      (tester) async {
        pantalla(tester);
        ahora = DateTime.utc(2026, 11, 14, 16, 29, 59); // faltan 30 min 1 s

        await tester.pumpWidget(cuenta());
        expect(
          find.byKey(const ValueKey('cuenta-atras-bloques')),
          findsOneWidget,
        );
        expect(numero(tester, 'minutos'), '30');
        expect(numero(tester, 'segundos'), '01');

        ahora = DateTime.utc(2026, 11, 14, 16, 30); // faltan 30 min justos
        temporizadores.single.tic();
        await tester.pump();
        expect(
          find.byKey(const ValueKey('cuenta-atras-bloques')),
          findsNothing,
        );
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('cuenta-atras'))).data,
          'Calentando…',
        );
        expect(temporizadores.single.cancelado, isFalse);

        ahora = DateTime.utc(2026, 11, 14, 17, 1); // pasada la hora sin empezar
        temporizadores.single.tic();
        await tester.pump();
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('cuenta-atras'))).data,
          'A punto de empezar',
        );
        // Nunca números negativos y el temporizador se para.
        expect(find.textContaining('-'), findsNothing);
        expect(temporizadores.single.cancelado, isTrue);
      },
    );

    testWidgets('sin hora no pinta nada', (tester) async {
      pantalla(tester);

      await tester.pumpWidget(cuenta(hora: null));

      expect(find.byKey(const ValueKey('cuenta-atras')), findsNothing);
      expect(temporizadores, isEmpty);
    });

    testWidgets('etiquetas en catalán y en inglés', (tester) async {
      pantalla(tester);
      ahora = DateTime.utc(2026, 11, 12, 12);

      await tester.pumpWidget(cuenta(locale: const Locale('ca')));
      expect(find.text('Dies'), findsOneWidget);
      expect(find.text('Segons'), findsOneWidget);

      await tester.pumpWidget(cuenta(locale: const Locale('en')));
      expect(find.text('Days'), findsOneWidget);
      expect(find.text('Seconds'), findsOneWidget);
    });

    testWidgets(
      'el temporizador se para en segundo plano, con otra pantalla encima y al salir, y se recalcula al volver',
      (tester) async {
        pantalla(tester);
        ahora = DateTime.utc(2026, 11, 14, 13, 45);
        final navegador = GlobalKey<NavigatorState>();

        await tester.pumpWidget(cuenta(navegador: navegador));
        expect(temporizadores.last.cancelado, isFalse);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        expect(temporizadores.last.cancelado, isTrue);

        // Al volver se recalcula con la hora de ahora, sin error acumulado.
        ahora = DateTime.utc(2026, 11, 14, 14, 45);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(temporizadores, hasLength(2));
        expect(temporizadores.last.cancelado, isFalse);
        expect(numero(tester, 'horas'), '02');
        expect(numero(tester, 'minutos'), '15');

        await tester.pumpWidget(const SizedBox());
        expect(temporizadores.last.cancelado, isTrue);
      },
    );

    testWidgets(
      'en un iPhone pequeño con letra grande no se corta ni desborda',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        ahora = DateTime.utc(2026, 11, 12, 12); // con días: cuatro bloques

        await tester.pumpWidget(cuenta());

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('bloque-segundos')), findsOneWidget);
      },
    );

    testWidgets('en modo oscuro se ve', (tester) async {
      pantalla(tester);
      ahora = DateTime.utc(2026, 11, 12, 12);

      await tester.pumpWidget(
        appCon(
          Theme(
            data: ThemeData.dark(),
            child: CuentaAtrasBloques(
              dia: DateTime(2026, 11, 14),
              hora: '18:00',
              ahora: () => ahora,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('cuenta-atras-bloques')),
        findsOneWidget,
      );
    });

    testWidgets('es un dato secundario: la fila no pasa de 230 dp (menos con 3 bloques) y va centrada', (
      tester,
    ) async {
      pantalla(tester); // 400 dp de ancho

      ahora = DateTime.utc(2026, 11, 12, 12); // con días: cuatro bloques

      await tester.pumpWidget(cuenta());

      final fila = find.byKey(const ValueKey('cuenta-atras-bloques'));

      expect(tester.getSize(fila).width, lessThanOrEqualTo(230));
      expect(tester.getSize(fila).width, closeTo(230, 0.5));
      expect(tester.getCenter(fila).dx, closeTo(200, 0.5));

      ahora = DateTime.utc(2026, 11, 14, 13, 44, 20); // menos de 24 h: tres bloques

      await tester.pumpWidget(cuenta());
      await tester.pump();

      expect(tester.getSize(fila).width, lessThanOrEqualTo(230 * 3 / 4 + 0.5));
      expect(tester.getCenter(fila).dx, closeTo(200, 0.5));
    });

    testWidgets('números de 18 sp en negrita y etiquetas de 10 sp debajo', (
      tester,
    ) async {
      pantalla(tester);

      ahora = DateTime.utc(2026, 11, 12, 12);

      await tester.pumpWidget(cuenta());

      final numeroTexto = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('bloque-horas')),
          matching: find.byKey(const ValueKey('bloque-numero')),
        ),
      );
      final etiqueta = tester.widget<Text>(find.text('Horas'));

      expect(numeroTexto.style!.fontSize, 18);
      expect(numeroTexto.style!.fontWeight, FontWeight.bold);
      expect(etiqueta.style!.fontSize, 10);
      // La etiqueta va debajo del número.
      expect(
        tester.getTopLeft(find.text('Horas')).dy,
        greaterThanOrEqualTo(
          tester
              .getBottomLeft(
                find.descendant(
                  of: find.byKey(const ValueKey('bloque-horas')),
                  matching: find.byKey(const ValueKey('bloque-numero')),
                ),
              )
              .dy,
        ),
      );

      // Bajo: el bloque entero (número y etiqueta) mide poco (antes, unos 68 dp).
      expect(
        tester.getSize(find.byKey(const ValueKey('bloque-horas'))).height,
        lessThan(56),
      );
    });

    testWidgets('con letra a 1,6 y 320 dp de ancho caben los 4 bloques en una fila, sin cortarse', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      ahora = DateTime.utc(2026, 11, 12, 12);

      await tester.pumpWidget(
        appCon(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CuentaAtrasBloques(
                  dia: DateTime(2026, 11, 14),
                  hora: '18:00',
                  ahora: () => ahora,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final fila = find.byKey(const ValueKey('cuenta-atras-bloques'));
      final ancho = tester.getSize(fila).width;

      expect(ancho, lessThanOrEqualTo(230));

      // Los cuatro bloques en una sola fila (misma posición vertical) y dentro de la fila.
      final tops = [
        for (final b in ['dias', 'horas', 'minutos', 'segundos'])
          tester.getTopLeft(find.byKey(ValueKey('bloque-$b'))).dy,
      ];

      expect(tops.toSet(), hasLength(1));

      final rectFila = tester.getRect(fila);

      for (final etiqueta in ['Días', 'Horas', 'Minutos', 'Segundos']) {
        final rect = tester.getRect(find.text(etiqueta));

        expect(rect.left, greaterThanOrEqualTo(rectFila.left - 0.5), reason: etiqueta);
        expect(rect.right, lessThanOrEqualTo(rectFila.right + 0.5), reason: etiqueta);
      }

      for (final bloque in ['dias', 'horas', 'minutos', 'segundos']) {
        final rect = tester.getRect(
          find.descendant(
            of: find.byKey(ValueKey('bloque-$bloque')),
            matching: find.byKey(const ValueKey('bloque-numero')),
          ),
        );

        expect(rect.right, lessThanOrEqualTo(rectFila.right + 0.5), reason: bloque);
      }
    });
  });
}
