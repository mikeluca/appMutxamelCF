import 'dart:async';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/models/imagenes_redes_model.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/widgets/imagenes_redes_vista.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/widgets/seccion_imagenes_redes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/imagenes_redes_soporte.dart';

Widget _seccion(
  ServicioImagenesFalso servicio, {
  String tipo = tipoImagenPrevia,
  String idioma = 'es',
  VoidCallback? alDenegar,
}) {
  return appDePrueba(
    Scaffold(
      body: SingleChildScrollView(
        child: SeccionImagenesRedes(
          servicio: servicio,
          viernes: viernesDePrueba,
          tipo: tipo,
          alDenegar: alDenegar,
        ),
      ),
    ),
    idioma: idioma,
  );
}

void main() {
  late List<
    ({List<Uint8List> pngs, List<String> nombres, String texto, Rect origen})
  >
  compartidos;

  setUp(() {
    compartidos = [];
    CompartirImagenesRedes.enviar = (pngs, nombres, texto, origen) async {
      compartidos.add((
        pngs: pngs,
        nombres: nombres,
        texto: texto,
        origen: origen,
      ));
    };
  });

  group('modelo', () {
    test('lee imágenes y textos, y filtra por tipo', () {
      final modelo = ImagenesRedesModel.fromJson({
        'desde': '2026-11-13',
        'hasta': '2026-11-15',
        'imagenes': [
          {
            'id': 1,
            'tipo': 'PREVIA',
            'modalidad': 'F11',
            'pagina': 1,
            'totalPaginas': 2,
            'version': 3,
            'fechaGeneracion': '2026-11-13T12:00:00',
          },
          {
            'id': 2,
            'tipo': 'RESULTADOS',
            'modalidad': 'F8',
            'pagina': 1,
            'totalPaginas': 1,
            'version': 1,
          },
        ],
        'textoPrevia': 'p',
        'textoResultados': 'r',
      });

      expect(modelo.desde, viernesDePrueba);
      expect(modelo.deTipo(tipoImagenPrevia).single.totalPaginas, 2);
      expect(modelo.deTipo(tipoImagenPrevia).single.version, 3);
      expect(modelo.deTipo(tipoImagenResultados).single.modalidad, 'F8');
      expect(modelo.textoDe(tipoImagenPrevia), 'p');
      expect(modelo.textoDe(tipoImagenResultados), 'r');
    });
  });

  group('sección de un tipo', () {
    testWidgets('sin imágenes de la previa ofrece "Generar ahora" y ya no dice '
        'que se generan solas', (tester) async {
      await tester.pumpWidget(_seccion(ServicioImagenesFalso()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Todavía no se han generado'), findsOneWidget);
      expect(find.textContaining('solas'), findsNothing);
      expect(find.text('Generar ahora'), findsOneWidget);
      // Solo el tipo de la pestaña
      expect(find.byKey(const ValueKey('generar-RESULTADOS')), findsNothing);
    });

    testWidgets('los resultados tienen su propio texto y su botón', (
      tester,
    ) async {
      await tester.pumpWidget(
        _seccion(ServicioImagenesFalso(), tipo: tipoImagenResultados),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('los resultados'), findsOneWidget);
      expect(find.byKey(const ValueKey('generar-RESULTADOS')), findsOneWidget);
      expect(find.byKey(const ValueKey('generar-PREVIA')), findsNothing);
    });

    testWidgets('pide las imágenes del fin de semana indicado', (tester) async {
      final servicio = ServicioImagenesFalso();

      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();

      expect(servicio.consultadas, [viernesDePrueba]);
    });

    testWidgets('"Generar ahora" genera ese tipo y enseña las miniaturas', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..trasRegenerar = modeloDePrueba([
          imagenDePrueba(1, 'PREVIA', 'F11', 1, 2),
          imagenDePrueba(2, 'PREVIA', 'F11', 2, 2),
          imagenDePrueba(3, 'PREVIA', 'F8', 1, 1),
        ]);

      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('generar-PREVIA')));
      await tester.pumpAndSettle();

      expect(servicio.regeneradas.single.tipo, 'PREVIA');
      expect(servicio.regeneradas.single.fecha, viernesDePrueba);
      expect(find.byKey(const ValueKey('imagen-redes-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('imagen-redes-3')), findsOneWidget);
      expect(find.text('Fútbol 11 1 de 2'), findsOneWidget);
      expect(find.text('Fútbol 8'), findsOneWidget);
      expect(find.text('Imágenes generadas'), findsOneWidget);
      expect(find.text('Volver a generar'), findsOneWidget);
    });

    testWidgets('si no hay partidos que mostrar lo dice', (tester) async {
      final servicio = ServicioImagenesFalso();

      await tester.pumpWidget(_seccion(servicio, tipo: tipoImagenResultados));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('generar-RESULTADOS')));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay partidos que mostrar en este fin de semana.'),
        findsOneWidget,
      );
    });

    testWidgets('un error al generar se avisa y se puede reintentar', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..falloRegenerar = Exception('sin red');

      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('generar-PREVIA')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(const ValueKey('generar-PREVIA')), findsOneWidget);
    });

    testWidgets('con imágenes el botón es "Volver a generar" y pide '
        'confirmación; al cancelar no genera', (tester) async {
      final servicio = ServicioImagenesFalso(
        actual: modeloDePrueba([imagenDePrueba(1, 'PREVIA', 'F11', 1, 1)]),
      );

      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();

      expect(find.text('Volver a generar'), findsOneWidget);
      expect(find.text('Generar ahora'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('generar-PREVIA')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Se sustituirán las imágenes actuales de este fin de semana por '
          'unas nuevas.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.regeneradas, isEmpty);
      expect(find.byKey(const ValueKey('imagen-redes-1')), findsOneWidget);
    });

    testWidgets('al confirmar regenera y las miniaturas son las nuevas', (
      tester,
    ) async {
      final servicio =
          ServicioImagenesFalso(
              actual: modeloDePrueba([
                imagenDePrueba(1, 'PREVIA', 'F11', 1, 1),
              ]),
            )
            ..trasRegenerar = modeloDePrueba([
              imagenDePrueba(7, 'PREVIA', 'F11', 1, 2, version: 2),
              imagenDePrueba(8, 'PREVIA', 'F11', 2, 2, version: 2),
            ]);

      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('generar-PREVIA')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar-regenerar-si')));
      await tester.pumpAndSettle();

      expect(servicio.regeneradas.single.fecha, viernesDePrueba);
      expect(find.byKey(const ValueKey('imagen-redes-1')), findsNothing);
      expect(find.byKey(const ValueKey('imagen-redes-7')), findsOneWidget);
      expect(servicio.descargadas, containsAll(['1:1', '7:2', '8:2']));
    });

    testWidgets('mismo id con otra versión: se vuelve a descargar el PNG', (
      tester,
    ) async {
      final servicio =
          ServicioImagenesFalso(
              actual: modeloDePrueba([
                imagenDePrueba(1, 'PREVIA', 'F11', 1, 1),
              ]),
            )
            ..trasRegenerar = modeloDePrueba([
              imagenDePrueba(1, 'PREVIA', 'F11', 1, 1, version: 2),
            ]);

      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('generar-PREVIA')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar-regenerar-si')));
      await tester.pumpAndSettle();

      expect(servicio.descargadas, ['1:1', '1:2']);
    });

    testWidgets('mientras genera, el botón está desactivado', (tester) async {
      final servicio = ServicioImagenesFalso(
        actual: modeloDePrueba([imagenDePrueba(1, 'PREVIA', 'F11', 1, 1)]),
      )..espera = Completer<void>();

      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('generar-PREVIA')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar-regenerar-si')));
      await tester.pump();

      expect(
        tester
            .widget<ButtonStyleButton>(
              find.byKey(const ValueKey('generar-PREVIA')),
            )
            .onPressed,
        isNull,
      );

      servicio.espera!.complete();
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<ButtonStyleButton>(
              find.byKey(const ValueKey('generar-PREVIA')),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('un error al volver a generar conserva las imágenes', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso(
        actual: modeloDePrueba([imagenDePrueba(1, 'PREVIA', 'F11', 1, 1)]),
      )..falloRegenerar = Exception('sin red');

      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('generar-PREVIA')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar-regenerar-si')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(const ValueKey('imagen-redes-1')), findsOneWidget);
    });

    testWidgets('un error al cargar se puede reintentar', (tester) async {
      final servicio = ServicioImagenesFalso()
        ..falloObtener = Exception('sin red');

      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();

      expect(
        find.text('No se han podido cargar las imágenes.'),
        findsOneWidget,
      );

      servicio.falloObtener = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Generar ahora'), findsOneWidget);
    });

    testWidgets('un 403 al cargar avisa a la pantalla', (tester) async {
      var denegados = 0;
      final servicio = ServicioImagenesFalso()
        ..falloObtener = const ApiException('No', statusCode: 403);

      await tester.pumpWidget(_seccion(servicio, alDenegar: () => denegados++));
      await tester.pumpAndSettle();

      expect(denegados, 1);
    });

    testWidgets('un 403 al generar avisa a la pantalla', (tester) async {
      var denegados = 0;
      final servicio = ServicioImagenesFalso()
        ..falloRegenerar = const ApiException('No', statusCode: 403);

      await tester.pumpWidget(_seccion(servicio, alDenegar: () => denegados++));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('generar-PREVIA')));
      await tester.pumpAndSettle();

      expect(denegados, 1);
      // No se enseña un error de red: lo gestiona la pantalla.
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('en catalán y en inglés', (tester) async {
      final servicio = ServicioImagenesFalso(
        actual: modeloDePrueba([imagenDePrueba(1, 'PREVIA', 'F11', 1, 1)]),
      );

      await tester.pumpWidget(_seccion(servicio, idioma: 'ca'));
      await tester.pumpAndSettle();
      expect(find.text('Torna a generar'), findsOneWidget);

      await tester.pumpWidget(_seccion(servicio, idioma: 'en'));
      await tester.pumpAndSettle();
      expect(find.text('Generate again'), findsOneWidget);
    });
  });

  group('vista previa', () {
    final imagenes = [
      imagenDePrueba(1, 'PREVIA', 'F11', 1, 2),
      imagenDePrueba(2, 'PREVIA', 'F11', 2, 2),
      imagenDePrueba(3, 'PREVIA', 'F8', 1, 1),
    ];

    Future<void> abrir(
      WidgetTester tester,
      ServicioImagenesFalso servicio,
    ) async {
      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('imagen-redes-2')));
      await tester.pumpAndSettle();
    }

    testWidgets('al pulsar una miniatura abre esa imagen a pantalla completa', (
      tester,
    ) async {
      await abrir(
        tester,
        ServicioImagenesFalso(actual: modeloDePrueba(imagenes)),
      );

      expect(find.byType(ImagenesRedesVistaPage), findsOneWidget);
      expect(find.text('Previa · Fútbol 11 2 de 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('vista-imagen-2')), findsOneWidget);
    });

    testWidgets('compartir envía todas las páginas juntas con el texto', (
      tester,
    ) async {
      await abrir(
        tester,
        ServicioImagenesFalso(actual: modeloDePrueba(imagenes)),
      );

      await tester.tap(find.byKey(const ValueKey('imagenes-compartir')));
      await tester.pumpAndSettle();

      expect(compartidos, hasLength(1));
      expect(compartidos.single.pngs, hasLength(3));
      expect(
        compartidos.single.origen,
        tester.getRect(find.byKey(const ValueKey('imagenes-compartir'))),
      );
      expect(compartidos.single.nombres, [
        'previa_f11_1.png',
        'previa_f11_2.png',
        'previa_f8_1.png',
      ]);
      expect(
        compartidos.single.texto,
        'Texto previa #somMTX #mareaAzul #MutxamelCF',
      );
    });

    testWidgets('si falla el menú de compartir, avisa', (tester) async {
      CompartirImagenesRedes.enviar = (_, _, _, _) async =>
          throw Exception('x');

      await abrir(
        tester,
        ServicioImagenesFalso(actual: modeloDePrueba(imagenes)),
      );

      await tester.tap(find.byKey(const ValueKey('imagenes-compartir')));
      await tester.pumpAndSettle();

      expect(
        find.text('No se han podido compartir las imágenes.'),
        findsOneWidget,
      );
    });

    testWidgets('copiar texto lo deja en el portapapeles', (tester) async {
      String? copiado;

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

      await abrir(
        tester,
        ServicioImagenesFalso(actual: modeloDePrueba(imagenes)),
      );

      await tester.tap(find.byKey(const ValueKey('imagenes-copiar')));
      await tester.pumpAndSettle();

      expect(copiado, 'Texto previa #somMTX #mareaAzul #MutxamelCF');
      expect(find.text('Texto copiado'), findsOneWidget);
    });

    testWidgets('regenerar pide ese tipo y fin de semana y actualiza las '
        'páginas', (tester) async {
      final servicio = ServicioImagenesFalso(actual: modeloDePrueba(imagenes))
        ..trasRegenerar = modeloDePrueba([
          imagenDePrueba(9, 'PREVIA', 'F11', 1, 1),
        ]);

      await abrir(tester, servicio);

      await tester.tap(find.byKey(const ValueKey('imagenes-regenerar')));
      await tester.pumpAndSettle();

      expect(servicio.regeneradas.single.tipo, 'PREVIA');
      expect(servicio.regeneradas.single.fecha, viernesDePrueba);
      expect(find.text('Imágenes generadas'), findsOneWidget);
      expect(find.byKey(const ValueKey('vista-imagen-9')), findsOneWidget);
    });

    testWidgets('los resultados comparten el texto de resultados', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso(
        actual: modeloDePrueba([imagenDePrueba(5, 'RESULTADOS', 'F8', 1, 1)]),
      );

      await tester.pumpWidget(_seccion(servicio, tipo: tipoImagenResultados));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('imagen-redes-5')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('imagenes-compartir')));
      await tester.pumpAndSettle();

      expect(
        compartidos.single.texto,
        'Texto resultados #somMTX #mareaAzul #MutxamelCF',
      );
      expect(compartidos.single.nombres, ['resultados_f8_1.png']);
    });
  });
}
