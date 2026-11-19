import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/models/imagenes_redes_model.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/models/partido_primer_equipo_model.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/pages/imagenes_redes_page.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/utils/fin_de_semana_imagenes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/imagenes_redes_soporte.dart';

// Miércoles 18/11/2026
final DateTime _miercoles = DateTime(2026, 11, 18, 10);

Widget _pagina(
  ServicioImagenesFalso servicio, {
  String? tipoInicial,
  DateTime? desde,
  DateTime? hoy,
  String idioma = 'es',
}) {
  return appDePrueba(
    ImagenesRedesPage(
      servicio: servicio,
      tipoInicial: tipoInicial,
      desde: desde,
      ahora: () => hoy ?? _miercoles,
    ),
    idioma: idioma,
  );
}

/// Abre la pantalla desde otra (para poder comprobar que vuelve atrás).
Widget _desdeMenu(ServicioImagenesFalso servicio) {
  return appDePrueba(
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImagenesRedesPage(
                  servicio: servicio,
                  ahora: () => _miercoles,
                ),
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
}

String _fecha(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('selector-fecha'))).data!;

void main() {
  group('fin de semana por defecto', () {
    DateTime d(int dia) => DateTime(2026, 11, dia);

    test('Previa: el que viene; de viernes a domingo, el actual', () {
      expect(viernesPorDefectoPrevia(d(16)), d(20)); // lunes
      expect(viernesPorDefectoPrevia(d(18)), d(20)); // miércoles
      expect(viernesPorDefectoPrevia(d(19)), d(20)); // jueves
      expect(viernesPorDefectoPrevia(d(20)), d(20)); // viernes
      expect(viernesPorDefectoPrevia(d(21)), d(20)); // sábado
      expect(viernesPorDefectoPrevia(d(22)), d(20)); // domingo
      expect(viernesPorDefectoPrevia(d(23)), d(27)); // lunes siguiente
    });

    test('Resultados: el último que ha terminado', () {
      expect(viernesPorDefectoResultados(d(16)), d(13)); // lunes
      expect(viernesPorDefectoResultados(d(19)), d(13)); // jueves
      expect(
        viernesPorDefectoResultados(d(20)),
        d(13),
      ); // viernes: aún no ha terminado
      expect(viernesPorDefectoResultados(d(22)), d(13)); // domingo
      expect(viernesPorDefectoResultados(d(23)), d(20)); // lunes siguiente
    });

    test('un fin de semana ha terminado después de su domingo', () {
      expect(finDeSemanaTerminado(d(13), d(15)), isFalse);
      expect(finDeSemanaTerminado(d(13), d(16)), isTrue);
      expect(finDeSemanaTerminado(d(20), d(18)), isFalse);
    });

    test('desplazar por semanas cruza el cambio de hora sin desfasarse', () {
      // El cambio de hora de octubre de 2026 es el domingo 25.
      expect(
        desplazarSemanas(DateTime(2026, 10, 23), 1),
        DateTime(2026, 10, 30),
      );
      expect(
        desplazarSemanas(DateTime(2026, 10, 30), -1),
        DateTime(2026, 10, 23),
      );
    });
  });

  group('pestañas', () {
    testWidgets(
      'las cuatro pestañas: Previa, Resultados, Primer Equipo y Filial',
      (tester) async {
        await tester.pumpWidget(_pagina(ServicioImagenesFalso()));
        await tester.pumpAndSettle();

        expect(find.text('Imágenes para redes'), findsOneWidget);
        expect(find.byKey(const ValueKey('pestana-previa')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('pestana-resultados')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('pestana-primer-equipo')),
          findsOneWidget,
        );
        expect(find.text('Previa'), findsOneWidget);
        expect(find.text('Resultados'), findsOneWidget);
        expect(find.text('Partido Primer Equipo'), findsOneWidget);
        expect(find.byKey(const ValueKey('pestana-filial')), findsOneWidget);
        expect(find.text('Partido Filial'), findsOneWidget);
        expect(find.byType(Tab), findsNWidgets(4));
      },
    );

    testWidgets('abre en Previa por defecto y se pasa de pestaña', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso();

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('generar-PREVIA')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('pestana-resultados')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('generar-RESULTADOS')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('pestana-primer-equipo')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('cartel-tarjeta-partido')),
        findsOneWidget,
      );
    });

    testWidgets('con el tipo del aviso abre esa pestaña', (tester) async {
      await tester.pumpWidget(
        _pagina(ServicioImagenesFalso(), tipoInicial: tipoImagenResultados),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('generar-RESULTADOS')), findsOneWidget);
      expect(find.byKey(const ValueKey('generar-PREVIA')), findsNothing);

      await tester.pumpWidget(
        _pagina(
          ServicioImagenesFalso(),
          tipoInicial: tipoImagenPartidoPrimerEquipo,
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('sin tipo (aviso antiguo de la bandeja) abre Resultados si el '
        'fin de semana ya terminó y Previa si no', (tester) async {
      await tester.pumpWidget(
        _pagina(ServicioImagenesFalso(), desde: DateTime(2026, 11, 13)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('generar-RESULTADOS')), findsOneWidget);

      await tester.pumpWidget(
        _pagina(ServicioImagenesFalso(), desde: DateTime(2026, 11, 20)),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        _pagina(ServicioImagenesFalso(), desde: DateTime(2026, 11, 20)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('generar-PREVIA')), findsOneWidget);
    });

    testWidgets('las pestañas también salen en catalán y en inglés', (
      tester,
    ) async {
      await tester.pumpWidget(_pagina(ServicioImagenesFalso(), idioma: 'ca'));
      await tester.pumpAndSettle();

      expect(find.text('Imatges per a xarxes'), findsOneWidget);
      expect(find.text('Prèvia'), findsOneWidget);
      expect(find.text('Partit Primer Equip'), findsOneWidget);
      expect(find.text('Partit Filial'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_pagina(ServicioImagenesFalso(), idioma: 'en'));
      await tester.pumpAndSettle();

      expect(find.text('Social media images'), findsOneWidget);
      expect(find.text('First Team match'), findsOneWidget);
      expect(find.text('Reserve team match'), findsOneWidget);
    });
  });

  group('selector de fin de semana', () {
    testWidgets('Previa abre en el fin de semana que viene', (tester) async {
      final servicio = ServicioImagenesFalso();

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();

      expect(_fecha(tester), '20/11 - 22/11');
      expect(servicio.consultadas, [DateTime(2026, 11, 20)]);
    });

    testWidgets('Resultados abre en el último que ha terminado', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso();

      await tester.pumpWidget(
        _pagina(servicio, tipoInicial: tipoImagenResultados),
      );
      await tester.pumpAndSettle();

      expect(_fecha(tester), '13/11 - 15/11');
      expect(servicio.consultadas, [DateTime(2026, 11, 13)]);
    });

    testWidgets('de viernes a domingo Previa es el fin de semana actual', (
      tester,
    ) async {
      await tester.pumpWidget(
        _pagina(ServicioImagenesFalso(), hoy: DateTime(2026, 11, 21, 12)),
      );
      await tester.pumpAndSettle();

      expect(_fecha(tester), '20/11 - 22/11');
    });

    testWidgets('las flechas cambian de fin de semana y piden sus imágenes', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso();

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('selector-siguiente')));
      await tester.pumpAndSettle();

      expect(_fecha(tester), '27/11 - 29/11');

      await tester.tap(find.byKey(const ValueKey('selector-anterior')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('selector-anterior')));
      await tester.pumpAndSettle();

      expect(_fecha(tester), '13/11 - 15/11');
      expect(servicio.consultadas, [
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 27),
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 13),
      ]);
    });

    testWidgets('generar usa el fin de semana que se está viendo', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso();

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('selector-siguiente')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('generar-PREVIA')));
      await tester.pumpAndSettle();

      expect(servicio.regeneradas.single.fecha, DateTime(2026, 11, 27));
    });

    testWidgets('cada pestaña conserva su propio fin de semana', (
      tester,
    ) async {
      await tester.pumpWidget(_pagina(ServicioImagenesFalso()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('selector-siguiente')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('pestana-resultados')));
      await tester.pumpAndSettle();

      expect(_fecha(tester), '13/11 - 15/11');

      await tester.tap(find.byKey(const ValueKey('pestana-previa')));
      await tester.pumpAndSettle();

      expect(_fecha(tester), '27/11 - 29/11');
    });

    testWidgets('el aviso abre su pestaña en su fin de semana', (tester) async {
      final servicio = ServicioImagenesFalso();

      await tester.pumpWidget(
        _pagina(
          servicio,
          tipoInicial: tipoImagenPrevia,
          desde: DateTime(2026, 12, 4),
        ),
      );
      await tester.pumpAndSettle();

      expect(_fecha(tester), '04/12 - 06/12');
      expect(servicio.consultadas.single, DateTime(2026, 12, 4));
    });
  });

  group('403', () {
    testWidgets('un 403 en las imágenes avisa y vuelve al menú', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..falloObtener = const ApiException('No', statusCode: 403);

      await tester.pumpWidget(_desdeMenu(servicio));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(ImagenesRedesPage), findsNothing);
      expect(find.text('Abrir'), findsOneWidget);
      expect(
        find.text('Ya no tienes permiso para ver las imágenes para redes'),
        findsOneWidget,
      );
    });

    testWidgets('un 403 en el partido del Primer Equipo también', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..falloPartido = const ApiException('No', statusCode: 403);

      await tester.pumpWidget(_desdeMenu(servicio));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // El partido se pide al abrir la pantalla aunque no sea la pestaña visible.
      await tester.pumpAndSettle();
      expect(find.byType(ImagenesRedesPage), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('pestana-primer-equipo')));
      await tester.pumpAndSettle();

      expect(find.byType(ImagenesRedesPage), findsNothing);
      expect(
        find.text('Ya no tienes permiso para ver las imágenes para redes'),
        findsOneWidget,
      );
    });
  });

  group('visual', () {
    testWidgets('en iPhone pequeño, con letra grande y en modo oscuro no '
        'desborda', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final servicio = ServicioImagenesFalso(
        actual: modeloDePrueba([
          imagenDePrueba(1, 'PREVIA', 'F11', 1, 2, version: 1),
          imagenDePrueba(2, 'PREVIA', 'F8', 1, 1),
        ], desde: DateTime(2026, 11, 20)),
      );

      // Letra grande del sistema.
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        appDePrueba(
          ImagenesRedesPage(servicio: servicio, ahora: () => _miercoles),
          tema: ThemeData.dark(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      for (final pestana in [
        'pestana-resultados',
        'pestana-primer-equipo',
        'pestana-filial',
      ]) {
        // Con letra grande las pestañas no caben: la barra se desliza.
        await tester.ensureVisible(find.byKey(ValueKey(pestana)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey(pestana)));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: pestana);
      }
    });
  });

  test('el modelo de apertura reconoce los tipos', () {
    expect(tipoImagenPrevia, 'PREVIA');
    expect(tipoImagenResultados, 'RESULTADOS');
    expect(tipoImagenPartidoPrimerEquipo, isNotEmpty);
  });
}
