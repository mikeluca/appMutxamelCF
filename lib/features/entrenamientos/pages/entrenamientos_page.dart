import 'package:flutter/material.dart';
import 'entrenamiento_form_page.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/models/perfil_app.dart';
import '../model/entrenamiento_model.dart';
import '../services/entrenamiento_service.dart';
import '../../../core/widget/club_app_bar_title.dart';

class EntrenamientosPage extends StatefulWidget {
  final PerfilEquipo equipo;

  const EntrenamientosPage({super.key, required this.equipo});

  @override
  State<EntrenamientosPage> createState() => _EntrenamientosPageState();
}

class _EntrenamientosPageState extends State<EntrenamientosPage> {
  final EntrenamientoService _service = EntrenamientoService();

  late Future<List<EntrenamientoModel>> _futureEntrenamientos;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futureEntrenamientos = _service.obtenerPorEquipo(widget.equipo.id);
  }

  Future<void> _recargar() async {
    setState(_cargar);
    await _futureEntrenamientos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: 'Entrenamientos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EntrenamientoFormPage(equipo: widget.equipo),
            ),
          );

          if (resultado == true && mounted) {
            _recargar();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<EntrenamientoModel>>(
          future: _futureEntrenamientos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _construirError(snapshot.error);
            }

            final entrenamientos = snapshot.data ?? [];

            if (entrenamientos.isEmpty) {
              return _construirVacio();
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: entrenamientos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _construirTarjeta(entrenamientos[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _construirTarjeta(EntrenamientoModel entrenamiento) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EntrenamientoFormPage(
                equipo: widget.equipo,
                entrenamiento: entrenamiento,
              ),
            ),
          );

          if (resultado == true && mounted) {
            _recargar();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.azulOscuro,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fact_check,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatearFecha(entrenamiento.fecha),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${entrenamiento.asistencias.length} jugadores',
                      style: TextStyle(color: _colors.onSurfaceVariant),
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

  Widget _construirVacio() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 90),
        Icon(Icons.fact_check_outlined, size: 64, color: _colors.primary),
        const SizedBox(height: 20),
        Text(
          'Todavía no hay entrenamientos.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Crea el primero pulsando el botón Nuevo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _construirError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'No se han podido cargar los entrenamientos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: _colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(_cargar);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(String fecha) {
    final match = RegExp(r'\[(\d+),\s*(\d+),\s*(\d+)\]').firstMatch(fecha);

    if (match == null) {
      return fecha;
    }

    final ano = int.parse(match.group(1)!);
    final mes = int.parse(match.group(2)!);
    final dia = int.parse(match.group(3)!);

    final date = DateTime(ano, mes, dia);

    const diasSemana = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    final diaSemana = diasSemana[date.weekday - 1];

    return '$diaSemana - '
        '${dia.toString().padLeft(2, '0')}/'
        '${mes.toString().padLeft(2, '0')}/'
        '$ano';
  }
}
