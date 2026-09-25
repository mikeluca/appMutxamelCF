import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/cuota_familiar_model.dart';
import '../models/pago_cuota_model.dart';
import '../services/cuota_familiar_service.dart';

class CuotasPage extends StatefulWidget {
  const CuotasPage({super.key});

  @override
  State<CuotasPage> createState() => _CuotasPageState();
}

class _CuotasPageState extends State<CuotasPage> {
  List<CuotaFamiliarModel> _cuotas = [];

  bool _cargando = true;
  String? _error;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cargarCuotas();
  }

  Future<void> _cargarCuotas() async {
    try {
      final cuotas = await CuotaFamiliarService.obtenerMisCuotas();

      if (!mounted) return;

      setState(() {
        _cuotas = cuotas;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Map<int, List<CuotaFamiliarModel>> get _cuotasPorJugador {
    final grupos = <int, List<CuotaFamiliarModel>>{};

    for (final cuota in _cuotas) {
      grupos.putIfAbsent(cuota.jugadorId, () => []).add(cuota);
    }

    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: ClubAppBarTitle(titulo: _t.clubPageFees)),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return Center(child: CircularProgressIndicator(color: AppColors.azul));
    }

    if (_error != null) {
      return _construirError();
    }

    if (_cuotas.isEmpty) {
      return RefreshIndicator(
        color: AppColors.azul,
        onRefresh: _cargarCuotas,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _t.noFeesRegistered,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final grupos = _cuotasPorJugador;

    return RefreshIndicator(
      color: AppColors.azul,
      onRefresh: _cargarCuotas,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text(
            _t.clubPageFees,
            style: TextStyle(
              color: _colors.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t.playersCountSimple(grupos.length),
            style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 16),

          for (final jugadorId in grupos.keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _construirGrupoJugador(grupos[jugadorId]!),
            ),
        ],
      ),
    );
  }

  Widget _construirGrupoJugador(List<CuotaFamiliarModel> cuotas) {
    final nombre = cuotas.first.jugadorNombre;
    final pendientes = cuotas
        .where((c) => c.estado != 'PAGADO')
        .length;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            nombre,
            style: TextStyle(
              color: _colors.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${_t.feesCountLabel(cuotas.length)}'
            '${pendientes == 0 ? _t.feesAllPaidSuffix : _t.feesPendingSuffix(pendientes)}',
            style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.azulOscuro.withValues(alpha: 0.08),
            child: Icon(Icons.person_outline, color: AppColors.azul),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: cuotas.map(_construirFilaCuota).toList(),
        ),
      ),
    );
  }

  Widget _construirFilaCuota(CuotaFamiliarModel cuota) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _mostrarPagos(cuota),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                cuota.tituloConPeriodo,
                style: TextStyle(
                  color: _colors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Importe y estado en columna (no en fila) para que el
            // importe quede siempre pegado al borde derecho, sin
            // desplazarse según lo ancha que sea la burbuja de estado.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${cuota.importe.toStringAsFixed(2)} €',
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                _construirBadgeEstado(cuota),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarPagos(CuotaFamiliarModel cuota) {
    if (cuota.pagos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.noPaymentRegistered)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cuota.tituloConPeriodo),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cuota.pagos.length; i++) ...[
                if (i > 0) const Divider(height: 24),
                _construirDetallePago(cuota.pagos[i]),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t.close),
          ),
        ],
      ),
    );
  }

  Widget _construirDetallePago(PagoCuotaModel pago) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${pago.importe.toStringAsFixed(2)} €',
          style: TextStyle(
            color: _colors.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        _construirDatoPago(
          Icons.event_outlined,
          pago.fechaPagoFormateada ?? _t.noDateRegistered,
        ),
        const SizedBox(height: 4),
        _construirDatoPago(
          Icons.payments_outlined,
          (pago.metodoPago == null || pago.metodoPago!.isEmpty)
              ? _t.methodNotIndicated
              : pago.metodoPago!,
        ),
      ],
    );
  }

  Widget _construirDatoPago(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, size: 16, color: _colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
        ),
      ],
    );
  }

  Widget _construirBadgeEstado(CuotaFamiliarModel cuota) {
    final (texto, color) = _estiloEstado(cuota);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color) _estiloEstado(CuotaFamiliarModel cuota) {
    if (cuota.vencida) {
      return (_t.feeStatusOverdue, Colors.redAccent);
    }

    switch (cuota.estado) {
      case 'PAGADO':
        return (_t.feeStatusPaid, Colors.green.shade600);
      case 'PARCIAL':
        return (_t.feeStatusPartial, AppColors.azul);
      default:
        return (_t.feeStatusPending, AppColors.dorado);
    }
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _error = null;
                });

                _cargarCuotas();
              },
              icon: const Icon(Icons.refresh),
              label: Text(_t.retry),
            ),
          ],
        ),
      ),
    );
  }
}
