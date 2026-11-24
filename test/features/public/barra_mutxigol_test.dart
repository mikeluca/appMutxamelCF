import 'package:app_mutxamel_cf/features/home/home_page.dart';
import 'package:app_mutxamel_cf/features/juego/estado_mutxigol.dart';
import 'package:app_mutxamel_cf/features/juego/models/juego_modelos.dart';
import 'package:app_mutxamel_cf/features/juego/pages/mutxigol_page.dart';
import 'package:app_mutxamel_cf/features/matches/models/match_model.dart';
import 'package:app_mutxamel_cf/features/matches/services/match_service.dart';
import 'package:app_mutxamel_cf/features/news/models/news_model.dart';
import 'package:app_mutxamel_cf/features/news/pages/news_detail_page.dart';
import 'package:app_mutxamel_cf/features/news/pages/news_page.dart';
import 'package:app_mutxamel_cf/features/news/services/news_services.dart';
import 'package:app_mutxamel_cf/features/public/public_shell_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/juego_helpers.dart';

class _NoticiasFalsas extends NewsService {
  _NoticiasFalsas(this.noticias);

  final List<NewsModel> noticias;
  final List<int?> peticiones = [];

  @override
  Future<List<NewsModel>> obtenerNoticias({int? antesId, int limite = 5}) async {
    peticiones.add(antesId);

    return noticias;
  }
}

class _PartidosFalsos extends MatchService {
  @override
  Future<MatchModel?> obtenerResultadoPrimerEquipo() async => null;
}

NewsModel _noticia(int id, String titulo) => NewsModel(
  id: id,
  titulo: titulo,
  contenido: 'Contenido de $titulo',
  imagenUrl: null,
);

void main() {
  setUp(EstadoMutxigol.reiniciar);
  tearDown(EstadoMutxigol.reiniciar);

  group('la barra inferior', () {
    /// La shell con las pestañas de siempre salvo las que necesitan red o WebView (sustituidas por un texto).
    Future<void> pintarShell(WidgetTester tester) async {
      pantallaDeMovil(tester, alto: 900);

      await tester.pumpWidget(
        appDePrueba(
          const PublicShellPage(
            paginas: [
              Text('pestaña-inicio'),
              MutxigolPage(),
              Text('pestaña-partidos'),
              Text('pestaña-tienda'),
              Text('pestaña-club'),
            ],
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('lleva Mutxigol en lugar de Noticias, con su cara en un círculo', (tester) async {
      await pintarShell(tester);

      expect(find.text('Mutxigol'), findsOneWidget);
      expect(find.text('Noticias'), findsNothing);

      // Las demás pestañas siguen en su sitio.
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Partidos'), findsOneWidget);
      expect(find.text('Tienda'), findsOneWidget);
      expect(find.text('Club'), findsOneWidget);

      // El icono es la cara recortada en círculo.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('icono-mutxigol')),
          matching: find.byType(ClipOval),
        ),
        findsOneWidget,
      );
      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.cara)),
        findsOneWidget,
      );
    });

    testWidgets('la cara lleva la equipación elegida', (tester) async {
      EstadoMutxigol.equipacion.value = Equipacion.rosa;

      await pintarShell(tester);

      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.rosa, PoseMutxigol.cara)),
        findsOneWidget,
      );

      // Y cambia al elegir otra.
      EstadoMutxigol.equipacion.value = Equipacion.azul;
      await tester.pump();

      expect(
        imagenDe(ImagenesMutxigol.pose(Equipacion.azul, PoseMutxigol.cara)),
        findsOneWidget,
      );
    });

    testWidgets('Mutxigol ocupa el sitio que tenía Noticias y abre la pantalla del juego', (tester) async {
      await pintarShell(tester);

      int pestanaVisible() =>
          tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

      expect(pestanaVisible(), 0);

      await tester.tap(find.text('Mutxigol'));
      await tester.pump();

      expect(pestanaVisible(), 1);
      expect(find.byType(MutxigolPage), findsOneWidget);
      expect(find.byKey(const ValueKey('selector-equipacion')), findsOneWidget);
    });

    testWidgets('los índices de las demás pestañas no cambian', (tester) async {
      await pintarShell(tester);

      int pestanaVisible() =>
          tester.widget<IndexedStack>(find.byType(IndexedStack)).index!;

      for (final (etiqueta, indice, texto) in [
        ('Partidos', 2, 'pestaña-partidos'),
        ('Tienda', 3, 'pestaña-tienda'),
        ('Club', 4, 'pestaña-club'),
        ('Inicio', 0, 'pestaña-inicio'),
      ]) {
        await tester.tap(find.text(etiqueta));
        await tester.pump();

        expect(pestanaVisible(), indice, reason: etiqueta);
        expect(find.text(texto), findsOneWidget);
      }
    });
  });

  group('las noticias desde Inicio', () {
    Future<_NoticiasFalsas> pintarInicio(
      WidgetTester tester,
      List<NewsModel> noticias,
    ) async {
      pantallaDeMovil(tester, alto: 2000);

      final servicio = _NoticiasFalsas(noticias);

      await tester.pumpWidget(
        appDePrueba(
          HomePage(
            matchService: _PartidosFalsos(),
            newsService: servicio,
            avisosDeResultados: const Stream<void>.empty(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return servicio;
    }

    testWidgets('debajo de las 3 últimas noticias hay "Ver todas las noticias" que abre la lista con flecha de volver', (tester) async {
      final servicio = await pintarInicio(tester, [
        _noticia(1, 'Primera'),
        _noticia(2, 'Segunda'),
        _noticia(3, 'Tercera'),
        _noticia(4, 'Cuarta'),
      ]);

      // Solo salen las 3 últimas.
      expect(find.text('Primera'), findsOneWidget);
      expect(find.text('Tercera'), findsOneWidget);
      expect(find.text('Cuarta'), findsNothing);

      final enlace = find.byKey(const ValueKey('ver-todas-noticias'));

      expect(enlace, findsOneWidget);
      expect(find.text('Ver todas las noticias'), findsOneWidget);

      // Está debajo de la tercera noticia.
      expect(
        tester.getTopLeft(enlace).dy,
        greaterThan(tester.getBottomLeft(find.text('Tercera')).dy),
      );

      await tester.ensureVisible(enlace);
      await tester.tap(enlace);
      await tester.pumpAndSettle();

      expect(find.byType(NewsPage), findsOneWidget);
      // La lista completa: ahora sí sale la cuarta.
      expect(find.text('Cuarta'), findsOneWidget);
      expect(servicio.peticiones.length, greaterThanOrEqualTo(2));

      // Pantalla con flecha de volver.
      expect(find.byType(BackButton), findsOneWidget);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(find.byType(NewsPage), findsNothing);
      expect(find.byKey(const ValueKey('ver-todas-noticias')), findsOneWidget);
    });

    testWidgets('una noticia sigue abriendo su detalle, desde Inicio y desde la lista', (tester) async {
      await pintarInicio(tester, [_noticia(1, 'Primera'), _noticia(2, 'Segunda')]);

      await tester.tap(find.text('Primera'));
      await tester.pumpAndSettle();

      expect(find.byType(NewsDetailPage), findsOneWidget);
      expect(find.text('Contenido de Primera'), findsWidgets);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      final enlace = find.byKey(const ValueKey('ver-todas-noticias'));

      await tester.ensureVisible(enlace);
      await tester.tap(enlace);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Segunda'));
      await tester.pumpAndSettle();

      expect(find.byType(NewsDetailPage), findsOneWidget);
    });
  });
}
