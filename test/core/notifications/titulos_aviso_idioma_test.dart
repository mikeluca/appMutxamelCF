import 'package:flutter_test/flutter_test.dart';

import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';

/// Los avisos llegan en el idioma de la cuenta: lo que decide a dónde lleva
/// tocarlos es el `tipo` del data (que no cambia), y para las filas de la
/// bandeja, que no guardan el data, el título de la convocatoria nueva en
/// cualquiera de los tres idiomas.
void main() {
  group('título de la convocatoria nueva en cada idioma', () {
    test('se reconoce en castellano, valenciano e inglés', () {
      for (final titulo in [
        'Nueva convocatoria',
        'Nova convocatòria',
        'New call-up',
        '  New call-up ',
      ]) {
        expect(esTituloNuevaConvocatoria(titulo), isTrue, reason: titulo);
        expect(esAvisoDeConvocatoria(titulo: titulo), isTrue, reason: titulo);
      }
    });

    test('otros títulos no cuentan', () {
      expect(esTituloNuevaConvocatoria('Cambio en la convocatoria'), isFalse);
      expect(esTituloNuevaConvocatoria(null), isFalse);
      expect(esAvisoDeConvocatoria(titulo: 'Training cancelled'), isFalse);
    });
  });

  group('la acción del data reconoce la convocatoria nueva', () {
    test('NUEVA lo es sea cual sea el título', () {
      for (final titulo in ['Nueva convocatoria', 'Canvi', 'Whatever', null]) {
        expect(
          esConvocatoriaNueva(accion: 'NUEVA', titulo: titulo),
          isTrue,
          reason: '$titulo',
        );
      }
    });

    test('con otra acción no lo es, aunque el título sea el de una nueva', () {
      for (final accion in ['CAMBIO', 'QUITADO', 'ANULADA']) {
        expect(
          esConvocatoriaNueva(accion: accion, titulo: 'New call-up'),
          isFalse,
          reason: accion,
        );
      }
    });

    test('sin acción (avisos antiguos y bandeja) se mira el título', () {
      expect(esConvocatoriaNueva(titulo: 'Nova convocatòria'), isTrue);
      expect(esConvocatoriaNueva(accion: '', titulo: 'New call-up'), isTrue);
      expect(esConvocatoriaNueva(titulo: 'Call-up updated'), isFalse);
      expect(esConvocatoriaNueva(), isFalse);
    });

    test('un aviso antiguo de tipo COMUNICACION con acción NUEVA es de convocatoria', () {
      expect(
        esAvisoDeConvocatoria(tipo: 'COMUNICACION', titulo: 'Anything', accion: 'NUEVA'),
        isTrue,
      );
      expect(
        esAvisoDeConvocatoria(tipo: 'COMUNICACION', titulo: 'Anything'),
        isFalse,
      );
      expect(
        esAvisoDeConvocatoria(tipo: 'COMUNICACION', titulo: 'New call-up', accion: 'CAMBIO'),
        isFalse,
      );
    });
  });

  group('el tipo decide el destino, no el idioma del texto', () {
    test('los tipos de convocatoria siguen siendo avisos de convocatoria con cualquier título', () {
      for (final titulo in ['Cambio en la convocatoria', 'Canvi en la convocatòria', 'Call-up updated']) {
        expect(
          esAvisoDeConvocatoria(tipo: tipoPushConvocatoria, titulo: titulo),
          isTrue,
          reason: titulo,
        );
        expect(
          esAvisoDeConvocatoria(tipo: tipoPushConvocatoriaEditar, titulo: titulo),
          isTrue,
          reason: titulo,
        );
        expect(
          esAvisoDeConvocatoria(tipo: tipoPushPasarLista, titulo: titulo),
          isTrue,
          reason: titulo,
        );
      }
    });

    test('pasar lista abre la asistencia aunque el título esté en inglés', () {
      final destino = destinoDeAvisoConvocatoria(
        tipo: tipoPushPasarLista,
        titulo: 'Take attendance',
        datos: {'entrenamientoId': '9'},
      );

      expect(destino, isA<PasarLista>());
      expect((destino as PasarLista).entrenamientoId, 9);
    });

    test('editar convocatoria abre la edición aunque el título esté en valenciano', () {
      final destino = destinoDeAvisoConvocatoria(
        tipo: tipoPushConvocatoriaEditar,
        titulo: 'Convocat amb absència justificada',
        datos: {'convocatoriaId': '4'},
      );

      expect(destino, isA<EditarConvocatoria>());
    });

    test('continuidad abre la pantalla de continuidad en cualquier idioma', () {
      expect(
        destinoDeAvisoConvocatoria(tipo: tipoPushContinuidad, titulo: 'Next season: 2027/2028'),
        isA<AbrirContinuidad>(),
      );
    });
  });
}
