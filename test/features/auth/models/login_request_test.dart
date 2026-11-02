import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_request.dart';

void main() {
  group('LoginRequest.toJson', () {
    test('serializa email y password tal cual se le pasan', () {
      final request = LoginRequest(
        email: 'jugador@mutxamelcf.es',
        password: 'secreto123',
      );

      expect(request.toJson(), {
        'email': 'jugador@mutxamelcf.es',
        'password': 'secreto123',
      });
    });

    test('incluye el idioma cuando se informa y no lo envía cuando no', () {
      final con = LoginRequest(
        email: 'jugador@mutxamelcf.es',
        password: 'secreto123',
        idioma: 'ca',
      );

      expect(con.toJson()['idioma'], 'ca');
      expect(
        LoginRequest(email: 'a@a.es', password: 'x').toJson(),
        isNot(contains('idioma')),
      );
    });
  });
}
