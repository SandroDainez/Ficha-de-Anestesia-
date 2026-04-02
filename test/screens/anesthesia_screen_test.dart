import 'package:anestesia_app/models/anesthesia_record.dart';
import 'package:anestesia_app/models/airway.dart';
import 'package:anestesia_app/models/fluid_balance.dart';
import 'package:anestesia_app/models/hemodynamic_point.dart';
import 'package:anestesia_app/models/patient.dart';
import 'package:anestesia_app/models/pre_anesthetic_assessment.dart';
import 'package:anestesia_app/screens/anesthesia_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTestableApp(AnesthesiaRecord record) {
  return MaterialApp(
    home: AnesthesiaScreen(initialRecord: record),
  );
}

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    AnesthesiaRecord record,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestableApp(record));
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
      preAnestheticAssessment: const PreAnestheticAssessment(
        comorbidities: ['HAS'],
        otherComorbidities: '',
        currentMedications: ['Losartana'],
        otherMedications: '',
        allergyDescription: 'Latex',
        smokingStatus: 'Nao',
        alcoholStatus: 'Social',
        otherHabits: '',
        mets: '4 METs',
        physicalExam: 'Sem alteracoes',
        airway: Airway(
          mallampati: 'II',
          cormackLehane: '',
          device: 'TOT',
          tubeNumber: '7.5',
          technique: 'Videolaringoscopio',
          observation: '',
        ),
        mouthOpening: '> 3 dedos',
        neckMobility: 'Preservada',
        dentition: 'Sem protese',
        difficultAirwayPredictors: [],
        otherDifficultAirwayPredictors: '',
        difficultVentilationPredictors: [],
        otherDifficultVentilationPredictors: '',
        otherAirwayDetails: '',
        complementaryExamItems: [],
        complementaryExams: '',
        otherComplementaryExams: '',
        fastingSolids: '>8h',
        fastingLiquids: '>4h',
        fastingNotes: '',
        asaClassification: 'II',
        asaNotes: '',
        anestheticPlan: 'Anestesia geral balanceada',
        otherAnestheticPlan: '',
        restrictionItems: ['Nao aceita transfusao'],
        patientRestrictions: 'Nao aceita transfusao',
        otherRestrictions: '',
      ),
      airway: const Airway(
        mallampati: 'II',
        cormackLehane: 'I',
        device: 'TOT',
        tubeNumber: '7.5',
        technique: 'Videolaringoscopio',
        observation: 'Sem dificuldade',
      ),
      anesthesiaTechnique: 'Anestesia geral balanceada',
      maintenanceAgents: 'Sevoflurano\nRemifentanil',
      fluidBalance: const FluidBalance(
        crystalloids: '1500',
        colloids: '0',
        blood: '0',
        diuresis: '300',
        bleeding: '150',
        spongeCount: '',
        otherLosses: '',
      ),
      drugs: const ['Propofol|150 mg|08:00'],
      events: const ['08:05|Inducao|Sem intercorrencias.'],
      hemodynamicPoints: const [
        HemodynamicPoint(type: 'PAS', value: 120, time: 5),
        HemodynamicPoint(type: 'PAD', value: 70, time: 5),
        HemodynamicPoint(type: 'FC', value: 78, time: 5),
        HemodynamicPoint(type: 'SpO2', value: 99, time: 5),
      ],
      anesthesiologistName: 'Dr. Costa',
      anesthesiologistCrm: '12345',
      anesthesiologistDetails: 'Equipe A',
      surgeryDescription: 'Colecistectomia',
      surgeonName: 'Dr. Silva',
      assistantNames: const ['Dra. Lima'],
      timeOutChecklist: const ['Paciente identificado'],
      timeOutCompleted: true,
    );
  }

  testWidgets('renders anesthesia record main sections and values', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    expect(find.text('GABS'), findsOneWidget);
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('Colecistectomia'), findsOneWidget);
    expect(find.text('Time-out finalizado'), findsOneWidget);
    expect(find.text('Anestesia geral balanceada'), findsOneWidget);
    expect(find.text('+1050 mL'), findsOneWidget);
    expect(find.text('VERIFICAR FICHA COM IA'), findsOneWidget);
    expect(find.text('FINALIZAR CASO'), findsOneWidget);
  });

  testWidgets('summarizes pediatric fasting by intake type in anesthesia screen', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      patient: buildRecord().patient.copyWith(population: PatientPopulation.pediatric),
      preAnestheticAssessment: buildRecord().preAnestheticAssessment.copyWith(
        fastingSolids: '6-8h',
        fastingLiquids: '2-4h',
        fastingBreastMilk: '4-6h',
      ),
    );

    await pumpScreen(tester, record);
    await tester.pumpAndSettle();

    expect(find.textContaining('Formula/refeicao: 6-8h'), findsOneWidget);
    expect(find.textContaining('Leite materno: 4-6h'), findsOneWidget);
    expect(find.textContaining('Liquidos claros: 2-4h'), findsOneWidget);
  });

  testWidgets('gives hemodynamic chart visual priority in the main layout', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    final airwayRect = tester.getRect(find.byKey(const Key('airway-card')));
    final techniqueRect = tester.getRect(find.byKey(const Key('technique-card')));
    final chartRect =
        tester.getRect(find.byKey(const Key('hemodynamic-chart-section')));

    expect(chartRect.width, greaterThan(airwayRect.width));
    expect(chartRect.width, greaterThan(techniqueRect.width));
    expect(chartRect.left, lessThanOrEqualTo(techniqueRect.left));
    expect(find.text('FC atual'), findsOneWidget);
  });

  testWidgets('opens record analysis dialog from footer action', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.scrollUntilVisible(
      find.text('VERIFICAR FICHA COM IA'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('VERIFICAR FICHA COM IA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Análise da ficha'), findsOneWidget);
    expect(
      find.text(
        'Ficha anestésica global consistente para revisão final, sem campos obrigatórios pendentes.',
      ),
      findsOneWidget,
    );
    expect(find.text('Fechar'), findsOneWidget);
  });

  testWidgets('hemodynamic area starts blocked and unlocks after anesthesia start', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      hemodynamicPoints: const [],
      hemodynamicMarkers: const [],
    );
    await pumpScreen(tester, record);

    expect(find.text('Aguardando início'), findsWidgets);

    final surgeryButton = tester.widget<FilledButton>(
      find.byKey(const Key('hemo-start-surgery-button')),
    );
    expect(surgeryButton.onPressed, isNull);

    await tester.ensureVisible(
      find.byKey(const Key('hemo-start-anesthesia-button')),
    );
    await tester.tap(find.byKey(const Key('hemo-start-anesthesia-button')));
    await tester.pumpAndSettle();

    expect(find.text('Modo lançamento'), findsOneWidget);
    expect(find.textContaining('Aferição atual:'), findsOneWidget);

    final updatedSurgeryButton = tester.widget<FilledButton>(
      find.byKey(const Key('hemo-start-surgery-button')),
    );
    expect(updatedSurgeryButton.onPressed, isNotNull);
  });

  testWidgets('hemodynamic area toggles between register and correction modes', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      hemodynamicMarkers: const [
        HemodynamicMarker(
          label: 'Início da anestesia',
          time: 0,
          clockTime: '08:00:00',
          recordedAtIso: '2026-03-31T08:00:00.000',
        ),
      ],
    );
    await pumpScreen(tester, record);

    expect(find.text('Registro'), findsOneWidget);
    expect(find.text('Correção'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('hemo-toggle-mode-button')));
    await tester.tap(find.byKey(const Key('hemo-toggle-mode-button')));
    await tester.pumpAndSettle();

    expect(find.text('Modo correção'), findsOneWidget);
    expect(find.text('Correção'), findsOneWidget);
    expect(find.text('Voltar para registro'), findsOneWidget);
  });

  testWidgets('updates anesthetic technique through the edit dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.tap(find.byKey(const Key('technique-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Editar Técnica anestésica'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'TIVA'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Bloqueio periférico'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('technique-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('TIVA'), findsOneWidget);
    expect(find.text('Bloqueio periférico'), findsOneWidget);
  });

  testWidgets('shows pediatric fluid support based on Holliday-Segar', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      patient: buildRecord().patient.copyWith(
        population: PatientPopulation.pediatric,
        age: 1,
        weightKg: 12,
        heightMeters: 0.82,
      ),
    );

    await pumpScreen(tester, record);

    expect(find.text('Apoio clínico pediátrico'), findsOneWidget);
    expect(find.text('Manutenção: 44 mL/h'), findsOneWidget);
    expect(find.text('Cálculo basal por Holliday-Segar (4-2-1).'), findsOneWidget);
    expect(
      find.text(
        'Em lactentes pequenos, considerar glicose 1-2,5% com monitorização de glicemia.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows term neonatal fluid support only when age profile allows it', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      patient: buildRecord().patient.copyWith(
        population: PatientPopulation.neonatal,
        age: 0,
        weightKg: 3.5,
        heightMeters: 0.5,
        postnatalAgeDays: 2,
        gestationalAgeWeeks: 39,
        birthWeightKg: 3.2,
      ),
    );

    await pumpScreen(tester, record);

    expect(find.text('Apoio clínico neonatal'), findsOneWidget);
    expect(find.text('Manutenção: 10-12 mL/h'), findsOneWidget);
    expect(find.text('Neonato termo, 2 dia(s) de vida.'), findsOneWidget);
    expect(
      find.text(
        'Manutenção inicial: cristalóide isotônico com sódio 131-154 mmol/L e glicose 5-10%.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows pediatric airway reference support in the airway card', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      patient: buildRecord().patient.copyWith(
        population: PatientPopulation.pediatric,
        age: 8,
        weightKg: 26,
        heightMeters: 1.22,
      ),
    );

    await pumpScreen(tester, record);

    expect(find.text('Referência pediátrica'), findsOneWidget);
    expect(find.text('TOT com cuff: 5.5 mm'), findsOneWidget);
    expect(find.text('TOT sem cuff: 6 mm'), findsOneWidget);
    expect(find.text('Profundidade oral estimada: 16 cm'), findsOneWidget);
    expect(find.text('Mallampati'), findsNothing);
  });

  testWidgets('shows neonatal airway reference support in the airway card', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      patient: buildRecord().patient.copyWith(
        population: PatientPopulation.neonatal,
        age: 0,
        weightKg: 3.1,
        heightMeters: 0.49,
        gestationalAgeWeeks: 39,
        postnatalAgeDays: 1,
        birthWeightKg: 3.0,
      ),
    );

    await pumpScreen(tester, record);

    expect(find.text('Referência neonatal'), findsOneWidget);
    expect(find.text('TOT inicial por peso: 3,5 mm'), findsOneWidget);
    expect(find.text('Profundidade labial estimada: 9,1 cm'), findsOneWidget);
    expect(find.text('Mallampati'), findsNothing);
  });

  testWidgets('shows pediatric technique options instead of adult defaults', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      patient: buildRecord().patient.copyWith(
        population: PatientPopulation.pediatric,
        age: 5,
      ),
    );

    await pumpScreen(tester, record);

    await tester.tap(find.byKey(const Key('technique-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Máscara laríngea'), findsOneWidget);
    expect(find.text('Bloqueio caudal/regional'), findsOneWidget);
    expect(find.text('TIVA'), findsNothing);
    expect(find.text('Raquianestesia'), findsNothing);
  });

  testWidgets('shows pediatric fasting guidance in the fasting card summary', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      patient: buildRecord().patient.copyWith(
        population: PatientPopulation.pediatric,
        age: 5,
      ),
      fastingHours: '6',
    );

    await pumpScreen(tester, record);

    expect(
      find.text('Referência pediátrica: claros 2 h, leite materno 4 h, fórmula 6 h'),
      findsOneWidget,
    );
  });

  testWidgets('shows pediatric monitoring guidance in the monitoring dialog', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      patient: buildRecord().patient.copyWith(
        population: PatientPopulation.pediatric,
        age: 6,
      ),
    );

    await pumpScreen(tester, record);

    await tester.tap(find.text('Nenhum item de monitorização'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Monitorização'), findsOneWidget);
    expect(find.text('Sugestão pediátrica'), findsOneWidget);
    expect(
      find.text(
        'Monitorização básica intraoperatória: ECG, PA não invasiva, SpO₂, capnografia e temperatura.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('saves monitoring items through the monitoring dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.tap(find.text('Nenhum item de monitorização'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'ECG (5 derivações)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'SpO₂'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('ECG (5 derivações), SpO₂'), findsOneWidget);
    expect(find.textContaining('Sugeridos ausentes:'), findsOneWidget);
  });

  testWidgets('saves venous access through the dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.ensureVisible(find.byKey(const Key('venous-access-entry')));
    await tester.tap(find.byKey(const Key('venous-access-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Editar Acesso venoso'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'MSE');
    await tester.tap(find.widgetWithText(ChoiceChip, '18'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar AVP'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('AVP MSE - 18G'), findsOneWidget);
    expect(find.text('1 acesso registrado'), findsOneWidget);
  });

  testWidgets('saves arterial access through the dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.ensureVisible(find.byKey(const Key('arterial-access-entry')));
    await tester.tap(find.byKey(const Key('arterial-access-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Editar Acesso arterial'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'radial esquerda 20G');
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar PAI'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('PAI - radial esquerda 20G'), findsWidgets);
    expect(find.text('1 acesso registrado'), findsOneWidget);
  });

  testWidgets('saves prophylactic antibiotic through the dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.ensureVisible(find.byKey(const Key('antibiotic-entry')));
    await tester.tap(find.byKey(const Key('antibiotic-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Editar Antibiótico profilaxia'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('catalog-dose-field-Cefazolina')),
      '2 g',
    );
    await tester.enterText(
      find.byKey(const Key('catalog-time-field-Cefazolina')),
      '07:45',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cefazolina'), findsWidgets);
    expect(find.textContaining('07:45'), findsWidgets);
  });

  testWidgets('saves other medications through the dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.ensureVisible(find.byKey(const Key('other-medications-entry')));
    await tester.tap(find.byKey(const Key('other-medications-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Editar Outras medicações'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('catalog-dose-field-Dexametasona')),
      '8 mg',
    );
    await tester.enterText(
      find.byKey(const Key('catalog-time-field-Dexametasona')),
      '08:10',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Dexametasona'), findsWidgets);
    expect(find.textContaining('Inicial: 8 mg'), findsOneWidget);
  });

  testWidgets('saves vasoactive drugs through the dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.ensureVisible(find.byKey(const Key('vasoactive-entry')));
    await tester.tap(find.byKey(const Key('vasoactive-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Editar Drogas vasoativas'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('vasoactive-dose-field-Etilefrina')),
      '10 mg',
    );
    await tester.enterText(
      find.byKey(const Key('vasoactive-time-field-Etilefrina')),
      '08:30',
    );
    await tester.enterText(
      find.byKey(const Key('vasoactive-repeat-field-Etilefrina')),
      '5 mg 08:45',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Etilefrina'), findsWidgets);
    expect(find.textContaining('Inicial: 10 mg'), findsOneWidget);
    expect(find.textContaining('Repiques: 5 mg 08:45'), findsOneWidget);
  });

  testWidgets('adds FC through manual hemodynamic entry dialog', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      hemodynamicPoints: const [],
      hemodynamicMarkers: const [
        HemodynamicMarker(
          label: 'Início da anestesia',
          time: 0,
          clockTime: '08:00:00',
          recordedAtIso: '2026-03-31T08:00:00.000',
        ),
      ],
    );

    await pumpScreen(tester, record);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'FC'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'FC'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('hemo-manual-entry-button')));
    await tester.tap(find.byKey(const Key('hemo-manual-entry-button')));
    await tester.pumpAndSettle();

    expect(find.text('Lançar FC'), findsWidgets);
    await tester.enterText(find.byType(TextField).last, '88');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('88'), findsWidgets);
  });

  testWidgets('completes time-out flow through the surgery dialog', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      timeOutChecklist: const [],
      timeOutCompleted: false,
    );
    await pumpScreen(tester, record);

    await tester.tap(find.byKey(const Key('surgery-timeout-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Time-out'), findsOneWidget);

    const timeOutItems = [
      'Equipe identificada por nome e funcao',
      'Paciente, procedimento e sitio confirmados',
      'Alergias conferidas',
      'Antibioticoprofilaxia realizada no tempo correto',
      'Exames e imagens disponiveis',
      'Risco hemorragico discutido',
      'Plano anestesico e via aerea discutidos',
      'Instrumentais e equipamentos conferidos',
    ];

    for (final item in timeOutItems) {
      await tester.ensureVisible(find.text(item).last);
      await tester.tap(find.text(item).last);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const Key('surgery-complete-timeout-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('surgery-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Time-out finalizado'), findsOneWidget);
    expect(find.text('8 itens confirmados'), findsOneWidget);
  });

  testWidgets('updates airway technique through the airway dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.tap(find.byKey(const Key('airway-technique-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Técnica de intubação'), findsWidgets);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Fibroscopia'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('airway-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Fibroscopia'), findsOneWidget);
  });

  testWidgets('updates fluid balance through the edit dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.ensureVisible(find.byKey(const Key('fluid-balance-entry')));
    await tester.tap(find.byKey(const Key('fluid-balance-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Editar Balanço hídrico'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('fluid-diuresis-field')), '400');
    await tester.enterText(find.byKey(const Key('fluid-bleeding-field')), '200');
    await tester.enterText(find.byKey(const Key('fluid-sponge-count-field')), '2');
    await tester.enterText(find.byKey(const Key('fluid-other-losses-field')), '50');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fluid-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('400 mL'), findsOneWidget);
    expect(find.text('200 mL'), findsOneWidget);
    expect(find.text('2 un • 200 mL'), findsOneWidget);
    expect(find.text('50 mL'), findsOneWidget);
    expect(find.text('+650 mL'), findsOneWidget);
  });

  testWidgets('updates drugs through the edit dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.ensureVisible(find.byKey(const Key('drugs-entry')));
    await tester.tap(find.byKey(const Key('drugs-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Editar Indução (Drogas)'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('drug-dose-field-Remifentanil')),
      '0,08 mcg/kg/min',
    );
    await tester.enterText(
      find.byKey(const Key('drug-time-field-Remifentanil')),
      '09:15',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drug-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Remifentanil'), findsWidgets);
    expect(find.textContaining('Inicial: 0,08 mcg/kg/min'), findsOneWidget);
    expect(find.text('09:15'), findsOneWidget);
  });

  testWidgets('updates events through the edit dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.ensureVisible(find.byKey(const Key('events-entry')));
    await tester.tap(find.byKey(const Key('events-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Editar Eventos'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Extubação'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('event-time-field')), '09:30');
    await tester.enterText(
      find.byKey(const Key('event-details-field')),
      'Sem intercorrências na saída',
    );
    await tester.tap(find.byKey(const Key('event-add-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('event-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('09:30'), findsOneWidget);
    expect(find.text('EXTUBAÇÃO'), findsOneWidget);
    expect(find.text('Sem intercorrências na saída'), findsOneWidget);
  });
}
