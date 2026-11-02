import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_mutxamel_cf/core/config/app_preferences.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/services/topics_anonimos.dart';

void main() {
  late List<String> altas;
  late List<String> bajas;
  late TopicsAnonimos topics;

  setUp(() {
    altas = [];
    bajas = [];
    topics = TopicsAnonimos(
      suscribir: (topic) async => altas.add(topic),
      desuscribir: (topic) async => bajas.add(topic),
    );
  });

  group('TopicsAnonimos nombres', () {
    test('un topic por idioma', () {
      expect(TopicsAnonimos.topicDe('noticias', 'ca'), 'noticias_ca');
      expect(TopicsAnonimos.topicDe('resultados', 'en'), 'resultados_en');
    });

    test('los otros son el antiguo sin idioma y los de los demás idiomas', () {
      expect(TopicsAnonimos.otrosTopics('noticias', 'ca'), [
        'noticias',
        'noticias_es',
        'noticias_en',
      ]);
    });
  });

  group('TopicsAnonimos.activar', () {
    test('alta en el topic del idioma y baja del antiguo y de los otros', () async {
      await topics.activar('resultados', 'ca');

      expect(altas, ['resultados_ca']);
      expect(bajas, ['resultados', 'resultados_es', 'resultados_en']);
    });
  });

  group('TopicsAnonimos.desactivar', () {
    test('baja de todos los topics de ese tipo y no da de alta ninguno', () async {
      await topics.desactivar('noticias');

      expect(altas, isEmpty);
      expect(
        bajas,
        unorderedEquals([
          'noticias',
          'noticias_es',
          'noticias_ca',
          'noticias_en',
        ]),
      );
    });
  });

  group('TopicsAnonimos.cambiarIdioma', () {
    test('de lo que está activo, baja del idioma anterior y alta en el nuevo', () async {
      await topics.cambiarIdioma(
        anterior: 'es',
        nuevo: 'en',
        noticias: true,
        resultados: true,
      );

      expect(bajas, ['noticias_es', 'resultados_es']);
      expect(altas, ['noticias_en', 'resultados_en']);
    });

    test('solo toca los tipos que el usuario tiene activos', () async {
      await topics.cambiarIdioma(
        anterior: 'ca',
        nuevo: 'es',
        noticias: false,
        resultados: true,
      );

      expect(bajas, ['resultados_ca']);
      expect(altas, ['resultados_es']);
    });

    test('con todo desactivado o el mismo idioma, no hace nada', () async {
      await topics.cambiarIdioma(
        anterior: 'es',
        nuevo: 'ca',
        noticias: false,
        resultados: false,
      );
      await topics.cambiarIdioma(
        anterior: 'es',
        nuevo: 'es',
        noticias: true,
        resultados: true,
      );

      expect(altas, isEmpty);
      expect(bajas, isEmpty);
    });
  });

  group('TopicsAnonimos.sincronizar', () {
    test('migra a quien estaba en los topics antiguos al topic de su idioma', () async {
      await topics.sincronizar(idioma: 'ca', noticias: true, resultados: false);

      expect(altas, ['noticias_ca']);
      expect(bajas, ['noticias', 'noticias_es', 'noticias_en']);
    });

    test('sin ningún interruptor activo, no hace nada', () async {
      await topics.sincronizar(
        idioma: 'es',
        noticias: false,
        resultados: false,
      );

      expect(altas, isEmpty);
      expect(bajas, isEmpty);
    });
  });

  group('TopicsAnonimos.desuscribirDeTodos', () {
    test('baja de los ocho topics: los seis por idioma y los dos antiguos', () async {
      await topics.desuscribirDeTodos();

      expect(altas, isEmpty);
      expect(bajas.toSet(), {
        'noticias',
        'noticias_es',
        'noticias_ca',
        'noticias_en',
        'resultados',
        'resultados_es',
        'resultados_ca',
        'resultados_en',
      });
      expect(bajas, hasLength(8));
    });
  });

  group('PushNotificationService con los topics anónimos', () {
    late TopicsAnonimos original;

    setUp(() {
      original = PushNotificationService.topicsAnonimos;
      PushNotificationService.topicsAnonimos = topics;
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStoragePlatform.instance =
          TestFlutterSecureStoragePlatform(<String, String>{});
    });

    tearDown(() {
      PushNotificationService.topicsAnonimos = original;
    });

    test('el interruptor de noticias usa el topic del idioma de la app', () async {
      await AppPreferences.guardarIdioma('ca');

      await PushNotificationService.activarNoticiasAnonimas(true);

      expect(altas, ['noticias_ca']);
      expect(bajas, ['noticias', 'noticias_es', 'noticias_en']);

      altas.clear();
      bajas.clear();

      await PushNotificationService.activarNoticiasAnonimas(false);

      expect(altas, isEmpty);
      expect(bajas, hasLength(4));
    });

    test('el interruptor de resultados usa el topic del idioma de la app', () async {
      await AppPreferences.guardarIdioma('en');

      await PushNotificationService.activarResultadosAnonimos(true);

      expect(altas, ['resultados_en']);
    });

    test('al cambiar de idioma cambia de topic y recuerda el idioma de los topics', () async {
      await AppPreferences.guardarNotifResultados(true);

      await PushNotificationService.alCambiarIdioma('es', 'ca');

      expect(bajas, ['resultados_es']);
      expect(altas, ['resultados_ca']);
      expect(await AppPreferences.obtenerIdiomaTopics(), 'ca');
    });

    test('un fallo de Firebase al cambiar de idioma no se propaga', () async {
      await AppPreferences.guardarNotifNoticias(true);
      PushNotificationService.topicsAnonimos = TopicsAnonimos(
        suscribir: (_) async => throw Exception('sin red'),
        desuscribir: (_) async {},
      );

      await PushNotificationService.alCambiarIdioma('es', 'en');
    });

    test('al arrancar, migra los topics antiguos al idioma de la app una sola vez', () async {
      await AppPreferences.guardarIdioma('es');
      await AppPreferences.guardarNotifNoticias(true);

      await PushNotificationService.sincronizarTopicsAnonimos();

      expect(altas, ['noticias_es']);
      expect(bajas, ['noticias', 'noticias_ca', 'noticias_en']);
      expect(await AppPreferences.obtenerIdiomaTopics(), 'es');

      altas.clear();
      bajas.clear();

      // Segundo arranque, mismo idioma: ya está hecho.
      await PushNotificationService.sincronizarTopicsAnonimos();

      expect(altas, isEmpty);
      expect(bajas, isEmpty);
    });

    test('al arrancar con otro idioma que la última vez, vuelve a ajustar los topics', () async {
      await AppPreferences.guardarIdioma('en');
      await AppPreferences.guardarIdiomaTopics('es');
      await AppPreferences.guardarNotifResultados(true);

      await PushNotificationService.sincronizarTopicsAnonimos();

      expect(altas, ['resultados_en']);
    });
  });
}
