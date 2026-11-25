import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Se ejecuta para cada fichero de test: el almacenamiento seguro (el token de la sesión) no existe en test y, sin
/// simularlo, una llamada se queda esperando para siempre. Vacío por defecto; los tests que necesitan una sesión
/// guardada ponen sus valores con `FlutterSecureStorage.setMockInitialValues`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  FlutterSecureStorage.setMockInitialValues({});

  await testMain();
}
