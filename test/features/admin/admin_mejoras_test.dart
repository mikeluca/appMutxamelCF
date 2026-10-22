import 'dart:convert';

import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/admin/models/admin_model.dart';
import 'package:app_mutxamel_cf/features/admin/pages/cuentas_pendientes_page.dart';
import 'package:app_mutxamel_cf/features/admin/pages/estado_app_page.dart';
import 'package:app_mutxamel_cf/features/admin/pages/invitar_usuario_page.dart';
import 'package:app_mutxamel_cf/features/admin/pages/moderacion_page.dart';
import 'package:app_mutxamel_cf/features/admin/services/admin_service.dart';
import 'package:app_mutxamel_cf/features/auth/models/login_response.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_session.dart';
import 'package:app_mutxamel_cf/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../support/http_test_helpers.dart';

const _pablo = PersonaDisponibleModel(
  tipo: TipoVinculo.jugador,
  id: 1,
  nombre: 'Pablo Garcia',
  detalle: 'Cadete A',
);
const _luis = PersonaDisponibleModel(
  tipo: TipoVinculo.jugador,
  id: 2,
  nombre: 'Luis Lopez',
  detalle: 'Cadete B',
);
const _marta = PersonaDisponibleModel(
  tipo: TipoVinculo.familiar,
  id: 3,
  nombre: 'Marta Gil',
  detalle: 'Pablo Garcia',
);
const _ana = PersonaDisponibleModel(
  tipo: TipoVinculo.cuerpoTecnico,
  id: 4,
  nombre: 'Ana Ruiz',
  detalle: 'Alevín',
);

class _FakeAdmin extends AdminService {
  VinculosDisponiblesModel vinculos = const VinculosDisponiblesModel(
    jugadores: [_pablo, _luis],
    familiares: [_marta],
    cuerpoTecnico: [_ana],
    roles: [
      RolDisponibleModel(codigo: 'COORDINADOR', nombre: 'Coordinador'),
      RolDisponibleModel(codigo: 'RETRANSMISION', nombre: 'Retransmisión'),
    ],
  );

  final List<
    ({
      String email,
      String? nombre,
      String? apellidos,
      List<PersonaDisponibleModel> vinculos,
      List<String> roles,
    })
  >
  invitaciones = [];

  Object? falloAlInvitar;
  EstadoAppModel estado = const EstadoAppModel();
  Map<FiltroEstado, List<UsuarioEstadoModel>> usuarios = {};
  final List<FiltroEstado> filtrosPedidos = [];
  List<ReporteModel> resueltos = [];
  final List<String> llamadas = [];
  List<UsuarioPendienteModel> pendientes = [];

  @override
  Future<VinculosDisponiblesModel> obtenerVinculosDisponibles() async =>
      vinculos;

  @override
  Future<InvitacionEnviadaModel> invitar({
    required String email,
    String? nombre,
    String? apellidos,
    required List<PersonaDisponibleModel> vinculos,
    List<String> roles = const [],
  }) async {
    if (falloAlInvitar != null) throw falloAlInvitar!;

    invitaciones.add((
      email: email,
      nombre: nombre,
      apellidos: apellidos,
      vinculos: vinculos,
      roles: roles,
    ));

    return InvitacionEnviadaModel(email: email);
  }

  @override
  Future<EstadoAppModel> obtenerEstado() async => estado;

  @override
  Future<List<UsuarioEstadoModel>> obtenerUsuariosEstado(
    FiltroEstado filtro,
  ) async {
    filtrosPedidos.add(filtro);

    return usuarios[filtro] ?? const [];
  }

  @override
  Future<List<ReporteModel>> obtenerReportes({bool resueltos = false}) async =>
      resueltos ? this.resueltos : const [];

  @override
  Future<void> reactivarAutor(int reporteId, {String? nota}) async {
    llamadas.add('reactivar:$reporteId:$nota');
  }

  @override
  Future<List<UsuarioPendienteModel>> obtenerUsuariosPendientes() async =>
      pendientes;
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

Future<void> _pintar(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(home));
  await tester.pumpAndSettle();
}

UsuarioPendienteModel _pendiente(int id, String email) => UsuarioPendienteModel(
  id: id,
  email: email,
  nombre: null,
  apellidos: null,
  roles: const ['COORDINADOR'],
  vinculos: const [],
  fechaAlta: DateTime(2026, 10, 26),
  tokenCaducado: false,
  intentosActivacion: 0,
);

ReporteModel _reporte(
  int id, {
  String estado = estadoReporteAutorDesactivado,
  bool autorActivo = false,
  String? nota,
}) => ReporteModel(
  id: id,
  fechaReporte: DateTime(2026, 10, 21, 12, 30),
  motivo: 'Insultos',
  reportador: 'Reportador',
  autorId: 20,
  autor: 'Autor $id',
  autorActivo: autorActivo,
  autorEsAdmin: false,
  titulo: 'Título',
  contenido: 'Texto',
  fechaMensaje: DateTime(2026, 10, 20, 9, 0),
  estado: estado,
  resueltoPor: 'Admin Uno',
  fechaResolucion: DateTime(2026, 10, 21, 13, 0),
  nota: nota,
  otrosReportesDelAutor: 0,
);

void main() {
  // ---- invitar -------------------------------------------------------------------------------

  group('formulario de invitar', () {
    final nombre = find.byKey(const ValueKey('invitar-nombre'));
    final email = find.byKey(const ValueKey('invitar-email'));
    final enviar = find.byKey(const ValueKey('invitar-enviar'));

    Future<_FakeAdmin> abrir(WidgetTester tester) async {
      final servicio = _FakeAdmin();
      await _pintar(tester, InvitarUsuarioPage(servicio: servicio));
      return servicio;
    }

    testWidgets('lista las personas sin cuenta del tipo elegido y las '
        'filtra con el buscador', (tester) async {
      await abrir(tester);

      expect(find.text('Pablo Garcia'), findsOneWidget);
      expect(find.text('Luis Lopez'), findsOneWidget);
      expect(find.text('Cadete A'), findsOneWidget);
      expect(find.text('Marta Gil'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('invitar-busqueda')),
        'luis',
      );
      await tester.pump();

      expect(find.text('Pablo Garcia'), findsNothing);
      expect(find.text('Luis Lopez'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('invitar-busqueda')),
        'zzz',
      );
      await tester.pump();

      expect(
        find.text('No hay personas sin cuenta que coincidan.'),
        findsOneWidget,
      );
    });

    testWidgets('cambiar de tipo muestra familiares y cuerpo técnico (el '
        'familiar con sus jugadores)', (tester) async {
      await abrir(tester);

      await tester.tap(find.text('Familiar'));
      await tester.pumpAndSettle();

      expect(find.text('Marta Gil'), findsOneWidget);
      expect(find.text('Pablo Garcia'), findsOneWidget); // sus jugadores
      expect(find.text('Luis Lopez'), findsNothing);

      await tester.tap(find.text('Cuerpo técnico'));
      await tester.pumpAndSettle();

      expect(find.text('Ana Ruiz'), findsOneWidget);
    });

    testWidgets('elegir una persona la pasa a un chip que se puede quitar', (
      tester,
    ) async {
      await abrir(tester);

      await tester.tap(find.byKey(const ValueKey('persona-JUGADOR-1')));
      await tester.pumpAndSettle();

      final chip = find.byKey(const ValueKey('elegido-JUGADOR-1'));
      expect(chip, findsOneWidget);
      // Ya no se ofrece en la lista.
      expect(find.byKey(const ValueKey('persona-JUGADOR-1')), findsNothing);

      // El último icono del chip es el de quitarlo.
      await tester.tap(
        find.descendant(of: chip, matching: find.byType(Icon)).last,
      );
      await tester.pumpAndSettle();

      expect(chip, findsNothing);
      expect(find.byKey(const ValueKey('persona-JUGADOR-1')), findsOneWidget);
    });

    testWidgets('el resumen enseña los roles resultantes de los vínculos y de '
        'los roles adicionales', (tester) async {
      await abrir(tester);

      expect(find.text('Elige al menos un vínculo o un rol.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('persona-JUGADOR-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('persona-JUGADOR-2')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('rol-COORDINADOR')));
      await tester.tap(find.byKey(const ValueKey('rol-COORDINADOR')));
      await tester.pumpAndSettle();

      final resumen = find.byKey(const ValueKey('invitar-resumen'));

      // Dos jugadores son un solo rol.
      expect(
        find.descendant(of: resumen, matching: find.byType(Chip)),
        findsNWidgets(2),
      );
      expect(find.byKey(const ValueKey('resumen-JUGADOR')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('resumen-COORDINADOR')),
        findsOneWidget,
      );
    });

    testWidgets('los roles adicionales son los que manda el servidor', (
      tester,
    ) async {
      await abrir(tester);

      expect(find.text('Roles adicionales'), findsOneWidget);
      expect(find.byKey(const ValueKey('rol-COORDINADOR')), findsOneWidget);
      expect(find.byKey(const ValueKey('rol-RETRANSMISION')), findsOneWidget);
      expect(find.byKey(const ValueKey('rol-ADMIN_APP')), findsNothing);
    });

    testWidgets('sin vínculos ni roles no se envía', (tester) async {
      final servicio = await abrir(tester);

      await tester.enterText(nombre, 'Ana');
      await tester.enterText(email, 'ana@x.es');
      await tester.ensureVisible(enviar);
      await tester.tap(enviar);
      await tester.pumpAndSettle();

      expect(servicio.invitaciones, isEmpty);
      expect(find.text('Elige al menos un vínculo o un rol.'), findsOneWidget);
    });

    testWidgets('sin ficha hace falta el nombre, y siempre un email válido', (
      tester,
    ) async {
      final servicio = await abrir(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('rol-RETRANSMISION')));
      await tester.tap(find.byKey(const ValueKey('rol-RETRANSMISION')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(enviar);
      await tester.tap(enviar);
      await tester.pumpAndSettle();

      expect(find.text('Escribe el nombre de la persona.'), findsOneWidget);
      expect(find.text('Escribe un email válido.'), findsOneWidget);
      expect(servicio.invitaciones, isEmpty);
    });

    testWidgets('con una ficha no hace falta el nombre', (tester) async {
      final servicio = await abrir(tester);

      await tester.tap(find.byKey(const ValueKey('persona-JUGADOR-1')));
      await tester.pumpAndSettle();
      await tester.enterText(email, 'pablo@x.es');
      await tester.ensureVisible(enviar);
      await tester.tap(enviar);
      await tester.pumpAndSettle();

      expect(servicio.invitaciones.single.email, 'pablo@x.es');
      expect(servicio.invitaciones.single.nombre, '');
    });

    testWidgets('con un familiar el email lo pone el servidor y se avisa', (
      tester,
    ) async {
      final servicio = await abrir(tester);

      await tester.tap(find.text('Familiar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('persona-FAMILIAR-3')));
      await tester.pumpAndSettle();

      expect(
        find.text('Con un familiar vinculado se usa el email de su ficha.'),
        findsOneWidget,
      );

      await tester.ensureVisible(enviar);
      await tester.tap(enviar);
      await tester.pumpAndSettle();

      expect(servicio.invitaciones.single.vinculos, [_marta]);
    });

    testWidgets('envía vínculos y roles y devuelve la invitación', (
      tester,
    ) async {
      final servicio = _FakeAdmin();
      InvitacionEnviadaModel? devuelta;

      await _pintar(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                devuelta = await Navigator.push<InvitacionEnviadaModel>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvitarUsuarioPage(servicio: servicio),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(nombre, 'Carlos');
      await tester.enterText(
        find.byKey(const ValueKey('invitar-apellidos')),
        'Mas',
      );
      await tester.enterText(email, ' carlos@x.es ');
      await tester.tap(find.byKey(const ValueKey('persona-JUGADOR-2')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('rol-COORDINADOR')));
      await tester.tap(find.byKey(const ValueKey('rol-COORDINADOR')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(enviar);
      await tester.tap(enviar);
      await tester.pumpAndSettle();

      final enviada = servicio.invitaciones.single;
      expect(enviada.email, 'carlos@x.es');
      expect(enviada.nombre, 'Carlos');
      expect(enviada.apellidos, 'Mas');
      expect(enviada.vinculos, [_luis]);
      expect(enviada.roles, ['COORDINADOR']);

      // Vuelve a la pantalla anterior con la invitación.
      expect(find.byType(InvitarUsuarioPage), findsNothing);
      expect(devuelta?.email, 'carlos@x.es');
    });

    testWidgets('un email ya registrado (409) enseña el mensaje y se queda', (
      tester,
    ) async {
      final servicio = await abrir(tester);
      servicio.falloAlInvitar = const ApiException(
        'Ya existe una cuenta con ese email. Revisa Cuentas pendientes.',
        statusCode: 409,
      );

      await tester.tap(find.byKey(const ValueKey('persona-JUGADOR-1')));
      await tester.pumpAndSettle();
      await tester.enterText(email, 'repetido@x.es');
      await tester.ensureVisible(enviar);
      await tester.tap(enviar);
      await tester.pumpAndSettle();

      expect(
        find.text('Ya existe una cuenta con ese email. Revisa Cuentas pendientes.'),
        findsOneWidget,
      );
      expect(find.byType(InvitarUsuarioPage), findsOneWidget);
    });
  });

  group('Invitar desde Cuentas pendientes', () {
    testWidgets('el botón Invitar abre el formulario; al invitar avisa y la '
        'lista incluye la nueva cuenta', (tester) async {
      final servicio = _FakeAdmin()..pendientes = [_pendiente(1, 'ana@x.es')];

      await _pintar(
        tester,
        CuentasPendientesPage(
          servicio: servicio,
          constructorInvitar: () => Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  // La cuenta nueva ya existe en el servidor al volver.
                  servicio.pendientes = [
                    _pendiente(2, 'nuevo@x.es'),
                    _pendiente(1, 'ana@x.es'),
                  ];
                  Navigator.pop(
                    context,
                    const InvitacionEnviadaModel(email: 'nuevo@x.es'),
                  );
                },
                child: const Text('invitar ya'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('nuevo@x.es'), findsNothing);
      expect(find.text('Invitar'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('invitar-usuario')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('invitar ya'));
      await tester.pumpAndSettle();

      expect(find.byType(CuentasPendientesPage), findsOneWidget);
      expect(find.text('Invitación enviada a nuevo@x.es'), findsOneWidget);
      expect(find.text('nuevo@x.es'), findsWidgets);
    });

    testWidgets('si se vuelve sin invitar no pasa nada', (tester) async {
      final servicio = _FakeAdmin();

      await _pintar(
        tester,
        CuentasPendientesPage(
          servicio: servicio,
          constructorInvitar: () => const Scaffold(body: Text('formulario')),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('invitar-usuario')));
      await tester.pumpAndSettle();
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  // ---- estado de la app ----------------------------------------------------------------------

  group('estado de la app', () {
    const estado = EstadoAppModel(
      activas: 40,
      pendientes: 3,
      desactivadas: 2,
      activasSinDispositivo: 5,
      activasSinNotificaciones: 0,
      usuariosInactivos: 7,
      diasInactividad: 30,
      dispositivosVersionAntigua: 2,
      versiones: [
        VersionDispositivosModel(
          plataforma: 'ANDROID',
          version: '1.0.10',
          dispositivos: 20,
        ),
        VersionDispositivosModel(
          plataforma: 'IOS',
          version: '1.0.1',
          dispositivos: 2,
          porDebajoMinima: true,
        ),
        VersionDispositivosModel(
          plataforma: 'ANDROID',
          version: 'Desconocida',
          dispositivos: 1,
        ),
      ],
      minimaAndroid: '1.0.5',
      minimaIos: '1.0.7',
    );

    String total(String clave) => tester0.widget<Text>(
      find.byKey(ValueKey('total-$clave')),
    ).data!;

    testWidgets('tarjetas con los totales', (tester) async {
      tester0 = tester;
      await _pintar(tester, EstadoAppPage(servicio: _FakeAdmin()..estado = estado));

      expect(total('activas'), '40');
      expect(total('pendientes'), '3');
      expect(total('desactivadas'), '2');
      expect(total('SIN_DISPOSITIVO'), '5');
      expect(total('SIN_NOTIFICACIONES'), '0');
      expect(total('VERSION_ANTIGUA'), '2');
      expect(total('INACTIVOS'), '7');

      expect(find.text('Cuentas activas'), findsOneWidget);
      expect(find.text('Sin dispositivo (sin push)'), findsOneWidget);
      expect(find.text('Sin entrar en 30 días'), findsOneWidget);
    });

    testWidgets('la tabla de versiones resalta en rojo las inferiores a la '
        'mínima', (tester) async {
      await _pintar(tester, EstadoAppPage(servicio: _FakeAdmin()..estado = estado));

      expect(
        find.text('Versión mínima: Android 1.0.5 · iOS 1.0.7'),
        findsOneWidget,
      );

      Color? color(String texto, String clave) =>
          tester.widget<Text>(find.text(texto)).style?.color;

      expect(color('1.0.1', 'IOS-1.0.1'), const Color(0xFFDC2626));
      expect(color('1.0.10', 'ANDROID-1.0.10'), isNull);
      expect(color('Desconocida', 'ANDROID-Desconocida'), isNull);
    });

    testWidgets('pulsar un total abre la lista de ese filtro con un botón '
        'para escribir a cada cuenta', (tester) async {
      final servicio = _FakeAdmin()
        ..estado = estado
        ..usuarios = {
          FiltroEstado.sinDispositivo: [
            UsuarioEstadoModel(
              id: 7,
              nombre: 'Marta Gil',
              email: 'marta@x.es',
              roles: const ['FAMILIAR'],
              ultimoAcceso: DateTime(2026, 9, 1),
              versiones: const ['1.0.2'],
            ),
            const UsuarioEstadoModel(
              id: 8,
              nombre: 'Luis Lopez',
              email: 'luis@x.es',
            ),
          ],
        };

      UsuarioEstadoModel? chat;

      await _pintar(
        tester,
        EstadoAppPage(
          servicio: servicio,
          constructorChat: (usuario) {
            chat = usuario;
            return const Scaffold(body: Text('CHAT'));
          },
        ),
      );

      await tester.tap(find.byKey(const ValueKey('tarjeta-SIN_DISPOSITIVO')));
      await tester.pumpAndSettle();

      expect(servicio.filtrosPedidos, [FiltroEstado.sinDispositivo]);
      expect(find.text('Marta Gil'), findsOneWidget);
      expect(find.text('marta@x.es'), findsOneWidget);
      expect(find.text('Familiar'), findsOneWidget);
      expect(find.text('Último acceso: 01/09/2026'), findsOneWidget);
      expect(find.text('Sin accesos registrados'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('escribir-7')));
      await tester.pumpAndSettle();

      expect(find.text('CHAT'), findsOneWidget);
      expect(chat?.id, 7);
    });

    testWidgets('una lista vacía lo dice, y las tarjetas de totales no se '
        'pulsan', (tester) async {
      final servicio = _FakeAdmin()..estado = estado;

      await _pintar(tester, EstadoAppPage(servicio: servicio));

      await tester.tap(find.byKey(const ValueKey('tarjeta-activas')));
      await tester.pumpAndSettle();

      expect(servicio.filtrosPedidos, isEmpty);

      await tester.tap(find.byKey(const ValueKey('tarjeta-SIN_NOTIFICACIONES')));
      await tester.pumpAndSettle();

      expect(find.text('No hay cuentas en esta lista.'), findsOneWidget);
    });

    testWidgets('un 403 no es un error de conexión', (tester) async {
      await _pintar(tester, EstadoAppPage(servicio: _ErrorEstado()));

      expect(find.text('No tienes permiso'), findsOneWidget);
    });
  });

  // ---- reactivar desde moderación ------------------------------------------------------------

  group('reactivar una cuenta desde Moderación', () {
    Future<_FakeAdmin> abrir(WidgetTester tester, List<ReporteModel> resueltos) async {
      final servicio = _FakeAdmin()..resueltos = resueltos;

      await _pintar(tester, ModeracionPage(servicio: servicio));
      await tester.tap(find.text('Resueltos'));
      await tester.pumpAndSettle();

      return servicio;
    }

    testWidgets('solo en los AUTOR_DESACTIVADO con el autor aún '
        'desactivado', (tester) async {
      await abrir(tester, [
        _reporte(1),
        _reporte(2, autorActivo: true),
        _reporte(3, estado: estadoReporteDescartado),
        _reporte(4, estado: estadoReporteMensajeBorrado),
      ]);

      expect(find.byKey(const ValueKey('reactivar-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('reactivar-2')), findsNothing);
      expect(find.byKey(const ValueKey('reactivar-3')), findsNothing);
      expect(find.byKey(const ValueKey('reactivar-4')), findsNothing);
      expect(find.text('Reactivar cuenta'), findsOneWidget);
    });

    testWidgets('pide confirmación con nota opcional y reactiva', (
      tester,
    ) async {
      final servicio = await abrir(tester, [_reporte(1)]);

      await tester.tap(find.byKey(const ValueKey('reactivar-1')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Podrá volver a entrar con su contraseña'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'Se ha disculpado');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, ['reactivar:1:Se ha disculpado']);
      expect(find.text('Cuenta reactivada'), findsOneWidget);
    });

    testWidgets('cancelar no reactiva nada', (tester) async {
      final servicio = await abrir(tester, [_reporte(1)]);

      await tester.tap(find.byKey(const ValueKey('reactivar-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(servicio.llamadas, isEmpty);
    });
  });

  // ---- modelos y servicio --------------------------------------------------------------------

  group('modelos', () {
    test('los vínculos disponibles leen jugadores, familiares con sus '
        'jugadores, cuerpo técnico y roles', () {
      final v = VinculosDisponiblesModel.fromJson({
        'jugadores': [
          {'id': 1, 'nombre': 'Pablo Garcia', 'equipo': 'Cadete A'},
        ],
        'familiares': [
          {
            'id': 2,
            'nombre': 'Marta Gil',
            'jugadores': ['Pablo Garcia', 'Luis Lopez'],
          },
        ],
        'cuerpoTecnico': [
          {'id': 3, 'nombre': 'Ana Ruiz', 'equipo': null},
        ],
        'rolesAdicionales': [
          {'codigo': 'COORDINADOR', 'nombre': 'Coordinador'},
        ],
      });

      expect(v.de(TipoVinculo.jugador).single.detalle, 'Cadete A');
      expect(
        v.de(TipoVinculo.familiar).single.detalle,
        'Pablo Garcia, Luis Lopez',
      );
      expect(v.de(TipoVinculo.cuerpoTecnico).single.detalle, '');
      expect(v.de(TipoVinculo.cuerpoTecnico).single.tipo.codigo, 'ENTRENADOR');
      expect(v.roles.single.codigo, 'COORDINADOR');
    });

    test('el estado lee totales, versiones y mínimas', () {
      final e = EstadoAppModel.fromJson({
        'cuentas': {'activas': 4, 'pendientes': 1, 'desactivadas': 2},
        'activasSinDispositivo': 3,
        'activasSinNotificaciones': 2,
        'usuariosInactivos': 1,
        'diasInactividad': 30,
        'dispositivosVersionAntigua': 5,
        'versiones': [
          {
            'plataforma': 'IOS',
            'version': '1.0.1',
            'dispositivos': 2,
            'porDebajoMinima': true,
          },
        ],
        'versionMinima': {'android': '1.0.5', 'ios': '1.0.7'},
      });

      expect(e.activas, 4);
      expect(e.total(FiltroEstado.sinDispositivo), 3);
      expect(e.total(FiltroEstado.versionAntigua), 5);
      expect(e.versiones.single.porDebajoMinima, isTrue);
      expect(e.minimaIos, '1.0.7');
    });
  });

  group('AdminService', () {
    setUp(() async {
      FlutterSecureStoragePlatform.instance =
          TestFlutterSecureStoragePlatform(<String, String>{});
      await AuthSession.guardarSesion(
        LoginResponse(
          token: 'tok',
          usuarioId: 1,
          email: 'a@a.com',
          roles: const ['ADMIN_APP'],
        ),
      );
    });

    test('invitar hace POST /app/admin/invitaciones con vínculos y roles', () async {
      final r = await conMockHttp((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/app/admin/invitaciones'));
        expect(request.headers['Authorization'], 'Bearer tok');
        expect(jsonDecode(request.body), {
          'email': 'a@x.es',
          'nombre': 'Ana',
          'vinculos': [
            {'tipo': 'JUGADOR', 'personaId': 1},
            {'tipo': 'FAMILIAR', 'personaId': 3},
          ],
          'roles': ['COORDINADOR'],
        });

        return http.Response(
          jsonEncode({'email': 'a@x.es', 'emailEnviado': false}),
          201,
        );
      }, () => AdminService().invitar(
        email: ' a@x.es ',
        nombre: 'Ana',
        apellidos: '  ',
        vinculos: const [_pablo, _marta],
        roles: const ['COORDINADOR'],
      ));

      expect(r.email, 'a@x.es');
      expect(r.emailEnviado, isFalse);
    });

    test('el 409 de un email repetido conserva el mensaje del servidor', () async {
      await expectLater(
        conMockHttp(
          (request) async => http.Response('Ya existe una cuenta con ese email.', 409),
          () => AdminService().invitar(email: 'a@x.es', vinculos: const []),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.message, 'message', contains('Ya existe')),
        ),
      );
    });

    test('estado, usuarios y reactivar piden las rutas del backend', () async {
      await conMockHttp((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/app/admin/estado'));

        return http.Response(jsonEncode({'cuentas': {}}), 200);
      }, () => AdminService().obtenerEstado());

      final usuarios = await conMockHttp((request) async {
        expect(request.url.path, endsWith('/app/admin/estado/usuarios'));
        expect(request.url.queryParameters['filtro'], 'VERSION_ANTIGUA');

        return http.Response(
          jsonEncode([
            {'id': 1, 'nombre': 'Ana', 'email': 'a@x.es', 'roles': ['JUGADOR']},
          ]),
          200,
        );
      }, () => AdminService().obtenerUsuariosEstado(FiltroEstado.versionAntigua));

      expect(usuarios.single.roles, ['JUGADOR']);

      await conMockHttp((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          endsWith('/app/moderacion/reportes/9/reactivar-autor'),
        );
        expect(jsonDecode(request.body), {'nota': 'Ya está bien'});

        return http.Response('', 204);
      }, () => AdminService().reactivarAutor(9, nota: ' Ya está bien '));
    });
  });
}

late WidgetTester tester0;

class _ErrorEstado extends AdminService {
  @override
  Future<EstadoAppModel> obtenerEstado() async =>
      throw const ApiException('Prohibido', statusCode: 403);
}
