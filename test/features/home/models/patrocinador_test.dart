import 'package:app_mutxamel_cf/features/home/models/patrocinador.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Patrocinador.fromJson', () {
    test('lee nombre, imagenUrl, url y circular', () {
      final p = Patrocinador.fromJson({
        'nombre': 'La bodega de Elias',
        'imagenUrl': '/images/laBodega.jpg',
        'url': 'https://www.instagram.com/labodegaelias/',
        'circular': true,
      });

      expect(p.nombre, 'La bodega de Elias');
      expect(p.imagenUrl, '/images/laBodega.jpg');
      expect(p.url, 'https://www.instagram.com/labodegaelias/');
      expect(p.circular, isTrue);
    });

    test('url null o vacía es sin enlace y circular ausente es false', () {
      final nula = Patrocinador.fromJson({
        'nombre': 'Aresala',
        'imagenUrl': '/images/aresala.jpg',
        'url': null,
        'circular': false,
      });
      final vacia = Patrocinador.fromJson({
        'nombre': 'X',
        'imagenUrl': '/images/x.jpg',
        'url': ' ',
      });

      expect(nula.url, isNull);
      expect(vacia.url, isNull);
      expect(vacia.circular, isFalse);
    });
  });
}
