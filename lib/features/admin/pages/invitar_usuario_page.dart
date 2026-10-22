import 'package:flutter/material.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/utils/nombre_rol.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/admin_model.dart';
import '../services/admin_service.dart';

/// Formulario para invitar a una persona a la app (ADMIN_APP): nombre, apellidos y email,
/// los vínculos con personas del club (jugador, familiar, cuerpo técnico) y los roles
/// adicionales. Muestra los roles que tendrá la cuenta antes de enviar. Al invitar vuelve
/// con la [InvitacionEnviadaModel].
class InvitarUsuarioPage extends StatefulWidget {
  final AdminService? servicio;

  const InvitarUsuarioPage({super.key, this.servicio});

  @override
  State<InvitarUsuarioPage> createState() => _InvitarUsuarioPageState();
}

class _InvitarUsuarioPageState extends State<InvitarUsuarioPage> {
  /// Cuántas personas se listan a la vez bajo el buscador.
  static const int _maximoResultados = 30;

  late final AdminService _servicio = widget.servicio ?? AdminService();

  late Future<VinculosDisponiblesModel> _futuro;

  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _apellidos = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _busqueda = TextEditingController();

  TipoVinculo _tipo = TipoVinculo.jugador;

  /// Las personas elegidas, en el orden en que se eligieron.
  final List<PersonaDisponibleModel> _elegidos = [];
  final Set<String> _roles = {};

  bool _enviando = false;
  String? _errorNombre;
  String? _errorEmail;
  String? _errorVinculos;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerVinculosDisponibles();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellidos.dispose();
    _email.dispose();
    _busqueda.dispose();
    super.dispose();
  }

  bool get _hayFicha => _elegidos.isNotEmpty;

  bool get _hayFamiliar =>
      _elegidos.any((p) => p.tipo == TipoVinculo.familiar);

  /// Los roles que tendrá la cuenta: uno por tipo de vínculo elegido, más los adicionales.
  List<String> get _rolesResultantes => {
    for (final p in _elegidos) p.tipo.codigo,
    ..._roles,
  }.toList();

  String _etiquetaTipo(TipoVinculo tipo) => switch (tipo) {
    TipoVinculo.jugador => _t.inviteLinkPlayer,
    TipoVinculo.familiar => _t.inviteLinkFamily,
    TipoVinculo.cuerpoTecnico => _t.inviteLinkStaff,
  };

  bool _emailValido(String texto) {
    final limpio = texto.trim();

    return limpio.contains('@') &&
        limpio.indexOf('@') > 0 &&
        limpio.lastIndexOf('.') > limpio.indexOf('@') + 1 &&
        !limpio.endsWith('.');
  }

  Future<void> _enviar() async {
    final nombre = _nombre.text.trim();
    final email = _email.text.trim();

    String? errorNombre;
    String? errorEmail;
    String? errorVinculos;

    if (_elegidos.isEmpty && _roles.isEmpty) {
      errorVinculos = _t.inviteSummaryEmpty;
    }

    // Sin ficha de la que sacar el nombre, hay que escribirlo.
    if (!_hayFicha && nombre.isEmpty) {
      errorNombre = _t.inviteNameRequired;
    }

    // Con un familiar el servidor usa el email de su ficha.
    if (!_hayFamiliar && !_emailValido(email)) {
      errorEmail = _t.inviteEmailRequired;
    }

    setState(() {
      _errorNombre = errorNombre;
      _errorEmail = errorEmail;
      _errorVinculos = errorVinculos;
    });

    if (errorNombre != null || errorEmail != null || errorVinculos != null) {
      return;
    }

    setState(() => _enviando = true);

    try {
      final invitacion = await _servicio.invitar(
        email: email,
        nombre: nombre,
        apellidos: _apellidos.text,
        vinculos: _elegidos,
        roles: _roles.toList(),
      );

      if (!mounted) return;

      Navigator.pop(context, invitacion);
    } catch (e) {
      if (!mounted) return;

      // Los 4xx traen un mensaje claro (email ya registrado, rol no permitido...).
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeDeAccion(_t, e))));

      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.inviteTitle)),
      body: FutureBuilder<VinculosDisponiblesModel>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error is Exception
                          ? mensajeDeError(_t, snapshot.error)
                          : _t.inviteLoadError,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {
                        _futuro = _servicio.obtenerVinculosDisponibles();
                      }),
                      icon: const Icon(Icons.refresh),
                      label: Text(_t.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          return _construirFormulario(snapshot.data!);
        },
      ),
    );
  }

  Widget _construirFormulario(VinculosDisponiblesModel datos) {
    final roles = _rolesResultantes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        TextField(
          key: const ValueKey('invitar-nombre'),
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: _t.inviteNameLabel,
            errorText: _errorNombre,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('invitar-apellidos'),
          controller: _apellidos,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: _t.inviteSurnameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('invitar-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: _t.inviteEmailLabel,
            helperText: _hayFamiliar ? _t.inviteEmailFromFamily : null,
            errorText: _errorEmail,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _t.inviteLinksTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<TipoVinculo>(
          key: const ValueKey('invitar-tipo'),
          showSelectedIcon: false,
          segments: [
            for (final tipo in TipoVinculo.values)
              ButtonSegment(value: tipo, label: Text(_etiquetaTipo(tipo))),
          ],
          selected: {_tipo},
          onSelectionChanged: (seleccion) => setState(() {
            _tipo = seleccion.first;
            _busqueda.clear();
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('invitar-busqueda'),
          controller: _busqueda,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: _t.inviteSearchHint,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        ),
        ..._construirResultados(datos),
        if (_elegidos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final persona in _elegidos)
                InputChip(
                  key: ValueKey('elegido-${persona.tipo.codigo}-${persona.id}'),
                  avatar: Icon(_icono(persona.tipo), size: 18),
                  label: Text(persona.nombre),
                  onDeleted: _enviando
                      ? null
                      : () => setState(() => _elegidos.remove(persona)),
                ),
            ],
          ),
        ],
        if (datos.roles.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            _t.inviteRolesTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          for (final rol in datos.roles)
            CheckboxListTile(
              key: ValueKey('rol-${rol.codigo}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _roles.contains(rol.codigo),
              title: Text(nombreDeRol(_t, rol.codigo)),
              onChanged: _enviando
                  ? null
                  : (valor) => setState(() {
                      if (valor == true) {
                        _roles.add(rol.codigo);
                      } else {
                        _roles.remove(rol.codigo);
                      }
                    }),
            ),
        ],
        const SizedBox(height: 24),
        Container(
          key: const ValueKey('invitar-resumen'),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: _errorVinculos == null
                ? null
                : Border.all(color: Colors.redAccent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t.inviteSummaryTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (roles.isEmpty)
                Text(
                  _errorVinculos ?? _t.inviteSummaryEmpty,
                  style: TextStyle(
                    color: _errorVinculos == null
                        ? _colors.onSurfaceVariant
                        : Colors.redAccent,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  children: [
                    for (final rol in roles)
                      Chip(
                        key: ValueKey('resumen-$rol'),
                        label: Text(nombreDeRol(_t, rol)),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('invitar-enviar'),
          onPressed: _enviando ? null : _enviar,
          icon: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: Text(_t.inviteSubmit),
        ),
      ],
    );
  }

  IconData _icono(TipoVinculo tipo) => switch (tipo) {
    TipoVinculo.jugador => Icons.sports_soccer,
    TipoVinculo.familiar => Icons.family_restroom,
    TipoVinculo.cuerpoTecnico => Icons.sports,
  };

  List<Widget> _construirResultados(VinculosDisponiblesModel datos) {
    final texto = _busqueda.text.trim().toLowerCase();

    final resultados = datos
        .de(_tipo)
        .where((p) => !_elegidos.contains(p))
        .where((p) => texto.isEmpty || p.nombre.toLowerCase().contains(texto))
        .take(_maximoResultados)
        .toList();

    if (resultados.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _t.inviteNoResults,
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
        ),
      ];
    }

    return [
      for (final persona in resultados)
        ListTile(
          key: ValueKey('persona-${persona.tipo.codigo}-${persona.id}'),
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(persona.nombre),
          subtitle: persona.detalle.isEmpty ? null : Text(persona.detalle),
          trailing: const Icon(Icons.add_circle_outline),
          onTap: _enviando
              ? null
              : () => setState(() {
                  _elegidos.add(persona);
                  _errorVinculos = null;
                }),
        ),
    ];
  }
}
