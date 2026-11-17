import 'package:material_ui/material_ui.dart';

import '../../../core/notifications/services/permiso_notificaciones.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../services/seguir_partido_service.dart';

/// "Seguir este partido" de la ficha de un partido que no ha terminado (la ficha no lo pinta si ha terminado):
/// un botón con campana que da de alta o de baja en el topic del partido.
///
/// Solo se muestra a quien NO recibe ya los avisos de resultados; a quien sí los recibe le dice, en pequeño, que ya
/// recibe los avisos de todos los partidos. Si no se puede saber (sin red con cuenta), no se ofrece nada, salvo si
/// ya sigue el partido (entonces se puede dejar de seguir).
class BotonSeguirPartido extends StatefulWidget {
  final int partidoId;

  /// El día del partido: con él se da de baja pasados dos días.
  final DateTime? fecha;
  final SeguirPartidoService service;

  /// Asegura el permiso de notificaciones antes de seguir (pantalla propia, la peticion del sistema y, si esta denegado
  /// del todo, el aviso con "Abrir ajustes"). Los tests lo sustituyen.
  final Future<bool> Function(BuildContext context)? asegurarPermiso;

  const BotonSeguirPartido({
    super.key,
    required this.partidoId,
    required this.fecha,
    required this.service,
    this.asegurarPermiso,
  });

  @override
  State<BotonSeguirPartido> createState() => _BotonSeguirPartidoState();
}

class _BotonSeguirPartidoState extends State<BotonSeguirPartido> {
  bool _cargado = false;
  bool _sigue = false;
  bool? _recibeResultados;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(BotonSeguirPartido anterior) {
    super.didUpdateWidget(anterior);

    if (anterior.partidoId != widget.partidoId) {
      _cargado = false;
      _cargar();
    }
  }

  Future<void> _cargar() async {
    bool sigue;
    bool? recibe;

    try {
      sigue = await widget.service.sigue(widget.partidoId);
      recibe = await widget.service.recibeAvisosDeResultados();
    } catch (_) {
      sigue = false;
      recibe = null;
    }

    if (!mounted) return;

    setState(() {
      _sigue = sigue;
      _recibeResultados = recibe;
      _cargado = true;
    });
  }

  Future<void> _alternar() async {
    if (_ocupado) return;

    final t = AppLocalizations.of(context);
    final mensajes = ScaffoldMessenger.of(context);

    setState(() => _ocupado = true);

    String? mensaje;

    try {
      if (_sigue) {
        await widget.service.dejarDeSeguir(widget.partidoId);
        _sigue = false;
        mensaje = t.followStopped;
      } else {
        final concedido =
            await (widget.asegurarPermiso ??
                (c) => PermisoNotificaciones.asegurar(
                  c,
                  MotivoPermiso.seguirPartido,
                ))(context);

        final resultado = concedido
            ? await widget.service.seguir(widget.partidoId, widget.fecha)
            : ResultadoSeguir.permisoDenegado;

        if (resultado == ResultadoSeguir.seguido) {
          _sigue = true;
          mensaje = t.followStarted;
        } else {
          // Sin permiso no se marca como seguido.
          mensaje = t.followPermissionDenied;
        }
      }
    } catch (_) {
      mensaje = t.followError;
    }

    if (mounted) setState(() => _ocupado = false);

    mensajes.showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_cargado) return const SizedBox.shrink();

    final t = AppLocalizations.of(context);

    if (_sigue) {
      return _envolver(
        FilledButton.tonalIcon(
          key: const ValueKey('boton-siguiendo'),
          onPressed: _ocupado ? null : _alternar,
          icon: const Icon(Icons.notifications_active),
          label: Text(t.followingMatchButton),
        ),
      );
    }

    if (_recibeResultados == true) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Text(
          t.followAlreadyAll,
          key: const ValueKey('seguir-ya-recibe'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (_recibeResultados == false) {
      return _envolver(
        OutlinedButton.icon(
          key: const ValueKey('boton-seguir'),
          onPressed: _ocupado ? null : _alternar,
          icon: const Icon(Icons.notifications_none),
          label: Text(t.followMatchButton),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _envolver(Widget boton) =>
      Padding(padding: const EdgeInsets.fromLTRB(16, 6, 16, 6), child: boton);
}
