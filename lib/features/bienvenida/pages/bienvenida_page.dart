import 'package:material_ui/material_ui.dart';

import '../../../core/config/app_preferences.dart';
import '../../../core/notifications/services/permiso_notificaciones.dart';
import '../../../core/notifications/services/push_notification_service.dart';
import '../../../core/notifications/widgets/pantalla_avisos.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/app_routes.dart';

/// Bienvenida del primer arranque (solo en instalaciones nuevas), en dos pasos: el idioma (cambia la app al momento) y los
/// avisos (la pantalla previa al permiso de notificaciones, con los interruptores "Resultados" y "Noticias" para quien
/// no tiene sesión). "Saltar" está visible en los dos pasos. Al terminar se marca como hecha y se va a la portada.
class BienvenidaPage extends StatefulWidget {
  /// El idioma con el que está ahora la app (el del móvil si es uno de los tres, que ya se fijó al arrancar).
  final String idiomaActual;

  /// Cambia el idioma de toda la app al momento.
  final Future<void> Function(String idioma) onIdiomaChanged;

  /// Solo para tests: aplica los interruptores (los topics anónimos de resultados y noticias).
  final Future<void> Function(bool resultados, bool noticias)? aplicarAvisos;

  /// Solo para tests: lo que se hace al terminar (por defecto, ir a la portada).
  final VoidCallback? alTerminar;

  const BienvenidaPage({
    super.key,
    required this.idiomaActual,
    required this.onIdiomaChanged,
    this.aplicarAvisos,
    this.alTerminar,
  });

  static const int pasos = 2;

  @override
  State<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage> {
  static const List<({String codigo, String nombre})> _idiomas = [
    (codigo: 'es', nombre: 'Castellano'),
    (codigo: 'ca', nombre: 'Valencià'),
    (codigo: 'en', nombre: 'English'),
  ];

  int _paso = 0;
  bool _resultados = true;
  bool _noticias = true;
  bool _ocupado = false;

  AppLocalizations get _t => AppLocalizations.of(context);

  Future<void> _terminar() async {
    await AppPreferences.guardarBienvenidaHecha();

    if (!mounted) return;

    final alTerminar = widget.alTerminar;

    if (alTerminar != null) {
      alTerminar();
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.public);
  }

  Future<void> _siguiente() async {
    setState(() => _paso = 1);

    // Se está ofreciendo la pantalla de avisos: cuenta como la primera oferta.
    await PermisoNotificaciones.registrarOferta();
  }

  Future<void> _activar() async {
    if (_ocupado) return;

    setState(() => _ocupado = true);

    final contexto = context;
    var concedido = false;

    final estado = await PermisoNotificaciones.leerEstado();

    if (estado == EstadoPermisoAvisos.denegado) {
      // El sistema ya no vuelve a preguntar: se explica cómo activarlas.
      if (contexto.mounted) {
        await PermisoNotificaciones.mostrarAvisoDenegado(contexto);
      }
    } else {
      concedido =
          estado == EstadoPermisoAvisos.concedido ||
          await PermisoNotificaciones.pedirYRegistrar();
    }

    if (concedido) {
      await (widget.aplicarAvisos ?? _aplicarAvisos)(_resultados, _noticias);
    }

    await _terminar();
  }

  /// "Ahora no": no se pide el permiso del sistema y los interruptores quedan apagados.
  Future<void> _ahoraNo() async {
    if (_ocupado) return;

    await _terminar();
  }

  static Future<void> _aplicarAvisos(bool resultados, bool noticias) async {
    await PushNotificationService.activarResultadosAnonimos(resultados);
    await AppPreferences.guardarNotifResultados(resultados);

    await PushNotificationService.activarNoticiasAnonimas(noticias);
    await AppPreferences.guardarNotifNoticias(noticias);
  }

  Widget _cabecera() {
    final colores = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 8, 0),
      child: Row(
        children: [
          Row(
            key: const ValueKey('bienvenida-indicador'),
            children: [
              for (var i = 0; i < BienvenidaPage.pasos; i++)
                Container(
                  width: i == _paso ? 22 : 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: i == _paso
                        ? AppColors.azul
                        : colores.onSurface.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _t.welcomeStepOf(_paso + 1, BienvenidaPage.pasos),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: colores.onSurfaceVariant),
            ),
          ),
          const Spacer(),
          TextButton(
            key: const ValueKey('bienvenida-saltar'),
            onPressed: _ocupado ? null : _terminar,
            child: Text(_t.welcomeSkip),
          ),
        ],
      ),
    );
  }

  Widget _pasoIdioma() {
    final colores = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/escudo.png',
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _t.welcomeLanguageTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colores.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _t.welcomeLanguageSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colores.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    for (final idioma in _idiomas)
                      Card(
                        key: ValueKey('bienvenida-idioma-${idioma.codigo}'),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: widget.idiomaActual == idioma.codigo
                                ? AppColors.azul
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            idioma.nombre,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: widget.idiomaActual == idioma.codigo
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.azul,
                                )
                              : const Icon(Icons.circle_outlined),
                          onTap: () => widget.onIdiomaChanged(idioma.codigo),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('bienvenida-continuar'),
                  onPressed: _siguiente,
                  child: Text(_t.welcomeContinue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pasoAvisos() {
    return ContenidoAvisos(
      conInterruptores: true,
      resultados: _resultados,
      noticias: _noticias,
      onResultados: (v) => setState(() => _resultados = v),
      onNoticias: (v) => setState(() => _noticias = v),
      onActivar: _activar,
      onAhoraNo: _ahoraNo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _cabecera(),
            Expanded(child: _paso == 0 ? _pasoIdioma() : _pasoAvisos()),
          ],
        ),
      ),
    );
  }
}
