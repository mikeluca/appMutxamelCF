/// Minúsculas y sin acentos ni diéresis, para buscar sin distinguir mayúsculas ni acentos ("Pérez" encuentra "perez").
String textoParaBuscar(String texto) {
  const origen = 'áàäâãåéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÅÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
  const destino = 'aaaaaaeeeeiiiiooooouuuuncAAAAAAEEEEIIIIOOOOOUUUUNC';

  final buffer = StringBuffer();

  for (final caracter in texto.split('')) {
    final i = origen.indexOf(caracter);

    buffer.write(i < 0 ? caracter : destino[i]);
  }

  return buffer.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
