import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../models/preferencias_notificacion_model.dart';
import '../services/preferencias_notificacion_service.dart';

class AjustesPage extends StatefulWidget {
  final String temaActual;
  final ValueChanged<String> onTemaChanged;

  const AjustesPage({
    super.key,
    required this.temaActual,
    required this.onTemaChanged,
  });

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  PreferenciasNotificacionModel? _preferencias;

  bool _cargandoPreferencias = true;
  bool _guardandoPreferencias = false;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se han podido cargar las preferencias'),
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido guardar la preferencia')),
      );
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
      appBar: AppBar(title: ClubAppBarTitle(titulo: 'Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _construirSeccion(
            titulo: 'Notificaciones',
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
                  titulo: 'Notificaciones',
                  subtitulo: _preferencias!.notificacionesActivadas
                      ? 'Recibir notificaciones del club'
                      : 'No recibir notificaciones',
                  valor: _preferencias!.notificacionesActivadas,
                  onChanged: (valor) {
                    _actualizarPreferencias(notificacionesActivadas: valor);
                  },
                ),

                const SizedBox(height: 10),

                _construirSwitch(
                  icono: Icons.article_outlined,
                  titulo: 'Noticias',
                  subtitulo: 'Recibir avisos sobre nuevas noticias',
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
                  titulo: 'Mensajes',
                  subtitulo: 'Recibir avisos de nuevos mensajes',
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
                  titulo: 'Resultados',
                  subtitulo: 'Recibir avisos sobre resultados',
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
            titulo: 'Aplicación',
            icono: Icons.phone_android_outlined,
            children: [
              _construirOpcionApariencia(),

              const SizedBox(height: 10),

              _construirOpcion(
                icono: Icons.info_outline,
                titulo: 'Acerca de appMTX',
                subtitulo: 'Información de la aplicación',
                onTap: _mostrarAcercaDe,
              ),
            ],
          ),
        ],
      ),
    );
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
                  'Apariencia',
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Elige cómo quieres ver la aplicación',
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
              items: const [
                DropdownMenuItem(value: 'system', child: Text('Automático')),
                DropdownMenuItem(value: 'light', child: Text('Claro')),
                DropdownMenuItem(value: 'dark', child: Text('Oscuro')),
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

  Widget _construirOpcion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
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

              Icon(Icons.chevron_right, color: _colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarAcercaDe() {
    showAboutDialog(
      context: context,
      applicationName: 'appMTX',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Mutxamel Club de Fútbol',
      applicationIcon: Image.asset(
        'assets/images/escudo_icon.png',
        width: 48,
        height: 48,
      ),
    );
  }
}
