import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../ficha_partido/widgets/ficha_comunes.dart';
import 'datos_compartir.dart';

/// Los colores de cada estilo de la imagen.
class _Paleta {
  final List<Color> fondo;
  final Color texto;
  final Color suave;
  final Color acento;
  final Color sobreAcento;
  final Color rayas;
  final double marcaDeAgua;

  const _Paleta({
    required this.fondo,
    required this.texto,
    required this.suave,
    required this.acento,
    required this.sobreAcento,
    required this.rayas,
    required this.marcaDeAgua,
  });

  static _Paleta de(EstiloCompartir estilo) {
    return switch (estilo) {
      EstiloCompartir.club => const _Paleta(
        fondo: [AppColors.azul, AppColors.azulOscuro, Color(0xFF06263B)],
        texto: Colors.white,
        suave: Color(0xFFD4E4F0),
        acento: AppColors.dorado,
        sobreAcento: Color(0xFF18252B),
        rayas: Color(0x0FFFFFFF),
        marcaDeAgua: 0.07,
      ),
      EstiloCompartir.oscuro => const _Paleta(
        fondo: [Color(0xFF222831), Color(0xFF14181D), Color(0xFF080A0D)],
        texto: Colors.white,
        suave: Color(0xFFB8C0C8),
        acento: AppColors.dorado,
        sobreAcento: Color(0xFF18252B),
        rayas: Color(0x0AFFFFFF),
        marcaDeAgua: 0.06,
      ),
      EstiloCompartir.claro => const _Paleta(
        fondo: [Colors.white, Color(0xFFF1F5F8), Color(0xFFDCE6ED)],
        texto: AppColors.azulOscuro,
        suave: Color(0xFF52636F),
        acento: AppColors.azulOscuro,
        sobreAcento: Colors.white,
        rayas: Color(0x0F0B3D5C),
        marcaDeAgua: 0.07,
      ),
    };
  }
}

/// Rayas diagonales muy sutiles de fondo.
class _Rayas extends CustomPainter {
  final Color color;

  const _Rayas(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke;

    const paso = 84.0;

    for (double x = -size.height; x < size.width + size.height; x += paso) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(_Rayas anterior) => anterior.color != color;
}

/// La imagen que se comparte: 1080 px de ancho y 1350 (publicación) o 1920 (historia) de alto. Todo se dibuja con
/// widgets y las fuentes de la app; solo hay imágenes en los escudos. En la historia se dejan libres 250 px arriba y
/// abajo (los que tapan Instagram y WhatsApp).
class TarjetaCompartir extends StatelessWidget {
  static const double ancho = 1080;

  /// El lado de la antigua imagen cuadrada (se conserva el nombre para quien lo use como ancho).
  static const double lado = ancho;

  /// Los píxeles que se dejan libres arriba y abajo en la historia.
  static const double zonaLibreHistoria = 250;

  final DatosCompartir datos;
  final OpcionesCompartir opciones;

  const TarjetaCompartir({
    super.key,
    required this.datos,
    this.opciones = const OpcionesCompartir(),
  });

  static const Color _verde = Color(0xFF2E9E4F);
  static const Color _gris = Color(0xFF8A949B);
  static const Color _rojo = Color(0xFFD64545);

  @override
  Widget build(BuildContext context) {
    final p = _Paleta.de(opciones.estilo);
    final historia = opciones.formato == FormatoCompartir.historia;
    final k = historia ? 1.14 : 1.0;
    final estiloBase =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    return SizedBox(
      key: const ValueKey('tarjeta-compartir'),
      width: ancho,
      height: opciones.formato.alto,
      child: DefaultTextStyle(
        style: estiloBase.copyWith(
          color: p.texto,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w600,
        ),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: p.fondo,
                  ),
                ),
              ),
              CustomPaint(painter: _Rayas(p.rayas)),
              Center(
                child: Opacity(
                  key: const ValueKey('compartir-marca-de-agua'),
                  opacity: p.marcaDeAgua,
                  child: Image.asset(
                    'assets/images/escudo.png',
                    width: 900,
                    height: 900,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  64,
                  historia ? zonaLibreHistoria : 64,
                  64,
                  historia ? zonaLibreHistoria : 52,
                ),
                child: Column(
                  children: [
                    _cabecera(p, k),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: ancho - 128,
                            child: _centro(context, p, k),
                          ),
                        ),
                      ),
                    ),
                    _pie(context, p, k),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- arriba: competición, fecha y campo ------------------------------------------------------

  Widget _cabecera(_Paleta p, double k) {
    final fechaYCampo = [
      datos.fecha,
      if (datos.campo != null) datos.campo!,
    ].where((s) => s.isNotEmpty).join(' · ');

    return Column(
      children: [
        if (datos.competicion.isNotEmpty)
          Text(
            datos.competicion,
            key: const ValueKey('compartir-competicion'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: p.texto,
              fontSize: 42 * k,
              fontWeight: FontWeight.w800,
            ),
          ),
        if (fechaYCampo.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            fechaYCampo,
            key: const ValueKey('compartir-fecha'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.suave, fontSize: 34 * k),
          ),
        ],
      ],
    );
  }

  // ---- centro: etiqueta, escudos, marcador, cinta, goleadores y racha ---------------------------

  Widget _centro(BuildContext context, _Paleta p, double k) {
    final t = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _etiqueta(p, k),
        SizedBox(height: 44 * k),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _equipo(
                datos.local,
                datos.mutxamelEsLocal || datos.rivalEsPropio,
                datos.mutxamelEsLocal ? null : datos.escudoRivalUrl,
                p,
                k,
                'compartir-local',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _equipo(
                datos.visitante,
                !datos.mutxamelEsLocal || datos.rivalEsPropio,
                datos.mutxamelEsLocal ? datos.escudoRivalUrl : null,
                p,
                k,
                'compartir-visitante',
              ),
            ),
          ],
        ),
        SizedBox(height: 24 * k),
        _marcador(context, p, k),
        if (datos.resultado == ResultadoCompartir.victoria ||
            datos.resultado == ResultadoCompartir.empate) ...[
          SizedBox(height: 24 * k),
          _cinta(t, p, k),
        ],
        if (datos.antesDelPartido) ...[
          SizedBox(height: 40 * k),
          _teEsperamos(t, p, k),
        ] else if (datos.tieneGoleadores && opciones.goleadores) ...[
          SizedBox(height: 40 * k),
          _goleadores(t, p, k),
        ],
        if (datos.tieneRacha && opciones.racha) ...[
          SizedBox(height: 40 * k),
          _racha(context, t, p, k),
        ],
      ],
    );
  }

  Widget _etiqueta(_Paleta p, double k) {
    final enDirecto = datos.fase == FaseCompartir.enJuego;

    return DecoratedBox(
      key: const ValueKey('compartir-etiqueta'),
      decoration: BoxDecoration(
        color: p.acento,
        borderRadius: BorderRadius.circular(60),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 44 * k, vertical: 16 * k),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (enDirecto) ...[
              Container(
                key: const ValueKey('compartir-punto-rojo'),
                width: 28 * k,
                height: 28 * k,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 16 * k),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  datos.etiqueta,
                  key: const ValueKey('compartir-estado'),
                  style: TextStyle(
                    color: p.sobreAcento,
                    fontSize: 52 * k,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// El tamaño del nombre según lo largo que sea, para que quepa en dos líneas.
  static double _tamanoNombre(String nombre, double k) {
    final largo = nombre.length;
    final base = largo <= 14
        ? 50.0
        : largo <= 22
        ? 42.0
        : largo <= 32
        ? 36.0
        : 30.0;

    return base * k;
  }

  Widget _equipo(
    String nombre,
    bool mutxamel,
    String? url,
    _Paleta p,
    double k,
    String clave,
  ) {
    return Column(
      children: [
        EscudoEquipo(
          mutxamel: mutxamel,
          tamano: 250 * k,
          url: url,
          colorGenerico: p.suave,
        ),
        SizedBox(height: 20 * k),
        Text(
          nombre,
          key: ValueKey(clave),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: p.texto,
            fontSize: _tamanoNombre(nombre, k),
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _marcador(BuildContext context, _Paleta p, double k) {
    final t = AppLocalizations.of(context);
    final marcador = datos.marcador;

    if (marcador != null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          marcador,
          key: const ValueKey('compartir-marcador'),
          style: TextStyle(
            color: p.texto,
            fontSize: 250 * k,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      );
    }

    final hora = datos.hora;

    // Antes del partido: la hora grande y "vs".
    if (datos.antesDelPartido && hora != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.matchVs,
            key: const ValueKey('compartir-vs'),
            style: TextStyle(
              color: p.suave,
              fontSize: 60 * k,
              fontWeight: FontWeight.w800,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              hora,
              key: const ValueKey('compartir-hora'),
              style: TextStyle(
                color: p.texto,
                fontSize: 200 * k,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      t.matchVs,
      key: const ValueKey('compartir-vs'),
      style: TextStyle(
        color: p.texto,
        fontSize: 150 * k,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _cinta(AppLocalizations t, _Paleta p, double k) {
    final victoria = datos.resultado == ResultadoCompartir.victoria;

    return Container(
      key: ValueKey(
        victoria ? 'compartir-cinta-victoria' : 'compartir-cinta-empate',
      ),
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18 * k),
      decoration: BoxDecoration(
        color: victoria ? _verde : _gris,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        victoria ? t.shareRibbonWin : t.shareRibbonDraw,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 64 * k,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _goleadores(AppLocalizations t, _Paleta p, double k) {
    final todos = datos.goleadores;
    final visibles = todos.take(DatosCompartir.maxGoleadores).toList();
    final restantes = todos.length - visibles.length;

    return Column(
      key: const ValueKey('compartir-goleadores'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final g in visibles)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5 * k),
            child: Text(
              DatosCompartir.lineaGoleador(g),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.texto,
                fontSize: 46 * k,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (restantes > 0)
          Padding(
            padding: EdgeInsets.only(top: 6 * k),
            child: Text(
              t.shareMoreScorers(restantes),
              key: const ValueKey('compartir-mas-goleadores'),
              style: TextStyle(color: p.suave, fontSize: 38 * k),
            ),
          ),
      ],
    );
  }

  Widget _teEsperamos(AppLocalizations t, _Paleta p, double k) {
    return Column(
      key: const ValueKey('compartir-te-esperamos'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.shareSeeYou,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: p.texto,
            fontSize: 60 * k,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  /// G, E o P (en inglés W, D, L).
  static String _letra(String resultado, String idioma) {
    if (idioma == 'en') {
      return switch (resultado) {
        'G' => 'W',
        'P' => 'L',
        _ => 'D',
      };
    }

    return resultado;
  }

  Widget _racha(BuildContext context, AppLocalizations t, _Paleta p, double k) {
    final idioma = Localizations.localeOf(context).languageCode;

    return Column(
      key: const ValueKey('compartir-racha'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.shareLastFive,
          style: TextStyle(
            color: p.suave,
            fontSize: 38 * k,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 14 * k),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < datos.racha.length; i++) ...[
              if (i > 0) SizedBox(width: 18 * k),
              Container(
                key: ValueKey('compartir-racha-$i'),
                width: 78 * k,
                height: 78 * k,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: switch (datos.racha[i].resultado) {
                    'G' => _verde,
                    'P' => _rojo,
                    _ => _gris,
                  },
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _letra(datos.racha[i].resultado, idioma),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40 * k,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ---- abajo: hashtags, QR y escudo -------------------------------------------------------------

  Widget _pie(BuildContext context, _Paleta p, double k) {
    final t = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (opciones.hashtags) ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              DatosCompartir.hashtags,
              key: const ValueKey('compartir-pie'),
              style: TextStyle(
                color: p.texto,
                fontSize: 40 * k,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: 22 * k),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/escudo.png',
              key: const ValueKey('compartir-escudo-pie'),
              width: 96 * k,
              height: 96 * k,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 32 * k),
            Flexible(
              child: Text(
                opciones.qr ? t.shareDownloadApp : t.shareImageFooter,
                key: const ValueKey('compartir-descarga'),
                textAlign: opciones.qr ? TextAlign.right : TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.texto,
                  fontSize: 38 * k,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (opciones.qr) ...[
              SizedBox(width: 28 * k),
              // Fondo blanco y margen para que se lea bien con cualquier estilo.
              Container(
                key: const ValueKey('compartir-qr'),
                color: Colors.white,
                padding: EdgeInsets.all(12 * k),
                child: QrImageView(
                  data: DatosCompartir.web,
                  size: 150 * k,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
