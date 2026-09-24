import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/features/club/models/red_social.dart';

void main() {
  group('kRedesSociales', () {
    test('contiene las 4 redes sociales de la cabecera de la web', () {
      expect(kRedesSociales.length, 4);
      expect(
        kRedesSociales.map((red) => red.nombre),
        ['X (Twitter)', 'Facebook', 'Instagram', 'YouTube'],
      );
    });

    test('cada red social tiene su enlace externo correcto', () {
      final urlsPorNombre = {
        for (final red in kRedesSociales) red.nombre: red.url,
      };

      expect(urlsPorNombre['X (Twitter)'], 'https://x.com/mutxamelcf');
      expect(urlsPorNombre['Facebook'], 'https://facebook.com/MutxamelCF17');
      expect(
        urlsPorNombre['Instagram'],
        'https://instagram.com/mutxamelcf.oficial/',
      );
      expect(
        urlsPorNombre['YouTube'],
        'https://youtube.com/@mutxamelcf355',
      );
    });
  });
}
