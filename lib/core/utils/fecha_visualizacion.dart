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
