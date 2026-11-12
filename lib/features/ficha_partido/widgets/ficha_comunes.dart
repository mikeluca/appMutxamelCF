import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Escudo de un equipo en la ficha: el del club (el asset de siempre) o, para el rival, un escudo genérico.
class EscudoEquipo extends StatelessWidget {
  final bool mutxamel;
  final double tamano;

  const EscudoEquipo({super.key, required this.mutxamel, this.tamano = 56});

  @override
  Widget build(BuildContext context) {
    if (mutxamel) {
      return Image.asset(
        'assets/images/escudo.png',
        key: const ValueKey('escudo-mutxamel'),
        width: tamano,
        height: tamano,
        fit: BoxFit.contain,
      );
    }

    return SizedBox(
      width: tamano,
      height: tamano,
      child: Icon(
        Icons.shield_outlined,
        key: const ValueKey('escudo-rival'),
        size: tamano * 0.9,
        color: Colors.white70,
      ),
    );
  }
}

/// Rectángulo amarillo o rojo de una tarjeta.
class TarjetaIcono extends StatelessWidget {
  final bool roja;
  final double alto;

  const TarjetaIcono({super.key, required this.roja, this.alto = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(roja ? 'tarjeta-roja' : 'tarjeta-amarilla'),
      width: alto * 0.72,
      height: alto,
      decoration: BoxDecoration(
        color: roja ? const Color(0xFFD62828) : const Color(0xFFF2C500),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Foto en miniatura de un jugador (base64 del backend) o, si no hay (un menor, o sin foto), un avatar neutro.
class FotoJugador extends StatelessWidget {
  final String? fotoBase64;
  final double radio;

  const FotoJugador({super.key, this.fotoBase64, this.radio = 20});

  Uint8List? _bytes() {
    final foto = fotoBase64;

    if (foto == null || foto.isEmpty) return null;

    try {
      return base64Decode(foto);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final avatar = CircleAvatar(
      key: const ValueKey('avatar-jugador'),
      radius: radio,
      backgroundColor: colors.primaryContainer,
      child: Icon(
        Icons.person,
        size: radio * 1.2,
        color: colors.onPrimaryContainer,
      ),
    );

    final bytes = _bytes();

    if (bytes == null) return avatar;

    return CircleAvatar(
      key: const ValueKey('foto-jugador'),
      radius: radio,
      backgroundColor: colors.primaryContainer,
      child: ClipOval(
        child: Image.memory(
          bytes,
          width: radio * 2,
          height: radio * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => avatar,
        ),
      ),
    );
  }
}

/// Texto del marcador "2-1" para una píldora.
String marcadorTexto(int? izquierda, int? derecha) =>
    '${izquierda ?? '-'}-${derecha ?? '-'}';

/// La expulsión por doble amarilla: dos tarjetas amarillas y una roja juntas, en ese orden.
class TarjetasDobleAmarilla extends StatelessWidget {
  final double alto;

  const TarjetasDobleAmarilla({super.key, this.alto = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('tarjetas-doble-amarilla'),
      mainAxisSize: MainAxisSize.min,
      children: [
        TarjetaIcono(roja: false, alto: alto),
        const SizedBox(width: 2),
        TarjetaIcono(roja: false, alto: alto),
        const SizedBox(width: 2),
        TarjetaIcono(roja: true, alto: alto),
      ],
    );
  }
}
