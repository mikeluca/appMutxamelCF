import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/models/partido_primer_equipo_model.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/pages/imagenes_redes_page.dart';
import 'package:app_mutxamel_cf/features/imagenes_redes/widgets/imagenes_redes_vista.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/imagenes_redes_soporte.dart';

const String _textoFilialEs =
    'Próximo partido: Mutxamel C.F. “B” – Pego. Domingo 22/11 a las 19:00, Camp Nou Los Olmos (Mutxamel). '
    '¡Os esperamos! #somMTX #mareaAzul #MutxamelCF';

PartidoPrimerEquipoModel _partidoFilial() => const PartidoPrimerEquipoModel(
  disponible: true,
  partidoId: 40,
  rival: 'Pego',
  campo: 'Camp Nou Los Olmos (Mutxamel)',
  competicion: 'Segona FFCV, Grup 7',
  textoEs: _textoFilialEs,
  textoCa: 'Pròxim partit del Filial',
);

Widget _pagina(ServicioImagenesFalso servicio, {String tipo = 'FILIAL'}) {
  return appDePrueba(
    ImagenesRedesPage(
      servicio: servicio,
      tipoInicial: tipo == 'FILIAL'
          ? tipoImagenPartidoFilial
          : tipoImagenPartidoPrimerEquipo,
      ahora: () => DateTime(2026, 11, 18, 10),
    ),
  );
}

Finder _clave(String clave) => find.byKey(ValueKey(clave));

Future<void> _tocar(WidgetTester tester, String clave) async {
  await tester.ensureVisible(_clave(clave));
  await tester.pumpAndSettle();
  await tester.tap(_clave(clave));
  await tester.pumpAndSettle();
}

Future<void> _segmento(WidgetTester tester, String clave, String texto) async {
  await tester.ensureVisible(_clave(clave));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: _clave(clave), matching: find.text(texto)),
  );
  await tester.pumpAndSettle();
}

Future<void> _pestana(WidgetTester tester, String clave) async {
  await tester.ensureVisible(_clave(clave));
  await tester.pumpAndSettle();
  await tester.tap(_clave(clave));
  await tester.pumpAndSettle();
}

void main() {
  late List<({List<Uint8List> pngs, List<String> nombres, String texto})>
  compartidos;
  String? copiado;

  setUp(() {
    compartidos = [];
    copiado = null;
    CompartirImagenesRedes.enviar = (pngs, nombres, texto, origen) async {
      compartidos.add((pngs: pngs, nombres: nombres, texto: texto));
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

  group('rutas', () {
    test('cada cartel tiene su ruta y el nombre de su fichero', () {
      expect(CartelEquipo.primerEquipo.ruta, 'partido-primer-equipo');
      expect(CartelEquipo.filial.ruta, 'partido-filial');
      expect(CartelEquipo.primerEquipo.prefijoFichero, 'cartel_primer_equipo');
      expect(CartelEquipo.filial.prefijoFichero, 'cartel_filial');
    });
  });

  group('el partido del Filial', () {
    testWidgets(
      'disponible: su tarjeta y sus botones, y se pide el del Filial',
      (tester) async {
        final servicio = ServicioImagenesFalso()
          ..partidoFilial = _partidoFilial();

        await tester.pumpWidget(_pagina(servicio));
        await tester.pumpAndSettle();

        expect(_clave('filial-cartel-tarjeta-partido'), findsOneWidget);
        expect(find.text('Pego'), findsOneWidget);
        expect(find.text('Segona FFCV, Grup 7'), findsOneWidget);
        expect(_clave('filial-cartel-generar'), findsOneWidget);
        expect(_clave('filial-cartel-compartir'), findsOneWidget);
        expect(_clave('filial-cartel-copiar'), findsOneWidget);
        expect(servicio.partidosPedidosFilial, 1);
        expect(
          servicio.peticiones.where((p) => p.equipo == CartelEquipo.filial),
          isNotEmpty,
        );
      },
    );

    testWidgets('SIN_PARTIDO: mensaje propio y sin botones', (tester) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = const PartidoPrimerEquipoModel(
          disponible: false,
          motivo: motivoSinPartido,
        );

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay ningún próximo partido del Filial'),
        findsOneWidget,
      );
      expect(
        find.text('No hay ningún próximo partido del Primer Equipo'),
        findsNothing,
      );
      expect(_clave('filial-cartel-generar'), findsNothing);
      expect(_clave('filial-cartel-compartir'), findsNothing);
      expect(_clave('filial-cartel-copiar'), findsNothing);
    });

    testWidgets('YA_EMPEZADO: mensaje y sin botones', (tester) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = const PartidoPrimerEquipoModel(
          disponible: false,
          motivo: motivoYaEmpezado,
        );

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();

      expect(find.text('El partido ya ha empezado'), findsOneWidget);
      expect(_clave('filial-cartel-generar'), findsNothing);
      expect(_clave('filial-cartel-copiar'), findsNothing);
    });

    testWidgets('el Primer Equipo puede estar disponible y el Filial no', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = const PartidoPrimerEquipoModel(
          disponible: false,
          motivo: motivoSinPartido,
        );

      await tester.pumpWidget(_pagina(servicio, tipo: 'PRIMER'));
      await tester.pumpAndSettle();
      await _pestana(tester, 'pestana-filial');

      expect(_clave('filial-cartel-generar'), findsNothing);
      expect(
        find.text('No hay ningún próximo partido del Filial'),
        findsOneWidget,
      );
    });

    testWidgets('un error al cargar el partido del Filial se reintenta', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial()
        ..falloPartidoFilial = Exception('sin red');

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();

      expect(
        find.text('No se ha podido cargar el próximo partido.'),
        findsOneWidget,
      );

      servicio.falloPartidoFilial = null;
      await _tocar(tester, 'filial-cartel-reintentar-partido');

      expect(_clave('filial-cartel-tarjeta-partido'), findsOneWidget);
      expect(servicio.partidosPedidosFilial, 2);
    });
  });

  group('generar, compartir y copiar en el Filial', () {
    testWidgets('Generar pide el cartel del Filial con las opciones elegidas', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial();

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();

      await _segmento(tester, 'filial-cartel-formato', 'Historia');
      await _segmento(tester, 'filial-cartel-idioma', 'Valencià');
      await _tocar(tester, 'filial-cartel-opcion-racha');
      await _tocar(tester, 'filial-cartel-opcion-hashtags');
      await _tocar(tester, 'filial-cartel-generar');

      expect(servicio.cartelesFilial, [
        const OpcionesCartel(
          formato: FormatoCartel.historia,
          idioma: IdiomaCartel.ca,
          racha: false,
          hashtags: false,
        ),
      ]);
      // Y ni una petición al cartel del Primer Equipo
      expect(servicio.carteles, isEmpty);
      expect(
        servicio.peticiones.where(
          (p) => p.que == 'png' && p.equipo == CartelEquipo.primerEquipo,
        ),
        isEmpty,
      );
    });

    testWidgets('por defecto: los tres chips marcados', (tester) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial();

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();
      await _tocar(tester, 'filial-cartel-generar');

      expect(servicio.cartelesFilial.single, const OpcionesCartel());
    });

    testWidgets('al cambiar una opción la imagen queda desactualizada', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial();

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();
      await _tocar(tester, 'filial-cartel-generar');
      await _tocar(tester, 'filial-cartel-opcion-qr');

      expect(servicio.cartelesFilial, hasLength(1));
      expect(_clave('filial-cartel-desactualizada'), findsOneWidget);
      expect(
        tester
            .widget<ButtonStyleButton>(_clave('filial-cartel-compartir'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('si falla, el error sale con Reintentar', (tester) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial()
        ..fallosCartelFilial.add(Exception('sin red'));

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();
      await _tocar(tester, 'filial-cartel-generar');

      expect(find.text('No se ha podido generar el cartel.'), findsOneWidget);

      await _tocar(tester, 'filial-cartel-reintentar');

      expect(servicio.cartelesFilial, hasLength(2));
      expect(_clave('filial-cartel-png'), findsOneWidget);
    });

    testWidgets('Compartir envía el PNG con el nombre del Filial y su texto', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial();

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();
      await _tocar(tester, 'filial-cartel-generar');
      await _tocar(tester, 'filial-cartel-compartir');

      expect(compartidos.single.nombres, ['cartel_filial_publicacion.png']);
      expect(compartidos.single.texto, _textoFilialEs);
    });

    testWidgets('Compartir y Copiar quitan los hashtags si están desmarcados', (
      tester,
    ) async {
      simularPortapapeles(tester);
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial();

      await tester.pumpWidget(_pagina(servicio));
      await tester.pumpAndSettle();
      await _tocar(tester, 'filial-cartel-copiar');

      expect(copiado, _textoFilialEs);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tocar(tester, 'filial-cartel-opcion-hashtags');
      await _tocar(tester, 'filial-cartel-copiar');

      expect(copiado, isNot(contains('#')));

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _tocar(tester, 'filial-cartel-generar');
      await _tocar(tester, 'filial-cartel-compartir');

      expect(compartidos.single.texto, isNot(contains('#')));
    });

    testWidgets('un 403 al generar el cartel del Filial avisa y vuelve atrás', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial()
        ..fallosCartelFilial.add(const ApiException('No', statusCode: 403));

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
                      tipoInicial: tipoImagenPartidoFilial,
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
      await _tocar(tester, 'filial-cartel-generar');

      expect(find.byType(ImagenesRedesPage), findsNothing);
      expect(
        find.text('Ya no tienes permiso para ver las imágenes para redes'),
        findsOneWidget,
      );
    });
  });

  group('los dos carteles no se mezclan', () {
    testWidgets('las opciones de uno no pasan al otro', (tester) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial();

      await tester.pumpWidget(_pagina(servicio, tipo: 'PRIMER'));
      await tester.pumpAndSettle();

      // Primer Equipo: Historia, valenciano y sin QR
      await _segmento(tester, 'cartel-formato', 'Historia');
      await _segmento(tester, 'cartel-idioma', 'Valencià');
      await _tocar(tester, 'cartel-opcion-qr');

      await _pestana(tester, 'pestana-filial');

      // Filial: sigue con los valores por defecto
      expect(
        tester.widget<FilterChip>(_clave('filial-cartel-opcion-qr')).selected,
        isTrue,
      );
      await _tocar(tester, 'filial-cartel-generar');

      expect(servicio.cartelesFilial.single, const OpcionesCartel());

      // Y al volver, el Primer Equipo conserva lo suyo
      await _pestana(tester, 'pestana-primer-equipo');
      await _tocar(tester, 'cartel-generar');

      expect(
        servicio.carteles.single,
        const OpcionesCartel(
          formato: FormatoCartel.historia,
          idioma: IdiomaCartel.ca,
          qr: false,
        ),
      );
      expect(servicio.cartelesFilial, hasLength(1));
    });

    testWidgets('las imágenes generadas y su estado son de cada cartel', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial();

      await tester.pumpWidget(_pagina(servicio, tipo: 'PRIMER'));
      await tester.pumpAndSettle();

      await _tocar(tester, 'cartel-generar');

      expect(_clave('cartel-png'), findsOneWidget);

      await _pestana(tester, 'pestana-filial');

      // El Filial aún no ha generado nada, aunque el Primer Equipo sí
      expect(_clave('filial-cartel-png'), findsNothing);
      expect(
        tester
            .widget<ButtonStyleButton>(_clave('filial-cartel-compartir'))
            .onPressed,
        isNull,
      );

      await _tocar(tester, 'filial-cartel-generar');
      await _tocar(tester, 'filial-cartel-opcion-racha');

      // El Filial queda desactualizado, el Primer Equipo no
      expect(_clave('filial-cartel-desactualizada'), findsOneWidget);

      await _pestana(tester, 'pestana-primer-equipo');

      expect(_clave('cartel-png'), findsOneWidget);
      expect(_clave('cartel-desactualizada'), findsNothing);
      expect(
        tester.widget<ButtonStyleButton>(_clave('cartel-compartir')).onPressed,
        isNotNull,
      );
      expect(servicio.carteles, hasLength(1));
      expect(servicio.cartelesFilial, hasLength(1));
    });

    testWidgets('cada cartel comparte y copia su propio texto', (tester) async {
      simularPortapapeles(tester);
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial();

      await tester.pumpWidget(_pagina(servicio, tipo: 'PRIMER'));
      await tester.pumpAndSettle();
      await _tocar(tester, 'cartel-generar');
      await _tocar(tester, 'cartel-compartir');

      expect(compartidos.single.texto, textoEsDePrueba);
      expect(compartidos.single.nombres, [
        'cartel_primer_equipo_publicacion.png',
      ]);

      await _pestana(tester, 'pestana-filial');
      await _tocar(tester, 'filial-cartel-generar');
      await _tocar(tester, 'filial-cartel-compartir');

      expect(compartidos.last.texto, _textoFilialEs);
      expect(compartidos.last.nombres, ['cartel_filial_publicacion.png']);
    });

    testWidgets('el partido de cada cartel se pide una vez a su ruta', (
      tester,
    ) async {
      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial();

      await tester.pumpWidget(_pagina(servicio, tipo: 'PRIMER'));
      await tester.pumpAndSettle();
      await _pestana(tester, 'pestana-filial');
      await _pestana(tester, 'pestana-primer-equipo');
      await _pestana(tester, 'pestana-filial');

      expect(servicio.partidosPedidos, 1);
      expect(servicio.partidosPedidosFilial, 1);
    });
  });

  group('visual', () {
    testWidgets('con cuatro pestañas en iPhone pequeño, letra grande y modo '
        'oscuro no desborda y las pestañas se deslizan', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final servicio = ServicioImagenesFalso()
        ..partidoFilial = _partidoFilial();

      await tester.pumpWidget(
        appDePrueba(
          ImagenesRedesPage(
            servicio: servicio,
            tipoInicial: tipoImagenPartidoFilial,
            ahora: () => DateTime(2026, 11, 18, 10),
          ),
          tema: ThemeData.dark(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await _tocar(tester, 'filial-cartel-generar');
      await _segmento(tester, 'filial-cartel-formato', 'Historia');

      expect(tester.takeException(), isNull);
      expect(_clave('filial-cartel-desactualizada'), findsOneWidget);

      for (final pestana in [
        'pestana-previa',
        'pestana-primer-equipo',
        'pestana-filial',
      ]) {
        await _pestana(tester, pestana);

        expect(tester.takeException(), isNull, reason: pestana);
      }
    });
  });
}
