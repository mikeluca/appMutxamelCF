import 'package:material_ui/material_ui.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../services/juego_service.dart';

/// El diálogo para elegir o cambiar el alias del ranking: enseña las reglas del backend y, si el servidor rechaza el
/// alias (no vale, está en uso...), su mensaje sin cerrarse.
class DialogoAlias extends StatefulWidget {
  const DialogoAlias({super.key, required this.servicio, this.aliasActual});

  final JuegoService servicio;
  final String? aliasActual;

  /// Lo abre y devuelve el alias guardado (null si se cancela).
  static Future<String?> mostrar(
    BuildContext context, {
    required JuegoService servicio,
    String? aliasActual,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) =>
          DialogoAlias(servicio: servicio, aliasActual: aliasActual),
    );
  }

  @override
  State<DialogoAlias> createState() => _DialogoAliasState();
}

class _DialogoAliasState extends State<DialogoAlias> {
  late final TextEditingController _controlador = TextEditingController(
    text: widget.aliasActual ?? '',
  );

  bool _guardando = false;
  String? _error;
  bool _sesionCaducada = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final t = AppLocalizations.of(context);
    final alias = _controlador.text.trim();

    if (alias.isEmpty || _guardando) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final perfil = await widget.servicio.actualizarPerfil(alias: alias);

      if (!mounted) return;

      Navigator.pop(context, perfil.alias ?? alias);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _guardando = false;
        _sesionCaducada = esSesionCaducada(e);
        // Cada código con su mensaje: 400 y 409 traen el motivo del servidor; 401, 403 y 5xx tienen el suyo.
        _error = mensajeDeJuego(t, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(t.gameAliasTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.gameAliasRules),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('campo-alias'),
              controller: _controlador,
              autofocus: true,
              maxLength: 15,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _guardar(),
              decoration: InputDecoration(
                labelText: t.gameAliasLabel,
                border: const OutlineInputBorder(),
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (_sesionCaducada)
          TextButton(
            key: const ValueKey('ir-a-login'),
            onPressed: () {
              final navegador = Navigator.of(context);

              navegador.pop();
              navegador.pushNamed(AppRoutes.login);
            },
            child: Text(t.loginButton),
          ),
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          key: const ValueKey('guardar-alias'),
          onPressed: _guardando ? null : _guardar,
          child: Text(t.save),
        ),
      ],
    );
  }
}
