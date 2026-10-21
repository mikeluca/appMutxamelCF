import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../services/auth_manager.dart';
import '../services/auth_service.dart';
import 'activar_cuenta_page.dart';
import 'login_page.dart';

/// Pantalla 2 de "¿Has olvidado tu contraseña?": código de 6 dígitos y
/// contraseña nueva. Con éxito entra directamente en el Área Club.
class RestablecerPasswordPage extends StatefulWidget {
  final String email;

  const RestablecerPasswordPage({super.key, required this.email});

  /// Lo que el backend tarda en admitir otra petición para el mismo email.
  static const Duration esperaReenvio = Duration(minutes: 2);

  @override
  State<RestablecerPasswordPage> createState() =>
      _RestablecerPasswordPageState();
}

class _RestablecerPasswordPageState extends State<RestablecerPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  Timer? _temporizador;
  int _segundosRestantes = RestablecerPasswordPage.esperaReenvio.inSeconds;

  bool _mostrarPassword = false;
  bool _cargando = false;
  bool _reenviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciarCuentaAtras();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _codigoController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  void _iniciarCuentaAtras() {
    _temporizador?.cancel();
    _segundosRestantes = RestablecerPasswordPage.esperaReenvio.inSeconds;

    _temporizador = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _segundosRestantes--;
      });

      if (_segundosRestantes <= 0) {
        timer.cancel();
      }
    });
  }

  String _formatearTiempo(int segundos) {
    final minutos = (segundos ~/ 60).toString();
    final resto = (segundos % 60).toString().padLeft(2, '0');

    return '$minutos:$resto';
  }

  Future<void> _reenviarCodigo() async {
    final t = AppLocalizations.of(context);

    setState(() {
      _reenviando = true;
      _error = null;
    });

    try {
      await AuthService.recuperarPassword(email: widget.email);

      if (!mounted) return;

      _iniciarCuentaAtras();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.recoverCodeSent)));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = mensajeDeRecuperacion(t, e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _reenviando = false;
        });
      }
    }
  }

  Future<void> _cambiarPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final t = AppLocalizations.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final loginResponse = await AuthService.restablecerPassword(
        email: widget.email,
        codigo: _codigoController.text,
        password: _passwordController.text,
      );

      try {
        await AuthManager.completarAcceso(loginResponse);
      } catch (_) {
        // La contraseña YA se ha cambiado; solo ha fallado dejar la sesión
        // lista (p. ej. sin red). No se enseña un error: se lleva al login
        // con el email relleno para que entre con la contraseña nueva.
        try {
          await AuthManager.cerrarSesion(desregistrarDispositivo: false);
        } catch (_) {
          // Nada que limpiar.
        }

        mensajes.showSnackBar(
          SnackBar(content: Text(t.recoverChangedLoginHint)),
        );

        if (!mounted) return;

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginPage(emailInicial: widget.email),
          ),
          (route) => route.isFirst,
        );

        return;
      }

      mensajes.showSnackBar(SnackBar(content: Text(t.recoverPasswordChanged)));

      if (!mounted) return;

      // Entrada directa al Área Club: se limpia toda la pila (login +
      // recuperación) para no volver a una pantalla ya usada.
      navigator.pushNamedAndRemoveUntil(AppRoutes.club, (route) => false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException && e.statusCode == 400
              ? t.recoverCodeInvalid
              : mensajeDeRecuperacion(t, e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final puedeReenviar = _segundosRestantes <= 0 && !_reenviando && !_cargando;

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: t.recoverTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t.recoverCodeSent,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      t.recoverResetHeading,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 24),

                    TextFormField(
                      key: const Key('recuperar_email'),
                      initialValue: widget.email,
                      readOnly: true,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: t.storeEmailLabel,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      key: const Key('recuperar_codigo'),
                      controller: _codigoController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return t.codeRequired;
                        }

                        if (value.trim().length != 6) {
                          return t.codeLength;
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      key: const Key('recuperar_password'),
                      controller: _passwordController,
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
                          onPressed: () {
                            setState(() {
                              _mostrarPassword = !_mostrarPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t.passwordChooseRequired;
                        }

                        if (value.length < 8) {
                          return t.passwordMinLength;
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      key: const Key('recuperar_confirmar'),
                      controller: _confirmarPasswordController,
                      obscureText: !_mostrarPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_cargando) {
                          _cambiarPassword();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: t.repeatPasswordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return t.passwordsDontMatch;
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _cambiarPassword,
                        child: _cargando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(t.recoverChangePassword),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: puedeReenviar ? _reenviarCodigo : null,
                      child: Text(
                        _segundosRestantes > 0
                            ? t.recoverResendIn(
                                _formatearTiempo(_segundosRestantes),
                              )
                            : t.recoverResend,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${t.recoverNotActivated} ',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        InkWell(
                          onTap: _cargando
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ActivarCuentaPage(
                                      emailInicial: widget.email,
                                    ),
                                  ),
                                ),
                          child: Text(
                            t.activateAccountButton,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
