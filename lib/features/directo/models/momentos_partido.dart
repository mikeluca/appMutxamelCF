import '../../ficha_partido/models/ficha_partido_model.dart';
import '../../ficha_partido/models/reloj_directo.dart';

/// Un hecho del partido colocado en la barra de momentos.
class Momento {
  /// Posición del hecho en la lista de eventos de la ficha.
  final int indice;
  final EventoFicha evento;

  /// Dónde cae en la barra, de 0 (inicio del partido) a 1 (final de la segunda parte).
  final double fraccion;

  /// true en el carril de arriba (el equipo local) y false en el de abajo (el visitante).
  final bool arriba;

  /// Fila dentro del carril: los hechos muy juntos se reparten en dos filas para no taparse.
  final int fila;

  const Momento({
    required this.indice,
    required this.evento,
    required this.fraccion,
    required this.arriba,
    this.fila = 0,
  });
}

/// Coloca los hechos de la ficha (los de [eventos], con lo último primero) en una línea de 0 a 2·[minutosParte].
///
/// * Arriba los del equipo local, abajo los del visitante: los hechos del Mutxamel van con el Mutxamel y el gol y
///   las tarjetas del rival con el rival.
/// * Los minutos de añadido se colocan al final de su parte (nunca se salen de ella): la primera parte acaba en
///   `minutosParte` y la segunda en `2·minutosParte`. La parte de cada hecho sale del separador DESCANSO (lo que
///   hay antes es primera parte); sin separador, del reloj y, si no, de si el minuto pasa de `minutosParte`.
/// * Los separadores y los hechos sin minuto no se colocan.
List<Momento> colocarMomentos(
  List<EventoFicha> eventos, {
  required int minutosParte,
  required bool mutxamelEsLocal,
  FaseReloj? fase,
}) {
  final duracion = minutosParte <= 0 ? 45 : minutosParte;
  final total = duracion * 2;

  final hayDescanso = eventos.any((e) => e.tipo == EventoFicha.descanso);

  final colocados = <Momento>[];

  // Del más antiguo al más reciente: lo anterior al DESCANSO es de la primera parte.
  var segunda = false;

  for (var i = eventos.length - 1; i >= 0; i--) {
    final evento = eventos[i];

    if (evento.tipo == EventoFicha.descanso) {
      segunda = true;
      continue;
    }

    if (evento.esSeparador) continue;

    final minuto = evento.minuto;

    if (minuto == null || minuto < 0) continue;

    final enSegunda = hayDescanso
        ? segunda
        : (fase == FaseReloj.primeraParte ? false : minuto > duracion);

    final posicion = enSegunda
        ? minuto.clamp(duracion, total)
        : minuto.clamp(0, duracion);

    colocados.add(
      Momento(
        indice: i,
        evento: evento,
        fraccion: posicion / total,
        arriba: evento.esNuestro == mutxamelEsLocal,
      ),
    );
  }

  // Los muy juntos del mismo carril se reparten en dos filas.
  final porCarril = <bool, List<Momento>>{true: [], false: []};

  for (final m in colocados) {
    porCarril[m.arriba]!.add(m);
  }

  final resultado = <Momento>[];

  for (final carril in porCarril.values) {
    carril.sort((a, b) => a.fraccion.compareTo(b.fraccion));

    var anterior = -1.0;
    var filaAnterior = 1;

    for (final m in carril) {
      final cerca = anterior >= 0 && (m.fraccion - anterior) < 0.04;
      final fila = cerca ? 1 - filaAnterior : 0;

      resultado.add(
        Momento(
          indice: m.indice,
          evento: m.evento,
          fraccion: m.fraccion,
          arriba: m.arriba,
          fila: fila,
        ),
      );

      anterior = m.fraccion;
      filaAnterior = fila;
    }
  }

  resultado.sort((a, b) => a.indice.compareTo(b.indice));

  return resultado;
}
