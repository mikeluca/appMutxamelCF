import 'package:flutter/material.dart';
import 'entrenamiento_form_page.dart';

import '../../../core/utils/backend_date.dart';
import '../../auth/models/perfil_app.dart';
import '../model/entrenamiento_model.dart';
import '../services/entrenamiento_service.dart';
import '../widgets/entrenamiento_card.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Todos los entrenamientos anteriores a hoy del equipo, del más cercano al
/// más lejano, para consultar y modificar su asistencia.
class EntrenamientosPasadosPage extends StatefulWidget {
  final PerfilEquipo equipo;

  const EntrenamientosPasadosPage({super.key, required this.equipo});

  @override
  State<EntrenamientosPasadosPage> createState() =>
      _EntrenamientosPasadosPageState();
}

class _EntrenamientosPasadosPageState extends State<EntrenamientosPasadosPage> {
  final EntrenamientoService _service = EntrenamientoService();

  late Future<List<EntrenamientoModel>> _futureEntrenamientos;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    final ahora = DateTime.now();
    final ayer = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    ).subtract(const Duration(days: 1));

    _futureEntrenamientos = _service
        .obtenerPorEquipo(widget.equipo.id, hasta: ayer)
        .then(_ordenarDelMasRecienteAlMasAntiguo);
  }

  List<EntrenamientoModel> _ordenarDelMasRecienteAlMasAntiguo(
    List<EntrenamientoModel> entrenamientos,
  ) {
    final ordenados = [...entrenamientos];

    ordenados.sort((a, b) {
      final fechaA = parseFechaTextoBackend(a.fecha);
      final fechaB = parseFechaTextoBackend(b.fecha);

      if (fechaA == null || fechaB == null) return 0;

      return fechaB.compareTo(fechaA);
    });

    return ordenados;
  }

  Future<void> _recargar() async {
    setState(_cargar);
    await _futureEntrenamientos;
  }

  Future<void> _abrir(EntrenamientoModel entrenamiento) async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.pastTrainingsTitle)),
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              itemCount: entrenamientos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => EntrenamientoCard(
                entrenamiento: entrenamientos[index],
                onTap: () => _abrir(entrenamientos[index]),
              ),
            );
          },
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
        Icon(Icons.history, size: 64, color: _colors.primary),
        const SizedBox(height: 20),
        Text(
          _t.noPastTrainings,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _colors.onSurface,
          ),
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
              _t.trainingsLoadError,
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
              onPressed: () => setState(_cargar),
              icon: const Icon(Icons.refresh),
              label: Text(_t.retry),
            ),
          ],
        ),
      ),
    );
  }
}
