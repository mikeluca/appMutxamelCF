import 'package:material_ui/material_ui.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../services/solicitud_familia_service.dart';
import '../widgets/tarjeta_solicitud_familia.dart';
import 'pedir_acceso_jugador_page.dart';

/// "Mi solicitud de acceso": el estado de las solicitudes propias. Es a donde lleva el aviso al familiar (aprobado o
/// rechazado) y desde aquí se puede pedir el acceso a otro jugador.
class MiSolicitudFamiliaPage extends StatefulWidget {
  final SolicitudFamiliaService servicio;

  const MiSolicitudFamiliaPage({
    super.key,
    this.servicio = const SolicitudFamiliaService(),
  });

  @override
  State<MiSolicitudFamiliaPage> createState() => _MiSolicitudFamiliaPageState();
}

class _MiSolicitudFamiliaPageState extends State<MiSolicitudFamiliaPage> {
  final _tarjetaKey = GlobalKey<TarjetaSolicitudFamiliaState>();

  Future<void> _pedirAcceso() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PedirAccesoJugadorPage(servicio: widget.servicio),
      ),
    );

    await _tarjetaKey.currentState?.recargar();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: t.familyRequestStatusTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _tarjetaKey.currentState?.recargar(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TarjetaSolicitudFamilia(
              key: _tarjetaKey,
              servicio: widget.servicio,
              onPedirAcceso: _pedirAcceso,
            ),
          ],
        ),
      ),
    );
  }
}
