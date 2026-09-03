import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../teams/services/team_services.dart';
import '../models/perfil_app.dart';
import '../services/perfil_service.dart';

class MisEquiposPage extends StatefulWidget {
  const MisEquiposPage({super.key});

  @override
  State<MisEquiposPage> createState() => _MisEquiposPageState();
}

class _MisEquiposPageState extends State<MisEquiposPage> {
  PerfilApp? _perfil;
  bool _cargando = true;
  String? _error;

  ColorScheme get _colors => Theme.of(context).colorScheme;

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
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis equipos')),
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

    final equipos = _perfil?.equipos ?? [];

    if (equipos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarPerfil,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: 80),
            Icon(Icons.groups_outlined, size: 64, color: _colors.primary),
            SizedBox(height: 20),
            Center(
              child: Text(
                'No tienes equipos asociados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPerfil,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        itemCount: equipos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          return _construirTarjetaEquipo(equipos[index]);
        },
      ),
    );
  }

  Widget _construirTarjetaEquipo(PerfilEquipo equipo) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.azulOscuro,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.groups,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    equipo.nombre,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),
            FutureBuilder(
              future: TeamService().obtenerJugadores(equipo.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      const Icon(
                        Icons.groups_outlined,
                        size: 20,
                        color: AppColors.azul,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Número de jugadores: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  return Row(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 20,
                        color: AppColors.azul,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Número de jugadores: -',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _colors.onSurface,
                        ),
                      ),
                    ],
                  );
                }

                final jugadores = snapshot.data ?? [];

                return _datoEquipo(
                  Icons.groups_outlined,
                  'Número de jugadores',
                  jugadores.length.toString(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _datoEquipo(IconData icono, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icono, size: 20, color: AppColors.azul),
          const SizedBox(width: 10),
          Text(
            '$titulo: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _colors.onSurface,
            ),
          ),
          Expanded(
            child: Text(valor, style: TextStyle(color: _colors.onSurface)),
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
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'No se han podido cargar tus equipos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _error = null;
                });

                _cargarPerfil();
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
