class LoginResponse {
  final String token;
  final int usuarioId;
  final String email;
  final List<String> roles;

  LoginResponse({
    required this.token,
    required this.usuarioId,
    required this.email,
    required this.roles,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      usuarioId: json['usuarioId'] as int,
      email: json['email'] as String,
      roles: List<String>.from(json['roles'] ?? []),
    );
  }
}
