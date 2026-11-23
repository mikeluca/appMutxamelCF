import '../../l10n/gen/app_localizations.dart';

/// Formato único para mostrar la fecha de un partido o un entrenamiento
/// a un usuario en cualquier pantalla de la app: "NombreDía, DD/MM/AAAA",
/// en el idioma activo (es/ca/en).
String formatearFechaConDiaSemana(DateTime fecha, AppLocalizations t) {
  final diasSemana = [
    t.weekdayMonday,
    t.weekdayTuesday,
    t.weekdayWednesday,
    t.weekdayThursday,
    t.weekdayFriday,
    t.weekdaySaturday,
    t.weekdaySunday,
  ];

  final diaSemana = diasSemana[fecha.weekday - 1];
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final anio = fecha.year.toString();

  return '$diaSemana, $dia/$mes/$anio';
}

/// Fecha y hora de un partido en una sola línea: "Domingo 22/11/2026 · 17:30" (sin la hora si no la hay, y sin el día si
/// no hay fecha). Es la línea de las tarjetas de Inicio y de la pestaña Partidos.
String formatearFechaHoraEnUnaLinea(
  DateTime? fecha,
  String? hora,
  AppLocalizations t, {
  String? respaldoFecha,
}) {
  final partes = <String>[];

  if (fecha != null) {
    partes.add(formatearFechaConDiaSemana(fecha, t).replaceFirst(', ', ' '));
  } else if (respaldoFecha != null && respaldoFecha.isNotEmpty) {
    partes.add(respaldoFecha);
  }

  if (hora != null && hora.trim().isNotEmpty) {
    partes.add(hora.trim());
  }

  return partes.join(' · ');
}
