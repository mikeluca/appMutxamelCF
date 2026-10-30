import 'dart:async';

import 'package:app_mutxamel_cf/core/navigation/app_navigator.dart';
import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/core/notifications/services/local_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/services/push_notification_service.dart';
import 'package:app_mutxamel_cf/core/notifications/utils/convocatoria_notificacion.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_service.dart';
import 'package:app_mutxamel_cf/features/invitados/models/invitacion_model.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _conUsuario(List<String> roles) => AuthManager.establecerUsuario(
  AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles),
);

class _FakeConvocatorias extends ConvocatoriaService {
  final List<int> pedidas = [];
  Object? fallo;

  @override
  Future<ConvocatoriaModel> obtenerPorId(int convocatoriaId) async {
    pedidas.add(convocatoriaId);

    if (fallo != null) throw fallo!;

    return ConvocatoriaModel(
      id: convocatoriaId,
      equipoId: 2,
      equipo: 'Cadete B',
      partidoId: 11,
      rival: 'Denia',
      campo: 'Campo',
      fechaPartido: '2026-11-14',
      horaPartido: '09:30',
      horaConvocatoria: '08:30',
      lugarConvocatoria: 'Vestuarios',
      usuarioEntrenadorId: 8,
      jugadores: const [],
    );
  }
}

RemoteMessage _push(String tipo, Map<String, String> data) => RemoteMessage(
  data: {'tipo': tipo, 'referenciaId': '90', ...data},
  notification: RemoteNotification(title: 'Aviso', body: 'Texto'),
);

Future<void> _pintarApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('HOME')),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => AuthManager.olvidarUsuario());
  tearDown(() => AuthManager.olvidarUsuario());

  group('los tipos INVITACION_*', () {
    test('son los del contrato y los dos que añade el cambio de fecha', () {
      expect(tiposPushInvitacion, {
        'INVITACION_PENDIENTE',
        'INVITACION_RECHAZADA',
        'INVITACION_LIBERAR',
        'INVITACION_INFORMATIVA',
        'INVITACION_AUTORIZADA',
        'INVITACION_PLAZO',
        'INVITACION_LIBERADA_COORDINACION',
        'INVITACION_DESESTIMADA',
        'INVITACION_ANULADA',
        'INVITACION_FECHA_CAMBIADA',
        'INVITACION_SOLAPAMIENTO',
      });
    });

    test('al abrir la app en frío esperan a que haya sesión y home', () {
      for (final tipo in tiposPushInvitacion) {
        expect(esAvisoDeConvocatoria(tipo: tipo), isTrue, reason: tipo);
      }

      expect(esAvisoDeConvocatoria(tipo: 'COMUNICACION'), isFalse);
    });
  });

  group('destino de cada aviso', () {
    test(
      'pendiente y plazo abren la lista de invitaciones, solo a coordinación',
      () async {
        for (final tipo in ['INVITACION_PENDIENTE', 'INVITACION_PLAZO']) {
          await _conUsuario(['COORDINADOR']);
          expect(
            destinoDeAvisoConvocatoria(
              tipo: tipo,
              datos: {'invitacionId': '31'},
            ),
            const AbrirInvitaciones(),
          );

          await _conUsuario(['ADMIN_APP']);
          expect(
            destinoDeAvisoConvocatoria(tipo: tipo),
            const AbrirInvitaciones(),
          );

          await _conUsuario(['ENTRENADOR']);
          expect(destinoDeAvisoConvocatoria(tipo: tipo), isNull);
        }
      },
    );

    test(
      'rechazada, desestimada y cambio de fecha abren esa convocatoria para elegir a otro',
      () async {
        await _conUsuario(['ENTRENADOR']);

        for (final tipo in [
          'INVITACION_RECHAZADA',
          'INVITACION_DESESTIMADA',
          'INVITACION_FECHA_CAMBIADA',
        ]) {
          expect(
            destinoDeAvisoConvocatoria(
              tipo: tipo,
              datos: {'convocatoriaId': '100'},
            ),
            const EditarConvocatoria(100),
            reason: tipo,
          );

          // Sin la convocatoria no hay nada que abrir.
          expect(destinoDeAvisoConvocatoria(tipo: tipo), isNull, reason: tipo);
        }
      },
    );

    test(
      'liberar abre la convocatoria de origen con el botón de liberar',
      () async {
        await _conUsuario(['ENTRENADOR']);

        expect(
          destinoDeAvisoConvocatoria(
            tipo: 'INVITACION_LIBERAR',
            datos: {
              'invitacionId': '31',
              'convocatoriaId': '100',
              'convocatoriaOrigenId': '101',
              'jugadorId': '1',
            },
          ),
          const AbrirLiberarInvitacion(
            convocatoriaId: 101,
            invitacionId: 31,
            jugadorId: 1,
          ),
        );
      },
    );

    test(
      'liberar sin convocatoria de origen: coordinación va a la lista; un entrenador, a nada',
      () async {
        final datos = {'invitacionId': '31', 'convocatoriaId': '100'};

        await _conUsuario(['COORDINADOR']);
        expect(
          destinoDeAvisoConvocatoria(tipo: 'INVITACION_LIBERAR', datos: datos),
          const AbrirInvitaciones(),
        );

        await _conUsuario(['ENTRENADOR']);
        expect(
          destinoDeAvisoConvocatoria(tipo: 'INVITACION_LIBERAR', datos: datos),
          isNull,
        );
      },
    );

    test(
      'autorizada, informativa, liberada por coordinación, anulada y solapamiento abren el calendario en ese día',
      () async {
        for (final roles in [
          ['ENTRENADOR'],
          ['FAMILIAR'],
          ['COORDINADOR'],
        ]) {
          await _conUsuario(roles);

          for (final tipo in [
            'INVITACION_AUTORIZADA',
            'INVITACION_INFORMATIVA',
            'INVITACION_LIBERADA_COORDINACION',
            'INVITACION_ANULADA',
            'INVITACION_SOLAPAMIENTO',
          ]) {
            expect(
              destinoDeAvisoConvocatoria(
                tipo: tipo,
                datos: {'fechaPartido': '2026-11-14'},
              ),
              AbrirCalendario(DateTime(2026, 11, 14)),
              reason: '$tipo $roles',
            );
          }
        }
      },
    );

    test('sin fecha en el aviso, el calendario se abre en hoy', () async {
      await _conUsuario(['FAMILIAR']);

      expect(
        destinoDeAvisoConvocatoria(tipo: 'INVITACION_ANULADA'),
        const AbrirCalendario(),
      );
    });

    test(
      'la bandeja, que solo guarda el tipo, abre la lista a coordinación',
      () async {
        await _conUsuario(['COORDINADOR']);

        expect(
          destinoDeTipoDeInvitacion('INVITACION_PENDIENTE'),
          const AbrirInvitaciones(),
        );
        expect(
          destinoDeTipoDeInvitacion('INVITACION_PLAZO'),
          const AbrirInvitaciones(),
        );
        expect(destinoDeTipoDeInvitacion('INVITACION_RECHAZADA'), isNull);
        expect(destinoDeTipoDeInvitacion(null), isNull);

        await _conUsuario(['ENTRENADOR']);
        expect(destinoDeTipoDeInvitacion('INVITACION_PENDIENTE'), isNull);
      },
    );
  });

  group('payload de la notificación local', () {
    test('ida y vuelta de la lista de invitaciones y del botón de liberar', () {
      for (final destino in <DestinoConvocatoria>[
        const AbrirInvitaciones(),
        const AbrirLiberarInvitacion(
          convocatoriaId: 101,
          invitacionId: 31,
          jugadorId: 1,
        ),
        const AbrirLiberarInvitacion(convocatoriaId: 101, invitacionId: 31),
      ]) {
        expect(destinoDePayload(payloadDeDestino(destino)), destino);
      }

      expect(payloadDeDestino(const AbrirInvitaciones()), 'INVITACIONES');
    });

    test('un payload de liberar sin los ids no abre nada', () {
      expect(destinoDePayload('LIBERAR_INVITACION:'), isNull);
      expect(destinoDePayload('LIBERAR_INVITACION:0|31'), isNull);
      expect(destinoDePayload('LIBERAR_INVITACION:101'), isNull);
    });

    test('payloadDeAviso lleva el destino de un INVITACION_*', () async {
      await _conUsuario(['COORDINADOR']);

      expect(
        LocalNotificationService.payloadDeAviso(
          comunicacionId: 90,
          titulo: 'Jugador invitado pendiente de aprobar',
          datos: {'tipo': 'INVITACION_PENDIENTE'},
        ),
        'INVITACIONES',
      );

      await _conUsuario(['FAMILIAR']);

      expect(
        LocalNotificationService.payloadDeAviso(
          comunicacionId: 90,
          titulo: 'Convocado con otro equipo',
          datos: {'tipo': 'INVITACION_ANULADA', 'fechaPartido': '2026-11-14'},
        ),
        'CALENDARIO:2026-11-14',
      );
    });
  });

  group('flujo de un push INVITACION_*', () {
    late List<({int comunicacionId, Map<String, dynamic> datos})> mostradas;
    late _FakeConvocatorias convocatorias;
    late List<String> abiertas;

    setUp(() {
      mostradas = [];
      abiertas = [];
      convocatorias = _FakeConvocatorias();

      PushNotificationService.contarNoLeidas = () async => 1;
      PushNotificationService.mostrarNotificacionLocal =
          ({
            required int comunicacionId,
            required String titulo,
            required String mensaje,
            int cantidadNoLeidas = 1,
            bool esPrivada = false,
            int? autorId,
            Map<String, dynamic> datos = const {},
          }) async {
            mostradas.add((comunicacionId: comunicacionId, datos: datos));
          };

      AppNavigator.fabricaConvocatoriaService = () => convocatorias;
      AppNavigator.constructorInvitaciones = () {
        abiertas.add('INVITACIONES');
        return const Scaffold(body: Text('LISTA INVITACIONES'));
      };
      AppNavigator.constructorLiberarInvitacion = (convocatoria, liberar) {
        abiertas.add(
          'LIBERAR:${convocatoria.id}:${liberar.invitacionId}:${liberar.jugadorId}',
        );
        return const Scaffold(body: Text('LIBERAR'));
      };
      AppNavigator.constructorEdicion = (convocatoria) {
        abiertas.add('EDICION:${convocatoria.id}');
        return const Scaffold(body: Text('EDICION'));
      };
      AppNavigator.constructorCalendario = (dia) {
        abiertas.add('CALENDARIO:$dia');
        return const Scaffold(body: Text('CALENDARIO'));
      };
    });

    tearDown(() {
      AppNavigator.fabricaConvocatoriaService = null;
      AppNavigator.constructorInvitaciones = null;
      AppNavigator.constructorLiberarInvitacion = null;
      AppNavigator.constructorEdicion = null;
      AppNavigator.constructorCalendario = null;
    });

    testWidgets(
      'con la app abierta se enseña como notificación local (no se descarta como tipo desconocido)',
      (tester) async {
        await _conUsuario(['COORDINADOR']);
        await _pintarApp(tester);

        for (final tipo in tiposPushInvitacion) {
          await PushNotificationService.mostrarEnPrimerPlano(_push(tipo, {}));
        }

        expect(mostradas, hasLength(tiposPushInvitacion.length));
      },
    );

    testWidgets('INVITACION_PENDIENTE toca y abre la lista de invitaciones', (
      tester,
    ) async {
      await _conUsuario(['COORDINADOR']);
      await _pintarApp(tester);

      unawaited(
        PushNotificationService.procesarNotificacion(
          _push('INVITACION_PENDIENTE', {'invitacionId': '31'}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LISTA INVITACIONES'), findsOneWidget);
      expect(abiertas, ['INVITACIONES']);
    });

    testWidgets(
      'INVITACION_LIBERAR toca y abre la convocatoria de origen con el botón',
      (tester) async {
        await _conUsuario(['ENTRENADOR']);
        await _pintarApp(tester);

        unawaited(
          PushNotificationService.procesarNotificacion(
            _push('INVITACION_LIBERAR', {
              'invitacionId': '31',
              'convocatoriaId': '100',
              'convocatoriaOrigenId': '101',
              'jugadorId': '1',
            }),
          ),
        );
        await tester.pumpAndSettle();

        // Pide la convocatoria de ORIGEN (101), no la de destino (100).
        expect(convocatorias.pedidas, [101]);
        expect(abiertas, ['LIBERAR:101:31:1']);
        expect(find.text('LIBERAR'), findsOneWidget);
      },
    );

    testWidgets(
      'si la convocatoria de origen ya no existe, un aviso y nada más',
      (tester) async {
        convocatorias.fallo = const ApiException('no existe', statusCode: 404);
        await _conUsuario(['ENTRENADOR']);
        await _pintarApp(tester);

        unawaited(
          PushNotificationService.procesarNotificacion(
            _push('INVITACION_LIBERAR', {
              'invitacionId': '31',
              'convocatoriaOrigenId': '101',
            }),
          ),
        );
        await tester.pumpAndSettle();

        expect(abiertas, isEmpty);
        expect(
          find.text('Esta convocatoria ya no está disponible'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'INVITACION_RECHAZADA toca y abre la edición de esa convocatoria',
      (tester) async {
        await _conUsuario(['ENTRENADOR']);
        await _pintarApp(tester);

        unawaited(
          PushNotificationService.procesarNotificacion(
            _push('INVITACION_RECHAZADA', {'convocatoriaId': '100'}),
          ),
        );
        await tester.pumpAndSettle();

        expect(convocatorias.pedidas, [100]);
        expect(abiertas, ['EDICION:100']);
      },
    );

    testWidgets(
      'INVITACION_AUTORIZADA toca y abre el calendario en el día del partido',
      (tester) async {
        await _conUsuario(['ENTRENADOR']);
        await _pintarApp(tester);

        unawaited(
          PushNotificationService.procesarNotificacion(
            _push('INVITACION_AUTORIZADA', {'fechaPartido': '2026-11-14'}),
          ),
        );
        await tester.pumpAndSettle();

        expect(abiertas, ['CALENDARIO:${DateTime(2026, 11, 14)}']);
      },
    );

    testWidgets(
      'la notificación local de un aviso de coordinación, al tocarla, abre la lista',
      (tester) async {
        await _conUsuario(['COORDINADOR']);
        await _pintarApp(tester);

        LocalNotificationService.procesarPayload('INVITACIONES');
        await tester.pumpAndSettle();

        expect(abiertas, ['INVITACIONES']);
      },
    );

    testWidgets(
      'con la app cerrada el aviso espera a que haya sesión y se abre al arrancar',
      (tester) async {
        PushNotificationService.restaurarSesion = () async =>
            AuthManager.estaAutenticado;
        PushNotificationService.simularMensajeInicial(
          _push('INVITACION_PENDIENTE', {'invitacionId': '31'}),
        );

        await _conUsuario(['COORDINADOR']);
        await _pintarApp(tester);

        await PushNotificationService.procesarNotificacionInicial();

        // Todavía nada: ni sesión ni pantalla abierta hasta que home esté pintada.
        expect(abiertas, isEmpty);

        unawaited(PushNotificationService.procesarAvisoPendiente());
        await tester.pumpAndSettle();

        expect(abiertas, ['INVITACIONES']);

        PushNotificationService.simularMensajeInicial(null);
      },
    );
  });

  group('modelo del aviso de liberar', () {
    test('guarda la invitación y el jugador', () {
      const liberar = LiberarInvitacion(invitacionId: 31, jugadorId: 1);

      expect(liberar.invitacionId, 31);
      expect(liberar.jugadorId, 1);
    });
  });
}
