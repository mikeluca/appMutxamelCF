import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

/// Color asociado a cada estado de asistencia a un entrenamiento
/// ("PRESENTE"/"FALTA"/"FALTA_JUSTIFICADA"/"MAL_COMPORTAMIENTO"/
/// "RETRASO"), compartido entre la pantalla de gestión de asistencia y
/// el calendario del familiar/jugador para que ambos usen los mismos
/// colores.
Color colorEstadoAsistencia(String estado) {
  switch (estado) {
    case 'PRESENTE':
      return const Color.fromARGB(255, 64, 236, 70);
    case 'FALTA_JUSTIFICADA':
      return const Color.fromARGB(255, 255, 230, 7);
    case 'FALTA':
      return const Color.fromARGB(255, 248, 26, 26);
    case 'MAL_COMPORTAMIENTO':
      return const Color.fromARGB(255, 105, 104, 104);
    case 'RETRASO':
      return const Color.fromARGB(255, 115, 23, 190);
    default:
      return Colors.green;
  }
}

/// Texto localizado de un estado de asistencia. Devuelve el propio
/// código si no se reconoce (no debería ocurrir con los estados que
/// admite el backend, pero evita dejar la tarjeta en blanco ante un
/// valor inesperado).
String labelEstadoAsistencia(AppLocalizations t, String estado) {
  switch (estado) {
    case 'PRESENTE':
      return t.attendanceStatusPresent;
    case 'FALTA':
      return t.attendanceStatusAbsent;
    case 'RETRASO':
      return t.attendanceStatusLate;
    case 'FALTA_JUSTIFICADA':
      return t.attendanceStatusJustifiedAbsence;
    case 'MAL_COMPORTAMIENTO':
      return t.attendanceStatusMisconduct;
    default:
      return estado;
  }
}
