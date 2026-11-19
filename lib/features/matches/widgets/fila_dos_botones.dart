import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Dos botones que ocupan todo el ancho disponible: el primero a la izquierda y el segundo pegado a la derecha en la
/// misma fila. Si no caben juntos (pantalla pequeña o letra grande), el segundo baja debajo del primero, también
/// alineado a la derecha, sin cortarse.
class FilaDosBotones extends MultiChildRenderObjectWidget {
  FilaDosBotones({
    super.key,
    required Widget izquierda,
    required Widget derecha,
  }) : super(children: [izquierda, derecha]);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFila();
}

class _FilaParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderFila extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FilaParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FilaParentData> {
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FilaParentData) {
      child.parentData = _FilaParentData();
    }
  }

  RenderBox get _a => firstChild!;
  RenderBox get _b => childAfter(_a)!;

  /// Calcula el tamaño y, si [conPosiciones], coloca los hijos.
  Size _distribuir(BoxConstraints constraints, {required bool conPosiciones}) {
    final tope = constraints.hasBoundedWidth ? constraints.maxWidth : null;
    final suelto = BoxConstraints(maxWidth: tope ?? double.infinity);

    final Size a;
    final Size b;

    if (conPosiciones) {
      _a.layout(suelto, parentUsesSize: true);
      _b.layout(suelto, parentUsesSize: true);
      a = _a.size;
      b = _b.size;
    } else {
      a = _a.getDryLayout(suelto);
      b = _b.getDryLayout(suelto);
    }

    final juntos = tope == null || a.width + b.width <= tope;
    final ancho = tope ?? a.width + b.width;

    if (juntos) {
      final alto = a.height > b.height ? a.height : b.height;

      if (conPosiciones) {
        (_a.parentData! as _FilaParentData).offset = Offset(
          0,
          (alto - a.height) / 2,
        );
        (_b.parentData! as _FilaParentData).offset = Offset(
          ancho - b.width,
          (alto - b.height) / 2,
        );
      }

      return constraints.constrain(Size(ancho, alto));
    }

    if (conPosiciones) {
      (_a.parentData! as _FilaParentData).offset = Offset.zero;
      (_b.parentData! as _FilaParentData).offset = Offset(
        ancho - b.width,
        a.height,
      );
    }

    return constraints.constrain(Size(ancho, a.height + b.height));
  }

  @override
  void performLayout() {
    size = _distribuir(constraints, conPosiciones: true);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _distribuir(constraints, conPosiciones: false);

  @override
  double computeMinIntrinsicWidth(double height) =>
      _a.getMinIntrinsicWidth(height) > _b.getMinIntrinsicWidth(height)
      ? _a.getMinIntrinsicWidth(height)
      : _b.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _a.getMaxIntrinsicWidth(height) + _b.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _a.getMinIntrinsicHeight(width) > _b.getMinIntrinsicHeight(width)
      ? _a.getMinIntrinsicHeight(width)
      : _b.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _a.getMaxIntrinsicHeight(width) + _b.getMaxIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
