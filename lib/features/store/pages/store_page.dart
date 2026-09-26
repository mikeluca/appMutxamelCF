import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/tienda_pedido_item.dart';
import '../services/tienda_service.dart';

class _ProductoTienda {
  /// Valor EXACTO que espera el backend en el campo 'prenda'. No se
  /// traduce: es contenido enviado a la API, no texto de interfaz.
  final String prenda;
  final String Function(AppLocalizations t) titulo;
  final String precio;
  final String Function(AppLocalizations t) descripcion;
  final String imagenUrl;
  final String Function(AppLocalizations t)? nota;

  const _ProductoTienda({
    required this.prenda,
    required this.titulo,
    required this.precio,
    required this.descripcion,
    required this.imagenUrl,
    this.nota,
  });
}

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  // Misma URL que ya usa AcercaDePage para enlazar a páginas del
  // sitio web público del club (distinto del host de la API).
  static const String _urlPoliticaPrivacidad =
      'https://mutxamelcf.es/politicaPrivacidad';

  static const List<String> _tallas = [
    '2',
    '4',
    '6',
    '8',
    '10',
    '12',
    '14',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '3XL',
    '4XL',
  ];

  // Talla / Pecho (cm) / Largo (cm).
  static const List<List<String>> _guiaTallas = [
    ['2', '35', '50'],
    ['4', '37', '51,5'],
    ['6', '38,5', '54'],
    ['8', '40', '56'],
    ['10', '40,5', '58'],
    ['12', '42', '61,5'],
    ['14', '46,5', '65,5'],
    ['S', '49', '69'],
    ['M', '50,5', '72'],
    ['L', '53,5', '74,5'],
    ['XL', '57', '78'],
    ['XXL', '61,5', '82'],
    ['3XL', '63', '85'],
    ['4XL', '65,5', '87'],
  ];

  final TiendaService _tiendaService = TiendaService();

  late final List<_ProductoTienda> _productos;

  // Estado por prenda (clave: _ProductoTienda.prenda).
  final Map<String, int> _cantidades = {};
  final Map<String, List<String?>> _tallasSeleccionadas = {};

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _aceptaPrivacidad = false;
  bool _enviando = false;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();

    _productos = [
      _ProductoTienda(
        prenda: 'Camiseta oficial',
        titulo: (t) => t.storeProductShirtTitle,
        precio: '30 €',
        descripcion: (t) => t.storeProductShirtDescription,
        // El nombre exacto del fichero en el servidor lleva tilde
        // en la "o" (no en la "i"): segunda_equipacón.jpeg.
        imagenUrl: '${AppConfig.mediaBaseUrl}/images/primera_equipacion.jpeg',
      ),
      _ProductoTienda(
        prenda: 'Segunda equipacion - colaboracion AECC',
        titulo: (t) => t.storeProductSecondKitTitle,
        precio: '30 €',
        descripcion: (t) => t.storeProductSecondKitDescription,
        imagenUrl: Uri.encodeFull(
          '${AppConfig.mediaBaseUrl}/images/segunda_equipacón.jpeg',
        ),
        nota: (t) => t.storeProductSecondKitNote,
      ),
    ];

    for (final producto in _productos) {
      _cantidades[producto.prenda] = 0;
      _tallasSeleccionadas[producto.prenda] = [];
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _cambiarCantidad(_ProductoTienda producto, int delta) {
    setState(() {
      final actual = _cantidades[producto.prenda] ?? 0;
      final nueva = (actual + delta).clamp(0, 20);

      _cantidades[producto.prenda] = nueva;

      final tallas = _tallasSeleccionadas[producto.prenda]!;

      if (nueva > tallas.length) {
        tallas.addAll(List<String?>.filled(nueva - tallas.length, null));
      } else if (nueva < tallas.length) {
        tallas.removeRange(nueva, tallas.length);
      }
    });
  }

  Future<void> _abrirPoliticaPrivacidad() async {
    final uri = Uri.parse(_urlPoliticaPrivacidad);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
  }

  void _resetearFormulario() {
    _nombreController.clear();
    _telefonoController.clear();
    _emailController.clear();

    setState(() {
      _aceptaPrivacidad = false;

      for (final producto in _productos) {
        _cantidades[producto.prenda] = 0;
        _tallasSeleccionadas[producto.prenda] = [];
      }
    });
  }

  Future<void> _crearPedido() async {
    if (_enviando) return;

    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();
    final email = _emailController.text.trim();
    final t = AppLocalizations.of(context);

    if (nombre.isEmpty) {
      _mostrarError(t.storeErrorEnterName);
      return;
    }

    final emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!emailValido) {
      _mostrarError(t.storeErrorInvalidEmail);
      return;
    }

    if (!_aceptaPrivacidad) {
      _mostrarError(t.storeErrorAcceptPrivacy);
      return;
    }

    final items = <TiendaPedidoItem>[];

    for (final producto in _productos) {
      final cantidad = _cantidades[producto.prenda] ?? 0;

      if (cantidad <= 0) continue;

      final tallas = _tallasSeleccionadas[producto.prenda]!;

      if (tallas.any((talla) => talla == null || talla.isEmpty)) {
        _mostrarError(
          t.storeErrorSelectSizeForProduct(producto.titulo(t)),
        );
        return;
      }

      items.add(
        TiendaPedidoItem(
          prenda: producto.prenda,
          cantidad: cantidad,
          tallas: tallas.cast<String>(),
        ),
      );
    }

    if (items.isEmpty) {
      _mostrarError(t.storeErrorSelectAtLeastOne);
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      await _tiendaService.crearPedido(
        nombre: nombre,
        telefono: telefono.isEmpty ? null : telefono,
        email: email,
        items: items,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.storeOrderSentMessage),
          duration: const Duration(seconds: 5),
        ),
      );

      _resetearFormulario();
    } catch (e) {
      if (!mounted) return;

      _mostrarError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ClubAppBarTitle(titulo: AppLocalizations.of(context).storeTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _construirHero(),
          const SizedBox(height: 24),
          ..._productos.map(_construirTarjetaProducto),
          _construirGuiaTallas(),
          const SizedBox(height: 20),
          _construirFormularioCliente(),
        ],
      ),
    );
  }

  Widget _construirHero() {
    final t = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.storeHeroKicker,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.storeHeroTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            t.storeHeroSubtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaProducto(_ProductoTienda producto) {
    final cantidad = _cantidades[producto.prenda] ?? 0;
    final t = AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(
              producto.imagenUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: _colors.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: _colors.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        producto.titulo(t),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _colors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      producto.precio,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azul,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  producto.descripcion(t),
                  style: TextStyle(
                    color: _colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                if (producto.nota != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 16,
                        color: Colors.pinkAccent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          producto.nota!(t),
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: _colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      t.storeUnits,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _enviando || cantidad <= 0
                          ? null
                          : () => _cambiarCantidad(producto, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$cantidad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _colors.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: _enviando || cantidad >= 20
                          ? null
                          : () => _cambiarCantidad(producto, 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                _construirSelectorTallas(producto),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSelectorTallas(_ProductoTienda producto) {
    final cantidad = _cantidades[producto.prenda] ?? 0;

    if (cantidad == 0) {
      return const SizedBox.shrink();
    }

    final tallas = _tallasSeleccionadas[producto.prenda]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cantidad; i++)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: DropdownButtonFormField<String>(
              key: ValueKey('${producto.prenda}_talla_$i'),
              initialValue: tallas[i],
              isDense: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).storeSizeUnitLabel(i + 1),
                border: const OutlineInputBorder(),
              ),
              items: _tallas
                  .map(
                    (talla) =>
                        DropdownMenuItem(value: talla, child: Text(talla)),
                  )
                  .toList(),
              onChanged: _enviando
                  ? null
                  : (valor) {
                      setState(() {
                        tallas[i] = valor;
                      });
                    },
            ),
          ),
      ],
    );
  }

  Widget _construirGuiaTallas() {
    final t = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          t.storeSizeGuideTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _colors.onSurface,
          ),
        ),
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              t.storeSizeGuideHint,
              style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: _colors.outlineVariant),
            ),
            children: [
              TableRow(
                children: [
                  _construirCeldaGuiaTallas(
                    t.storeSizeGuideSize,
                    esCabecera: true,
                  ),
                  _construirCeldaGuiaTallas(
                    t.storeSizeGuideChest,
                    esCabecera: true,
                  ),
                  _construirCeldaGuiaTallas(
                    t.storeSizeGuideLength,
                    esCabecera: true,
                  ),
                ],
              ),
              for (final fila in _guiaTallas)
                TableRow(
                  children: [
                    _construirCeldaGuiaTallas(fila[0]),
                    _construirCeldaGuiaTallas(fila[1]),
                    _construirCeldaGuiaTallas(fila[2]),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirCeldaGuiaTallas(String texto, {bool esCabecera = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _colors.onSurface,
          fontWeight: esCabecera ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _construirFormularioCliente() {
    final t = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.storeCustomerDataTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.storeCustomerDataHint,
              style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreController,
              enabled: !_enviando,
              decoration: InputDecoration(
                labelText: t.storeFullNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonoController,
              enabled: !_enviando,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: t.storePhoneLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              enabled: !_enviando,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: t.storeEmailLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _aceptaPrivacidad,
                  onChanged: _enviando
                      ? null
                      : (valor) {
                          setState(() {
                            _aceptaPrivacidad = valor ?? false;
                          });
                        },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: _colors.onSurface,
                        ),
                        children: [
                          TextSpan(text: t.storePrivacyAcceptPrefix),
                          TextSpan(
                            text: t.storePrivacyPolicyLink,
                            style: const TextStyle(
                              color: AppColors.azul,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = _abrirPoliticaPrivacidad,
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _crearPedido,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_outward),
                label: Text(
                  _enviando ? t.storeSendingButton : t.storeCreateOrderButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
