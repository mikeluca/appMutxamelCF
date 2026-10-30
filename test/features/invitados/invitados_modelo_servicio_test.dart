import 'dart:convert';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/convocatorias/model/convocatoria_model.dart';
import 'package:app_mutxamel_cf/features/convocatorias/services/convocatoria_service.dart';
import 'package:app_mutxamel_cf/features/invitados/models/invitacion_model.dart';
import 'package:app_mutxamel_cf/features/invitados/services/invitados_service.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/teams/models/estadisticas_equipo_model.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/http_test_helpers.dart';

Map<String, dynamic> _convocatoriaJson() => {
  'id': 20,
  'equipoId': 5,
  'equipo': 'Cadete A',
  'partidoId': 30,
  'rival': 'Pego',
  'campo': 'Municipal',
  'fechaPartido': '2026-11-14',
  'horaPartido': '11:00',
  'horaConvocatoria': '10:00',
  'lugarConvocatoria': 'Vestuarios',
  'usuarioEntrenadorId': 1,
  'jugadores': [
    {
      'jugadorId': 6,
      'jugador': 'Fran Gil',
      'ausenciaJustificada': false,
      'motivoAusencia': null,
      'invitado': false,
      'equipoOrigenId': null,
      'equipoOrigen': null,
      'estadoInvitacion': null,
      'motivoRechazo': null,
    },
    {
      'jugadorId': 1,
      'jugador': 'Ana Pérez',
      'ausenciaJustificada': false,
      'invitado': true,
      'equipoOrigenId': 2,
      'equipoOrigen': 'Cadete B',
      'estadoInvitacion': 'AUTORIZADO',
    },
    {
      'jugadorId': 2,
      'jugador': 'Biel Gil',
      'invitado': true,
      'equipoOrigenId': 2,
      'equipoOrigen': 'Cadete B',
      'estadoInvitacion': 'PENDIENTE_ENTRENADOR',
    },
    {
      'jugadorId': 3,
      'jugador': 'Carla Sanz',
      'invitado': true,
      'equipoOrigenId': 3,
      'equipoOrigen': 'Infantil A',
      'estadoInvitacion': 'RECHAZADO',
      'motivoRechazo': 'Ese día juega con su equipo',
    },
  ],
};

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      <String, String>{},
    );
  });

  Future<void> iniciarSesion() => AuthSession.guardarSesion(
    LoginResponse(token: 't', usuarioId: 1, email: 'a@a.com', roles: const []),
  );

  group('modelo de la convocatoria', () {
    test('lee los invitados con su equipo de origen y su estado', () {
      final c = ConvocatoriaModel.fromJson(_convocatoriaJson());

      final propio = c.jugadores[0];

      expect(propio.invitado, isFalse);
      expect(propio.estadoInvitacion, isNull);
      expect(propio.juega, isTrue);

      final autorizado = c.jugadores[1];

      expect(autorizado.invitado, isTrue);
      expect(autorizado.equipoOrigen, 'Cadete B');
      expect(autorizado.equipoOrigenId, 2);
      expect(autorizado.estadoInvitacion, EstadoInvitacion.autorizado);
      expect(autorizado.juega, isTrue);

      expect(c.jugadores[2].pendiente, isTrue);
      expect(c.jugadores[2].juega, isFalse);

      final rechazado = c.jugadores[3];

      expect(rechazado.rechazado, isTrue);
      expect(rechazado.motivoRechazo, 'Ese día juega con su equipo');
      expect(rechazado.juega, isFalse);
    });

    test('separa propios, invitados, los que juegan y los rechazados', () {
      final c = ConvocatoriaModel.fromJson(_convocatoriaJson());

      expect(c.propios.map((j) => j.jugadorId), [6]);
      expect(c.invitados.map((j) => j.jugadorId), [1, 2, 3]);
      expect(c.queJuegan.map((j) => j.jugadorId), [6, 1]);
      expect(c.invitadosRechazados.map((j) => j.jugadorId), [3]);
    });

    test(
      'una respuesta antigua, sin los campos nuevos, es de un jugador propio',
      () {
        final j = ConvocatoriaJugadorModel.fromJson({
          'jugadorId': 9,
          'jugador': 'Luis',
        });

        expect(j.invitado, isFalse);
        expect(j.estadoInvitacion, isNull);
        expect(j.juega, isTrue);
      },
    );

    test('el formulario recibe los invitados con su estado', () {
      final c = ConvocatoriaModel.fromJson(_convocatoriaJson());
      final elegidos = c.invitadosParaFormulario;

      expect(elegidos.map((e) => e.jugadorId), [1, 2, 3]);
      expect(elegidos[0].cuenta, isTrue);
      expect(elegidos[2].rechazado, isTrue);
      expect(elegidos[2].cuenta, isFalse);
    });

    test('un invitado desestimado por la familia no cuenta para el máximo', () {
      const elegido = InvitadoElegido(
        jugadorId: 1,
        nombre: 'Ana',
        equipoOrigen: 'Cadete B',
        estado: EstadoInvitacion.autorizado,
        ausenciaJustificada: true,
      );

      expect(elegido.cuenta, isFalse);
    });
  });

  group('otros modelos', () {
    test('el partido del calendario lleva si el jugador es invitado', () {
      final invitado = MatchModel.fromJson({
        'id': 10,
        'equipo': 'Cadete A',
        'rival': 'Pego',
        'invitado': true,
        'convocado': true,
      });

      expect(invitado.invitado, isTrue);
      expect(MatchModel.fromJson({'rival': 'Elx'}).invitado, isFalse);
    });

    test('las estadísticas y las tarjetas marcan al invitado', () {
      final tarjetas = TarjetasJugadorModel.fromJson({
        'jugadorId': 1,
        'nombre': 'Ana',
        'amarillas': 2,
        'rojas': 0,
        'estado': 'OK',
        'invitado': true,
      });

      expect(tarjetas.invitado, isTrue);

      final goleador = JugadorDestacadoModel.fromJson({
        'jugadorId': 1,
        'nombre': 'Ana',
        'goles': 3,
        'invitado': true,
      });

      expect(goleador.invitado, isTrue);
      expect(
        JugadorDestacadoModel.fromJson({
          'jugadorId': 2,
          'nombre': 'Luis',
        }).invitado,
        isFalse,
      );
    });

    test(
      'lee una invitación pendiente con su solapamiento y la otra invitación',
      () {
        final i = InvitacionPendienteModel.fromJson({
          'id': 31,
          'estado': 'PENDIENTE_ENTRENADOR',
          'convocatoriaId': 100,
          'partidoId': 10,
          'jugadorId': 1,
          'jugador': 'Ana Pérez',
          'equipoOrigenId': 2,
          'equipoOrigen': 'Cadete B',
          'equipoDestinoId': 1,
          'equipoDestino': 'Cadete A',
          'fechaPartido': '2026-11-14',
          'horaPartido': '11:00',
          'rival': 'Pego',
          'usuarioInvitaId': 7,
          'convoca': 'Cuerpo técnico de Cadete A',
          'fechaPeticionEntrenador': '2026-11-12T10:05:00',
          'plazoVencido': true,
          'jugadorConvocadoEnOrigen': true,
          'solapamiento': [
            {'partidoId': 11, 'hora': '09:30', 'rival': 'Denia'},
          ],
          'otraInvitacion': {
            'convocatoriaJugadorId': 40,
            'equipoDestinoId': 6,
            'equipoDestino': 'Cadete C',
            'partidoId': 13,
            'horaPartido': '12:00',
            'rival': 'Javea',
            'estado': 'PENDIENTE_COORDINACION',
          },
        });

        expect(i.estado, EstadoInvitacion.pendienteEntrenador);
        expect(i.fechaPartido, DateTime(2026, 11, 14));
        expect(i.plazoVencido, isTrue);
        expect(i.solapamiento.single.rival, 'Denia');
        expect(i.otraInvitacion!.equipoDestino, 'Cadete C');
        expect(
          i.otraInvitacion!.estado,
          EstadoInvitacion.pendienteCoordinacion,
        );
        expect(i.fechaPeticionEntrenador, DateTime(2026, 11, 12, 10, 5));
      },
    );

    test('sin otra invitación ni solapamiento, vienen vacíos', () {
      final i = InvitacionPendienteModel.fromJson({
        'id': 1,
        'estado': 'PENDIENTE_COORDINACION',
        'jugador': 'Ana',
        'equipoOrigen': 'B',
        'equipoDestino': 'A',
        'solapamiento': <dynamic>[],
        'otraInvitacion': null,
      });

      expect(i.solapamiento, isEmpty);
      expect(i.otraInvitacion, isNull);
      expect(i.plazoVencido, isFalse);
    });
  });

  group('conflicto 409', () {
    ApiException error(Object? cuerpo, {int estado = 409}) =>
        ApiException('texto', statusCode: estado, datos: cuerpo);

    test('se decide por el código, no por el mensaje', () {
      final c = ConflictoInvitacion.desde(
        error({
          'codigo': 'JUGADOR_INVITADO_ESE_DIA',
          'mensaje': 'cualquier texto',
          'jugadorId': 1,
          'equipoDestino': 'Cadete A',
          'fecha': '2026-11-14',
        }),
      );

      expect(c!.codigo, codigoJugadorInvitadoEseDia);
      expect(c.jugadorId, 1);
      expect(c.equipoDestino, 'Cadete A');
      expect(c.fecha, DateTime(2026, 11, 14));

      expect(
        ConflictoInvitacion.desde(
          error({
            'codigo': 'JUGADOR_YA_INVITADO_ESE_DIA',
            'equipoDestino': 'C',
          }),
        )!.codigo,
        codigoJugadorYaInvitadoEseDia,
      );
    });

    test(
      'no es un conflicto de invitaciones si no es 409, no trae código o es otro',
      () {
        expect(ConflictoInvitacion.desde(null), isNull);
        expect(ConflictoInvitacion.desde(Exception('x')), isNull);
        expect(
          ConflictoInvitacion.desde(
            error({'codigo': 'JUGADOR_INVITADO_ESE_DIA'}, estado: 400),
          ),
          isNull,
        );
        expect(ConflictoInvitacion.desde(error('texto plano')), isNull);
        expect(
          ConflictoInvitacion.desde(error({'codigo': 'PRUEBAS_SIN_CONFIRMAR'})),
          isNull,
        );
      },
    );
  });

  group('servicio de invitados', () {
    test('equipos y jugadores invitables de un partido', () async {
      await iniciarSesion();

      final equipos = await conMockHttp((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          endsWith('/app/partidos/10/invitables/equipos'),
        );
        expect(request.headers['Authorization'], 'Bearer t');
        return http.Response(
          jsonEncode([
            {
              'equipoId': 2,
              'nombre': 'Cadete B',
              'categoria': 'Cadete',
              'grupo': 'B',
            },
          ]),
          200,
        );
      }, () => InvitadosService().obtenerEquipos(10));

      expect(equipos.single.nombre, 'Cadete B');

      final jugadores = await conMockHttp((request) async {
        expect(
          request.url.path,
          endsWith('/app/partidos/10/invitables/equipos/2/jugadores'),
        );
        return http.Response(
          jsonEncode([
            {
              'jugadorId': 1,
              'nombre': 'Ana Pérez',
              'dorsal': 7,
              'yaInvitado': true,
              'bloqueado': false,
              'motivoBloqueo': null,
            },
            {
              'jugadorId': 2,
              'nombre': 'Biel Gil',
              'dorsal': 9,
              'yaInvitado': false,
              'bloqueado': true,
              'motivoBloqueo': 'Ya está invitado con Cadete C el 14/11/2026',
            },
          ]),
          200,
        );
      }, () => InvitadosService().obtenerJugadores(10, 2));

      expect(jugadores[0].yaInvitado, isTrue);
      expect(jugadores[1].bloqueado, isTrue);
      expect(jugadores[1].motivoBloqueo, contains('Cadete C'));
    });

    test('pendientes, aprobar, rechazar con y sin motivo, y liberar', () async {
      await iniciarSesion();

      final pendientes = await conMockHttp((request) async {
        expect(request.url.path, endsWith('/app/invitaciones/pendientes'));
        return http.Response(
          jsonEncode([
            {'id': 31, 'estado': 'PENDIENTE_COORDINACION', 'jugador': 'Ana'},
          ]),
          200,
        );
      }, () => InvitadosService().obtenerPendientes());

      expect(pendientes.single.id, 31);

      final aprobada = await conMockHttp((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/app/invitaciones/31/aprobar'));
        expect(request.body, isEmpty);
        return http.Response(
          jsonEncode({
            'id': 31,
            'estado': 'PENDIENTE_ENTRENADOR',
            'jugador': 'Ana',
          }),
          200,
        );
      }, () => InvitadosService().aprobar(31));

      expect(aprobada.estado, EstadoInvitacion.pendienteEntrenador);

      final rechazada = await conMockHttp((request) async {
        expect(request.url.path, endsWith('/app/invitaciones/31/rechazar'));
        expect(jsonDecode(request.body), {'motivo': 'Juega ese día'});
        return http.Response(
          jsonEncode({
            'id': 31,
            'estado': 'RECHAZADO',
            'motivoRechazo': 'Juega ese día',
          }),
          200,
        );
      }, () => InvitadosService().rechazar(31, motivo: '  Juega ese día  '));

      expect(rechazada.estado, EstadoInvitacion.rechazado);
      expect(rechazada.motivoRechazo, 'Juega ese día');

      // El motivo es opcional: sin él no se manda cuerpo.
      await conMockHttp((request) async {
        expect(request.body, isEmpty);
        return http.Response(
          jsonEncode({'id': 31, 'estado': 'RECHAZADO'}),
          200,
        );
      }, () => InvitadosService().rechazar(31, motivo: '   '));

      final liberada = await conMockHttp((request) async {
        expect(request.url.path, endsWith('/app/invitaciones/31/liberar'));
        return http.Response(
          jsonEncode({'id': 31, 'estado': 'AUTORIZADO'}),
          200,
        );
      }, () => InvitadosService().liberar(31));

      expect(liberada.estado, EstadoInvitacion.autorizado);
    });

    test(
      'desestimar manda el motivo al endpoint del partido y el jugador',
      () async {
        await iniciarSesion();

        final justificacion = await conMockHttp(
          (request) async {
            expect(request.method, 'POST');
            expect(
              request.url.path,
              endsWith('/app/partidos/10/invitados/1/desestimar'),
            );
            expect(jsonDecode(request.body), {'motivo': 'Cumpleaños'});
            return http.Response(
              jsonEncode({
                'partidoId': 10,
                'jugadorId': 1,
                'jugador': 'Ana',
                'motivo': 'Cumpleaños',
                'fechaCreacion': '2026-11-12T10:00:00',
              }),
              201,
            );
          },
          () => InvitadosService().desestimar(
            partidoId: 10,
            jugadorId: 1,
            motivo: 'Cumpleaños',
          ),
        );

        expect(justificacion.motivo, 'Cumpleaños');
      },
    );

    test('un 409 llega con su código para decidir el diálogo', () async {
      await iniciarSesion();

      final fallo = await conMockHttp(
        (request) async => http.Response(
          jsonEncode({
            'codigo': 'JUGADOR_YA_INVITADO_ESE_DIA',
            'mensaje': 'x',
            'jugadorId': 1,
            'equipoDestino': 'Cadete C',
            'fecha': '2026-11-14',
          }),
          409,
        ),
        () async {
          try {
            await InvitadosService().aprobar(31);
          } catch (e) {
            return e;
          }
          return null;
        },
      );

      final conflicto = ConflictoInvitacion.desde(fallo);

      expect(conflicto!.codigo, codigoJugadorYaInvitadoEseDia);
      expect(conflicto.equipoDestino, 'Cadete C');
    });
  });

  group('servicio de convocatorias', () {
    test(
      'crear y actualizar mandan invitadosIds siempre que se les pasa una lista',
      () async {
        await iniciarSesion();

        await conMockHttp(
          (request) async {
            expect(request.method, 'POST');
            expect(jsonDecode(request.body), {
              'partidoId': 30,
              'horaConvocatoria': '10:00',
              'lugarConvocatoria': 'Vestuarios',
              'jugadoresIds': [6],
              'invitadosIds': [1, 3],
              'equipacionId': null,
              'equipacionMochilaId': null,
              'equipajeIndicado': true,
            });
            return http.Response(jsonEncode(_convocatoriaJson()), 201);
          },
          () => ConvocatoriaService().crear(
            partidoId: 30,
            horaConvocatoria: '10:00',
            lugarConvocatoria: 'Vestuarios',
            jugadoresIds: [6],
            invitadosIds: [1, 3],
          ),
        );

        // Una lista vacía se manda (quita a todos), no se omite.
        await conMockHttp(
          (request) async {
            expect(request.method, 'PUT');
            expect(jsonDecode(request.body)['invitadosIds'], isEmpty);
            expect(
              jsonDecode(request.body).containsKey('invitadosIds'),
              isTrue,
            );
            return http.Response(jsonEncode(_convocatoriaJson()), 200);
          },
          () => ConvocatoriaService().actualizar(
            convocatoriaId: 20,
            partidoId: 30,
            horaConvocatoria: '10:00',
            lugarConvocatoria: 'Vestuarios',
            jugadoresIds: [6],
            invitadosIds: const [],
          ),
        );
      },
    );

    test(
      'sin invitadosIds no se manda el campo (el servidor no los toca)',
      () async {
        await iniciarSesion();

        await conMockHttp(
          (request) async {
            expect(
              jsonDecode(request.body).containsKey('invitadosIds'),
              isFalse,
            );
            return http.Response(jsonEncode(_convocatoriaJson()), 200);
          },
          () => ConvocatoriaService().actualizar(
            convocatoriaId: 20,
            partidoId: 30,
            horaConvocatoria: '10:00',
            lugarConvocatoria: 'Vestuarios',
          ),
        );
      },
    );
  });
}
