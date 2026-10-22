import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/gen/app_localizations.dart';
import '../config/app_preferences.dart';
import '../navigation/app_navigator.dart';
import '../network/api_client.dart';
import 'pantalla_version_obsoleta.dart';

/// Compara dos versiones semánticas ("1.0.10" > "1.0.9"): negativo si [a] es
/// anterior a [b], 0 si son iguales y positivo si es posterior. Ignora el
/// número de compilación ("1.0.2+6") y el sufijo de pre-lanzamiento
/// ("1.0.2-beta"); una parte que falte o no sea un número cuenta como 0.
int compararVersiones(String a, String b) {
  final partesA = _partesDeVersion(a);
  final partesB = _partesDeVersion(b);

  final largo = partesA.length > partesB.length
      ? partesA.length
      : partesB.length;

  for (var i = 0; i < largo; i++) {
    final x = i < partesA.length ? partesA[i] : 0;
    final y = i < partesB.length ? partesB[i] : 0;

    if (x != y) {
      return x.compareTo(y);
    }
  }

  return 0;
}

List<int> _partesDeVersion(String version) {
  final base = version.trim().split(RegExp(r'[+-]')).first;

  return base.split('.').map((parte) => int.tryParse(parte.trim()) ?? 0).toList();
}

/// Lo que publica el servidor en GET /api/public/app/version.
class VersionRemota {
  final String minimaAndroid;
  final String minimaIos;
  final String recomendadaAndroid;
  final String recomendadaIos;
  final String urlAndroid;
  final String urlIos;

  const VersionRemota({
    required this.minimaAndroid,
    required this.minimaIos,
    required this.recomendadaAndroid,
    required this.recomendadaIos,
    required this.urlAndroid,
    required this.urlIos,
  });

  factory VersionRemota.fromJson(Map<String, dynamic> json) {
    String texto(String clave) => json[clave]?.toString() ?? '';

    return VersionRemota(
      minimaAndroid: texto('minimaAndroid'),
      minimaIos: texto('minimaIos'),
      recomendadaAndroid: texto('recomendadaAndroid'),
      recomendadaIos: texto('recomendadaIos'),
      urlAndroid: texto('urlAndroid'),
      urlIos: texto('urlIos'),
    );
  }

  String minima({required bool esIos}) => esIos ? minimaIos : minimaAndroid;

  String recomendada({required bool esIos}) =>
      esIos ? recomendadaIos : recomendadaAndroid;

  String url({required bool esIos}) => esIos ? urlIos : urlAndroid;
}

enum EstadoVersion {
  /// La versión instalada es la recomendada o una posterior.
  actualizada,

  /// Anterior a la recomendada: se avisa una vez al día, sin bloquear.
  recomendada,

  /// Anterior a la mínima: la app se bloquea hasta que se actualice.
  obligatoria,
}

/// Qué pasa con la versión [instalada] según lo que publica el servidor para su
/// plataforma. Una mínima o recomendada vacía no exige nada.
EstadoVersion evaluarVersion({
  required String instalada,
  required VersionRemota remota,
  required bool esIos,
}) {
  final minima = remota.minima(esIos: esIos);
  final recomendada = remota.recomendada(esIos: esIos);

  if (minima.trim().isNotEmpty && compararVersiones(instalada, minima) < 0) {
    return EstadoVersion.obligatoria;
  }

  if (recomendada.trim().isNotEmpty &&
      compararVersiones(instalada, recomendada) < 0) {
    return EstadoVersion.recomendada;
  }

  return EstadoVersion.actualizada;
}

/// Control de la versión mínima obligatoria: se consulta al arrancar (en el
/// splash) y al volver de segundo plano. Si falla la consulta (sin red), la app
/// sigue con normalidad.
class ControlVersion {
  ControlVersion._();

  /// Solo para tests: sustituyen a la red, al plugin de la versión instalada, a
  /// la plataforma, al reloj y a la apertura de la tienda.
  @visibleForTesting
  static Future<VersionRemota> Function() obtenerRemota = () async {
    final data = await ApiClient.get('/public/app/version');

    return VersionRemota.fromJson(data as Map<String, dynamic>);
  };

  @visibleForTesting
  static Future<String> Function() obtenerInstalada = () async {
    final info = await PackageInfo.fromPlatform();

    return info.version;
  };

  @visibleForTesting
  static bool Function() esIos = () => Platform.isIOS;

  @visibleForTesting
  static DateTime Function() ahora = DateTime.now;

  @visibleForTesting
  static Future<bool> Function(Uri url) abrirUrl = (url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  /// La versión instalada de la app, o null si no se puede leer.
  static Future<String?> versionInstalada() async {
    try {
      return await obtenerInstalada();
    } catch (e) {
      debugPrint('NO SE PUDO LEER LA VERSIÓN INSTALADA: $e');
      return null;
    }
  }

  static bool _bloqueada = false;
  static bool _comprobando = false;
  static bool _splashTerminado = false;
  static VersionRemota? _ultimaRemota;
  static EstadoVersion? _ultimoEstado;

  static bool get bloqueada => _bloqueada;

  @visibleForTesting
  static EstadoVersion? get ultimoEstado => _ultimoEstado;

  @visibleForTesting
  static void reiniciar() {
    _bloqueada = false;
    _comprobando = false;
    _splashTerminado = false;
    _ultimaRemota = null;
    _ultimoEstado = null;
  }

  /// El splash ya ha dado paso a home: desde ahora se puede avisar encima.
  static void splashTerminado() {
    _splashTerminado = true;
  }

  /// Consulta el servidor y, si la versión instalada es anterior a la mínima,
  /// bloquea la app con [PantallaVersionObsoleta]. Devuelve el estado, o null si
  /// no se pudo comprobar (sin red, respuesta rara...): entonces la app sigue.
  static Future<EstadoVersion?> comprobar() async {
    if (_comprobando) {
      return _ultimoEstado;
    }

    _comprobando = true;

    try {
      final instalada = await versionInstalada();

      if (instalada == null) {
        return null;
      }

      final remota = await obtenerRemota();

      final estado = evaluarVersion(
        instalada: instalada,
        remota: remota,
        esIos: esIos(),
      );

      _ultimaRemota = remota;
      _ultimoEstado = estado;

      if (estado == EstadoVersion.obligatoria) {
        _bloquear(remota);
      }

      return estado;
    } catch (e) {
      debugPrint('NO SE PUDO COMPROBAR LA VERSIÓN DE LA APP: $e');
      return null;
    } finally {
      _comprobando = false;
    }
  }

  static void _bloquear(VersionRemota remota) {
    if (_bloqueada) {
      return;
    }

    final navigatorState = AppNavigator.navigator;

    if (navigatorState == null) {
      return;
    }

    _bloqueada = true;

    // Sustituye todas las pantallas: no hay nada a lo que volver. El Future de la
    // ruta solo se completa al cerrarla (nunca), así que no se espera.
    navigatorState.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => PantallaVersionObsoleta(
          alActualizar: () => abrirTienda(remota),
        ),
      ),
      (_) => false,
    );
  }

  static Future<void> abrirTienda(VersionRemota remota) async {
    final url = remota.url(esIos: esIos());

    if (url.trim().isEmpty) {
      return;
    }

    try {
      await abrirUrl(Uri.parse(url));
    } catch (e) {
      debugPrint('NO SE PUDO ABRIR LA TIENDA: $e');
    }
  }

  /// Al volver de segundo plano: comprueba de nuevo y, si procede, avisa.
  static Future<void> alReanudar() async {
    await comprobar();
    await avisarSiProcede();
  }

  /// Aviso no bloqueante de que hay una versión recomendada: una vez al día, con
  /// "Actualizar" y "Más tarde". No se muestra mientras dure el splash (el paso a
  /// home lo taparía) ni con la app bloqueada.
  static Future<void> avisarSiProcede() async {
    final remota = _ultimaRemota;

    if (_ultimoEstado != EstadoVersion.recomendada ||
        remota == null ||
        _bloqueada ||
        !_splashTerminado) {
      return;
    }

    final contexto = AppNavigator.navigatorKey.currentContext;

    if (contexto == null || !contexto.mounted) {
      return;
    }

    final hoy = _diaTexto(ahora());

    if (await AppPreferences.obtenerUltimoAvisoVersion() == hoy) {
      return;
    }

    // Se anota antes de enseñarlo: un día, un aviso, lo que se elija.
    await AppPreferences.guardarUltimoAvisoVersion(hoy);

    if (!contexto.mounted) {
      return;
    }

    final t = AppLocalizations.of(contexto);

    final actualizar = await showDialog<bool>(
      context: contexto,
      builder: (dialogo) => AlertDialog(
        title: Text(t.versionUpdateAvailableTitle),
        content: Text(t.versionUpdateAvailableBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: Text(t.versionUpdateLater),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: Text(t.versionUpdateButton),
          ),
        ],
      ),
    );

    if (actualizar == true) {
      await abrirTienda(remota);
    }
  }

  static String _diaTexto(DateTime dia) {
    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dia.year}-${dos(dia.month)}-${dos(dia.day)}';
  }
}
