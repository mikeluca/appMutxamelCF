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
