class PreferenciasNotificacionModel {
  final int usuarioAppId;
  final bool notificacionesActivadas;
  final bool noticiasActivadas;
  final bool comunicacionesActivadas;
  final bool mensajesActivados;
  final bool resultadosActivados;

  const PreferenciasNotificacionModel({
    required this.usuarioAppId,
    required this.notificacionesActivadas,
    required this.noticiasActivadas,
    required this.comunicacionesActivadas,
    required this.mensajesActivados,
    required this.resultadosActivados,
  });

  factory PreferenciasNotificacionModel.fromJson(Map<String, dynamic> json) {
    return PreferenciasNotificacionModel(
      usuarioAppId: (json['usuarioAppId'] as num?)?.toInt() ?? 0,
      notificacionesActivadas: json['notificacionesActivadas'] == true,
      noticiasActivadas: json['noticiasActivadas'] == true,
      comunicacionesActivadas: json['comunicacionesActivadas'] == true,
      mensajesActivados: json['mensajesActivados'] == true,
      resultadosActivados: json['resultadosActivados'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificacionesActivadas': notificacionesActivadas,
      'noticiasActivadas': noticiasActivadas,
      'comunicacionesActivadas': true,
      'mensajesActivados': mensajesActivados,
      'resultadosActivados': resultadosActivados,
    };
  }
}
