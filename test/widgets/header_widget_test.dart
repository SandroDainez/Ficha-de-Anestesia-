import 'package:anestesia_app/models/airway.dart';
import 'package:anestesia_app/models/patient.dart';
import 'package:anestesia_app/models/pre_anesthetic_assessment.dart';
import 'package:anestesia_app/widgets/header_widget.dart';
import 'package:anestesia_app/widgets/ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows key clinical chips together and flags airway or ventilation risk in red',
    (WidgetTester tester) async {
      const assessment = PreAnestheticAssessment(
        comorbidities: [],
        otherComorbidities: '',
        currentMedications: [],
        otherMedications: '',
        allergyDescription: '',
        smokingStatus: '',
        alcoholStatus: '',
        otherHabits: '',
        mets: '2-3 METs',
        physicalExam: '',
        airway: Airway.empty(),
        mouthOpening: '',
        neckMobility: '',
        dentition: '',
        difficultAirwayPredictors: ['Mallampati III', 'Abertura oral reduzida'],
        otherDifficultAirwayPredictors: '',
        difficultVentilationPredictors: ['Barba', 'OSA'],
        otherDifficultVentilationPredictors: '',
        otherAirwayDetails: '',
        complementaryExamItems: [],
        complementaryExams: '',
        otherComplementaryExams: '',
        fastingSolids: '<6h',
        fastingLiquids: '2h',
        fastingBreastMilk: '',
        fastingNotes: '',
        asaClassification: 'III',
        asaNotes: '',
        anestheticPlan: '',
        otherAnestheticPlan: '',
        restrictionItems: [],
        patientRestrictions: '',
        otherRestrictions: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnesthesiaHeaderWidget(
              patient: Patient(
                name: 'Paciente teste',
                age: 54,
                weightKg: 78,
                heightMeters: 1.7,
                asa: 'III',
                informedConsentStatus: 'Não assinado',
                allergies: ['Látex'],
                restrictions: ['Sem transfusão'],
                medications: ['Losartana'],
              ),
              mallampati: 'III',
              preAnestheticAssessment: assessment,
            ),
          ),
        ),
      );

      final chips = tester.widgetList<ClinicalChip>(find.byType(ClinicalChip));
      final labels = chips.map((chip) => chip.label).toList();

      expect(labels, contains('Perfil'));
      expect(labels, contains('ASA'));
      expect(labels, contains('Consentimento'));
      expect(labels, contains('METS / funcional'));
      expect(labels, contains('Via aérea difícil'));
      expect(labels, contains('Ventilação difícil'));
      expect(labels, contains('Jejum'));

      final airwayChip = chips.firstWhere(
        (chip) => chip.label == 'Via aérea difícil',
      );
      final ventilationChip = chips.firstWhere(
        (chip) => chip.label == 'Ventilação difícil',
      );
      final fastingChip = chips.firstWhere((chip) => chip.label == 'Jejum');

      expect(airwayChip.color, UiColors.danger);
      expect(ventilationChip.color, UiColors.danger);
      expect(fastingChip.color, UiColors.danger);
    },
  );

  testWidgets('allows tapping derived pre-anesthetic chips for editing', (
    WidgetTester tester,
  ) async {
    var metsTapped = false;
    var airwayTapped = false;
    var ventilationTapped = false;
    var fastingTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnesthesiaHeaderWidget(
            patient: const Patient(
              name: 'Paciente teste',
              age: 54,
              weightKg: 78,
              heightMeters: 1.7,
              asa: '',
              allergies: [],
              restrictions: [],
              medications: [],
            ),
            mallampati: '',
            preAnestheticAssessment: const PreAnestheticAssessment.empty(),
            onFunctionalCapacityTap: () {
              metsTapped = true;
            },
            onDifficultAirwayTap: () {
              airwayTapped = true;
            },
            onDifficultVentilationTap: () {
              ventilationTapped = true;
            },
            onFastingTap: () {
              fastingTapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('METS / FUNCIONAL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VIA AÉREA DIFÍCIL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VENTILAÇÃO DIFÍCIL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JEJUM'));
    await tester.pumpAndSettle();

    expect(metsTapped, isTrue);
    expect(airwayTapped, isTrue);
    expect(ventilationTapped, isTrue);
    expect(fastingTapped, isTrue);
  });

  testWidgets(
    'uses neutral colors for absent findings and danger for positive risks',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnesthesiaHeaderWidget(
              patient: Patient(
                name: 'Paciente teste',
                age: 54,
                weightKg: 78,
                heightMeters: 1.7,
                asa: 'II',
                informedConsentStatus: 'Assinado',
                allergies: [],
                restrictions: [],
                medications: ['Losartana'],
              ),
              mallampati: 'II',
              preAnestheticAssessment: PreAnestheticAssessment(
                comorbidities: [],
                otherComorbidities: '',
                currentMedications: [],
                otherMedications: '',
                allergyDescription: '',
                smokingStatus: '',
                alcoholStatus: '',
                otherHabits: '',
                mets: '>4 METs',
                physicalExam: '',
                airway: Airway.empty(),
                mouthOpening: '',
                neckMobility: '',
                dentition: '',
                difficultAirwayPredictors: [],
                otherDifficultAirwayPredictors: '',
                difficultVentilationPredictors: [],
                otherDifficultVentilationPredictors: '',
                otherAirwayDetails: '',
                complementaryExamItems: [],
                complementaryExams: '',
                otherComplementaryExams: '',
                fastingSolids: '>8h',
                fastingLiquids: '',
                fastingBreastMilk: '',
                fastingNotes: '',
                asaClassification: 'II',
                asaNotes: '',
                anestheticPlan: '',
                otherAnestheticPlan: '',
                restrictionItems: [],
                patientRestrictions: '',
                otherRestrictions: '',
              ),
            ),
          ),
        ),
      );

      final chips = tester.widgetList<ClinicalChip>(find.byType(ClinicalChip));
      final profileChip = chips.firstWhere((chip) => chip.label == 'Perfil');
      final asaChip = chips.firstWhere((chip) => chip.label == 'ASA');
      final airwayChip = chips.firstWhere(
        (chip) => chip.label == 'Via aérea difícil',
      );
      final ventilationChip = chips.firstWhere(
        (chip) => chip.label == 'Ventilação difícil',
      );
      final mallampatiChip = chips.firstWhere(
        (chip) => chip.label == 'Mallampati',
      );
      final allergiesChip = chips.firstWhere(
        (chip) => chip.label == 'Alergias',
      );
      final restrictionsChip = chips.firstWhere(
        (chip) => chip.label == 'Restrições',
      );
      final medicationsChip = chips.firstWhere(
        (chip) => chip.label == 'Medicações',
      );

      expect(profileChip.color, UiColors.success);
      expect(asaChip.color, UiColors.success);
      expect(airwayChip.color, UiColors.info);
      expect(ventilationChip.color, UiColors.info);
      expect(mallampatiChip.color, UiColors.success);
      expect(allergiesChip.color, UiColors.info);
      expect(restrictionsChip.color, UiColors.info);
      expect(medicationsChip.color, UiColors.success);
    },
  );

  testWidgets('marks ASA III or higher and positive restrictions in red', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnesthesiaHeaderWidget(
            patient: Patient(
              name: 'Paciente teste',
              age: 54,
              weightKg: 78,
              heightMeters: 1.7,
              asa: 'IV',
              informedConsentStatus: 'Assinado',
              allergies: ['Látex'],
              restrictions: ['Não aceita transfusão'],
              medications: [],
            ),
            mallampati: 'III',
            preAnestheticAssessment: PreAnestheticAssessment.empty(),
          ),
        ),
      ),
    );

    final chips = tester.widgetList<ClinicalChip>(find.byType(ClinicalChip));
    final asaChip = chips.firstWhere((chip) => chip.label == 'ASA');
    final mallampatiChip = chips.firstWhere(
      (chip) => chip.label == 'Mallampati',
    );
    final allergiesChip = chips.firstWhere((chip) => chip.label == 'Alergias');
    final restrictionsChip = chips.firstWhere(
      (chip) => chip.label == 'Restrições',
    );

    expect(asaChip.color, UiColors.danger);
    expect(mallampatiChip.color, UiColors.danger);
    expect(allergiesChip.color, UiColors.danger);
    expect(restrictionsChip.color, UiColors.danger);
  });
}
