import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/core/theme/app_colors.dart';

void main() {
  group('AppColors.colorTipoPartido', () {
    test('devuelve el color correspondiente a cada tipo conocido', () {
      expect(AppColors.colorTipoPartido('LIGA'), AppColors.azul);
      expect(AppColors.colorTipoPartido('AMISTOSO'), AppColors.gris);
      expect(AppColors.colorTipoPartido('COPA'), AppColors.dorado);
      expect(AppColors.colorTipoPartido('TORNEO'), AppColors.morado);
    });

    test('es insensible a mayusculas/minusculas y a espacios', () {
      expect(AppColors.colorTipoPartido(' liga '), AppColors.azul);
      expect(AppColors.colorTipoPartido('copa'), AppColors.dorado);
    });

    test('devuelve null si el tipo es desconocido o no informado', () {
      expect(AppColors.colorTipoPartido(null), isNull);
      expect(AppColors.colorTipoPartido(''), isNull);
      expect(AppColors.colorTipoPartido('OTRO'), isNull);
    });
  });

  group('AppColors.etiquetaTipoPartido', () {
    test('devuelve una etiqueta legible con la primera letra en mayuscula', () {
      expect(AppColors.etiquetaTipoPartido('LIGA'), 'Liga');
      expect(AppColors.etiquetaTipoPartido('AMISTOSO'), 'Amistoso');
      expect(AppColors.etiquetaTipoPartido('COPA'), 'Copa');
      expect(AppColors.etiquetaTipoPartido('TORNEO'), 'Torneo');
    });

    test('devuelve null si el tipo es nulo o esta vacio', () {
      expect(AppColors.etiquetaTipoPartido(null), isNull);
      expect(AppColors.etiquetaTipoPartido(''), isNull);
      expect(AppColors.etiquetaTipoPartido('   '), isNull);
    });
  });
}
