/// El tiempo de una partida de Parejas tal como se enseña: m:ss,d (minutos, segundos y décimas; las décimas se
/// truncan). 83450 ms → "1:23,4".
String formatearTiempo(int ms) {
  final decimas = (ms < 0 ? 0 : ms) ~/ 100;
  final segundos = (decimas ~/ 10) % 60;

  return '${decimas ~/ 600}:${segundos.toString().padLeft(2, '0')},${decimas % 10}';
}
