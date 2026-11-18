import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/services/auth_manager.dart';
import '../models/solicitud_familia_model.dart';
import '../services/solicitud_familia_service.dart';

/// La tarjeta "Solicitud pendiente de revisión por el club": los hijos pedidos y el estado de cada uno (pendiente,
/// aprobado, rechazado con motivo). Nunca enseña jugadores. Si el club ya ha aprobado algún hijo, recarga los roles de
/// la cuenta (como al iniciar sesión): el Área Club se reconstruye con Mis jugadores, Calendario, etc.
class TarjetaSolicitudFamilia extends StatefulWidget {
  final SolicitudFamiliaService servicio;

  /// Qué hacer al tocar "Pedir acceso a un jugador" (cuando no hay ninguna solicitud abierta); sin él no hay botón.
  final VoidCallback? onPedirAcceso;

  const TarjetaSolicitudFamilia({
    super.key,
    this.servicio = const SolicitudFamiliaService(),
    this.onPedirAcceso,
  });

  @override
  State<TarjetaSolicitudFamilia> createState() =>
      TarjetaSolicitudFamiliaState();
}

class TarjetaSolicitudFamiliaState extends State<TarjetaSolicitudFamilia> {
  List<SolicitudFamiliaMia>? _solicitudes;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    recargar();
  }

  /// Vuelve a pedir las solicitudes (y, si alguna ya tiene un hijo aprobado, los roles).
  Future<void> recargar() async {
    try {
      final lista = await widget.servicio.mias();

      if (!mounted) return;

      setState(() {
        _solicitudes = lista;
        _error = false;
      });

      if (lista.any((s) => s.algunHijoAprobado)) {
        // Con la cuenta ya vinculada, los roles son otros: se recargan (el Área Club escucha AuthManager.cambios).
        await AuthManager.recargarUsuario();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _solicitudes ??= const [];
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final solicitudes = _solicitudes;

    if (solicitudes == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (solicitudes.isEmpty) {
      return Card(
        key: const ValueKey('familia-sin-solicitud'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_error ? t.connectionError : t.familyNoRequest),
              if (widget.onPedirAcceso != null) ...[
                const SizedBox(height: 12),
                FilledButton(
                  key: const ValueKey('familia-pedir-acceso'),
                  onPressed: widget.onPedirAcceso,
                  child: Text(t.familyRequestAgain),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in solicitudes) _construirSolicitud(context, t, s),
        if (widget.onPedirAcceso != null && !solicitudes.any((s) => s.abierta))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FilledButton(
              key: const ValueKey('familia-pedir-acceso'),
              onPressed: widget.onPedirAcceso,
              child: Text(t.familyRequestAgain),
            ),
          ),
      ],
    );
  }

  Widget _construirSolicitud(
    BuildContext context,
    AppLocalizations t,
    SolicitudFamiliaMia s,
  ) {
    final colores = Theme.of(context).colorScheme;

    final titulo = s.abierta
        ? t.familyRequestCardTitle
        : s.estado == estadoSolicitudAprobada
        ? t.familyRequestApprovedTitle
        : t.familyRequestRejectedTitle;

    final icono = s.abierta
        ? Icons.hourglass_top_outlined
        : s.estado == estadoSolicitudAprobada
        ? Icons.check_circle_outline
        : Icons.cancel_outlined;

    return Card(
      key: ValueKey('familia-solicitud-${s.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: colores.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (s.abierta) ...[
              const SizedBox(height: 8),
              Text(
                t.familyRequestCardIntro,
                style: TextStyle(color: colores.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            for (final h in s.hijos) _construirHijo(context, t, h),
            // El motivo es de la solicitud (los hijos no tienen el suyo): sale si se ha rechazado algún hijo.
            if ((s.motivoRechazo ?? '').isNotEmpty &&
                s.hijos.any((h) => h.estado == estadoHijoRechazado)) ...[
              const SizedBox(height: 8),
              Text(t.familyRejectedReason(s.motivoRechazo!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirHijo(BuildContext context, AppLocalizations t, HijoMio h) {
    final colores = Theme.of(context).colorScheme;

    final (texto, color) = switch (h.estado) {
      estadoHijoAprobado => (t.familyChildApproved, Colors.green),
      estadoHijoRechazado => (t.familyChildRejected, colores.error),
      _ => (t.familyChildPending, colores.primary),
    };

    return Padding(
      key: ValueKey('familia-hijo-${h.id}'),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.nombreCompleto,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (h.equipo.isNotEmpty)
                  Text(
                    h.equipo,
                    style: TextStyle(
                      color: colores.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              texto,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
