import 'package:material_ui/material_ui.dart';
import 'entrenamiento_form_page.dart';
import 'entrenamientos_pasados_page.dart';

import '../../../core/utils/backend_date.dart';
import '../../auth/models/perfil_app.dart';
import '../model/entrenamiento_model.dart';
import '../services/entrenamiento_service.dart';
import '../widgets/entrenamiento_card.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Entrenamientos del equipo: solo los de las próximas dos semanas, con el
/// próximo destacado. Los anteriores están en [EntrenamientosPasadosPage].
class EntrenamientosPage extends StatefulWidget {
  final PerfilEquipo equipo;

  const EntrenamientosPage({super.key, required this.equipo});

  @override
  State<EntrenamientosPage> createState() => _EntrenamientosPageState();
}

class _EntrenamientosPageState extends State<EntrenamientosPage> {
  static const int _diasVentana = 14;

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
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    _futureEntrenamientos = _service
        .obtenerPorEquipo(
          widget.equipo.id,
          desde: hoy,
          hasta: hoy.add(const Duration(days: _diasVentana)),
        )
        .then(_ordenarDelMasProximoAlMasLejano);
  }

  /// El primero de la lista es el próximo entrenamiento.
  List<EntrenamientoModel> _ordenarDelMasProximoAlMasLejano(
    List<EntrenamientoModel> entrenamientos,
  ) {
    final ordenados = [...entrenamientos];

    ordenados.sort((a, b) {
      final fechaA = parseFechaTextoBackend(a.fecha);
      final fechaB = parseFechaTextoBackend(b.fecha);

      if (fechaA == null || fechaB == null) return 0;

      return fechaA.compareTo(fechaB);
    });

    return ordenados;
  }

  Future<void> _recargar() async {
    setState(_cargar);
    await _futureEntrenamientos;
  }

  Future<void> _abrirFormulario({EntrenamientoModel? entrenamiento}) async {
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

  Future<void> _abrirPasados() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntrenamientosPasadosPage(equipo: widget.equipo),
      ),
    );

    // La asistencia o el alta de un entrenamiento de hoy pueden haber
    // cambiado desde la pantalla de pasados.
    if (mounted) {
      _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.trainingsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: Text(_t.newMasculineButton),
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

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                _construirBotonPasados(),
                const SizedBox(height: 16),
                if (entrenamientos.isEmpty)
                  _construirVacio()
                else
                  for (var i = 0; i < entrenamientos.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    EntrenamientoCard(
                      entrenamiento: entrenamientos[i],
                      destacado: i == 0,
                      onTap: () =>
                          _abrirFormulario(entrenamiento: entrenamientos[i]),
                    ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _construirBotonPasados() {
    return OutlinedButton.icon(
      onPressed: _abrirPasados,
      icon: const Icon(Icons.history),
      label: Text(_t.pastTrainingsButton),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _construirVacio() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.fact_check_outlined, size: 64, color: _colors.primary),
        const SizedBox(height: 20),
        Text(
          _t.noUpcomingTrainings,
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
              onPressed: () {
                setState(_cargar);
              },
              icon: const Icon(Icons.refresh),
              label: Text(_t.retry),
            ),
          ],
        ),
      ),
    );
  }
}
