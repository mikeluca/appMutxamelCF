import 'package:app_mutxamel_cf/features/directo/widgets/marcador_que_late.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo que pinta un [MarcadorQueLate] ("2 - 1", con el local a la izquierda), como antes lo pintaba un solo `Text`.
String marcadorEscrito(MarcadorQueLate marcador) {
  final favor = marcador.golesFavor;
  final contra = marcador.golesContra;

  if (favor == null || contra == null) return marcador.vacio;

  return marcador.mutxamelEsLocal ? '$favor - $contra' : '$contra - $favor';
}

/// El marcador pintado con ese texto ("2 - 1").
Finder encuentraMarcador(String texto) => find.byWidgetPredicate(
  (w) => w is MarcadorQueLate && marcadorEscrito(w) == texto,
  description: 'marcador "$texto"',
);

/// El texto de un marcador (o de un `Text`) a partir de su clave.
String textoDe(WidgetTester tester, Finder finder) {
  final w = tester.widget(finder);

  if (w is MarcadorQueLate) return marcadorEscrito(w);
  if (w is Text) return w.data!;

  throw StateError('No es un Text ni un marcador: $w');
}
