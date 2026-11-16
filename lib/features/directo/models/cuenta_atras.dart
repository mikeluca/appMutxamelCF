/// La hora de un partido está en hora de España (Europe/Madrid), la del club. Si el móvil está en otra zona
/// horaria hay que convertirla: este paquete no usa `timezone` (no está en el proyecto), así que se aplican las
/// reglas del horario de verano europeo, que son fijas: se adelanta el último domingo de marzo a la 01:00 UTC y se
/// atrasa el último domingo de octubre a la 01:00 UTC (CET = UTC+1, CEST = UTC+2).
class HoraMadrid {
  HoraMadrid._();

  /// El instante (en UTC) de las [horaTexto] ("18:30") del [dia] en hora de Madrid; null si no hay hora válida.
  static DateTime? instante(DateTime? dia, String? horaTexto) {
    if (dia == null || horaTexto == null) return null;

    final partes = horaTexto.trim().split(':');

    if (partes.length < 2) return null;

    final horas = int.tryParse(partes[0].trim());
    final minutos = int.tryParse(partes[1].trim());

    if (horas == null ||
        minutos == null ||
        horas < 0 ||
        horas > 23 ||
        minutos < 0 ||
        minutos > 59) {
      return null;
    }

    // Como si esa hora fuera UTC; luego se le resta el desfase de Madrid de ese día.
    final comoUtc = DateTime.utc(dia.year, dia.month, dia.day, horas, minutos);
    final enHorarioDeInvierno = comoUtc.subtract(const Duration(hours: 1));
    final desfase = _esHorarioDeVerano(enHorarioDeInvierno) ? 2 : 1;

    return comoUtc.subtract(Duration(hours: desfase));
  }

  static bool _esHorarioDeVerano(DateTime instanteUtc) {
    final inicio = _ultimoDomingo(instanteUtc.year, DateTime.march);
    final fin = _ultimoDomingo(instanteUtc.year, DateTime.october);

    return !instanteUtc.isBefore(inicio) && instanteUtc.isBefore(fin);
  }

  /// El último domingo del mes, a la 01:00 UTC.
  static DateTime _ultimoDomingo(int anio, int mes) {
    var dia = DateTime.utc(anio, mes + 1, 0);

    while (dia.weekday != DateTime.sunday) {
      dia = dia.subtract(const Duration(days: 1));
    }

    return DateTime.utc(anio, mes, dia.day, 1);
  }
}

enum FaseCuentaAtras {
  /// "Empieza en 2 d 4 h".
  dias,

  /// "Empieza en 3 h 15 min".
  horas,

  /// "Empieza en 45 min".
  minutos,

  /// Desde 30 min antes: "Calentando…".
  calentando,

  /// Ya pasó la hora y el partido no ha empezado: "A punto de empezar" (nunca números negativos).
  aPuntoDeEmpezar,
}

/// Cuánto falta para un partido que todavía no ha empezado.
class CuentaAtras {
  final FaseCuentaAtras fase;
  final int dias;
  final int horas;
  final int minutos;

  const CuentaAtras(this.fase, {this.dias = 0, this.horas = 0, this.minutos = 0});

  /// Desde cuánto antes del inicio se dice "Calentando…".
  static const Duration calentamiento = Duration(minutes: 30);

  static CuentaAtras calcular(DateTime inicio, DateTime ahora) {
    final falta = inicio.difference(ahora);

    if (falta <= Duration.zero) {
      return const CuentaAtras(FaseCuentaAtras.aPuntoDeEmpezar);
    }

    if (falta <= calentamiento) {
      return const CuentaAtras(FaseCuentaAtras.calentando);
    }

    if (falta < const Duration(hours: 1)) {
      return CuentaAtras(FaseCuentaAtras.minutos, minutos: falta.inMinutes);
    }

    if (falta < const Duration(days: 1)) {
      return CuentaAtras(
        FaseCuentaAtras.horas,
        horas: falta.inHours,
        minutos: falta.inMinutes % 60,
      );
    }

    return CuentaAtras(
      FaseCuentaAtras.dias,
      dias: falta.inDays,
      horas: falta.inHours % 24,
    );
  }
}
