import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/mensaje_error.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/solicitud_familia_model.dart';

/// La política de privacidad de la web del club.
const String urlPoliticaPrivacidad = 'https://mutxamelcf.es/politicaPrivacidad';

/// Máximo de hijos por solicitud (lo impone el backend).
const int maxHijosSolicitud = 5;

/// Categorías que se sugieren al escribir el equipo. Solo ayudan a escribir: NUNCA salen nombres de jugadores.
const List<String> categoriasSugeridas = [
  'Escuelita',
  'Prebenjamín',
  'Benjamín',
  'Alevín',
  'Infantil',
  'Cadete',
  'Juvenil',
];

/// El texto de un parentesco en el idioma de la app.
String textoParentesco(AppLocalizations t, ParentescoFamilia p) {
  return switch (p) {
    ParentescoFamilia.madre => t.familyRelMother,
    ParentescoFamilia.padre => t.familyRelFather,
    ParentescoFamilia.tutor => t.familyRelGuardian,
    ParentescoFamilia.otro => t.familyRelOther,
  };
}

/// El texto de un parentesco a partir del código del backend (el código si no se reconoce).
String textoParentescoDeCodigo(AppLocalizations t, String codigo) {
  final p = ParentescoFamilia.deCodigo(codigo);

  return p == null ? codigo : textoParentesco(t, p);
}

/// Un desplegable con los cuatro parentescos.
class SelectorParentesco extends StatelessWidget {
  final ParentescoFamilia? valor;
  final ValueChanged<ParentescoFamilia?> onChanged;

  const SelectorParentesco({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return DropdownButtonFormField<ParentescoFamilia>(
      key: const ValueKey('familia-parentesco'),
      initialValue: valor,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: t.familyRelationship,
        prefixIcon: const Icon(Icons.family_restroom_outlined),
      ),
      items: [
        for (final p in ParentescoFamilia.values)
          DropdownMenuItem(
            value: p,
            child: Text(textoParentesco(t, p), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
      validator: (v) => v == null ? t.familyRelationshipRequired : null,
    );
  }
}

class _HijoControles {
  final nombre = TextEditingController();
  final apellidos = TextEditingController();
  final equipo = TextEditingController();
  final focoEquipo = FocusNode();

  void dispose() {
    nombre.dispose();
    apellidos.dispose();
    equipo.dispose();
    focoEquipo.dispose();
  }
}

/// El paso "tus hijos": de uno a cinco, cada uno con nombre, apellidos y equipo o categoría (texto libre con
/// sugerencias de categorías). Se valida con [FormularioHijosState.validar] y se leen con
/// [FormularioHijosState.hijos].
class FormularioHijos extends StatefulWidget {
  const FormularioHijos({super.key});

  @override
  State<FormularioHijos> createState() => FormularioHijosState();
}

class FormularioHijosState extends State<FormularioHijos> {
  final _formKey = GlobalKey<FormState>();
  final List<_HijoControles> _controles = [_HijoControles()];

  @override
  void dispose() {
    for (final c in _controles) {
      c.dispose();
    }
    super.dispose();
  }

  bool validar() => _formKey.currentState?.validate() ?? false;

  List<HijoNuevo> get hijos => [
    for (final c in _controles)
      HijoNuevo(
        nombre: c.nombre.text,
        apellidos: c.apellidos.text,
        equipo: c.equipo.text,
      ),
  ];

  void _anadir() {
    if (_controles.length >= maxHijosSolicitud) return;

    setState(() => _controles.add(_HijoControles()));
  }

  void _quitar(int indice) {
    setState(() => _controles.removeAt(indice).dispose());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colores = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.familyChildrenIntro,
            style: TextStyle(color: colores.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _controles.length; i++) ...[
            _construirHijo(context, t, i),
            const SizedBox(height: 16),
          ],
          if (_controles.length < maxHijosSolicitud)
            OutlinedButton.icon(
              key: const ValueKey('familia-anadir-hijo'),
              onPressed: _anadir,
              icon: const Icon(Icons.person_add_alt_outlined),
              label: Text(t.familyAddChild),
            )
          else
            Text(
              t.familyMaxChildren,
              textAlign: TextAlign.center,
              style: TextStyle(color: colores.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _construirHijo(BuildContext context, AppLocalizations t, int i) {
    final c = _controles[i];
    final colores = Theme.of(context).colorScheme;

    return Container(
      key: ValueKey('familia-hijo-$i'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colores.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colores.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.familyChildNumber(i + 1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (_controles.length > 1)
                TextButton.icon(
                  key: ValueKey('familia-quitar-hijo-$i'),
                  onPressed: () => _quitar(i),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(t.familyRemoveChild),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('familia-hijo-nombre-$i'),
            controller: c.nombre,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: t.familyChildFirstName,
              counterText: '',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? t.familyChildNameRequired
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('familia-hijo-apellidos-$i'),
            controller: c.apellidos,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            maxLength: 150,
            decoration: InputDecoration(
              labelText: t.familyChildLastName,
              counterText: '',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? t.familyChildLastNameRequired
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('familia-hijo-equipo-$i'),
            controller: c.equipo,
            focusNode: c.focoEquipo,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            maxLength: 100,
            decoration: InputDecoration(
              labelText: t.familyChildTeam,
              hintText: t.familyChildTeamHint,
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          // Sugerencias de categorías EN el flujo (no en un desplegable que tape el botón en pantallas pequeñas).
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: [
              for (final categoria in categoriasSugeridas)
                ActionChip(
                  key: ValueKey('familia-sugerencia-$i-$categoria'),
                  label: Text(categoria),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    c.equipo.text = categoria;
                    c.equipo.selection = TextSelection.collapsed(
                      offset: categoria.length,
                    );
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Las dos casillas obligatorias: ser el representante legal (o estar autorizado) y aceptar la política de privacidad
/// (con enlace). Los avisos "Marca esta casilla" salen cuando [mostrarErrores] es true y la casilla sigue sin marcar.
class CasillasFamilia extends StatelessWidget {
  final bool representante;
  final bool privacidad;
  final bool mostrarErrores;
  final ValueChanged<bool> onRepresentante;
  final ValueChanged<bool> onPrivacidad;

  const CasillasFamilia({
    super.key,
    required this.representante,
    required this.privacidad,
    required this.mostrarErrores,
    required this.onRepresentante,
    required this.onPrivacidad,
  });

  Future<void> _abrirPolitica(BuildContext context) async {
    final uri = Uri.parse(urlPoliticaPrivacidad);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).linkOpenError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _casilla(
          context,
          clave: 'familia-casilla-representante',
          valor: representante,
          texto: t.familyDeclareRepresentative,
          onChanged: onRepresentante,
        ),
        _casilla(
          context,
          clave: 'familia-casilla-privacidad',
          valor: privacidad,
          texto: t.familyAcceptPrivacy,
          onChanged: onPrivacidad,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('familia-leer-privacidad'),
            onPressed: () => _abrirPolitica(context),
            child: Text(t.familyReadPrivacy),
          ),
        ),
      ],
    );
  }

  Widget _casilla(
    BuildContext context, {
    required String clave,
    required bool valor,
    required String texto,
    required ValueChanged<bool> onChanged,
  }) {
    final t = AppLocalizations.of(context);
    final error = mostrarErrores && !valor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          key: ValueKey(clave),
          value: valor,
          onChanged: (v) => onChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(texto),
        ),
        if (error)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Text(
              t.familyCheckRequired,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

/// El mensaje de un error de la API de las solicitudes: un 429 es "demasiados intentos"; un 4xx distinto de 403 trae
/// del backend un texto claro (reglas de negocio); lo demás, el error de conexión.
String mensajeErrorFamilia(AppLocalizations t, Object? error) {
  if (error is ApiException && error.statusCode == 429) {
    return t.familyTooManyAttempts;
  }

  return mensajeDeAccion(t, error);
}
