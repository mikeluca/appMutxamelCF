class AuthUser {
  final int usuarioId;
  final String email;
  final List<String> roles;

  AuthUser({required this.usuarioId, required this.email, required this.roles});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      usuarioId: json['usuarioId'] as int,
      email: json['email'] as String,
      roles: List<String>.from(json['roles'] ?? []),
    );
  }

  bool tieneRol(String rol) {
    return roles.contains(rol);
  }
}
