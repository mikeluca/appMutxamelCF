import 'package:flutter/material.dart';

class ClubAppBarTitle extends StatelessWidget {
  final String titulo;

  const ClubAppBarTitle({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/escudo.png',
          width: 28,
          height: 36,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(titulo, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
