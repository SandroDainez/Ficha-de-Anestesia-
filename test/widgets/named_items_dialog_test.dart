import 'package:anestesia_app/widgets/anesthesia_basic_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('supports adding more than one team member before saving', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NamedItemsDialog(
            title: 'Cirurgiões',
            label: 'Nome do cirurgião',
            addButtonLabel: 'Adicionar cirurgião',
            emptyStateText: 'Nenhum cirurgião adicionado.',
            initialItems: [],
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Dr. Silva');
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar cirurgião'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Dra. Lima');
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar cirurgião'));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Silva'), findsOneWidget);
    expect(find.text('Dra. Lima'), findsOneWidget);
  });
}
