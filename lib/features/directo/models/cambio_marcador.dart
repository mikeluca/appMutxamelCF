/// Qué ha cambiado en el marcador de un partido entre lo que ya se veía y lo recién recibido.
enum CambioMarcador {
  /// Igual que antes.
  ninguno,

  /// Sube el marcador del Mutxamel (aunque a la vez suba el del rival: una sola celebración con el marcador final).
  golNuestro,

  /// Sube solo el marcador del rival.
  golRival,

  /// El marcador baja (gol anulado): solo se actualiza, sin celebración ni destello.
  baja,
}

/// Compara el marcador que ya se mostraba con el nuevo. Un marcador sin informar (`null`) cuenta como 0, el que
/// se ve ("-") antes de que empiece el partido.
CambioMarcador compararMarcador({
  required int? favorAntes,
  required int? contraAntes,
  required int? favor,
  required int? contra,
}) {
  final fa = favorAntes ?? 0;
  final ca = contraAntes ?? 0;
  final f = favor ?? 0;
  final c = contra ?? 0;

  if (f < fa || c < ca) {
    return CambioMarcador.baja;
  }

  if (f > fa) {
    return CambioMarcador.golNuestro;
  }

  if (c > ca) {
    return CambioMarcador.golRival;
  }

  return CambioMarcador.ninguno;
}
