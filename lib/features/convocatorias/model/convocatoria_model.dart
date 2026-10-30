import '../../invitados/models/invitacion_model.dart';

class ConvocatoriaModel {
  final int id;
  final int equipoId;
  final String equipo;
  final int partidoId;

  /// Rival/campo/fecha/hora del partido: el backend ya no los guarda en
  /// la convocatoria, los lee en vivo del partido vinculado (partidoId)
  /// y los expone aquí igual que antes para no romper la UI existente.
  final String rival;
  final String campo;
  final String fechaPartido;
  final String horaPartido;

  final String horaConvocatoria;
  final String lugarConvocatoria;
  final int usuarioEntrenadorId;
  final List<ConvocatoriaJugadorModel> jugadores;

  /// El partido ya tiene resultado: la convocatoria ya no se puede eliminar.
  final bool partidoConResultado;

  /// Convocados que han justificado su ausencia a este partido (siguen en la
  /// convocatoria hasta que el entrenador los sustituya).
  List<ConvocatoriaJugadorModel> get ausentes =>
      jugadores.where((j) => j.ausenciaJustificada).toList();

  /// Los jugadores del propio equipo (sin los invitados de otros equipos).
  List<ConvocatoriaJugadorModel> get propios =>
      jugadores.where((j) => !j.invitado).toList();

  /// Los invitados de otros equipos, en cualquier estado.
  List<ConvocatoriaJugadorModel> get invitados =>
      jugadores.where((j) => j.invitado).toList();

  /// Los que juegan: los del propio equipo y los invitados ya autorizados.
  List<ConvocatoriaJugadorModel> get queJuegan =>
      jugadores.where((j) => j.juega).toList();

  /// Los invitados que ya no están en juego porque coordinación los rechazó.
  List<ConvocatoriaJugadorModel> get invitadosRechazados =>
      jugadores.where((j) => j.rechazado).toList();

  /// Los invitados tal como los gestiona el formulario: todos menos los rechazados
  /// (para quitar uno rechazado basta con no volver a enviarlo).
  List<InvitadoElegido> get invitadosParaFormulario => invitados
      .map(
        (j) => InvitadoElegido(
          jugadorId: j.jugadorId,
          nombre: j.jugador,
          equipoOrigenId: j.equipoOrigenId,
          equipoOrigen: j.equipoOrigen ?? '',
          estado: j.estadoInvitacion,
          ausenciaJustificada: j.ausenciaJustificada,
          motivoAusencia: j.motivoAusencia,
          motivoRechazo: j.motivoRechazo,
        ),
      )
      .toList();

  ConvocatoriaModel({
    required this.id,
    required this.equipoId,
    required this.equipo,
    required this.partidoId,
    required this.rival,
    required this.campo,
    required this.fechaPartido,
    required this.horaPartido,
    required this.horaConvocatoria,
    required this.lugarConvocatoria,
    required this.usuarioEntrenadorId,
    required this.jugadores,
    this.partidoConResultado = false,
  });

  factory ConvocatoriaModel.fromJson(Map<String, dynamic> json) {
    return ConvocatoriaModel(
      id: json['id'],
      equipoId: json['equipoId'],
      equipo: json['equipo'] ?? '',
      partidoId: json['partidoId'],
      rival: json['rival'] ?? '',
      campo: json['campo'] ?? '',
      fechaPartido: json['fechaPartido'].toString(),
      horaPartido: json['horaPartido'] ?? '',
      horaConvocatoria: json['horaConvocatoria'] ?? '',
      lugarConvocatoria: json['lugarConvocatoria'] ?? '',
      usuarioEntrenadorId: json['usuarioEntrenadorId'],
      jugadores: (json['jugadores'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                ConvocatoriaJugadorModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      partidoConResultado: json['partidoConResultado'] == true,
    );
  }
}

class ConvocatoriaJugadorModel {
  final int jugadorId;
  final String jugador;

  /// El jugador ha justificado su ausencia a este partido, y su motivo.
  final bool ausenciaJustificada;
  final String? motivoAusencia;

  /// Jugador de otro equipo invitado a esta convocatoria: su equipo habitual y en qué
  /// estado está la invitación (null en los jugadores del propio equipo).
  final bool invitado;
  final int? equipoOrigenId;
  final String? equipoOrigen;
  final EstadoInvitacion? estadoInvitacion;
  final String? motivoRechazo;

  ConvocatoriaJugadorModel({
    required this.jugadorId,
    required this.jugador,
    this.ausenciaJustificada = false,
    this.motivoAusencia,
    this.invitado = false,
    this.equipoOrigenId,
    this.equipoOrigen,
    this.estadoInvitacion,
    this.motivoRechazo,
  });

  bool get rechazado => estadoInvitacion == EstadoInvitacion.rechazado;

  bool get pendiente =>
      estadoInvitacion == EstadoInvitacion.pendienteCoordinacion ||
      estadoInvitacion == EstadoInvitacion.pendienteEntrenador;

  /// Juega: del propio equipo o invitado ya autorizado.
  bool get juega => !invitado || estadoInvitacion == EstadoInvitacion.autorizado;

  factory ConvocatoriaJugadorModel.fromJson(Map<String, dynamic> json) {
    return ConvocatoriaJugadorModel(
      jugadorId: json['jugadorId'],
      jugador: json['jugador'] ?? '',
      ausenciaJustificada: json['ausenciaJustificada'] as bool? ?? false,
      motivoAusencia: json['motivoAusencia'] as String?,
      invitado: json['invitado'] as bool? ?? false,
      equipoOrigenId: (json['equipoOrigenId'] as num?)?.toInt(),
      equipoOrigen: json['equipoOrigen'] as String?,
      estadoInvitacion: EstadoInvitacion.desde(
        json['estadoInvitacion'] as String?,
      ),
      motivoRechazo: json['motivoRechazo'] as String?,
    );
  }
}
