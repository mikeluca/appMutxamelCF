import 'package:app_mutxamel_cf/features/partido_en_vivo/models/partido_en_vivo_models.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/pages/partido_en_vivo_page.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/services/partido_en_vivo_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      deshacibleId: deshacible ? ultimo.id : null,
      deshacibleExpira: deshacible
          ? ultimo.fecha!.add(const Duration(minutes: 2))
          : null,
    );
  }

  EstadoPartidoEnVivo _registrar(
    int partidoId,
    String tipo,
    FasePartido nuevaFase, {
    int? jugadorId,
    String? autor,
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
    return _estado(partidoId);
  }

  @override
  Future<List<ConvocadoEnVivo>> obtenerConvocados(int partidoId) async =>
      const [
        ConvocadoEnVivo(jugadorId: 11, dorsal: 1, nombre: 'Luis Lopez'),
        ConvocadoEnVivo(jugadorId: 10, dorsal: 9, nombre: 'Pablo Garcia'),
      ];

  @override
  Future<EstadoPartidoEnVivo> enviarInicioPartido(int partidoId) async =>
      _registrar(partidoId, 'INICIO', FasePartido.primeraParte);

  @override
  Future<EstadoPartidoEnVivo> enviarGolFavor(
    int partidoId, {
    int? jugadorId,
    String? autorTexto,
  }) async {
    llamadas.add('autor:$jugadorId/$autorTexto');

    return _registrar(
      partidoId,
      'GOL_FAVOR',
      fase,
      jugadorId: jugadorId,
      autor: jugadorId == 10
          ? 'Pablo Garcia'
          : jugadorId == 11
          ? 'Luis Lopez'
          : autorTexto,
    );
  }

  @override
  Future<EstadoPartidoEnVivo> enviarGolContra(int partidoId) async =>
      _registrar(partidoId, 'GOL_CONTRA', fase);

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
        expect(find.byType(TextField), findsNothing);
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

        final campo = tester.widget<TextField>(find.byType(TextField));
        expect(campo.maxLength, 60);

        await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
        await tester.pumpAndSettle();
        expect(find.text('Escribe el autor del gol.'), findsOneWidget);
        expect(servicio.llamadas.where((l) => l.startsWith('autor:')), isEmpty);

        await tester.enterText(find.byType(TextField), 'Un amigo');
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
}
