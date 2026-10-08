class AuthUser {
  final int usuarioId;
  final String email;
  final List<String> roles;

  /// Nombre para mostrar (el de la ficha o, si no tiene, el de la cuenta).
  /// Null si la cuenta aún no tiene ninguno.
  final String? nombre;

  AuthUser({
    required this.usuarioId,
    required this.email,
    required this.roles,
    this.nombre,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      usuarioId: json['usuarioId'] as int,
      email: json['email'] as String,
      roles: List<String>.from(json['roles'] ?? []),
      nombre: json['nombre'] as String?,
    );
  }

  bool tieneRol(String rol) {
    return roles.contains(rol);
  }
}
