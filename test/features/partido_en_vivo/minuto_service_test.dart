import 'dart:convert';

import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/models/partido_en_vivo_models.dart';
import 'package:app_mutxamel_cf/features/partido_en_vivo/services/partido_en_vivo_service.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/http_test_helpers.dart';

http.Response _estado() => http.Response(
  jsonEncode({
    'partidoId': 30,
    'rival': 'Pego',
    'local': true,
    'fase': 'SEGUNDA_PARTE',
    'golesFavor': 1,
    'golesContra': 0,
    'goleadores': ['Pablo'],
    'eventos': [
      {'id': 4, 'tipo': 'GOL_FAVOR', 'autor': 'Pablo', 'minuto': 56},
      {'id': 5, 'tipo': 'DESCANSO'},
    ],
    'minutoActual': 57,
  }),
  200,
);

void main() {
  setUp(() async {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      <String, String>{},
    );
    await AuthSession.guardarSesion(
      LoginResponse(
        token: 'tok',
        usuarioId: 1,
        email: 'a@a.com',
        roles: const ['RETRANSMISION'],
      ),
    );
  });

  test('el estado lee el minuto de cada evento y el minuto actual', () {
    final estado = EstadoPartidoEnVivo.fromJson(
      jsonDecode(_estado().body) as Map<String, dynamic>,
    );

    expect(estado.minutoActual, 57);
    expect(estado.eventos.first.minuto, 56);
    expect(estado.eventos.last.minuto, isNull);
  });

  test('un backend antiguo sin minutos sigue funcionando', () {
    final estado = EstadoPartidoEnVivo.fromJson({
      'partidoId': 30,
      'eventos': [
        {'id': 1, 'tipo': 'GOL_FAVOR'},
      ],
    });

    expect(estado.minutoActual, isNull);
    expect(estado.eventos.single.minuto, isNull);
  });

  test('el gol a favor envía el minuto con el autor', () async {
    await conMockHttp((request) async {
      expect(request.url.path, endsWith('/partido-en-vivo/30/gol-favor'));
      expect(jsonDecode(request.body), {
        'jugadorId': 10,
        'autorTexto': null,
        'minuto': 23,
      });

      return _estado();
    }, () => PartidoEnVivoService().enviarGolFavor(30, jugadorId: 10, minuto: 23));
  });

  test('el gol en contra envía el minuto (o null para que lo calcule el '
      'servidor)', () async {
    await conMockHttp((request) async {
      expect(request.url.path, endsWith('/partido-en-vivo/30/gol-contra'));
      expect(jsonDecode(request.body), {'minuto': 31});

      return _estado();
    }, () => PartidoEnVivoService().enviarGolContra(30, minuto: 31));

    await conMockHttp((request) async {
      expect(jsonDecode(request.body), {'minuto': null});

      return _estado();
    }, () => PartidoEnVivoService().enviarGolContra(30));
  });

  test('corregir el minuto hace PATCH .../eventos/{id}/minuto', () async {
    final estado = await conMockHttp((request) async {
      expect(request.method, 'PATCH');
      expect(
        request.url.path,
        endsWith('/partido-en-vivo/30/eventos/4/minuto'),
      );
      expect(request.headers['Authorization'], 'Bearer tok');
      expect(jsonDecode(request.body), {'minuto': 12});

      return _estado();
    }, () => PartidoEnVivoService().corregirMinuto(30, 4, 12));

    expect(estado.partidoId, 30);
  });
}
