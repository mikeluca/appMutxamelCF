import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../models/comunicacion_model.dart';
import '../models/notificacion_model.dart';
import '../models/perfil_app.dart';
import '../services/comunicacion_service.dart';
import '../services/perfil_service.dart';
import 'comunicacion_detail_page.dart';
import 'comunicacion_form_page.dart';

class ComunicacionesPage extends StatefulWidget {
  const ComunicacionesPage({super.key});

  @override
  State<ComunicacionesPage> createState() => _ComunicacionesPageState();
}

class _ComunicacionesPageState extends State<ComunicacionesPage>
    with SingleTickerProviderStateMixin {
  List<ComunicacionModel> _comunicacionesRecibidas = [];
  List<ComunicacionModel> _comunicacionesEnviadas = [];

  final Map<int, bool> _comunicacionesLeidas = {};

  PerfilApp? _perfil;

  bool _cargando = true;
  String? _error;

  late TabController _tabController;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  bool get _puedeCrear {
    final perfil = _perfil;

    if (perfil == null) {
      return false;
    }

    return perfil.tieneRol('ENTRENADOR') ||
        perfil.tieneRol('COORDINADOR') ||
        perfil.tieneRol('ADMIN_APP') ||
        perfil.tieneRol('JUGADOR') ||
        perfil.tieneRol('FAMILIAR');
  }

  bool get _esCoordinadorOAdmin {
    final perfil = _perfil;

    if (perfil == null) {
      return false;
    }

    return perfil.tieneRol('COORDINADOR') || perfil.tieneRol('ADMIN_APP');
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final perfil = await PerfilService.obtenerPerfil();

      final recibidas = await ComunicacionService.obtenerComunicaciones();

      final enviadas =
          await ComunicacionService.obtenerComunicacionesEnviadas();

      final notificaciones = await ComunicacionService.obtenerNotificaciones();

      final estados = <int, bool>{};

      for (final notificacion in notificaciones) {
        if (notificacion.tipo.toUpperCase() != 'COMUNICACION') {
          continue;
        }

        final referenciaId = notificacion.referenciaId;

        if (referenciaId == null || referenciaId <= 0) {
          continue;
        }

        estados[referenciaId] = notificacion.leida;
      }

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _comunicacionesRecibidas = recibidas;
        _comunicacionesEnviadas = enviadas;

        _comunicacionesLeidas
          ..clear()
          ..addAll(estados);

        _error = null;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _recargar() async {
    try {
      final perfil = await PerfilService.obtenerPerfil();

      final recibidas = await ComunicacionService.obtenerComunicaciones();

      final enviadas =
          await ComunicacionService.obtenerComunicacionesEnviadas();

      final notificaciones = await ComunicacionService.obtenerNotificaciones();

      final estados = <int, bool>{};

      for (final notificacion in notificaciones) {
        if (notificacion.tipo.toUpperCase() != 'COMUNICACION') {
          continue;
        }

        final referenciaId = notificacion.referenciaId;

        if (referenciaId == null || referenciaId <= 0) {
          continue;
        }

        estados[referenciaId] = notificacion.leida;
      }

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _comunicacionesRecibidas = recibidas;
        _comunicacionesEnviadas = enviadas;

        _comunicacionesLeidas
          ..clear()
          ..addAll(estados);

        _error = null;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _nuevaComunicacion() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ComunicacionFormPage()),
    );

    if (resultado == true && mounted) {
      await _recargar();
    }
  }

  Future<void> _abrirComunicacion(
    ComunicacionModel comunicacion, {
    required bool enviada,
  }) async {
    if (!enviada && !(_comunicacionesLeidas[comunicacion.id] ?? false)) {
      try {
        final notificaciones =
            await ComunicacionService.obtenerNotificaciones();

        NotificacionModel? notificacionEncontrada;

        for (final notificacion in notificaciones) {
          if (notificacion.tipo.toUpperCase() == 'COMUNICACION' &&
              notificacion.referenciaId == comunicacion.id &&
              !notificacion.leida) {
            notificacionEncontrada = notificacion;
            break;
          }
        }

        if (notificacionEncontrada != null) {
          await ComunicacionService.marcarNotificacionComoLeida(
            notificacionEncontrada.id,
          );

          if (mounted) {
            setState(() {
              _comunicacionesLeidas[comunicacion.id] = true;
            });
          }
        }
      } catch (_) {
        // No impedimos abrir la comunicación
        // aunque falle el marcado como leída.
      }
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ComunicacionDetallePage(comunicacionId: comunicacion.id),
      ),
    );

    if (!mounted) return;

    await _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: 'Comunicaciones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inbox_outlined), text: 'Recibidas'),
            Tab(icon: Icon(Icons.send_outlined), text: 'Enviadas'),
          ],
        ),
      ),
      floatingActionButton: _puedeCrear
          ? FloatingActionButton.extended(
              onPressed: _nuevaComunicacion,
              icon: const Icon(Icons.add),
              label: const Text('Nueva'),
            )
          : null,
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _construirError();
    }

    return TabBarView(
      controller: _tabController,
      children: [_construirListaRecibidas(), _construirListaEnviadas()],
    );
  }

  Widget _construirListaRecibidas() {
    if (_comunicacionesRecibidas.isEmpty) {
      return _construirVacio(
        titulo: 'No tienes comunicaciones',
        subtitulo: _esCoordinadorOAdmin
            ? 'Aquí aparecerán las comunicaciones del club.'
            : 'Aquí aparecerán las comunicaciones de tus equipos.',
        icono: Icons.inbox_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _recargar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        itemCount: _comunicacionesRecibidas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final comunicacion = _comunicacionesRecibidas[index];

          return _construirComunicacion(comunicacion, enviada: false);
        },
      ),
    );
  }

  Widget _construirListaEnviadas() {
    if (_comunicacionesEnviadas.isEmpty) {
      return _construirVacio(
        titulo: 'No has enviado comunicaciones',
        subtitulo: 'Aquí aparecerán las comunicaciones que hayas enviado.',
        icono: Icons.send_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _recargar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        itemCount: _comunicacionesEnviadas.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final comunicacion = _comunicacionesEnviadas[index];

          return _construirComunicacion(comunicacion, enviada: true);
        },
      ),
    );
  }

  Widget _construirVacio({
    required String titulo,
    required String subtitulo,
    required IconData icono,
  }) {
    return RefreshIndicator(
      onRefresh: _recargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Icon(icono, size: 64, color: _colors.primary),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _construirComunicacion(
    ComunicacionModel comunicacion, {
    required bool enviada,
  }) {
    final leida = enviada
        ? true
        : (_comunicacionesLeidas[comunicacion.id] ?? false);

    final fondo = enviada
        ? _colors.surface
        : leida
        ? _colors.surface
        : _colors.primaryContainer.withValues(alpha: 0.35);

    final colorIcono = enviada
        ? _colors.onSecondaryContainer
        : leida
        ? _colors.onSurfaceVariant
        : _colors.primary;

    final fondoIcono = enviada
        ? _colors.secondaryContainer
        : leida
        ? _colors.surfaceContainerHighest
        : _colors.primaryContainer;

    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirComunicacion(comunicacion, enviada: enviada),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: fondoIcono,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  enviada
                      ? Icons.send_outlined
                      : leida
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                  color: colorIcono,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comunicacion.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _colors.onSurface,
                        fontSize: 16,
                        fontWeight: leida || enviada
                            ? FontWeight.w600
                            : FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _normalizarContenido(comunicacion.contenido),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _colors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: leida || enviada
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Text(
                          _formatearFecha(comunicacion.fechaPublicacion),
                          style: TextStyle(
                            color: _colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),

                        if (!enviada && !leida) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(Icons.chevron_right, color: _colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizarContenido(String contenido) {
    return contenido
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\n');
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return '';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year} · $hora:$minuto';
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: _colors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: _colors.onSurface),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _error = null;
                });

                _cargarDatos();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
