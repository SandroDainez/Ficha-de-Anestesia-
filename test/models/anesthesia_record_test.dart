import 'package:anestesia_app/models/anesthesia_record.dart';
import 'package:anestesia_app/models/airway.dart';
import 'package:anestesia_app/models/fluid_balance.dart';
import 'package:anestesia_app/models/hemodynamic_entry.dart';
import 'package:anestesia_app/models/hemodynamic_point.dart';
import 'package:anestesia_app/models/patient.dart';
import 'package:anestesia_app/models/pre_anesthetic_assessment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes and restores anesthesia record', () {
    const record = AnesthesiaRecord(
      patient: Patient(
        name: 'Maria',
        age: 42,
        weightKg: 68,
        heightMeters: 1.65,
        asa: 'II',
        informedConsentStatus: 'Assinado',
        allergies: ['Dipirona'],
        restrictions: ['Nao aceita transfusao'],
        medications: ['Losartana'],
      ),
      preAnestheticAssessment: PreAnestheticAssessment(
        comorbidities: ['HAS'],
        otherComorbidities: '',
        currentMedications: ['Losartana'],
        otherMedications: '',
        allergyDescription: 'Dipirona',
        smokingStatus: 'Nao',
        alcoholStatus: 'Social',
        otherHabits: '',
        mets: '4 METs',
        physicalExam: 'Sem alteracoes relevantes',
        airway: Airway(
          mallampati: 'II',
          cormackLehane: 'I',
          device: 'TOT',
          tubeNumber: '7.5',
          technique: 'Videolaringoscopio',
          observation: 'Sem intercorrencias',
        ),
        mouthOpening: '> 3 dedos',
        neckMobility: 'Preservada',
        dentition: 'Sem protese',
        difficultAirwayPredictors: ['Mallampati III/IV'],
        otherDifficultAirwayPredictors: '',
        difficultVentilationPredictors: ['Obesidade'],
        otherDifficultVentilationPredictors: '',
        otherAirwayDetails: '',
        complementaryExamItems: ['ECG'],
        complementaryExams: 'ECG normal',
        otherComplementaryExams: '',
        fastingSolids: '>8h',
        fastingLiquids: '>4h',
        fastingNotes: '',
        surgeryPriority: 'Eletiva',
        surgeryClearanceStatus: 'Cirurgia liberada',
        surgeryClearanceNotes: '',
        asaClassification: 'II',
        asaNotes: '',
        anestheticPlan: 'Anestesia geral balanceada',
        otherAnestheticPlan: '',
        postoperativePlanningItems: ['Reserva de UTI'],
        otherPostoperativePlanning: 'Sangue reservado',
        planningNotes: 'Chegou compensada.',
        preAnestheticOrientationItems: [],
        preAnestheticOrientationNotes: '',
        anesthesiaTeamRequestItems: [],
        anesthesiaTeamRequestNotes: '',
        restrictionItems: ['Nao aceita transfusao'],
        patientRestrictions: 'Nao aceita transfusao',
        otherRestrictions: '',
      ),
      airway: Airway(
        mallampati: 'II',
        cormackLehane: 'I',
        device: 'TOT',
        tubeNumber: '7.5',
        technique: 'Videolaringoscopio',
        observation: 'Sem intercorrencias',
      ),
      fluidBalance: FluidBalance(
        crystalloids: '1500',
        colloids: '250',
        blood: '0',
        diuresis: '400',
        bleeding: '200',
        spongeCount: '1',
        otherLosses: '50',
      ),
      anesthesiaTechnique: 'Anestesia geral balanceada',
      maintenanceAgents: 'Sevoflurano',
      hemodynamicEntries: [
        HemodynamicEntry(
          time: '00:05',
          heartRate: '78',
          systolic: '120',
          diastolic: '70',
          spo2: '99',
        ),
      ],
      hemodynamicPoints: [HemodynamicPoint(type: 'FC', value: 78, time: 5)],
      hemodynamicMarkers: [
        HemodynamicMarker(
          label: 'Inicio da anestesia',
          time: 0,
          clockTime: '08:00:00',
          recordedAtIso: '2026-03-31T08:00:00.000',
        ),
      ],
      events: ['Inducao sem intercorrencias'],
      drugs: ['Propofol'],
      adjuncts: ['Aquecedor'],
      otherMedications: ['Ondansetrona|4 mg|08:00'],
      vasoactiveDrugs: ['Efedrina|10 mg|08:20'],
      prophylacticAntibiotics: ['Cefazolina|2 g|07:45'],
      fastingHours: '8',
      venousAccesses: ['Jelco 18G MSD'],
      arterialAccesses: ['Radial esquerda'],
      monitoringItems: ['ECG (5 derivações)', 'SpO₂'],
      surgicalSize: 'Medio porte',
      surgeryDescription: 'Colecistectomia',
      surgeryPriority: 'Eletiva',
      surgeonName: 'Dr. Silva',
      assistantNames: ['Dra. Lima'],
      patientDestination: 'RPA',
      otherPatientDestination: 'Observação prolongada',
      operationalNotes: 'Paciente chegou de enfermaria sem intercorrências.',
      safeSurgeryChecklist: ['Paciente identificado'],
      timeOutChecklist: ['Antibiotico realizado'],
      timeOutCompleted: true,
      anesthesiologistName: 'Dr. Costa',
      anesthesiologistCrm: '12345',
      anesthesiologistDetails: 'R3 supervisionado',
    );

    final restored = AnesthesiaRecord.fromJson(record.toJson());

    expect(restored.patient.name, 'Maria');
    expect(restored.patient.informedConsentStatus, 'Assinado');
    expect(restored.preAnestheticAssessment.asaClassification, 'II');
    expect(restored.preAnestheticAssessment.surgeryPriority, 'Eletiva');
    expect(restored.preAnestheticAssessment.postoperativePlanningItems, [
      'Reserva de UTI',
    ]);
    expect(restored.airway.tubeNumber, '7.5');
    expect(restored.fluidBalance.totalBalance, 1000);
    expect(
      restored.hemodynamicEntries.single.formattedBloodPressure,
      '120 / 70',
    );
    expect(restored.hemodynamicPoints.single.type, 'FC');
    expect(restored.hemodynamicMarkers.single.clockTime, '08:00:00');
    expect(restored.events, ['Inducao sem intercorrencias']);
    expect(restored.otherMedications, ['Ondansetrona|4 mg|08:00']);
    expect(restored.vasoactiveDrugs, ['Efedrina|10 mg|08:20']);
    expect(restored.prophylacticAntibiotics, ['Cefazolina|2 g|07:45']);
    expect(restored.fastingHours, '8');
    expect(restored.monitoringItems, ['ECG (5 derivações)', 'SpO₂']);
    expect(restored.surgeryPriority, 'Eletiva');
    expect(restored.patientDestination, 'RPA');
    expect(
      restored.operationalNotes,
      'Paciente chegou de enfermaria sem intercorrências.',
    );
    expect(restored.timeOutCompleted, isTrue);
  });
}
