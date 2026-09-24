/// Un artículo (prenda + unidades + tallas) dentro de un pedido de
/// la tienda. `tallas` debe tener tantos elementos como `cantidad`
/// (una talla por unidad), tal como espera POST /public/tienda/pedido.
class TiendaPedidoItem {
  final String prenda;
  final int cantidad;
  final List<String> tallas;

  const TiendaPedidoItem({
    required this.prenda,
    required this.cantidad,
    required this.tallas,
  });

  Map<String, dynamic> toJson() {
    return {'prenda': prenda, 'cantidad': cantidad, 'tallas': tallas};
  }
}
