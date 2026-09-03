import 'package:flutter/material.dart';

import '../../../core/config/app_preferences.dart';
import '../../../core/theme/app_colors.dart';

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
  bool _notificacionesActivadas = true;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final notificaciones = await AppPreferences.obtenerNotificaciones();

    if (!mounted) return;

    setState(() {
      _notificacionesActivadas = notificaciones;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _construirSeccion(
            titulo: 'Notificaciones',
            icono: Icons.notifications_none_outlined,
            children: [
              _construirSwitch(
                icono: Icons.notifications_outlined,
                titulo: 'Notificaciones',
                subtitulo: _notificacionesActivadas
                    ? 'Recibir comunicaciones del club'
                    : 'No recibir notificaciones',
                valor: _notificacionesActivadas,
                onChanged: (valor) async {
                  setState(() {
                    _notificacionesActivadas = valor;
                  });

                  await AppPreferences.guardarNotificaciones(valor);
                },
              ),
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
    required ValueChanged<bool> onChanged,
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
                SizedBox(height: 3),
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
