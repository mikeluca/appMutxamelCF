import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';

class AcercaDePage extends StatefulWidget {
  const AcercaDePage({super.key});

  @override
  State<AcercaDePage> createState() => _AcercaDePageState();
}

class _AcercaDePageState extends State<AcercaDePage> {
  static const String _urlWeb = 'https://mutxamelcf.es';
  static const String _urlPoliticaPrivacidad =
      'https://mutxamelcf.es/politicaPrivacidad';
  static const String _email = 'contacto.web@mutxamelcf.es';

  PackageInfo? _packageInfo;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _cargarPackageInfo();
  }

  Future<void> _cargarPackageInfo() async {
    final info = await PackageInfo.fromPlatform();

    if (!mounted) return;

    setState(() {
      _packageInfo = info;
    });
  }

  String get _version {
    final info = _packageInfo;

    if (info == null) {
      return '';
    }

    return info.buildNumber.isEmpty
        ? 'Versión ${info.version}'
        : 'Versión ${info.version} (${info.buildNumber})';
  }

  Future<void> _abrirUrl(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se ha podido abrir el enlace')));
    }
  }

  Future<void> _enviarEmail(String email) async {
    final uri = Uri.parse('mailto:$email');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede abrir la aplicación de correo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: 'Acerca de appMTX')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _construirCabecera(),

          const SizedBox(height: 24),

          _construirSeccion(
            titulo: 'El club',
            icono: Icons.info_outline,
            children: [
              _construirTarjetaTexto(
                'La aplicación oficial del Mutxamel Club de Fútbol te '
                'mantiene al día de convocatorias, entrenamientos, '
                'resultados y comunicaciones del club, estés donde estés.',
              ),
            ],
          ),

          const SizedBox(height: 24),

          _construirSeccion(
            titulo: 'Contacto',
            icono: Icons.contact_mail_outlined,
            children: [
              _construirOpcion(
                icono: Icons.public,
                titulo: 'Página web',
                subtitulo: _urlWeb,
                onTap: () => _abrirUrl(_urlWeb),
              ),

              const SizedBox(height: 10),

              _construirOpcion(
                icono: Icons.email_outlined,
                titulo: 'Email',
                subtitulo: _email,
                onTap: () => _enviarEmail(_email),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _construirSeccion(
            titulo: 'Legal',
            icono: Icons.gavel_outlined,
            children: [
              _construirOpcion(
                icono: Icons.privacy_tip_outlined,
                titulo: 'Política de privacidad',
                subtitulo: 'Cómo tratamos tus datos',
                onTap: () => _abrirUrl(_urlPoliticaPrivacidad),
              ),

              const SizedBox(height: 10),

              _construirOpcion(
                icono: Icons.description_outlined,
                titulo: 'Licencias de terceros',
                subtitulo: 'Software libre utilizado en la aplicación',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'appMTX',
                  applicationVersion: _version,
                  applicationIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Image.asset(
                      'assets/images/escudo.png',
                      width: 64,
                      height: 64,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              '© ${DateTime.now().year} Mutxamel Club de Fútbol',
              style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCabecera() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Image.asset('assets/images/escudo.png', height: 90),

          const SizedBox(height: 16),

          const Text(
            'appMTX',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Aplicación oficial del Mutxamel Club de Fútbol',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),

          if (_version.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _version,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirSeccion({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: _colors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                color: _colors.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...children,
      ],
    );
  }

  Widget _construirTarjetaTexto(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: _colors.onSurface,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _construirOpcion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.azul.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: _colors.primary, size: 24),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: _colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: _colors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: _colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
