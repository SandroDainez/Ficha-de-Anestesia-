import 'package:anestesia_app/widgets/anesthesia_basic_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('choice field dialog shows searchable option grid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChoiceFieldDialog(
            title: 'Perfil do paciente',
            options: ['adult', 'pediatric'],
            initialValue: 'adult',
            optionLabelBuilder: _labelForProfile,
          ),
        ),
      ),
    );

    expect(find.text('Buscar...'), findsOneWidget);
    expect(find.text('Adulto'), findsOneWidget);
    expect(find.text('Pediátrico'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'pedi');
    await tester.pumpAndSettle();

    expect(find.text('Adulto'), findsNothing);
    expect(find.text('Pediátrico'), findsOneWidget);
  });

  testWidgets('list field dialog shows searchable suggestion grid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ListFieldDialog(
            title: 'Alergias',
            label: 'Alergias',
            initialItems: [],
            suggestions: ['Látex', 'Dipirona', 'Penicilina'],
          ),
        ),
      ),
    );

    expect(find.text('Buscar...'), findsOneWidget);
    expect(find.text('Látex'), findsOneWidget);
    expect(find.text('Dipirona'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'peni');
    await tester.pumpAndSettle();

    expect(find.text('Látex'), findsNothing);
    expect(find.text('Dipirona'), findsNothing);
    expect(find.text('Penicilina'), findsOneWidget);
  });

  testWidgets('supports adding more than one team member before saving', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NamedItemsDialog(
            title: 'Cirurgiões',
            label: 'Nome',
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

  testWidgets('uses the same base field label pattern as anesthesiologists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NamedItemsDialog(
            title: 'Auxiliares',
            label: 'Nome',
            addButtonLabel: 'Adicionar auxiliar',
            emptyStateText: 'Nenhum auxiliar adicionado.',
            initialItems: [],
          ),
        ),
      ),
    );

    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Nenhum auxiliar adicionado.'), findsOneWidget);
  });
}

String _labelForProfile(String option) {
  switch (option) {
    case 'adult':
      return 'Adulto';
    case 'pediatric':
      return 'Pediátrico';
    default:
      return option;
  }
}
