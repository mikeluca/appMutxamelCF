import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../core/network/api_client.dart';

/// Las funciones que el servidor tiene activadas (GET /api/public/app/funciones, sin sesión). Solo se consultan y se
/// guardan en memoria mientras vive la pantalla que las pide: no se persiste nada en el móvil.
class FuncionesApp {
  /// Si el servidor deja a las familias registrarse solas. Sin respuesta, con error o sin el campo, es false.
  final bool registroFamiliasHabilitado;

  const FuncionesApp({this.registroFamiliasHabilitado = false});

  /// Todo apagado: lo que se asume mientras se consulta y cuando la consulta falla.
  static const deshabilitadas = FuncionesApp();

  factory FuncionesApp.fromJson(Object? json) {
    final habilitado = json is Map<String, dynamic>
        ? json['registroFamiliasHabilitado']
        : null;

    return FuncionesApp(registroFamiliasHabilitado: habilitado == true);
  }

  /// Solo para tests: sustituye a la red.
  @visibleForTesting
  static Future<Object?> Function() leerDelServidor = () =>
      ApiClient.get('/public/app/funciones');

  /// Consulta las funciones; ante cualquier fallo devuelve [deshabilitadas].
  static Future<FuncionesApp> consultar() async {
    try {
      return FuncionesApp.fromJson(await leerDelServidor());
    } catch (_) {
      return deshabilitadas;
    }
  }
}
