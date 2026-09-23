import 'package:flutter/material.dart';

import '../../../core/widget/club_app_bar_title.dart';
import '../../teams/services/team_services.dart';
import '../models/destinatario_comunicacion_model.dart';
import '../models/perfil_app.dart';
import '../services/comunicacion_service.dart';
import '../services/perfil_service.dart';

/// A quién puede dirigirse una comunicación. Los tres modos son
/// excluyentes entre sí: un mensaje va a categorías, a equipos o a
/// una única persona en privado, nunca a una mezcla de los tres.
enum _ModoDestinatario { equipos, categorias, privado }

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

  _ModoDestinatario? _modoSeleccionado;

  final Set<int> _equiposSeleccionados = {};
  final Set<String> _categoriasSeleccionadas = {};
  int? _destinatarioSeleccionado;

  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  String _busquedaDestinatarios = '';

  ColorScheme get _colors => Theme.of(context).colorScheme;

  bool get _esEntrenador => _perfil?.tieneRol('ENTRENADOR') ?? false;

  bool get _esCoordinador => _perfil?.tieneRol('COORDINADOR') ?? false;

  bool get _esAdmin => _perfil?.tieneRol('ADMIN_APP') ?? false;

  bool get _puedeSeleccionarCategorias => _esCoordinador || _esAdmin;

  bool get _puedeSeleccionarEquipos =>
      (_esEntrenador || _esCoordinador || _esAdmin) &&
      _equiposDisponibles.isNotEmpty;

  bool get _puedeSeleccionarPrivado => _destinatariosDisponibles.isNotEmpty;

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

        // Los getters ya reflejan el perfil y las listas recién
        // asignadas arriba, así que reutilizamos exactamente la misma
        // lógica que decide qué modos se muestran en el selector.
        _modoSeleccionado = _modoPorDefecto(
          equipos: _puedeSeleccionarEquipos,
          categorias: _puedeSeleccionarCategorias,
          privado: _puedeSeleccionarPrivado,
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  /// El modo por defecto es el primero disponible, priorizando
  /// equipos (el caso más habitual: avisar al propio equipo) y
  /// dejando privado como última opción.
  _ModoDestinatario? _modoPorDefecto({
    required bool equipos,
    required bool categorias,
    required bool privado,
  }) {
    if (equipos) return _ModoDestinatario.equipos;
    if (categorias) return _ModoDestinatario.categorias;
    if (privado) return _ModoDestinatario.privado;
    return null;
  }

  bool _esRolGlobal(PerfilApp perfil) {
    return perfil.tieneRol('COORDINADOR') || perfil.tieneRol('ADMIN_APP');
  }

  void _cambiarModo(_ModoDestinatario modo) {
    if (_modoSeleccionado == modo) return;

    setState(() {
      _modoSeleccionado = modo;

      // Al cambiar de modo se descarta la selección anterior: un
      // mensaje solo puede ir a un tipo de destinatario.
      _equiposSeleccionados.clear();
      _categoriasSeleccionadas.clear();
      _destinatarioSeleccionado = null;
    });
  }

  Future<void> _guardar() async {
    if (_guardando) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final modo = _modoSeleccionado;

    if (modo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona a quién quieres escribir.')),
      );

      return;
    }

    switch (modo) {
      case _ModoDestinatario.equipos:
        if (_equiposSeleccionados.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecciona al menos un equipo.')),
          );
          return;
        }
        break;

      case _ModoDestinatario.categorias:
        if (_categoriasSeleccionadas.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecciona al menos una categoría.')),
          );
          return;
        }
        break;

      case _ModoDestinatario.privado:
        if (_destinatarioSeleccionado == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecciona un destinatario.')),
          );
          return;
        }
        break;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await ComunicacionService.crearComunicacion(
        titulo: modo == _ModoDestinatario.privado
            ? null
            : _tituloController.text,
        contenido: _contenidoController.text,
        equipoIds: modo == _ModoDestinatario.equipos
            ? _equiposSeleccionados.toList()
            : const [],
        categorias: modo == _ModoDestinatario.categorias
            ? _categoriasSeleccionadas.toList()
            : const [],
        destinatariosIds: modo == _ModoDestinatario.privado
            ? [_destinatarioSeleccionado!]
            : const [],
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

                _construirSelectorModo(),

                const SizedBox(height: 12),

                switch (_modoSeleccionado) {
                  _ModoDestinatario.equipos => _construirEquipos(),
                  _ModoDestinatario.categorias => _construirCategorias(),
                  _ModoDestinatario.privado => _construirDestinatariosDirectos(),
                  null => _construirSinModosDisponibles(),
                },
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
            if (_modoSeleccionado != _ModoDestinatario.privado) ...[
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
            ],

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

  Widget _construirSelectorModo() {
    final opciones = <ButtonSegment<_ModoDestinatario>>[
      if (_puedeSeleccionarEquipos)
        ButtonSegment(
          value: _ModoDestinatario.equipos,
          label: Text(
            _esEntrenador && !_esCoordinador && !_esAdmin
                ? 'Mis equipos'
                : 'Equipos',
          ),
          icon: const Icon(Icons.groups_outlined),
        ),
      if (_puedeSeleccionarCategorias)
        const ButtonSegment(
          value: _ModoDestinatario.categorias,
          label: Text('Categorías'),
          icon: Icon(Icons.category_outlined),
        ),
      if (_puedeSeleccionarPrivado)
        const ButtonSegment(
          value: _ModoDestinatario.privado,
          label: Text('Privado'),
          icon: Icon(Icons.person_outline),
        ),
    ];

    if (opciones.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_ModoDestinatario>(
        segments: opciones,
        selected: _modoSeleccionado == null ? {} : {_modoSeleccionado!},
        emptySelectionAllowed: true,
        onSelectionChanged: _guardando
            ? null
            : (seleccion) {
                if (seleccion.isNotEmpty) {
                  _cambiarModo(seleccion.first);
                }
              },
      ),
    );
  }

  Widget _construirSinModosDisponibles() {
    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          'No tienes ningún destinatario disponible para escribir una '
          'comunicación.',
          style: TextStyle(color: _colors.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _construirEquipos() {
    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'Elige uno o varios equipos.',
              style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
            ),
          ),

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
    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'Elige una o varias categorías.',
              style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
            ),
          ),

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
    final destinatariosFiltrados = _destinatariosFiltrados;

    return Card(
      margin: EdgeInsets.zero,
      color: _colors.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'Elige una única persona; el mensaje será privado solo '
              'para ella.',
              style: TextStyle(color: _colors.onSurfaceVariant, fontSize: 13),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
            RadioGroup<int>(
              groupValue: _destinatarioSeleccionado,
              onChanged: (seleccionado) {
                if (_guardando) return;

                setState(() {
                  _destinatarioSeleccionado = seleccionado;
                });
              },
              child: Column(
                children: destinatariosFiltrados
                    .map(
                      (destinatario) => RadioListTile<int>(
                        value: destinatario.id,
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
                    )
                    .toList(),
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
