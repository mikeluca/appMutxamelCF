import 'dart:ui';

/// Un equipaje del club (GET /app/equipaciones y los campos equipacion /
/// equipacionMochila de la convocatoria). camiseta, pantalon y medias son el color en
/// texto; colorHex ('#RRGGBB') es la muestra de color.
class EquipacionModel {
  final int id;
  final String nombre;
  final String? camiseta;
  final String? pantalon;
  final String? medias;
  final String? colorHex;

  const EquipacionModel({
    required this.id,
    required this.nombre,
    this.camiseta,
    this.pantalon,
    this.medias,
    this.colorHex,
  });

  factory EquipacionModel.fromJson(Map<String, dynamic> json) {
    String? texto(Object? valor) {
      final limpio = valor?.toString().trim();

      return limpio == null || limpio.isEmpty ? null : limpio;
    }

    return EquipacionModel(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      camiseta: texto(json['camiseta']),
      pantalon: texto(json['pantalon']),
      medias: texto(json['medias']),
      colorHex: texto(json['colorHex']),
    );
  }

  /// null si [json] no es un objeto (equipaje no indicado).
  static EquipacionModel? fromJsonOrNull(Object? json) =>
      json is Map<String, dynamic> ? EquipacionModel.fromJson(json) : null;

  /// El color de la muestra, o null si no hay colorHex o no es un #RRGGBB válido.
  Color? get color {
    final hex = colorHex;

    if (hex == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) {
      return null;
    }

    return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
  }

  /// Si tiene algún dato de camiseta, pantalón o medias que mostrar.
  bool get tieneDetalle => camiseta != null || pantalon != null || medias != null;

  @override
  bool operator ==(Object other) =>
      other is EquipacionModel &&
      other.id == id &&
      other.nombre == nombre &&
      other.camiseta == camiseta &&
      other.pantalon == pantalon &&
      other.medias == medias &&
      other.colorHex == colorHex;

  @override
  int get hashCode => Object.hash(id, nombre, camiseta, pantalon, medias, colorHex);
}
