class DispositivoAppRequest {
  final String tokenFcm;
  final String plataforma;

  const DispositivoAppRequest({
    required this.tokenFcm,
    required this.plataforma,
  });

  Map<String, dynamic> toJson() {
    return {'tokenFcm': tokenFcm, 'plataforma': plataforma};
  }
}
