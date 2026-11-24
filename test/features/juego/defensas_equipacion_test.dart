import 'dart:ui' as ui;

import 'package:app_mutxamel_cf/features/juego/logica/cabezazos_logica.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/widgets/escena_cabezazos.dart';
import 'package:app_mutxamel_cf/features/juego/widgets/siluetas_juego.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/juego_helpers.dart';

/// Pinta un defensa de 62 × 68 y devuelve una función para leer el color de un punto (fracciones del recuadro).
Future<Color Function(double, double)> _pintar(Equipacion e) async {
  const w = 62, h = 68;
  final grabador = ui.PictureRecorder();

  DefensaPainter(equipacion: e).paint(Canvas(grabador), const Size(62, 68));

  final img = await grabador.endRecording().toImage(w, h);
  final datos = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!;

  return (fx, fy) {
    final x = (fx * w).floor();
    final y = (fy * h).floor();
    final i = (y * w + x) * 4;

    return Color.fromARGB(
      datos.getUint8(i + 3),
      datos.getUint8(i),
      datos.getUint8(i + 1),
      datos.getUint8(i + 2),
    );
  };
}

bool _casi(Color a, Color b) =>
    (a.r - b.r).abs() < 0.02 && (a.g - b.g).abs() < 0.02 && (a.b - b.b).abs() < 0.02;

void main() {
  test('los colores son los de las imágenes de Mutxigol: azul 1E5BC6 con vivos blancos y rosa E0359A con vivos grises', () {
    expect(KitDefensa.azul.base, const Color(0xFF1E5BC6));
    expect(KitDefensa.azul.vivos, const Color(0xFFFFFFFF));
    expect(KitDefensa.rosa.base, const Color(0xFFE0359A));
    expect(KitDefensa.rosa.vivos, const Color(0xFFBDBDBD));
  });

  test('la otra equipación: azul ↔ rosa', () {
    expect(Equipacion.azul.opuesta, Equipacion.rosa);
    expect(Equipacion.rosa.opuesta, Equipacion.azul);
  });

  for (final (equipacion, base, vivos) in [
    (Equipacion.rosa, const Color(0xFFE0359A), const Color(0xFFBDBDBD)),
    (Equipacion.azul, const Color(0xFF1E5BC6), const Color(0xFFFFFFFF)),
  ]) {
    test('un defensa ${equipacion.name}: camiseta, pantalón y medias del mismo color, franja diagonal y línea fina en los vivos', () async {
      final color = await _pintar(equipacion);

      // Camiseta (debajo de la franja), pantalón y medias.
      expect(_casi(color(0.30, 0.50), base), isTrue, reason: 'camiseta');
      expect(_casi(color(0.50, 0.61), base), isTrue, reason: 'pantalón');
      expect(_casi(color(0.38, 0.78), base), isTrue, reason: 'media izquierda');
      expect(_casi(color(0.62, 0.78), base), isTrue, reason: 'media derecha');

      // La franja diagonal y la línea fina entre camiseta y pantalón, en el color de los vivos.
      expect(_casi(color(0.55, 0.45), vivos), isTrue, reason: 'franja');
      expect(_casi(color(0.30, 0.551), vivos), isTrue, reason: 'línea fina');
    });
  }

  testWidgets('con Mutxigol azul los defensas van de rosa; con Mutxigol rosa, de azul', (tester) async {
    for (final (mutxigol, defensas) in [
      (Equipacion.azul, Equipacion.rosa),
      (Equipacion.rosa, Equipacion.azul),
    ]) {
      pantallaDeMovil(tester, alto: 640);

      final logica = CabezazosLogica(alto: 640);

      logica.tocar();
      logica.colocarBarrera(200, 250, 140);

      await tester.pumpWidget(
        appDePrueba(
          EscenaCabezazos(logica: logica, equipacion: mutxigol, activa: true),
        ),
      );

      final pintores = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((c) => c.painter)
          .whereType<DefensaPainter>()
          .toList();

      expect(pintores, isNotEmpty);
      expect(pintores.every((p) => p.equipacion == defensas), isTrue, reason: 'Mutxigol ${mutxigol.name}');

      // Y se ve la imagen de Mutxigol con SU equipación.
      expect(
        imagenDe(ImagenesMutxigol.pose(mutxigol, PoseMutxigol.salto)),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
    }
  });
}
