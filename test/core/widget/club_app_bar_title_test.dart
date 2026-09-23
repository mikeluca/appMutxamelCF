import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_mutxamel_cf/core/widget/club_app_bar_title.dart';

void main() {
  testWidgets('ClubAppBarTitle muestra el titulo recibido', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: null,
          body: ClubAppBarTitle(titulo: 'Mutxamel CF'),
        ),
      ),
    );

    expect(find.text('Mutxamel CF'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('el texto largo se trunca con puntos suspensivos', (
    tester,
  ) async {
    const tituloLargo =
        'Un titulo extremadamente largo que no deberia caber en el AppBar';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ClubAppBarTitle(titulo: tituloLargo)),
      ),
    );

    final textWidget = tester.widget<Text>(find.text(tituloLargo));

    expect(textWidget.overflow, TextOverflow.ellipsis);
  });
}
