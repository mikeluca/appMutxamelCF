import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../models/comunicacion_model.dart';
import '../services/comunicacion_service.dart';

class ComunicacionDetallePage extends StatefulWidget {
  final int comunicacionId;

  const ComunicacionDetallePage({super.key, required this.comunicacionId});

  @override
  State<ComunicacionDetallePage> createState() =>
      _ComunicacionDetallePageState();
}

class _ComunicacionDetallePageState extends State<ComunicacionDetallePage> {
  ComunicacionModel? _comunicacion;

  bool _cargando = true;
  String? _error;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _cargarComunicacion();
  }

  Future<void> _cargarComunicacion() async {
    try {
      final comunicacion = await ComunicacionService.obtenerComunicacionPorId(
        widget.comunicacionId,
      );

      if (!mounted) return;

      setState(() {
        _comunicacion = comunicacion;
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
      appBar: AppBar(title: ClubAppBarTitle(titulo: 'Comunicación')),
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

    if (_comunicacion == null) {
      return const Center(
        child: Text('No se ha podido cargar la comunicación.'),
      );
    }

    final comunicacion = _comunicacion!;

    return RefreshIndicator(
      color: AppColors.azul,
      onRefresh: _cargarComunicacion,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _construirCabecera(comunicacion),

          const SizedBox(height: 20),

          _construirContenidoPrincipal(comunicacion),
        ],
      ),
    );
  }

  Widget _construirCabecera(ComunicacionModel comunicacion) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: AppColors.blancoCalido,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications,
              color: AppColors.azulOscuro,
              size: 26,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comunicacion.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _formatearFecha(comunicacion.fechaPublicacion),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirContenidoPrincipal(ComunicacionModel comunicacion) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        comunicacion.contenido
            .replaceAll(r'\r\n', '\n')
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\r', '\n'),
        style: TextStyle(color: _colors.onSurface, fontSize: 16, height: 1.5),
      ),
    );
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

                _cargarComunicacion();
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
