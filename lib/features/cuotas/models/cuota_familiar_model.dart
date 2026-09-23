import 'pago_cuota_model.dart';

class CuotaFamiliarModel {
  final int id;
  final int jugadorId;
  final String jugadorNombre;
  final String concepto;
  final String? periodo;
  final double importe;
  final String estado;
  final String? periodoFormateado;
  final bool vencida;
  final List<PagoCuotaModel> pagos;

  const CuotaFamiliarModel({
    required this.id,
    required this.jugadorId,
    required this.jugadorNombre,
    required this.concepto,
    required this.periodo,
    required this.importe,
    required this.estado,
    required this.periodoFormateado,
    required this.vencida,
    required this.pagos,
  });

  factory CuotaFamiliarModel.fromJson(Map<String, dynamic> json) {
    return CuotaFamiliarModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      jugadorId: (json['jugadorId'] as num?)?.toInt() ?? 0,
      jugadorNombre: json['jugadorNombre'] as String? ?? '',
      concepto: json['concepto'] as String? ?? 'Otros',
      periodo: json['periodo'] as String?,
      importe: (json['importe'] as num?)?.toDouble() ?? 0,
      estado: json['estado'] as String? ?? 'PENDIENTE',
      periodoFormateado: json['periodoFormateado'] as String?,
      vencida: json['vencida'] == true,
      pagos: (json['pagos'] as List<dynamic>? ?? [])
          .map((item) => PagoCuotaModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// "Cuota F8 - Septiembre / 2026" si tiene periodo, si no solo el
  /// concepto (no todas las cuotas son mensuales).
  String get tituloConPeriodo =>
      periodoFormateado != null ? '$concepto - $periodoFormateado' : concepto;
}
