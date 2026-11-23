import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Un fichero que ha elegido el usuario: su nombre y su contenido. No se guarda en ningún sitio: solo se mantiene en
/// memoria hasta subirlo.
class FicheroElegido {
  final String nombre;
  final Uint8List bytes;

  const FicheroElegido({required this.nombre, required this.bytes});
}

/// Elegir un fichero del móvil (Archivos, iCloud, Descargas...). Detrás de una interfaz para poder sustituirlo en
/// los tests.
abstract class SelectorFicheros {
  /// Abre el selector del sistema solo con ficheros de las [extensiones] (sin el punto: "csv", "xlsx"). Null si el
  /// usuario cancela.
  Future<FicheroElegido?> elegir({required List<String> extensiones});
}

/// El selector del sistema (la hoja de documentos de iOS, el selector de Android).
class SelectorFicherosSistema implements SelectorFicheros {
  const SelectorFicherosSistema();

  @override
  Future<FicheroElegido?> elegir({required List<String> extensiones}) async {
    final fichero = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensiones,
    );

    if (fichero == null) return null;

    return FicheroElegido(
      nombre: fichero.name,
      bytes: await fichero.readAsBytes(),
    );
  }
}
