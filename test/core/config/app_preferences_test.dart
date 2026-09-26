import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_mutxamel_cf/core/config/app_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppPreferences.obtenerNotifNoticias/guardarNotifNoticias', () {
    test('por defecto es false (opt-in explicito)', () async {
      expect(await AppPreferences.obtenerNotifNoticias(), isFalse);
    });

    test('guarda y recupera el valor activado', () async {
      await AppPreferences.guardarNotifNoticias(true);

      expect(await AppPreferences.obtenerNotifNoticias(), isTrue);

      await AppPreferences.guardarNotifNoticias(false);

      expect(await AppPreferences.obtenerNotifNoticias(), isFalse);
    });
  });

  group('AppPreferences.existeIdiomaGuardado', () {
    test('es false cuando nunca se ha guardado un idioma', () async {
      expect(await AppPreferences.existeIdiomaGuardado(), isFalse);
    });

    test('es true despues de guardar un idioma', () async {
      await AppPreferences.guardarIdioma('en');

      expect(await AppPreferences.existeIdiomaGuardado(), isTrue);
    });
  });

  group('AppPreferences.obtenerNotifResultados/guardarNotifResultados', () {
    test('por defecto es false (opt-in explicito)', () async {
      expect(await AppPreferences.obtenerNotifResultados(), isFalse);
    });

    test('guarda y recupera el valor activado', () async {
      await AppPreferences.guardarNotifResultados(true);

      expect(await AppPreferences.obtenerNotifResultados(), isTrue);

      await AppPreferences.guardarNotifResultados(false);

      expect(await AppPreferences.obtenerNotifResultados(), isFalse);
    });
  });
}
