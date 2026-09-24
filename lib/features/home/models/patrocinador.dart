/// Patrocinador del club mostrado en la pantalla principal, igual
/// que en la sección "Nuestros Patrocinadores" del footer de la web.
/// Es una lista estática/hardcodeada (igual que en la web: no viene
/// de ninguna API ni base de datos).
class Patrocinador {
  final String nombre;

  /// Nombre del fichero en /images/ (mismo host que sirve la API).
  final String imagen;

  /// Enlace externo a la web/red social del patrocinador. Null si no
  /// lleva enlace (p.ej. Aresala, que en la web tampoco lo lleva).
  final String? url;

  /// true si en la web se muestra recortada en círculo
  /// (object-fit: cover; border-radius: 50%).
  final bool circular;

  const Patrocinador({
    required this.nombre,
    required this.imagen,
    this.url,
    this.circular = false,
  });
}

const List<Patrocinador> kPatrocinadores = [
  Patrocinador(
    nombre: 'Frutas y verduras Juanete',
    imagen: 'frutasJuanete.jpg',
    url: 'https://www.instagram.com/frutasjuanete/',
  ),
  Patrocinador(
    nombre: 'Unlimited Developments',
    imagen: 'unlimited.jpg',
    url: 'https://www.unlimiteddevelopments.es/',
  ),
  Patrocinador(
    nombre: 'Ayto Mutxamel',
    imagen: 'aytoMutxamel.jpg',
    url: 'https://ayto.mutxamel.org/',
  ),
  Patrocinador(
    nombre: 'Alumed Sistemas',
    imagen: 'alumed.jpg',
    url: 'https://alumedsistemas.com/',
  ),
  Patrocinador(
    nombre: 'Asesoria Collado',
    imagen: 'collado.jpg',
    url: 'https://asesoriacollado.com/es',
  ),
  Patrocinador(
    nombre: 'Clinica Dental NUVA',
    imagen: 'nuva.jpg',
    url: 'https://clinicadentalnuva.com/es',
    circular: true,
  ),
  Patrocinador(
    nombre: 'Limpieza de Tubos Costablanca',
    imagen: 'costablanca.jpg',
    url: 'https://www.limpiezadetuboscostablanca.net/',
  ),
  Patrocinador(
    nombre: 'La bodega de Elias',
    imagen: 'laBodega.jpg',
    url: 'https://www.instagram.com/labodegaelias/',
    circular: true,
  ),
  // Sin enlace, igual que en la web.
  Patrocinador(nombre: 'Aresala', imagen: 'aresala.jpg'),
  Patrocinador(
    nombre: 'AA Energy',
    imagen: 'aaenergy.jpeg',
    url: 'https://www.aaenergyenriquez.es',
  ),
];
