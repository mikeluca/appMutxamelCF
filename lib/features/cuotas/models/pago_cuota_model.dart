class PagoCuotaModel {
  final double importe;
  final String? fechaPagoFormateada;
  final String? metodoPago;

  const PagoCuotaModel({
    required this.importe,
    required this.fechaPagoFormateada,
    required this.metodoPago,
  });

  factory PagoCuotaModel.fromJson(Map<String, dynamic> json) {
    return PagoCuotaModel(
      importe: (json['importe'] as num?)?.toDouble() ?? 0,
      fechaPagoFormateada: json['fechaPagoFormateada'] as String?,
      metodoPago: json['metodoPago'] as String?,
    );
  }
}
