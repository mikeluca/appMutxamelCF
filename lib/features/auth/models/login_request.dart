class LoginRequest {
  final String email;
  final String password;

  /// Idioma que muestra la app ("es", "ca" o "en"); el backend lo guarda para
  /// escribir los avisos en ese idioma. Opcional.
  final String? idioma;

  LoginRequest({required this.email, required this.password, this.idioma});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'idioma': ?idioma};
  }
}
