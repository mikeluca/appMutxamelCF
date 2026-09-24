/// Enlace a una red social del club, igual que los iconos que
/// aparecen en la cabecera de la web (cabecera.html) en todas las
/// páginas. Es una lista estática/hardcodeada, igual que en la web.
class RedSocial {
  final String nombre;

  /// Nombre del fichero en /images/ (mismo host que sirve la API).
  final String imagen;

  final String url;

  const RedSocial({
    required this.nombre,
    required this.imagen,
    required this.url,
  });
}

const List<RedSocial> kRedesSociales = [
  RedSocial(
    nombre: 'X (Twitter)',
    imagen: 'twitter.png',
    url: 'https://x.com/mutxamelcf',
  ),
  RedSocial(
    nombre: 'Facebook',
    imagen: 'facebook.png',
    url: 'https://facebook.com/MutxamelCF17',
  ),
  RedSocial(
    nombre: 'Instagram',
    imagen: 'instagram.png',
    url: 'https://instagram.com/mutxamelcf.oficial/',
  ),
  RedSocial(
    nombre: 'YouTube',
    imagen: 'youtube.png',
    url: 'https://youtube.com/@mutxamelcf355',
  ),
];
