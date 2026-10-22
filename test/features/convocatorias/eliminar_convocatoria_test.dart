import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/core/utils/como_llegar.dart';
import 'package:app_mutxamel_cf/features/auth/models/perfil_app.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/pages/convocatoria_detalle_page.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _FakeConvocatoriaService extends ConvocatoriaService {
  final List<int> eliminadas = [];
  Object? error;

  @override
  Future<void> eliminar(int convocatoriaId) async {
    if (error != null) {
      throw error!;
    }

    eliminadas.add(convocatoriaId);
  }
}

final _convocatoria = ConvocatoriaModel(
  id: 20,
  equipoId: 5,
  equipo: 'Cadete A',
  partidoId: 30,
  rival: 'Pego C.F.',
  campo: 'Campo Municipal',
  fechaPartido: '2026-10-24',
  horaPartido: '11:00',
  horaConvocatoria: '09:30',
  lugarConvocatoria: 'Vestuarios',
  usuarioEntrenadorId: 1,
  jugadores: [ConvocatoriaJugadorModel(jugadorId: 100, jugador: 'Pablo Garcia')],
);

/// Una pantalla de atrás que abre el detalle, para ver qué devuelve al cerrarse.
Future<bool?> Function() _abrir(
  WidgetTester tester,
  _FakeConvocatoriaService servicio,
) {
  bool? resultado;
  var cerrado = false;

  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  return () async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                const Text('lista'),
                TextButton(
                  onPressed: () async {
                    resultado = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConvocatoriaDetallePage(
                          equipo: PerfilEquipo(id: 5, nombre: 'Cadete A'),
                          convocatoria: _convocatoria,
                          service: servicio,
                        ),
                      ),
                    );
                    cerrado = true;
                  },
                  child: const Text('abrir'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    return cerrado ? resultado : null;
  };
}

void main() {
  setUpAll(() async => initializeDateFormatting('es'));

  final boton = find.byKey(const ValueKey('eliminar-convocatoria'));

  testWidgets('el detalle tiene el botón rojo "Eliminar convocatoria"', (
    tester,
  ) async {
    await _abrir(tester, _FakeConvocatoriaService())();

    expect(boton, findsOneWidget);
    expect(find.text('Eliminar convocatoria'), findsOneWidget);

    final estilo = tester.widget<OutlinedButton>(boton).style!;

    expect(estilo.foregroundColor!.resolve({}), Colors.redAccent);
  });

  testWidgets('pide confirmación avisando de que se avisará a los convocados', (
    tester,
  ) async {
    final servicio = _FakeConvocatoriaService();

    await _abrir(tester, servicio)();

    await tester.tap(boton);
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar la convocatoria?'), findsOneWidget);
    expect(find.text('Se avisará a los convocados.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(servicio.eliminadas, isEmpty);
    expect(find.text('lista'), findsNothing);
    expect(find.byType(ConvocatoriaDetallePage), findsOneWidget);
  });

  testWidgets('al confirmar la elimina y vuelve a la lista', (tester) async {
    final servicio = _FakeConvocatoriaService();

    await _abrir(tester, servicio)();

    await tester.tap(boton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(servicio.eliminadas, [20]);
    expect(find.byType(ConvocatoriaDetallePage), findsNothing);
    expect(find.text('lista'), findsOneWidget);
    expect(find.text('Convocatoria eliminada.'), findsOneWidget);
  });

  testWidgets('si el backend responde 400 se muestra su motivo y se queda', (
    tester,
  ) async {
    final servicio = _FakeConvocatoriaService()
      ..error = const ApiException(
        'No se puede eliminar la convocatoria: el partido ya tiene resultado',
        statusCode: 400,
      );

    await _abrir(tester, servicio)();

    await tester.tap(boton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No se puede eliminar la convocatoria: el partido ya tiene resultado',
      ),
      findsOneWidget,
    );
    expect(find.byType(ConvocatoriaDetallePage), findsOneWidget);
  });

  testWidgets('otro fallo da un mensaje genérico', (tester) async {
    final servicio = _FakeConvocatoriaService()
      ..error = const ApiException('boom', statusCode: 500);

    await _abrir(tester, servicio)();

    await tester.tap(boton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se ha podido eliminar la convocatoria.'),
      findsOneWidget,
    );
    expect(find.text('boom'), findsNothing);
  });

  testWidgets('el campo y el lugar de citación tienen "Cómo llegar"', (
    tester,
  ) async {
    final abiertas = <Uri>[];
    ComoLlegar.esIos = () => false;
    ComoLlegar.abrirUrl = (url) async {
      abiertas.add(url);
      return true;
    };

    await _abrir(tester, _FakeConvocatoriaService())();

    expect(find.byIcon(Icons.directions), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.directions).first);
    await tester.pump();

    expect(abiertas.single.queryParameters['query'],
        'Campo Municipal, Alicante');
  });
}
