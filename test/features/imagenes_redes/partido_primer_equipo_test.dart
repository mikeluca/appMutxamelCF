import 'dart:async';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/models/partido_primer_equipo_model.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/pages/imagenes_redes_page.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/widgets/imagenes_redes_vista.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/imagenes_redes_soporte.dart';

Widget _pagina(
  ServicioImagenesFalso servicio, {
  String idioma = 'es',
  ThemeData? tema,
}) {
  return appDePrueba(
    ImagenesRedesPage(
      servicio: servicio,
      tipoInicial: tipoImagenPartidoPrimerEquipo,
      ahora: () => DateTime(2026, 11, 18, 10),
    ),
    idioma: idioma,
    tema: tema,
  );
}

Future<void> _abrir(
  WidgetTester tester,
  ServicioImagenesFalso servicio, {
  String idioma = 'es',
}) async {
  await tester.pumpWidget(_pagina(servicio, idioma: idioma));
  await tester.pumpAndSettle();
}

Finder _clave(String clave) => find.byKey(ValueKey(clave));

Future<void> _tocar(WidgetTester tester, String clave) async {
  await tester.ensureVisible(_clave(clave));
  await tester.pumpAndSettle();
  await tester.tap(_clave(clave));
  await tester.pumpAndSettle();
}

/// Elige un segmento de un SegmentedButton por su texto.
Future<void> _segmento(WidgetTester tester, String clave, String texto) async {
  await tester.ensureVisible(_clave(clave));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: _clave(clave), matching: find.text(texto)),
  );
  await tester.pumpAndSettle();
}

void main() {
  late List<
    ({List<Uint8List> pngs, List<String> nombres, String texto, Rect origen})
  >
  compartidos;
  String? copiado;

  setUp(() {
    compartidos = [];
    copiado = null;
    CompartirImagenesRedes.enviar = (pngs, nombres, texto, origen) async {
      compartidos.add((
        pngs: pngs,
        nombres: nombres,
        texto: texto,
        origen: origen,
      ));
    };
  });

  void simularPortapapeles(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiado = (call.arguments as Map)['text'] as String?;
        }

        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  group('modelo', () {
    test('lee el partido disponible', () {
      final partido = PartidoPrimerEquipoModel.fromJson({
        'disponible': true,
        'motivo': null,
        'partidoId': 30,
        'local': false,
        'rival': 'Pego',
        'escudoRivalUrl': '/api/public/escudos-rivales/40?v=2',
        'dia': '2026-11-21',
        'hora': '17:30',
        'campo': 'Les Costeres Gata',
        'competicion': 'Primera FFCV, Grup 4',
        'jornada': 11,
        'tipo': 'LIGA',
        'textoPublicacion': {'es': 'texto es', 'ca': 'text ca'},
      });

      expect(partido.disponible, isTrue);
      expect(partido.local, isFalse);
      expect(partido.rival, 'Pego');
      expect(partido.dia, DateTime(2026, 11, 21));
      expect(partido.hora, '17:30');
      expect(partido.jornada, 11);
      expect(partido.textoDe(IdiomaCartel.es), 'texto es');
      expect(partido.textoDe(IdiomaCartel.ca), 'text ca');
    });

    test('lee el no disponible con su motivo', () {
      final partido = PartidoPrimerEquipoModel.fromJson({
        'disponible': false,
        'motivo': 'YA_EMPEZADO',
      });

      expect(partido.disponible, isFalse);
      expect(partido.motivo, motivoYaEmpezado);
      expect(partido.rival, isEmpty);
      expect(partido.dia, isNull);
    });

    test('las opciones arman la consulta del PNG', () {
      expect(
        const OpcionesCartel().consulta,
        '?formato=PUBLICACION&idioma=es&racha=true&qr=true&hashtags=true',
      );
      expect(
        const OpcionesCartel(
          formato: FormatoCartel.historia,
          idioma: IdiomaCartel.ca,
          racha: false,
          qr: false,
          hashtags: false,
        ).consulta,
        '?formato=HISTORIA&idioma=ca&racha=false&qr=false&hashtags=false',
      );
    });

    test('las proporciones son las de 1080x1350 y 1080x1920', () {
      expect(FormatoCartel.publicacion.proporcion, closeTo(1080 / 1350, 1e-9));
      expect(FormatoCartel.historia.proporcion, closeTo(1080 / 1920, 1e-9));
    });

    test('quita los hashtags del texto', () {
      expect(
        textoSinHashtags(textoEsDePrueba),
        'Próximo partido: Mutxamel C.F. – Salesianos. Sábado 21/11 a las 17:30, '
        'Camp Nou Los Olmos (Mutxamel). ¡Os esperamos!',
      );
      expect(textoSinHashtags('Sin hashtags'), 'Sin hashtags');
    });
  });

  group('el partido', () {
    testWidgets('disponible: escudos, rival, día y hora, campo y competición', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso();

      await _abrir(tester, servicio);

      expect(servicio.partidosPedidos, 1);
      expect(_clave('cartel-tarjeta-partido'), findsOneWidget);
      expect(find.text('Salesianos Alicante'), findsOneWidget);
      expect(find.text('Mutxamel C.F.'), findsOneWidget);
      expect(find.text('21/11/2026 · 17:30'), findsOneWidget);
      expect(find.text('Camp Nou Los Olmos (Mutxamel)'), findsOneWidget);
      expect(find.text('Primera FFCV, Grup 4 · Jornada 11'), findsOneWidget);
      expect(_clave('cartel-generar'), findsOneWidget);
      expect(_clave('cartel-compartir'), findsOneWidget);
      expect(_clave('cartel-copiar'), findsOneWidget);
      // Sin generar todavía no hay imagen ni se ha pedido nada.
      expect(_clave('cartel-png'), findsNothing);
      expect(servicio.carteles, isEmpty);
    });

    testWidgets('sin jornada ni competición no salen líneas vacías', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso(
        partido: const PartidoPrimerEquipoModel(
          disponible: true,
          rival: 'Pego',
        ),
      );

      await _abrir(tester, servicio);

      expect(_clave('cartel-competicion'), findsNothing);
      expect(_clave('cartel-campo'), findsNothing);
      expect(_clave('cartel-fecha'), findsNothing);
    });

    testWidgets('SIN_PARTIDO: mensaje claro y sin botones', (tester) async {
      await _abrir(
        tester,
        ServicioImagenesFalso(
          partido: const PartidoPrimerEquipoModel(
            disponible: false,
            motivo: motivoSinPartido,
          ),
        ),
      );

      expect(
        find.text('No hay ningún próximo partido del Primer Equipo'),
        findsOneWidget,
      );
      expect(_clave('cartel-generar'), findsNothing);
      expect(_clave('cartel-compartir'), findsNothing);
      expect(_clave('cartel-copiar'), findsNothing);
      expect(_clave('cartel-formato'), findsNothing);
    });

    testWidgets('YA_EMPEZADO: mensaje claro y sin botones', (tester) async {
      await _abrir(
        tester,
        ServicioImagenesFalso(
          partido: const PartidoPrimerEquipoModel(
            disponible: false,
            motivo: motivoYaEmpezado,
          ),
        ),
      );

      expect(find.text('El partido ya ha empezado'), findsOneWidget);
      expect(_clave('cartel-generar'), findsNothing);
      expect(_clave('cartel-compartir'), findsNothing);
      expect(_clave('cartel-copiar'), findsNothing);
    });

    testWidgets('un error al cargar el partido se puede reintentar', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..falloPartido = Exception('sin red');

      await _abrir(tester, servicio);

      expect(
        find.text('No se ha podido cargar el próximo partido.'),
        findsOneWidget,
      );

      servicio.falloPartido = null;
      await _tocar(tester, 'cartel-reintentar-partido');

      expect(_clave('cartel-tarjeta-partido'), findsOneWidget);
      expect(servicio.partidosPedidos, 2);
    });

    testWidgets('textos en catalán y en inglés', (tester) async {
      await _abrir(tester, ServicioImagenesFalso(), idioma: 'ca');

      expect(find.text('Idioma del cartell'), findsOneWidget);
      expect(find.text('Castellà'), findsOneWidget);
      expect(find.text('Valencià'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await _abrir(tester, ServicioImagenesFalso(), idioma: 'en');

      expect(find.text('Poster language'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
      expect(find.text('Generate'), findsOneWidget);
    });
  });

  group('opciones y generar', () {
    testWidgets('por defecto: Publicación, castellano y los tres chips '
        'marcados', (tester) async {
      await _abrir(tester, ServicioImagenesFalso());

      expect(find.text('Formato'), findsOneWidget);
      expect(find.text('Publicación'), findsOneWidget);
      expect(find.text('Historia'), findsOneWidget);
      expect(find.text('Castellano'), findsOneWidget);
      expect(find.text('Valencià'), findsOneWidget);

      for (final chip in ['racha', 'qr', 'hashtags']) {
        await tester.ensureVisible(_clave('cartel-opcion-$chip'));
        expect(
          tester.widget<FilterChip>(_clave('cartel-opcion-$chip')).selected,
          isTrue,
          reason: chip,
        );
      }
    });

    testWidgets('Generar pide el PNG con las opciones por defecto', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso();

      await _abrir(tester, servicio);
      await _tocar(tester, 'cartel-generar');

      expect(servicio.carteles, [const OpcionesCartel()]);
      expect(_clave('cartel-png'), findsOneWidget);
    });

    testWidgets('Generar envía formato, idioma y chips elegidos', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso();

      await _abrir(tester, servicio);
      await _segmento(tester, 'cartel-formato', 'Historia');
      await _segmento(tester, 'cartel-idioma', 'Valencià');
      await _tocar(tester, 'cartel-opcion-racha');
      await _tocar(tester, 'cartel-opcion-qr');
      await _tocar(tester, 'cartel-opcion-hashtags');
      await _tocar(tester, 'cartel-generar');

      expect(servicio.carteles, [
        const OpcionesCartel(
          formato: FormatoCartel.historia,
          idioma: IdiomaCartel.ca,
          racha: false,
          qr: false,
          hashtags: false,
        ),
      ]);
    });

    testWidgets('cada chip se envía por separado', (tester) async {
      final servicio = ServicioImagenesFalso();

      await _abrir(tester, servicio);
      await _tocar(tester, 'cartel-opcion-qr');
      await _tocar(tester, 'cartel-generar');

      expect(servicio.carteles.single.qr, isFalse);
      expect(servicio.carteles.single.racha, isTrue);
      expect(servicio.carteles.single.hashtags, isTrue);
    });

    testWidgets('al cambiar una opción no se pide el PNG: la imagen queda '
        'desactualizada hasta volver a generar', (tester) async {
      final servicio = ServicioImagenesFalso();

      await _abrir(tester, servicio);
      await _tocar(tester, 'cartel-generar');

      expect(_clave('cartel-desactualizada'), findsNothing);

      await _tocar(tester, 'cartel-opcion-qr');
      await _segmento(tester, 'cartel-formato', 'Historia');
      await _tocar(tester, 'cartel-opcion-racha');

      // Tres cambios y ninguna petición nueva
      expect(servicio.carteles, hasLength(1));
      expect(_clave('cartel-desactualizada'), findsOneWidget);
      expect(
        find.text('Desactualizada: pulsa Generar para ver los cambios'),
        findsOneWidget,
      );
      // La imagen anterior se sigue viendo, con su proporción
      expect(_clave('cartel-png'), findsOneWidget);
      expect(_clave('cartel-imagen-PUBLICACION'), findsOneWidget);

      await _tocar(tester, 'cartel-generar');

      expect(servicio.carteles, hasLength(2));
      expect(_clave('cartel-desactualizada'), findsNothing);
      expect(_clave('cartel-imagen-HISTORIA'), findsOneWidget);
    });

    testWidgets('volver a dejar las opciones como estaban quita el aviso', (
      tester,
    ) async {
      await _abrir(tester, ServicioImagenesFalso());
      await _tocar(tester, 'cartel-generar');
      await _tocar(tester, 'cartel-opcion-qr');

      expect(_clave('cartel-desactualizada'), findsOneWidget);

      await _tocar(tester, 'cartel-opcion-qr');

      expect(_clave('cartel-desactualizada'), findsNothing);
    });

    testWidgets('la imagen se ve con la proporción del formato', (
      tester,
    ) async {
      await _abrir(tester, ServicioImagenesFalso());
      await _segmento(tester, 'cartel-formato', 'Historia');
      await _tocar(tester, 'cartel-generar');

      final caja = tester.getSize(_clave('cartel-imagen-HISTORIA'));

      expect(caja.width / caja.height, closeTo(1080 / 1920, 0.01));
    });

    testWidgets('mientras carga hay un indicador y no se puede pulsar otra '
        'vez Generar', (tester) async {
      final servicio = ServicioImagenesFalso()
        ..esperaCartel = Completer<void>();

      await _abrir(tester, servicio);

      await tester.ensureVisible(_clave('cartel-generar'));
      await tester.tap(_clave('cartel-generar'));
      await tester.pump();
      await tester.pump();

      expect(_clave('cartel-cargando'), findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(_clave('cartel-generar')).onPressed,
        isNull,
      );

      servicio.esperaCartel!.complete();
      await tester.pumpAndSettle();

      expect(_clave('cartel-cargando'), findsNothing);
      expect(_clave('cartel-png'), findsOneWidget);
      expect(servicio.carteles, hasLength(1));
    });

    testWidgets('si falla, el error sale en texto claro con Reintentar', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..fallosCartel.add(Exception('sin red'));

      await _abrir(tester, servicio);
      await _tocar(tester, 'cartel-generar');

      expect(find.text('No se ha podido generar el cartel.'), findsOneWidget);
      expect(_clave('cartel-png'), findsNothing);

      await _tocar(tester, 'cartel-reintentar');

      expect(servicio.carteles, hasLength(2));
      expect(find.text('No se ha podido generar el cartel.'), findsNothing);
      expect(_clave('cartel-png'), findsOneWidget);
    });

    testWidgets('un fallo con una imagen ya generada la conserva', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso();

      await _abrir(tester, servicio);
      await _tocar(tester, 'cartel-generar');

      servicio.fallosCartel.add(Exception('sin red'));
      await _tocar(tester, 'cartel-opcion-qr');
      await _tocar(tester, 'cartel-generar');

      expect(_clave('cartel-error'), findsOneWidget);
      expect(_clave('cartel-png'), findsOneWidget);
    });

    testWidgets('un 409 (el partido ya empezó) vuelve a preguntar por el '
        'partido y deja de ofrecer botones', (tester) async {
      final servicio = ServicioImagenesFalso()
        ..fallosCartel.add(
          const ApiException(
            'El cartel no está disponible',
            statusCode: 409,
            datos: {'codigo': 'YA_EMPEZADO'},
          ),
        );

      await _abrir(tester, servicio);

      servicio.partido = const PartidoPrimerEquipoModel(
        disponible: false,
        motivo: motivoYaEmpezado,
      );
      await _tocar(tester, 'cartel-generar');

      expect(servicio.partidosPedidos, 2);
      expect(find.text('El partido ya ha empezado'), findsOneWidget);
      expect(_clave('cartel-generar'), findsNothing);
    });
  });

  group('Compartir y Copiar texto', () {
    testWidgets('Compartir envía el PNG con su texto, con hashtags', (
      tester,
    ) async {
      await _abrir(tester, ServicioImagenesFalso());

      // Sin imagen generada no se puede compartir
      expect(
        tester.widget<ButtonStyleButton>(_clave('cartel-compartir')).onPressed,
        isNull,
      );

      await _tocar(tester, 'cartel-generar');
      await _tocar(tester, 'cartel-compartir');

      expect(compartidos, hasLength(1));
      expect(compartidos.single.pngs.single, pngDePrueba);
      expect(compartidos.single.nombres, [
        'cartel_primer_equipo_publicacion.png',
      ]);
      expect(compartidos.single.texto, textoEsDePrueba);
      // El menú de compartir (iPad) se ancla al botón
      expect(compartidos.single.origen.isEmpty, isFalse);
    });

    testWidgets('Compartir sin hashtags quita los hashtags del texto', (
      tester,
    ) async {
      await _abrir(tester, ServicioImagenesFalso());
      await _tocar(tester, 'cartel-opcion-hashtags');
      await _tocar(tester, 'cartel-generar');
      await _tocar(tester, 'cartel-compartir');

      expect(compartidos.single.texto, isNot(contains('#')));
      expect(compartidos.single.texto, endsWith('¡Os esperamos!'));
    });

    testWidgets('Compartir en valenciano comparte el texto en valenciano', (
      tester,
    ) async {
      await _abrir(tester, ServicioImagenesFalso());
      await _segmento(tester, 'cartel-idioma', 'Valencià');
      await _segmento(tester, 'cartel-formato', 'Historia');
      await _tocar(tester, 'cartel-generar');
      await _tocar(tester, 'cartel-compartir');

      expect(compartidos.single.texto, textoCaDePrueba);
      expect(compartidos.single.nombres, ['cartel_primer_equipo_historia.png']);
    });

    testWidgets('con la imagen desactualizada no se puede compartir', (
      tester,
    ) async {
      await _abrir(tester, ServicioImagenesFalso());
      await _tocar(tester, 'cartel-generar');
      await _tocar(tester, 'cartel-opcion-qr');

      expect(
        tester.widget<ButtonStyleButton>(_clave('cartel-compartir')).onPressed,
        isNull,
      );
      expect(compartidos, isEmpty);
    });

    testWidgets('si falla el menú de compartir, avisa', (tester) async {
      CompartirImagenesRedes.enviar = (_, _, _, _) async =>
          throw Exception('x');

      await _abrir(tester, ServicioImagenesFalso());
      await _tocar(tester, 'cartel-generar');
      await _tocar(tester, 'cartel-compartir');

      expect(
        find.text('No se han podido compartir las imágenes.'),
        findsOneWidget,
      );
    });

    testWidgets('Copiar texto copia el texto del idioma elegido con hashtags', (
      tester,
    ) async {
      simularPortapapeles(tester);

      await _abrir(tester, ServicioImagenesFalso());
      // No hace falta haber generado la imagen
      await _tocar(tester, 'cartel-copiar');

      expect(copiado, textoEsDePrueba);
      expect(find.text('Texto copiado'), findsOneWidget);

      await _segmento(tester, 'cartel-idioma', 'Valencià');
      // El aviso de "Texto copiado" tapa el botón hasta que desaparece.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tocar(tester, 'cartel-copiar');

      expect(copiado, textoCaDePrueba);
    });

    testWidgets('Copiar texto quita los hashtags si están desmarcados', (
      tester,
    ) async {
      simularPortapapeles(tester);

      await _abrir(tester, ServicioImagenesFalso());
      await _tocar(tester, 'cartel-opcion-hashtags');
      await _tocar(tester, 'cartel-copiar');

      expect(copiado, isNot(contains('#')));
      expect(copiado, endsWith('¡Os esperamos!'));

      await _segmento(tester, 'cartel-idioma', 'Valencià');
      // El aviso de "Texto copiado" tapa el botón hasta que desaparece.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tocar(tester, 'cartel-copiar');

      expect(copiado, isNot(contains('#')));
      expect(copiado, endsWith('Us esperem!'));
    });
  });

  group('403 y no guardar nada', () {
    testWidgets('un 403 al generar avisa y vuelve atrás', (tester) async {
      final servicio = ServicioImagenesFalso()
        ..fallosCartel.add(const ApiException('No', statusCode: 403));

      await tester.pumpWidget(
        appDePrueba(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImagenesRedesPage(
                      servicio: servicio,
                      tipoInicial: tipoImagenPartidoPrimerEquipo,
                    ),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await _tocar(tester, 'cartel-generar');

      expect(find.byType(ImagenesRedesPage), findsNothing);
      expect(
        find.text('Ya no tienes permiso para ver las imágenes para redes'),
        findsOneWidget,
      );
    });

    test('las opciones siempre empiezan por defecto: no se guardan', () {
      // El estado de las opciones es solo del widget: ni preferencias ni disco.
      expect(const OpcionesCartel(), const OpcionesCartel().copiaCon());
      expect(const OpcionesCartel().racha, isTrue);
      expect(const OpcionesCartel().qr, isTrue);
      expect(const OpcionesCartel().hashtags, isTrue);
    });
  });

  group('visual', () {
    testWidgets('en iPhone pequeño, con letra grande y en modo oscuro, con la '
        'imagen generada, no desborda', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final servicio = ServicioImagenesFalso(
        partido: partidoDePrueba(local: false),
      );

      await tester.pumpWidget(_pagina(servicio, tema: ThemeData.dark()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await _tocar(tester, 'cartel-generar');
      await _segmento(tester, 'cartel-formato', 'Historia');

      expect(tester.takeException(), isNull);
      expect(_clave('cartel-desactualizada'), findsOneWidget);
    });
  });
}
