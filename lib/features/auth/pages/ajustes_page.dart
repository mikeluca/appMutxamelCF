import 'package:flutter/material.dart';

import '../../../core/config/app_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/services/push_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/preferencias_notificacion_model.dart';
import '../../../routing/app_routes.dart';
import '../services/auth_manager.dart';
import '../services/auth_service.dart';
import '../services/preferencias_notificacion_service.dart';
import 'acerca_de_page.dart';

class AjustesPage extends StatefulWidget {
  final String temaActual;
  final ValueChanged<String> onTemaChanged;
  final String idiomaActual;
  final ValueChanged<String> onIdiomaChanged;

  const AjustesPage({
    super.key,
    required this.temaActual,
    required this.onTemaChanged,
    required this.idiomaActual,
    required this.onIdiomaChanged,
  });

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  PreferenciasNotificacionModel? _preferencias;

  bool _cargandoPreferencias = true;
  bool _guardandoPreferencias = false;

  // Preferencias "anónimas" (sin sesión iniciada): guardadas en el
  // dispositivo, no ligadas a ninguna cuenta.
  bool _notifNoticiasAnonimo = false;
  bool _notifResultadosAnonimo = false;
  bool _cargandoPreferenciasAnonimas = true;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    if (AuthManager.estaAutenticado) {
      _cargarPreferencias();
    } else {
      _cargarPreferenciasAnonimas();
    }
  }

  Future<void> _cargarPreferenciasAnonimas() async {
    final noticias = await AppPreferences.obtenerNotifNoticias();
    final resultados = await AppPreferences.obtenerNotifResultados();

    if (!mounted) return;

    setState(() {
      _notifNoticiasAnonimo = noticias;
      _notifResultadosAnonimo = resultados;
      _cargandoPreferenciasAnonimas = false;
    });
  }

  Future<void> _cambiarNotifNoticiasAnonimo(bool valor) async {
    setState(() => _notifNoticiasAnonimo = valor);

    if (valor) {
      await PushNotificationService.suscribirATopic(
        PushNotificationService.topicNoticias,
      );
    } else {
      await PushNotificationService.desuscribirDeTopic(
        PushNotificationService.topicNoticias,
      );
    }

    await AppPreferences.guardarNotifNoticias(valor);
  }

  Future<void> _cambiarNotifResultadosAnonimo(bool valor) async {
    setState(() => _notifResultadosAnonimo = valor);

    if (valor) {
      await PushNotificationService.suscribirATopic(
        PushNotificationService.topicResultados,
      );
    } else {
      await PushNotificationService.desuscribirDeTopic(
        PushNotificationService.topicResultados,
      );
    }

    await AppPreferences.guardarNotifResultados(valor);
  }

  Future<void> _cargarPreferencias() async {
    try {
      final preferencias =
          await PreferenciasNotificacionService.obtenerPreferencias();

      if (!mounted) return;

      setState(() {
        _preferencias = preferencias;
        _cargandoPreferencias = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cargandoPreferencias = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.settingsPreferencesLoadError)));
    }
  }

  Future<void> _actualizarPreferencias({
    bool? notificacionesActivadas,
    bool? noticiasActivadas,
    bool? comunicacionesActivadas,
    bool? mensajesActivados,
    bool? resultadosActivados,
  }) async {
    final actuales = _preferencias;

    if (actuales == null || _guardandoPreferencias) {
      return;
    }

    final nuevas = PreferenciasNotificacionModel(
      usuarioAppId: actuales.usuarioAppId,
      notificacionesActivadas:
          notificacionesActivadas ?? actuales.notificacionesActivadas,
      noticiasActivadas: noticiasActivadas ?? actuales.noticiasActivadas,
      comunicacionesActivadas:
          comunicacionesActivadas ?? actuales.comunicacionesActivadas,
      mensajesActivados: mensajesActivados ?? actuales.mensajesActivados,
      resultadosActivados: resultadosActivados ?? actuales.resultadosActivados,
    );

    setState(() {
      _preferencias = nuevas;
      _guardandoPreferencias = true;
    });

    try {
      final actualizadas =
          await PreferenciasNotificacionService.actualizarPreferencias(nuevas);

      if (!mounted) return;

      setState(() {
        _preferencias = actualizadas;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _preferencias = actuales;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t.settingsPreferenceSaveError)));
    } finally {
      if (mounted) {
        setState(() {
          _guardandoPreferencias = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.settingsTitle)),
      body: AuthManager.estaAutenticado
          ? _construirContenidoConSesion()
          : _construirContenidoAnonimo(),
    );
  }

  Widget _construirContenidoAnonimo() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          _t.settingsNotifAnonymousHint,
          style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
        ),

        const SizedBox(height: 16),

        _construirSeccion(
          titulo: _t.settingsSectionNotifications,
          icono: Icons.notifications_none_outlined,
          children: [
            if (_cargandoPreferenciasAnonimas)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _colors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: CircularProgressIndicator()),
              )
            else ...[
              _construirSwitch(
                icono: Icons.article_outlined,
                titulo: _t.settingsNotifNewsAnon,
                subtitulo: _t.settingsNotifNewsAnonSubtitle,
                valor: _notifNoticiasAnonimo,
                onChanged: (valor) => _cambiarNotifNoticiasAnonimo(valor),
              ),

              const SizedBox(height: 10),

              _construirSwitch(
                icono: Icons.sports_soccer_outlined,
                titulo: _t.settingsNotifResultsFirstTeam,
                subtitulo: _t.settingsNotifResultsFirstTeamSubtitle,
                valor: _notifResultadosAnonimo,
                onChanged: (valor) => _cambiarNotifResultadosAnonimo(valor),
              ),
            ],
          ],
        ),

        const SizedBox(height: 24),

        _construirSeccion(
          titulo: _t.settingsLanguage,
          icono: Icons.translate_outlined,
          children: [_construirOpcionIdioma()],
        ),
      ],
    );
  }

  Widget _construirContenidoConSesion() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        _construirSeccion(
          titulo: _t.settingsSectionNotifications,
          icono: Icons.notifications_none_outlined,
          children: [
            if (_cargandoPreferencias)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _colors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_preferencias != null) ...[
              _construirSwitch(
                icono: Icons.notifications_outlined,
                titulo: _t.settingsNotifGeneral,
                subtitulo: _preferencias!.notificacionesActivadas
                    ? _t.settingsNotifGeneralSubtitleOn
                    : _t.settingsNotifGeneralSubtitleOff,
                valor: _preferencias!.notificacionesActivadas,
                onChanged: (valor) {
                  _actualizarPreferencias(notificacionesActivadas: valor);
                },
              ),

              const SizedBox(height: 10),

              _construirSwitch(
                icono: Icons.article_outlined,
                titulo: _t.settingsNotifNews,
                subtitulo: _t.settingsNotifNewsSubtitle,
                valor: _preferencias!.noticiasActivadas,
                onChanged: _preferencias!.notificacionesActivadas
                    ? (valor) {
                        _actualizarPreferencias(noticiasActivadas: valor);
                      }
                    : null,
              ),

              const SizedBox(height: 10),

              _construirSwitch(
                icono: Icons.chat_bubble_outline,
                titulo: _t.settingsNotifMessages,
                subtitulo: _t.settingsNotifMessagesSubtitle,
                valor: _preferencias!.mensajesActivados,
                onChanged: _preferencias!.notificacionesActivadas
                    ? (valor) {
                        _actualizarPreferencias(mensajesActivados: valor);
                      }
                    : null,
              ),

              const SizedBox(height: 10),

              _construirSwitch(
                icono: Icons.sports_soccer_outlined,
                titulo: _t.settingsNotifResults,
                subtitulo: _t.settingsNotifResultsSubtitle,
                valor: _preferencias!.resultadosActivados,
                onChanged: _preferencias!.notificacionesActivadas
                    ? (valor) {
                        _actualizarPreferencias(resultadosActivados: valor);
                      }
                    : null,
              ),

              if (_guardandoPreferencias) ...[
                const SizedBox(height: 12),
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ],
        ),

        const SizedBox(height: 24),

        _construirSeccion(
          titulo: _t.settingsSectionApplication,
          icono: Icons.phone_android_outlined,
          children: [
            _construirOpcionApariencia(),

            const SizedBox(height: 10),

            _construirOpcionIdioma(),

            const SizedBox(height: 10),

            _construirOpcion(
              icono: Icons.info_outline,
              titulo: _t.settingsAboutApp,
              subtitulo: _t.settingsAboutAppSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AcercaDePage()),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        _construirSeccion(
          titulo: _t.settingsSectionAccount,
          icono: Icons.manage_accounts_outlined,
          children: [
            _construirOpcion(
              icono: Icons.delete_forever_outlined,
              titulo: _t.settingsDeleteAccount,
              subtitulo: _t.settingsDeleteAccountSubtitle,
              colorIcono: _colors.error,
              onTap: _eliminarCuenta,
            ),
          ],
        ),
      ],
    );
  }

  /// Pide confirmación y contraseña, borra la cuenta en el backend y,
  /// si todo va bien, cierra la sesión y vuelve al inicio.
  Future<void> _eliminarCuenta() async {
    final eliminada = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _EliminarCuentaDialog(),
    );

    if (eliminada != true || !mounted) return;

    final mensaje = _t.deleteAccountDone;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // La cuenta ya no existe en el backend: no se intenta desregistrar el
    // dispositivo con un token inválido, solo se limpia lo local.
    await PushNotificationService.borrarTokenFcmLocal();
    await AuthManager.cerrarSesion(desregistrarDispositivo: false);

    messenger.showSnackBar(SnackBar(content: Text(mensaje)));

    navigator.pushNamedAndRemoveUntil(AppRoutes.public, (route) => false);
  }

  Widget _construirSeccion({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: _colors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                color: _colors.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...children,
      ],
    );
  }

  Widget _construirSwitch({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.azul.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: _colors.primary, size: 24),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitulo,
                  style: TextStyle(
                    color: _colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: valor,
            onChanged: onChanged,
            activeThumbColor: AppColors.azul,
          ),
        ],
      ),
    );
  }

  Widget _construirOpcionApariencia() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.azul.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.dark_mode_outlined,
              color: _colors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t.settingsAppearance,
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _t.settingsAppearanceSubtitle,
                  style: TextStyle(
                    color: _colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.temaActual,
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(_t.settingsThemeAuto),
                ),
                DropdownMenuItem(
                  value: 'light',
                  child: Text(_t.settingsThemeLight),
                ),
                DropdownMenuItem(
                  value: 'dark',
                  child: Text(_t.settingsThemeDark),
                ),
              ],
              onChanged: (valor) {
                if (valor == null) return;

                widget.onTemaChanged(valor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirOpcionIdioma() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.azul.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.translate_outlined,
              color: _colors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t.settingsLanguage,
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _t.settingsLanguageSubtitle,
                  style: TextStyle(
                    color: _colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.idiomaActual,
              items: [
                DropdownMenuItem(
                  value: 'es',
                  child: Text(_t.settingsLanguageSpanish),
                ),
                DropdownMenuItem(
                  value: 'ca',
                  child: Text(_t.settingsLanguageValencian),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(_t.settingsLanguageEnglish),
                ),
              ],
              onChanged: (valor) {
                if (valor == null) return;

                widget.onIdiomaChanged(valor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirOpcion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color? colorIcono,
  }) {
    return Material(
      color: _colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.azul.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icono,
                  color: colorIcono ?? _colors.primary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: _colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: _colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: _colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo de confirmación del borrado de cuenta: explica qué se borra,
/// pide la contraseña y llama al backend. Se cierra con `true` solo si
/// la cuenta se ha eliminado; los errores se muestran dentro del diálogo.
class _EliminarCuentaDialog extends StatefulWidget {
  const _EliminarCuentaDialog();

  @override
  State<_EliminarCuentaDialog> createState() => _EliminarCuentaDialogState();
}

class _EliminarCuentaDialogState extends State<_EliminarCuentaDialog> {
  final TextEditingController _passwordController = TextEditingController();

  bool _eliminando = false;
  String? _error;

  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() => _error = _t.deleteAccountPasswordRequired);
      return;
    }

    setState(() {
      _eliminando = true;
      _error = null;
    });

    try {
      await AuthService.eliminarCuenta(password: password);

      if (!mounted) return;

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _eliminando = false;
        _error = switch (e.statusCode) {
          400 => _t.deleteAccountWrongPassword,
          429 => _t.deleteAccountTooManyAttempts,
          _ => _t.deleteAccountError,
        };
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _eliminando = false;
        _error = _t.deleteAccountError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_t.deleteAccountDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t.deleteAccountWarning),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              enabled: !_eliminando,
              autofocus: true,
              decoration: InputDecoration(
                labelText: _t.deleteAccountPasswordLabel,
                border: const OutlineInputBorder(),
                errorText: _error,
                errorMaxLines: 3,
              ),
              onSubmitted: (_) => _confirmar(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _eliminando ? null : () => Navigator.pop(context, false),
          child: Text(_t.cancel),
        ),
        FilledButton(
          onPressed: _eliminando ? null : _confirmar,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: _eliminando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_t.deleteAccountConfirm),
        ),
      ],
    );
  }
}
