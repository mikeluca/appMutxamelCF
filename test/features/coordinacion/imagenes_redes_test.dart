import 'dart:convert';

import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/features/coordinacion/models/coordinacion_model.dart';
import 'package:app_mutxamel_cf/features/coordinacion/models/imagenes_redes_model.dart';
import 'package:app_mutxamel_cf/features/coordinacion/pages/fin_de_semana_page.dart';
import 'package:app_mutxamel_cf/features/coordinacion/services/coordinacion_service.dart';
import 'package:app_mutxamel_cf/features/coordinacion/services/imagenes_redes_service.dart';
import 'package:app_mutxamel_cf/features/coordinacion/widgets/imagenes_redes_vista.dart';
import 'package:app_mutxamel_cf/features/coordinacion/widgets/seccion_imagenes_redes.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un PNG de 1x1 píxel.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

final DateTime _viernes = DateTime(2026, 11, 13);

ImagenRedesModel _imagen(
  int id,
  String tipo,
  String modalidad,
  int pagina,
  int total,
) {
  return ImagenRedesModel(
    id: id,
    tipo: tipo,
    modalidad: modalidad,
    pagina: pagina,
    totalPaginas: total,
    version: 1,
  );
}

ImagenesRedesModel _modelo(List<ImagenRedesModel> imagenes) {
  return ImagenesRedesModel(
    desde: _viernes,
    hasta: DateTime(2026, 11, 15),
    imagenes: imagenes,
    textoPrevia: 'Texto previa #somMTX #mareaAzul #MutxamelCF',
    textoResultados: 'Texto resultados #somMTX #mareaAzul #MutxamelCF',
  );
}

class _Servicio extends ImagenesRedesService {
  ImagenesRedesModel actual;
  ImagenesRedesModel? trasRegenerar;
  final List<({String tipo, DateTime? fecha})> regeneradas = [];
  Object? fallo;

  _Servicio(this.actual);

  @override
  Future<ImagenesRedesModel> obtener({DateTime? fecha}) async => actual;

  @override
  Future<Uint8List> descargarPng(ImagenRedesModel imagen) async => _png;

  @override
  Future<ImagenesRedesModel> regenerar({
    required String tipo,
    DateTime? fecha,
  }) async {
    regeneradas.add((tipo: tipo, fecha: fecha));

    if (fallo != null) throw fallo!;

    actual = trasRegenerar ?? actual;

    return actual;
  }
}

class _Coordinacion extends CoordinacionService {
  @override
  Future<FinDeSemanaModel> obtenerFinDeSemana({DateTime? fecha}) async {
    return FinDeSemanaModel(
      desde: _viernes,
      hasta: DateTime(2026, 11, 15),
      sinConvocatoria: const [],
      resultadosPendientes: const [],
      descansan: const [],
      sinPartido: const [],
      ultimaImportacionFfcv: null,
    );
  }
}

Widget _app(Widget hijo, {String idioma = 'es'}) {
  return MaterialApp(
    locale: Locale(idioma),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: hijo,
  );
}

Widget _seccion(_Servicio servicio) {
  return _app(
    Scaffold(
      body: SingleChildScrollView(
        child: SeccionImagenesRedes(servicio: servicio, viernes: _viernes),
      ),
    ),
  );
}

void main() {
  late List<({List<Uint8List> pngs, List<String> nombres, String texto})>
  compartidos;

  setUp(() {
    compartidos = [];
    CompartirImagenesRedes.enviar = (pngs, nombres, texto) async {
      compartidos.add((pngs: pngs, nombres: nombres, texto: texto));
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

      expect(modelo.desde, _viernes);
      expect(modelo.deTipo(tipoImagenPrevia).single.totalPaginas, 2);
      expect(modelo.deTipo(tipoImagenPrevia).single.version, 3);
      expect(modelo.deTipo(tipoImagenResultados).single.modalidad, 'F8');
      expect(modelo.textoDe(tipoImagenPrevia), 'p');
      expect(modelo.textoDe(tipoImagenResultados), 'r');
    });
  });

  group('sección "Imágenes para redes"', () {
    testWidgets('sin imágenes dice cuándo se generan y ofrece "Generar ahora"', (
      tester,
    ) async {
      await tester.pumpWidget(_seccion(_Servicio(_modelo(const []))));
      await tester.pumpAndSettle();

      expect(find.text('Imágenes para redes'), findsOneWidget);
      expect(
        find.text(
          'Todavía no se han generado. Se generan solas los viernes a las 12:00.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Todavía no se han generado. Se generan solas los lunes a las 09:00.',
        ),
        findsOneWidget,
      );
      expect(find.text('Generar ahora'), findsNWidgets(2));
    });

    testWidgets('"Generar ahora" genera ese tipo y enseña las miniaturas', (
      tester,
    ) async {
      final servicio = _Servicio(_modelo(const []))
        ..trasRegenerar = _modelo([
          _imagen(1, 'PREVIA', 'F11', 1, 2),
          _imagen(2, 'PREVIA', 'F11', 2, 2),
          _imagen(3, 'PREVIA', 'F8', 1, 1),
        ]);

      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('generar-PREVIA')));
      await tester.pumpAndSettle();

      expect(servicio.regeneradas.single.tipo, 'PREVIA');
      expect(servicio.regeneradas.single.fecha, _viernes);
      expect(find.byKey(const ValueKey('imagen-redes-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('imagen-redes-3')), findsOneWidget);
      expect(find.text('Fútbol 11 1 de 2'), findsOneWidget);
      expect(find.text('Fútbol 8'), findsOneWidget);
      // Los resultados siguen sin generar.
      expect(find.byKey(const ValueKey('generar-RESULTADOS')), findsOneWidget);
      expect(find.text('Imágenes generadas'), findsOneWidget);
    });

    testWidgets('si no hay partidos que mostrar lo dice', (tester) async {
      final servicio = _Servicio(_modelo(const []));

      await tester.pumpWidget(_seccion(servicio));
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
      final servicio = _Servicio(_modelo(const []))
        ..fallo = Exception('sin red');

      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('generar-PREVIA')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(const ValueKey('generar-PREVIA')), findsOneWidget);
    });

    testWidgets('también sale en catalán', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SeccionImagenesRedes(
              servicio: _Servicio(_modelo(const [])),
              viernes: _viernes,
            ),
          ),
          idioma: 'ca',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Imatges per a xarxes'), findsOneWidget);
      expect(find.text('Generar ara'), findsNWidgets(2));
    });
  });

  group('vista previa', () {
    final imagenes = [
      _imagen(1, 'PREVIA', 'F11', 1, 2),
      _imagen(2, 'PREVIA', 'F11', 2, 2),
      _imagen(3, 'PREVIA', 'F8', 1, 1),
    ];

    Future<void> abrir(WidgetTester tester, _Servicio servicio) async {
      await tester.pumpWidget(_seccion(servicio));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('imagen-redes-2')));
      await tester.pumpAndSettle();
    }

    testWidgets('al pulsar una miniatura abre esa imagen a pantalla completa', (
      tester,
    ) async {
      await abrir(tester, _Servicio(_modelo(imagenes)));

      expect(find.byType(ImagenesRedesVistaPage), findsOneWidget);
      expect(find.text('Previa · Fútbol 11 2 de 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('vista-imagen-2')), findsOneWidget);
    });

    testWidgets('compartir envía todas las páginas juntas con el texto', (
      tester,
    ) async {
      await abrir(tester, _Servicio(_modelo(imagenes)));

      await tester.tap(find.byKey(const ValueKey('imagenes-compartir')));
      await tester.pumpAndSettle();

      expect(compartidos, hasLength(1));
      expect(compartidos.single.pngs, hasLength(3));
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
      CompartirImagenesRedes.enviar = (_, _, _) async => throw Exception('x');

      await abrir(tester, _Servicio(_modelo(imagenes)));

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

      await abrir(tester, _Servicio(_modelo(imagenes)));

      await tester.tap(find.byKey(const ValueKey('imagenes-copiar')));
      await tester.pumpAndSettle();

      expect(copiado, 'Texto previa #somMTX #mareaAzul #MutxamelCF');
      expect(find.text('Texto copiado'), findsOneWidget);
    });

    testWidgets(
      'regenerar pide ese tipo y fin de semana y actualiza las páginas',
      (tester) async {
        final servicio = _Servicio(_modelo(imagenes))
          ..trasRegenerar = _modelo([_imagen(9, 'PREVIA', 'F11', 1, 1)]);

        await abrir(tester, servicio);

        await tester.tap(find.byKey(const ValueKey('imagenes-regenerar')));
        await tester.pumpAndSettle();

        expect(servicio.regeneradas.single.tipo, 'PREVIA');
        expect(servicio.regeneradas.single.fecha, _viernes);
        expect(find.text('Imágenes generadas'), findsOneWidget);
        expect(find.byKey(const ValueKey('vista-imagen-9')), findsOneWidget);
        expect(find.text('Previa · Fútbol 11'), findsOneWidget);
      },
    );

    testWidgets('los resultados comparten el texto de resultados', (
      tester,
    ) async {
      final servicio = _Servicio(
        _modelo([_imagen(5, 'RESULTADOS', 'F8', 1, 1)]),
      );

      await tester.pumpWidget(_seccion(servicio));
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

  group('panel Fin de semana', () {
    testWidgets('lleva la sección "Imágenes para redes" del fin de semana', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          FinDeSemanaPage(
            servicio: _Coordinacion(),
            imagenesServicio: _Servicio(
              _modelo([_imagen(1, 'PREVIA', 'F11', 1, 1)]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SeccionImagenesRedes), findsOneWidget);
      expect(find.byKey(const ValueKey('imagen-redes-1')), findsOneWidget);
    });

    testWidgets('abierto desde el aviso baja hasta la sección', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          FinDeSemanaPage(
            servicio: _Coordinacion(),
            imagenesServicio: _Servicio(_modelo(const [])),
            fechaInicial: _viernes,
            irAImagenes: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SeccionImagenesRedes), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(SeccionImagenesRedes)).dy,
        lessThan(600),
      );
    });
  });

  group('aviso push', () {
    test('el push abre "Imágenes para redes" de ese fin de semana', () {
      final destino = destinoDeAvisoConvocatoria(
        tipo: tipoPushImagenesRedes,
        datos: {
          'tipo': 'IMAGENES_REDES',
          'pantalla': 'IMAGENES_REDES',
          'desde': '2026-11-13',
          'tipoImagen': 'PREVIA',
        },
      );

      expect(destino, AbrirImagenesRedes(_viernes));
    });

    test('sin fecha abre el de hoy', () {
      expect(
        destinoDeAvisoConvocatoria(tipo: tipoPushImagenesRedes),
        const AbrirImagenesRedes(),
      );
    });

    test('el payload de la notificación local va y vuelve', () {
      final destino = AbrirImagenesRedes(_viernes);

      expect(payloadDeDestino(destino), 'IMAGENES_REDES:2026-11-13');
      expect(destinoDePayload('IMAGENES_REDES:2026-11-13'), destino);
      expect(payloadDeDestino(const AbrirImagenesRedes()), 'IMAGENES_REDES');
      expect(destinoDePayload('IMAGENES_REDES'), const AbrirImagenesRedes());
    });

    test('la referencia de la bandeja es el viernes como yyyyMMdd', () {
      expect(diaDeReferenciaImagenes(20261113), _viernes);
      expect(diaDeReferenciaImagenes(null), isNull);
      expect(diaDeReferenciaImagenes(7), isNull);
      expect(diaDeReferenciaImagenes(20261399), isNull);
    });
  });
}
