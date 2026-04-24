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
  return MaterialApp(home: AnesthesiaScreen(initialRecord: record));
}

void main() {
  Future<void> pumpScreen(WidgetTester tester, AnesthesiaRecord record) async {
    await tester.binding.setSurfaceSize(const Size(1600, 2400));
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
      surgeryPriority: 'Eletiva',
      surgeonName: 'Dr. Silva',
      assistantNames: const ['Dra. Lima'],
      patientDestination: 'RPA',
      operationalNotes: 'Paciente chegou em sala colaborativa.',
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
    expect(find.text('Time-out finalizado'), findsWidgets);
    expect(find.byKey(const Key('events-card')), findsOneWidget);
    expect(find.byKey(const Key('fluid-balance-card')), findsOneWidget);
    expect(find.text('VERIFICAR PENDÊNCIAS'), findsOneWidget);
    expect(find.text('FINALIZAR CASO'), findsOneWidget);
  });

  testWidgets(
    'shows antibiotic prophylaxis suggestion from selected surgery in the edit flow',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        prophylacticAntibiotics: const [],
        surgeryDescription: 'Colecistectomia',
      );

      await pumpScreen(tester, record);
      await tester.tap(find.text('7) ANTIBIOTICOPROFILAXIA'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('antibiotic-entry')));
      await tester.pumpAndSettle();

      expect(find.text('Sugestões pela cirurgia selecionada'), findsOneWidget);
      expect(
        find.text('Ginecológica / abdominal limpa-contaminada'),
        findsOneWidget,
      );
      expect(find.text('Cefazolina • Dose: 2 g IV'), findsOneWidget);
      expect(
        find.text(
          'Repique/redose: Redose em 4 h se cirurgia prolongada ou perda sanguínea importante.',
        ),
        findsOneWidget,
      );
      expect(find.text('Aplicar sugestão'), findsOneWidget);
    },
  );

  testWidgets('renumbers cards after fasting moves to the header', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    expect(find.text('CHECKLIST PRÉ-ANESTESIA'), findsOneWidget);
    expect(find.text('7) ANTIBIOTICOPROFILAXIA'), findsOneWidget);
    expect(find.text('8) ACESSO VENOSO'), findsOneWidget);
    expect(find.text('9) ACESSO ARTERIAL'), findsOneWidget);
    expect(find.text('10) MONITORIZAÇÃO'), findsOneWidget);
    expect(find.text('11) TIME-OUT'), findsOneWidget);
    expect(find.text('22) DESTINO PÓS-OPERATÓRIO'), findsOneWidget);
    expect(find.text('21) DESTINO PÓS-OPERATÓRIO'), findsNothing);
  });

  testWidgets(
    'opens quick header editors for METS, airway risk, ventilation and fasting',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        preAnestheticAssessment: buildRecord().preAnestheticAssessment.copyWith(
          mets: '',
          difficultAirwayPredictors: const [],
          difficultVentilationPredictors: const [],
          fastingSolids: '',
          fastingLiquids: '',
        ),
      );

      await pumpScreen(tester, record);

      await tester.tap(find.text('METS / FUNCIONAL').first);
      await tester.pumpAndSettle();
      expect(find.text('METS / capacidade funcional'), findsOneWidget);
      expect(find.text('Boa capacidade funcional.'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VIA AÉREA DIFÍCIL').first);
      await tester.pumpAndSettle();
      expect(find.text('Via aérea difícil'), findsOneWidget);
      expect(find.text('Outros achados (um por linha)'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VENTILAÇÃO DIFÍCIL').first);
      await tester.pumpAndSettle();
      expect(find.text('Ventilação difícil'), findsOneWidget);
      expect(find.text('Outros achados (um por linha)'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('JEJUM').first);
      await tester.pumpAndSettle();
      expect(find.text('Jejum'), findsOneWidget);
      expect(find.text('Líquidos claros'), findsOneWidget);
    },
  );

  testWidgets(
    'shows explanatory choices for ASA and Mallampati from header chips',
    (WidgetTester tester) async {
      await pumpScreen(tester, buildRecord());

      await tester.tap(find.text('ASA').first);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Paciente saudavel, sem doenca sistemica clinicamente relevante.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Doenca sistemica grave que representa ameaca constante a vida.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('MALLAMPATI').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Palato mole, fauces, uvula e pilares visiveis.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Videolaringoscopio/fibroscopia e estrategia de resgate pronta.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('saves functional capacity through the header quick dialog', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      preAnestheticAssessment: buildRecord().preAnestheticAssessment.copyWith(
        mets: '',
      ),
    );

    await pumpScreen(tester, record);

    await tester.tap(find.text('METS / FUNCIONAL').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Boa capacidade funcional.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('>4 METs'), findsOneWidget);
  });

  testWidgets(
    'summarizes pediatric fasting by intake type in anesthesia screen',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        patient: buildRecord().patient.copyWith(
          population: PatientPopulation.pediatric,
        ),
        preAnestheticAssessment: buildRecord().preAnestheticAssessment.copyWith(
          fastingSolids: '6-8h',
          fastingLiquids: '2-4h',
          fastingBreastMilk: '4-6h',
        ),
      );

      await pumpScreen(tester, record);
      await tester.pumpAndSettle();

      expect(find.textContaining('Fórmula/refeição 6-8h'), findsOneWidget);
      expect(find.textContaining('Leite materno 4-6h'), findsOneWidget);
      expect(find.textContaining('Líquidos 2-4h'), findsOneWidget);
    },
  );

  testWidgets('gives hemodynamic chart visual priority in the main layout', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    final airwayRect = tester.getRect(find.byKey(const Key('airway-card')));
    final techniqueRect = tester.getRect(find.byKey(const Key('events-card')));
    final chartRect = tester.getRect(
      find.byKey(const Key('hemodynamic-chart-section')),
    );

    expect(chartRect.width, greaterThan(airwayRect.width));
    expect(chartRect.width, greaterThanOrEqualTo(techniqueRect.width));
    expect(chartRect.left, lessThanOrEqualTo(techniqueRect.left));
    await tester.ensureVisible(find.text('GRÁFICO HEMODINÂMICO'));
    await tester.tap(find.text('GRÁFICO HEMODINÂMICO'));
    await tester.pumpAndSettle();
    expect(find.text('FC atual'), findsOneWidget);
    expect(find.text('PAM'), findsWidgets);
    expect(find.text('Sat'), findsWidgets);
    expect(find.text('pam'), findsNothing);
    expect(find.text('SpO2'), findsNothing);
  });

  testWidgets('opens record analysis dialog from footer action', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.scrollUntilVisible(
      find.text('VERIFICAR PENDÊNCIAS'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('VERIFICAR PENDÊNCIAS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Pendências da ficha'), findsOneWidget);
    expect(find.text('Fechar'), findsOneWidget);
  });

  testWidgets(
    'hemodynamic area starts blocked and unlocks after anesthesia start',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        hemodynamicPoints: const [],
        hemodynamicMarkers: const [],
      );
      await pumpScreen(tester, record);
      await tester.ensureVisible(
        find.byKey(const Key('hemodynamic-chart-section')),
      );
      await tester.tap(find.text('GRÁFICO HEMODINÂMICO'));
      await tester.pumpAndSettle();

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
      expect(find.textContaining('Anestesia: '), findsWidgets);
      expect(
        find.textContaining('Anestesia: Toque para informar'),
        findsNothing,
      );
    },
  );

  testWidgets('shows finish buttons for anesthesia and surgery markers', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(hemodynamicMarkers: const []);
    await pumpScreen(tester, record);
    await tester.ensureVisible(
      find.byKey(const Key('hemodynamic-chart-section')),
    );
    await tester.tap(find.text('GRÁFICO HEMODINÂMICO'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('hemo-start-anesthesia-button')),
    );
    await tester.tap(find.byKey(const Key('hemo-start-anesthesia-button')));
    await tester.pumpAndSettle();

    final endAnesthesiaButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('hemo-end-anesthesia-button')),
    );
    expect(endAnesthesiaButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('hemo-start-surgery-button')));
    await tester.pumpAndSettle();

    final endSurgeryButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('hemo-end-surgery-button')),
    );
    expect(endSurgeryButton.onPressed, isNotNull);
  });

  testWidgets(
    'time-out card shows numbered clickable items and can finalize in place',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        timeOutChecklist: const [],
        timeOutCompleted: false,
      );
      await pumpScreen(tester, record);
      await tester.ensureVisible(find.byKey(const Key('surgery-timeout-card')));

      await tester.tap(find.text('11) TIME-OUT'));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(
        find.text('Equipe identificada por nome e funcao'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('surgery-timeout-item-1')));
      await tester.pumpAndSettle();

      expect(find.text('1 itens confirmados'), findsOneWidget);

      for (var i = 2; i <= 8; i++) {
        await tester.ensureVisible(find.byKey(Key('surgery-timeout-item-$i')));
        await tester.tap(find.byKey(Key('surgery-timeout-item-$i')));
        await tester.pumpAndSettle();
      }

      await tester.ensureVisible(
        find.byKey(const Key('surgery-complete-timeout-button')),
      );
      await tester.tap(
        find.byKey(const Key('surgery-complete-timeout-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Time-out finalizado'), findsWidgets);
    },
  );

  testWidgets(
    'hemodynamic area toggles between register and correction modes',
    (WidgetTester tester) async {
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
      await tester.ensureVisible(
        find.byKey(const Key('hemodynamic-chart-section')),
      );
      await tester.tap(find.text('GRÁFICO HEMODINÂMICO'));
      await tester.pumpAndSettle();

      expect(find.text('Registro'), findsWidgets);
      expect(find.text('Correção'), findsNothing);

      await tester.ensureVisible(
        find.byKey(const Key('hemo-toggle-mode-button')),
      );
      await tester.tap(find.byKey(const Key('hemo-toggle-mode-button')));
      await tester.pumpAndSettle();

      expect(find.text('Modo correção'), findsOneWidget);
      expect(find.text('Correção'), findsOneWidget);
      expect(find.text('Voltar para registro'), findsOneWidget);
    },
  );

  testWidgets('updates anesthetic technique through the edit dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.ensureVisible(find.text('Editar técnica'));
    await tester.tap(find.text('Editar técnica'));
    await tester.pumpAndSettle();

    expect(find.text('Editar Técnica anestésica'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'TIVA'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Bloqueio periférico'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('technique-save-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Editar técnica'));
    await tester.tap(find.text('Editar técnica'));
    await tester.pumpAndSettle();

    final tivaChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'TIVA'),
    );
    final bloqueioChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Bloqueio periférico'),
    );

    expect(tivaChip.selected, isTrue);
    expect(bloqueioChip.selected, isTrue);
  });

  testWidgets('shows anesthetic technique card above the surgical workflow', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    final techniqueRect = tester.getRect(find.byKey(const Key('events-card')));
    final surgeryRect = tester.getRect(
      find.byKey(const Key('surgery-description-card')),
    );

    expect(techniqueRect.top, lessThan(surgeryRect.top));
  });

  testWidgets(
    'hides general anesthesia cards for neuraxial technique with associated sedation',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        anesthesiaTechnique: 'Raquianestesia\nSedação',
        anesthesiaTechniqueDetails:
            'Raquianestesia com sedação associada e sem necessidade de anestesia geral.',
        maintenanceAgents: '',
        drugs: const [],
        sedationMedications: const ['Midazolam|2 mg|08:00'],
        airway: const Airway(
          mallampati: '',
          cormackLehane: '',
          device: '',
          tubeNumber: '',
          technique: '',
          observation: '',
        ),
      );

      await pumpScreen(tester, record);

      expect(find.byKey(const Key('technique-card')), findsOneWidget);
      expect(find.byKey(const Key('neuraxial-needles-card')), findsOneWidget);
      expect(find.byKey(const Key('drugs-card')), findsNothing);
      expect(find.byKey(const Key('maintenance-card')), findsNothing);
      expect(find.byKey(const Key('airway-card')), findsNothing);
    },
  );

  testWidgets(
    'shows induction suggestions by weight and confirms a selected drug',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        drugs: const [],
        patient: buildRecord().patient.copyWith(weightKg: 68),
      );

      await pumpScreen(tester, record);
      await tester.ensureVisible(find.byKey(const Key('drugs-card')));

      await tester.tap(find.text('13) INDUÇÃO'));
      await tester.pumpAndSettle();

      expect(find.text('Propofol'), findsOneWidget);
      expect(find.text('136 mg • ~13.6 mL (10 mg/mL)'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar').first);
      await tester.pumpAndSettle();

      expect(find.text('1 item(ns) registrados'), findsWidgets);
    },
  );

  testWidgets(
    'sedation card is available for techniques that may require associated sedation',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        sedationMedications: const [],
        anesthesiaTechnique: 'Raquianestesia\nBloqueio periférico',
      );

      await pumpScreen(tester, record);
      await tester.ensureVisible(find.byKey(const Key('technique-card')));

      expect(find.text('12) SEDAÇÃO COMPLEMENTAR'), findsOneWidget);
    },
  );

  testWidgets(
    'technique section uses tecnica anestesica and brief editable description',
    (WidgetTester tester) async {
      await pumpScreen(tester, buildRecord());

      expect(find.text('TÉCNICA ANESTÉSICA'), findsOneWidget);
      expect(find.text('Eventos'), findsNothing);

      await tester.tap(find.text('TÉCNICA ANESTÉSICA'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Técnica anestésica'), findsOneWidget);
    },
  );

  testWidgets(
    'preparation card exposes clickable pre-anesthesia checklist items',
    (WidgetTester tester) async {
      await pumpScreen(tester, buildRecord());

      await tester.ensureVisible(find.byKey(const Key('preparation-card')));
      await tester.tap(find.byKey(const Key('preparation-card')));
      await tester.pumpAndSettle();

      expect(find.text('Equipamento de anestesia checado'), findsOneWidget);
      expect(
        find.text('Materiais para intubação disponíveis e testados'),
        findsOneWidget,
      );
      expect(find.text('Termo de consentimento assinado'), findsOneWidget);
      expect(find.text('Pré-anestésico realizado'), findsOneWidget);
      expect(
        find.text('Monitorização instalada e funcionando'),
        findsOneWidget,
      );
      expect(find.text('Acesso venoso pérvio'), findsOneWidget);

      await tester.tap(find.text('Equipamento de anestesia checado'));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsWidgets);
    },
  );

  testWidgets(
    'shows adjunct suggestions by weight and confirms a selected adjunct',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        adjuncts: const [],
        patient: buildRecord().patient.copyWith(weightKg: 68),
      );

      await pumpScreen(tester, record);
      await tester.ensureVisible(find.text('14) ADJUVANTES ANESTÉSICOS'));

      await tester.tap(find.text('14) ADJUVANTES ANESTÉSICOS'));
      await tester.pumpAndSettle();

      expect(find.text('Sulfato de Mg'), findsOneWidget);
      expect(find.text('2720 mg • ~27.2 mL (100 mg/mL)'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar').first);
      await tester.pumpAndSettle();

      expect(find.text('1 item(ns) registrados'), findsWidgets);
    },
  );

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
    await tester.ensureVisible(
      find.text('20) REPOSIÇÃO VOLÊMICA, SANGUE E DERIVADOS'),
    );
    await tester.tap(find.text('20) REPOSIÇÃO VOLÊMICA, SANGUE E DERIVADOS'));
    await tester.pumpAndSettle();

    expect(find.text('Apoio clínico pediátrico'), findsOneWidget);
    expect(find.text('Manutenção: 44 mL/h'), findsOneWidget);
    expect(
      find.text('Cálculo basal por Holliday-Segar (4-2-1).'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Em lactentes pequenos, considerar glicose 1-2,5% com monitorização de glicemia.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows term neonatal fluid support only when age profile allows it',
    (WidgetTester tester) async {
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
      await tester.ensureVisible(
        find.text('20) REPOSIÇÃO VOLÊMICA, SANGUE E DERIVADOS'),
      );
      await tester.tap(find.text('20) REPOSIÇÃO VOLÊMICA, SANGUE E DERIVADOS'));
      await tester.pumpAndSettle();

      expect(find.text('Apoio clínico neonatal'), findsOneWidget);
      expect(find.text('Manutenção: 10-12 mL/h'), findsOneWidget);
      expect(find.text('Neonato termo, 2 dia(s) de vida.'), findsOneWidget);
      expect(
        find.text(
          'Manutenção inicial: cristalóide isotônico com sódio 131-154 mmol/L e glicose 5-10%.',
        ),
        findsOneWidget,
      );
    },
  );

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
    await tester.tap(find.text('15) VIA AÉREA'));
    await tester.pumpAndSettle();

    expect(find.text('Referência pediátrica'), findsOneWidget);
    expect(find.text('TOT com cuff: 5.5 mm'), findsOneWidget);
    expect(find.text('TOT sem cuff: 6 mm'), findsOneWidget);
    expect(find.text('Profundidade oral estimada: 16 cm'), findsOneWidget);
    expect(find.text('Mallampati'), findsNothing);
  });

  testWidgets('airway card uses materiais de apoio label', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.tap(find.text('15) VIA AÉREA'));
    await tester.pumpAndSettle();

    expect(find.text('Materiais de apoio'), findsOneWidget);
    expect(find.text('Observações'), findsNothing);
  });

  testWidgets(
    'shows contextual mechanical ventilation card for general anesthesia and allows editing',
    (WidgetTester tester) async {
      await pumpScreen(tester, buildRecord());

      expect(find.byKey(const Key('ventilation-card')), findsOneWidget);

      await tester.tap(find.text('16) VENTILAÇÃO MECÂNICA'));
      await tester.pumpAndSettle();

      expect(find.text('Sugestão contextual'), findsOneWidget);
      expect(find.textContaining('VT'), findsWidgets);

      await tester.tap(find.byKey(const Key('ventilation-entry')));
      await tester.pumpAndSettle();

      expect(find.text('Ventilação mecânica'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('ventilation-mode-field')),
        'PCV-VG',
      );
      await tester.enterText(
        find.byKey(const Key('ventilation-fio2-field')),
        '45',
      );
      await tester.tap(find.byKey(const Key('ventilation-save-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ventilation-card')), findsOneWidget);
      expect(find.text('Ventilação mecânica'), findsNothing);
    },
  );

  testWidgets(
    'organizes preparation monitoring and timeout before induction workflow',
    (WidgetTester tester) async {
      await pumpScreen(tester, buildRecord());

      final preparationRect = tester.getRect(
        find.byKey(const Key('preparation-card')),
      );
      final timeoutRect = tester.getRect(
        find.byKey(const Key('surgery-timeout-card')),
      );
      final drugsRect = tester.getRect(find.byKey(const Key('drugs-card')));

      expect(preparationRect.top, lessThan(drugsRect.top));
      expect(timeoutRect.top, lessThan(drugsRect.top));
    },
  );

  testWidgets(
    'uses height-based reference weight for adult ventilation suggestion in obesity',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        patient: buildRecord().patient.copyWith(
          weightKg: 110,
          heightMeters: 1.60,
        ),
        surgeryDescription: 'Colecistectomia videolaparoscópica',
      );

      await pumpScreen(tester, record);

      expect(find.textContaining('VT 384 mL'), findsOneWidget);

      await tester.tap(find.text('16) VENTILAÇÃO MECÂNICA'));
      await tester.pumpAndSettle();

      expect(find.textContaining('altura 160 cm'), findsOneWidget);
      expect(find.textContaining('peso de referência 64'), findsOneWidget);
      expect(
        find.textContaining('PEEP e FR um pouco mais altas'),
        findsOneWidget,
      );
    },
  );

  testWidgets('saves emergence and extubation notes through the new card', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    expect(find.text('DESPERTAR / EXTUBAÇÃO'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('emergence-entry')));
    await tester.tap(find.byKey(const Key('emergence-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Despertar / extubação'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Extubado em sala'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('emergence-notes-field')),
      'Aspiradas secreções, reversão adequada e ventilação espontânea eficaz.',
    );
    await tester.tap(find.byKey(const Key('emergence-save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Extubado em sala'), findsWidgets);
    expect(find.textContaining('Aspiradas secreções'), findsOneWidget);
  });

  testWidgets(
    'maintenance card shows clickable groups and inhalational estimate in ml per hour',
    (WidgetTester tester) async {
      await pumpScreen(tester, buildRecord());

      await tester.tap(find.text('17) MANUTENÇÃO DA ANESTESIA'));
      await tester.pumpAndSettle();

      expect(find.text('Anestésicos EV contínuos em bomba'), findsWidgets);
      expect(find.text('Anestésicos inalatórios'), findsWidgets);
      expect(find.text('Opioides EV contínuos em bomba'), findsWidgets);
      expect(find.text('Opioides'), findsWidgets);
      expect(find.text('Bloqueadores neuromusculares'), findsWidgets);
      expect(find.textContaining('EV contínua em bomba'), findsWidgets);
      expect(
        find.textContaining('O₂ 1,0 + ar 1,0 + N₂O 0,0 = FGF 2,0 L/min'),
        findsWidgets,
      );
      expect(find.widgetWithText(FilledButton, 'Confirmar'), findsWidgets);
    },
  );

  testWidgets(
    'maintenance card switches propofol and remifentanil to TIVA labels and updates sevo estimate by FGF',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        anesthesiaTechnique: 'Anestesia venosa total (TIVA)',
      );

      await pumpScreen(tester, record);

      await tester.tap(find.text('17) MANUTENÇÃO DA ANESTESIA'));
      await tester.pumpAndSettle();

      expect(find.text('Manutenção TIVA'), findsWidgets);
      expect(find.text('Anestésicos EV contínuos em bomba'), findsNothing);
      expect(find.textContaining('TIVA em bomba'), findsWidgets);

      await tester.ensureVisible(
        find.byKey(const Key('maintenance-edit-sevoflurano')),
      );
      await tester.tap(find.byKey(const Key('maintenance-edit-sevoflurano')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Oxigênio (O₂)'),
        '2,0',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Ar comprimido'),
        '2,0',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('FGF 4,0 L/min'), findsOneWidget);
    },
  );

  testWidgets('shows accumulated volatile consumption by anesthesia time', (
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
        HemodynamicMarker(
          label: 'Fim da anestesia',
          time: 120,
          clockTime: '10:00:00',
          recordedAtIso: '2026-03-31T10:00:00.000',
        ),
      ],
    );

    await pumpScreen(tester, record);
    await tester.tap(find.text('17) MANUTENÇÃO DA ANESTESIA'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Sevoflurano: 13,1 mL/h • acumulado 26,2 mL em 2,0 h',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'fluid replacement dialog suggests surgical size and supports multiple crystalloid entries',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        surgeryDescription: 'Colecistectomia',
        surgicalSize: '',
        fluidBalance: buildRecord().fluidBalance.copyWith(
          crystalloids: '',
          crystalloidEntries: const [],
        ),
        fastingHours: '8',
      );

      await pumpScreen(tester, record);

      await tester.tap(find.text('20) REPOSIÇÃO VOLÊMICA, SANGUE E DERIVADOS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apoio clínico adulto'));
      await tester.pumpAndSettle();

      expect(find.text('Sugestão automática: Medio'), findsOneWidget);
      expect(find.text('Jejum sem sugestão'), findsOneWidget);
      expect(find.text('Sem intraop sugerida'), findsOneWidget);

      await tester.tap(find.widgetWithText(ActionChip, 'RL +500 mL').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ActionChip, 'SF 0,9% +500 mL').first,
      );
      await tester.pumpAndSettle();

      expect(find.text('RL • 500'), findsOneWidget);
      expect(find.text('SF 0,9% • 500'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('RL • 500'), findsNothing);
      expect(find.text('SF 0,9% • 500'), findsOneWidget);
    },
  );

  testWidgets(
    'blood components are added by unit and converted to average volume in balance flow',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        fluidBalance: buildRecord().fluidBalance.copyWith(
          blood: '',
          bloodEntries: const [],
        ),
      );

      await pumpScreen(tester, record);

      await tester.tap(find.text('20) REPOSIÇÃO VOLÊMICA, SANGUE E DERIVADOS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apoio clínico adulto'));
      await tester.pumpAndSettle();

      expect(find.text('+1 UI Concentrado de hemácias'), findsOneWidget);
      expect(find.text('+1 UI Plasma fresco congelado'), findsOneWidget);
      expect(find.text('Albumina 5% +100 mL'), findsOneWidget);
      expect(find.text('Gelatina'), findsNothing);

      await tester.tap(
        find.widgetWithText(ActionChip, '+1 UI Concentrado de hemácias'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Concentrado de hemácias • 1 UI • 280'), findsOneWidget);
    },
  );

  testWidgets(
    'balance dialog supports partial blood loss and other loss presets',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        fluidBalance: buildRecord().fluidBalance.copyWith(
          bloodLossEntries: const [],
          otherLossEntries: const [],
        ),
      );

      await pumpScreen(tester, record);

      await tester.tap(find.text('21) BALANÇO HÍDRICO'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fluid-balance-entry')));
      await tester.pumpAndSettle();

      expect(find.text('Adicionar perdas sanguíneas parciais'), findsOneWidget);
      expect(find.text('Perdas insensíveis 50 mL/h'), findsOneWidget);
      expect(find.text('Ventilação mecânica 50 mL/h'), findsOneWidget);

      await tester.tap(find.widgetWithText(ActionChip, '100 mL'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ActionChip, 'Perdas insensíveis 50 mL/h'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ActionChip, 'Ventilação mecânica 50 mL/h'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perda parcial • 100'), findsOneWidget);
      expect(find.text('Perdas insensíveis • 50 mL/h • 50'), findsOneWidget);
      expect(find.text('Ventilação mecânica • 50 mL/h • 50'), findsOneWidget);
    },
  );

  testWidgets('arterial access card stays next to venous access in overview', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    final venousRect = tester.getRect(
      find.byKey(const Key('venous-access-card')),
    );
    final arterialRect = tester.getRect(
      find.byKey(const Key('arterial-access-card')),
    );

    expect((arterialRect.top - venousRect.top).abs(), lessThan(5));
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
    await tester.tap(find.text('15) VIA AÉREA'));
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('TÉCNICA ANESTÉSICA'));
    await tester.pumpAndSettle();

    expect(find.text('Máscara laríngea'), findsOneWidget);
    expect(find.text('Bloqueio caudal/regional'), findsOneWidget);
    expect(find.text('TIVA'), findsNothing);
    expect(find.text('Raquianestesia'), findsNothing);
  });

  testWidgets(
    'technique dialog suggests a specific description for combined techniques',
    (WidgetTester tester) async {
      await pumpScreen(tester, buildRecord());

      await tester.ensureVisible(find.text('Editar técnica'));
      await tester.tap(find.text('Editar técnica'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'TIVA'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Bloqueio periférico'));
      await tester.pumpAndSettle();

      final detailsField = tester.widget<TextField>(
        find.byKey(const Key('technique-details-field')),
      );
      final detailsText = detailsField.controller?.text ?? '';

      expect(detailsText, contains('técnica combinada'));
      expect(detailsText, contains('anestesia geral'));
      expect(detailsText, contains('bloqueio'));
    },
  );

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

    expect(find.textContaining('Fórmula/refeição >8h'), findsOneWidget);
  });

  testWidgets('shows pediatric monitoring guidance in the monitoring card', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      patient: buildRecord().patient.copyWith(
        population: PatientPopulation.pediatric,
        age: 6,
      ),
    );

    await pumpScreen(tester, record);

    await tester.tap(find.text('10) MONITORIZAÇÃO'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('ECG (5 derivações)'), findsOneWidget);
    expect(find.text('PA não invasiva'), findsOneWidget);
  });

  testWidgets('saves monitoring items through the monitoring card', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.tap(find.text('10) MONITORIZAÇÃO'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('monitoring-item-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('monitoring-item-4')));
    await tester.pumpAndSettle();

    expect(find.text('2 item(ns) selecionados'), findsOneWidget);
    expect(find.textContaining('Sugeridos ausentes:'), findsOneWidget);
  });

  testWidgets(
    'shows touch-to-fill summary for monitoring and expands on first tap',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(monitoringItems: const []);

      await pumpScreen(tester, record);

      expect(find.text('Monitorização pendente'), findsOneWidget);
      expect(find.text('Toque para preencher'), findsWidgets);
      expect(find.text('ECG (5 derivações)'), findsNothing);

      await tester.tap(find.text('Toque para preencher').first);
      await tester.pumpAndSettle();

      expect(find.text('ECG (5 derivações)'), findsOneWidget);
      expect(find.text('PA não invasiva'), findsOneWidget);
    },
  );

  testWidgets(
    'shows touch-to-fill summary for timeout and expands on first tap',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        timeOutChecklist: const [],
        timeOutCompleted: false,
      );

      await pumpScreen(tester, record);

      expect(find.text('Time-out pendente'), findsOneWidget);
      expect(find.text('Toque para preencher'), findsWidgets);
      expect(find.text('Equipe identificada por nome e funcao'), findsNothing);

      await tester.tap(find.text('11) TIME-OUT'));
      await tester.pumpAndSettle();

      expect(
        find.text('Equipe identificada por nome e funcao'),
        findsOneWidget,
      );
      expect(
        find.text('Paciente, procedimento e sitio confirmados'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'starts inline anesthesia cards collapsed and expands on first tap',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        drugs: const [],
        adjuncts: const [],
        airway: const Airway.empty(),
        maintenanceAgents: '',
        fluidBalance: const FluidBalance.empty(),
      );

      await pumpScreen(tester, record);

      expect(find.text('Nenhuma droga de indução registrada'), findsOneWidget);
      expect(find.text('Nenhum adjuvante registrado'), findsOneWidget);
      expect(find.text('Via aérea pendente'), findsOneWidget);
      expect(
        find.text('Nenhum agente de manutenção registrado'),
        findsOneWidget,
      );
      expect(find.text('Balanço hídrico pendente'), findsOneWidget);

      expect(find.text('Propofol'), findsNothing);
      expect(find.text('Sulfato de Mg'), findsNothing);
      expect(find.text('Dispositivo'), findsNothing);

      await tester.tap(find.byKey(const Key('drugs-card')));
      await tester.pumpAndSettle();
      expect(find.text('Propofol'), findsOneWidget);

      await tester.ensureVisible(find.text('14) ADJUVANTES ANESTÉSICOS'));
      await tester.tap(find.text('14) ADJUVANTES ANESTÉSICOS'));
      await tester.pumpAndSettle();
      expect(find.text('Sulfato de Mg'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('airway-card')));
      await tester.tap(find.byKey(const Key('airway-card')));
      await tester.pumpAndSettle();
      expect(find.text('Dispositivo'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('maintenance-card')));
      await tester.tap(find.byKey(const Key('maintenance-card')));
      await tester.pumpAndSettle();
      expect(find.text('Anestésicos EV contínuos em bomba'), findsWidgets);
    },
  );

  testWidgets(
    'opens antibiotic and access dialogs directly from the compact cards',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        prophylacticAntibiotics: const [],
        venousAccesses: const [],
        arterialAccesses: const [],
      );

      await pumpScreen(tester, record);

      await tester.tap(find.byKey(const Key('antibiotic-entry')));
      await tester.pumpAndSettle();
      expect(find.text('Editar Antibiótico profilaxia'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('venous-access-entry')));
      await tester.pumpAndSettle();
      expect(find.text('Editar Acesso venoso'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('arterial-access-entry')));
      await tester.pumpAndSettle();
      expect(find.text('Editar Acesso arterial'), findsOneWidget);
    },
  );

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
    expect(find.text('1 acesso(s) válido(s) • 0 perda(s)'), findsOneWidget);
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
    expect(find.text('1 acesso(s) válido(s) • 0 perda(s)'), findsOneWidget);
  });

  testWidgets('saves prophylactic antibiotic through the dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.ensureVisible(find.byKey(const Key('antibiotic-entry')).first);
    await tester.tap(find.byKey(const Key('antibiotic-entry')).first);
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

    await tester.ensureVisible(
      find.byKey(const Key('other-medications-entry')),
    );
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
    expect(find.text('1 item(ns) registrados'), findsWidgets);
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
    expect(find.text('1 item(ns) registrados'), findsWidgets);
  });

  testWidgets(
    'neuraxial needle card requests raqui or peridural needles when neuraxial technique is selected',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        anesthesiaTechnique: 'Raquianestesia',
        neuraxialNeedles: const [],
      );

      await pumpScreen(tester, record);
      await tester.ensureVisible(find.text('AGULHAS RAQUI / PERIDURAL'));
      await tester.tap(find.text('AGULHAS RAQUI / PERIDURAL'));
      await tester.pumpAndSettle();

      expect(find.text('AGULHAS RAQUI / PERIDURAL'), findsOneWidget);
      expect(find.text('Nenhuma agulha neuraxial registrada'), findsOneWidget);
      expect(
        find.text('Relacionar agulhas usadas na raqui/peridural'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'usage summary card consolidates medications materials fluids and blood products used',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        drugs: const ['Propofol|150 mg|||2 ampolas'],
        venousAccesses: const ['AVP MSE - 18G'],
        arterialAccesses: const ['PAI - radial esquerda 20G'],
        anesthesiaMaterials: const ['TOT 7,5 1 un'],
        fluidBalance: buildRecord().fluidBalance.copyWith(
          crystalloidEntries: const ['RL|500'],
          bloodEntries: const ['Concentrado de hemácias|1 UI|280'],
        ),
      );

      await pumpScreen(tester, record);
      await tester.ensureVisible(find.text('CONSOLIDADO DE USO'));
      await tester.tap(find.text('CONSOLIDADO DE USO'));
      await tester.pumpAndSettle();

      expect(find.text('Indução: Propofol • 2 ampolas'), findsOneWidget);
      expect(find.text('Via aérea: TOT 7.5 • 1 un'), findsOneWidget);
      expect(find.text('Acesso venoso: AVP MSE - 18G • 1 un'), findsOneWidget);
      expect(
        find.text('Acesso arterial: PAI - radial esquerda 20G • 1 un'),
        findsOneWidget,
      );
      expect(find.text('Cristaloides: RL • 500 mL'), findsOneWidget);
      expect(
        find.text(
          'Sangue e derivados: Concentrado de hemácias • 1 UI • 280 mL',
        ),
        findsOneWidget,
      );
      expect(find.text('Ajuste manual: TOT 7,5 1 un'), findsNothing);
    },
  );

  testWidgets('manual additional items keep previously added entries', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(anesthesiaMaterials: const []);

    await pumpScreen(tester, record);
    await tester.ensureVisible(find.byKey(const Key('materials-entry')));
    await tester.tap(find.byKey(const Key('materials-entry')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Itens extras / ajustes / quantidades'),
      'Seringa 20 mL 2 un',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar item'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Itens extras / ajustes / quantidades'),
      'Extensor 1 un',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Adicionar item'));
    await tester.pumpAndSettle();

    expect(find.text('Seringa 20 mL 2 un'), findsWidgets);
    expect(find.text('Extensor 1 un'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('materials-entry')));
    await tester.tap(find.byKey(const Key('materials-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Seringa 20 mL 2 un'), findsWidgets);
    expect(find.text('Extensor 1 un'), findsWidgets);
  });

  testWidgets(
    'usage summary includes fresh gas consumption and manual oxygen therapy totals',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(
        maintenanceAgents:
            'Sevoflurano|Anestésicos inalatórios|2,0 vol% • O₂ 2,0 + ar 1,0 + N₂O 1,0 = FGF 4,0 L/min • ~26,4 mL/h|4.0|2.0|2.0|1.0|1.0',
        anesthesiaMaterials: const ['__OXY__|mascara|5.0|30'],
        hemodynamicMarkers: const [
          HemodynamicMarker(
            label: 'Início da anestesia',
            time: 0,
            clockTime: '10:00:00',
            recordedAtIso: '2026-04-23T10:00:00.000',
          ),
          HemodynamicMarker(
            label: 'Fim da anestesia',
            time: 60,
            clockTime: '11:00:00',
            recordedAtIso: '2026-04-23T11:00:00.000',
          ),
        ],
      );

      await pumpScreen(tester, record);
      await tester.ensureVisible(find.text('CONSOLIDADO DE USO'));
      await tester.tap(find.text('CONSOLIDADO DE USO'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Gases medicinais: Oxigênio (O₂) • 120 L • Sevoflurano (O₂) 2,0 L/min • 1,0 h',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Gases medicinais: Ar comprimido • 60 L • Sevoflurano (ar) 1,0 L/min • 1,0 h',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Gases medicinais: Óxido nitroso (N₂O) • 60 L • Sevoflurano (N₂O) 1,0 L/min • 1,0 h',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Oxigenoterapia: Máscara de O₂ • 150 L • 5,0 L/min • 30 min'),
        findsOneWidget,
      );
    },
  );

  testWidgets('manual oxygen therapy entries persist in materials dialog', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(anesthesiaMaterials: const []);

    await pumpScreen(tester, record);
    await tester.ensureVisible(find.byKey(const Key('materials-entry')));
    await tester.tap(find.byKey(const Key('materials-entry')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('O₂ em cateter'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Fluxo de O₂ (L/min)'),
      '3',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Tempo utilizado (min)'),
      '20',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Adicionar oxigenoterapia'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Cateter de O₂ • 3,0 L/min • 20 min • consumo 60 L'),
      findsWidgets,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('materials-entry')));
    await tester.tap(find.byKey(const Key('materials-entry')));
    await tester.pumpAndSettle();

    expect(
      find.text('Cateter de O₂ • 3,0 L/min • 20 min • consumo 60 L'),
      findsWidgets,
    );
  });

  testWidgets('venous access dialog records lost material with justification', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(venousAccesses: const []);

    await pumpScreen(tester, record);

    await tester.tap(find.byKey(const Key('venous-access-entry')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Material'),
      'AVP MSE - 20G',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Quantidade'),
      '2 un',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Justificativa'),
      'duas tentativas sem sucesso',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Adicionar perda/consumo'),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Perda: AVP MSE - 20G • 2 un • duas tentativas sem sucesso',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CONSOLIDADO DE USO'));
    await tester.tap(find.text('CONSOLIDADO DE USO'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Perda de material: AVP MSE - 20G • 2 un • duas tentativas sem sucesso',
      ),
      findsOneWidget,
    );
  });

  testWidgets('completes time-out flow through the surgery dialog', (
    WidgetTester tester,
  ) async {
    final record = buildRecord().copyWith(
      timeOutChecklist: const [],
      timeOutCompleted: false,
    );
    await pumpScreen(tester, record);

    await tester.tap(find.text('11) TIME-OUT'));
    await tester.pumpAndSettle();

    expect(find.text('11) TIME-OUT'), findsOneWidget);

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
      await tester.ensureVisible(find.text(item));
      await tester.tap(find.text(item));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const Key('surgery-complete-timeout-button')));
    await tester.pumpAndSettle();

    expect(find.text('Time-out finalizado'), findsWidgets);
    expect(find.text('8 itens confirmados'), findsWidgets);
  });

  testWidgets(
    'updates surgery priority destination and notes through surgery dialog',
    (WidgetTester tester) async {
      await pumpScreen(tester, buildRecord());

      await tester.tap(find.byKey(const Key('surgery-priority-entry')).first);
      await tester.pumpAndSettle();

      expect(find.text('Tipo de cirurgia'), findsWidgets);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Urgência'));
      await tester.tap(find.byKey(const Key('surgery-save-button')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('surgery-destination-entry')).first,
      );
      await tester.tap(
        find.byKey(const Key('surgery-destination-entry')).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Destino pós-operatório'), findsWidgets);
      await tester.tap(find.widgetWithText(ChoiceChip, 'UTI'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('surgery-other-destination-field')),
        'leito reservado',
      );
      await tester.tap(find.byKey(const Key('surgery-save-button')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('surgery-notes-entry')).first,
      );
      await tester.tap(find.byKey(const Key('surgery-notes-entry')).first);
      await tester.pumpAndSettle();

      expect(find.text('Anotações relevantes'), findsWidgets);
      await tester.enterText(
        find.byType(TextField).last,
        'Paciente chegou com acesso periférico único.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Urgência'), findsWidgets);
      expect(find.textContaining('UTI • leito reservado'), findsOneWidget);
      expect(
        find.textContaining('Paciente chegou com acesso periférico único.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'updates surgery description through preset cards in surgery dialog',
    (WidgetTester tester) async {
      final record = buildRecord().copyWith(surgeryDescription: '');

      await pumpScreen(tester, record);

      await tester.tap(
        find.byKey(const Key('surgery-description-entry')).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Principais cirurgias'), findsOneWidget);
      expect(find.text('Histerectomia por vídeo'), findsWidgets);
      expect(find.text('Vídeo colecistectomia'), findsOneWidget);

      await tester.tap(find.text('Histerectomia por vídeo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('surgery-description-field')),
        'Outras: laparoscopia diagnóstica',
      );
      await tester.tap(find.byKey(const Key('surgery-save-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Histerectomia por vídeo'), findsWidgets);
      expect(
        find.textContaining('Outras: laparoscopia diagnóstica'),
        findsOneWidget,
      );
    },
  );

  testWidgets('updates airway technique through the airway dialog', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, buildRecord());

    await tester.tap(find.text('15) VIA AÉREA'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('airway-technique-entry')));
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

    await tester.tap(find.text('21) BALANÇO HÍDRICO'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('fluid-balance-entry')));
    await tester.tap(find.byKey(const Key('fluid-balance-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Editar Balanço hídrico'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('fluid-diuresis-field')),
      '400',
    );
    await tester.enterText(
      find.byKey(const Key('fluid-bleeding-field')),
      '200',
    );
    await tester.enterText(
      find.byKey(const Key('fluid-sponge-count-field')),
      '2',
    );
    await tester.enterText(
      find.byKey(const Key('fluid-other-losses-field')),
      '50',
    );
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

    await tester.tap(find.text('13) INDUÇÃO'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Edição avançada').first);
    await tester.tap(find.text('Edição avançada').first);
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
    expect(find.text('2 item(ns) registrados'), findsWidgets);
  });
}
