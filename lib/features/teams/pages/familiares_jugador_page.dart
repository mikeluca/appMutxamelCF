import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../models/familiar_jugador_model.dart';
import '../../auth/models/perfil_app.dart';
import '../models/player_model.dart';
import '../services/team_services.dart';

class FamiliaresJugadorPage extends StatefulWidget {
  final PerfilEquipo equipo;
  final PlayerModel jugador;

  const FamiliaresJugadorPage({
    super.key,
    required this.equipo,
    required this.jugador,
  });

  @override
  State<FamiliaresJugadorPage> createState() => _FamiliaresJugadorPageState();
}

class _FamiliaresJugadorPageState extends State<FamiliaresJugadorPage> {
  final TeamService _teamService = TeamService();

  late Future<List<FamiliarJugadorModel>> _familiaresFuture;

  @override
  void initState() {
    super.initState();
    _cargarFamiliares();
  }

  void _cargarFamiliares() {
    _familiaresFuture = _teamService.obtenerFamiliaresJugador(
      equipoId: widget.equipo.id,
      jugadorId: widget.jugador.id,
    );
  }

  Future<void> _refrescar() async {
    setState(() {
      _cargarFamiliares();
    });

    await _familiaresFuture;
  }

  Future<void> _llamar(String telefono) async {
    final uri = Uri.parse('tel:$telefono');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede abrir la aplicación de teléfono'),
        ),
      );
    }
  }

  Future<void> _enviarEmail(String email) async {
    final uri = Uri.parse('mailto:$email');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede abrir la aplicación de correo'),
        ),
      );
    }
  }

  Future<void> _abrirWhatsapp(String telefono) async {
    final numero = telefono.replaceAll(RegExp(r'[^0-9+]'), '');

    final numeroWhatsapp = numero.startsWith('+')
        ? numero.substring(1)
        : numero;

    final uri = Uri.parse('https://wa.me/$numeroWhatsapp');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede abrir WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const ClubAppBarTitle(titulo: 'Familiares')),
      body: FutureBuilder<List<FamiliarJugadorModel>>(
        future: _familiaresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refrescar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  const Icon(Icons.error_outline, size: 50),
                  const SizedBox(height: 12),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final familiares = snapshot.data ?? [];

          if (familiares.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refrescar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  const Icon(Icons.family_restroom, size: 60),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Este jugador no tiene familiares registrados',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${widget.jugador.nombre} ${widget.jugador.apellidos}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...familiares.map(_construirFamiliar),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirFamiliar(FamiliarJugadorModel familiar) {
    final tieneTelefono =
        familiar.telefono != null && familiar.telefono!.trim().isNotEmpty;

    final tieneEmail =
        familiar.email != null && familiar.email!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        familiar.nombreCompleto,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (familiar.parentesco != null &&
                          familiar.parentesco!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          familiar.parentesco!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (familiar.esFamiliarPrincipal)
                  Icon(
                    Icons.star,
                    color: Theme.of(context).colorScheme.primary,
                    size: 26,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (tieneTelefono)
              Row(
                children: [
                  const Icon(Icons.phone_outlined),
                  const SizedBox(width: 10),
                  Expanded(child: Text(familiar.telefono!)),
                ],
              ),

            if (tieneTelefono) const SizedBox(height: 8),

            if (tieneEmail)
              Row(
                children: [
                  const Icon(Icons.email_outlined),
                  const SizedBox(width: 10),
                  Expanded(child: Text(familiar.email!)),
                ],
              ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (tieneTelefono)
                  OutlinedButton.icon(
                    onPressed: () => _llamar(familiar.telefono!),
                    icon: const Icon(Icons.call),
                    label: const Text('Llamar'),
                  ),

                if (tieneEmail)
                  OutlinedButton.icon(
                    onPressed: () => _enviarEmail(familiar.email!),
                    icon: const Icon(Icons.email),
                    label: const Text('Email'),
                  ),

                if (tieneTelefono && familiar.tieneWhatsapp)
                  OutlinedButton.icon(
                    onPressed: () => _abrirWhatsapp(familiar.telefono!),
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
