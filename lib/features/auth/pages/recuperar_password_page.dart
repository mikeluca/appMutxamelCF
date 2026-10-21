import 'package:flutter/material.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../services/auth_service.dart';
import 'restablecer_password_page.dart';

/// Pantalla 1 de "¿Has olvidado tu contraseña?": pide el email y, enviado el
/// código, pasa a [RestablecerPasswordPage]. El backend responde igual exista o
/// no la cuenta, así que esta pantalla también: nunca dice si el email existe.
class RecuperarPasswordPage extends StatefulWidget {
  /// Email que ya se había escrito en el login, si lo había.
  final String? emailInicial;

  const RecuperarPasswordPage({super.key, this.emailInicial});

  @override
  State<RecuperarPasswordPage> createState() => _RecuperarPasswordPageState();
}

class _RecuperarPasswordPageState extends State<RecuperarPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController = TextEditingController(
    text: widget.emailInicial?.trim() ?? '',
  );

  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final t = AppLocalizations.of(context);
    final email = _emailController.text.trim().toLowerCase();

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await AuthService.recuperarPassword(email: email);

      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RestablecerPasswordPage(email: email),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = mensajeDeRecuperacion(t, e);
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
                    Image.asset('assets/images/escudo.png', height: 110),

                    const SizedBox(height: 24),

                    Text(
                      t.recoverTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      t.recoverSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      onFieldSubmitted: (_) {
                        if (!_cargando) {
                          _enviarCodigo();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: t.storeEmailLabel,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return t.loginEmailRequired;
                        }

                        if (!value.contains('@')) {
                          return t.loginEmailInvalid;
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
                        onPressed: _cargando ? null : _enviarCodigo,
                        child: _cargando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(t.recoverSendCode),
                      ),
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
