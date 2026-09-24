import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/club_app_bar_title.dart';
import '../models/tienda_pedido_item.dart';
import '../services/tienda_service.dart';

class _ProductoTienda {
  /// Valor EXACTO que espera el backend en el campo 'prenda'.
  final String prenda;
  final String titulo;
  final String precio;
  final String descripcion;
  final String imagenUrl;
  final String? nota;

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
        titulo: 'Camiseta oficial',
        precio: '30 €',
        descripcion:
            'La esencia del Mutxamel CF, un año más, vestida de azul. '
            'Nuestra primera equipación combina la tradición y la '
            'identidad del club con un diseño moderno.',
        // El nombre exacto del fichero en el servidor lleva tilde
        // en la "o" (no en la "i"): segunda_equipacón.jpeg.
        imagenUrl: '${AppConfig.mediaBaseUrl}/images/primera_equipacion.jpeg',
      ),
      _ProductoTienda(
        prenda: 'Segunda equipacion - colaboracion AECC',
        titulo: 'Segunda equipación',
        precio: '30 €',
        descripcion:
            'Mucho más que una camiseta. Nuestra segunda equipación, de '
            'color rosa, nace de una colaboración muy especial con la '
            'Asociación Española Contra el Cáncer, uniendo deporte, '
            'compromiso y solidaridad.',
        imagenUrl: Uri.encodeFull(
          '${AppConfig.mediaBaseUrl}/images/segunda_equipacón.jpeg',
        ),
        nota: 'Colaboración con la Asociación Española Contra el Cáncer',
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

    if (nombre.isEmpty) {
      _mostrarError('Introduce tu nombre y apellidos.');
      return;
    }

    final emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!emailValido) {
      _mostrarError('Introduce un email válido.');
      return;
    }

    if (!_aceptaPrivacidad) {
      _mostrarError('Debes aceptar la política de privacidad.');
      return;
    }

    final items = <TiendaPedidoItem>[];

    for (final producto in _productos) {
      final cantidad = _cantidades[producto.prenda] ?? 0;

      if (cantidad <= 0) continue;

      final tallas = _tallasSeleccionadas[producto.prenda]!;

      if (tallas.any((talla) => talla == null || talla.isEmpty)) {
        _mostrarError(
          'Selecciona la talla de cada unidad de "${producto.titulo}".',
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
      _mostrarError('Selecciona al menos una prenda y sus unidades.');
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
        const SnackBar(
          content: Text(
            'Pedido enviado. Nos pondremos en contacto contigo para '
            'confirmar el pago y la recogida/envío.',
          ),
          duration: Duration(seconds: 5),
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
      appBar: AppBar(title: ClubAppBarTitle(titulo: 'Tienda')),
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
          const Text(
            'MUTXAMEL CF',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Viste los colores',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'La nueva colección del club ya está aquí. Elige tu prenda, '
            'selecciona tus tallas y haznos llegar tu pedido.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaProducto(_ProductoTienda producto) {
    final cantidad = _cantidades[producto.prenda] ?? 0;

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
                        producto.titulo,
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
                  producto.descripcion,
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
                          producto.nota!,
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
                      'Unidades',
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
                labelText: 'Talla unidad ${i + 1}',
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
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guía de tallas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mide una prenda que te quede bien y compara con estas '
              'medidas aproximadas.',
              style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 36,
                columns: const [
                  DataColumn(label: Text('Talla')),
                  DataColumn(label: Text('Pecho (cm)')),
                  DataColumn(label: Text('Largo (cm)')),
                ],
                rows: _guiaTallas
                    .map(
                      (fila) => DataRow(
                        cells: fila
                            .map((valor) => DataCell(Text(valor)))
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirFormularioCliente() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tus datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Te escribiremos para confirmar disponibilidad y forma de pago.',
              style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreController,
              enabled: !_enviando,
              decoration: const InputDecoration(
                labelText: 'Nombre y apellidos',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _telefonoController,
              enabled: !_enviando,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              enabled: !_enviando,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
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
                          const TextSpan(
                            text: 'Acepto el tratamiento de mis datos '
                                'según la ',
                          ),
                          TextSpan(
                            text: 'política de privacidad',
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
                label: Text(_enviando ? 'Enviando...' : 'CREAR PEDIDO'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
