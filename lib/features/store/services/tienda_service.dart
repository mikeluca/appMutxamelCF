import '../../../core/network/api_client.dart';
import '../models/tienda_pedido_item.dart';

class TiendaService {
  /// Envía un pedido de la tienda al club. Endpoint público (sin
  /// autenticación), igual que /public/resultados.
  Future<void> crearPedido({
    required String nombre,
    String? telefono,
    required String email,
    required List<TiendaPedidoItem> items,
  }) async {
    await ApiClient.post(
      '/public/tienda/pedido',
      body: {
        'nombre': nombre,
        'telefono': telefono,
        'email': email,
        'items': items.map((item) => item.toJson()).toList(),
      },
    );
  }
}
