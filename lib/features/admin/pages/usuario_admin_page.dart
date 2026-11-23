import 'package:material_ui/material_ui.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/utils/texto_busqueda.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/services/auth_manager.dart';
import '../models/admin_model.dart';
import '../services/admin_service.dart';
import 'usuarios_admin_page.dart';

/// La ficha de una cuenta de la app (solo ADMIN_APP): editar el nombre (solo si no tiene ficha vinculada), ver, añadir y
/// quitar vínculos y roles, reenviar la invitación, activar o desactivar y eliminar una invitación sin activar. La
/// cuenta propia y las de otros administradores se ven pero no se tocan (sin botones); el servidor lo comprueba también
/// y, si responde que no, se muestra su mensaje.
class UsuarioAdminPage extends StatefulWidget {
  final UsuarioAdminModel usuario;
  final AdminService? servicio;

  /// Solo para tests: la cuenta que está usando la app (por defecto, la de la sesión).
  final int? usuarioActualId;

  const UsuarioAdminPage({
    super.key,
    required this.usuario,
    this.servicio,
    this.usuarioActualId,
  });

  @override
  State<UsuarioAdminPage> createState() => _UsuarioAdminPageState();
}

class _UsuarioAdminPageState extends State<UsuarioAdminPage> {
  late final AdminService _servicio = widget.servicio ?? AdminService();

  late UsuarioAdminModel _usuario = widget.usuario;

  VinculosDisponiblesModel? _opciones;
  bool _trabajando = false;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  int? get _miId =>
      widget.usuarioActualId ?? AuthManager.usuarioActual?.usuarioId;

  bool get _esPropia => _usuario.id == _miId;

  /// La cuenta propia y las de otros administradores no se tocan desde la app.
  bool get _puedeGestionar => !_esPropia && !_usuario.esAdmin;

  /// Ejecuta una acción, vuelve a pedir la cuenta y avisa; si falla enseña el mensaje del servidor. [alTerminar]
  /// decide qué se hace con la cuenta tras la acción (por defecto, refrescarla).
  Future<bool> _ejecutar(
    Future<void> Function() accion,
    String mensaje, {
    bool cerrarAlTerminar = false,
  }) async {
    setState(() => _trabajando = true);

    try {
      await accion();

      if (!mounted) return true;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));

      if (cerrarAlTerminar) {
        Navigator.pop(context);

        return true;
      }

      await _refrescar();

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeDeAdmin(_t, e))));

      return false;
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  /// Vuelve a pedir la cuenta al servidor (el estado, los roles y los vínculos pueden haber cambiado).
  Future<void> _refrescar() async {
    try {
      final todos = await _servicio.obtenerUsuarios();
      final actual = todos.where((u) => u.id == _usuario.id).firstOrNull;

      if (!mounted) return;

      if (actual == null) {
        Navigator.pop(context);

        return;
      }

      setState(() => _usuario = actual);
    } catch (_) {
      // Si no se puede refrescar se queda lo que había; el listado se recarga al volver.
    }
  }

  Future<bool> _confirmar(String texto, String boton) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirmar-accion'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(boton),
          ),
        ],
      ),
    );

    return confirmado == true && mounted;
  }

  Future<void> _reenviar() async {
    setState(() => _trabajando = true);

    try {
      final email = await _servicio.reenviarUsuario(_usuario.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t.pendingAccountsResent(email.isEmpty ? _usuario.email : email),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Los 4xx traen un mensaje claro del servidor (ya activa, "inténtalo en N min"...).
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeDeAdmin(_t, e))));
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _activar() async {
    if (!await _confirmar(
      _t.usersActivateConfirm(_usuario.email),
      _t.usersActivate,
    )) {
      return;
    }

    await _ejecutar(
      () => _servicio.activarUsuario(_usuario.id),
      _t.usersActivated,
    );
  }

  Future<void> _desactivar() async {
    if (!await _confirmar(
      _t.usersDeactivateConfirm(_usuario.email),
      _t.usersDeactivate,
    )) {
      return;
    }

    await _ejecutar(
      () => _servicio.desactivarUsuario(_usuario.id),
      _t.usersDeactivated,
    );
  }

  Future<void> _eliminar() async {
    if (!await _confirmar(
      _t.usersDeleteConfirm(_usuario.email),
      _t.usersDelete,
    )) {
      return;
    }

    await _ejecutar(
      () => _servicio.eliminarUsuario(_usuario.id),
      _t.usersDeleted,
      cerrarAlTerminar: true,
    );
  }

  Future<void> _editarNombre() async {
    final datos = await showDialog<({String nombre, String apellidos})>(
      context: context,
      builder: (_) => _DialogoNombre(nombreInicial: _usuario.nombre ?? ''),
    );

    if (datos == null || !mounted) return;

    await _ejecutar(
      () => _servicio.actualizarNombreUsuario(
        _usuario.id,
        nombre: datos.nombre,
        apellidos: datos.apellidos,
      ),
      _t.usersNameSaved,
    );
  }

  // ---- vínculos y roles --------------------------------------------------------------------------

  String _etiquetaTipo(String tipo) => switch (tipo) {
    'JUGADOR' => _t.inviteLinkPlayer,
    'FAMILIAR' => _t.inviteLinkFamily,
    'ENTRENADOR' => _t.inviteLinkStaff,
    _ => tipo,
  };

  Future<void> _quitarVinculo(VinculoCuentaModel vinculo) async {
    if (!await _confirmar(
      _t.usersRemoveConfirm(
        vinculo.nombre.isEmpty ? _etiquetaTipo(vinculo.tipo) : vinculo.nombre,
      ),
      _t.usersRemove,
    )) {
      return;
    }

    await _ejecutar(
      () => _servicio.quitarVinculoUsuario(
        _usuario.id,
        tipo: vinculo.tipo,
        personaId: vinculo.personaId,
      ),
      _t.usersLinkRemoved,
    );
  }

  Future<void> _quitarRol(RolCuentaModel rol) async {
    if (!await _confirmar(_t.usersRemoveConfirm(rol.nombre), _t.usersRemove)) {
      return;
    }

    await _ejecutar(
      () => _servicio.quitarVinculoUsuario(_usuario.id, tipo: rol.codigo),
      _t.usersLinkRemoved,
    );
  }

  /// Las personas y los roles que se pueden añadir a esta cuenta (se piden una vez).
  Future<VinculosDisponiblesModel?> _cargarOpciones() async {
    if (_opciones != null) return _opciones;

    try {
      _opciones = await _servicio.obtenerVinculosDisponibles();

      return _opciones;
    } catch (e) {
      if (!mounted) return null;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeDeAdmin(_t, e))));

      return null;
    }
  }

  Future<void> _anadir() async {
    setState(() => _trabajando = true);

    final opciones = await _cargarOpciones();

    if (!mounted) return;

    setState(() => _trabajando = false);

    if (opciones == null) return;

    // Jugador y familiar son uno por cuenta; el cuerpo técnico admite varios equipos.
    final tiene = _usuario.vinculos.map((v) => v.tipo).toSet();
    final tipos = [
      if (!tiene.contains('JUGADOR')) TipoVinculo.jugador,
      if (!tiene.contains('FAMILIAR')) TipoVinculo.familiar,
      TipoVinculo.cuerpoTecnico,
    ];
    final yaTiene = _usuario.roles.map((r) => r.codigo).toSet();
    final roles = opciones.roles
        .where((r) => !yaTiene.contains(r.codigo))
        .toList();

    final elegido = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      builder: (hoja) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  _t.usersAddPersonTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final tipo in tipos)
                ListTile(
                  key: ValueKey('anadir-tipo-${tipo.codigo}'),
                  leading: const Icon(Icons.person_outline),
                  title: Text(_etiquetaTipo(tipo.codigo)),
                  onTap: () => Navigator.pop(hoja, tipo),
                ),
              if (roles.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    _t.usersAddRoleTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                for (final rol in roles)
                  ListTile(
                    key: ValueKey('anadir-rol-${rol.codigo}'),
                    leading: const Icon(Icons.badge_outlined),
                    title: Text(rol.nombre),
                    onTap: () => Navigator.pop(hoja, rol),
                  ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (!mounted || elegido == null) return;

    if (elegido is RolDisponibleModel) {
      await _ejecutar(
        () => _servicio.anadirRolUsuario(_usuario.id, elegido.codigo),
        _t.usersLinkAdded,
      );

      return;
    }

    if (elegido is TipoVinculo) {
      final persona = await _elegirPersona(elegido, opciones.de(elegido));

      if (persona == null || !mounted) return;

      await _ejecutar(
        () => _servicio.anadirVinculoUsuario(_usuario.id, persona),
        _t.usersLinkAdded,
      );
    }
  }

  /// El selector de personas de un tipo, con buscador.
  Future<PersonaDisponibleModel?> _elegirPersona(
    TipoVinculo tipo,
    List<PersonaDisponibleModel> personas,
  ) {
    return showModalBottomSheet<PersonaDisponibleModel>(
      context: context,
      isScrollControlled: true,
      builder: (hoja) => _SelectorPersona(
        titulo: _etiquetaTipo(tipo.codigo),
        personas: personas,
      ),
    );
  }

  // ---- pantalla ----------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final u = _usuario;

    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.usersDetailTitle)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _construirCabecera(u),
              if (!_puedeGestionar) ...[
                const SizedBox(height: 12),
                Container(
                  key: const ValueKey('solo-lectura'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _esPropia
                              ? _t.usersReadOnlyOwn
                              : _t.usersReadOnlyAdmin,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _construirVinculos(u),
              if (_puedeGestionar) ...[
                const SizedBox(height: 16),
                ..._construirAcciones(u),
              ],
            ],
          ),
          if (_trabajando)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirCabecera(UsuarioAdminModel u) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    u.nombreVisible,
                    key: const ValueKey('ficha-nombre'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InsigniaEstadoCuenta(estado: u.estado),
              ],
            ),
            if (u.nombreVisible != u.email)
              Text(u.email, style: TextStyle(color: _colors.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(
              u.ultimoAcceso == null
                  ? _t.usersNeverAccessed
                  : _t.usersLastAccess(fechaHoraCorta(u.ultimoAcceso!)),
              style: TextStyle(fontSize: 12, color: _colors.onSurfaceVariant),
            ),
            if (_puedeGestionar && !u.tieneFicha)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('editar-nombre-boton'),
                  onPressed: _trabajando ? null : _editarNombre,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(_t.usersEditName),
                ),
              ),
            if (u.tieneFicha)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _t.usersNameFromProfile,
                  style: TextStyle(
                    fontSize: 12,
                    color: _colors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirVinculos(UsuarioAdminModel u) {
    final roles = u.rolesSinPersona;
    final admin = u.roles.where((r) => r.esAdmin).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t.usersLinksTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        if (u.vinculos.isEmpty && roles.isEmpty && admin.isEmpty)
          Text(
            _t.usersNoLinks,
            key: const ValueKey('sin-vinculos'),
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
        for (final v in u.vinculos)
          _filaVinculo(
            clave: 'vinculo-${v.tipo}-${v.personaId}',
            titulo: v.nombre.isEmpty ? _etiquetaTipo(v.tipo) : v.nombre,
            subtitulo: [
              _etiquetaTipo(v.tipo),
              if (v.detalle.isNotEmpty) v.detalle,
            ].join(' · '),
            alQuitar: _puedeGestionar ? () => _quitarVinculo(v) : null,
          ),
        for (final r in admin)
          _filaVinculo(
            clave: 'rol-${r.codigo}',
            titulo: r.nombre,
            subtitulo: null,
            alQuitar: null,
          ),
        for (final r in roles)
          _filaVinculo(
            clave: 'rol-${r.codigo}',
            titulo: r.nombre,
            subtitulo: null,
            alQuitar: _puedeGestionar ? () => _quitarRol(r) : null,
          ),
        if (_puedeGestionar)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('anadir-vinculo'),
              onPressed: _trabajando ? null : _anadir,
              icon: const Icon(Icons.add),
              label: Text(_t.usersAddLink),
            ),
          ),
      ],
    );
  }

  Widget _filaVinculo({
    required String clave,
    required String titulo,
    required String? subtitulo,
    required VoidCallback? alQuitar,
  }) {
    return Card(
      key: ValueKey(clave),
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        title: Text(titulo),
        subtitle: subtitulo == null ? null : Text(subtitulo),
        trailing: alQuitar == null
            ? null
            : IconButton(
                key: ValueKey('quitar-$clave'),
                tooltip: _t.usersRemove,
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _trabajando ? null : alQuitar,
              ),
      ),
    );
  }

  List<Widget> _construirAcciones(UsuarioAdminModel u) {
    return [
      if (!u.activa) ...[
        OutlinedButton.icon(
          key: const ValueKey('reenviar'),
          onPressed: _trabajando ? null : _reenviar,
          icon: const Icon(Icons.forward_to_inbox_outlined),
          label: Text(_t.pendingAccountsResend),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const ValueKey('activar'),
          onPressed: _trabajando ? null : _activar,
          icon: const Icon(Icons.check_circle_outline),
          label: Text(_t.usersActivate),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const ValueKey('eliminar'),
          onPressed: _trabajando ? null : _eliminar,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
          ),
          icon: const Icon(Icons.delete_outline),
          label: Text(_t.usersDelete),
        ),
      ] else
        OutlinedButton.icon(
          key: const ValueKey('desactivar'),
          onPressed: _trabajando ? null : _desactivar,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
          ),
          icon: const Icon(Icons.block_outlined),
          label: Text(_t.usersDeactivate),
        ),
    ];
  }
}

/// El diálogo para cambiar el nombre y los apellidos de una cuenta sin ficha. Los controladores son suyos: se liberan
/// cuando el diálogo termina de cerrarse.
class _DialogoNombre extends StatefulWidget {
  final String nombreInicial;

  const _DialogoNombre({required this.nombreInicial});

  @override
  State<_DialogoNombre> createState() => _DialogoNombreState();
}

class _DialogoNombreState extends State<_DialogoNombre> {
  late final TextEditingController _nombre = TextEditingController(
    text: widget.nombreInicial,
  );
  final TextEditingController _apellidos = TextEditingController();

  @override
  void dispose() {
    _nombre.dispose();
    _apellidos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(t.usersEditName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('editar-nombre'),
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: t.usersName),
            ),
            TextField(
              key: const ValueKey('editar-apellidos'),
              controller: _apellidos,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: t.usersSurname),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          key: const ValueKey('guardar-nombre'),
          onPressed: () => Navigator.pop(context, (
            nombre: _nombre.text,
            apellidos: _apellidos.text,
          )),
          child: Text(t.usersSave),
        ),
      ],
    );
  }
}

/// La hoja para elegir una persona de un tipo, con buscador por nombre.
class _SelectorPersona extends StatefulWidget {
  final String titulo;
  final List<PersonaDisponibleModel> personas;

  const _SelectorPersona({required this.titulo, required this.personas});

  @override
  State<_SelectorPersona> createState() => _SelectorPersonaState();
}

class _SelectorPersonaState extends State<_SelectorPersona> {
  final TextEditingController _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = textoParaBuscar(_busqueda.text);
    final visibles = widget.personas
        .where(
          (p) => texto.isEmpty || textoParaBuscar(p.nombre).contains(texto),
        )
        .toList();
    final altoTeclado = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: altoTeclado),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  key: const ValueKey('buscar-persona'),
                  controller: _busqueda,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: t.usersChoosePerson,
                    hintText: t.inviteSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: visibles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            t.usersNoPeople,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView(
                        children: [
                          for (final p in visibles)
                            ListTile(
                              key: ValueKey('persona-${p.tipo.codigo}-${p.id}'),
                              title: Text(p.nombre),
                              subtitle: p.detalle.isEmpty
                                  ? null
                                  : Text(p.detalle),
                              onTap: () => Navigator.pop(context, p),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
