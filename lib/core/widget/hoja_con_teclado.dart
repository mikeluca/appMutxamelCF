import 'package:material_ui/material_ui.dart';

/// Cuerpo de una hoja inferior con teclado: el contenido se desplaza y el botón de [pie] (Enviar) queda fijo abajo,
/// fuera de la lista. La hoja sube con el teclado (relleno con `viewInsets.bottom`; el `isScrollControlled` lo pone
/// quien abre la hoja) y tocar un hueco cierra el teclado, que en iOS no tiene tecla "Hecho" en el numérico.
class HojaConTeclado extends StatelessWidget {
  final List<Widget> children;
  final Widget? pie;
  final double alturaMaxima;

  const HojaConTeclado({
    super.key,
    required this.children,
    this.pie,
    this.alturaMaxima = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    final teclado = MediaQuery.viewInsetsOf(context).bottom;
    final alto = MediaQuery.sizeOf(context).height;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: teclado),
        child: SafeArea(
          // Con el teclado abierto ya no hay barra de gestos debajo.
          bottom: teclado == 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: alto * alturaMaxima),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    children: children,
                  ),
                ),
                if (pie != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                    child: SizedBox(width: double.infinity, child: pie),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
