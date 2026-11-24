import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app_mutxamel_cf/features/juego/logica/cabezazos_logica.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las formas de choque de Mutxigol se miden sobre el canal alfa de mutxigol_salto.webp (768 × 768 px): estos tests
/// comprueban contra la imagen que los círculos siguen el cuerpo y que no cubren cuernos, mechón ni la mano del brazo
/// estirado.
class _Mascara {
  _Mascara(this.w, this.h, this.datos);

  final int w;
  final int h;
  final ByteData datos;

  bool opaco(int x, int y) =>
      x >= 0 && y >= 0 && x < w && y < h && datos.getUint8((y * w + x) * 4 + 3) > 40;
}

Future<_Mascara> _cargar(Equipacion e) async {
  final bytes = await File(ImagenesMutxigol.pose(e, PoseMutxigol.salto)).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final img = (await codec.getNextFrame()).image;
  final datos = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;

  return _Mascara(img.width, img.height, datos);
}

void main() {
  for (final e in Equipacion.values) {
    test('los círculos de ${e.carpeta} siguen la silueta de mutxigol_salto (alfa)', () async {
      final m = await _cargar(e);

      expect(m.w, 768);
      expect(m.h, 768);

      // El personaje visible mide ~0,68 de la imagen.
      var minY = m.h, maxY = 0;

      for (var y = 0; y < m.h; y++) {
        for (var x = 0; x < m.w; x++) {
          if (m.opaco(x, y)) {
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }

      expect((maxY - minY) / m.h, closeTo(CabezazosLogica.alturaVisibleEnImagen, 0.015));

      final circulos = [
        for (final (dx, dy, r) in CabezazosLogica.circulosCuerpo)
          (cx: (0.5 + dx) * m.w, cy: (0.5 + dy) * m.h, r: r * m.w),
      ];

      // 1) Cada círculo cae casi entero sobre píxeles opacos (el cuerpo): ≥ 88 %.
      for (var i = 0; i < circulos.length; i++) {
        final c = circulos[i];
        var dentro = 0, opacos = 0;

        for (var y = (c.cy - c.r).floor(); y <= (c.cy + c.r).ceil(); y++) {
          for (var x = (c.cx - c.r).floor(); x <= (c.cx + c.r).ceil(); x++) {
            if ((x - c.cx) * (x - c.cx) + (y - c.cy) * (y - c.cy) <= c.r * c.r) {
              dentro++;

              if (m.opaco(x, y)) opacos++;
            }
          }
        }

        expect(opacos / dentro, greaterThan(0.88), reason: 'círculo $i sobre el cuerpo');
      }

      bool cubierto(int x, int y) => circulos.any(
        (c) => (x - c.cx) * (x - c.cx) + (y - c.cy) * (y - c.cy) <= c.r * c.r,
      );

      // 2) Los cuernos (la punta de arriba, y 84–125 y x 365–400) y el mechón blanco quedan fuera.
      var cuernos = 0, cuernosCubiertos = 0;

      for (var y = 84; y < 125; y++) {
        for (var x = 360; x < 500; x++) {
          if (m.opaco(x, y)) {
            cuernos++;

            if (cubierto(x, y)) cuernosCubiertos++;
          }
        }
      }

      expect(cuernos, greaterThan(100));
      expect(cuernosCubiertos / cuernos, lessThan(0.05), reason: 'cuernos y mechón fuera');

      // 3) La mano del brazo estirado (x 225–310, y 190–300) queda fuera.
      var mano = 0, manoCubierta = 0;

      for (var y = 190; y < 300; y++) {
        for (var x = 225; x < 300; x++) {
          if (m.opaco(x, y)) {
            mano++;

            if (cubierto(x, y)) manoCubierta++;
          }
        }
      }

      expect(mano, greaterThan(500));
      expect(manoCubierta / mano, lessThan(0.05), reason: 'la mano fuera');

      // 4) Cubren lo esencial del cuerpo: la camiseta y la cabeza (≥ 80 % de lo opaco en x 310–465, y 330–490 y de la
      // cabeza en x 330–520, y 150–330).
      for (final zona in [(310, 465, 330, 490), (330, 520, 150, 330)]) {
        var total = 0, tapado = 0;

        for (var y = zona.$3; y < zona.$4; y++) {
          for (var x = zona.$1; x < zona.$2; x++) {
            if (m.opaco(x, y)) {
              total++;

              if (cubierto(x, y)) tapado++;
            }
          }
        }

        expect(tapado / total, greaterThan(0.8), reason: 'zona $zona');
      }
    });
  }
}
