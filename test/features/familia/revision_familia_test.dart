import 'package:app_mutxamel_cf/core/network/api_client.dart';
import 'package:app_mutxamel_cf/features/auth/models/auth_user.dart';
import 'package:app_mutxamel_cf/features/auth/pages/club_page.dart';
import 'package:app_mutxamel_cf/features/auth/services/auth_manager.dart';
import 'package:app_mutxamel_cf/features/familia/models/solicitud_familia_model.dart';
import 'package:app_mutxamel_cf/features/familia/pages/solicitudes_familia_page.dart';
import 'package:app_mutxamel_cf/features/familia/services/solicitud_familia_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../../support/http_test_helpers.dart';
import 'soporte_familia.dart';

const _luisAlevin = CoincidenciaJugador(
  jugadorId: 55,
  nombre: 'Luis Pérez Gómez',
  equipoId: 8,
  equipo: 'Alevín B',
  coincideEquipo: true,
  dorsal: 7,
);

const _luisBenjamin = CoincidenciaJugador(
  jugadorId: 56,
  nombre: 'Luis Pérez Ruiz',
  equipoId: 9,
  equipo: 'Benjamín A',
  coincideEquipo: false,
);

const _evaGarcia = CoincidenciaJugador(
  jugadorId: 57,
  nombre: 'Eva García Soler',
  equipoId: 8,
  equipo: 'Alevín B',
  coincideEquipo: false,
);

SolicitudRevision _solicitud({int id = 12, List<HijoRevision>? hijos}) =>
    SolicitudRevision(
      id: id,
      nombre: 'Ana',
      apellidos: 'Pérez Gil',
      email: 'ana@example.com',
      telefono: '623 17 68 18',
      parentesco: 'MADRE',
      estado: 'PENDIENTE',
      fechaSolicitud: DateTime(2026, 11, 18, 10, 15),
      hijos:
          hijos ??
          const [
            HijoRevision(
              id: 31,
              nombre: 'Luis',
              apellidos: 'Pérez',
              equipo: 'Alevín B',
              estado: 'PENDIENTE',
              jugador: null,
              coincidencias: [_luisAlevin, _luisBenjamin],
            ),
            HijoRevision(
              id: 32,
              nombre: 'Pau',
              apellidos: 'Nadie',
              equipo: '',
              estado: 'PENDIENTE',
              jugador: null,
              coincidencias: [],
            ),
          ],
    );

/// Un servicio de mentira: lo que devuelve y lo que se le pide.
class _Fake extends SolicitudFamiliaService {
  _Fake({List<SolicitudRevision>? pendientes, this.total})
    : lista = pendientes ?? [_solicitud()];

  List<SolicitudRevision> lista;
  int? total;
  Object? falloPendientes;
  Object? falloAprobar;

  final aprobados = <(int, int)>[];
  final rechazados = <(int, String?)>[];
  final busquedas = <String>[];
  List<CoincidenciaJugador> encontrados = [_evaGarcia];
  int cargas = 0;

  @override
  Future<List<SolicitudRevision>> pendientes() async {
    cargas++;

    if (falloPendientes != null) throw falloPendientes!;

    return lista;
  }

  @override
  Future<int> contarPendientes() async => total ?? lista.length;

  @override
  Future<List<CoincidenciaJugador>> buscarJugadores(String texto) async {
    busquedas.add(texto);

    return encontrados;
  }

  @override
  Future<void> aprobarHijo(int hijoId, int jugadorId) async {
    if (falloAprobar != null) throw falloAprobar!;

    aprobados.add((hijoId, jugadorId));
    _quitar(hijoId);
  }

  @override
  Future<void> rechazarHijo(int hijoId, {String? motivo}) async {
    rechazados.add((hijoId, motivo));
    _quitar(hijoId);
  }

  /// El hijo deja de estar pendiente; sin hijos pendientes, la solicitud desaparece de la lista.
  void _quitar(int hijoId) {
    lista = [
      for (final s in lista)
        if (s.hijos.any((h) => h.id != hijoId && h.pendiente))
          SolicitudRevision(
            id: s.id,
            nombre: s.nombre,
            apellidos: s.apellidos,
            email: s.email,
            telefono: s.telefono,
            parentesco: s.parentesco,
            estado: s.estado,
            fechaSolicitud: s.fechaSolicitud,
            hijos: [
              for (final h in s.hijos)
                if (h.id != hijoId) h,
            ],
          ),
    ];
  }
}

Finder _clave(String clave) => find.byKey(ValueKey(clave));

void main() {
  setUp(() {
    prepararAlmacenamiento();
  });

  Future<void> pintarPagina(WidgetTester tester, _Fake fake) => pintarFamilia(
    tester,
    SolicitudesFamiliaPage(servicio: fake),
    tamano: const Size(390, 1600),
  );

  group('pantalla de revisión', () {
    testWidgets(
      'enseña el familiar, lo que escribió la familia y las coincidencias',
      (tester) async {
        await pintarPagina(tester, _Fake());

        expect(find.text('Solicitudes de familia'), findsOneWidget);

        // El familiar: nombre, parentesco, email, teléfono y fecha.
        expect(find.text('Ana Pérez Gil'), findsOneWidget);
        expect(find.text('Madre'), findsOneWidget);
        expect(find.text('ana@example.com'), findsOneWidget);
        expect(find.text('623 17 68 18'), findsOneWidget);

        // Lo escrito por la familia.
        expect(find.text('Escrito por la familia'), findsNWidgets(2));
        expect(find.text('Luis Pérez · Alevín B'), findsOneWidget);
        expect(find.text('Pau Nadie'), findsOneWidget);

        // Las coincidencias: jugador, equipo, dorsal y "mismo equipo".
        expect(find.text('Luis Pérez Gómez'), findsOneWidget);
        expect(find.text('Alevín B · Dorsal 7'), findsOneWidget);
        expect(find.text('Mismo equipo'), findsOneWidget);
        expect(find.text('Luis Pérez Ruiz'), findsOneWidget);
        expect(find.text('Benjamín A'), findsOneWidget);

        // Un hijo sin coincidencias lo dice y manda a buscar.
        expect(_clave('familia-sin-coincidencias-32'), findsOneWidget);
        expect(find.text('Buscar otro jugador'), findsNWidgets(2));
      },
    );

    testWidgets(
      'aprobar exige elegir un jugador y manda el elegido con un toque',
      (tester) async {
        final fake = _Fake();

        await pintarPagina(tester, fake);

        // Sin elegir, el botón está desactivado.
        expect(
          tester.widget<FilledButton>(_clave('familia-aprobar-31')).onPressed,
          isNull,
        );
        expect(
          find.text('Elige un jugador para poder aprobar'),
          findsNWidgets(2),
        );

        await tester.tap(_clave('familia-coincidencia-31-56'));
        await tester.pumpAndSettle();

        expect(
          tester.widget<FilledButton>(_clave('familia-aprobar-31')).onPressed,
          isNotNull,
        );

        // Se puede cambiar de elección.
        await tester.tap(_clave('familia-coincidencia-31-55'));
        await tester.pumpAndSettle();
        await tester.tap(_clave('familia-aprobar-31'));
        await tester.pumpAndSettle();

        expect(fake.aprobados, [(31, 55)]);
        expect(find.text('Acceso aprobado'), findsOneWidget);
        // La lista se recarga: ya solo queda el otro hijo.
        expect(fake.cargas, 2);
        expect(_clave('familia-revision-hijo-31'), findsNothing);
        expect(_clave('familia-revision-hijo-32'), findsOneWidget);
      },
    );

    testWidgets('buscar otro jugador: hoja con buscador, resultados y elección', (
      tester,
    ) async {
      final fake = _Fake();

      await pintarPagina(tester, fake);

      await tester.tap(_clave('familia-buscar-otro-32'));
      await tester.pumpAndSettle();

      expect(_clave('familia-buscador'), findsOneWidget);
      expect(find.text('Nombre o apellidos (mínimo 3 letras)'), findsOneWidget);

      // Con menos de 3 letras no se busca.
      await tester.enterText(_clave('familia-buscador'), 'ga');
      await tester.pumpAndSettle();

      expect(fake.busquedas, isEmpty);

      await tester.enterText(_clave('familia-buscador'), 'garcia');
      await tester.pumpAndSettle();

      expect(fake.busquedas, ['garcia']);
      expect(find.text('Eva García Soler'), findsOneWidget);

      await tester.tap(_clave('familia-resultado-57'));
      await tester.pumpAndSettle();

      // La hoja se cierra, el jugador queda elegido para ese hijo y ya se puede aprobar.
      expect(_clave('familia-buscador'), findsNothing);
      expect(_clave('familia-coincidencia-32-57'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(_clave('familia-aprobar-32')).onPressed,
        isNotNull,
      );

      await tester.tap(_clave('familia-aprobar-32'));
      await tester.pumpAndSettle();

      expect(fake.aprobados, [(32, 57)]);
    });

    testWidgets('una búsqueda sin resultados lo dice', (tester) async {
      final fake = _Fake()..encontrados = [];

      await pintarPagina(tester, fake);

      await tester.tap(_clave('familia-buscar-otro-32'));
      await tester.pumpAndSettle();
      await tester.enterText(_clave('familia-buscador'), 'zzzz');
      await tester.pumpAndSettle();

      expect(_clave('familia-sin-resultados'), findsOneWidget);
      expect(find.text('Sin resultados'), findsOneWidget);
    });

    testWidgets('con el teclado abierto la hoja de búsqueda sube con él', (
      tester,
    ) async {
      await pintarFamilia(
        tester,
        SolicitudesFamiliaPage(servicio: _Fake()),
        tamano: const Size(320, 568),
        escala: 1.5,
        oscuro: true,
      );

      await tester.ensureVisible(_clave('familia-buscar-otro-32'));
      await tester.pumpAndSettle();
      await tester.tap(_clave('familia-buscar-otro-32'));
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();

      expect(
        tester.getRect(_clave('familia-buscador')).bottom,
        lessThanOrEqualTo(568 - 260),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('rechazar pide confirmación; cancelar no hace nada', (
      tester,
    ) async {
      final fake = _Fake();

      await pintarPagina(tester, fake);

      await tester.tap(_clave('familia-rechazar-31'));
      await tester.pumpAndSettle();

      expect(find.text('¿Rechazar esta solicitud?'), findsOneWidget);
      expect(
        find.text(
          'Ana Pérez Gil no tendrá acceso a la información de ese jugador.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(fake.rechazados, isEmpty);
      expect(_clave('familia-revision-hijo-31'), findsOneWidget);
    });

    testWidgets('rechazar con motivo lo manda y recarga la lista', (
      tester,
    ) async {
      final fake = _Fake();

      await pintarPagina(tester, fake);

      await tester.tap(_clave('familia-rechazar-31'));
      await tester.pumpAndSettle();
      await tester.enterText(
        _clave('familia-motivo'),
        '  No es de nuestro club  ',
      );
      await tester.tap(_clave('familia-confirmar-rechazo'));
      await tester.pumpAndSettle();

      expect(fake.rechazados, [(31, '  No es de nuestro club  ')]);
      expect(find.text('Solicitud rechazada'), findsOneWidget);
      expect(_clave('familia-revision-hijo-31'), findsNothing);
    });

    testWidgets('rechazar sin motivo también vale', (tester) async {
      final fake = _Fake();

      await pintarPagina(tester, fake);

      await tester.tap(_clave('familia-rechazar-32'));
      await tester.pumpAndSettle();
      await tester.tap(_clave('familia-confirmar-rechazo'));
      await tester.pumpAndSettle();

      expect(fake.rechazados.single.$1, 32);
      expect(fake.rechazados.single.$2, '');
    });

    testWidgets(
      'al aprobar o rechazar el último hijo la solicitud desaparece y sale el vacío',
      (tester) async {
        final fake = _Fake(
          pendientes: [
            _solicitud(
              hijos: const [
                HijoRevision(
                  id: 40,
                  nombre: 'Eva',
                  apellidos: 'García',
                  equipo: '',
                  estado: 'PENDIENTE',
                  jugador: null,
                  coincidencias: [_evaGarcia],
                ),
              ],
            ),
          ],
        );

        await pintarPagina(tester, fake);

        await tester.tap(_clave('familia-coincidencia-40-57'));
        await tester.pumpAndSettle();
        await tester.tap(_clave('familia-aprobar-40'));
        await tester.pumpAndSettle();

        expect(find.text('No hay solicitudes pendientes.'), findsOneWidget);
      },
    );

    testWidgets('un error al aprobar lo explica y deja reintentar', (
      tester,
    ) async {
      final fake = _Fake()
        ..falloAprobar = const ApiException(
          'La solicitud ya no está pendiente de revisar',
          statusCode: 409,
        );

      await pintarPagina(tester, fake);

      await tester.tap(_clave('familia-coincidencia-31-55'));
      await tester.pumpAndSettle();
      await tester.tap(_clave('familia-aprobar-31'));
      await tester.pumpAndSettle();

      expect(
        find.text('La solicitud ya no está pendiente de revisar'),
        findsOneWidget,
      );
      expect(_clave('familia-revision-hijo-31'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(_clave('familia-aprobar-31')).onPressed,
        isNotNull,
      );
    });

    testWidgets('sin solicitudes lo dice', (tester) async {
      await pintarPagina(tester, _Fake(pendientes: []));

      expect(_clave('familia-sin-pendientes'), findsOneWidget);
    });

    testWidgets(
      'si falla la carga lo dice y no confunde con "no hay solicitudes"',
      (tester) async {
        final roto = _Fake()
          ..falloPendientes = const ApiException('boom', statusCode: 500);

        await pintarPagina(tester, roto);

        expect(
          find.text(
            'No se ha podido conectar. Comprueba tu conexión e inténtalo de nuevo.',
          ),
          findsOneWidget,
        );
        expect(_clave('familia-sin-pendientes'), findsNothing);
      },
    );

    testWidgets(
      'caben en un iPhone pequeño con letra grande, en oscuro y en otros idiomas',
      (tester) async {
        for (final idioma in ['es', 'ca', 'en']) {
          await pintarFamilia(
            tester,
            SolicitudesFamiliaPage(servicio: _Fake()),
            tamano: const Size(320, 568),
            escala: 2.0,
            oscuro: true,
            idioma: idioma,
          );

          expect(tester.takeException(), isNull, reason: idioma);
        }
      },
    );
  });

  group('menú y contador por rol', () {
    Future<void> pintarClub(
      WidgetTester tester,
      List<String> roles,
      _Fake fake,
    ) async {
      await AuthManager.establecerUsuario(
        AuthUser(usuarioId: 1, email: 'a@b.c', roles: roles),
      );

      await conMockHttp(
        (request) async => http.Response('no', 404),
        () => pintarFamilia(
          tester,
          ClubPage(solicitudFamiliaService: fake),
          tamano: const Size(390, 2400),
        ),
      );
    }

    for (final rol in ['COORDINADOR', 'ADMIN_APP']) {
      testWidgets(
        '$rol: "Solicitudes de familia" con el contador de pendientes',
        (tester) async {
          final fake = _Fake(total: 3);

          await pintarClub(tester, [rol], fake);

          expect(find.text('Solicitudes de familia'), findsOneWidget);
          expect(find.text('3'), findsOneWidget);
        },
      );
    }

    testWidgets('ENTRENADOR: la ve junto a Mis equipos, con su contador', (
      tester,
    ) async {
      final fake = _Fake(total: 2);

      await pintarClub(tester, ['ENTRENADOR'], fake);

      expect(find.text('Mis equipos'), findsOneWidget);
      expect(find.text('Solicitudes de familia'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('sin pendientes no hay burbuja', (tester) async {
      await pintarClub(tester, [
        'COORDINADOR',
      ], _Fake(total: 0, pendientes: []));

      expect(find.text('Solicitudes de familia'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    for (final rol in ['FAMILIAR', 'JUGADOR', 'RETRANSMISION']) {
      testWidgets('$rol no ve la opción ni pide el contador', (tester) async {
        final fake = _Fake(total: 5);

        await pintarClub(tester, [rol], fake);

        expect(find.text('Solicitudes de familia'), findsNothing);
        expect(find.text('5'), findsNothing);
      });
    }

    testWidgets(
      'tocarla abre la pantalla y al volver se actualiza el contador',
      (tester) async {
        final fake = _Fake(total: 2);

        await pintarClub(tester, ['COORDINADOR'], fake);

        expect(find.text('2'), findsOneWidget);

        await tester.tap(find.text('Solicitudes de familia'));
        await tester.pumpAndSettle();

        expect(find.byType(SolicitudesFamiliaPage), findsOneWidget);

        fake.total = 1;

        Navigator.of(tester.element(find.byType(SolicitudesFamiliaPage))).pop();
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsNothing);
      },
    );
  });
}
