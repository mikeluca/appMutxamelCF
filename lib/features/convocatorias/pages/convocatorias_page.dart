import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../auth/models/perfil_app.dart';
import '../model/convocatoria_model.dart';
import '../services/convocatoria_service.dart';
import 'convocatoria_form_page.dart';

class ConvocatoriasPage extends StatefulWidget {
  final PerfilEquipo equipo;

  const ConvocatoriasPage({super.key, required this.equipo});

  @override
  State<ConvocatoriasPage> createState() => _ConvocatoriasPageState();
}

class _ConvocatoriasPageState extends State<ConvocatoriasPage> {
  final ConvocatoriaService _service = ConvocatoriaService();

  late Future<List<ConvocatoriaModel>> _futureConvocatorias;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futureConvocatorias = _service.obtenerPorEquipo(widget.equipo.id);
  }

  Future<void> _recargar() async {
    setState(_cargar);
    await _futureConvocatorias;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: 'Convocatorias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConvocatoriaFormPage(equipo: widget.equipo),
            ),
          );

          if (resultado == true && mounted) {
            _recargar();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: RefreshIndicator(
        onRefresh: _recargar,
        child: FutureBuilder<List<ConvocatoriaModel>>(
          future: _futureConvocatorias,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _construirError(snapshot.error);
            }

            final convocatorias = snapshot.data ?? [];

            if (convocatorias.isEmpty) {
              return _construirVacio();
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: convocatorias.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _construirTarjeta(convocatorias[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _construirTarjeta(ConvocatoriaModel convocatoria) {
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
              builder: (_) => ConvocatoriaFormPage(
                equipo: widget.equipo,
                convocatoria: convocatoria,
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
                  color: _colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.sports_soccer,
                  color: _colors.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      convocatoria.rival,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatearFecha(convocatoria.fechaPartido),
                      style: TextStyle(
                        color: _colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${convocatoria.horaPartido} · '
                      '${convocatoria.campo}',
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
        Icon(Icons.sports_soccer_outlined, size: 64, color: _colors.primary),
        const SizedBox(height: 20),
        Text(
          'Todavía no hay convocatorias.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Crea la primera pulsando el botón Nueva.',
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
              'No se han podido cargar las convocatorias.',
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
