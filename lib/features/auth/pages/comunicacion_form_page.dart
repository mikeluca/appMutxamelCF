import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../teams/services/team_services.dart';
import '../models/destinatario_comunicacion_model.dart';
import '../models/perfil_app.dart';
import '../services/comunicacion_service.dart';
import '../services/perfil_service.dart';

class ComunicacionFormPage extends StatefulWidget {
  const ComunicacionFormPage({super.key});

  @override
  State<ComunicacionFormPage> createState() => _ComunicacionFormPageState();
}

class _ComunicacionFormPageState extends State<ComunicacionFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tituloController = TextEditingController();

  final TextEditingController _contenidoController = TextEditingController();

  final TextEditingController _buscadorDestinatariosController =
      TextEditingController();

  final TeamService _teamService = TeamService();

  PerfilApp? _perfil;

  List<PerfilEquipo> _equiposDisponibles = [];
  List<String> _categoriasDisponibles = [];
  List<DestinatarioComunicacionModel> _destinatariosDisponibles = [];

  final Set<int> _equiposSeleccionados = {};
  final Set<String> _categoriasSeleccionadas = {};
  final Set<int> _destinatariosSeleccionados = {};

  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  String _busquedaDestinatarios = '';

  ColorScheme get _colors => Theme.of(context).colorScheme;

  bool get _esEntrenador => _perfil?.tieneRol('ENTRENADOR') ?? false;

  bool get _esCoordinador => _perfil?.tieneRol('COORDINADOR') ?? false;

  bool get _esAdmin => _perfil?.tieneRol('ADMIN_APP') ?? false;

  bool get _puedeSeleccionarCategorias => _esCoordinador || _esAdmin;

  List<DestinatarioComunicacionModel> get _destinatariosFiltrados {
    final texto = _busquedaDestinatarios.trim().toLowerCase();

    if (texto.isEmpty) {
      return _destinatariosDisponibles;
    }

    return _destinatariosDisponibles.where((destinatario) {
      final nombre = destinatario.nombreCompleto.toLowerCase();

      final rol = destinatario.rol.toLowerCase();

      return nombre.contains(texto) || rol.contains(texto);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _buscadorDestinatariosController.addListener(
      _actualizarBusquedaDestinatarios,
    );

    _cargarDatos();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    _buscadorDestinatariosController.dispose();

    super.dispose();
  }

  void _actualizarBusquedaDestinatarios() {
    if (!mounted) return;

    setState(() {
      _busquedaDestinatarios = _buscadorDestinatariosController.text;
    });
  }

  Future<void> _cargarDatos() async {
    try {
      final perfil = await PerfilService.obtenerPerfil();

      final destinatarios =
          await ComunicacionService.obtenerDestinatariosDirectos();

      List<PerfilEquipo> equipos;

      if (_esRolGlobal(perfil)) {
        final todosLosEquipos = await _teamService.obtenerEquipos();

        equipos = todosLosEquipos
            .map(
              (equipo) => PerfilEquipo(
                id: equipo.id,
                nombre: equipo.nombre,
                categoria: equipo.categoria,
                grupo: equipo.grupo,
                deporte: equipo.deporte,
              ),
            )
            .toList();
      } else {
        equipos = perfil.equipos;
      }

      /*
       * Las categorías se generan siguiendo el orden de los
       * equipos, en lugar de ordenarlas alfabéticamente.
       *
       * De esta forma, si los equipos vienen ordenados:
       *
       * Infantil
       * Cadete
       * Juvenil
       *
       * las categorías mantendrán ese mismo orden.
       */
      final categorias = <String>[];
      final categoriasVistas = <String>{};

      for (final equipo in equipos) {
        final categoria = equipo.categoria?.trim();

        if (categoria != null &&
            categoria.isNotEmpty &&
            categoriasVistas.add(categoria)) {
          categorias.add(categoria);
        }
      }

      if (!mounted) return;

      setState(() {
        _perfil = perfil;
        _equiposDisponibles = equipos;
        _categoriasDisponibles = categorias;
        _destinatariosDisponibles = destinatarios;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  bool _esRolGlobal(PerfilApp perfil) {
    return perfil.tieneRol('COORDINADOR') || perfil.tieneRol('ADMIN_APP');
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_equiposSeleccionados.isEmpty &&
        _categoriasSeleccionadas.isEmpty &&
        _destinatariosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes seleccionar al menos un equipo, una categoría '
            'o un destinatario.',
          ),
        ),
      );

      return;
    }

    /*
     * Los entrenadores necesitan seleccionar al menos un equipo
     * cuando utilizan la comunicación por equipos/categorías.
     *
     * Si envían únicamente a destinatarios directos, esa
     * selección no es necesaria.
     */
    if (_esEntrenador &&
        _equiposSeleccionados.isEmpty &&
        _categoriasSeleccionadas.isEmpty &&
        _destinatariosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes seleccionar al menos un equipo, '
            'una categoría o un destinatario.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await ComunicacionService.crearComunicacion(
        titulo: _tituloController.text,
        contenido: _contenidoController.text,
        equipoIds: _equiposSeleccionados.toList(),
        categorias: _categoriasSeleccionadas.toList(),
        destinatariosIds: _destinatariosSeleccionados.toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comunicación creada correctamente.')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se ha podido crear la comunicación: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ClubAppBarTitle(titulo: 'Nueva comunicación'),
      ),
      body: _construirContenido(),
    );
  }

  Widget _construirContenido() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _construirError();
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              children: [
                _construirCamposTexto(),

                const SizedBox(height: 24),

                _construirTituloDestinatarios(),

                const SizedBox(height: 12),

                if (_esEntrenador || _esCoordinador || _esAdmin) ...[
                  _construirEquipos(),
                ],

                if (_puedeSeleccionarCategorias) ...[
                  const SizedBox(height: 12),
                  _construirCategorias(),
                ],

                const SizedBox(height: 12),

                _construirDestinatariosDirectos(),
              ],
            ),
          ),

          _construirBotonGuardar(),
        ],
      ),
    );
  }

  Widget _construirCamposTexto() {
    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextFormField(
              controller: _tituloController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Escribe el título',
                prefixIcon: Icon(Icons.title_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El título es obligatorio.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _contenidoController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 6,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Mensaje',
                hintText: 'Escribe el contenido de la comunicación',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 90),
                  child: Icon(Icons.message_outlined),
                ),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El mensaje es obligatorio.';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTituloDestinatarios() {
    return Text(
      'Destinatarios',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _colors.onSurface,
      ),
    );
  }

  Widget _construirEquipos() {
    if (_equiposDisponibles.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        color: _colors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'No hay equipos disponibles.',
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        enabled: !_guardando,
        leading: Icon(Icons.groups_outlined, color: _colors.primary),
        title: Text(
          _esEntrenador ? 'Mis equipos' : 'Equipos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _colors.onSurface,
          ),
        ),
        subtitle: _equiposSeleccionados.isEmpty
            ? null
            : Text('${_equiposSeleccionados.length} seleccionado(s)'),
        children: [
          const Divider(height: 1),

          ..._equiposDisponibles.map(
            (equipo) => CheckboxListTile(
              value: _equiposSeleccionados.contains(equipo.id),
              onChanged: _guardando
                  ? null
                  : (seleccionado) {
                      setState(() {
                        if (seleccionado == true) {
                          _equiposSeleccionados.add(equipo.id);
                        } else {
                          _equiposSeleccionados.remove(equipo.id);
                        }
                      });
                    },

              // SOLO mostramos el nombre del equipo.
              title: Text(
                equipo.nombre,
                style: TextStyle(
                  color: _colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),

              controlAffinity: ListTileControlAffinity.leading,

              activeColor: _colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCategorias() {
    if (_categoriasDisponibles.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        color: _colors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'No hay categorías disponibles.',
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        enabled: !_guardando,
        leading: Icon(Icons.category_outlined, color: _colors.primary),
        title: Text(
          'Categorías',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _colors.onSurface,
          ),
        ),
        subtitle: _categoriasSeleccionadas.isEmpty
            ? null
            : Text(
                '${_categoriasSeleccionadas.length} '
                'seleccionada(s)',
              ),
        children: [
          const Divider(height: 1),

          ..._categoriasDisponibles.map(
            (categoria) => CheckboxListTile(
              value: _categoriasSeleccionadas.contains(categoria),
              onChanged: _guardando
                  ? null
                  : (seleccionada) {
                      setState(() {
                        if (seleccionada == true) {
                          _categoriasSeleccionadas.add(categoria);
                        } else {
                          _categoriasSeleccionadas.remove(categoria);
                        }
                      });
                    },
              title: Text(
                categoria,
                style: TextStyle(
                  color: _colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: _colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirDestinatariosDirectos() {
    if (_destinatariosDisponibles.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        color: _colors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            'No hay destinatarios directos disponibles.',
            style: TextStyle(color: _colors.onSurfaceVariant),
          ),
        ),
      );
    }

    final destinatariosFiltrados = _destinatariosFiltrados;

    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        enabled: !_guardando,
        leading: Icon(Icons.person_outline, color: _colors.primary),
        title: Text(
          'Destinatarios directos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _colors.onSurface,
          ),
        ),
        subtitle: _destinatariosSeleccionados.isEmpty
            ? null
            : Text(
                '${_destinatariosSeleccionados.length} '
                'seleccionado(s)',
              ),
        children: [
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _buscadorDestinatariosController,
              enabled: !_guardando,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Buscar destinatario',
                hintText: 'Nombre o apellidos',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busquedaDestinatarios.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _guardando
                            ? null
                            : () {
                                _buscadorDestinatariosController.clear();
                              },
                        icon: const Icon(Icons.clear),
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          if (destinatariosFiltrados.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'No se han encontrado destinatarios.',
                style: TextStyle(color: _colors.onSurfaceVariant),
              ),
            )
          else
            ...destinatariosFiltrados.map(
              (destinatario) => CheckboxListTile(
                value: _destinatariosSeleccionados.contains(destinatario.id),
                onChanged: _guardando
                    ? null
                    : (seleccionado) {
                        setState(() {
                          if (seleccionado == true) {
                            _destinatariosSeleccionados.add(destinatario.id);
                          } else {
                            _destinatariosSeleccionados.remove(destinatario.id);
                          }
                        });
                      },
                title: Text(
                  destinatario.nombreCompleto,
                  style: TextStyle(
                    color: _colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  destinatario.rol,
                  style: TextStyle(color: _colors.onSurfaceVariant),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _colors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _construirBotonGuardar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: _colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_guardando ? 'Guardando...' : 'Guardar comunicación'),
          ),
        ),
      ),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: _colors.error),
            const SizedBox(height: 16),
            Text(
              'No se han podido cargar los destinatarios.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: _colors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _error = null;
                });

                _cargarDatos();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
