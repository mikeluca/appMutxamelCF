import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ============================================================
  // TEMA CLARO
  // ============================================================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: AppColors.fondo,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.azul,
      primary: AppColors.azul,
      secondary: AppColors.dorado,
      onSecondary: const Color(0xFF18252B),
      surface: AppColors.blancoCalido,
      onSurface: AppColors.texto,
      onSurfaceVariant: const Color(0xFF52636A),
      onPrimary: Colors.white,
      brightness: Brightness.light,
    ),

    // Mismo color que el fondo de la pantalla (igual que en home_page.dart), con texto legible sobre fondo claro.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.fondo,
      foregroundColor: AppColors.texto,
      centerTitle: true,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: AppColors.blancoCalido,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.texto),
      bodyMedium: TextStyle(color: AppColors.texto),
      titleLarge: TextStyle(
        color: AppColors.azulOscuro,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: AppColors.azulOscuro,
        fontWeight: FontWeight.bold,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.azul,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.blancoCalido,
      indicatorColor: AppColors.azul.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: AppColors.azul,
            fontWeight: FontWeight.bold,
          );
        }

        return const TextStyle(color: AppColors.texto);
      }),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.blancoCalido,
      hintStyle: const TextStyle(color: Color(0xFF52636A)),
      labelStyle: const TextStyle(color: Color(0xFF52636A)),
      floatingLabelStyle: const TextStyle(color: AppColors.azul),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.azul, width: 2),
      ),
    ),

    dividerTheme: const DividerThemeData(color: Colors.black12, thickness: 1),
  );

  // ============================================================
  // TEMA OSCURO
  // ============================================================

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: const Color(0xFF10181D),

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.azul,
      primary: const Color(0xFF4FA3D1),
      secondary: AppColors.dorado,
      onSecondary: const Color(0xFF071B27),
      surface: const Color(0xFF18252B),
      onSurface: const Color(0xFFE8EEF1),
      onSurfaceVariant: const Color(0xFFB7C3C9),
      onPrimary: const Color(0xFF071B27),
      brightness: Brightness.dark,
    ),

    // Mismo color que el fondo de la pantalla (igual que en home_page.dart), con texto legible sobre fondo oscuro.
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF10181D),
      foregroundColor: Color(0xFFE8EEF1),
      centerTitle: true,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF18252B),
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFE8EEF1)),
      bodyMedium: TextStyle(color: Color(0xFFE8EEF1)),
      bodySmall: TextStyle(color: Color(0xFFB7C3C9)),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4FA3D1),
        foregroundColor: const Color(0xFF071B27),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF18252B),
      indicatorColor: AppColors.azul.withValues(alpha: 0.35),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: Color(0xFF6DB8DF),
            fontWeight: FontWeight.bold,
          );
        }

        return const TextStyle(color: Color(0xFFB7C3C9));
      }),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF18252B),
      hintStyle: const TextStyle(color: Color(0xFF84939B)),
      labelStyle: const TextStyle(color: Color(0xFFB7C3C9)),
      floatingLabelStyle: const TextStyle(color: Color(0xFF6DB8DF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4FA3D1), width: 2),
      ),
    ),

    dividerTheme: const DividerThemeData(color: Colors.white12, thickness: 1),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.dorado;
        }

        return const Color(0xFFB7C3C9);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.azul;
        }

        return const Color(0xFF3A484F);
      }),
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(color: Colors.white),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0xFF18252B)),
      ),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF18252B),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(color: Color(0xFFE8EEF1), fontSize: 15),
    ),
  );
}
