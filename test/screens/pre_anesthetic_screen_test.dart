import 'package:anestesia_app/models/airway.dart';
import 'package:anestesia_app/models/patient.dart';
import 'package:anestesia_app/models/pre_anesthetic_assessment.dart';
import 'package:anestesia_app/screens/pre_anesthetic_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows GABS header in pre-anesthetic screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PreAnestheticScreen(
          patient: const Patient(
            name: 'Adulto',
            age: 40,
            weightKg: 70,
            heightMeters: 1.7,
            asa: 'II',
            allergies: [],
            restrictions: [],
            medications: [],
          ),
          initialAssessment: const PreAnestheticAssessment.empty(),
          initialConsultationDate: '',
        ),
      ),
    );

    expect(find.text('GABS'), findsOneWidget);
    expect(
      find.text('Grupo de Anestesiologistas da Baixada Santista'),
      findsOneWidget,
    );
    expect(find.text('Consulta pré-anestésica do adulto'), findsOneWidget);
    expect(find.text('Tela inicial'), findsOneWidget);
  });

  testWidgets('shows pediatric antecedent guidance in pre-anesthetic screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PreAnestheticScreen(
          patient: const Patient(
            name: 'Pedro',
            age: 5,
            weightKg: 18,
            heightMeters: 1.08,
            asa: 'I',
            allergies: [],
            restrictions: [],
            medications: [],
            population: PatientPopulation.pediatric,
          ),
          initialAssessment: const PreAnestheticAssessment.empty(),
          initialConsultationDate: '',
        ),
      ),
    );

    await tester.tap(find.text('Antecedentes'));
    await tester.pumpAndSettle();

    expect(find.text('Foco pediátrico'), findsOneWidget);
    expect(find.text('Prematuridade'), findsOneWidget);
    expect(find.text('IVAS recente'), findsOneWidget);
    expect(find.text('Cardiopatia congênita'), findsOneWidget);
    expect(find.text('HAS'), findsNothing);
    expect(find.text('DM'), findsNothing);
    expect(find.text('Doença coronariana'), findsNothing);
  });

  testWidgets(
    'shows surgery priority and postoperative planning for adult pre-anesthetic screen',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: PreAnestheticScreen(
            patient: const Patient(
              name: 'Adulto',
              age: 52,
              weightKg: 82,
              heightMeters: 1.75,
              asa: 'III',
              allergies: [],
              restrictions: [],
              medications: [],
            ),
            initialAssessment: const PreAnestheticAssessment.empty(),
            initialConsultationDate: '',
          ),
        ),
      );

      await tester.tap(find.text('Prioridade cirúrgica'));
      await tester.pumpAndSettle();

      expect(find.text('Eletiva'), findsOneWidget);
      expect(find.text('Urgência'), findsOneWidget);
      expect(find.text('Emergência'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Reservas estratégicas (UTI / Sangue / Outros)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.text('Reservas estratégicas (UTI / Sangue / Outros)'),
      );
      await tester.pumpAndSettle();

      expect(find.text('UTI'), findsOneWidget);
      expect(find.text('Sangue'), findsOneWidget);
      expect(find.text('UTI + sangue'), findsOneWidget);
      expect(find.text('Ventilação pós-operatória'), findsOneWidget);
    },
  );

  testWidgets('shows ASA quick reference in adult pre-anesthetic screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PreAnestheticScreen(
          patient: const Patient(
            name: 'Adulto',
            age: 52,
            weightKg: 82,
            heightMeters: 1.75,
            asa: 'III',
            allergies: [],
            restrictions: [],
            medications: [],
          ),
          initialAssessment: const PreAnestheticAssessment.empty(),
          initialConsultationDate: '',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Classificação ASA'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Classificação ASA'));
    await tester.pumpAndSettle();

    expect(
      find.text('Referencia rapida de ASA (classe e significado)'),
      findsOneWidget,
    );
    expect(find.text('ASA I'), findsOneWidget);
    expect(
      find.text(
        'Paciente saudavel, sem doenca sistemica clinicamente relevante.',
      ),
      findsOneWidget,
    );
    expect(find.text('ASA VI'), findsOneWidget);
    expect(
      find.text('Usado em contexto de captacao de orgaos.'),
      findsOneWidget,
    );
    expect(
      find.text('Use o sufixo E em urgencia/emergencia quando aplicavel.'),
      findsOneWidget,
    );
  });

  testWidgets('groups adult medications and pre-anesthetic orientations', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PreAnestheticScreen(
          patient: const Patient(
            name: 'Adulto',
            age: 52,
            weightKg: 82,
            heightMeters: 1.75,
            asa: 'III',
            allergies: [],
            restrictions: [],
            medications: [],
          ),
          initialAssessment: const PreAnestheticAssessment.empty(),
          initialConsultationDate: '',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Medicações em uso'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Medicações em uso'));
    await tester.pumpAndSettle();

    expect(find.text('Antidiabéticos'), findsOneWidget);
    expect(find.text('Anticoagulantes'), findsOneWidget);
    expect(find.text('IECA / ARB'), findsOneWidget);
    expect(find.text('Metformina (antidiabético)'), findsOneWidget);
    expect(find.text('Losartana (ARB)'), findsOneWidget);

    await tester.tap(find.text('Medicações em uso'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Orientações de pré-anestésico'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Orientações de pré-anestésico'));
    await tester.pumpAndSettle();

    expect(find.text('Anti-hipertensivos'), findsOneWidget);
    expect(find.text('Anticoagulantes orais'), findsOneWidget);
    expect(find.text('Antiagregantes'), findsOneWidget);
    expect(find.text('GLP-1'), findsOneWidget);

    await tester.tap(find.text('Anti-hipertensivos'));
    await tester.pumpAndSettle();

    expect(
      find.text('Manter todos, inclusive no dia da cirurgia'),
      findsOneWidget,
    );
    expect(find.text('Outros'), findsWidgets);

    await tester.tap(find.text('Manter todos, inclusive no dia da cirurgia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter com atenção à PA e volemia'));
    await tester.pumpAndSettle();

    final manterTodosText = tester.widget<Text>(
      find.text('Manter todos, inclusive no dia da cirurgia'),
    );
    final manterAtencaoText = tester.widget<Text>(
      find.text('Manter com atenção à PA e volemia'),
    );
    expect(manterTodosText.style?.color, isNot(const Color(0xFF26384A)));
    expect(manterAtencaoText.style?.color, isNot(const Color(0xFF26384A)));
  });

  testWidgets(
    'shows neonatal medication and exam guidance in pre-anesthetic screen',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: PreAnestheticScreen(
            patient: const Patient(
              name: 'RN',
              age: 0,
              weightKg: 3.0,
              heightMeters: 0.49,
              asa: 'III',
              allergies: [],
              restrictions: [],
              medications: [],
              population: PatientPopulation.neonatal,
              postnatalAgeDays: 2,
              gestationalAgeWeeks: 38,
              birthWeightKg: 2.8,
            ),
            initialAssessment: const PreAnestheticAssessment.empty(),
            initialConsultationDate: '',
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Medicações em uso'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Medicações em uso'));
      await tester.pumpAndSettle();

      expect(find.text('Foco neonatal'), findsOneWidget);
      expect(find.text('Cafeína'), findsOneWidget);
      expect(find.text('Dobutamina (vasoativo)'), findsOneWidget);
      expect(find.text('Dopamina (vasoativo)'), findsOneWidget);
      expect(find.text('Adrenalina (vasoativo)'), findsOneWidget);
      expect(find.text('AAS'), findsNothing);
      expect(find.text('Losartana'), findsNothing);

      await tester.tap(find.text('Medicações em uso'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Exames complementares'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Exames complementares'));
      await tester.pumpAndSettle();

      expect(find.text('Exames por contexto neonatal'), findsOneWidget);
      expect(find.text('Glicemia'), findsOneWidget);
      expect(find.text('Gasometria'), findsOneWidget);
    },
  );

  testWidgets(
    'shows fixed fasting guidance in neonatal pre-anesthetic screen',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: PreAnestheticScreen(
            patient: const Patient(
              name: 'RN',
              age: 0,
              weightKg: 3.1,
              heightMeters: 0.49,
              asa: 'III',
              allergies: [],
              restrictions: [],
              medications: [],
              population: PatientPopulation.neonatal,
              postnatalAgeDays: 4,
              gestationalAgeWeeks: 36,
              birthWeightKg: 2.5,
            ),
            initialAssessment: const PreAnestheticAssessment.empty(),
            initialConsultationDate: '',
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Jejum recomendado'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Jejum recomendado'));
      await tester.pumpAndSettle();

      expect(find.text('Padronizar 8 horas para alimentos.'), findsOneWidget);
      expect(
        find.text('Padronizar 2 horas para líquido claro (água).'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Use o campo Outros quando precisar individualizar a orientação.',
        ),
        findsOneWidget,
      );
      expect(find.text('Leite materno'), findsNothing);
    },
  );

  testWidgets('uses fixed fasting fields for pediatric screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PreAnestheticScreen(
          patient: const Patient(
            name: 'Pedro',
            age: 7,
            weightKg: 24,
            heightMeters: 1.18,
            asa: 'I',
            allergies: [],
            restrictions: [],
            medications: [],
            population: PatientPopulation.pediatric,
          ),
          initialAssessment: const PreAnestheticAssessment.empty(),
          initialConsultationDate: '',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Jejum recomendado'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Jejum recomendado'));
    await tester.pumpAndSettle();

    expect(find.text('Padronizar 8 horas para alimentos.'), findsOneWidget);
    expect(
      find.text('Padronizar 2 horas para líquido claro (água).'),
      findsOneWidget,
    );
    expect(find.text('Jejum para alimentos'), findsOneWidget);
    expect(find.text('Líquido claro (água)'), findsOneWidget);
    expect(find.text('Leite materno'), findsNothing);
    expect(find.text('Outros'), findsWidgets);
  });

  testWidgets(
    'hides adult-centered airway items in neonatal pre-anesthetic screen',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: PreAnestheticScreen(
            patient: const Patient(
              name: 'RN',
              age: 0,
              weightKg: 3.0,
              heightMeters: 0.49,
              asa: 'III',
              allergies: [],
              restrictions: [],
              medications: [],
              population: PatientPopulation.neonatal,
              postnatalAgeDays: 2,
              gestationalAgeWeeks: 38,
              birthWeightKg: 2.8,
            ),
            initialAssessment: const PreAnestheticAssessment.empty(),
            initialConsultationDate: '',
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Avaliação de via aérea'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Avaliação de via aérea'));
      await tester.pumpAndSettle();

      expect(find.text('Mallampati'), findsNothing);
      expect(find.text('Dentição / prótese'), findsNothing);
      expect(find.text('Dentição'), findsNothing);
      expect(find.text('Prótese móvel'), findsNothing);
      expect(find.text('Sem prótese'), findsNothing);
    },
  );

  testWidgets('hides Mallampati in pediatric pre-anesthetic screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PreAnestheticScreen(
          patient: const Patient(
            name: 'Pedro',
            age: 5,
            weightKg: 18,
            heightMeters: 1.08,
            asa: 'I',
            allergies: [],
            restrictions: [],
            medications: [],
            population: PatientPopulation.pediatric,
          ),
          initialAssessment: const PreAnestheticAssessment.empty(),
          initialConsultationDate: '',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Avaliação de via aérea'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Avaliação de via aérea'));
    await tester.pumpAndSettle();

    expect(find.text('Mallampati'), findsNothing);
    expect(
      find.text('Referencia rapida de Mallampati (classe e significado)'),
      findsNothing,
    );
  });

  testWidgets(
    'adapts context and reserve sections for pediatric pre-anesthetic screen',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: PreAnestheticScreen(
            patient: const Patient(
              name: 'Pedro',
              age: 5,
              weightKg: 18,
              heightMeters: 1.08,
              asa: 'I',
              allergies: [],
              restrictions: [],
              medications: [],
              population: PatientPopulation.pediatric,
            ),
            initialAssessment: const PreAnestheticAssessment.empty(),
            initialConsultationDate: '',
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Exposição e sintomas recentes'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Exposição e sintomas recentes'));
      await tester.pumpAndSettle();

      expect(find.text('Tabagismo passivo'), findsOneWidget);
      expect(find.text('Sintomas respiratórios'), findsOneWidget);
      expect(find.text('Álcool'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Reserva funcional pediátrica'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Reserva funcional pediátrica'));
      await tester.pumpAndSettle();

      expect(find.text('Atividade preservada'), findsWidgets);
      expect(find.text('Limitação importante'), findsWidgets);
      expect(find.text('1 MET'), findsNothing);
    },
  );

  testWidgets(
    'adapts context and reserve sections for neonatal pre-anesthetic screen',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: PreAnestheticScreen(
            patient: const Patient(
              name: 'RN',
              age: 0,
              weightKg: 3.0,
              heightMeters: 0.49,
              asa: 'III',
              allergies: [],
              restrictions: [],
              medications: [],
              population: PatientPopulation.neonatal,
              postnatalAgeDays: 2,
              gestationalAgeWeeks: 38,
              birthWeightKg: 2.8,
            ),
            initialAssessment: const PreAnestheticAssessment.empty(),
            initialConsultationDate: '',
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Contexto respiratório neonatal'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Contexto respiratório neonatal'));
      await tester.pumpAndSettle();

      expect(find.text('Suporte respiratório recente'), findsOneWidget);
      expect(find.text('Apneia/bradicardia'), findsOneWidget);
      expect(find.text('Álcool'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Reserva clínica neonatal'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Reserva clínica neonatal'));
      await tester.pumpAndSettle();

      expect(find.text('Estável em ar ambiente'), findsWidgets);
      expect(find.text('Suporte ventilatório'), findsWidgets);
      expect(find.text('1 MET'), findsNothing);
    },
  );

  testWidgets(
    'uses objection wording instead of parental refusal for pediatric restrictions',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: PreAnestheticScreen(
            patient: const Patient(
              name: 'Pedro',
              age: 5,
              weightKg: 18,
              heightMeters: 1.08,
              asa: 'I',
              allergies: [],
              restrictions: [],
              medications: [],
              population: PatientPopulation.pediatric,
            ),
            initialAssessment: const PreAnestheticAssessment.empty(),
            initialConsultationDate: '',
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Consentimento e cuidados especiais'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Consentimento e cuidados especiais'));
      await tester.pumpAndSettle();

      expect(find.text('Objeção familiar a hemocomponentes'), findsOneWidget);
      expect(find.text('Não aceita transfusão'), findsNothing);
    },
  );

  testWidgets(
    'uses objection wording instead of parental refusal for neonatal restrictions',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: PreAnestheticScreen(
            patient: const Patient(
              name: 'RN',
              age: 0,
              weightKg: 3.0,
              heightMeters: 0.49,
              asa: 'III',
              allergies: [],
              restrictions: [],
              medications: [],
              population: PatientPopulation.neonatal,
              postnatalAgeDays: 2,
              gestationalAgeWeeks: 38,
              birthWeightKg: 2.8,
            ),
            initialAssessment: const PreAnestheticAssessment.empty(),
            initialConsultationDate: '',
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Consentimento e suporte necessário'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Consentimento e suporte necessário'));
      await tester.pumpAndSettle();

      expect(find.text('Objeção familiar a hemocomponentes'), findsOneWidget);
      expect(find.text('Não aceita transfusão'), findsNothing);
    },
  );

  testWidgets('shows compact physical exam fields in pre-anesthetic screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PreAnestheticScreen(
          patient: const Patient(
            name: 'Adulto',
            age: 40,
            weightKg: 70,
            heightMeters: 1.7,
            asa: 'II',
            allergies: [],
            restrictions: [],
            medications: [],
          ),
          initialAssessment: const PreAnestheticAssessment.empty(),
          initialConsultationDate: '',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Exame clínico'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Exame clínico'));
    await tester.pumpAndSettle();

    expect(find.text('AC'), findsOneWidget);
    expect(find.text('FC'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('PAS'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('PAS'), findsOneWidget);
    expect(find.text('PAD'), findsOneWidget);
    expect(find.text('AP'), findsOneWidget);
    expect(find.text('Nível de consciência'), findsOneWidget);
    expect(find.text('Outros achados'), findsOneWidget);
    expect(find.text('Escrita livre'), findsOneWidget);
  });

  testWidgets('shows surgery clearance as alert when surgery is not released', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PreAnestheticScreen(
          patient: const Patient(
            name: 'Adulto',
            age: 40,
            weightKg: 70,
            heightMeters: 1.7,
            asa: 'II',
            allergies: [],
            restrictions: [],
            medications: [],
          ),
          initialAssessment: const PreAnestheticAssessment(
            comorbidities: [],
            otherComorbidities: '',
            currentMedications: [],
            otherMedications: '',
            allergyDescription: '',
            smokingStatus: '',
            alcoholStatus: '',
            otherHabits: '',
            mets: '',
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
            fastingSolids: '',
            fastingLiquids: '',
            fastingNotes: '',
            asaClassification: '',
            asaNotes: '',
            anestheticPlan: '',
            otherAnestheticPlan: '',
            preAnestheticOrientationItems: [],
            preAnestheticOrientationNotes: '',
            restrictionItems: [],
            patientRestrictions: '',
            otherRestrictions: '',
            surgeryClearanceStatus: 'Pendente para liberação',
            surgeryClearanceNotes: 'Pendente de exame',
          ),
          initialConsultationDate: '',
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Situação da cirurgia'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Pendente para liberação • Pendente de exame'),
      findsOneWidget,
    );

    final card = tester.widget<Card>(
      find.ancestor(
        of: find.text('Situação da cirurgia'),
        matching: find.byType(Card),
      ),
    );

    expect(card.color, const Color(0xFFFFF7F7));
  });

  testWidgets(
    'shows surgery clearance as completed only when surgery is released',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: PreAnestheticScreen(
            patient: const Patient(
              name: 'Adulto',
              age: 40,
              weightKg: 70,
              heightMeters: 1.7,
              asa: 'II',
              allergies: [],
              restrictions: [],
              medications: [],
            ),
            initialAssessment: const PreAnestheticAssessment(
              comorbidities: [],
              otherComorbidities: '',
              currentMedications: [],
              otherMedications: '',
              allergyDescription: '',
              smokingStatus: '',
              alcoholStatus: '',
              otherHabits: '',
              mets: '',
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
              fastingSolids: '',
              fastingLiquids: '',
              fastingNotes: '',
              asaClassification: '',
              asaNotes: '',
              anestheticPlan: '',
              otherAnestheticPlan: '',
              preAnestheticOrientationItems: [],
              preAnestheticOrientationNotes: '',
              restrictionItems: [],
              patientRestrictions: '',
              otherRestrictions: '',
              surgeryClearanceStatus: 'Cirurgia liberada',
              surgeryClearanceNotes: '',
            ),
            initialConsultationDate: '',
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Situação da cirurgia'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Cirurgia liberada'), findsOneWidget);

      final card = tester.widget<Card>(
        find.ancestor(
          of: find.text('Situação da cirurgia'),
          matching: find.byType(Card),
        ),
      );

      expect(card.color, const Color(0xFFF4FBF6));
    },
  );

  testWidgets('syncs Mallampati III/IV with difficult airway predictor', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PreAnestheticScreen(
          patient: const Patient(
            name: 'Adulto',
            age: 40,
            weightKg: 70,
            heightMeters: 1.7,
            asa: 'II',
            allergies: [],
            restrictions: [],
            medications: [],
          ),
          initialAssessment: const PreAnestheticAssessment.empty(),
          initialConsultationDate: '',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Avaliação de via aérea'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Avaliação de via aérea'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('III'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('III'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Mallampati III/IV'), findsWidgets);
  });

  testWidgets(
    'syncs mouth opening and neck mobility with difficult airway predictors',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: PreAnestheticScreen(
            patient: const Patient(
              name: 'Adulto',
              age: 40,
              weightKg: 70,
              heightMeters: 1.7,
              asa: 'II',
              allergies: [],
              restrictions: [],
              medications: [],
            ),
            initialAssessment: const PreAnestheticAssessment.empty(),
            initialConsultationDate: '',
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Avaliação de via aérea'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Avaliação de via aérea'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('2-3 dedos (3-5 cm)'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('2-3 dedos (3-5 cm)'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Limitada'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Limitada'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Abertura oral reduzida'), findsWidgets);
      expect(find.textContaining('Mobilidade cervical limitada'), findsWidgets);
    },
  );

  testWidgets('airway alert summary shows only risk predictors', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PreAnestheticScreen(
          patient: const Patient(
            name: 'Adulto',
            age: 40,
            weightKg: 70,
            heightMeters: 1.7,
            asa: 'II',
            allergies: [],
            restrictions: [],
            medications: [],
          ),
          initialAssessment: const PreAnestheticAssessment.empty(),
          initialConsultationDate: '',
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Avaliação de via aérea'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Avaliação de via aérea'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('> 3 dedos (> 5 cm)'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('> 3 dedos (> 5 cm)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Limitada'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Limitada'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Intubação difícil'), findsWidgets);
    expect(find.textContaining('Abertura oral: > 3 dedos'), findsNothing);
  });
}
