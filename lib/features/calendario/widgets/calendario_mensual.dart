import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Vista visual del calendario (mes o semana, con marcadores por día
/// que tiene eventos) + agenda del día seleccionado debajo. Reutilizada
/// tanto por la vista de jugador/familiar (calendario único combinando
/// varios equipos) como por la de gestión del entrenador/coordinador
/// (un único equipo): es genérica sobre el tipo de elemento [T] para
/// que cada pantalla pueda decorar sus eventos con el contexto que
/// necesite (equipo, jugador...) sin acoplar este widget a un modelo
/// concreto. [fechaDe] indica cómo obtener la fecha de cada elemento y
/// [itemBuilder] cómo pintarlo.
class CalendarioMensual<T> extends StatefulWidget {
  final List<T> items;
  final DateTime Function(T item) fechaDe;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String textoSinEventosDia;
  final String locale;
  final DateTime? primerDia;
  final DateTime? ultimoDia;

  const CalendarioMensual({
    super.key,
    required this.items,
    required this.fechaDe,
    required this.itemBuilder,
    required this.textoSinEventosDia,
    required this.locale,
    this.primerDia,
    this.ultimoDia,
  });

  @override
  State<CalendarioMensual<T>> createState() => _CalendarioMensualState<T>();
}

class _CalendarioMensualState<T> extends State<CalendarioMensual<T>> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _formato = CalendarFormat.month;

  @override
  void initState() {
    super.initState();

    final hoy = DateTime.now();
    _focusedDay = _soloFecha(hoy);
    _selectedDay = _focusedDay;
  }

  DateTime _soloFecha(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);

  List<T> _eventosDelDia(DateTime dia) {
    final clave = _soloFecha(dia);

    return widget.items
        .where((item) => _soloFecha(widget.fechaDe(item)) == clave)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final eventosDelDiaSeleccionado = _eventosDelDia(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: colors.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TableCalendar<T>(
              locale: widget.locale,
              firstDay:
                  widget.primerDia ??
                  DateTime.now().subtract(const Duration(days: 365)),
              lastDay:
                  widget.ultimoDia ??
                  DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              currentDay: _soloFecha(DateTime.now()),
              selectedDayPredicate: (dia) => _soloFecha(dia) == _selectedDay,
              calendarFormat: _formato,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Mes',
                CalendarFormat.week: 'Semana',
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              eventLoader: _eventosDelDia,
              onFormatChanged: (formato) {
                setState(() => _formato = formato);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = _soloFecha(selectedDay);
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: HeaderStyle(
                formatButtonShowsNext: false,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: TextStyle(color: colors.onSurface),
                titleTextStyle: TextStyle(
                  color: colors.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: colors.onSurface,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: colors.onSurface,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: colors.onSurfaceVariant),
                weekendStyle: TextStyle(color: colors.onSurfaceVariant),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(color: colors.onSurface),
                weekendTextStyle: TextStyle(color: colors.onSurface),
                todayDecoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(color: colors.onPrimaryContainer),
                selectedDecoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(color: colors.onPrimary),
                markerDecoration: BoxDecoration(
                  color: colors.secondary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (eventosDelDiaSeleccionado.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            color: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.event_busy, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.textoSinEventosDia,
                      style: TextStyle(color: colors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              for (final item in eventosDelDiaSeleccionado) ...[
                widget.itemBuilder(context, item),
                const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}
