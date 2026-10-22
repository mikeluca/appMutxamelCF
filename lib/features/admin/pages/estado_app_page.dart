import 'package:flutter/material.dart';

import '../../../core/utils/mensaje_error.dart';
import '../../../core/utils/nombre_rol.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/pages/chat_privado_page.dart';
import '../models/admin_model.dart';
import '../services/admin_service.dart';

/// Estado de la app (ADMIN_APP): totales de cuentas, quién no recibirá avisos, las versiones
/// instaladas por plataforma (en rojo las inferiores a la mínima) y, al pulsar un total, la
/// lista de cuentas de ese filtro.
class EstadoAppPage extends StatefulWidget {
  final AdminService? servicio;

  /// Solo para tests: sustituye al chat privado real (que pide datos a la red).
  final Widget Function(UsuarioEstadoModel usuario)? constructorChat;

  const EstadoAppPage({super.key, this.servicio, this.constructorChat});

  @override
  State<EstadoAppPage> createState() => _EstadoAppPageState();
}

class _EstadoAppPageState extends State<EstadoAppPage> {
  static const Color _rojo = Color(0xFFDC2626);

  late final AdminService _servicio = widget.servicio ?? AdminService();

  late Future<EstadoAppModel> _futuro;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerEstado();
  }

  Future<void> _recargar() async {
    final nuevo = _servicio.obtenerEstado();

    setState(() => _futuro = nuevo);

    try {
      await nuevo;
    } catch (_) {
      // El error ya se pinta en pantalla.
    }
  }

  String _tituloFiltro(FiltroEstado filtro, EstadoAppModel estado) =>
      switch (filtro) {
        FiltroEstado.sinDispositivo => _t.appStatusNoDevice,
        FiltroEstado.sinNotificaciones => _t.appStatusNoNotifications,
        FiltroEstado.versionAntigua => _t.appStatusOldVersion,
        FiltroEstado.inactivos => _t.appStatusInactive(estado.diasInactividad),
      };

  void _abrirLista(FiltroEstado filtro, EstadoAppModel estado) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _UsuariosEstadoPage(
          filtro: filtro,
          titulo: _tituloFiltro(filtro, estado),
          servicio: _servicio,
          constructorChat: widget.constructorChat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.clubPageAppStatus)),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<EstadoAppModel>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 40),
                  Text(
                    mensajeDeError(_t, snapshot.error),
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

            return _construirContenido(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _construirContenido(EstadoAppModel estado) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _tarjeta(
              clave: 'activas',
              titulo: _t.appStatusActive,
              total: estado.activas,
              color: Colors.green,
            ),
            _tarjeta(
              clave: 'pendientes',
              titulo: _t.appStatusPending,
              total: estado.pendientes,
              color: _colors.primary,
            ),
            _tarjeta(
              clave: 'desactivadas',
              titulo: _t.appStatusDeactivated,
              total: estado.desactivadas,
              color: _colors.onSurfaceVariant,
            ),
            for (final filtro in FiltroEstado.values)
              _tarjeta(
                clave: filtro.codigo,
                titulo: _tituloFiltro(filtro, estado),
                total: estado.total(filtro),
                color: estado.total(filtro) > 0 ? _rojo : Colors.green,
                alPulsar: () => _abrirLista(filtro, estado),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          _t.appStatusVersionsTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _t.appStatusMinimum(
            estado.minimaAndroid.isEmpty ? '-' : estado.minimaAndroid,
            estado.minimaIos.isEmpty ? '-' : estado.minimaIos,
          ),
          style: TextStyle(color: _colors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        _construirTablaVersiones(estado),
      ],
    );
  }

  Widget _tarjeta({
    required String clave,
    required String titulo,
    required int total,
    required Color color,
    VoidCallback? alPulsar,
  }) {
    final ancho = (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2;

    return SizedBox(
      width: ancho,
      child: Card(
        key: ValueKey('tarjeta-$clave'),
        margin: EdgeInsets.zero,
        elevation: 1,
        color: _colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: alPulsar,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total',
                  key: ValueKey('total-$clave'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(titulo, style: const TextStyle(fontSize: 13)),
                if (alPulsar != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: _colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirTablaVersiones(EstadoAppModel estado) {
    if (estado.versiones.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          _t.appStatusNoVersions,
          style: TextStyle(color: _colors.onSurfaceVariant),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const ValueKey('tabla-versiones'),
        columns: [
          DataColumn(label: Text(_t.appStatusPlatform)),
          DataColumn(label: Text(_t.appStatusVersion)),
          DataColumn(label: Text(_t.appStatusDevices), numeric: true),
        ],
        rows: [
          for (final v in estado.versiones)
            DataRow(
              key: ValueKey('version-${v.plataforma}-${v.version}'),
              cells: [
                for (final texto in [v.plataforma, v.version, '${v.dispositivos}'])
                  DataCell(
                    Text(
                      texto,
                      style: v.porDebajoMinima
                          ? const TextStyle(
                              color: _rojo,
                              fontWeight: FontWeight.bold,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Las cuentas de un filtro del estado, cada una con un botón para escribirle por chat privado.
class _UsuariosEstadoPage extends StatefulWidget {
  final FiltroEstado filtro;
  final String titulo;
  final AdminService servicio;
  final Widget Function(UsuarioEstadoModel usuario)? constructorChat;

  const _UsuariosEstadoPage({
    required this.filtro,
    required this.titulo,
    required this.servicio,
    this.constructorChat,
  });

  @override
  State<_UsuariosEstadoPage> createState() => _UsuariosEstadoPageState();
}

class _UsuariosEstadoPageState extends State<_UsuariosEstadoPage> {
  late Future<List<UsuarioEstadoModel>> _futuro;

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _futuro = widget.servicio.obtenerUsuariosEstado(widget.filtro);
  }

  Future<void> _recargar() async {
    final nuevo = widget.servicio.obtenerUsuariosEstado(widget.filtro);

    setState(() => _futuro = nuevo);

    try {
      await nuevo;
    } catch (_) {
      // El error ya se pinta en pantalla.
    }
  }

  void _escribir(UsuarioEstadoModel usuario) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            widget.constructorChat?.call(usuario) ??
            ChatPrivadoPage(
              contraparteId: usuario.id,
              contraparteNombre: usuario.nombre,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: widget.titulo)),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<UsuarioEstadoModel>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 40),
                  Text(
                    mensajeDeError(_t, snapshot.error),
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

            final usuarios = snapshot.data ?? const [];

            if (usuarios.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(40),
                children: [
                  Text(
                    _t.appStatusUsersEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _colors.onSurfaceVariant),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                for (final usuario in usuarios) ...[
                  _construirUsuario(usuario),
                  const SizedBox(height: 10),
                ],
                if (usuarios.length >= 200)
                  Text(
                    _t.appStatusUsersMax,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _colors.onSurfaceVariant,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _construirUsuario(UsuarioEstadoModel u) {
    final acceso = u.ultimoAcceso == null
        ? _t.appStatusNeverAccessed
        : _t.appStatusLastAccess(_fecha(u.ultimoAcceso!));

    return Card(
      key: ValueKey('usuario-${u.id}'),
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    u.email,
                    style: TextStyle(color: _colors.onSurfaceVariant),
                  ),
                  if (u.roles.isNotEmpty)
                    Text(u.roles.map((r) => nombreDeRol(_t, r)).join(', ')),
                  Text(
                    acceso,
                    style: TextStyle(
                      fontSize: 12,
                      color: _colors.onSurfaceVariant,
                    ),
                  ),
                  if (u.versiones.isNotEmpty)
                    Text(
                      u.versiones.join(', '),
                      style: TextStyle(
                        fontSize: 12,
                        color: _colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey('escribir-${u.id}'),
              tooltip: _t.appStatusWriteTooltip,
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => _escribir(u),
            ),
          ],
        ),
      ),
    );
  }

  static String _fecha(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }
}
