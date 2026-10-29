import '../../../core/config/app_config.dart';
import '../../../routing/app_routes.dart';
import 'auth_user.dart';

/// Secciones del menú del Área Club, en el orden en que se pintan.
enum SeccionClubId {
  club,
  jugador,
  familia,
  entrenador,
  coordinacion,
  administracion,
  retransmision,
  cuenta,
}

/// Cada opción del menú. Una opción solo puede estar en una sección.
enum OpcionClub {
  comunicaciones,
  calendario,
  partidos,
  clasificaciones,
  miFicha,
  misJugadores,
  cuotas,
  misEquipos,
  todosLosEquipos,
  finDeSemana,
  seguimientoJugadores,
  repartoEquipos,
  altaPrueba,
  moderacion,
  cuentasPendientes,
  estadoApp,
  partidoEnDirecto,
  miPerfil,
  cerrarSesion,
}

class SeccionClub {
  final SeccionClubId id;
  final List<OpcionClub> opciones;

  const SeccionClub(this.id, this.opciones);
}

/// Ruta a la que navega una opción; null si no navega a una ruta (Cuotas abre
/// un aviso y Cerrar sesión cierra la sesión).
String? rutaDeOpcionClub(OpcionClub opcion) {
  switch (opcion) {
    case OpcionClub.comunicaciones:
      return AppRoutes.communication;
    case OpcionClub.calendario:
      return AppRoutes.calendar;
    case OpcionClub.partidos:
      return AppRoutes.myMatches;
    case OpcionClub.clasificaciones:
      return AppRoutes.myStandings;
    case OpcionClub.miFicha:
      return AppRoutes.myCard;
    case OpcionClub.misJugadores:
      return AppRoutes.players;
    case OpcionClub.misEquipos:
    case OpcionClub.todosLosEquipos:
      return AppRoutes.myTeams;
    case OpcionClub.finDeSemana:
      return AppRoutes.weekend;
    case OpcionClub.seguimientoJugadores:
      return AppRoutes.playerTracking;
    case OpcionClub.repartoEquipos:
      return AppRoutes.rosterAllocation;
    case OpcionClub.altaPrueba:
      return AppRoutes.trialPlayer;
    case OpcionClub.moderacion:
      return AppRoutes.moderation;
    case OpcionClub.cuentasPendientes:
      return AppRoutes.pendingAccounts;
    case OpcionClub.estadoApp:
      return AppRoutes.appStatus;
    case OpcionClub.partidoEnDirecto:
      return AppRoutes.liveMatch;
    case OpcionClub.miPerfil:
      return AppRoutes.profile;
    case OpcionClub.cuotas:
    case OpcionClub.cerrarSesion:
      return null;
  }
}

/// Qué secciones y opciones ve el usuario. Función pura: las condiciones de
/// cada opción son las del menú de siempre; aquí solo se decide dónde van.
/// Una sección sin opciones no se devuelve.
List<SeccionClub> construirSeccionesClub(
  AuthUser? usuario, {
  bool cuotasDisponibles = AppConfig.cuotasDisponibles,
}) {
  bool tiene(String rol) => usuario?.tieneRol(rol) == true;

  final esFamiliar = tiene('FAMILIAR');
  final esJugador = tiene('JUGADOR');
  final esEntrenador = tiene('ENTRENADOR');
  final esGestionGlobal = tiene('COORDINADOR') || tiene('ADMIN_APP');
  final esAdmin = tiene('ADMIN_APP');
  final esRetransmision = tiene('RETRANSMISION');

  // Un JUGADOR sin rol de familiar tiene su propia ficha. Si es JUGADOR y
  // FAMILIAR a la vez, "Mis jugadores" ya los incluye a todos.
  final soloJugador = esJugador && !esFamiliar;

  final veClasificaciones =
      esGestionGlobal || esJugador || esFamiliar || esEntrenador;

  final secciones = <SeccionClub>[
    SeccionClub(SeccionClubId.club, [
      OpcionClub.comunicaciones,
      OpcionClub.calendario,
      OpcionClub.partidos,
      if (veClasificaciones) OpcionClub.clasificaciones,
    ]),
    SeccionClub(SeccionClubId.jugador, [
      if (soloJugador) OpcionClub.miFicha,
    ]),
    SeccionClub(SeccionClubId.familia, [
      if (esFamiliar) OpcionClub.misJugadores,
      if (esFamiliar && cuotasDisponibles) OpcionClub.cuotas,
    ]),
    SeccionClub(SeccionClubId.entrenador, [
      // Con rol de gestión global, "Todos los equipos" va en Coordinación.
      if (esEntrenador && !esGestionGlobal) OpcionClub.misEquipos,
    ]),
    SeccionClub(SeccionClubId.coordinacion, [
      if (esGestionGlobal) OpcionClub.todosLosEquipos,
      if (esGestionGlobal) OpcionClub.finDeSemana,
      if (esGestionGlobal) OpcionClub.seguimientoJugadores,
      if (esGestionGlobal) OpcionClub.repartoEquipos,
      if (esGestionGlobal) OpcionClub.altaPrueba,
    ]),
    SeccionClub(SeccionClubId.administracion, [
      if (esAdmin) OpcionClub.moderacion,
      if (esAdmin) OpcionClub.cuentasPendientes,
      if (esAdmin) OpcionClub.estadoApp,
    ]),
    SeccionClub(SeccionClubId.retransmision, [
      if (esRetransmision) OpcionClub.partidoEnDirecto,
    ]),
    const SeccionClub(SeccionClubId.cuenta, [
      OpcionClub.miPerfil,
      OpcionClub.cerrarSesion,
    ]),
  ];

  return secciones.where((s) => s.opciones.isNotEmpty).toList();
}
