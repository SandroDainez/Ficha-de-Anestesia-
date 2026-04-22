import 'package:anestesia_app/models/anesthesia_record.dart';
import 'package:anestesia_app/models/patient.dart';
import 'package:anestesia_app/screens/post_anesthesia_recovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableApp(AnesthesiaRecord record) {
    return MaterialApp(
      home: PostAnesthesiaRecoveryScreen(record: record),
    );
  }

  AnesthesiaRecord buildRecord() {
    return AnesthesiaRecord.empty().copyWith(
      patient: const Patient(
        name: 'Maria Souza',
        age: 42,
        weightKg: 68,
        heightMeters: 1.65,
        asa: 'II',
        allergies: ['Latex'],
        restrictions: ['Nao aceita transfusao'],
        medications: ['Losartana'],
      ),
      surgeryDescription: 'Colecistectomia',
      anesthesiaTechnique: 'Anestesia geral balanceada',
      anesthesiaTechniqueDetails: 'Sem intercorrências maiores no intraoperatório.',
      operationalNotes: 'Transferência estável para recuperação.',
    );
  }

  testWidgets('recovery page exposes admission monitoring scales complications interventions and discharge sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableApp(buildRecord()));

    expect(find.text('ADMISSÃO NA RPA'), findsOneWidget);
    expect(find.text('CRITÉRIOS DE ADMISSÃO'), findsOneWidget);
    expect(find.text('MONITORIZAÇÃO NA RECUPERAÇÃO'), findsOneWidget);
    expect(find.text('ESCALAS E AVALIAÇÕES'), findsOneWidget);
    expect(find.text('COMPLICAÇÕES NA RECUPERAÇÃO'), findsOneWidget);
    expect(find.text('INTERVENÇÕES NA RECUPERAÇÃO'), findsOneWidget);
    expect(find.text('CRITÉRIOS DE ALTA'), findsOneWidget);
    expect(find.text('ALTA DA RECUPERAÇÃO'), findsOneWidget);
  });

  testWidgets('recovery destination options do not include alta da RPA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestableApp(buildRecord()));

    await tester.ensureVisible(find.text('ALTA DA RECUPERAÇÃO'));
    await tester.tap(find.text('ALTA DA RECUPERAÇÃO'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('Enfermaria'), findsWidgets);
    expect(find.text('UTI'), findsWidgets);
    expect(find.text('Alta da RPA'), findsNothing);
  });
}
