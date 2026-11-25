import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_mutxamel_cf/features/juego/logica/cabezazos_logica.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/widgets/escena_cabezazos.dart';
import 'package:app_mutxamel_cf/features/juego/widgets/siluetas_juego.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/juego_helpers.dart';

/// Pinta un defensa de 62 × 68 y devuelve una función para leer el color de un punto (fracciones del recuadro).
Future<Color Function(double, double)> _pintar(DefensaPainter pintor) async {
  const w = 62, h = 68;
  final grabador = ui.PictureRecorder();

  pintor.paint(Canvas(grabador), const Size(62, 68));

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

/// Una imagen lisa de 840 × 480 de ese color (una "camiseta" de prueba).
Future<ui.Image> _lisa(Color color) async {
  final grabador = ui.PictureRecorder();

  Canvas(grabador).drawRect(
    const Rect.fromLTWH(0, 0, 840, 480),
    Paint()..color = color,
  );

  return grabador.endRecording().toImage(840, 480);
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

  test('las camisetas de los defensas están declaradas en el pubspec y existen', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    for (final e in Equipacion.values) {
      final ruta = ImagenesMutxigol.camisetaDefensa(e);

      expect(ruta, 'assets/images/mutxigol/camiseta_defensa_${e.carpeta}.webp');
      expect(File(ruta).existsSync(), isTrue, reason: ruta);
      expect(pubspec, contains('- $ruta'), reason: ruta);
    }
  });

  for (final (equipacion, base, vivos) in [
    (Equipacion.rosa, const Color(0xFFE0359A), const Color(0xFFBDBDBD)),
    (Equipacion.azul, const Color(0xFF1E5BC6), const Color(0xFFFFFFFF)),
  ]) {
    test('sin la imagen cargada, un defensa ${equipacion.name} pinta la camiseta lisa del color base, sin excepciones', () async {
      final color = await _pintar(DefensaPainter(equipacion: equipacion));

      // Camiseta (lisa, también donde iría la franja), pantalón, medias y mangas del mismo color.
      expect(_casi(color(0.30, 0.50), base), isTrue, reason: 'camiseta');
      expect(_casi(color(0.55, 0.45), base), isTrue, reason: 'camiseta (donde iría la franja)');
      expect(_casi(color(0.50, 0.61), base), isTrue, reason: 'pantalón');
      expect(_casi(color(0.38, 0.78), base), isTrue, reason: 'media izquierda');
      expect(_casi(color(0.62, 0.78), base), isTrue, reason: 'media derecha');
      expect(_casi(color(0.15, 0.31), base), isTrue, reason: 'manga');

      // La línea fina entre camiseta y pantalón y el ribete de las mangas, en los vivos.
      expect(_casi(color(0.30, 0.551), vivos), isTrue, reason: 'línea fina');
      expect(_casi(color(0.15, 0.3897), vivos), isTrue, reason: 'ribete de la manga');
    });
  }

  testWidgets('con la imagen, la camiseta es la imagen (recortada en su recuadro) y lo demás, del color base', (tester) async {
    await tester.runAsync(() async {
      final verde = await _lisa(const Color(0xFF00C853));
      final color = await _pintar(DefensaPainter(equipacion: Equipacion.rosa, camiseta: verde));

      expect(_casi(color(0.50, 0.40), const Color(0xFF00C853)), isTrue, reason: 'camiseta = imagen');
      expect(_casi(color(0.30, 0.50), const Color(0xFF00C853)), isTrue);
      // Mangas, pantalón y medias siguen siendo del color base.
      expect(_casi(color(0.15, 0.31), KitDefensa.rosa.base), isTrue, reason: 'manga');
      expect(_casi(color(0.50, 0.61), KitDefensa.rosa.base), isTrue, reason: 'pantalón');
      expect(_casi(color(0.38, 0.78), KitDefensa.rosa.base), isTrue, reason: 'medias');
      // Y la línea fina de los vivos se queda.
      expect(_casi(color(0.30, 0.551), KitDefensa.rosa.vivos), isTrue, reason: 'línea fina');
      // Fuera del recuadro de la camiseta no se pinta la imagen.
      expect(_casi(color(0.12, 0.45), const Color(0xFF00C853)), isFalse);
    });
  });

  testWidgets('las imágenes reales se decodifican una vez (840 × 480) y se reutilizan', (tester) async {
    await tester.runAsync(() async {
      for (final e in Equipacion.values) {
        CamisetasDefensa.ponerParaTests(e, null);

        final primera = await CamisetasDefensa.cargar(e);

        expect(primera, isNotNull, reason: e.name);
        expect(primera!.width, 840);
        expect(primera.height, 480);
        // La segunda vez es la misma imagen: no se decodifica otra vez.
        expect(identical(await CamisetasDefensa.cargar(e), primera), isTrue);
        expect(identical(CamisetasDefensa.de(e), primera), isTrue);
      }
    });
  });

  testWidgets('el painter usa la camiseta de la equipación contraria: Mutxigol azul → rosa y al revés', (tester) async {
    await tester.runAsync(() async {
      await CamisetasDefensa.cargar(Equipacion.azul);
      await CamisetasDefensa.cargar(Equipacion.rosa);
    });

    final azul = CamisetasDefensa.de(Equipacion.azul)!;
    final rosa = CamisetasDefensa.de(Equipacion.rosa)!;

    expect(identical(azul, rosa), isFalse);

    for (final (mutxigol, defensas, esperada) in [
      (Equipacion.azul, Equipacion.rosa, rosa),
      (Equipacion.rosa, Equipacion.azul, azul),
    ]) {
      pantallaDeMovil(tester, alto: 640);

      final logica = CabezazosLogica(alto: 640);

      logica.tocar();
      logica.colocarBarrera(200, 250, 140);

      await tester.pumpWidget(
        appDePrueba(EscenaCabezazos(logica: logica, equipacion: mutxigol, activa: true)),
      );

      final pintores = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((c) => c.painter)
          .whereType<DefensaPainter>()
          .toList();

      expect(pintores, isNotEmpty);
      expect(pintores.every((p) => p.equipacion == defensas), isTrue, reason: 'Mutxigol ${mutxigol.name}');
      expect(
        pintores.every((p) => identical(p.camiseta, esperada)),
        isTrue,
        reason: 'Mutxigol ${mutxigol.name} → camiseta ${defensas.name}',
      );

      // Y se ve la imagen de Mutxigol con SU equipación.
      expect(imagenDe(ImagenesMutxigol.pose(mutxigol, PoseMutxigol.salto)), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    }
  });

  test('shouldRepaint también compara la imagen (y la ya dibujada)', () {
    const base = DefensaPainter(equipacion: Equipacion.rosa);

    expect(base.shouldRepaint(const DefensaPainter(equipacion: Equipacion.rosa)), isFalse);
    expect(base.shouldRepaint(const DefensaPainter(equipacion: Equipacion.azul)), isTrue);
  });

  testWidgets('shouldRepaint: otra camiseta o la caché que llega repinta', (tester) async {
    await tester.runAsync(() async {
      final a = await _lisa(const Color(0xFF111111));
      final b = await _lisa(const Color(0xFF222222));

      expect(DefensaPainter(camiseta: a).shouldRepaint(DefensaPainter(camiseta: a)), isFalse);
      expect(DefensaPainter(camiseta: a).shouldRepaint(DefensaPainter(camiseta: b)), isTrue);
      expect(DefensaPainter(camiseta: a).shouldRepaint(const DefensaPainter()), isTrue);
      expect(DefensaPainter(camiseta: a, cacheada: b).shouldRepaint(DefensaPainter(camiseta: a)), isTrue);
    });
  });

  testWidgets('la caché: el defensa se genera una vez a su tamaño en píxeles y luego se pinta con esa imagen', (tester) async {
    await tester.runAsync(() async {
      CacheDefensas.vaciar();

      final camiseta = await _lisa(const Color(0xFF00C853));

      // Sin imagen de camiseta no se cachea nada (saldría el respaldo liso).
      expect(CacheDefensas.obtener(Equipacion.rosa, 68, null), isNull);
      expect(CacheDefensas.generadas, 0);

      // La primera vez no está: se pone a generar.
      expect(CacheDefensas.obtener(Equipacion.rosa, 68, camiseta), isNull);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final hecha = CacheDefensas.obtener(Equipacion.rosa, 68, camiseta);

      expect(hecha, isNotNull);
      expect(hecha!.width, (62 * CacheDefensas.pixelesPorUnidad).ceil());
      expect(hecha.height, (68 * CacheDefensas.pixelesPorUnidad).ceil());
      // Alturas parecidas comparten imagen (se agrupan de 2 en 2).
      expect(identical(CacheDefensas.obtener(Equipacion.rosa, 67.4, camiseta), hecha), isTrue);
      expect(CacheDefensas.generadas, 1);

      // Pintar con la caché da lo mismo que dibujar directamente.
      final directo = await _pintar(DefensaPainter(equipacion: Equipacion.rosa, camiseta: camiseta));
      final cacheado = await _pintar(
        DefensaPainter(equipacion: Equipacion.rosa, camiseta: camiseta, cacheada: hecha),
      );

      for (final (x, y) in [(0.5, 0.40), (0.15, 0.31), (0.5, 0.61), (0.38, 0.78)]) {
        expect(_casi(cacheado(x, y), directo(x, y)), isTrue, reason: 'punto ($x, $y)');
      }

      CacheDefensas.vaciar();
    });
  });
}
