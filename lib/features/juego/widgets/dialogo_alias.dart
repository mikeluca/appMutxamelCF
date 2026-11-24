import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../l10n/gen/app_localizations.dart';
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

      final codigo = e is ApiException ? e.statusCode : null;

      setState(() {
        _guardando = false;
        // 400 (el alias no vale) y 409 (en uso) traen el motivo del servidor.
        _error = codigo == 400 || codigo == 409
            ? (e as ApiException).message
            : mensajeDeError(t, e);
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
