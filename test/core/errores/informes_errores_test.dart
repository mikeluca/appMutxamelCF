
import 'package:app_mutxamel_cf/core/config/app_preferences.dart';
import 'package:app_mutxamel_cf/core/errores/informes_errores.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Pasarela implements PasarelaInformes {
  final List<bool> recogida = [];
  final List<FlutterErrorDetails> erroresDeFlutter = [];
  final List<Object> errores = [];
  final Map<String, String> claves = {};

  @override
  Future<void> activarRecogida(bool activada) async => recogida.add(activada);

  @override
  Future<void> registrarErrorDeFlutter(FlutterErrorDetails detalles) async =>
      erroresDeFlutter.add(detalles);

  @override
  Future<void> registrarError(Object error, StackTrace pila) async =>
      errores.add(error);

  @override
  Future<void> poner(String clave, String valor) async => claves[clave] = valor;
}

void main() {
  late _Pasarela pasarela;
  late void Function(FlutterErrorDetails)? onErrorAnterior;
  late bool Function(Object, StackTrace)? onErrorPlataformaAnterior;

  setUp(() {
    SharedPreferences.setMockInitialValues({'idioma_aplicacion': 'ca'});

    pasarela = _Pasarela();
    InformesErrores.pasarela = pasarela;
    InformesErrores.esDebug = () => false;
    InformesErrores.leerVersion = () async => '1.0.11+19';
    InformesErrores.haySesion = () async => false;
    InformesErrores.recogidaActivada = false;

    onErrorAnterior = FlutterError.onError;
    onErrorPlataformaAnterior = PlatformDispatcher.instance.onError;
    // Sin enseñar el error en la consola del test
    FlutterError.presentError = (_) {};
  });

  tearDown(() {
    FlutterError.onError = onErrorAnterior;
    PlatformDispatcher.instance.onError = onErrorPlataformaAnterior;
    FlutterError.presentError = FlutterError.dumpErrorToConsole;
  });

  group('recogida', () {
    test(
      'en debug no se envía nada, aunque la preferencia esté activada',
      () async {
        InformesErrores.esDebug = () => true;

        await InformesErrores.iniciar();

        expect(pasarela.recogida, [false]);
        expect(InformesErrores.recogidaActivada, isFalse);

        FlutterError.onError!(FlutterErrorDetails(exception: 'fallo'));
        PlatformDispatcher.instance.onError!('otro fallo', StackTrace.empty);

        expect(pasarela.erroresDeFlutter, isEmpty);
        expect(pasarela.errores, isEmpty);
      },
    );

    test(
      'en release está activada por defecto y envía los dos tipos de error',
      () async {
        await InformesErrores.iniciar();

        expect(pasarela.recogida, [true]);

        FlutterError.onError!(FlutterErrorDetails(exception: 'fallo'));
        final gestionado = PlatformDispatcher.instance.onError!(
          'otro fallo',
          StackTrace.empty,
        );

        expect(pasarela.erroresDeFlutter, hasLength(1));
        expect(pasarela.errores, ['otro fallo']);
        expect(gestionado, isTrue);
      },
    );

    test(
      'con el interruptor de Ajustes apagado no se envía nada, y se aplica al arrancar',
      () async {
        SharedPreferences.setMockInitialValues({
          'idioma_aplicacion': 'es',
          'informes_errores': false,
        });

        await InformesErrores.iniciar();

        expect(pasarela.recogida, [false]);

        FlutterError.onError!(FlutterErrorDetails(exception: 'fallo'));
        PlatformDispatcher.instance.onError!('otro', StackTrace.empty);

        expect(pasarela.erroresDeFlutter, isEmpty);
        expect(pasarela.errores, isEmpty);
      },
    );

    test(
      'el interruptor guarda la preferencia y la aplica al momento',
      () async {
        await InformesErrores.iniciar();

        await InformesErrores.cambiarPreferencia(false);

        expect(await AppPreferences.obtenerInformesErrores(), isFalse);
        expect(pasarela.recogida.last, isFalse);

        FlutterError.onError!(FlutterErrorDetails(exception: 'fallo'));
        expect(pasarela.erroresDeFlutter, isEmpty);

        await InformesErrores.cambiarPreferencia(true);

        expect(await AppPreferences.obtenerInformesErrores(), isTrue);
        expect(pasarela.recogida.last, isTrue);

        FlutterError.onError!(FlutterErrorDetails(exception: 'fallo'));
        expect(pasarela.erroresDeFlutter, hasLength(1));
      },
    );

    test('por defecto el interruptor está activado', () async {
      expect(await AppPreferences.obtenerInformesErrores(), isTrue);
    });
  });

  group('sin datos personales', () {
    test('solo la versión, el idioma y si hay sesión', () async {
      await InformesErrores.iniciar();

      expect(pasarela.claves, {
        InformesErrores.claveVersion: '1.0.11+19',
        InformesErrores.claveIdioma: 'ca',
        InformesErrores.claveSesion: 'no',
      });
    });

    test('con sesión solo dice "si", nunca quién es', () async {
      InformesErrores.haySesion = () async => true;

      await InformesErrores.actualizarClaves();

      expect(pasarela.claves[InformesErrores.claveSesion], 'si');
      expect(pasarela.claves.keys, {
        InformesErrores.claveVersion,
        InformesErrores.claveIdioma,
        InformesErrores.claveSesion,
      });
      // Ninguna clave ni valor lleva un correo
      expect(pasarela.claves.values.any((v) => v.contains('@')), isFalse);
    });

    test('la pasarela no tiene forma de poner un identificador de usuario', () {
      // La interfaz solo ofrece activar la recogida, registrar errores y poner claves: no hay setUserIdentifier.
      final metodos = <String>{
        'activarRecogida',
        'registrarErrorDeFlutter',
        'registrarError',
        'poner',
      };

      expect(metodos.contains('setUserIdentifier'), isFalse);
    });
  });
}
