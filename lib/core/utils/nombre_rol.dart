import '../../l10n/gen/app_localizations.dart';

/// El texto de un rol de la cuenta (el mismo en Mi perfil y en el Área Club).
/// Un rol desconocido se devuelve tal cual.
String nombreDeRol(AppLocalizations t, String rol) {
  switch (rol) {
    case 'FAMILIAR':
      return t.roleFamiliar;
    case 'JUGADOR':
      return t.roleJugador;
    case 'ENTRENADOR':
      return t.roleEntrenador;
    case 'COORDINADOR':
      return t.roleCoordinador;
    case 'RETRANSMISION':
      return t.roleRetransmision;
    case 'SOCIO':
      return t.roleSocio;
    case 'ADMIN_APP':
      return t.roleAdministrador;
    default:
      return rol;
  }
}
