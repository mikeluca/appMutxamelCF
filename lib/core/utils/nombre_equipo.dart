/// El nombre de un equipo RIVAL como se enseña en la app: sin las siglas de la entidad, solo el nombre y la letra del
/// equipo. Solo cambia lo que se pinta: los datos, las búsquedas y lo que se envía al backend siguen con el nombre
/// original.
///
///  * "C.D. Salesianos Alicante" → "Salesianos Alicante"
///  * "Alicante Coty F.C." → "Alicante Coty"
///  * `C. F. Gata "A"` → `Gata "A"`
///  * "U.D. Altea S.A.D." → "Altea"
///
/// Quita:
///  * secuencias de letras sueltas seguidas de punto, con o sin espacio entre ellas (C.F., C. F., S.A.D., U.E., C.D.E.);
///  * las mismas siglas sin puntos cuando van como palabra aparte en mayúsculas (CF, FC, CD, UD, SD, UE, CE, AC, SAD,
///    CDE);
///  * los espacios sobrantes y los guiones o comas sueltos al principio o al final.
///
/// No quita ninguna otra palabra ni la letra del equipo entre comillas ("A", "B"...), tal como vengan. Si al quitarlas no
/// queda nada, devuelve el nombre original.
String nombreEquipoCorto(String nombre) {
  // Dos o más letras sueltas con punto (C.F., C. F., S.A.D.), que no sean el final de una palabra más larga.
  final conPuntos = RegExp(
    r'(?<![\p{L}\p{N}])(?:\p{L}\.\s*){2,}',
    unicode: true,
  );

  // Las mismas siglas sin puntos, como palabra aparte y en mayúsculas.
  final sinPuntos = RegExp(
    r'(?<![\p{L}\p{N}.])(?:CDE|SAD|CF|FC|CD|UD|SD|UE|CE|AC)(?![\p{L}\p{N}])',
    unicode: true,
  );

  var corto = nombre.replaceAll(conPuntos, ' ').replaceAll(sinPuntos, ' ');

  corto = corto.replaceAll(RegExp(r'\s+'), ' ');
  corto = corto.replaceAll(RegExp(r'^[\s,\-–—]+|[\s,\-–—]+$'), '');

  return corto.isEmpty ? nombre : corto;
}

/// El nombre de un rival para pintarlo: sin siglas, salvo que sea un equipo de nuestro club ([esPropio]: el filial, que
/// sigue como hoy) o el propio Mutxamel.
String nombreRivalVisible(String nombre, {bool esPropio = false}) =>
    esPropio || _esMutxamel(nombre) ? nombre : nombreEquipoCorto(nombre);

bool _esMutxamel(String nombre) => nombre
    .toLowerCase()
    .replaceAll('.', '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .startsWith('mutxamel');
