import 'package:material_ui/material_ui.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/utils/nombre_rol.dart';
import '../../../core/utils/texto_busqueda.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/services/auth_manager.dart';
import '../models/admin_model.dart';
import '../services/admin_service.dart';
import 'invitar_usuario_page.dart';
import 'usuario_admin_page.dart';

/// Los colores de los estados de una cuenta (los mismos que las insignias del panel web).
Color colorDeEstadoCuenta(EstadoCuenta estado, ColorScheme colores) =>
    switch (estado) {
      EstadoCuenta.activa => const Color(0xFF16A34A),
      EstadoCuenta.pendiente => const Color(0xFFD97706),
      EstadoCuenta.caducada => const Color(0xFFDC2626),
      EstadoCuenta.desactivada => colores.onSurfaceVariant,
    };

String textoDeEstadoCuenta(AppLocalizations t, EstadoCuenta estado) =>
    switch (estado) {
      EstadoCuenta.activa => t.usersStateActive,
      EstadoCuenta.pendiente => t.usersStatePending,
      EstadoCuenta.caducada => t.usersStateExpired,
      EstadoCuenta.desactivada => t.usersStateDisabled,
    };

/// La insignia con el estado de una cuenta.
class InsigniaEstadoCuenta extends StatelessWidget {
  final EstadoCuenta estado;

  const InsigniaEstadoCuenta({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = colorDeEstadoCuenta(estado, Theme.of(context).colorScheme);

    return Container(
      key: ValueKey('estado-${estado.codigo}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        textoDeEstadoCuenta(AppLocalizations.of(context), estado),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

String fechaHoraCorta(DateTime fecha) {
  String dos(int n) => n.toString().padLeft(2, '0');

  final local = fecha.toLocal();

  return '${dos(local.day)}/${dos(local.month)}/${local.year} '
      '${dos(local.hour)}:${dos(local.minute)}';
}

/// Usuarios de la app (solo ADMIN_APP): todas las cuentas, con buscador por nombre o email y filtros de rol y de
/// estado, y la ficha de cada una para editarla. Sustituye a "Cuentas pendientes": con [estadoInicial] se abre ya
/// filtrada (los avisos de cuentas pendientes la abren con Pendiente).
class UsuariosAdminPage extends StatefulWidget {
  final AdminService? servicio;
  final EstadoCuenta? estadoInicial;

  /// Solo para tests: la cuenta que está usando la app (por defecto, la de la sesión).
  final int? usuarioActualId;

  /// Solo para tests: sustituye al formulario de invitar.
  final Widget Function()? constructorInvitar;

  const UsuariosAdminPage({
    super.key,
    this.servicio,
    this.estadoInicial,
    this.usuarioActualId,
    this.constructorInvitar,
  });

  @override
  State<UsuariosAdminPage> createState() => _UsuariosAdminPageState();
}

class _UsuariosAdminPageState extends State<UsuariosAdminPage> {
  static const String _sinRoles = '__SIN_ROLES__';

  /// Los roles conocidos, en el orden de la tabla del panel.
  static const List<String> _rolesConocidos = [
    'JUGADOR',
    'FAMILIAR',
    'ENTRENADOR',
    'COORDINADOR',
    'RETRANSMISION',
    'RRSS',
    'ADMIN_APP',
  ];

  late final AdminService _servicio = widget.servicio ?? AdminService();

  late Future<List<UsuarioAdminModel>> _futuro;
  List<UsuarioAdminModel> _usuarios = const [];

  final TextEditingController _busqueda = TextEditingController();
  String? _rol;
  EstadoCuenta? _estado;

  /// Sube al limpiar los filtros, para que los desplegables vuelvan a "Todos".
  int _versionFiltros = 0;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  int? get _miId =>
      widget.usuarioActualId ?? AuthManager.usuarioActual?.usuarioId;

  @override
  void initState() {
    super.initState();
    _estado = widget.estadoInicial;
    _futuro = _cargar();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<List<UsuarioAdminModel>> _cargar() async {
    final usuarios = await _servicio.obtenerUsuarios();

    _usuarios = usuarios;

    return usuarios;
  }

  /// Vuelve a pedir las cuentas; los filtros elegidos se mantienen.
  Future<void> _recargar() async {
    final nuevo = _cargar();

    setState(() {
      _futuro = nuevo;
    });

    try {
      await nuevo;
    } catch (_) {
      // El error ya se pinta en pantalla.
    }
  }

  bool get _hayFiltros =>
      _busqueda.text.trim().isNotEmpty || _rol != null || _estado != null;

  void _limpiarFiltros() {
    setState(() {
      _busqueda.clear();
      _rol = null;
      _estado = null;
      _versionFiltros++;
    });
  }

  bool _coincide(UsuarioAdminModel u) {
    final texto = textoParaBuscar(_busqueda.text);

    if (texto.isNotEmpty) {
      final dondeBuscar = textoParaBuscar(
        '${u.nombreVisible} ${u.email} '
        '${u.vinculos.map((v) => v.nombre).join(' ')}',
      );

      if (!dondeBuscar.contains(texto)) return false;
    }

    if (_rol == _sinRoles) {
      if (u.roles.isNotEmpty) return false;
    } else if (_rol != null && !u.roles.any((r) => r.codigo == _rol)) {
      return false;
    }

    if (_estado != null && u.estado != _estado) return false;

    return true;
  }

  /// El desplegable de roles: los conocidos (con el nombre que traen las cuentas o el de siempre) y cualquier otro que
  /// aparezca.
  List<RolCuentaModel> _rolesParaFiltrar() {
    final nombres = <String, String>{};

    for (final u in _usuarios) {
      for (final r in u.roles) {
        nombres.putIfAbsent(r.codigo, () => r.nombre);
      }
    }

    final codigos = [
      ..._rolesConocidos,
      ...nombres.keys.where((c) => !_rolesConocidos.contains(c)),
    ];

    return [
      for (final c in codigos)
        RolCuentaModel(codigo: c, nombre: nombres[c] ?? nombreDeRol(_t, c)),
    ];
  }

  Future<void> _abrirFicha(UsuarioAdminModel usuario) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => UsuarioAdminPage(
          usuario: usuario,
          servicio: _servicio,
          usuarioActualId: _miId,
        ),
      ),
    );

    if (!mounted) return;

    await _recargar();
  }

  /// Abre el formulario de invitar; al volver con una invitación avisa y recarga la lista para que aparezca.
  Future<void> _invitar() async {
    final invitacion = await Navigator.push<InvitacionEnviadaModel>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            widget.constructorInvitar?.call() ??
            InvitarUsuarioPage(servicio: _servicio),
      ),
    );

    if (invitacion == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          invitacion.emailEnviado
              ? _t.inviteSent(invitacion.email)
              : _t.inviteCreatedNoEmail(invitacion.email),
        ),
      ),
    );

    await _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.clubPageUsers)),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('invitar-usuario'),
        onPressed: _invitar,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text(_t.inviteButton),
      ),
      body: FutureBuilder<List<UsuarioAdminModel>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _usuarios.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && _usuarios.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 40),
                Text(
                  mensajeDeAdmin(_t, snapshot.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _recargar,
                    icon: const Icon(Icons.refresh),
                    label: Text(_t.retry),
                  ),
                ),
              ],
            );
          }

          final visibles = _usuarios.where(_coincide).toList();

          return Column(
            children: [
              _construirFiltros(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _t.usersCount(visibles.length, _usuarios.length),
                    key: const ValueKey('contador-cuentas'),
                    style: TextStyle(color: _colors.onSurfaceVariant),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _recargar,
                  child: visibles.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(40),
                          children: [
                            Text(
                              _usuarios.isEmpty
                                  ? _t.usersEmpty
                                  : _t.usersNoneMatch,
                              key: const ValueKey('sin-resultados'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _colors.onSurfaceVariant),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                          children: [
                            for (final u in visibles) ...[
                              _construirTarjeta(u),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _construirFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            key: const ValueKey('buscar-usuarios'),
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _t.usersSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          // Rol y estado, uno debajo del otro: con letra grande o un iPhone pequeño no caben en una fila.
          DropdownButtonFormField<String?>(
            key: ValueKey('filtro-rol-$_versionFiltros'),
            isExpanded: true,
            initialValue: _rol,
            decoration: InputDecoration(
              labelText: _t.usersFilterRole,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(_t.usersAllRoles),
              ),
              for (final r in _rolesParaFiltrar())
                DropdownMenuItem<String?>(
                  value: r.codigo,
                  child: Text(r.nombre, overflow: TextOverflow.ellipsis),
                ),
              DropdownMenuItem<String?>(
                value: _sinRoles,
                child: Text(_t.usersNoRoles),
              ),
            ],
            onChanged: (valor) => setState(() => _rol = valor),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<EstadoCuenta?>(
            key: ValueKey('filtro-estado-$_versionFiltros'),
            isExpanded: true,
            initialValue: _estado,
            decoration: InputDecoration(
              labelText: _t.usersFilterState,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              DropdownMenuItem<EstadoCuenta?>(
                value: null,
                child: Text(_t.usersAllStates),
              ),
              for (final e in EstadoCuenta.values)
                DropdownMenuItem<EstadoCuenta?>(
                  value: e,
                  child: Text(
                    textoDeEstadoCuenta(_t, e),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (valor) => setState(() => _estado = valor),
          ),
          if (_hayFiltros)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('limpiar-filtros'),
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: Text(_t.usersClearFilters),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirTarjeta(UsuarioAdminModel u) {
    return Card(
      key: ValueKey('cuenta-${u.id}'),
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _abrirFicha(u),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InsigniaEstadoCuenta(estado: u.estado),
                ],
              ),
              if (u.nombreVisible != u.email)
                Text(
                  u.email,
                  style: TextStyle(color: _colors.onSurfaceVariant),
                ),
              const SizedBox(height: 6),
              if (u.roles.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final r in u.roles)
                      Chip(
                        label: Text(r.nombre),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                )
              else
                Text(
                  _t.usersNoRoles,
                  style: TextStyle(color: _colors.onSurfaceVariant),
                ),
              const SizedBox(height: 6),
              Text(
                u.ultimoAcceso == null
                    ? _t.usersNeverAccessed
                    : _t.usersLastAccess(fechaHoraCorta(u.ultimoAcceso!)),
                style: TextStyle(fontSize: 12, color: _colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
