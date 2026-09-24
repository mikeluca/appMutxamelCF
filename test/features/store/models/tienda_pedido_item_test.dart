import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/features/store/models/tienda_pedido_item.dart';

void main() {
  group('TiendaPedidoItem.toJson', () {
    test('serializa prenda, cantidad y tallas', () {
      const item = TiendaPedidoItem(
        prenda: 'Camiseta oficial',
        cantidad: 2,
        tallas: ['M', 'L'],
      );

      expect(item.toJson(), {
        'prenda': 'Camiseta oficial',
        'cantidad': 2,
        'tallas': ['M', 'L'],
      });
    });

    test('conserva el valor exacto de prenda para AECC', () {
      const item = TiendaPedidoItem(
        prenda: 'Segunda equipacion - colaboracion AECC',
        cantidad: 1,
        tallas: ['S'],
      );

      expect(item.toJson()['prenda'], 'Segunda equipacion - colaboracion AECC');
    });
  });
}
