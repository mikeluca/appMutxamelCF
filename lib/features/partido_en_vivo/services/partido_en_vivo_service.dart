import '../../../core/network/api_client.dart';

class PartidoEnVivoService {
  Future<void> enviarAlineacion({
    required String onceInicial,
    required String suplentes,
  }) {
    return ApiClient.post(
      '/app/partido-en-vivo/alineacion',
      autenticado: true,
      body: {'onceInicial': onceInicial, 'suplentes': suplentes},
    );
  }

  Future<void> enviarInicioPartido() {
    return ApiClient.post('/app/partido-en-vivo/inicio', autenticado: true);
  }

  Future<void> enviarGolFavor(String autor) {
    return ApiClient.post(
      '/app/partido-en-vivo/gol-favor',
      autenticado: true,
      body: {'autor': autor},
    );
  }

  Future<void> enviarGolContra() {
    return ApiClient.post(
      '/app/partido-en-vivo/gol-contra',
      autenticado: true,
    );
  }

  Future<void> enviarDescanso() {
    return ApiClient.post('/app/partido-en-vivo/descanso', autenticado: true);
  }

  Future<void> enviarSegundaParte() {
    return ApiClient.post(
      '/app/partido-en-vivo/segunda-parte',
      autenticado: true,
    );
  }

  Future<void> enviarFinalPartido() {
    return ApiClient.post('/app/partido-en-vivo/final', autenticado: true);
  }
}
