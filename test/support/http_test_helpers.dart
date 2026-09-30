import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Ejecuta [body] con todas las llamadas HTTP de nivel superior
/// (http.get/post/put/delete, usadas por ApiClient) interceptadas por
/// [handler], usando el mecanismo oficial de http.runWithClient. Evita
/// tener que inyectar un cliente en ApiClient solo para poder probarlo.
Future<T> conMockHttp<T>(
  Future<http.Response> Function(http.Request request) handler,
  Future<T> Function() body,
) {
  return http.runWithClient(body, () => MockClient(handler));
}

/// Cliente que falla si se le llama: para probar que ApiClient/los
/// servicios que dependen de el NO hacen ninguna peticion de red cuando
/// no deberian (p.ej. sin sesion iniciada).
Future<T> conMockHttpQueNoDebeLlamarse<T>(Future<T> Function() body) {
  return conMockHttp(
    (request) async {
      throw StateError(
        'No se esperaba ninguna peticion HTTP, pero se llamo a '
        '${request.method} ${request.url}',
      );
    },
    body,
  );
}
