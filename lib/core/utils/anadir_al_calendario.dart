import 'dart:io' show Platform;

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import 'evento_partido.dart';

/// "Añadir a mi calendario": abre el editor de eventos del sistema con el evento ya relleno (en Android, por el intent
/// del calendario, sin permisos; en iOS, con el permiso de solo escritura del calendario). Nunca lanza.
class AnadirAlCalendario {
  AnadirAlCalendario._();

  /// Solo para tests: sustituye al calendario del sistema; true si el evento se ha guardado o el editor se ha abierto.
  @visibleForTesting
  static Future<bool> Function(EventoCalendario evento) enviar = _enviar;

  @visibleForTesting
  static bool Function() esIos = () => Platform.isIOS;

  @visibleForTesting
  static Future<void> Function() abrirAjustes = () =>
      AppSettings.openAppSettings();

  static Future<bool> _enviar(EventoCalendario e) {
    return Add2Calendar.addEvent2Cal(
      Event(
        title: e.titulo,
        description: e.descripcion,
        location: e.lugar,
        startDate: e.inicio,
        endDate: e.fin,
        allDay: e.todoElDia,
        timeZone: e.zonaHoraria,
      ),
    );
  }

  /// Añade [evento] al calendario. Si el usuario cancela, no pasa nada; si el sistema no lo añade (en iOS: sin permiso
  /// del calendario, que el plugin no distingue de cancelar), un SnackBar con "Abrir ajustes".
  static Future<void> anadir(
    BuildContext context,
    EventoCalendario evento,
  ) async {
    final t = AppLocalizations.of(context);
    final mensajes = ScaffoldMessenger.maybeOf(context);

    try {
      final hecho = await enviar(evento);

      if (hecho) return;

      if (esIos()) {
        mensajes
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(t.calendarAddDenied),
              action: SnackBarAction(
                label: t.openSettingsAction,
                onPressed: () => abrirAjustes(),
              ),
            ),
          );
      } else {
        mensajes?.showSnackBar(SnackBar(content: Text(t.calendarAddError)));
      }
    } catch (e) {
      debugPrint('NO SE PUDO AÑADIR AL CALENDARIO: $e');

      mensajes?.showSnackBar(SnackBar(content: Text(t.calendarAddError)));
    }
  }
}
