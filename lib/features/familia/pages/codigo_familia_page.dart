import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/notifications/services/permiso_notificaciones.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../../auth/services/auth_manager.dart';
import '../services/solicitud_familia_service.dart';
import '../widgets/formulario_familia.dart';

/// El segundo tramo del registro: el código de 6 dígitos enviado al email (caduca en 5 días) más la contraseña y su
/// repetición (las mismas reglas que "Activar cuenta"). Si todo va bien la solicitud queda pendiente de revisión y la
/// persona entra en la app, solo con lo público y el estado de su solicitud.
class CodigoFamiliaPage extends StatefulWidget {
  final String email;

  /// El registro creó la cuenta pero el email no salió: se avisa de que hay que reenviar el código.
  final bool envioFallido;

  final SolicitudFamiliaService servicio;

  const CodigoFamiliaPage({
    super.key,
    required this.email,
    this.envioFallido = false,
    this.servicio = const SolicitudFamiliaService(),
  });

  @override
  State<CodigoFamiliaPage> createState() => _CodigoFamiliaPageState();
}

class _CodigoFamiliaPageState extends State<CodigoFamiliaPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();

  bool _mostrarPassword = false;
  bool _cargando = false;
  bool _reenviando = false;
  String? _error;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    _aviso = null;
  }

  @override
  void dispose() {
    _codigo.dispose();
    _password.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  AppLocalizations get _t => AppLocalizations.of(context);

  Future<void> _verificar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final login = await widget.servicio.verificar(
        email: widget.email,
        codigo: _codigo.text,
        password: _password.text,
      );

      await AuthManager.completarAcceso(login);

      if (!mounted) return;

      await PermisoNotificaciones.asegurar(context, MotivoPermiso.inicioSesion);

      if (!mounted) return;

      // Se limpia la pila: no se puede volver a un registro ya hecho.
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.club,
        (route) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _error = mensajeErrorFamilia(_t, e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _reenviar() async {
    setState(() {
      _reenviando = true;
      _error = null;
      _aviso = null;
    });

    try {
      await widget.servicio.reenviarCodigo(widget.email);

      if (mounted) setState(() => _aviso = _t.familyCodeResent);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = mensajeErrorFamilia(_t, e));
    } catch (e) {
      if (mounted) setState(() => _error = mensajeErrorFamilia(_t, e));
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: t.familyCodeTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            t.familyCodeIntro(widget.email),
                            key: const ValueKey('familia-codigo-intro'),
                            style: TextStyle(color: colores.onSurfaceVariant),
                          ),
                          if (widget.envioFallido) ...[
                            const SizedBox(height: 12),
                            _caja(
                              t.familySendFailed,
                              colores.error,
                              'familia-envio-fallido',
                            ),
                          ],
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const ValueKey('familia-codigo'),
                            controller: _codigo,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 22,
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              labelText: t.codeLabel,
                              prefixIcon: const Icon(Icons.vpn_key_outlined),
                              counterText: '',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return t.codeRequired;
                              }

                              return v.trim().length != 6 ? t.codeLength : null;
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const ValueKey('familia-reenviar'),
                              onPressed: (_reenviando || _cargando)
                                  ? null
                                  : _reenviar,
                              child: Text(t.familyResendCode),
                            ),
                          ),
                          if (_aviso != null)
                            _caja(
                              _aviso!,
                              colores.primary,
                              'familia-codigo-reenviado',
                            ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: const ValueKey('familia-password'),
                            controller: _password,
                            obscureText: !_mostrarPassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: t.newPasswordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _mostrarPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _mostrarPassword = !_mostrarPassword,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return t.passwordChooseRequired;
                              }

                              return v.length < 8 ? t.passwordMinLength : null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const ValueKey('familia-confirmar'),
                            controller: _confirmar,
                            obscureText: !_mostrarPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_cargando) _verificar();
                            },
                            decoration: InputDecoration(
                              labelText: t.repeatPasswordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            validator: (v) => v != _password.text
                                ? t.passwordsDontMatch
                                : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            _caja(_error!, colores.error, 'familia-error'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      key: const ValueKey('familia-confirmar-entrar'),
                      onPressed: _cargando ? null : _verificar,
                      child: _cargando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t.familyConfirmAndEnter),
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

  Widget _caja(String texto, Color color, String clave) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        key: ValueKey(clave),
        textAlign: TextAlign.center,
        style: TextStyle(color: color),
      ),
    );
  }
}
