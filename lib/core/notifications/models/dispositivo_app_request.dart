class DispositivoAppRequest {
  final String tokenFcm;
  final String plataforma;

  /// Versión instalada de la app ("1.0.10"); null si no se pudo leer.
  final String? versionApp;

  const DispositivoAppRequest({
    required this.tokenFcm,
    required this.plataforma,
    this.versionApp,
  });

  Map<String, dynamic> toJson() {
    return {
      'tokenFcm': tokenFcm,
      'plataforma': plataforma,
      'versionApp': ?versionApp,
    };
  }
}
