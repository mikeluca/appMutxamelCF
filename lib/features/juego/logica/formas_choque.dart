import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

/// Un círculo de choque.
class CirculoChoque {
  const CirculoChoque(this.cx, this.cy, this.r);

  final double cx;
  final double cy;
  final double r;

  Offset get centro => Offset(cx, cy);

  /// El mismo círculo girado [angulo] radianes (sentido de las agujas del reloj, con el eje Y hacia abajo) alrededor
  /// del punto ([px], [py]).
  CirculoChoque girado(double angulo, double px, double py) {
    final c = math.cos(angulo);
    final s = math.sin(angulo);
    final dx = cx - px;
    final dy = cy - py;

    return CirculoChoque(px + dx * c - dy * s, py + dx * s + dy * c, r);
  }

  /// Distancia de borde a borde con [otro] (negativa si se solapan).
  double distanciaA(CirculoChoque otro) =>
      math.sqrt(math.pow(cx - otro.cx, 2) + math.pow(cy - otro.cy, 2)) -
      r -
      otro.r;
}

/// Un rectángulo con las esquinas redondeadas.
class RectRedondeadoChoque {
  const RectRedondeadoChoque(this.rect, this.radio);

  final Rect rect;
  final double radio;

  /// Distancia exacta de un círculo a este rectángulo redondeado, de borde a borde (negativa si se solapan).
  ///
  /// Un rectángulo redondeado es el rectángulo interior (el recortado [radio] por cada lado) engordado [radio]: la
  /// distancia es la del centro del círculo a ese rectángulo interior, menos [radio] y menos el radio del círculo.
  double distanciaA(CirculoChoque c) {
    final interior = rect.deflate(radio);
    final dx = math.max(math.max(interior.left - c.cx, 0.0), c.cx - interior.right);
    final dy = math.max(math.max(interior.top - c.cy, 0.0), c.cy - interior.bottom);

    return math.sqrt(dx * dx + dy * dy) - radio - c.r;
  }
}

/// La forma de choque de un defensa: un círculo por la cabeza y un rectángulo redondeado por el cuerpo.
class FormaDefensa {
  const FormaDefensa(this.rect, this.cabeza, this.cuerpo);

  /// El recuadro donde se dibuja la silueta.
  final Rect rect;
  final CirculoChoque cabeza;
  final RectRedondeadoChoque cuerpo;

  /// Las proporciones de la silueta dentro de su recuadro (las mismas que usa el dibujo): la cabeza es un círculo de
  /// 0,15 del ancho centrado en (0,5; 0,16 del alto) y el cuerpo, de la camiseta a las botas, ocupa del 20 al 80 % del
  /// ancho y del 26 al 94 % del alto, con esquinas de 0,10 del ancho.
  static const double cabezaRadioAncho = 0.15;
  static const double cabezaCentroAlto = 0.16;
  static const double cuerpoIzquierda = 0.20;
  static const double cuerpoDerecha = 0.80;
  static const double cuerpoArriba = 0.26;
  static const double cuerpoAbajo = 0.94;
  static const double cuerpoEsquinaAncho = 0.10;

  factory FormaDefensa.de(Rect rect) {
    final w = rect.width;
    final h = rect.height;

    return FormaDefensa(
      rect,
      CirculoChoque(
        rect.left + w * 0.5,
        rect.top + h * cabezaCentroAlto,
        w * cabezaRadioAncho,
      ),
      RectRedondeadoChoque(
        Rect.fromLTRB(
          rect.left + w * cuerpoIzquierda,
          rect.top + h * cuerpoArriba,
          rect.left + w * cuerpoDerecha,
          rect.top + h * cuerpoAbajo,
        ),
        w * cuerpoEsquinaAncho,
      ),
    );
  }

  /// Distancia de un círculo a esta figura (la menor a la cabeza y al cuerpo).
  double distanciaA(CirculoChoque c) =>
      math.min(cabeza.distanciaA(c), cuerpo.distanciaA(c));
}
