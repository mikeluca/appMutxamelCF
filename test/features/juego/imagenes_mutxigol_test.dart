import 'dart:io';

import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las imágenes del juego: las poses nuevas están (en las dos equipaciones) y las de los juegos que ya no existen
/// (portero, parada, chutando, toques, corriendo, espalda) ni están ni se referencian.
void main() {
  const antiguas = ['portero', 'parada', 'chutando', 'toques', 'corriendo', 'espalda'];

  final carpeta = Directory('assets/images/mutxigol');

  test('cada pose existe en azul y en rosa, y está el balón', () {
    for (final equipacion in Equipacion.values) {
      for (final pose in PoseMutxigol.values) {
        expect(
          File(ImagenesMutxigol.pose(equipacion, pose)).existsSync(),
          isTrue,
          reason: '${equipacion.carpeta}/${pose.fichero}',
        );
      }
    }

    expect(File(ImagenesMutxigol.balon).existsSync(), isTrue);
    expect(File(ImagenesMutxigol.escudoClub).existsSync(), isTrue);
  });

  test('las poses son las 6 de ahora: parado, atrapando, celebrando, triste, cara y salto', () {
    expect(PoseMutxigol.values.map((p) => p.fichero).toSet(), {
      'mutxigol_parado',
      'mutxigol_atrapando',
      'mutxigol_celebrando',
      'mutxigol_triste',
      'mutxigol_cara',
      'mutxigol_salto',
    });
  });

  test('la carpeta no tiene ninguna imagen de más: solo esas poses y el balón', () {
    final ficheros = carpeta
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.replaceAll('\\', '/').split('assets/images/mutxigol/').last)
        .toSet();

    final esperados = {
      'balon.webp',
      for (final e in Equipacion.values)
        for (final p in PoseMutxigol.values) '${e.carpeta}/${p.fichero}.webp',
    };

    expect(ficheros, esperados);

    for (final f in ficheros) {
      for (final vieja in antiguas) {
        expect(f, isNot(contains(vieja)));
      }
    }
  });

  test('el código del juego no referencia las imágenes ni las poses antiguas', () {
    final fuentes = [
      ...Directory('lib/features/juego').listSync(recursive: true).whereType<File>(),
      File('lib/features/public/public_shell_page.dart'),
    ];

    for (final f in fuentes) {
      final texto = f.readAsStringSync();

      for (final vieja in antiguas) {
        expect(texto, isNot(contains('mutxigol_$vieja')), reason: '${f.path} → $vieja');
        expect(texto, isNot(contains('PoseMutxigol.$vieja')), reason: '${f.path} → $vieja');
      }

      expect(texto, isNot(contains('Juego.penaltis')), reason: f.path);
      expect(texto, isNot(contains('Juego.toques')), reason: f.path);
      expect(texto, isNot(contains('Juego.regatea')), reason: f.path);
      expect(texto.toLowerCase(), isNot(contains('regatea')), reason: f.path);
    }
  });

  test('el pubspec registra las dos carpetas y el balón', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('assets/images/mutxigol/balon.webp'));
    expect(pubspec, contains('assets/images/mutxigol/azul/'));
    expect(pubspec, contains('assets/images/mutxigol/rosa/'));
    expect(pubspec, contains('version: 1.0.16+25'));
  });
}
