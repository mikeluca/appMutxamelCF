import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============================================================
  // COLORES CORPORATIVOS MUTXAMEL CF
  // ============================================================

  static const Color azulOscuro = Color(0xFF0B3D5C);
  static const Color azul = Color(0xFF1976B8);
  static const Color fondo = Color(0xFFF5F1E9);
  static const Color dorado = Color(0xFFE5A928);

  // ============================================================
  // COLORES AUXILIARES
  // ============================================================

  static const Color texto = Color(0xFF18252B);
  static const Color blancoCalido = Color(0xFFFFFDF8);
  static const Color gris = Color(0xFF9E9E9E);
  static const Color morado = Color(0xFF7B3FA0);

  // ============================================================
  // ALIAS
  // Mantienen compatibilidad con código existente
  // ============================================================

  static const Color primary = azul;
  static const Color primaryDark = azulOscuro;
  static const Color secondary = dorado;

  // ============================================================
  // TIPO DE PARTIDO (Liga, Amistoso, Copa, Torneo)
  // ============================================================

  /// Color asociado a cada tipo de partido, usado para el borde de
  /// las tarjetas de partido. Devuelve null si el tipo es
  /// desconocido/no informado, en cuyo caso no se aplica ningún
  /// tratamiento especial.
  static Color? colorTipoPartido(String? tipo) {
    switch (tipo?.trim().toUpperCase()) {
      case 'LIGA':
        return azul;
      case 'AMISTOSO':
        return gris;
      case 'COPA':
        return dorado;
      case 'TORNEO':
        return morado;
      default:
        return null;
    }
  }

  /// Etiqueta legible para el tipo de partido (p.ej. 'Liga'). Devuelve
  /// null si el tipo es desconocido/no informado.
  static String? etiquetaTipoPartido(String? tipo) {
    final valor = tipo?.trim();

    if (valor == null || valor.isEmpty) {
      return null;
    }

    final minuscula = valor.toLowerCase();

    return minuscula[0].toUpperCase() + minuscula.substring(1);
  }
}