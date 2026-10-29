import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../services/reparto_service.dart';
import 'reparto_page.dart' show mensajeDeReparto;

/// Alta de un jugador de prueba en la temporada siguiente (COORDINADOR y
/// ADMIN_APP). Los errores del servidor (faltan datos, ninguna categoría cubre
/// su edad, aún no hay temporada siguiente) se muestran en texto claro.
class AltaPruebaPage extends StatefulWidget {
  /// Solo para tests: sustituye al servicio real.
  final RepartoService? servicio;

  const AltaPruebaPage({super.key, this.servicio});

  @override
  State<AltaPruebaPage> createState() => _AltaPruebaPageState();
}

class _AltaPruebaPageState extends State<AltaPruebaPage> {
  late final RepartoService _servicio = widget.servicio ?? RepartoService();

  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellidos = TextEditingController();
  final _anio = TextEditingController();

  bool _guardando = false;
  String? _error;
  String? _creado;

  @override
  void dispose() {
    _nombre.dispose();
    _apellidos.dispose();
    _anio.dispose();
    super.dispose();
  }

  String? _obligatorio(String? valor, AppLocalizations t) =>
      (valor ?? '').trim().isEmpty ? t.trialRequired : null;

  String? _validarAnio(String? valor, AppLocalizations t) {
    final anio = int.tryParse((valor ?? '').trim());

    if (anio == null || anio < 1950 || anio > DateTime.now().year) {
      return t.trialYearInvalid;
    }

    return null;
  }

  Future<void> _guardar() async {
    final t = AppLocalizations.of(context);

    if (!(_formulario.currentState?.validate() ?? false)) return;

    setState(() {
      _guardando = true;
      _error = null;
      _creado = null;
    });

    try {
      final prueba = await _servicio.altaPrueba(
        nombre: _nombre.text.trim(),
        apellidos: _apellidos.text.trim(),
        anioNacimiento: int.parse(_anio.text.trim()),
      );

      if (!mounted) return;

      _nombre.clear();
      _apellidos.clear();
      _anio.clear();

      setState(() => _creado = t.trialCreated(prueba.categoria ?? '-'));
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = mensajeDeReparto(t, e));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: t.trialTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.trialIntro, style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 16),
          Form(
            key: _formulario,
            child: Column(
              children: [
                TextFormField(
                  key: const ValueKey('prueba-nombre'),
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: t.trialName),
                  validator: (v) => _obligatorio(v, t),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('prueba-apellidos'),
                  controller: _apellidos,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: t.trialSurname),
                  validator: (v) => _obligatorio(v, t),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('prueba-anio'),
                  controller: _anio,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t.trialBirthYear),
                  validator: (v) => _validarAnio(v, t),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                key: const ValueKey('prueba-error'),
                style: TextStyle(color: colors.error),
              ),
            ),
          if (_creado != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _creado!,
                key: const ValueKey('prueba-creado'),
                style: TextStyle(color: colors.primary),
              ),
            ),
          FilledButton(
            key: const ValueKey('prueba-guardar'),
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.save),
          ),
        ],
      ),
    );
  }
}
