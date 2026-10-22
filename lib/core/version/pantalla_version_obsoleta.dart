import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';

/// Pantalla bloqueante: la versión instalada es anterior a la mínima que acepta
/// el servidor. No se puede cerrar (ni con el botón atrás): solo se puede ir a
/// la tienda a actualizar.
class PantallaVersionObsoleta extends StatelessWidget {
  final VoidCallback alActualizar;

  const PantallaVersionObsoleta({super.key, required this.alActualizar});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.azul,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/escudo.png',
                    width: 120,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t.versionUpdateRequiredBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    key: const ValueKey('boton-actualizar-version'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.dorado,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: alActualizar,
                    icon: const Icon(Icons.system_update),
                    label: Text(t.versionUpdateButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
