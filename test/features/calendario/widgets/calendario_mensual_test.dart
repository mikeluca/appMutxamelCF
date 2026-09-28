import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:app_mutxamel_cf/features/calendario/model/calendario_model.dart';
import 'package:app_mutxamel_cf/features/calendario/model/sesion_entrenamiento_model.dart';
import 'package:app_mutxamel_cf/features/calendario/widgets/calendario_mensual.dart';

void main() {
  // En la app real esto lo hace main() antes de runApp(); aquí no se
  // pasa por main(), así que hay que inicializarlo a mano o
  // TableCalendar lanza LocaleDataException al pintar el mes/día.
  setUpAll(() async {
    await initializeDateFormatting();
  });

  final hoy = DateTime.now();
  final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);
  final manana = hoySoloFecha.add(const Duration(days: 1));

  SesionEntrenamientoModel sesionEn(DateTime fecha) => SesionEntrenamientoModel(
    id: 1,
    equipoId: 1,
    equipo: 'Alevín A',
    fecha: fecha,
    hora: '18:00',
    lugar: 'Campo Municipal',
    estado: 'PROGRAMADA',
  );

  Future<void> pumpCalendario(
    WidgetTester tester,
    List<ItemCalendario> items,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CalendarioMensual(
              items: items,
              textoSinEventosDia: 'No hay entrenamientos ni partidos programados.',
              locale: 'es',
              itemBuilder: (context, item) => ListTile(
                key: ValueKey('item-${item.sesion?.id}-${item.fecha}'),
                title: Text(item.esEntrenamiento ? 'Entrenamiento' : 'Partido'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('pinta el calendario y la agenda del día de hoy por defecto', (
    tester,
  ) async {
    await pumpCalendario(tester, [
      ItemCalendario.deSesion(sesionEn(hoySoloFecha)),
    ]);

    expect(find.byType(TableCalendar<ItemCalendario>), findsOneWidget);
    expect(find.text('Entrenamiento'), findsOneWidget);
  });

  testWidgets(
    'muestra el mensaje de "sin eventos" cuando el día seleccionado no tiene nada',
    (tester) async {
      await pumpCalendario(tester, [
        ItemCalendario.deSesion(sesionEn(manana)),
      ]);

      // Hoy (día seleccionado por defecto) no tiene eventos: el de
      // mañana no debe aparecer en la agenda inicial.
      expect(find.text('Entrenamiento'), findsNothing);
      expect(
        find.text('No hay entrenamientos ni partidos programados.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('al tocar un día con eventos, la agenda se actualiza', (
    tester,
  ) async {
    await pumpCalendario(tester, [
      ItemCalendario.deSesion(sesionEn(manana)),
    ]);

    expect(find.text('Entrenamiento'), findsNothing);

    await tester.tap(find.text('${manana.day}').first);
    await tester.pumpAndSettle();

    expect(find.text('Entrenamiento'), findsOneWidget);
  });
}
