import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/admin/models/admin_model.dart';
import 'package:app_mutxamel_cf/features/admin/pages/usuario_admin_page.dart';
import 'package:app_mutxamel_cf/features/admin/pages/usuarios_admin_page.dart';
import 'package:app_mutxamel_cf/features/admin/services/admin_service.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _admin = 1; // La cuenta que usa la app.

const _rolJugador = RolCuentaModel(codigo: 'JUGADOR', nombre: 'Jugador');
const _rolFamiliar = RolCuentaModel(codigo: 'FAMILIAR', nombre: 'Familiar');
const _rolRrss = RolCuentaModel(codigo: 'RRSS', nombre: 'Redes sociales');
const _rolRetrans = RolCuentaModel(
  codigo: 'RETRANSMISION',
  nombre: 'Retransmisión',
);
const _rolAdmin = RolCuentaModel(codigo: 'ADMIN_APP', nombre: 'Administrador');

UsuarioAdminModel _cuenta(
  int id,
  String email, {
  String? nombre,
  EstadoCuenta estado = EstadoCuenta.activa,
  List<RolCuentaModel> roles = const [],
  List<VinculoCuentaModel> vinculos = const [],
  DateTime? ultimoAcceso,
}) => UsuarioAdminModel(
  id: id,
  email: email,
  nombre: nombre,
  estado: estado,
  roles: roles,
  vinculos: vinculos,
  ultimoAcceso: ultimoAcceso,
);

List<UsuarioAdminModel> _cuentas() => [
  _cuenta(
    2,
    'ana.perez@x.es',
    nombre: 'Ana Pérez',
    roles: const [_rolRrss, _rolRetrans],
    ultimoAcceso: DateTime(2026, 11, 20, 9, 15),
  ),
  _cuenta(
    3,
    'luis@x.es',
    estado: EstadoCuenta.pendiente,
    roles: const [_rolJugador],
    vinculos: const [
      VinculoCuentaModel(
        tipo: 'JUGADOR',
        personaId: 9,
        nombre: 'Luis Mas',
        detalle: 'Alevín A',
      ),
    ],
  ),
  _cuenta(
    4,
    'marta@x.es',
    nombre: 'Marta',
    estado: EstadoCuenta.caducada,
    roles: const [_rolFamiliar],
    vinculos: const [
      VinculoCuentaModel(tipo: 'FAMILIAR', personaId: 5, nombre: 'Marta Gil'),
    ],
  ),
  _cuenta(
    5,
    'pepe@x.es',
    nombre: 'Pepe',
    estado: EstadoCuenta.desactivada,
    roles: const [_rolRrss],
  ),
  _cuenta(6, 'sinroles@x.es', nombre: 'Sin Roles'),
  _cuenta(7, 'otroadmin@x.es', nombre: 'Otro Admin', roles: const [_rolAdmin]),
  _cuenta(_admin, 'yo@x.es', nombre: 'Yo Mismo', roles: const [_rolAdmin]),
];

class _FakeUsuarios extends AdminService {
  List<UsuarioAdminModel> cuentas = _cuentas();
  final List<String> llamadas = [];
  Object? fallo;

  VinculosDisponiblesModel opciones = const VinculosDisponiblesModel(
    jugadores: [
      PersonaDisponibleModel(
        tipo: TipoVinculo.jugador,
        id: 21,
        nombre: 'Pablo García',
        detalle: 'Cadete A',
      ),
      PersonaDisponibleModel(
        tipo: TipoVinculo.jugador,
        id: 22,
        nombre: 'Luis López',
        detalle: 'Cadete B',
      ),
    ],
    familiares: [
      PersonaDisponibleModel(
        tipo: TipoVinculo.familiar,
        id: 31,
        nombre: 'Marta Gil',
      ),
    ],
    cuerpoTecnico: [
      PersonaDisponibleModel(
        tipo: TipoVinculo.cuerpoTecnico,
        id: 41,
        nombre: 'Ana Ruiz',
        detalle: 'Alevín',
      ),
    ],
    roles: [
      RolDisponibleModel(codigo: 'COORDINADOR', nombre: 'Coordinador'),
      RolDisponibleModel(codigo: 'RETRANSMISION', nombre: 'Retransmisión'),
      RolDisponibleModel(codigo: 'RRSS', nombre: 'Redes sociales'),
    ],
  );

  void _registrar(String llamada) {
    llamadas.add(llamada);

    if (fallo != null) throw fallo!;
  }

  void _cambiar(int id, UsuarioAdminModel Function(UsuarioAdminModel) f) {
    cuentas = [for (final u in cuentas) u.id == id ? f(u) : u];
  }

  UsuarioAdminModel _conEstado(UsuarioAdminModel u, EstadoCuenta e) =>
      UsuarioAdminModel(
        id: u.id,
        email: u.email,
        nombre: u.nombre,
        estado: e,
        roles: u.roles,
        vinculos: u.vinculos,
        ultimoAcceso: u.ultimoAcceso,
      );

  @override
  Future<List<UsuarioAdminModel>> obtenerUsuarios() async => [...cuentas];

  @override
  Future<VinculosDisponiblesModel> obtenerVinculosDisponibles() async =>
      opciones;

  @override
  Future<void> actualizarNombreUsuario(
    int id, {
    required String nombre,
    String? apellidos,
  }) async {
    _registrar('nombre:$id:$nombre:${apellidos ?? ''}');
    _cambiar(id, (u) => u.conNombre('$nombre ${apellidos ?? ''}'.trim()));
  }

  @override
  Future<void> anadirVinculoUsuario(
    int id,
    PersonaDisponibleModel persona,
  ) async {
    _registrar('vinculo:$id:${persona.tipo.codigo}:${persona.id}');
  }

  @override
  Future<void> anadirRolUsuario(int id, String codigoRol) async {
    _registrar('rol:$id:$codigoRol');
    _cambiar(
      id,
      (u) => UsuarioAdminModel(
        id: u.id,
        email: u.email,
        nombre: u.nombre,
        estado: u.estado,
        roles: [
          ...u.roles,
          RolCuentaModel(codigo: codigoRol, nombre: codigoRol),
        ],
        vinculos: u.vinculos,
      ),
    );
  }

  @override
  Future<void> quitarVinculoUsuario(
    int id, {
    required String tipo,
    int? personaId,
  }) async {
    _registrar('quitar:$id:$tipo:${personaId ?? ''}');
  }

  @override
  Future<String> reenviarUsuario(int id) async {
    _registrar('reenviar:$id');

    return '';
  }

  @override
  Future<void> activarUsuario(int id) async {
    _registrar('activar:$id');
    _cambiar(id, (u) => _conEstado(u, EstadoCuenta.activa));
  }

  @override
  Future<void> desactivarUsuario(int id) async {
    _registrar('desactivar:$id');
    _cambiar(id, (u) => _conEstado(u, EstadoCuenta.desactivada));
  }

  @override
  Future<void> eliminarUsuario(int id) async {
    _registrar('eliminar:$id');
    cuentas = cuentas.where((u) => u.id != id).toList();
  }
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('es'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Future<void> _pintarLista(
  WidgetTester tester,
  _FakeUsuarios servicio, {
  EstadoCuenta? estado,
}) async {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    _app(
      UsuariosAdminPage(
        servicio: servicio,
        usuarioActualId: _admin,
        estadoInicial: estado,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pintarFicha(
  WidgetTester tester,
  _FakeUsuarios servicio,
  int id,
) async {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    _app(
      UsuarioAdminPage(
        usuario: servicio.cuentas.firstWhere((u) => u.id == id),
        servicio: servicio,
        usuarioActualId: _admin,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _contador(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('contador-cuentas'))).data!;

Future<void> _elegirEnDesplegable(
  WidgetTester tester,
  String clave,
  String opcion,
) async {
  await tester.tap(
    find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey &&
          (w.key as ValueKey).value.toString().startsWith(clave),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcion).last);
  await tester.pumpAndSettle();
}

void main() {
  group('la lista de usuarios', () {
    testWidgets('trae todas las cuentas, el contador y los datos de cada una', (
      tester,
    ) async {
      await _pintarLista(tester, _FakeUsuarios());

      expect(_contador(tester), '7 de 7 cuentas');
      // Los roles con su nombre, no con el código.
      expect(find.text('Redes sociales'), findsWidgets);
      expect(find.text('Retransmisión'), findsWidgets);
      expect(find.text('RRSS'), findsNothing);
      // Estados con su insignia.
      expect(find.byKey(const ValueKey('estado-ACTIVA')), findsWidgets);
      expect(find.byKey(const ValueKey('estado-PENDIENTE')), findsOneWidget);
      expect(find.byKey(const ValueKey('estado-CADUCADA')), findsOneWidget);
      expect(find.byKey(const ValueKey('estado-DESACTIVADA')), findsOneWidget);
      expect(find.text('Pendiente de activar'), findsWidgets);
      expect(find.text('Invitación caducada'), findsWidgets);
      // Último acceso, y "todavía no ha entrado" si no lo hay.
      expect(find.text('Último acceso: 20/11/2026 09:15'), findsOneWidget);
      expect(find.text('Todavía no ha entrado'), findsWidgets);
    });

    testWidgets(
      'el buscador filtra por nombre o email, sin mayúsculas ni acentos',
      (tester) async {
        await _pintarLista(tester, _FakeUsuarios());

        await tester.enterText(
          find.byKey(const ValueKey('buscar-usuarios')),
          'PEREZ',
        );
        await tester.pumpAndSettle();

        expect(_contador(tester), '1 de 7 cuentas');
        expect(find.byKey(const ValueKey('cuenta-2')), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('buscar-usuarios')),
          'luis@',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('cuenta-3')), findsOneWidget);
        expect(_contador(tester), '1 de 7 cuentas');

        // Busca en nombre y email, no en los roles.
        await tester.enterText(
          find.byKey(const ValueKey('buscar-usuarios')),
          'redes',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('sin-resultados')), findsOneWidget);
        expect(find.text('Ninguna cuenta cumple los filtros'), findsOneWidget);
      },
    );

    testWidgets(
      'el filtro de Rol incluye "Sin roles" y el de Estado sus cuatro estados',
      (tester) async {
        await _pintarLista(tester, _FakeUsuarios());

        await _elegirEnDesplegable(tester, 'filtro-rol', 'Redes sociales');
        expect(_contador(tester), '2 de 7 cuentas');
        expect(find.byKey(const ValueKey('cuenta-2')), findsOneWidget);
        expect(find.byKey(const ValueKey('cuenta-5')), findsOneWidget);

        await _elegirEnDesplegable(tester, 'filtro-rol', 'Sin roles');
        expect(_contador(tester), '1 de 7 cuentas');
        expect(find.byKey(const ValueKey('cuenta-6')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('limpiar-filtros')));
        await tester.pumpAndSettle();
        expect(_contador(tester), '7 de 7 cuentas');

        for (final caso in {
          'Activa': 4,
          'Pendiente de activar': 1,
          'Invitación caducada': 1,
          'Desactivada': 1,
        }.entries) {
          await _elegirEnDesplegable(tester, 'filtro-estado', caso.key);
          expect(
            _contador(tester),
            '${caso.value} de 7 cuentas',
            reason: caso.key,
          );
        }
      },
    );

    testWidgets('los tres filtros se combinan y "Limpiar filtros" los quita', (
      tester,
    ) async {
      await _pintarLista(tester, _FakeUsuarios());

      await _elegirEnDesplegable(tester, 'filtro-rol', 'Redes sociales');
      await _elegirEnDesplegable(tester, 'filtro-estado', 'Desactivada');
      expect(_contador(tester), '1 de 7 cuentas');
      expect(find.byKey(const ValueKey('cuenta-5')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('buscar-usuarios')),
        'ana',
      );
      await tester.pumpAndSettle();
      expect(_contador(tester), '0 de 7 cuentas');

      await tester.tap(find.byKey(const ValueKey('limpiar-filtros')));
      await tester.pumpAndSettle();
      expect(_contador(tester), '7 de 7 cuentas');
      expect(find.byKey(const ValueKey('limpiar-filtros')), findsNothing);
    });

    testWidgets(
      'con un aviso de cuentas pendientes se abre ya filtrada por Pendiente',
      (tester) async {
        await _pintarLista(
          tester,
          _FakeUsuarios(),
          estado: EstadoCuenta.pendiente,
        );

        expect(_contador(tester), '1 de 7 cuentas');
        expect(find.byKey(const ValueKey('cuenta-3')), findsOneWidget);
        expect(find.byKey(const ValueKey('limpiar-filtros')), findsOneWidget);
      },
    );

    testWidgets('con letra grande en un iPhone pequeño no se desborda', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        _app(
          UsuariosAdminPage(servicio: _FakeUsuarios(), usuarioActualId: _admin),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('un error al cargar enseña el reintento', (tester) async {
      final servicio = _FakeUsuarios();

      await tester.pumpWidget(
        _app(
          UsuariosAdminPage(
            servicio: _FallaAlCargar(),
            usuarioActualId: _admin,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
      expect(servicio.llamadas, isEmpty);
    });
  });

  group('la ficha de una cuenta', () {
    testWidgets('sin ficha vinculada se edita el nombre', (tester) async {
      final servicio = _FakeUsuarios();

      await _pintarFicha(tester, servicio, 6);
      await tester.tap(find.byKey(const ValueKey('editar-nombre-boton')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('editar-nombre')),
        'Rosa',
      );
      await tester.enterText(
        find.byKey(const ValueKey('editar-apellidos')),
        'Gil',
      );
      await tester.tap(find.byKey(const ValueKey('guardar-nombre')));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, ['nombre:6:Rosa:Gil']);
      expect(find.text('Nombre actualizado.'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('ficha-nombre'))).data,
        'Rosa Gil',
      );
    });

    testWidgets('con ficha vinculada el nombre sale de ella y no se edita', (
      tester,
    ) async {
      await _pintarFicha(tester, _FakeUsuarios(), 3);

      expect(find.byKey(const ValueKey('editar-nombre-boton')), findsNothing);
      expect(
        find.text('El nombre sale de su ficha vinculada.'),
        findsOneWidget,
      );
      expect(find.text('Luis Mas'), findsWidgets);
    });

    testWidgets(
      'añade un rol sin persona; ADMIN_APP no se ofrece y los que ya tiene tampoco',
      (tester) async {
        final servicio = _FakeUsuarios();

        await _pintarFicha(
          tester,
          servicio,
          5,
        ); // Pepe ya tiene Redes sociales.
        await tester.tap(find.byKey(const ValueKey('anadir-vinculo')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('anadir-rol-COORDINADOR')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('anadir-rol-RETRANSMISION')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('anadir-rol-RRSS')), findsNothing);
        expect(
          find.byKey(const ValueKey('anadir-rol-ADMIN_APP')),
          findsNothing,
        );
        expect(find.text('Administrador'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('anadir-rol-COORDINADOR')));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, ['rol:5:COORDINADOR']);
        expect(find.text('Vínculo o rol añadido.'), findsOneWidget);
      },
    );

    testWidgets(
      'vincula a un jugador eligiéndolo en el selector con buscador',
      (tester) async {
        final servicio = _FakeUsuarios();

        await _pintarFicha(tester, servicio, 5);
        await tester.tap(find.byKey(const ValueKey('anadir-vinculo')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('anadir-tipo-JUGADOR')));
        await tester.pumpAndSettle();

        expect(find.text('Pablo García'), findsOneWidget);
        expect(find.text('Luis López'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('buscar-persona')),
          'lopez',
        );
        await tester.pumpAndSettle();
        expect(find.text('Pablo García'), findsNothing);

        await tester.tap(find.byKey(const ValueKey('persona-JUGADOR-22')));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, ['vinculo:5:JUGADOR:22']);
      },
    );

    testWidgets('quita un vínculo y un rol, pidiendo confirmación', (
      tester,
    ) async {
      final servicio = _FakeUsuarios();

      await _pintarFicha(
        tester,
        servicio,
        2,
      ); // Redes sociales y Retransmisión.
      await tester.tap(find.byKey(const ValueKey('quitar-rol-RRSS')));
      await tester.pumpAndSettle();
      expect(
        find.text('¿Quitar «Redes sociales» de esta cuenta?'),
        findsOneWidget,
      );

      // Cancelar no quita nada.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(servicio.llamadas, isEmpty);

      await tester.tap(find.byKey(const ValueKey('quitar-rol-RRSS')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar-accion')));
      await tester.pumpAndSettle();
      expect(servicio.llamadas, ['quitar:2:RRSS:']);

      // Otra ficha: se vuelve a montar desde cero.
      await tester.pumpWidget(const SizedBox());
      await _pintarFicha(tester, servicio, 3);
      await tester.tap(find.byKey(const ValueKey('quitar-vinculo-JUGADOR-9')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar-accion')));
      await tester.pumpAndSettle();
      expect(servicio.llamadas.last, 'quitar:3:JUGADOR:9');
    });

    testWidgets(
      'activar una cuenta pendiente pide confirmación y la deja activa',
      (tester) async {
        final servicio = _FakeUsuarios();

        await _pintarFicha(tester, servicio, 3);
        await tester.tap(find.byKey(const ValueKey('activar')));
        await tester.pumpAndSettle();
        expect(
          find.text('¿Activar la cuenta de luis@x.es? Podrá entrar en la app.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(servicio.llamadas, isEmpty);

        await tester.tap(find.byKey(const ValueKey('activar')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirmar-accion')));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, ['activar:3']);
        expect(find.text('Cuenta activada.'), findsOneWidget);
        // La ficha se refresca: ahora está activa y ofrece desactivar.
        expect(find.byKey(const ValueKey('estado-ACTIVA')), findsOneWidget);
        expect(find.byKey(const ValueKey('desactivar')), findsOneWidget);
        expect(find.byKey(const ValueKey('activar')), findsNothing);
      },
    );

    testWidgets('desactivar una cuenta activa pide confirmación', (
      tester,
    ) async {
      final servicio = _FakeUsuarios();

      await _pintarFicha(tester, servicio, 2);
      expect(find.byKey(const ValueKey('activar')), findsNothing);
      expect(find.byKey(const ValueKey('eliminar')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('desactivar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar-accion')));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, ['desactivar:2']);
      expect(find.byKey(const ValueKey('estado-DESACTIVADA')), findsOneWidget);
    });

    testWidgets(
      'reenvía la invitación y avisa; un 429 enseña el mensaje del servidor',
      (tester) async {
        final servicio = _FakeUsuarios();

        await _pintarFicha(tester, servicio, 3);
        await tester.tap(find.byKey(const ValueKey('reenviar')));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, ['reenviar:3']);
        expect(find.text('Invitación reenviada a luis@x.es'), findsOneWidget);

        // Que el primer aviso termine de mostrarse antes de provocar el error.
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();

        servicio.fallo = const ApiException(
          'Ya se reenvió la activación a este usuario hace poco. Inténtalo de nuevo en 10 min.',
          statusCode: 429,
        );
        await tester.tap(find.byKey(const ValueKey('reenviar')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Inténtalo de nuevo en 10 min'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'elimina una invitación sin activar con confirmación y vuelve a la lista',
      (tester) async {
        final servicio = _FakeUsuarios();

        await _pintarLista(tester, servicio);
        await tester.tap(find.byKey(const ValueKey('cuenta-3')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('eliminar')));
        await tester.pumpAndSettle();
        expect(
          find.text(
            '¿Eliminar la invitación de luis@x.es? Se borra la cuenta sin activar.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('confirmar-accion')));
        await tester.pumpAndSettle();

        expect(servicio.llamadas, ['eliminar:3']);
        // De vuelta en la lista, ya sin esa cuenta y con el contador al día.
        expect(find.byType(UsuariosAdminPage), findsOneWidget);
        expect(find.byKey(const ValueKey('cuenta-3')), findsNothing);
        expect(_contador(tester), '6 de 6 cuentas');
      },
    );

    testWidgets('una cuenta activa no ofrece eliminar', (tester) async {
      await _pintarFicha(tester, _FakeUsuarios(), 6);

      expect(find.byKey(const ValueKey('eliminar')), findsNothing);
    });

    testWidgets(
      'al volver a la lista, esta se recarga y mantiene los filtros',
      (tester) async {
        final servicio = _FakeUsuarios();

        await _pintarLista(tester, servicio);
        await _elegirEnDesplegable(
          tester,
          'filtro-estado',
          'Pendiente de activar',
        );
        expect(_contador(tester), '1 de 7 cuentas');

        await tester.tap(find.byKey(const ValueKey('cuenta-3')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('activar')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirmar-accion')));
        await tester.pumpAndSettle();

        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();

        // Sigue filtrando por Pendiente y ya no queda ninguna.
        expect(_contador(tester), '0 de 7 cuentas');
        expect(find.byKey(const ValueKey('limpiar-filtros')), findsOneWidget);
      },
    );
  });

  group('las reglas de administrador', () {
    testWidgets('la cuenta propia se ve pero no se toca: sin botones', (
      tester,
    ) async {
      await _pintarFicha(tester, _FakeUsuarios(), _admin);

      expect(find.byKey(const ValueKey('solo-lectura')), findsOneWidget);
      expect(
        find.text('Es tu cuenta: no se puede modificar desde aquí.'),
        findsOneWidget,
      );
      for (final clave in [
        'desactivar',
        'activar',
        'eliminar',
        'reenviar',
        'anadir-vinculo',
        'editar-nombre-boton',
        'quitar-rol-ADMIN_APP',
      ]) {
        expect(find.byKey(ValueKey(clave)), findsNothing, reason: clave);
      }
    });

    testWidgets('la cuenta de otro administrador tampoco: sin botones', (
      tester,
    ) async {
      await _pintarFicha(tester, _FakeUsuarios(), 7);

      expect(
        find.text(
          'Es una cuenta de administrador: no se puede modificar desde la app.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('desactivar')), findsNothing);
      expect(find.byKey(const ValueKey('anadir-vinculo')), findsNothing);
      expect(find.byKey(const ValueKey('quitar-rol-ADMIN_APP')), findsNothing);
      // El rol se ve, solo que no se puede quitar.
      expect(find.text('Administrador'), findsWidgets);
    });

    testWidgets('si el servidor responde 403, se muestra su mensaje', (
      tester,
    ) async {
      final servicio = _FakeUsuarios();

      await _pintarFicha(tester, servicio, 2);
      servicio.fallo = const ApiException(
        'No se puede desactivar a un administrador',
        statusCode: 403,
      );

      await tester.tap(find.byKey(const ValueKey('desactivar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirmar-accion')));
      await tester.pumpAndSettle();

      expect(
        find.text('No se puede desactivar a un administrador'),
        findsOneWidget,
      );
      expect(find.text('No tienes permiso'), findsNothing);
    });
  });
}

class _FallaAlCargar extends AdminService {
  @override
  Future<List<UsuarioAdminModel>> obtenerUsuarios() async =>
      throw const ApiException('No hay conexión a internet.');
}
