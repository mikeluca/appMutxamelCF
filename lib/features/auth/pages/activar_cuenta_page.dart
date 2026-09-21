import 'package:flutter/material.dart';

import '../../../routing/app_routes.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../services/auth_manager.dart';
import '../services/auth_service.dart';

class ActivarCuentaPage extends StatefulWidget {
  const ActivarCuentaPage({super.key});

  @override
  State<ActivarCuentaPage> createState() => _ActivarCuentaPageState();
}

class _ActivarCuentaPageState extends State<ActivarCuentaPage> {
  final _formKey = GlobalKey<FormState>();

  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _mostrarPassword = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _activarCuenta() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final loginResponse = await AuthService.activarCuenta(
        token: _tokenController.text,
        password: _passwordController.text,
      );

      await AuthManager.completarAcceso(loginResponse);

      if (!mounted) return;

      // Entrada directa al Área Club: se limpia toda la pila de
      // navegación (login + esta pantalla) para que el usuario no
      // pueda volver atrás a una pantalla de activación ya usada.
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.club,
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
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
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: 'Activar cuenta')),
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
                      'Activa tu cuenta',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Introduce el código que te ha enviado el club por '
                      'email y elige tu contraseña de acceso.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _tokenController,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Código de activación',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Introduce el código que te enviamos por email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_mostrarPassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
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
                          return 'Elige una contraseña';
                        }

                        if (value.length < 8) {
                          return 'Debe tener al menos 8 caracteres';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmarPasswordController,
                      obscureText: !_mostrarPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (!_cargando) {
                          _activarCuenta();
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Repite la contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
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
                        onPressed: _cargando ? null : _activarCuenta,
                        child: _cargando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Activar y entrar'),
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
