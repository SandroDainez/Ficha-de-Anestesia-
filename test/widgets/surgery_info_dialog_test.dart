import 'package:anestesia_app/models/patient.dart';
import 'package:anestesia_app/widgets/surgery_info_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows common surgery cards and free-form other field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SurgeryInfoDialog(
            section: SurgeryInfoSection.description,
            initialDescription: '',
            initialPriority: '',
            initialSurgeon: '',
            initialAssistants: [],
            initialDestination: '',
            initialOtherDestination: '',
            initialNotes: '',
            initialChecklist: [],
            initialTimeOutChecklist: [],
            initialTimeOutCompleted: false,
            patientPopulation: PatientPopulation.adult,
          ),
        ),
      ),
    );

    expect(find.text('Principais cirurgias'), findsOneWidget);
    expect(find.text('Histerectomia por vídeo'), findsOneWidget);
    expect(find.text('Vídeo colecistectomia'), findsOneWidget);
    expect(find.text('Bariátrica sleeve'), findsOneWidget);
    expect(find.text('Bariátrica by pass'), findsOneWidget);
    expect(find.text('Gastrectomia vertical'), findsNothing);
    expect(find.text('Bypass gástrico em Y de Roux'), findsNothing);
    expect(find.text('Nefrectomia direita'), findsOneWidget);
    expect(find.text('Herniorrafia incisional'), findsOneWidget);
    expect(find.text('Fratura de fêmur esquerdo'), findsOneWidget);
    expect(find.text('Mastectomia'), findsOneWidget);
    expect(find.text('Prótese de mama'), findsOneWidget);
    expect(find.byKey(const Key('surgery-description-field')), findsOneWidget);
    expect(find.text('Outras'), findsOneWidget);
  });

  testWidgets('postoperative destination options do not include alta da RPA', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SurgeryInfoDialog(
            section: SurgeryInfoSection.destination,
            initialDescription: '',
            initialPriority: '',
            initialSurgeon: '',
            initialAssistants: [],
            initialDestination: '',
            initialOtherDestination: '',
            initialNotes: '',
            initialChecklist: [],
            initialTimeOutChecklist: [],
            initialTimeOutCompleted: false,
            patientPopulation: PatientPopulation.adult,
          ),
        ),
      ),
    );

    expect(find.text('RPA'), findsOneWidget);
    expect(find.text('Enfermaria'), findsOneWidget);
    expect(find.text('UTI'), findsOneWidget);
    expect(find.text('Alta da RPA'), findsNothing);
  });
}
