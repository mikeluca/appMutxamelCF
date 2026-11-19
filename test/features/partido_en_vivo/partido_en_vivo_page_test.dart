import 'dart:async';

import 'package:app_mutxamel_cf/features/ficha_partido/models/reloj_directo.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/models/partido_en_vivo_models.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/pages/partido_en_vivo_page.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/services/partido_en_vivo_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reloj del dispositivo que el test adelanta a mano.
class _Reloj {
  DateTime ahora = DateTime(2026, 10, 24, 11, 0, 0);

  void avanzar(Duration duracion) => ahora = ahora.add(duracion);
}

/// Servidor falso con las mismas reglas que el real: fase por orden, goles y
/// "deshacer" solo del último evento durante 2 minutos.
class _ServicioFalso extends PartidoEnVivoService {
  final _Reloj reloj;
  final List<PartidoEnVivoDisponible> partidos;
  final bool local;

  FasePartido fase = FasePartido.sinEmpezar;
  final List<EventoEnVivo> eventos = [];
  int _siguienteId = 1;

  final List<String> llamadas = [];
  bool rechazarElSiguiente = false;

  /// Si es true, obtenerEstado falla (sin red).
  bool fallarEstado = false;

  /// Si no es null, el servidor dice que quedan estos segundos para deshacer
  /// (el reloj del servidor no tiene por qué coincidir con el del móvil).
  int? segundosForzados;

  /// El minuto actual que dice el servidor (null = antes del inicio / descanso).
  int? minutoActual;

  /// Si no es null, obtenerConvocados espera a que se complete.
  Completer<List<ConvocadoEnVivo>>? convocadosPendientes;

  /// Si no es null, son los jugadores que devuelve obtenerConvocados.
  List<ConvocadoEnVivo>? convocadosForzados;

  /// El reloj que dice el estado (null = ninguno).
  RelojDirecto? relojForzado;

  /// Los dorsales del rival con una amarilla que dice el estado.
  List<int> dorsalesRivalForzados = const [];

  /// La alineación guardada que dice el estado (null = ninguna).
  AlineacionEnVivo? alineacion;

  /// Si no es null, el siguiente cambio o tarjeta lo rechaza el servidor con este mensaje.
  String? errorDeCambioOTarjeta;

  _ServicioFalso(this.reloj, this.partidos, {this.local = true});

  int get _favor => eventos.where((e) => e.tipo == 'GOL_FAVOR').length;

  int get _contra => eventos.where((e) => e.tipo == 'GOL_CONTRA').length;

  EstadoPartidoEnVivo _estado(int partidoId) {
    final ultimo = eventos.isEmpty ? null : eventos.last;
    final deshacible =
        ultimo != null &&
        ultimo.tipo != 'INICIO' &&
        !reloj.ahora.isAfter(ultimo.fecha!.add(const Duration(minutes: 2)));

    return EstadoPartidoEnVivo(
      partidoId: partidoId,
      rival: 'Pego C.F.',
      local: local,
      fase: fase,
      golesFavor: _favor,
      golesContra: _contra,
      goleadores: [
        for (final e in eventos)
          if (e.tipo == 'GOL_FAVOR' && e.autor != null) e.autor!,
      ],
      eventos: List.of(eventos),
      minutoActual: minutoActual,
      alineacion: alineacion,
      reloj: relojForzado,
      dorsalesRivalConAmarilla: dorsalesRivalForzados,
      deshacibleId: deshacible ? ultimo.id : null,
      deshacibleSegundos: deshacible
          ? segundosForzados ??
                ultimo.fecha!
                    .add(const Duration(minutes: 2))
                    .difference(reloj.ahora)
                    .inSeconds
          : null,
    );
  }

  EstadoPartidoEnVivo _registrar(
    int partidoId,
    String tipo,
    FasePartido nuevaFase, {
    int? jugadorId,
    String? autor,
    int? minuto,
    int? jugadorEntraId,
    String? jugadorEntra,
    bool dobleAmarilla = false,
    bool rival = false,
    int? dorsalRival,
  }) {
    llamadas.add('$tipo:$partidoId');

    if (rechazarElSiguiente) {
      rechazarElSiguiente = false;
      throw Exception('El partido ya ha terminado');
    }

    eventos.add(
      EventoEnVivo(
        id: _siguienteId++,
        tipo: tipo,
        jugadorId: jugadorId,
        autor: autor,
        fecha: reloj.ahora,
        minuto: minuto,
        jugadorEntraId: jugadorEntraId,
        jugadorEntra: jugadorEntra,
        dobleAmarilla: dobleAmarilla,
        rival: rival,
        dorsalRival: dorsalRival,
      ),
    );
    fase = nuevaFase;

    return _estado(partidoId);
  }

  @override
  Future<List<PartidoEnVivoDisponible>> obtenerPartidosDisponibles() async =>
      partidos;

  @override
  Future<EstadoPartidoEnVivo> obtenerEstado(int partidoId) async {
    llamadas.add('estado:$partidoId');
    if (fallarEstado) throw Exception('sin red');

    return _estado(partidoId);
  }

  @override
  Future<List<ConvocadoEnVivo>> obtenerConvocados(int partidoId) async {
    llamadas.add('convocados:$partidoId');

    final pendientes = convocadosPendientes;

    if (pendientes != null) {
      return pendientes.future;
    }

    final forzados = convocadosForzados;

    if (forzados != null) {
      return forzados;
    }

    return const [
      ConvocadoEnVivo(jugadorId: 11, dorsal: 1, nombre: 'Luis Lopez'),
      ConvocadoEnVivo(jugadorId: 10, dorsal: 9, nombre: 'Pablo Garcia'),
    ];
  }

  @override
  Future<EstadoPartidoEnVivo> enviarInicioPartido(int partidoId) async =>
      _registrar(partidoId, 'INICIO', FasePartido.primeraParte);

  @override
  Future<EstadoPartidoEnVivo> enviarGolFavor(
    int partidoId, {
    int? jugadorId,
    String? autorTexto,
    int? minuto,
  }) async {
    llamadas.add('autor:$jugadorId/$autorTexto');
    llamadas.add('minuto-gol:$minuto');

    return _registrar(
      partidoId,
      'GOL_FAVOR',
      fase,
      minuto: minuto,
      jugadorId: jugadorId,
      autor: jugadorId == 10
          ? 'Pablo Garcia'
          : jugadorId == 11
          ? 'Luis Lopez'
          : autorTexto,
    );
  }

  @override
  Future<EstadoPartidoEnVivo> enviarGolContra(
    int partidoId, {
    int? minuto,
    int? dorsal,
  }) async {
    llamadas.add('minuto-contra:$minuto');
    llamadas.add('dorsal-contra:$dorsal');

    return _registrar(
      partidoId,
      'GOL_CONTRA',
      fase,
      minuto: minuto,
      dorsalRival: dorsal,
    );
  }

  @override
  Future<EstadoPartidoEnVivo> corregirMinuto(
    int partidoId,
    int eventoId,
    int minuto,
  ) async {
    llamadas.add('corregir:$eventoId:$minuto');

    final i = eventos.indexWhere((e) => e.id == eventoId);
    final e = eventos[i];

    eventos[i] = EventoEnVivo(
      id: e.id,
      tipo: e.tipo,
      jugadorId: e.jugadorId,
      autor: e.autor,
      fecha: e.fecha,
      minuto: minuto,
      jugadorEntraId: e.jugadorEntraId,
      jugadorEntra: e.jugadorEntra,
      dobleAmarilla: e.dobleAmarilla,
      rival: e.rival,
      dorsalRival: e.dorsalRival,
    );

    return _estado(partidoId);
  }

  static const _nombres = {
    10: 'Pablo Garcia',
    11: 'Luis Lopez',
    12: 'Ana Ruiz',
    13: 'Juan Perez',
  };

  @override
  Future<EstadoPartidoEnVivo> enviarCambio(
    int partidoId, {
    required int jugadorSaleId,
    required int jugadorEntraId,
    int? minuto,
  }) async {
    llamadas.add('cambio:$jugadorSaleId>$jugadorEntraId:$minuto');

    final error = errorDeCambioOTarjeta;
    if (error != null) {
      errorDeCambioOTarjeta = null;
      throw Exception(error);
    }

    final actual = alineacion;
    if (actual != null) {
      alineacion = AlineacionEnVivo(
        formacion: actual.formacion,
        titulares: actual.titulares,
        suplentes: actual.suplentes,
        enElCampo: [
          ...actual.enElCampo.where((id) => id != jugadorSaleId),
          jugadorEntraId,
        ],
        suplentesDisponibles: actual.suplentesDisponibles
            .where((id) => id != jugadorEntraId)
            .toList(),
        expulsados: actual.expulsados,
      );
    }

    return _registrar(
      partidoId,
      'CAMBIO',
      fase,
      minuto: minuto,
      jugadorId: jugadorSaleId,
      autor: _nombres[jugadorSaleId],
      jugadorEntraId: jugadorEntraId,
      jugadorEntra: _nombres[jugadorEntraId],
    );
  }

  @override
  Future<EstadoPartidoEnVivo> enviarTarjeta(
    int partidoId, {
    int? jugadorId,
    required String color,
    int? minuto,
    bool rival = false,
    int? dorsal,
  }) async {
    llamadas.add(
      rival
          ? 'tarjeta-rival:$dorsal:$color:$minuto'
          : 'tarjeta:$jugadorId:$color:$minuto',
    );

    final error = errorDeCambioOTarjeta;
    if (error != null) {
      errorDeCambioOTarjeta = null;
      throw Exception(error);
    }

    if (rival) {
      // Como el servidor: la segunda amarilla al mismo dorsal es doble; sin dorsal, cada una suelta.
      final dobleRival =
          color == 'AMARILLA' &&
          dorsal != null &&
          eventos.any(
            (e) =>
                e.rival &&
                e.tipo == 'TARJETA_AMARILLA' &&
                e.dorsalRival == dorsal,
          );

      return _registrar(
        partidoId,
        color == 'ROJA' ? 'TARJETA_ROJA' : 'TARJETA_AMARILLA',
        fase,
        minuto: minuto,
        dobleAmarilla: dobleRival,
        rival: true,
        dorsalRival: dorsal,
      );
    }

    final segundaAmarilla =
        color == 'AMARILLA' &&
        eventos.any(
          (e) =>
              e.tipo == 'TARJETA_AMARILLA' &&
              !e.rival &&
              e.jugadorId == jugadorId,
        );

    return _registrar(
      partidoId,
      color == 'ROJA' ? 'TARJETA_ROJA' : 'TARJETA_AMARILLA',
      fase,
      minuto: minuto,
      jugadorId: jugadorId,
      autor: _nombres[jugadorId],
      dobleAmarilla: segundaAmarilla,
    );
  }

  @override
  Future<EstadoPartidoEnVivo> enviarDescanso(int partidoId) async =>
      _registrar(partidoId, 'DESCANSO', FasePartido.descanso);

  @override
  Future<EstadoPartidoEnVivo> enviarSegundaParte(int partidoId) async =>
      _registrar(partidoId, 'SEGUNDA_PARTE', FasePartido.segundaParte);

  @override
  Future<EstadoPartidoEnVivo> enviarFinalPartido(int partidoId) async =>
      _registrar(partidoId, 'FINAL', FasePartido.finalPartido);

  @override
  Future<EstadoPartidoEnVivo> deshacer(int partidoId, int eventoId) async {
    llamadas.add('deshacer:$eventoId');

    final anulado = eventos.removeLast();

    fase = switch (anulado.tipo) {
      'FINAL' => FasePartido.segundaParte,
      'SEGUNDA_PARTE' => FasePartido.descanso,
      'DESCANSO' => FasePartido.primeraParte,
      _ => fase,
    };

    return _estado(partidoId);
  }
}

const _unPartido = [
  PartidoEnVivoDisponible(
    id: 30,
    rival: 'Pego C.F.',
    hora: '11:00',
    local: true,
  ),
];

const _dosPartidos = [
  PartidoEnVivoDisponible(
    id: 30,
    rival: 'Pego C.F.',
    hora: '11:00',
    local: true,
  ),
  PartidoEnVivoDisponible(
    id: 31,
    rival: 'Villena',
    hora: '18:00',
    local: false,
  ),
];

Future<void> _pintar(
  WidgetTester tester,
  _ServicioFalso servicio,
  _Reloj reloj,
) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: PartidoEnVivoPage(service: servicio, ahora: () => reloj.ahora),
    ),
  );
  await tester.pumpAndSettle();
}

bool _habilitado(WidgetTester tester, String titulo) {
  final boton = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, titulo),
  );

  return boton.onPressed != null;
}

Future<void> _pulsarYConfirmar(WidgetTester tester, String titulo) async {
  await tester.tap(find.widgetWithText(ElevatedButton, titulo));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
  await tester.pumpAndSettle();
}

void main() {
  late _Reloj reloj;

  setUp(() => reloj = _Reloj());

  group('selector de partido', () {
    testWidgets('sin partidos hoy no deja empezar', (tester) async {
      await _pintar(tester, _ServicioFalso(reloj, const []), reloj);

      expect(
        find.text('No hay ningún partido del Primer Equipo hoy'),
        findsOneWidget,
      );
      expect(find.text('Inicio de partido'), findsNothing);
    });

    testWidgets('con un solo partido se selecciona directamente', (
      tester,
    ) async {
      final servicio = _ServicioFalso(reloj, _unPartido);

      await _pintar(tester, servicio, reloj);

      expect(find.text('Mutxamel 0 - 0 Pego C.F.'), findsOneWidget);
      expect(find.text('Sin empezar'), findsOneWidget);
      expect(servicio.llamadas, contains('estado:30'));
      // Con uno solo no hay nada que cambiar.
      expect(find.byIcon(Icons.swap_horiz), findsNothing);
    });

    testWidgets('con varios muestra rival, hora y local/visitante', (
      tester,
    ) async {
      final servicio = _ServicioFalso(reloj, _dosPartidos);

      await _pintar(tester, servicio, reloj);

      expect(
        find.text('Elige el partido que vas a retransmitir'),
        findsOneWidget,
      );
      expect(find.text('Pego C.F.'), findsOneWidget);
      expect(find.text('11:00 · Local'), findsOneWidget);
      expect(find.text('Villena'), findsOneWidget);
      expect(find.text('18:00 · Visitante'), findsOneWidget);
      expect(find.text('Inicio de partido'), findsNothing);

      await tester.tap(find.text('Villena'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, contains('estado:31'));
      expect(find.text('Inicio de partido'), findsOneWidget);

      // Se puede volver a elegir.
      await tester.tap(find.byIcon(Icons.swap_horiz));
      await tester.pumpAndSettle();

      expect(
        find.text('Elige el partido que vas a retransmitir'),
        findsOneWidget,
      );
    });
  });

  group('marcador', () {
    testWidgets('de local: "Mutxamel 2 - 1 Rival"', (tester) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      await _pintar(tester, servicio, reloj);

      await _pulsarYConfirmar(tester, 'Inicio de partido');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol a favor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pablo Garcia'));
      await tester.pumpAndSettle();

      reloj.avanzar(const Duration(minutes: 3));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol a favor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Luis Lopez'));
      await tester.pumpAndSettle();

      reloj.avanzar(const Duration(minutes: 3));
      await _pulsarYConfirmar(tester, 'Gol en contra');

      expect(find.text('Mutxamel 2 - 1 Pego C.F.'), findsOneWidget);
      expect(find.text('1ª parte'), findsOneWidget);
      expect(find.text('⚽ Pablo Garcia'), findsOneWidget);
      expect(find.text('⚽ Luis Lopez'), findsOneWidget);
    });

    testWidgets('de visitante el rival va primero', (tester) async {
      final servicio = _ServicioFalso(reloj, _unPartido, local: false);
      await _pintar(tester, servicio, reloj);

      await _pulsarYConfirmar(tester, 'Inicio de partido');
      await _pulsarYConfirmar(tester, 'Gol en contra');

      expect(find.text('Pego C.F. 1 - 0 Mutxamel'), findsOneWidget);
    });
  });

  group('botones por fase', () {
    testWidgets('solo se habilitan en el orden válido', (tester) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      await _pintar(tester, servicio, reloj);

      // Sin empezar: solo el inicio (y la alineación).
      expect(_habilitado(tester, 'Alineación'), isTrue);
      expect(_habilitado(tester, 'Inicio de partido'), isTrue);
      for (final titulo in [
        'Gol a favor',
        'Gol en contra',
        'Descanso',
        'Segunda parte',
        'Final de partido',
      ]) {
        expect(_habilitado(tester, titulo), isFalse, reason: titulo);
      }

      // Primera parte.
      await _pulsarYConfirmar(tester, 'Inicio de partido');
      expect(_habilitado(tester, 'Inicio de partido'), isFalse);
      expect(_habilitado(tester, 'Gol a favor'), isTrue);
      expect(_habilitado(tester, 'Gol en contra'), isTrue);
      expect(_habilitado(tester, 'Descanso'), isTrue);
      expect(_habilitado(tester, 'Segunda parte'), isFalse);
      expect(_habilitado(tester, 'Final de partido'), isTrue);

      // Descanso: sin goles, solo segunda parte (o final).
      await _pulsarYConfirmar(tester, 'Descanso');
      expect(find.text('Descanso'), findsWidgets);
      expect(_habilitado(tester, 'Gol a favor'), isFalse);
      expect(_habilitado(tester, 'Gol en contra'), isFalse);
      expect(_habilitado(tester, 'Descanso'), isFalse);
      expect(_habilitado(tester, 'Segunda parte'), isTrue);

      // Segunda parte.
      await _pulsarYConfirmar(tester, 'Segunda parte');
      expect(_habilitado(tester, 'Gol a favor'), isTrue);
      expect(_habilitado(tester, 'Segunda parte'), isFalse);
      expect(_habilitado(tester, 'Final de partido'), isTrue);

      // Final: ya no se puede nada salvo la alineación.
      await _pulsarYConfirmar(tester, 'Final de partido');
      expect(find.text('Final'), findsOneWidget);
      for (final titulo in [
        'Inicio de partido',
        'Gol a favor',
        'Gol en contra',
        'Descanso',
        'Segunda parte',
        'Final de partido',
      ]) {
        expect(_habilitado(tester, titulo), isFalse, reason: titulo);
      }
    });
  });

  group('autor del gol', () {
    Future<void> iniciarYAbrirSelector(
      WidgetTester tester,
      _ServicioFalso s,
    ) async {
      await _pintar(tester, s, reloj);
      await _pulsarYConfirmar(tester, 'Inicio de partido');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol a favor'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'la hoja lista a los convocados con su dorsal y no hay texto libre como opción principal',
      (tester) async {
        await iniciarYAbrirSelector(tester, _ServicioFalso(reloj, _unPartido));

        expect(find.text('¿Quién ha marcado?'), findsOneWidget);
        expect(find.text('Luis Lopez'), findsOneWidget);
        expect(find.text('Pablo Garcia'), findsOneWidget);
        expect(find.text('9'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('Otro…'), findsOneWidget);
        expect(find.text('Propia puerta (rival)'), findsOneWidget);
        // Lo único editable de la hoja es el minuto.
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byKey(const ValueKey('campo-minuto')), findsOneWidget);
      },
    );

    testWidgets(
      'el autor muestra también el nombre de retransmisión si lo tiene',
      (tester) async {
        final servicio = _ServicioFalso(reloj, _unPartido)
          ..convocadosForzados = const [
            ConvocadoEnVivo(
              jugadorId: 10,
              dorsal: 9,
              nombre: 'Pablo Garcia',
              nombreRetransmision: 'Pepe',
            ),
            ConvocadoEnVivo(
              jugadorId: 11,
              dorsal: 1,
              nombre: 'Luis Lopez',
              nombreRetransmision: 'Luis Lopez',
            ),
          ];
        await iniciarYAbrirSelector(tester, servicio);

        expect(find.text('Pablo Garcia'), findsOneWidget);
        expect(find.text('Pepe'), findsOneWidget);
        expect(find.text('Luis Lopez'), findsOneWidget);
      },
    );

    testWidgets('un convocado se envía por su jugadorId', (tester) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      await iniciarYAbrirSelector(tester, servicio);

      await tester.tap(find.text('Pablo Garcia'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, contains('autor:10/null'));
    });

    testWidgets(
      '"Otro…" pide un texto de hasta 60 caracteres y no admite vacío',
      (tester) async {
        final servicio = _ServicioFalso(reloj, _unPartido);
        await iniciarYAbrirSelector(tester, servicio);

        await tester.tap(find.text('Otro…'));
        await tester.pumpAndSettle();

        final campoOtro = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        final campo = tester.widget<TextField>(campoOtro);
        expect(campo.maxLength, 60);

        await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
        await tester.pumpAndSettle();
        expect(find.text('Escribe el autor del gol.'), findsOneWidget);
        expect(servicio.llamadas.where((l) => l.startsWith('autor:')), isEmpty);

        await tester.enterText(campoOtro, 'Un amigo');
        await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, contains('autor:null/Un amigo'));
        expect(find.text('⚽ Un amigo'), findsOneWidget);
      },
    );

    testWidgets('"Propia puerta" se envía como p.p.', (tester) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      await iniciarYAbrirSelector(tester, servicio);

      await tester.tap(find.text('Propia puerta (rival)'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, contains('autor:null/p.p.'));
      expect(find.text('⚽ p.p. (propia puerta del rival)'), findsOneWidget);
      expect(find.text('Mutxamel 1 - 0 Pego C.F.'), findsOneWidget);
    });

    testWidgets('el botón de gol está deshabilitado mientras cargan los '
        'convocados y no abre dos hojas', (tester) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      await _pintar(tester, servicio, reloj);
      await _pulsarYConfirmar(tester, 'Inicio de partido');

      final pendientes = Completer<List<ConvocadoEnVivo>>();
      servicio.convocadosPendientes = pendientes;

      expect(_habilitado(tester, 'Gol a favor'), isTrue);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol a favor'));
      await tester.pump();

      // Cargando: el botón no responde y se pidió la lista una sola vez.
      expect(_habilitado(tester, 'Gol a favor'), isFalse);
      expect(
        servicio.llamadas.where((l) => l.startsWith('convocados:')).length,
        1,
      );
      expect(find.text('¿Quién ha marcado?'), findsNothing);

      pendientes.complete(const [
        ConvocadoEnVivo(jugadorId: 10, dorsal: 9, nombre: 'Pablo Garcia'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('¿Quién ha marcado?'), findsOneWidget);
      expect(find.text('Pablo Garcia'), findsOneWidget);

      // Con la hoja abierta la carga ya terminó: al cerrarla el botón vuelve.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(_habilitado(tester, 'Gol a favor'), isTrue);
    });

    testWidgets('si falla la carga de convocados el botón vuelve a '
        'habilitarse', (tester) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      await _pintar(tester, servicio, reloj);
      await _pulsarYConfirmar(tester, 'Inicio de partido');

      final pendientes = Completer<List<ConvocadoEnVivo>>();
      servicio.convocadosPendientes = pendientes;

      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol a favor'));
      await tester.pump();
      expect(_habilitado(tester, 'Gol a favor'), isFalse);

      pendientes.completeError(Exception('sin conexión'));
      await tester.pumpAndSettle();

      // Se puede seguir con "Otro…" o "Propia puerta".
      expect(find.text('Otro…'), findsOneWidget);
    });
  });

  group('deshacer', () {
    testWidgets(
      'la barra cuenta atrás desde 2:00 y desaparece a los 2 minutos',
      (tester) async {
        final servicio = _ServicioFalso(reloj, _unPartido);
        await _pintar(tester, servicio, reloj);
        await _pulsarYConfirmar(tester, 'Inicio de partido');

        // El inicio no se puede deshacer.
        expect(find.byIcon(Icons.undo), findsNothing);

        await _pulsarYConfirmar(tester, 'Gol en contra');

        expect(find.text('Deshacer (2:00)'), findsOneWidget);
        expect(find.text('Último aviso: Gol en contra'), findsOneWidget);

        reloj.avanzar(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Deshacer (1:59)'), findsOneWidget);

        reloj.avanzar(const Duration(seconds: 59));
        await tester.pump(const Duration(seconds: 59));
        expect(find.text('Deshacer (1:00)'), findsOneWidget);

        reloj.avanzar(const Duration(seconds: 60));
        await tester.pump(const Duration(seconds: 60));

        expect(find.textContaining('Deshacer ('), findsNothing);
        expect(find.byIcon(Icons.undo), findsNothing);
      },
    );

    testWidgets('al pulsar deshace el gol y el marcador vuelve atrás', (
      tester,
    ) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      await _pintar(tester, servicio, reloj);
      await _pulsarYConfirmar(tester, 'Inicio de partido');
      await _pulsarYConfirmar(tester, 'Gol en contra');

      expect(find.text('Mutxamel 0 - 1 Pego C.F.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      expect(servicio.llamadas.any((l) => l.startsWith('deshacer:')), isTrue);
      expect(find.text('Mutxamel 0 - 0 Pego C.F.'), findsOneWidget);
      expect(find.text('Aviso deshecho.'), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsNothing);
    });

    testWidgets('deshacer el final pide confirmación antes', (tester) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      await _pintar(tester, servicio, reloj);
      await _pulsarYConfirmar(tester, 'Inicio de partido');
      await _pulsarYConfirmar(tester, 'Final de partido');

      expect(find.text('Final'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      expect(find.text('¿Deshacer el final?'), findsOneWidget);

      // Cancelar no deshace nada.
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas.any((l) => l.startsWith('deshacer:')), isFalse);
      expect(find.text('Final'), findsOneWidget);

      // Confirmar sí.
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Deshacer'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas.any((l) => l.startsWith('deshacer:')), isTrue);
      expect(find.text('2ª parte'), findsOneWidget);
    });

    testWidgets('deshacer un gol no pide confirmación', (tester) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      await _pintar(tester, servicio, reloj);
      await _pulsarYConfirmar(tester, 'Inicio de partido');
      await _pulsarYConfirmar(tester, 'Gol en contra');

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('la cuenta atrás usa los segundos del servidor, no la hora '
        'del móvil', (tester) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      await _pintar(tester, servicio, reloj);
      await _pulsarYConfirmar(tester, 'Inicio de partido');

      // El servidor dice que quedan 90 s aunque, con la hora del móvil, el
      // evento sea de hace unos instantes (el móvil va desfasado).
      servicio.segundosForzados = 90;
      await _pulsarYConfirmar(tester, 'Gol en contra');

      expect(find.text('Deshacer (1:30)'), findsOneWidget);

      reloj.avanzar(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Deshacer (1:00)'), findsOneWidget);

      reloj.avanzar(const Duration(seconds: 60));
      await tester.pump(const Duration(seconds: 60));
      expect(find.byIcon(Icons.undo), findsNothing);
    });

    testWidgets('sin segundos del servidor no se ofrece deshacer', (
      tester,
    ) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      await _pintar(tester, servicio, reloj);
      await _pulsarYConfirmar(tester, 'Inicio de partido');

      servicio.segundosForzados = 0;
      await _pulsarYConfirmar(tester, 'Gol en contra');

      expect(find.byIcon(Icons.undo), findsNothing);
    });

    test('el modelo lee segundosRestantesDeshacer', () {
      final estado = EstadoPartidoEnVivo.fromJson({
        'partidoId': 30,
        'eventos': [
          {'id': 5, 'tipo': 'GOL_CONTRA'},
        ],
        'ultimoEventoDeshacible': {
          'id': 5,
          'expira': '2026-10-24T11:02:00',
          'segundosRestantesDeshacer': 87,
        },
      });

      expect(estado.deshacibleId, 5);
      expect(estado.deshacibleSegundos, 87);
      expect(
        EstadoPartidoEnVivo.fromJson({'partidoId': 30}).deshacibleSegundos,
        isNull,
      );
    });
  });

  group('errores', () {
    testWidgets(
      'si el servidor rechaza un evento se avisa y se vuelve a leer el estado',
      (tester) async {
        final servicio = _ServicioFalso(reloj, _unPartido);
        await _pintar(tester, servicio, reloj);

        servicio.rechazarElSiguiente = true;
        final antes = servicio.llamadas.where((l) => l == 'estado:30').length;

        await _pulsarYConfirmar(tester, 'Inicio de partido');

        expect(
          find.textContaining('El partido ya ha terminado'),
          findsOneWidget,
        );
        expect(
          servicio.llamadas.where((l) => l == 'estado:30').length,
          greaterThan(antes),
        );
      },
    );
  });

  group('minuto del gol', () {
    final campoMinuto = find.byKey(const ValueKey('campo-minuto'));

    String? textoCampo(WidgetTester tester) =>
        tester.widget<TextField>(campoMinuto).controller?.text;

    Future<_ServicioFalso> empezar(WidgetTester tester, {int? minuto}) async {
      final servicio = _ServicioFalso(reloj, _unPartido);
      servicio.minutoActual = minuto;
      await _pintar(tester, servicio, reloj);
      await _pulsarYConfirmar(tester, 'Inicio de partido');
      return servicio;
    }

    Future<void> abrirSelectorGol(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol a favor'));
      await tester.pumpAndSettle();
    }

    testWidgets('el diálogo del gol a favor trae el minuto actual y se envía '
        'con el autor', (tester) async {
      final servicio = await empezar(tester, minuto: 23);

      await abrirSelectorGol(tester);

      expect(textoCampo(tester), '23');

      await tester.tap(find.text('Pablo Garcia'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, contains('minuto-gol:23'));
      expect(find.text("⚽ 23' Pablo Garcia"), findsOneWidget);
    });

    testWidgets(
      'al abrir el diálogo del gol recarga el estado y usa su minuto',
      (tester) async {
        final servicio = await empezar(tester, minuto: 23);
        servicio.llamadas.clear();

        // El partido ha avanzado en el servidor desde la última vez que se leyó.
        servicio.minutoActual = 40;

        await abrirSelectorGol(tester);

        expect(servicio.llamadas, contains('estado:30'));
        expect(textoCampo(tester), '40');

        // Sigue siendo un valor editable.
        await tester.enterText(campoMinuto, '41');
        await tester.tap(find.text('Pablo Garcia'));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, contains('minuto-gol:41'));
      },
    );

    testWidgets('si la recarga falla suma los minutos transcurridos', (
      tester,
    ) async {
      final servicio = await empezar(tester, minuto: 23);

      servicio.fallarEstado = true;
      reloj.avanzar(const Duration(minutes: 5, seconds: 30));

      await abrirSelectorGol(tester);

      expect(textoCampo(tester), '28');
    });

    testWidgets('el gol en contra también recarga el minuto, con respaldo', (
      tester,
    ) async {
      final servicio = await empezar(tester, minuto: 23);

      servicio.minutoActual = 52;

      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol en contra'));
      await tester.pumpAndSettle();

      expect(textoCampo(tester), '52');

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      servicio.fallarEstado = true;
      reloj.avanzar(const Duration(minutes: 3));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol en contra'));
      await tester.pumpAndSettle();

      // El último estado recibido ya traía el 52.
      expect(textoCampo(tester), '55');
    });

    testWidgets('el minuto es editable y se envía el escrito', (tester) async {
      final servicio = await empezar(tester);

      await abrirSelectorGol(tester);
      await tester.enterText(campoMinuto, '17');
      await tester.tap(find.text('Luis Lopez'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, contains('minuto-gol:17'));
      expect(find.text("⚽ 17' Luis Lopez"), findsOneWidget);
    });

    testWidgets('un minuto fuera de 0-150 no deja enviar el gol', (
      tester,
    ) async {
      final servicio = await empezar(tester);

      await abrirSelectorGol(tester);
      await tester.enterText(campoMinuto, '151');
      await tester.tap(find.text('Luis Lopez'));
      await tester.pumpAndSettle();

      expect(find.text('El minuto debe estar entre 0 y 150.'), findsOneWidget);
      expect(
        servicio.llamadas.where((l) => l.startsWith('minuto-gol')),
        isEmpty,
      );

      // Con 150 sí.
      await tester.enterText(campoMinuto, '150');
      await tester.tap(find.text('Luis Lopez'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, contains('minuto-gol:150'));
    });

    testWidgets('el campo del minuto es numérico', (tester) async {
      await empezar(tester);
      await abrirSelectorGol(tester);

      final campo = tester.widget<TextField>(campoMinuto);
      expect(campo.keyboardType, TextInputType.number);

      await tester.enterText(campoMinuto, 'ab1c2');
      expect(textoCampo(tester), '12');
    });

    testWidgets('vacío, el servidor calcula el minuto', (tester) async {
      final servicio = await empezar(tester);

      await abrirSelectorGol(tester);
      await tester.tap(find.text('Propia puerta (rival)'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, contains('minuto-gol:null'));
    });

    testWidgets('el gol en contra también pide el minuto', (tester) async {
      final servicio = await empezar(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol en contra'));
      await tester.pumpAndSettle();

      expect(campoMinuto, findsOneWidget);

      await tester.enterText(campoMinuto, '31');
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, contains('minuto-contra:31'));
      expect(find.text("🥅 31' Gol en contra"), findsOneWidget);
    });

    testWidgets('el gol en contra con un minuto no válido no se envía', (
      tester,
    ) async {
      final servicio = await empezar(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol en contra'));
      await tester.pumpAndSettle();
      await tester.enterText(campoMinuto, '200');
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(find.text('El minuto debe estar entre 0 y 150.'), findsOneWidget);
      expect(
        servicio.llamadas.where((l) => l.startsWith('minuto-contra')),
        isEmpty,
      );
    });

    testWidgets('pulsar un gol de la lista permite corregir su minuto', (
      tester,
    ) async {
      final servicio = await empezar(tester);

      await abrirSelectorGol(tester);
      await tester.enterText(campoMinuto, '12');
      await tester.tap(find.text('Pablo Garcia'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("⚽ 12' Pablo Garcia"));
      await tester.pumpAndSettle();

      expect(find.text('Corregir el minuto'), findsOneWidget);
      expect(textoCampo(tester), '12');

      await tester.enterText(campoMinuto, '14');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, contains('corregir:2:14'));
      expect(find.text("⚽ 14' Pablo Garcia"), findsOneWidget);
      expect(find.text('Minuto corregido.'), findsOneWidget);
    });

    testWidgets('la corrección exige un minuto válido y se puede cancelar', (
      tester,
    ) async {
      final servicio = await empezar(tester);

      await abrirSelectorGol(tester);
      await tester.enterText(campoMinuto, '12');
      await tester.tap(find.text('Pablo Garcia'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("⚽ 12' Pablo Garcia"));
      await tester.pumpAndSettle();
      await tester.enterText(campoMinuto, '');
      await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('El minuto debe estar entre 0 y 150.'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas.where((l) => l.startsWith('corregir')), isEmpty);
    });

    testWidgets('sin minuto en el evento se ve como antes', (tester) async {
      final servicio = await empezar(tester);

      await abrirSelectorGol(tester);
      await tester.enterText(campoMinuto, '');
      await tester.tap(find.text('Pablo Garcia'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, contains('minuto-gol:null'));
      expect(find.text('⚽ Pablo Garcia'), findsOneWidget);
    });
  });

  group('cambio y tarjeta', () {
    const jugadores = [
      ConvocadoEnVivo(jugadorId: 10, dorsal: 9, nombre: 'Pablo Garcia'),
      ConvocadoEnVivo(jugadorId: 11, dorsal: 1, nombre: 'Luis Lopez'),
      ConvocadoEnVivo(jugadorId: 12, dorsal: 14, nombre: 'Ana Ruiz'),
      ConvocadoEnVivo(jugadorId: 13, dorsal: 15, nombre: 'Juan Perez'),
    ];

    const alineacion = AlineacionEnVivo(
      formacion: '4-4-2',
      titulares: [10, 11],
      suplentes: [12, 13],
      enElCampo: [10, 11],
      suplentesDisponibles: [12, 13],
    );

    final campoMinuto = find.byKey(const ValueKey('campo-minuto'));

    Future<_ServicioFalso> empezar(
      WidgetTester tester, {
      AlineacionEnVivo? conAlineacion = alineacion,
      int? minuto = 23,
    }) async {
      final servicio = _ServicioFalso(reloj, _unPartido)
        ..convocadosForzados = jugadores
        ..alineacion = conAlineacion
        ..minutoActual = minuto;
      await _pintar(tester, servicio, reloj);
      await _pulsarYConfirmar(tester, 'Inicio de partido');
      return servicio;
    }

    Future<void> abrirCambio(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cambio'));
      await tester.pumpAndSettle();
    }

    Future<void> abrirTarjeta(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tarjeta'));
      await tester.pumpAndSettle();
    }

    Future<void> tocar(WidgetTester tester, String clave) async {
      await tester.tap(find.byKey(ValueKey(clave)));
      await tester.pumpAndSettle();
    }

    Future<void> confirmar(WidgetTester tester, String clave) async {
      await tester.tap(find.byKey(ValueKey(clave)));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'los botones solo valen con el partido en juego o en el descanso',
      (tester) async {
        final servicio = _ServicioFalso(reloj, _unPartido);
        await _pintar(tester, servicio, reloj);

        expect(_habilitado(tester, 'Cambio'), isFalse);
        expect(_habilitado(tester, 'Tarjeta'), isFalse);

        await _pulsarYConfirmar(tester, 'Inicio de partido');
        expect(_habilitado(tester, 'Cambio'), isTrue);
        expect(_habilitado(tester, 'Tarjeta'), isTrue);

        await _pulsarYConfirmar(tester, 'Descanso');
        expect(_habilitado(tester, 'Cambio'), isTrue);
        expect(_habilitado(tester, 'Tarjeta'), isTrue);

        await _pulsarYConfirmar(tester, 'Segunda parte');
        await _pulsarYConfirmar(tester, 'Final de partido');
        expect(_habilitado(tester, 'Cambio'), isFalse);
        expect(_habilitado(tester, 'Tarjeta'), isFalse);
      },
    );

    testWidgets(
      'con alineación, sale uno del campo y entra un suplente, con el minuto calculado',
      (tester) async {
        final servicio = await empezar(tester);
        await abrirCambio(tester);

        // Salen los que están en el campo; entran los suplentes disponibles.
        expect(find.byKey(const ValueKey('sale-10')), findsOneWidget);
        expect(find.byKey(const ValueKey('sale-11')), findsOneWidget);
        expect(find.byKey(const ValueKey('sale-12')), findsNothing);
        expect(find.byKey(const ValueKey('entra-12')), findsOneWidget);
        expect(find.byKey(const ValueKey('entra-13')), findsOneWidget);
        expect(find.byKey(const ValueKey('entra-10')), findsNothing);

        // El minuto viene calculado y es editable.
        expect(tester.widget<TextField>(campoMinuto).controller?.text, '23');

        // Sin elegir los dos no se puede enviar.
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('confirmar-cambio')),
              )
              .onPressed,
          isNull,
        );

        await tocar(tester, 'sale-10');
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('confirmar-cambio')),
              )
              .onPressed,
          isNull,
        );
        await tocar(tester, 'entra-12');
        await confirmar(tester, 'confirmar-cambio');

        expect(servicio.llamadas, contains('cambio:10>12:23'));
        expect(find.text('Cambio registrado.'), findsOneWidget);
        expect(
          find.text("🔄 23' Sale: Pablo Garcia · Entra: Ana Ruiz"),
          findsOneWidget,
        );

        // El estado se actualiza: el que entró puede salir y el que salió ya no.
        await abrirCambio(tester);
        expect(find.byKey(const ValueKey('sale-10')), findsNothing);
        expect(find.byKey(const ValueKey('sale-12')), findsOneWidget);
        expect(find.byKey(const ValueKey('entra-12')), findsNothing);
        expect(find.byKey(const ValueKey('entra-13')), findsOneWidget);
      },
    );

    testWidgets(
      'el minuto del cambio se puede editar y debe estar entre 0 y 150',
      (tester) async {
        final servicio = await empezar(tester);
        await abrirCambio(tester);

        await tocar(tester, 'sale-11');
        await tocar(tester, 'entra-13');

        await tester.enterText(campoMinuto, '200');
        await confirmar(tester, 'confirmar-cambio');
        expect(
          find.text('El minuto debe estar entre 0 y 150.'),
          findsOneWidget,
        );
        expect(servicio.llamadas.where((l) => l.startsWith('cambio')), isEmpty);

        await tester.enterText(campoMinuto, '31');
        await confirmar(tester, 'confirmar-cambio');
        expect(servicio.llamadas, contains('cambio:11>13:31'));
      },
    );

    testWidgets('en el descanso no hay minuto calculado y se manda sin él', (
      tester,
    ) async {
      final servicio = await empezar(tester, minuto: null);
      await _pulsarYConfirmar(tester, 'Descanso');
      await abrirCambio(tester);

      expect(tester.widget<TextField>(campoMinuto).controller?.text, '');

      await tocar(tester, 'sale-10');
      await tocar(tester, 'entra-12');
      await confirmar(tester, 'confirmar-cambio');

      expect(servicio.llamadas, contains('cambio:10>12:null'));
    });

    testWidgets(
      'sin alineación guardada valen todos los convocados y el que sale no puede entrar',
      (tester) async {
        await empezar(tester, conAlineacion: null);
        await abrirCambio(tester);

        for (final id in [10, 11, 12, 13]) {
          expect(find.byKey(ValueKey('sale-$id')), findsOneWidget);
          expect(find.byKey(ValueKey('entra-$id')), findsOneWidget);
        }

        await tocar(tester, 'sale-10');
        expect(find.byKey(const ValueKey('entra-10')), findsNothing);
        expect(find.byKey(const ValueKey('entra-11')), findsOneWidget);

        // Elegir como entrante a uno y luego hacerlo saliente lo quita de la elección.
        await tocar(tester, 'entra-11');
        await tocar(tester, 'sale-11');
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('confirmar-cambio')),
              )
              .onPressed,
          isNull,
        );
      },
    );

    testWidgets('el error del servidor se enseña en texto claro', (
      tester,
    ) async {
      final servicio = await empezar(tester);
      servicio.errorDeCambioOTarjeta =
          'El jugador que sale no está en el campo';

      await abrirCambio(tester);
      await tocar(tester, 'sale-10');
      await tocar(tester, 'entra-12');
      await confirmar(tester, 'confirmar-cambio');

      expect(
        find.textContaining('El jugador que sale no está en el campo'),
        findsOneWidget,
      );
      // Se vuelve a leer el estado y sigue sin haber cambio.
      expect(find.textContaining('🔄'), findsNothing);
    });

    testWidgets(
      'la tarjeta amarilla se envía con jugador y minuto y sale en la lista',
      (tester) async {
        final servicio = await empezar(tester);
        await abrirTarjeta(tester);

        expect(tester.widget<TextField>(campoMinuto).controller?.text, '23');
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('confirmar-tarjeta')),
              )
              .onPressed,
          isNull,
        );

        await tocar(tester, 'tarjeta-10');
        await confirmar(tester, 'confirmar-tarjeta');

        expect(servicio.llamadas, contains('tarjeta:10:AMARILLA:23'));
        expect(find.text('Tarjeta registrada.'), findsOneWidget);
        expect(find.text("🟨 23' Pablo Garcia"), findsOneWidget);
      },
    );

    testWidgets('la roja se elige con el selector de color', (tester) async {
      final servicio = await empezar(tester);
      await abrirTarjeta(tester);

      await tester.tap(find.text('Roja'));
      await tester.pumpAndSettle();
      await tocar(tester, 'tarjeta-11');
      await tester.enterText(campoMinuto, '40');
      await confirmar(tester, 'confirmar-tarjeta');

      expect(servicio.llamadas, contains('tarjeta:11:ROJA:40'));
      expect(find.text("🟥 40' Luis Lopez"), findsOneWidget);

      // Un expulsado ya no sale en la lista de jugadores para una tarjeta.
      await abrirTarjeta(tester);
      expect(find.byKey(const ValueKey('tarjeta-11')), findsNothing);
      expect(find.byKey(const ValueKey('tarjeta-10')), findsOneWidget);
    });

    testWidgets(
      'si es su segunda amarilla avisa de que será expulsión y la doble amarilla se anota como tal',
      (tester) async {
        final servicio = await empezar(tester);

        await abrirTarjeta(tester);
        await tocar(tester, 'tarjeta-10');
        // La primera amarilla no avisa de nada.
        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsNothing,
        );
        await confirmar(tester, 'confirmar-tarjeta');

        await abrirTarjeta(tester);
        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsNothing,
        );

        // Otro jugador sin amarilla: sin aviso.
        await tocar(tester, 'tarjeta-11');
        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsNothing,
        );

        // El que ya tiene una: aviso.
        await tocar(tester, 'tarjeta-10');
        expect(
          find.text('Es su segunda amarilla: será expulsado.'),
          findsOneWidget,
        );

        // Con roja no hay doble amarilla: sin aviso.
        await tester.tap(find.text('Roja'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsNothing,
        );
        await tester.tap(find.text('Amarilla'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsOneWidget,
        );

        await confirmar(tester, 'confirmar-tarjeta');

        expect(
          servicio.llamadas.where((l) => l.startsWith('tarjeta:10:AMARILLA')),
          hasLength(2),
        );
        expect(
          find.text("🟨 23' Pablo Garcia (expulsión por doble amarilla)"),
          findsOneWidget,
        );

        // Expulsado por la doble amarilla: ya no sale para otra tarjeta.
        await abrirTarjeta(tester);
        expect(find.byKey(const ValueKey('tarjeta-10')), findsNothing);
      },
    );

    testWidgets('el error de la tarjeta llega en texto claro', (tester) async {
      final servicio = await empezar(tester);
      servicio.errorDeCambioOTarjeta = 'El jugador ya ha sido expulsado';

      await abrirTarjeta(tester);
      await tocar(tester, 'tarjeta-10');
      await confirmar(tester, 'confirmar-tarjeta');

      expect(
        find.textContaining('El jugador ya ha sido expulsado'),
        findsOneWidget,
      );
    });

    testWidgets(
      'pulsar un cambio o una tarjeta de la lista corrige su minuto',
      (tester) async {
        final servicio = await empezar(tester);

        await abrirCambio(tester);
        await tocar(tester, 'sale-10');
        await tocar(tester, 'entra-12');
        await confirmar(tester, 'confirmar-cambio');

        await abrirTarjeta(tester);
        await tocar(tester, 'tarjeta-11');
        await confirmar(tester, 'confirmar-tarjeta');

        await tester.tap(find.textContaining('🔄'));
        await tester.pumpAndSettle();
        expect(find.text('Corregir el minuto'), findsOneWidget);
        await tester.enterText(campoMinuto, '25');
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, contains('corregir:2:25'));
        expect(
          find.text("🔄 25' Sale: Pablo Garcia · Entra: Ana Ruiz"),
          findsOneWidget,
        );

        await tester.tap(find.textContaining('🟨'));
        await tester.pumpAndSettle();
        await tester.enterText(campoMinuto, '26');
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, contains('corregir:3:26'));
        expect(find.text("🟨 26' Luis Lopez"), findsOneWidget);
      },
    );

    testWidgets(
      'se puede deshacer un cambio y una tarjeta, con su etiqueta en la barra',
      (tester) async {
        final servicio = await empezar(tester);

        await abrirCambio(tester);
        await tocar(tester, 'sale-10');
        await tocar(tester, 'entra-12');
        await confirmar(tester, 'confirmar-cambio');

        expect(find.text('Último aviso: Cambio'), findsOneWidget);

        await tester.tap(find.textContaining('Deshacer ('));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, contains('deshacer:2'));
        expect(find.textContaining('🔄'), findsNothing);

        await abrirTarjeta(tester);
        await tocar(tester, 'tarjeta-10');
        await confirmar(tester, 'confirmar-tarjeta');

        expect(find.text('Último aviso: Tarjeta'), findsOneWidget);

        await tester.tap(find.textContaining('Deshacer ('));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, contains('deshacer:3'));
        expect(find.textContaining('🟨'), findsNothing);
      },
    );

    testWidgets('sin cambios ni tarjetas lo dice', (tester) async {
      await empezar(tester);

      expect(find.text('Todavía no hay cambios ni tarjetas'), findsOneWidget);
    });

    test(
      'el modelo lee los campos nuevos del evento y la alineación del estado',
      () {
        final estado = EstadoPartidoEnVivo.fromJson({
          'partidoId': 30,
          'fase': 'SEGUNDA_PARTE',
          'eventos': [
            {
              'id': 5,
              'tipo': 'CAMBIO',
              'jugadorId': 10,
              'autor': 'Pablo Garcia',
              'minuto': 60,
              'jugadorEntraId': 12,
              'jugadorEntra': 'Ana Ruiz',
              'dobleAmarilla': false,
            },
            {
              'id': 6,
              'tipo': 'TARJETA_AMARILLA',
              'jugadorId': 11,
              'dobleAmarilla': true,
            },
          ],
          'alineacion': {
            'formacion': '4-4-2',
            'titulares': [10, 11],
            'suplentes': [12],
            'enElCampo': [11, 12],
            'suplentesDisponibles': [],
            'expulsados': [],
          },
        });

        expect(estado.eventos[0].jugadorEntraId, 12);
        expect(estado.eventos[0].jugadorEntra, 'Ana Ruiz');
        expect(estado.eventos[0].minutoCorregible, isTrue);
        expect(estado.eventos[1].dobleAmarilla, isTrue);
        expect(estado.eventos[1].esTarjeta, isTrue);
        expect(estado.alineacion!.formacion, '4-4-2');
        expect(estado.alineacion!.enElCampo, [11, 12]);

        // Un backend antiguo sin alineación.
        expect(
          EstadoPartidoEnVivo.fromJson({'partidoId': 1}).alineacion,
          isNull,
        );
      },
    );
  });

  group('eventos del rival, teclado y reloj', () {
    const jugadores = [
      ConvocadoEnVivo(jugadorId: 10, dorsal: 9, nombre: 'Pablo Garcia'),
      ConvocadoEnVivo(jugadorId: 11, dorsal: 1, nombre: 'Luis Lopez'),
      ConvocadoEnVivo(jugadorId: 12, dorsal: 7, nombre: 'Ana Ruiz'),
      ConvocadoEnVivo(jugadorId: 13, dorsal: 3, nombre: 'Juan Perez'),
    ];

    const alineacion = AlineacionEnVivo(
      formacion: '4-4-2',
      titulares: [10, 11],
      suplentes: [12, 13],
      enElCampo: [10, 11],
      suplentesDisponibles: [12, 13],
    );

    final campoMinuto = find.byKey(const ValueKey('campo-minuto'));
    final campoDorsal = find.byKey(const ValueKey('campo-dorsal'));

    Future<_ServicioFalso> empezar(WidgetTester tester) async {
      final servicio = _ServicioFalso(reloj, _unPartido)
        ..convocadosForzados = jugadores
        ..alineacion = alineacion
        ..minutoActual = 23;
      await _pintar(tester, servicio, reloj);
      await _pulsarYConfirmar(tester, 'Inicio de partido');
      return servicio;
    }

    Future<void> abrirTarjeta(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tarjeta'));
      await tester.pumpAndSettle();
    }

    Future<void> elegirRival(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('equipo-tarjeta')),
          matching: find.text('Rival'),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> enviarTarjeta(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('confirmar-tarjeta')));
      await tester.pumpAndSettle();
    }

    Future<void> golContra(
      WidgetTester tester, {
      String? minuto,
      String? dorsal,
    }) async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol en contra'));
      await tester.pumpAndSettle();

      if (minuto != null) await tester.enterText(campoMinuto, minuto);
      if (dorsal != null) await tester.enterText(campoDorsal, dorsal);

      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();
    }

    // ---- gol del rival con dorsal ----

    testWidgets('el gol del rival con dorsal lo envía y sale en la lista', (
      tester,
    ) async {
      final servicio = await empezar(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Gol en contra'));
      await tester.pumpAndSettle();

      // El diálogo tiene el campo opcional "Dorsal", numérico.
      expect(campoDorsal, findsOneWidget);
      expect(find.text('Dorsal'), findsOneWidget);
      expect(
        tester.widget<TextField>(campoDorsal).keyboardType,
        TextInputType.number,
      );

      await tester.enterText(campoMinuto, '31');
      await tester.enterText(campoDorsal, '9');
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, contains('minuto-contra:31'));
      expect(servicio.llamadas, contains('dorsal-contra:9'));
      expect(find.text("🥅 31' Gol en contra · Dorsal 9"), findsOneWidget);
    });

    testWidgets('el gol del rival sin dorsal se envía como antes', (
      tester,
    ) async {
      final servicio = await empezar(tester);

      await golContra(tester, minuto: '31');

      expect(servicio.llamadas, contains('dorsal-contra:null'));
      expect(find.text("🥅 31' Gol en contra"), findsOneWidget);
    });

    testWidgets(
      'el dorsal del gol del rival debe estar entre 0 y 99 (el 0 vale)',
      (tester) async {
        final servicio = await empezar(tester);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Gol en contra'));
        await tester.pumpAndSettle();

        // El campo solo deja escribir dos cifras: un 100 nunca llega a enviarse (queda en 10).
        await tester.enterText(campoDorsal, '100');
        expect(tester.widget<TextField>(campoDorsal).controller?.text, '10');

        await tester.enterText(campoDorsal, '0');
        await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, contains('dorsal-contra:0'));
      },
    );

    // ---- tarjeta del rival ----

    testWidgets(
      'la tarjeta del rival con dorsal envía rival y dorsal en lugar del jugador',
      (tester) async {
        final servicio = await empezar(tester);
        await abrirTarjeta(tester);

        // Mutxamel CF por defecto: la lista de jugadores, sin campo de dorsal.
        expect(find.byKey(const ValueKey('tarjeta-10')), findsOneWidget);
        expect(campoDorsal, findsNothing);

        await elegirRival(tester);

        // Rival: ni lista de jugadores ni hace falta elegir a nadie.
        expect(find.byKey(const ValueKey('tarjeta-10')), findsNothing);
        expect(campoDorsal, findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('confirmar-tarjeta')),
              )
              .onPressed,
          isNotNull,
        );

        await tester.enterText(campoDorsal, '9');
        await enviarTarjeta(tester);

        expect(servicio.llamadas, contains('tarjeta-rival:9:AMARILLA:23'));
        expect(find.text("🟨 23' Rival · Dorsal 9"), findsOneWidget);
      },
    );

    testWidgets(
      'la tarjeta del rival sin dorsal se envía igual (el dorsal es opcional)',
      (tester) async {
        final servicio = await empezar(tester);
        await abrirTarjeta(tester);
        await elegirRival(tester);

        await tester.tap(find.text('Roja'));
        await tester.pumpAndSettle();
        await enviarTarjeta(tester);

        expect(servicio.llamadas, contains('tarjeta-rival:null:ROJA:23'));
        expect(find.text("🟥 23' Rival"), findsOneWidget);
      },
    );

    testWidgets(
      'el dorsal de la tarjeta del rival solo admite dos cifras (0-99)',
      (tester) async {
        final servicio = await empezar(tester);
        await abrirTarjeta(tester);
        await elegirRival(tester);

        await tester.enterText(campoDorsal, '100');
        expect(tester.widget<TextField>(campoDorsal).controller?.text, '10');
        expect(
          tester.widget<TextField>(campoDorsal).keyboardType,
          TextInputType.number,
        );

        await tester.enterText(campoDorsal, '0');
        await enviarTarjeta(tester);

        expect(servicio.llamadas, contains('tarjeta-rival:0:AMARILLA:23'));
      },
    );

    testWidgets(
      'la segunda amarilla al mismo dorsal del rival avisa de que será expulsión',
      (tester) async {
        final servicio = await empezar(tester);

        await abrirTarjeta(tester);
        await elegirRival(tester);
        await tester.enterText(campoDorsal, '9');
        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsNothing,
        );
        await enviarTarjeta(tester);

        await abrirTarjeta(tester);
        await elegirRival(tester);

        // Sin dorsal o con otro dorsal: sin aviso.
        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsNothing,
        );
        await tester.enterText(campoDorsal, '4');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsNothing,
        );

        // El mismo dorsal: aviso.
        await tester.enterText(campoDorsal, '9');
        await tester.pumpAndSettle();
        expect(
          find.text('Es su segunda amarilla: será expulsado.'),
          findsOneWidget,
        );

        // Con roja no hay doble amarilla.
        await tester.tap(find.text('Roja'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsNothing,
        );
        await tester.tap(find.text('Amarilla'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsOneWidget,
        );

        await enviarTarjeta(tester);

        expect(
          find.text("🟨 23' Rival · Dorsal 9 (expulsión por doble amarilla)"),
          findsOneWidget,
        );
        expect(
          servicio.llamadas.where(
            (l) => l.startsWith('tarjeta-rival:9:AMARILLA'),
          ),
          hasLength(2),
        );
      },
    );

    testWidgets(
      'el aviso también sale con los dorsales con una amarilla que manda el servidor',
      (tester) async {
        final servicio = await empezar(tester);
        servicio.dorsalesRivalForzados = const [7];

        await abrirTarjeta(tester);
        await elegirRival(tester);
        await tester.enterText(campoDorsal, '7');
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'una tarjeta nuestra y una del rival no se mezclan: el 9 del rival no avisa por nuestro 9',
      (tester) async {
        await empezar(tester);

        // Amarilla a nuestro jugador de dorsal 9 (id 10).
        await abrirTarjeta(tester);
        await tester.tap(find.byKey(const ValueKey('tarjeta-10')));
        await tester.pumpAndSettle();
        await enviarTarjeta(tester);

        // El dorsal 9 del rival no tiene amarilla.
        await abrirTarjeta(tester);
        await elegirRival(tester);
        await tester.enterText(campoDorsal, '9');
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('aviso-segunda-amarilla')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'corregir el minuto de un evento del rival funciona y deshacer también',
      (tester) async {
        final servicio = await empezar(tester);

        await golContra(tester, minuto: '31', dorsal: '9');
        await abrirTarjeta(tester);
        await elegirRival(tester);
        await tester.enterText(campoDorsal, '5');
        await enviarTarjeta(tester);

        // Corregir el minuto de la tarjeta del rival.
        await tester.tap(find.text("🟨 23' Rival · Dorsal 5"));
        await tester.pumpAndSettle();
        await tester.enterText(campoMinuto, '25');
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
        await tester.pumpAndSettle();

        expect(servicio.llamadas.any((l) => l.startsWith('corregir:')), isTrue);
        expect(find.text("🟨 25' Rival · Dorsal 5"), findsOneWidget);

        // Y el dorsal del gol no cambia al corregir su minuto.
        await tester.tap(find.text("🥅 31' Gol en contra · Dorsal 9"));
        await tester.pumpAndSettle();
        await tester.enterText(campoMinuto, '33');
        await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
        await tester.pumpAndSettle();
        expect(find.text("🥅 33' Gol en contra · Dorsal 9"), findsOneWidget);

        // Deshacer la tarjeta del rival (el último evento).
        expect(find.text('Último aviso: Tarjeta'), findsOneWidget);
        await tester.tap(find.textContaining('Deshacer ('));
        await tester.pumpAndSettle();

        expect(servicio.llamadas.any((l) => l.startsWith('deshacer:')), isTrue);
        expect(find.textContaining('Rival · Dorsal 5'), findsNothing);
      },
    );

    test(
      'el modelo lee rival, dorsalRival y los dorsales con amarilla del estado',
      () {
        final estado = EstadoPartidoEnVivo.fromJson({
          'partidoId': 30,
          'fase': 'PRIMERA_PARTE',
          'dorsalesRivalConAmarilla': [4, 9],
          'eventos': [
            {
              'id': 5,
              'tipo': 'TARJETA_AMARILLA',
              'rival': true,
              'dorsalRival': 9,
              'jugadorId': null,
              'autor': null,
            },
            {'id': 6, 'tipo': 'GOL_CONTRA', 'rival': false, 'dorsalRival': 7},
            {'id': 7, 'tipo': 'GOL_CONTRA'},
          ],
        });

        expect(estado.dorsalesRivalConAmarilla, [4, 9]);
        expect(estado.eventos[0].rival, isTrue);
        expect(estado.eventos[0].dorsalRival, 9);
        expect(estado.eventos[1].rival, isFalse);
        expect(estado.eventos[1].dorsalRival, 7);

        // Un backend antiguo: sin los campos todo queda como antes.
        expect(estado.eventos[2].rival, isFalse);
        expect(estado.eventos[2].dorsalRival, isNull);
        expect(
          EstadoPartidoEnVivo.fromJson({
            'partidoId': 1,
          }).dorsalesRivalConAmarilla,
          isEmpty,
        );
      },
    );

    // ---- teclado: el botón Enviar queda visible y pulsable ----

    /// Pantalla baja y un teclado de 300 px abierto con la hoja ya pintada.
    Future<double> abrirTeclado(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 700);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      return 700 - 300;
    }

    testWidgets(
      'tarjeta: con el teclado abierto Enviar sigue visible y se puede pulsar',
      (tester) async {
        final servicio = await empezar(tester);
        await abrirTarjeta(tester);
        final limite = await abrirTeclado(tester);

        await tester.tap(campoMinuto);
        await tester.pumpAndSettle();

        final enviar = find.byKey(const ValueKey('confirmar-tarjeta'));
        expect(enviar, findsOneWidget);
        expect(tester.getRect(enviar).bottom, lessThanOrEqualTo(limite));

        // La lista se desplaza por encima: se elige un jugador y se envía con el botón fijo.
        await tester.ensureVisible(find.byKey(const ValueKey('tarjeta-10')));
        await tester.tap(find.byKey(const ValueKey('tarjeta-10')));
        await tester.pumpAndSettle();
        expect(tester.getRect(enviar).bottom, lessThanOrEqualTo(limite));

        await tester.tap(enviar);
        await tester.pumpAndSettle();

        expect(servicio.llamadas, contains('tarjeta:10:AMARILLA:23'));
      },
    );

    testWidgets(
      'tarjeta del rival: con el teclado abierto Enviar sigue visible',
      (tester) async {
        final servicio = await empezar(tester);
        await abrirTarjeta(tester);
        await elegirRival(tester);
        final limite = await abrirTeclado(tester);

        await tester.tap(campoDorsal);
        await tester.pumpAndSettle();
        await tester.enterText(campoDorsal, '9');

        final enviar = find.byKey(const ValueKey('confirmar-tarjeta'));
        expect(tester.getRect(enviar).bottom, lessThanOrEqualTo(limite));

        await tester.tap(enviar);
        await tester.pumpAndSettle();

        expect(servicio.llamadas, contains('tarjeta-rival:9:AMARILLA:23'));
      },
    );

    testWidgets(
      'cambio: con el teclado abierto Enviar sigue visible y se puede pulsar',
      (tester) async {
        final servicio = await empezar(tester);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Cambio'));
        await tester.pumpAndSettle();
        final limite = await abrirTeclado(tester);

        await tester.tap(campoMinuto);
        await tester.pumpAndSettle();

        final enviar = find.byKey(const ValueKey('confirmar-cambio'));
        expect(enviar, findsOneWidget);
        expect(tester.getRect(enviar).bottom, lessThanOrEqualTo(limite));

        await tester.ensureVisible(find.byKey(const ValueKey('sale-10')));
        await tester.tap(find.byKey(const ValueKey('sale-10')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('entra-12')));
        await tester.tap(find.byKey(const ValueKey('entra-12')));
        await tester.pumpAndSettle();

        expect(tester.getRect(enviar).bottom, lessThanOrEqualTo(limite));

        await tester.tap(enviar);
        await tester.pumpAndSettle();

        expect(servicio.llamadas, contains('cambio:10>12:23'));
      },
    );

    testWidgets(
      'gol: con el teclado abierto se llega a todos los autores sin que el teclado los tape',
      (tester) async {
        final servicio = await empezar(tester);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Gol a favor'));
        await tester.pumpAndSettle();
        final limite = await abrirTeclado(tester);

        await tester.tap(campoMinuto);
        await tester.pumpAndSettle();

        // Todo el contenido de la hoja queda por encima del teclado.
        expect(tester.getRect(campoMinuto).bottom, lessThanOrEqualTo(limite));

        // Lo último de la lista (Propia puerta) se alcanza desplazando y se puede elegir.
        final propia = find.text('Propia puerta (rival)');
        for (var i = 0; i < 10 && propia.evaluate().isEmpty; i++) {
          await tester.drag(
            find.byType(Scrollable).last,
            const Offset(0, -150),
          );
          await tester.pumpAndSettle();
        }
        await tester.pumpAndSettle();
        expect(tester.getRect(propia).bottom, lessThanOrEqualTo(limite));

        await tester.tap(propia);
        await tester.pumpAndSettle();

        expect(servicio.llamadas, contains('autor:null/p.p.'));
      },
    );

    testWidgets(
      'el campo del minuto se cierra con "Hecho" (done) y las hojas lo piden',
      (tester) async {
        await empezar(tester);
        await abrirTarjeta(tester);

        expect(
          tester.widget<TextField>(campoMinuto).textInputAction,
          TextInputAction.done,
        );

        await tester.tap(campoMinuto);
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isTrue);

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
      },
    );

    testWidgets(
      'tocar fuera del campo (en un hueco de la hoja) cierra el teclado',
      (tester) async {
        await empezar(tester);
        await abrirTarjeta(tester);

        await tester.tap(campoMinuto);
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isTrue);

        // El título de la hoja es un hueco sin acción: al tocarlo se cierra el teclado.
        await tester.tap(find.text('¿A quién se la han enseñado?'));
        await tester.pumpAndSettle();

        expect(tester.testTextInput.isVisible, isFalse);
      },
    );

    testWidgets(
      'en el diálogo del gol del rival el campo de minuto sigue a "Dorsal" y este se cierra con "Hecho"',
      (tester) async {
        await empezar(tester);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Gol en contra'));
        await tester.pumpAndSettle();

        expect(
          tester.widget<TextField>(campoMinuto).textInputAction,
          TextInputAction.next,
        );
        expect(
          tester.widget<TextField>(campoDorsal).textInputAction,
          TextInputAction.done,
        );
      },
    );

    // ---- reloj en la pantalla de retransmisión ----

    RelojDirecto relojPantalla({
      FaseReloj fase = FaseReloj.primeraParte,
      Duration enCurso = const Duration(minutes: 5),
      int minutoBase = 0,
    }) {
      final servidor = reloj.ahora;

      return RelojDirecto(
        fase: fase,
        inicioParteEpochMs: fase == FaseReloj.descanso
            ? null
            : servidor.subtract(enCurso).millisecondsSinceEpoch,
        minutoBase: minutoBase,
        minutosParte: 45,
        ahoraServidorEpochMs: servidor.millisecondsSinceEpoch,
        recibidoEn: servidor,
      );
    }

    testWidgets(
      'quien retransmite ve el reloj MM:ss y, en el descanso, no hay reloj',
      (tester) async {
        final servicio = _ServicioFalso(reloj, _unPartido)
          ..convocadosForzados = jugadores
          ..relojForzado = relojPantalla(
            enCurso: const Duration(minutes: 12, seconds: 4),
          );
        await _pintar(tester, servicio, reloj);

        // Antes del inicio no hay reloj (el servicio ya lo manda, pero se pinta con la fase).
        await _pulsarYConfirmar(tester, 'Inicio de partido');
        expect(find.byKey(const ValueKey('reloj-texto')), findsOneWidget);
        expect(find.text('12:04'), findsOneWidget);

        servicio.relojForzado = relojPantalla(
          fase: FaseReloj.descanso,
          minutoBase: 45,
        );
        await _pulsarYConfirmar(tester, 'Descanso');
        expect(find.byKey(const ValueKey('reloj-texto')), findsNothing);

        servicio.relojForzado = relojPantalla(
          fase: FaseReloj.segundaParte,
          minutoBase: 45,
          enCurso: const Duration(minutes: 2, seconds: 13),
        );
        await _pulsarYConfirmar(tester, 'Segunda parte');
        expect(find.text('47:13'), findsOneWidget);

        // Final: sin reloj.
        servicio.relojForzado = null;
        await _pulsarYConfirmar(tester, 'Final de partido');
        expect(find.byKey(const ValueKey('reloj-texto')), findsNothing);
      },
    );
  });
}
