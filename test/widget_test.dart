import 'package:flutter_test/flutter_test.dart';

import 'package:anestesia_app/main.dart';
import 'package:anestesia_app/screens/anesthesia_screen.dart';

void main() {
  testWidgets('renders case start screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AnestesiaApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Casos de Anestesia'), findsOneWidget);
    expect(find.text('Nova ficha anestésica'), findsOneWidget);
    expect(find.text('Novo pré-anestésico'), findsOneWidget);
  });

  testWidgets('navigates to pre-anesthetic screen from start screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnestesiaApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Novo pré-anestésico'));
    await tester.pumpAndSettle();

    expect(find.text('Consulta Pré-Anestésica'), findsOneWidget);
    expect(find.text('Identificação do paciente'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Idade (anos)'), findsOneWidget);
  });

  testWidgets('navigates to anesthesia screen from start screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnestesiaApp());
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Nova ficha anestésica'));
    await tester.pumpAndSettle();

    expect(find.byType(AnesthesiaScreen), findsOneWidget);
  });
}
