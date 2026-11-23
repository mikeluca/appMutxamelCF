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
  invitaciones,
  moderacion,
  usuarios,
  subirDatosFfcv,
  estadoApp,
  partidoEnDirecto,
  imagenesRedes,
  solicitudesFamilia,
  pedirAccesoJugador,
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
    case OpcionClub.invitaciones:
      return AppRoutes.invitations;
    case OpcionClub.moderacion:
      return AppRoutes.moderation;
    case OpcionClub.usuarios:
      return AppRoutes.users;
    case OpcionClub.subirDatosFfcv:
      return AppRoutes.ffcvUpload;
    case OpcionClub.estadoApp:
      return AppRoutes.appStatus;
    case OpcionClub.partidoEnDirecto:
      return AppRoutes.liveMatch;
    case OpcionClub.imagenesRedes:
      return AppRoutes.socialImages;
    case OpcionClub.solicitudesFamilia:
      return AppRoutes.familyRequests;
    case OpcionClub.pedirAccesoJugador:
      return AppRoutes.askAnotherPlayer;
    case OpcionClub.miPerfil:
      return AppRoutes.profile;
    case OpcionClub.cuotas:
    case OpcionClub.cerrarSesion:
      return null;
  }
}

/// true si la cuenta solo tiene roles de "Directo y RRSS" (RETRANSMISION, RRSS o los dos) y ningún otro.
bool esSoloDirectoYRrss(AuthUser? usuario) =>
    usuario != null &&
    usuario.roles.isNotEmpty &&
    usuario.roles.every((r) => r == 'RETRANSMISION' || r == 'RRSS');

/// Partido en directo: RETRANSMISION y ADMIN_APP (RRSS y el resto, no).
bool puedeVerPartidoEnDirecto(AuthUser? usuario) =>
    usuario?.tieneRol('RETRANSMISION') == true ||
    usuario?.tieneRol('ADMIN_APP') == true;

/// Imágenes para redes: RRSS y ADMIN_APP (RETRANSMISION y COORDINADOR, no).
bool puedeVerImagenesRedesUsuario(AuthUser? usuario) =>
    usuario?.tieneRol('RRSS') == true || usuario?.tieneRol('ADMIN_APP') == true;

/// Opciones de "Directo y RRSS" según los roles (la sección sin opciones no se pinta).
List<OpcionClub> _opcionesDirectoYRrss(AuthUser? usuario) => [
  if (puedeVerPartidoEnDirecto(usuario)) OpcionClub.partidoEnDirecto,
  if (puedeVerImagenesRedesUsuario(usuario)) OpcionClub.imagenesRedes,
];

/// Qué secciones y opciones ve el usuario. Función pura: las condiciones de
/// cada opción son las del menú de siempre; aquí solo se decide dónde van.
/// Una sección sin opciones no se devuelve.
List<SeccionClub> construirSeccionesClub(
  AuthUser? usuario, {
  bool cuotasDisponibles = AppConfig.cuotasDisponibles,
}) {
  // Una cuenta SIN roles (la de una familia que aún no está aprobada) no ve nada privado: el Área Club le enseña
  // el estado de su solicitud (tarjeta aparte) y solo puede cerrar sesión.
  if (usuario != null && usuario.roles.isEmpty) {
    return const [
      SeccionClub(SeccionClubId.cuenta, [OpcionClub.cerrarSesion]),
    ];
  }

  bool tiene(String rol) => usuario?.tieneRol(rol) == true;

  // Una cuenta solo de Retransmisión y/o Redes sociales no tiene equipo ni jugadores: Club (Comunicaciones,
  // Calendario, Mis partidos) y "Pedir acceso a otro jugador" no le sirven. Solo ve sus opciones de "Directo y
  // RRSS" y su cuenta.
  if (esSoloDirectoYRrss(usuario)) {
    return [
      SeccionClub(SeccionClubId.retransmision, _opcionesDirectoYRrss(usuario)),
      const SeccionClub(SeccionClubId.cuenta, [
        OpcionClub.miPerfil,
        OpcionClub.cerrarSesion,
      ]),
    ];
  }

  final esFamiliar = tiene('FAMILIAR');
  final esJugador = tiene('JUGADOR');
  final esEntrenador = tiene('ENTRENADOR');
  final esGestionGlobal = tiene('COORDINADOR') || tiene('ADMIN_APP');
  final esAdmin = tiene('ADMIN_APP');

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
    SeccionClub(SeccionClubId.jugador, [if (soloJugador) OpcionClub.miFicha]),
    SeccionClub(SeccionClubId.familia, [
      if (esFamiliar) OpcionClub.misJugadores,
      if (esFamiliar && cuotasDisponibles) OpcionClub.cuotas,
    ]),
    SeccionClub(SeccionClubId.entrenador, [
      // Con rol de gestión global, "Todos los equipos" va en Coordinación.
      if (esEntrenador && !esGestionGlobal) OpcionClub.misEquipos,
      // Los entrenadores revisan solo las solicitudes de sus equipos (lo filtra el backend).
      if (esEntrenador && !esGestionGlobal) OpcionClub.solicitudesFamilia,
    ]),
    SeccionClub(SeccionClubId.coordinacion, [
      if (esGestionGlobal) OpcionClub.todosLosEquipos,
      if (esGestionGlobal) OpcionClub.finDeSemana,
      if (esGestionGlobal) OpcionClub.seguimientoJugadores,
      if (esGestionGlobal) OpcionClub.repartoEquipos,
      if (esGestionGlobal) OpcionClub.altaPrueba,
      if (esGestionGlobal) OpcionClub.invitaciones,
      if (esGestionGlobal) OpcionClub.solicitudesFamilia,
    ]),
    SeccionClub(SeccionClubId.administracion, [
      if (esAdmin) OpcionClub.moderacion,
      if (esAdmin) OpcionClub.usuarios,
      if (esAdmin) OpcionClub.subirDatosFfcv,
      if (esAdmin) OpcionClub.estadoApp,
    ]),
    SeccionClub(SeccionClubId.retransmision, _opcionesDirectoYRrss(usuario)),
    SeccionClub(SeccionClubId.cuenta, [
      if (usuario != null) OpcionClub.pedirAccesoJugador,
      OpcionClub.miPerfil,
      OpcionClub.cerrarSesion,
    ]),
  ];

  return secciones.where((s) => s.opciones.isNotEmpty).toList();
}
