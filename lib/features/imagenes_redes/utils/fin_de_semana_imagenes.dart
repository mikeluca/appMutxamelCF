DateTime _soloDia(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);

/// El viernes más reciente (el de hoy si hoy es viernes), sin hora.
DateTime viernesReciente(DateTime hoy) {
  final dia = _soloDia(hoy);
  final atras = (dia.weekday - DateTime.friday + 7) % 7;

  return DateTime(dia.year, dia.month, dia.day - atras);
}

/// El fin de semana (su viernes) con el que abre la pestaña Previa: el que viene; de viernes a domingo, el actual.
DateTime viernesPorDefectoPrevia(DateTime hoy) {
  final reciente = viernesReciente(hoy);
  final enFinDeSemana = _soloDia(hoy).weekday >= DateTime.friday;

  return enFinDeSemana
      ? reciente
      : DateTime(reciente.year, reciente.month, reciente.day + 7);
}

/// El fin de semana (su viernes) con el que abre la pestaña Resultados: el último que ha terminado (de viernes a
/// domingo el actual aún no ha terminado, así que es el anterior).
DateTime viernesPorDefectoResultados(DateTime hoy) {
  final reciente = viernesReciente(hoy);
  final enFinDeSemana = _soloDia(hoy).weekday >= DateTime.friday;

  return enFinDeSemana
      ? DateTime(reciente.year, reciente.month, reciente.day - 7)
      : reciente;
}

/// true si el fin de semana que empieza ese viernes ya ha terminado (pasó su domingo).
bool finDeSemanaTerminado(DateTime viernes, DateTime hoy) {
  final domingo = DateTime(viernes.year, viernes.month, viernes.day + 2);

  return _soloDia(hoy).isAfter(domingo);
}

/// El viernes siguiente o anterior (por días de calendario: sumar 7 días no se desfasa al cambiar la hora).
DateTime desplazarSemanas(DateTime viernes, int semanas) =>
    DateTime(viernes.year, viernes.month, viernes.day + 7 * semanas);

/// dd/MM
String fechaCortaImagenes(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');

  return '$dia/$mes';
}

/// Suma [dias] días de calendario.
DateTime desplazarDias(DateTime fecha, int dias) =>
    DateTime(fecha.year, fecha.month, fecha.day + dias);
