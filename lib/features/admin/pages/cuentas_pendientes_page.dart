import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/admin_model.dart';
import '../services/admin_service.dart';

/// Cuentas invitadas que todavía no se han activado (ADMIN_APP), con la opción
/// de reenviarles la activación.
class CuentasPendientesPage extends StatefulWidget {
  final AdminService? servicio;

  const CuentasPendientesPage({super.key, this.servicio});

  @override
  State<CuentasPendientesPage> createState() => _CuentasPendientesPageState();
}

class _CuentasPendientesPageState extends State<CuentasPendientesPage> {
  static const Color _rojo = Color(0xFFDC2626);

  late final AdminService _servicio = widget.servicio ?? AdminService();

  late Future<List<UsuarioPendienteModel>> _futuro;

  final TextEditingController _busqueda = TextEditingController();
  String _filtro = '';

  /// Cuentas con un reenvío en curso (el botón queda deshabilitado).
  final Set<int> _reenviando = {};

  AppLocalizations get _t => AppLocalizations.of(context);
  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerUsuariosPendientes();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _recargar() async {
    final nuevo = _servicio.obtenerUsuariosPendientes();

    setState(() {
      _futuro = nuevo;
    });

    try {
      await nuevo;
    } catch (_) {
      // El error ya se pinta en pantalla.
    }
  }

  Future<void> _reenviar(UsuarioPendienteModel usuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(_t.pendingAccountsResendConfirm(usuario.email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_t.pendingAccountsResend),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    setState(() {
      _reenviando.add(usuario.id);
    });

    try {
      final email = await _servicio.reenviarActivacion(usuario.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t.pendingAccountsResent(email.isEmpty ? usuario.email : email),
          ),
        ),
      );

      await _recargar();
    } catch (e) {
      if (!mounted) return;

      // Los 4xx traen un mensaje claro del servidor (ya activa, 10 minutos...).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException && e.statusCode != null && e.statusCode! < 500
                ? e.message
                : _t.connectionError,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reenviando.remove(usuario.id);
        });
      }
    }
  }

  bool _coincide(UsuarioPendienteModel u) {
    final texto = _filtro.trim().toLowerCase();

    if (texto.isEmpty) return true;

    return u.email.toLowerCase().contains(texto) ||
        u.nombreMostrable.toLowerCase().contains(texto) ||
        '${u.nombre ?? ''} ${u.apellidos ?? ''}'.toLowerCase().contains(texto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: _t.clubPagePendingAccounts),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _busqueda,
              onChanged: (valor) => setState(() => _filtro = valor),
              decoration: InputDecoration(
                hintText: _t.pendingAccountsSearch,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _recargar,
              child: FutureBuilder<List<UsuarioPendienteModel>>(
                future: _futuro,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 40),
                        Text(_t.connectionError, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _recargar,
                            icon: const Icon(Icons.refresh),
                            label: Text(_t.retry),
                          ),
                        ),
                      ],
                    );
                  }

                  final usuarios = (snapshot.data ?? const [])
                      .where(_coincide)
                      .toList();

                  if (usuarios.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(40),
                      children: [
                        Text(
                          _t.pendingAccountsEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _colors.onSurfaceVariant),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final usuario in usuarios) ...[
                        _construirTarjeta(usuario),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjeta(UsuarioPendienteModel u) {
    final enCurso = _reenviando.contains(u.id);

    return Card(
      key: ValueKey('pendiente-${u.id}'),
      margin: EdgeInsets.zero,
      elevation: 1,
      color: _colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              u.nombreMostrable,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(u.email, style: TextStyle(color: _colors.onSurfaceVariant)),
            if (u.roles.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(u.roles.join(', ')),
            ],
            if (u.vinculos.isNotEmpty) Text(u.vinculos.join(', ')),
            const SizedBox(height: 6),
            Row(
              children: [
                if (u.fechaAlta != null)
                  Text(
                    _t.pendingAccountsInvited(_fechaCorta(u.fechaAlta!)),
                    style: TextStyle(
                      fontSize: 12,
                      color: _colors.onSurfaceVariant,
                    ),
                  ),
                if (u.tokenCaducado) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _rojo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _rojo),
                    ),
                    child: Text(
                      _t.pendingAccountsCodeExpired,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _rojo,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: enCurso ? null : () => _reenviar(u),
                icon: const Icon(Icons.forward_to_inbox_outlined),
                label: Text(_t.pendingAccountsResend),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fechaCorta(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');

    return '${dos(fecha.day)}/${dos(fecha.month)}';
  }
}
