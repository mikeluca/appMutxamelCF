import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../theme/app_colors.dart';

/// El contenido de la pantalla previa al permiso de notificaciones: escudo, título, tres ventajas y los botones
/// "Activar notificaciones" y "Ahora no". Con [conInterruptores] (la bienvenida) lleva además los de "Resultados" y
/// "Noticias". Se desplaza si la letra es grande; los botones quedan siempre visibles abajo.
class ContenidoAvisos extends StatelessWidget {
  final VoidCallback onActivar;
  final VoidCallback onAhoraNo;

  /// Si es true, se pintan los interruptores (para quien no tiene sesión).
  final bool conInterruptores;
  final bool resultados;
  final bool noticias;
  final ValueChanged<bool>? onResultados;
  final ValueChanged<bool>? onNoticias;

  const ContenidoAvisos({
    super.key,
    required this.onActivar,
    required this.onAhoraNo,
    this.conInterruptores = false,
    this.resultados = true,
    this.noticias = true,
    this.onResultados,
    this.onNoticias,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colores = Theme.of(context).colorScheme;

    Widget ventaja(IconData icono, String texto) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.azul.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: AppColors.azul),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colores.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
                      t.notifPromptTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colores.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ventaja(
                      Icons.sports_soccer_outlined,
                      t.notifPromptBenefitGoals,
                    ),
                    ventaja(
                      Icons.event_available_outlined,
                      t.notifPromptBenefitCallups,
                    ),
                    ventaja(Icons.campaign_outlined, t.notifPromptBenefitNews),
                    if (conInterruptores) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        key: const ValueKey('bienvenida-resultados'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.welcomeSwitchResults),
                        value: resultados,
                        onChanged: onResultados,
                      ),
                      SwitchListTile(
                        key: const ValueKey('bienvenida-noticias'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.welcomeSwitchNews),
                        value: noticias,
                        onChanged: onNoticias,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('avisos-activar'),
                      onPressed: onActivar,
                      child: Text(t.notifPromptEnable),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      key: const ValueKey('avisos-ahora-no'),
                      onPressed: onAhoraNo,
                      child: Text(t.notifPromptNotNow),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La pantalla previa al permiso de notificaciones, a pantalla completa: devuelve true con "Activar notificaciones"
/// (quien la abre lanza entonces la petición del sistema) y false con "Ahora no".
class PantallaAvisos extends StatelessWidget {
  const PantallaAvisos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContenidoAvisos(
          onActivar: () => Navigator.of(context).pop(true),
          onAhoraNo: () => Navigator.of(context).pop(false),
        ),
      ),
    );
  }
}
