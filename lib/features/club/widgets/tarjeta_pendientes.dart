import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/pendientes.dart';

/// El icono de cada grupo de "Pendientes".
IconData iconoDeGrupoPendiente(String codigo) => switch (codigo) {
  GrupoPendiente.listasSinPasar => Icons.fact_check_outlined,
  GrupoPendiente.convocatoriasSinPublicar => Icons.campaign_outlined,
  GrupoPendiente.resultadosPendientes => Icons.scoreboard_outlined,
  GrupoPendiente.solicitudesFamilia => Icons.family_restroom_outlined,
  GrupoPendiente.jugadoresALiberar ||
  GrupoPendiente.invitacionesPorAprobar ||
  GrupoPendiente.invitacionesSinLiberar => Icons.group_add_outlined,
  GrupoPendiente.moderacion => Icons.shield_outlined,
  GrupoPendiente.usuariosCaducadas => Icons.manage_accounts_outlined,
  GrupoPendiente.imagenesPrevia ||
  GrupoPendiente.imagenesResultados => Icons.photo_library_outlined,
  _ => Icons.pending_actions_outlined,
};

/// La tarjeta "Pendientes" arriba del Área Club: una fila por grupo (icono, título y contador) que se despliega con sus
/// elementos (como mucho 5) y "Ver todos". Sin grupos, una línea discreta "Todo al día ✓".
class TarjetaPendientes extends StatefulWidget {
  final List<GrupoPendiente> grupos;
  final void Function(ElementoPendiente elemento) onAbrirElemento;
  final void Function(GrupoPendiente grupo) onVerTodos;

  const TarjetaPendientes({
    super.key,
    required this.grupos,
    required this.onAbrirElemento,
    required this.onVerTodos,
  });

  @override
  State<TarjetaPendientes> createState() => _TarjetaPendientesState();
}

class _TarjetaPendientesState extends State<TarjetaPendientes> {
  /// Los grupos desplegados (por código), que se conservan al refrescar.
  final Set<String> _abiertos = {};

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Material(
      key: const ValueKey('tarjeta-pendientes'),
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 8, 17, 4),
              child: Row(
                children: [
                  Icon(Icons.checklist_rtl, color: colors.primary),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      t.pendingTitle,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.grupos.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 4, 17, 10),
                child: Text(
                  t.pendingAllDone,
                  key: const ValueKey('pendientes-al-dia'),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              )
            else
              for (final grupo in widget.grupos) _grupo(context, grupo),
          ],
        ),
      ),
    );
  }

  Widget _grupo(BuildContext context, GrupoPendiente grupo) {
    final t = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final abierto = _abiertos.contains(grupo.codigo);

    return Column(
      key: ValueKey('grupo-pendiente-${grupo.codigo}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: ValueKey('abrir-grupo-${grupo.codigo}'),
          onTap: () => setState(() {
            if (!_abiertos.remove(grupo.codigo)) _abiertos.add(grupo.codigo);
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
            child: Row(
              children: [
                Icon(
                  iconoDeGrupoPendiente(grupo.codigo),
                  size: 22,
                  color: colors.primary,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    grupo.titulo,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                _contador(grupo),

                const SizedBox(width: 6),

                Icon(
                  abierto ? Icons.expand_less : Icons.expand_more,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        if (abierto) ...[
          for (final elemento in grupo.elementos)
            InkWell(
              key: ValueKey(
                'elemento-pendiente-${grupo.codigo}-${elemento.id}',
              ),
              onTap: () => widget.onAbrirElemento(elemento),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(51, 8, 17, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        elemento.texto,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 13.5,
                        ),
                      ),
                    ),

                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 9),
              child: TextButton(
                key: ValueKey('ver-todos-${grupo.codigo}'),
                onPressed: () => widget.onVerTodos(grupo),
                child: Text(t.pendingSeeAll),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _contador(GrupoPendiente grupo) {
    return Container(
      key: ValueKey('contador-${grupo.codigo}'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      constraints: const BoxConstraints(minWidth: 22, minHeight: 20),
      decoration: BoxDecoration(
        color: AppColors.dorado,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        grupo.cantidad > 99 ? '99+' : '${grupo.cantidad}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
