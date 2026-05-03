import 'package:anestesia_app/widgets/intraoperative_entry_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'drug infusions dialog saves continuous infusion with ampoule count',
    (WidgetTester tester) async {
      List<String>? savedItems;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    savedItems = await showDialog<List<String>>(
                      context: context,
                      builder: (_) =>
                          const DrugInfusionsDialog(initialItems: []),
                    );
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('drug-dose-field-Propofol')),
        '120 mg',
      );
      await tester.enterText(
        find.byKey(const Key('drug-time-field-Propofol')),
        '08:00',
      );
      await tester.enterText(
        find.byKey(const Key('drug-infusion-field-Propofol')),
        '6 mg/kg/h',
      );
      await tester.enterText(
        find.byKey(const Key('drug-ampoules-field-Propofol')),
        '4 ampolas',
      );
      await tester.tap(find.byKey(const Key('drug-save-button')));
      await tester.pumpAndSettle();

      expect(savedItems, isNotNull);
      expect(
        savedItems,
        contains('Propofol|120 mg|08:00||6 mg/kg/h|4 ampolas'),
      );
    },
  );
}
