import '../../../core/notifications/utils/convocatoria_notificacion.dart';
import '../../imagenes_redes/models/imagenes_redes_model.dart';
import '../models/pendientes.dart';

/// El código de [elemento].destino (PASAR_LISTA:12, CONVOCATORIA_NUEVA:30...) como el destino que ya usan los avisos
/// para abrir esa misma pantalla. Null si no es de los que se abren con ellos (USUARIOS_CADUCADAS, que abre Usuarios
/// filtrado) o si el código no se conoce.
DestinoConvocatoria? destinoDePendiente(ElementoPendiente elemento) {
  final partes = elemento.destino.split(':');
  final codigo = partes.first;
  final argumento = partes.length > 1 ? partes.sublist(1).join(':') : '';

  switch (codigo) {
    case 'PASAR_LISTA':
      final id = int.tryParse(argumento) ?? elemento.id;

      return id == null ? null : PasarLista(id);
    case 'CONVOCATORIA_NUEVA':
      final partidoId = int.tryParse(argumento) ?? elemento.id;
      final equipoId = elemento.equipoId;

      if (partidoId == null || equipoId == null) return null;

      return AbrirFormularioConvocatoria(
        partidoId: partidoId,
        equipoId: equipoId,
        equipo: elemento.equipo ?? '',
      );
    case 'RESULTADO':
      final partidoId = int.tryParse(argumento) ?? elemento.id;
      final equipoId = elemento.equipoId;

      if (partidoId == null || equipoId == null) return null;

      return AbrirFormularioResultado(
        partidoId: partidoId,
        equipoId: equipoId,
        equipo: elemento.equipo ?? '',
        rival: elemento.rival ?? '',
        dia: elemento.fecha,
        hora: (elemento.hora ?? '').isEmpty ? null : elemento.hora,
      );
    case 'SOLICITUDES_FAMILIA':
      return const AbrirSolicitudesFamilia();
    case 'INVITACIONES':
      return const AbrirInvitaciones();
    case 'MODERACION':
      return const AbrirModeracion();
    case 'IMAGENES_PREVIA':
      return AbrirImagenesRedes(DateTime.tryParse(argumento), tipoImagenPrevia);
    case 'IMAGENES_RESULTADOS':
      return AbrirImagenesRedes(
        DateTime.tryParse(argumento),
        tipoImagenResultados,
      );
  }

  return null;
}

/// Si el destino es la lista de cuentas con la invitación caducada.
bool esUsuariosCaducadas(ElementoPendiente elemento) =>
    elemento.destino == 'USUARIOS_CADUCADAS';
