import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/features/home/models/patrocinador.dart';

void main() {
  group('kPatrocinadores', () {
    test('contiene los 10 patrocinadores del footer de la web', () {
      expect(kPatrocinadores.length, 10);
    });

    test('Aresala es el unico patrocinador sin enlace', () {
      final sinEnlace = kPatrocinadores.where((p) => p.url == null).toList();

      expect(sinEnlace, hasLength(1));
      expect(sinEnlace.single.nombre, 'Aresala');
    });

    test('NUVA y La bodega de Elias se muestran en circulo', () {
      final circulares = kPatrocinadores
          .where((p) => p.circular)
          .map((p) => p.nombre)
          .toList();

      expect(circulares, ['Clinica Dental NUVA', 'La bodega de Elias']);
    });

    test('todos los ficheros de imagen son .jpg salvo AA Energy (.jpeg)', () {
      for (final patrocinador in kPatrocinadores) {
        final esperaJpeg = patrocinador.nombre == 'AA Energy';

        expect(
          patrocinador.imagen.endsWith(esperaJpeg ? '.jpeg' : '.jpg'),
          isTrue,
          reason: '${patrocinador.nombre} -> ${patrocinador.imagen}',
        );
      }
    });
  });
}
