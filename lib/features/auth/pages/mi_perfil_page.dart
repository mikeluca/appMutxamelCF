import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/app_routes.dart';
import '../models/perfil_app.dart';
import '../services/perfil_service.dart';

class MiPerfilPage extends StatefulWidget {
  const MiPerfilPage({super.key});

  @override
  State<MiPerfilPage> createState() => _MiPerfilPageState();
}

class _MiPerfilPageState extends State<MiPerfilPage> {
  PerfilApp? _perfil;

  bool _cargando = true;
  String? _error;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final perfil = await PerfilService.obtenerPerfil();

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.clubPageMyProfile)),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.azul),
      );
    }

    if (_error != null) {
      return _construirError();
    }

    if (_perfil == null) {
      return Center(child: Text(_t.profileLoadError));
    }

    return RefreshIndicator(
      color: AppColors.azul,
      onRefresh: _cargarPerfil,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _construirCabecera(),
          const SizedBox(height: 20),
          _construirDatosPersonales(),
          const SizedBox(height: 20),
          _construirAjustes(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _construirCabecera() {
    final perfil = _perfil!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: AppColors.blancoCalido,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 46,
              color: AppColors.azulOscuro,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            perfil.nombreCompleto.isEmpty
                ? _t.defaultUser
                : perfil.nombreCompleto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _nombreRolPrincipal(perfil),
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _construirDatosPersonales() {
    final perfil = _perfil!;

    return _construirSeccion(
      titulo: _t.profileSectionMyData,
      icono: Icons.person_outline,
      children: [
        _construirDato(
          icono: Icons.email_outlined,
          titulo: _t.storeEmailLabel,
          valor: perfil.email,
        ),
        if (perfil.telefono != null && perfil.telefono!.trim().isNotEmpty)
          _construirDato(
            icono: Icons.phone_outlined,
            titulo: _t.clubPhone,
            valor: perfil.telefono!,
          ),
        _construirDato(
          icono: Icons.badge_outlined,
          titulo: _t.profileRole,
          valor: _rolesTexto(perfil.roles),
        ),
      ],
    );
  }

  Widget _construirAjustes() {
    return _construirSeccion(
      titulo: _t.profileSectionSettings,
      icono: Icons.settings_outlined,
      children: [
        _construirOpcion(
          icono: Icons.settings_outlined,
          titulo: _t.settingsTitle,
          subtitulo: _t.profileSettingsSubtitle,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.settings);
          },
        ),
      ],
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

  Widget _construirDato({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icono, color: AppColors.azul, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: _colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
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

                _cargarPerfil();
              },
              icon: const Icon(Icons.refresh),
              label: Text(_t.retry),
            ),
          ],
        ),
      ),
    );
  }

  String _nombreRolPrincipal(PerfilApp perfil) {
    if (perfil.roles.contains('FAMILIAR')) {
      return _t.roleFamiliar;
    }

    if (perfil.roles.contains('JUGADOR')) {
      return _t.roleJugador;
    }

    if (perfil.roles.contains('ENTRENADOR')) {
      return _t.roleEntrenador;
    }

    if (perfil.roles.contains('COORDINADOR')) {
      return _t.roleCoordinador;
    }

    if (perfil.roles.contains('RETRANSMISION')) {
      return _t.roleRetransmision;
    }

    if (perfil.roles.contains('ADMIN_APP')) {
      return _t.roleAdministrador;
    }

    if (perfil.roles.contains('SOCIO')) {
      return _t.roleSocio;
    }

    return _t.clubPageDefaultMember;
  }

  String _rolesTexto(List<String> roles) {
    return roles
        .map((rol) {
          switch (rol) {
            case 'FAMILIAR':
              return _t.roleFamiliar;
            case 'JUGADOR':
              return _t.roleJugador;
            case 'ENTRENADOR':
              return _t.roleEntrenador;
            case 'COORDINADOR':
              return _t.roleCoordinador;
            case 'RETRANSMISION':
              return _t.roleRetransmision;
            case 'SOCIO':
              return _t.roleSocio;
            case 'ADMIN_APP':
              return _t.roleAdministrador;
            default:
              return rol;
          }
        })
        .join(', ');
  }
}
