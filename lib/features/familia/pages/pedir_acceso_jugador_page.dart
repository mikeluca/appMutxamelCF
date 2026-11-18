import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/solicitud_familia_model.dart';
import '../services/solicitud_familia_service.dart';
import '../widgets/formulario_familia.dart';

/// "Pedir acceso a otro jugador": quien ya tiene la sesión iniciada pide vincular otro hijo o hija. Es el paso de los
/// hijos (con el parentesco) y el de las dos casillas, sin crear cuenta ni confirmar el email. Al enviar vuelve a la
/// pantalla anterior con el aviso "Solicitud enviada".
class PedirAccesoJugadorPage extends StatefulWidget {
  final SolicitudFamiliaService servicio;

  const PedirAccesoJugadorPage({
    super.key,
    this.servicio = const SolicitudFamiliaService(),
  });

  @override
  State<PedirAccesoJugadorPage> createState() => _PedirAccesoJugadorPageState();
}

class _PedirAccesoJugadorPageState extends State<PedirAccesoJugadorPage> {
  final _parentescoKey = GlobalKey<FormState>();
  final _hijosKey = GlobalKey<FormularioHijosState>();

  ParentescoFamilia? _parentesco;
  bool _representante = false;
  bool _privacidad = false;
  bool _casillasIntentadas = false;

  bool _cargando = false;
  String? _error;

  AppLocalizations get _t => AppLocalizations.of(context);

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _casillasIntentadas = true;
      _error = null;
    });

    final parentescoOk = _parentescoKey.currentState?.validate() ?? false;
    final hijosOk = _hijosKey.currentState?.validar() ?? false;

    if (!parentescoOk || !hijosOk || !_representante || !_privacidad) return;

    setState(() => _cargando = true);

    try {
      await widget.servicio.solicitarConSesion(
        SolicitudFamiliaNueva(
          parentesco: _parentesco!,
          hijos: _hijosKey.currentState!.hijos,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.familyAskSent)));

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;

      // 409: ya hay una solicitud abierta; el resto, el mensaje claro del backend.
      setState(() {
        _error = e.statusCode == 409
            ? _t.familyAlreadyPending
            : mensajeErrorFamilia(_t, e);
      });
    } catch (e) {
      if (mounted) setState(() => _error = mensajeErrorFamilia(_t, e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: t.familyAskAnotherPlayer)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Form(
                          key: _parentescoKey,
                          child: SelectorParentesco(
                            valor: _parentesco,
                            onChanged: (p) => setState(() => _parentesco = p),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FormularioHijos(key: _hijosKey),
                        const SizedBox(height: 16),
                        CasillasFamilia(
                          representante: _representante,
                          privacidad: _privacidad,
                          mostrarErrores: _casillasIntentadas,
                          onRepresentante: (v) =>
                              setState(() => _representante = v),
                          onPrivacidad: (v) => setState(() => _privacidad = v),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _error!,
                              key: const ValueKey('familia-error'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      key: const ValueKey('familia-principal'),
                      onPressed: _cargando ? null : _enviar,
                      child: _cargando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t.familySend),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
