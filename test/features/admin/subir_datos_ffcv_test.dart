import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/core/utils/selector_ficheros.dart';
import 'package:app_mutxamel_cf/features/admin/models/ffcv_model.dart';
import 'package:app_mutxamel_cf/features/admin/pages/subir_datos_ffcv_page.dart';
import 'package:app_mutxamel_cf/features/admin/services/ffcv_service.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/teams/models/team_model.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../../support/http_test_helpers.dart';

class _Selector implements SelectorFicheros {
  FicheroElegido? siguiente;
  final List<List<String>> pedidos = [];

  @override
  Future<FicheroElegido?> elegir({required List<String> extensiones}) async {
    pedidos.add(extensiones);

    return siguiente;
  }
}

class _FakeFfcv extends FfcvService {
  PrevisualizacionPartidosModel previaPartidos =
      const PrevisualizacionPartidosModel();
  PrevisualizacionClasificacionesModel previaClasificaciones =
      const PrevisualizacionClasificacionesModel();
  Object? fallo;
  final List<String> llamadas = [];
  List<({String competicion, String? letra, int equipoId})>?
  asignacionesEnviadas;
  List<int>? equiposEnviados;

  @override
  Future<PrevisualizacionPartidosModel> previsualizarPartidos({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    llamadas.add('previsualizar-partidos:$nombreArchivo:${bytes.length}');
    if (fallo != null) throw fallo!;

    return previaPartidos;
  }

  @override
  Future<ResultadoPartidosModel> confirmarPartidos(
    PrevisualizacionPartidosModel previa, {
    List<({String competicion, String? letra, int equipoId})> asignaciones =
        const [],
  }) async {
    llamadas.add('confirmar-partidos');
    asignacionesEnviadas = asignaciones;
    if (fallo != null) throw fallo!;

    return const ResultadoPartidosModel(
      creados: 2,
      actualizados: 1,
      sinCambios: 1,
      conflictosManuales: 0,
      sinEquipo: 0,
      descansosCreados: 1,
      descansosEliminados: 0,
      avisos: ['Un rival nuevo se ha enlazado con su escudo'],
    );
  }

  @override
  Future<PrevisualizacionClasificacionesModel> previsualizarClasificaciones({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    llamadas.add('previsualizar-clasificaciones:$nombreArchivo');
    if (fallo != null) throw fallo!;

    return previaClasificaciones;
  }

  @override
  Future<ResultadoClasificacionesModel> confirmarClasificaciones(
    List<int> equipoIds,
  ) async {
    llamadas.add('confirmar-clasificaciones');
    equiposEnviados = equipoIds;
    if (fallo != null) throw fallo!;

    return const ResultadoClasificacionesModel(
      importados: 2,
      filas: 28,
      equipos: ['Alevín A', 'Cadete A'],
    );
  }
}

PrevisualizacionPartidosModel _previaPartidos({bool conSinEquipo = false}) {
  final json = <String, dynamic>{
    'desde': '2026-11-20',
    'hasta': '2026-11-22',
    'filas': [
      {
        'fecha': '2026-11-21',
        'competicion': 'Alevín Gr. 3',
        'letra': 'A',
        'local': true,
        'rival': 'C.D. Salesianos Alicante',
        'campo': 'Campo municipal',
        'hora': '10:30',
        'jornada': 9,
        'estado': 'NUEVO',
        'equipoId': 3,
        'equipoNombre': 'Alevín A',
        'cambios': [],
      },
      {
        'fecha': '2026-11-21',
        'competicion': 'Cadete Gr. 2',
        'letra': 'A',
        'local': false,
        'rival': 'U.D. Altea',
        'campo': 'Altea',
        'hora': '16:00',
        'jornada': 9,
        'estado': 'ACTUALIZADO',
        'equipoId': 4,
        'equipoNombre': 'Cadete A',
        'cambios': ['hora: 15:30 → 16:00'],
      },
      {
        'fecha': '2026-11-22',
        'competicion': 'Infantil Gr. 1',
        'letra': 'B',
        'local': true,
        'rival': 'Pego C.F.',
        'estado': 'SIN_CAMBIOS',
        'equipoId': 5,
        'equipoNombre': 'Infantil B',
        'cambios': [],
      },
      if (conSinEquipo)
        {
          'fecha': '2026-11-22',
          'competicion': 'Juvenil Gr. 4',
          'letra': 'C',
          'local': true,
          'rival': 'Elche C.F.',
          'estado': 'SIN_EQUIPO',
          'cambios': [],
        },
    ],
    'descansan': [
      {'equipoId': 7, 'equipoNombre': 'Benjamín A'},
    ],
    'desaparecidos': [
      {
        'equipoNombre': 'Prebenjamín A',
        'fecha': '2026-11-14',
        'rival': 'C.F. Xàbia',
        'hora': '12:00',
        'tieneConvocatoria': true,
      },
    ],
    'errores': [
      {'linea': 14, 'mensaje': 'Fecha no válida'},
    ],
  };

  return PrevisualizacionPartidosModel.fromJson(json);
}

PrevisualizacionClasificacionesModel _previaClasificaciones() =>
    PrevisualizacionClasificacionesModel.fromJson({
      'filasLeidas': 540,
      'competiciones': 31,
      'equipos': [
        {
          'equipoId': 3,
          'equipoNombre': 'Alevín A',
          'encontrado': true,
          'competicion': 'Alevín Gr. 3',
          'jornada': 9,
          'jornadaGuardada': 8,
          'posicion': 2,
          'puntos': 21,
          'pj': 9,
          'antiguo': false,
          'importable': true,
          'marcadoPorDefecto': true,
          'cambia': true,
          'cambios': ['Posición: 3 → 2'],
        },
        {
          'equipoId': 4,
          'equipoNombre': 'Cadete A',
          'encontrado': true,
          'competicion': 'Cadete Gr. 2',
          'jornada': 6,
          'jornadaGuardada': 9,
          'posicion': 5,
          'puntos': 10,
          'pj': 6,
          'antiguo': true,
          'importable': true,
          'marcadoPorDefecto': false,
          'cambia': true,
          'cambios': [],
        },
        {
          'equipoId': 5,
          'equipoNombre': 'Infantil B',
          'encontrado': false,
          'motivo': 'No hay grupo para este equipo',
          'importable': false,
          'marcadoPorDefecto': false,
          'cambia': false,
          'cambios': [],
        },
      ],
      'sinMapeo': [
        {
          'competicion': 'Juvenil Gr. 4',
          'letra': 'C',
          'equipo': 'Mutxamel C.F.',
        },
      ],
      'errores': [
        {'linea': 3, 'mensaje': 'Fila ilegible'},
      ],
    });

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('es'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Future<void> _pintar(
  WidgetTester tester, {
  required _FakeFfcv servicio,
  required _Selector selector,
  Size tamano = const Size(800, 3200),
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    _app(
      SubirDatosFfcvPage(
        servicio: servicio,
        selector: selector,
        equipos: () async => const [
          TeamModel(
            id: 11,
            categoria: 'Juvenil',
            grupo: 'C',
            orden: 'a',
            nombre: 'Juvenil C',
            deporte: 'F',
          ),
          TeamModel(
            id: 12,
            categoria: 'Juvenil',
            grupo: 'A',
            orden: 'b',
            nombre: 'Juvenil A',
            deporte: 'F',
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FicheroElegido _fichero(String nombre) =>
    FicheroElegido(nombre: nombre, bytes: Uint8List.fromList([1, 2, 3]));

void main() {
  group('Partidos', () {
    testWidgets('lleva arriba la explicación de dónde se descarga el fichero', (
      tester,
    ) async {
      await _pintar(tester, servicio: _FakeFfcv(), selector: _Selector());

      expect(
        find.textContaining(
          'Descarga el listado LstPartidos.csv de la intranet de la FFCV',
        ),
        findsOneWidget,
      );
      expect(find.text('Elegir fichero'), findsOneWidget);
      expect(find.text('Ningún fichero elegido'), findsOneWidget);
    });

    testWidgets(
      'elegir, previsualizar y confirmar: sube el fichero, enseña lo que hará y el resultado',
      (tester) async {
        final servicio = _FakeFfcv()..previaPartidos = _previaPartidos();
        final selector = _Selector()..siguiente = _fichero('LstPartidos.csv');

        await _pintar(tester, servicio: servicio, selector: selector);

        await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
        await tester.pumpAndSettle();

        // Pide solo ficheros csv y enseña el nombre elegido.
        expect(selector.pedidos, [
          ['csv'],
        ]);
        expect(find.text('LstPartidos.csv'), findsOneWidget);
        expect(find.text('Cambiar fichero'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, ['previsualizar-partidos:LstPartidos.csv:3']);
        expect(
          find.text(
            'Fin de semana 20/11/2026 – 22/11/2026: 1 nuevos, 1 actualizados, 1 sin cambios',
          ),
          findsOneWidget,
        );
        // Las filas con su estado y sus cambios.
        expect(find.text('Nuevo'), findsOneWidget);
        expect(find.text('Actualizado'), findsOneWidget);
        expect(find.text('Sin cambios'), findsOneWidget);
        expect(find.text('Local · C.D. Salesianos Alicante'), findsOneWidget);
        expect(find.text('Visitante · U.D. Altea'), findsOneWidget);
        expect(find.text('hora: 15:30 → 16:00'), findsOneWidget);
        // Los avisos, destacados: errores, desaparecidos y descansos.
        expect(find.byKey(const ValueKey('ffcv-errores')), findsOneWidget);
        expect(find.text('Línea 14: Fecha no válida'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('ffcv-desaparecidos')),
          findsOneWidget,
        );
        expect(find.textContaining('tiene convocatoria'), findsOneWidget);
        expect(find.text('Benjamín A'), findsOneWidget);

        // Confirmar pide confirmación con el número de partidos.
        await tester.tap(find.byKey(const ValueKey('ffcv-confirmar')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Se importarán 2 partidos (1 nuevos y 1 actualizados). ¿Continuar?',
          ),
          findsOneWidget,
        );

        // Cancelar no importa nada.
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(servicio.llamadas, hasLength(1));

        await tester.tap(find.byKey(const ValueKey('ffcv-confirmar')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('ffcv-confirmar-dialogo')));
        await tester.pumpAndSettle();

        expect(servicio.llamadas.last, 'confirmar-partidos');
        expect(find.byKey(const ValueKey('ffcv-resultado')), findsOneWidget);
        expect(
          find.text(
            'Importación guardada: 2 nuevos, 1 actualizados, 1 sin cambios, 0 conflictos manuales, 0 sin equipo. Descansos: +1 / −0.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Un rival nuevo se ha enlazado con su escudo'),
          findsOneWidget,
        );
        // La vista previa desaparece: no se puede confirmar dos veces.
        expect(find.byKey(const ValueKey('ffcv-confirmar')), findsNothing);
      },
    );

    testWidgets(
      'las filas sin equipo se asignan a un equipo del club y se envían',
      (tester) async {
        final servicio = _FakeFfcv()
          ..previaPartidos = _previaPartidos(conSinEquipo: true);
        final selector = _Selector()..siguiente = _fichero('LstPartidos.csv');

        await _pintar(tester, servicio: servicio, selector: selector);
        await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('asignar-Juvenil Gr. 4|C')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Juvenil C').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('ffcv-confirmar')));
        await tester.pumpAndSettle();
        // Con el equipo asignado, la fila sin equipo también se importa: 3 partidos.
        expect(find.textContaining('Se importarán 3 partidos'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('ffcv-confirmar-dialogo')));
        await tester.pumpAndSettle();

        expect(servicio.asignacionesEnviadas, [
          (competicion: 'Juvenil Gr. 4', letra: 'C', equipoId: 11),
        ]);
      },
    );

    testWidgets(
      'si el servidor rechaza el fichero, su mensaje se enseña en claro',
      (tester) async {
        final servicio = _FakeFfcv()
          ..fallo = const ApiException(
            'El archivo no es un listado de partidos de la FFCV',
            statusCode: 400,
          );
        final selector = _Selector()..siguiente = _fichero('otro.csv');

        await _pintar(tester, servicio: servicio, selector: selector);
        await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('ffcv-error')), findsOneWidget);
        expect(
          find.text('El archivo no es un listado de partidos de la FFCV'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('ffcv-confirmar')), findsNothing);
      },
    );

    testWidgets(
      'un 403 enseña el mensaje del servidor y sin conexión, el error genérico',
      (tester) async {
        final servicio = _FakeFfcv()
          ..fallo = const ApiException(
            'Solo un administrador puede importar los datos de la FFCV',
            statusCode: 403,
          );
        final selector = _Selector()..siguiente = _fichero('LstPartidos.csv');

        await _pintar(tester, servicio: servicio, selector: selector);
        await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Solo un administrador puede importar los datos de la FFCV',
          ),
          findsOneWidget,
        );

        servicio.fallo = const ApiException('No hay conexión a internet.');
        await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
        await tester.pumpAndSettle();

        expect(find.textContaining('conexión'), findsOneWidget);
      },
    );

    testWidgets(
      'mientras sube y procesa hay un indicador y los botones quedan deshabilitados',
      (tester) async {
        final servicio = _FakeFfcvLento();
        final selector = _Selector()..siguiente = _fichero('LstPartidos.csv');

        await _pintar(tester, servicio: servicio, selector: selector);
        await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
        await tester.pump();

        expect(find.byKey(const ValueKey('ffcv-trabajando')), findsOneWidget);
        expect(find.text('Subiendo y procesando el fichero…'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('ffcv-previsualizar')),
              )
              .onPressed,
          isNull,
        );

        servicio.terminar();
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('ffcv-trabajando')), findsNothing);
      },
    );

    testWidgets('si el usuario cancela el selector no pasa nada', (
      tester,
    ) async {
      final selector = _Selector();

      await _pintar(tester, servicio: _FakeFfcv(), selector: selector);
      await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
      await tester.pumpAndSettle();

      expect(find.text('Ningún fichero elegido'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('ffcv-previsualizar')),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('Clasificaciones', () {
    Future<void> irAClasificaciones(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('pestana-clasificaciones')));
      await tester.pumpAndSettle();
    }

    testWidgets('lleva la explicación del panel y pide un .xlsx', (
      tester,
    ) async {
      final selector = _Selector();

      await _pintar(tester, servicio: _FakeFfcv(), selector: selector);
      await irAClasificaciones(tester);

      expect(
        find.textContaining(
          'Descarga ListadoClasificaciones.xlsx de la intranet de la FFCV',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
      await tester.pumpAndSettle();

      expect(selector.pedidos.single, ['xlsx']);
    });

    testWidgets('elegir, previsualizar y confirmar los equipos marcados', (
      tester,
    ) async {
      final servicio = _FakeFfcv()
        ..previaClasificaciones = _previaClasificaciones();
      final selector = _Selector()
        ..siguiente = _fichero('ListadoClasificaciones.xlsx');

      await _pintar(tester, servicio: servicio, selector: selector);
      await irAClasificaciones(tester);
      await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, [
        'previsualizar-clasificaciones:ListadoClasificaciones.xlsx',
      ]);
      expect(
        find.textContaining('540 filas leídas en 31 grupos'),
        findsOneWidget,
      );
      expect(find.text('Jornada 9 · Pos. 2 · 21 pts · PJ 9'), findsOneWidget);
      expect(find.text('• Posición: 3 → 2'), findsOneWidget);
      // El archivo antiguo, con su aviso destacado y desmarcado.
      expect(find.byKey(const ValueKey('ffcv-aviso-antiguo')), findsOneWidget);
      expect(
        find.textContaining(
          'el archivo es de la jornada 6 y lo guardado es de la jornada 9',
        ),
        findsOneWidget,
      );
      // El no encontrado, con su motivo y sin poder marcarse.
      expect(find.text('No hay grupo para este equipo'), findsOneWidget);
      // Las filas sin mapeo y los errores, destacados.
      expect(find.byKey(const ValueKey('ffcv-sin-mapeo')), findsOneWidget);
      expect(find.text('Línea 3: Fila ilegible'), findsOneWidget);

      final marcas = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .map((c) => c.value)
          .toList();
      expect(marcas, [true, false, false]);

      await tester.tap(find.byKey(const ValueKey('ffcv-confirmar')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Se actualizará la clasificación de 1 equipos'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('ffcv-confirmar-dialogo')));
      await tester.pumpAndSettle();

      expect(servicio.equiposEnviados, [3]);
      expect(
        find.text(
          '2 equipo(s) actualizado(s), 28 filas de clasificación guardadas.',
        ),
        findsOneWidget,
      );
      expect(find.text('• Alevín A'), findsOneWidget);
    });

    testWidgets('sin ningún equipo marcado no se confirma', (tester) async {
      final servicio = _FakeFfcv()
        ..previaClasificaciones = _previaClasificaciones();
      final selector = _Selector()
        ..siguiente = _fichero('ListadoClasificaciones.xlsx');

      await _pintar(tester, servicio: servicio, selector: selector);
      await irAClasificaciones(tester);
      await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
      await tester.pumpAndSettle();

      // Desmarca el único marcado.
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ffcv-confirmar')));
      await tester.pumpAndSettle();

      expect(find.text('Marca al menos un equipo.'), findsOneWidget);
      expect(servicio.equiposEnviados, isNull);
    });

    testWidgets('si la vista previa caducó, el mensaje del servidor lo dice', (
      tester,
    ) async {
      final servicio = _FakeFfcv()
        ..previaClasificaciones = _previaClasificaciones();
      final selector = _Selector()
        ..siguiente = _fichero('ListadoClasificaciones.xlsx');

      await _pintar(tester, servicio: servicio, selector: selector);
      await irAClasificaciones(tester);
      await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
      await tester.pumpAndSettle();

      servicio.fallo = const ApiException(
        'La vista previa ha caducado: vuelve a subir el archivo',
        statusCode: 400,
      );
      await tester.tap(find.byKey(const ValueKey('ffcv-confirmar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ffcv-confirmar-dialogo')));
      await tester.pumpAndSettle();

      expect(
        find.text('La vista previa ha caducado: vuelve a subir el archivo'),
        findsOneWidget,
      );
    });

    testWidgets('un fichero no válido da el error del servidor', (
      tester,
    ) async {
      final servicio = _FakeFfcv()
        ..fallo = const ApiException(
          'El archivo debe ser un Excel .xlsx (ListadoClasificaciones.xlsx)',
          statusCode: 400,
        );
      final selector = _Selector()
        ..siguiente = _fichero('clasificaciones.xlsx');

      await _pintar(tester, servicio: servicio, selector: selector);
      await irAClasificaciones(tester);
      await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'El archivo debe ser un Excel .xlsx (ListadoClasificaciones.xlsx)',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('con letra grande en un iPhone pequeño no se desborda', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final servicio = _FakeFfcv()..previaPartidos = _previaPartidos();
    final selector = _Selector()..siguiente = _fichero('LstPartidos.csv');

    await _pintar(
      tester,
      servicio: servicio,
      selector: selector,
      tamano: const Size(320, 568),
    );
    await tester.tap(find.byKey(const ValueKey('ffcv-elegir')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ffcv-previsualizar')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  group('FfcvService y el envío del fichero', () {
    setUp(() async {
      FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
        <String, String>{},
      );
      await AuthSession.guardarSesion(
        LoginResponse(
          token: 'tok',
          usuarioId: 1,
          email: 'a@a.com',
          roles: const ['ADMIN_APP'],
        ),
      );
    });

    test(
      'previsualizar partidos sube el fichero como multipart con el campo "archivo" y el token',
      () async {
        final previa = await conMockHttp(
          (request) async {
            expect(request.method, 'POST');
            expect(
              request.url.path,
              endsWith('/app/admin/ffcv/partidos/previsualizar'),
            );
            expect(request.headers['Authorization'], 'Bearer tok');
            expect(
              request.headers['content-type'],
              startsWith('multipart/form-data'),
            );
            expect(request.body, contains('name="archivo"'));
            expect(request.body, contains('filename="LstPartidos.csv"'));
            expect(request.body, contains('contenido-del-csv'));

            return http.Response(
              jsonEncode({
                'desde': '2026-11-20',
                'hasta': '2026-11-22',
                'filas': [],
              }),
              200,
            );
          },
          () => FfcvService().previsualizarPartidos(
            bytes: utf8.encode('contenido-del-csv'),
            nombreArchivo: 'LstPartidos.csv',
          ),
        );

        expect(previa.filas, isEmpty);
        expect(previa.desde, DateTime(2026, 11, 20));
      },
    );

    test(
      'confirmar partidos devuelve la previsualización recibida tal cual y las asignaciones',
      () async {
        final previa = _previaPartidos(conSinEquipo: true);

        await conMockHttp(
          (request) async {
            expect(
              request.url.path,
              endsWith('/app/admin/ffcv/partidos/confirmar'),
            );
            final cuerpo = jsonDecode(request.body) as Map<String, dynamic>;
            expect(cuerpo['previsualizacion'], previa.json);
            expect(cuerpo['asignaciones'], [
              {'competicion': 'Juvenil Gr. 4', 'letra': 'C', 'equipoId': 11},
            ]);

            return http.Response(jsonEncode({'creados': 1}), 200);
          },
          () => FfcvService().confirmarPartidos(
            previa,
            asignaciones: [
              (competicion: 'Juvenil Gr. 4', letra: 'C', equipoId: 11),
            ],
          ),
        );
      },
    );

    test('clasificaciones: subir y confirmar con equipoIds', () async {
      await conMockHttp(
        (request) async {
          expect(
            request.url.path,
            endsWith('/app/admin/ffcv/clasificaciones/previsualizar'),
          );
          expect(
            request.body,
            contains('filename="ListadoClasificaciones.xlsx"'),
          );

          return http.Response(
            jsonEncode({'filasLeidas': 3, 'competiciones': 1}),
            200,
          );
        },
        () => FfcvService().previsualizarClasificaciones(
          bytes: [1, 2, 3],
          nombreArchivo: 'ListadoClasificaciones.xlsx',
        ),
      );

      await conMockHttp((request) async {
        expect(
          request.url.path,
          endsWith('/app/admin/ffcv/clasificaciones/confirmar'),
        );
        expect(jsonDecode(request.body), {
          'equipoIds': [3, 4],
        });

        return http.Response(jsonEncode({'importados': 2, 'filas': 20}), 200);
      }, () => FfcvService().confirmarClasificaciones([3, 4]));
    });

    test(
      'el error del servidor ({"error": ...}) llega con su texto y su código',
      () async {
        await expectLater(
          conMockHttp(
            (request) async => http.Response(
              jsonEncode({
                'error':
                    'El archivo es demasiado grande para ser un listado de partidos',
              }),
              400,
            ),
            () => FfcvService().previsualizarPartidos(
              bytes: [1],
              nombreArchivo: 'LstPartidos.csv',
            ),
          ),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 400)
                .having(
                  (e) => e.message,
                  'message',
                  contains('demasiado grande'),
                ),
          ),
        );

        // Un 403: no es administrador.
        await expectLater(
          conMockHttp(
            (request) async => http.Response(
              jsonEncode({
                'error':
                    'Solo un administrador puede importar los datos de la FFCV',
              }),
              403,
            ),
            () => FfcvService().confirmarClasificaciones([1]),
          ),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
          ),
        );
      },
    );
  });
}

/// Un servicio que no contesta hasta que el test lo dice.
class _FakeFfcvLento extends _FakeFfcv {
  final _espera = Completer<void>();

  void terminar() => _espera.complete();

  @override
  Future<PrevisualizacionPartidosModel> previsualizarPartidos({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    await _espera.future;

    return const PrevisualizacionPartidosModel();
  }
}
