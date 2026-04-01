import 'airway.dart';

class PreAnestheticAssessment {
  const PreAnestheticAssessment({
    required this.comorbidities,
    required this.otherComorbidities,
    required this.currentMedications,
    required this.otherMedications,
    required this.allergyDescription,
    required this.smokingStatus,
    required this.alcoholStatus,
    required this.otherHabits,
    required this.mets,
    required this.physicalExam,
    required this.airway,
    required this.mouthOpening,
    required this.neckMobility,
    required this.dentition,
    required this.difficultAirwayPredictors,
    required this.otherDifficultAirwayPredictors,
    required this.difficultVentilationPredictors,
    required this.otherDifficultVentilationPredictors,
    required this.otherAirwayDetails,
    required this.complementaryExamItems,
    required this.complementaryExams,
    required this.otherComplementaryExams,
    required this.fastingSolids,
    required this.fastingLiquids,
    required this.fastingNotes,
    required this.asaClassification,
    required this.asaNotes,
    required this.anestheticPlan,
    required this.otherAnestheticPlan,
    required this.restrictionItems,
    required this.patientRestrictions,
    required this.otherRestrictions,
  });

  const PreAnestheticAssessment.empty()
      : comorbidities = const [],
        otherComorbidities = '',
        currentMedications = const [],
        otherMedications = '',
        allergyDescription = '',
        smokingStatus = '',
        alcoholStatus = '',
        otherHabits = '',
        mets = '',
        physicalExam = '',
        airway = const Airway.empty(),
        mouthOpening = '',
        neckMobility = '',
        dentition = '',
        difficultAirwayPredictors = const [],
        otherDifficultAirwayPredictors = '',
        difficultVentilationPredictors = const [],
        otherDifficultVentilationPredictors = '',
        otherAirwayDetails = '',
        complementaryExamItems = const [],
        complementaryExams = '',
        otherComplementaryExams = '',
        fastingSolids = '',
        fastingLiquids = '',
        fastingNotes = '',
        asaClassification = '',
        asaNotes = '',
        anestheticPlan = '',
        otherAnestheticPlan = '',
        restrictionItems = const [],
        patientRestrictions = '',
        otherRestrictions = '';

  final List<String> comorbidities;
  final String otherComorbidities;
  final List<String> currentMedications;
  final String otherMedications;
  final String allergyDescription;
  final String smokingStatus;
  final String alcoholStatus;
  final String otherHabits;
  final String mets;
  final String physicalExam;
  final Airway airway;
  final String mouthOpening;
  final String neckMobility;
  final String dentition;
  final List<String> difficultAirwayPredictors;
  final String otherDifficultAirwayPredictors;
  final List<String> difficultVentilationPredictors;
  final String otherDifficultVentilationPredictors;
  final String otherAirwayDetails;
  final List<String> complementaryExamItems;
  final String complementaryExams;
  final String otherComplementaryExams;
  final String fastingSolids;
  final String fastingLiquids;
  final String fastingNotes;
  final String asaClassification;
  final String asaNotes;
  final String anestheticPlan;
  final String otherAnestheticPlan;
  final List<String> restrictionItems;
  final String patientRestrictions;
  final String otherRestrictions;

  PreAnestheticAssessment copyWith({
    List<String>? comorbidities,
    String? otherComorbidities,
    List<String>? currentMedications,
    String? otherMedications,
    String? allergyDescription,
    String? smokingStatus,
    String? alcoholStatus,
    String? otherHabits,
    String? mets,
    String? physicalExam,
    Airway? airway,
    String? mouthOpening,
    String? neckMobility,
    String? dentition,
    List<String>? difficultAirwayPredictors,
    String? otherDifficultAirwayPredictors,
    List<String>? difficultVentilationPredictors,
    String? otherDifficultVentilationPredictors,
    String? otherAirwayDetails,
    List<String>? complementaryExamItems,
    String? complementaryExams,
    String? otherComplementaryExams,
    String? fastingSolids,
    String? fastingLiquids,
    String? fastingNotes,
    String? asaClassification,
    String? asaNotes,
    String? anestheticPlan,
    String? otherAnestheticPlan,
    List<String>? restrictionItems,
    String? patientRestrictions,
    String? otherRestrictions,
  }) {
    return PreAnestheticAssessment(
      comorbidities: comorbidities ?? this.comorbidities,
      otherComorbidities: otherComorbidities ?? this.otherComorbidities,
      currentMedications: currentMedications ?? this.currentMedications,
      otherMedications: otherMedications ?? this.otherMedications,
      allergyDescription: allergyDescription ?? this.allergyDescription,
      smokingStatus: smokingStatus ?? this.smokingStatus,
      alcoholStatus: alcoholStatus ?? this.alcoholStatus,
      otherHabits: otherHabits ?? this.otherHabits,
      mets: mets ?? this.mets,
      physicalExam: physicalExam ?? this.physicalExam,
      airway: airway ?? this.airway,
      mouthOpening: mouthOpening ?? this.mouthOpening,
      neckMobility: neckMobility ?? this.neckMobility,
      dentition: dentition ?? this.dentition,
      difficultAirwayPredictors:
          difficultAirwayPredictors ?? this.difficultAirwayPredictors,
      otherDifficultAirwayPredictors: otherDifficultAirwayPredictors ??
          this.otherDifficultAirwayPredictors,
      difficultVentilationPredictors: difficultVentilationPredictors ??
          this.difficultVentilationPredictors,
      otherDifficultVentilationPredictors:
          otherDifficultVentilationPredictors ??
              this.otherDifficultVentilationPredictors,
      otherAirwayDetails: otherAirwayDetails ?? this.otherAirwayDetails,
      complementaryExamItems:
          complementaryExamItems ?? this.complementaryExamItems,
      complementaryExams: complementaryExams ?? this.complementaryExams,
      otherComplementaryExams:
          otherComplementaryExams ?? this.otherComplementaryExams,
      fastingSolids: fastingSolids ?? this.fastingSolids,
      fastingLiquids: fastingLiquids ?? this.fastingLiquids,
      fastingNotes: fastingNotes ?? this.fastingNotes,
      asaClassification: asaClassification ?? this.asaClassification,
      asaNotes: asaNotes ?? this.asaNotes,
      anestheticPlan: anestheticPlan ?? this.anestheticPlan,
      otherAnestheticPlan: otherAnestheticPlan ?? this.otherAnestheticPlan,
      restrictionItems: restrictionItems ?? this.restrictionItems,
      patientRestrictions: patientRestrictions ?? this.patientRestrictions,
      otherRestrictions: otherRestrictions ?? this.otherRestrictions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comorbidities': comorbidities,
      'otherComorbidities': otherComorbidities,
      'currentMedications': currentMedications,
      'otherMedications': otherMedications,
      'allergyDescription': allergyDescription,
      'smokingStatus': smokingStatus,
      'alcoholStatus': alcoholStatus,
      'otherHabits': otherHabits,
      'mets': mets,
      'physicalExam': physicalExam,
      'airway': airway.toJson(),
      'mouthOpening': mouthOpening,
      'neckMobility': neckMobility,
      'dentition': dentition,
      'difficultAirwayPredictors': difficultAirwayPredictors,
      'otherDifficultAirwayPredictors': otherDifficultAirwayPredictors,
      'difficultVentilationPredictors': difficultVentilationPredictors,
      'otherDifficultVentilationPredictors':
          otherDifficultVentilationPredictors,
      'otherAirwayDetails': otherAirwayDetails,
      'complementaryExamItems': complementaryExamItems,
      'complementaryExams': complementaryExams,
      'otherComplementaryExams': otherComplementaryExams,
      'fastingSolids': fastingSolids,
      'fastingLiquids': fastingLiquids,
      'fastingNotes': fastingNotes,
      'asaClassification': asaClassification,
      'asaNotes': asaNotes,
      'anestheticPlan': anestheticPlan,
      'otherAnestheticPlan': otherAnestheticPlan,
      'restrictionItems': restrictionItems,
      'patientRestrictions': patientRestrictions,
      'otherRestrictions': otherRestrictions,
    };
  }

  factory PreAnestheticAssessment.fromJson(Map<dynamic, dynamic> json) {
    return PreAnestheticAssessment(
      comorbidities: (json['comorbidities'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      otherComorbidities: json['otherComorbidities'] as String? ?? '',
      currentMedications:
          (json['currentMedications'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      otherMedications: json['otherMedications'] as String? ?? '',
      allergyDescription: json['allergyDescription'] as String? ?? '',
      smokingStatus: json['smokingStatus'] as String? ?? '',
      alcoholStatus: json['alcoholStatus'] as String? ?? '',
      otherHabits: json['otherHabits'] as String? ?? '',
      mets: json['mets'] as String? ?? '',
      physicalExam: json['physicalExam'] as String? ?? '',
      airway: Airway.fromJson(
        json['airway'] as Map<dynamic, dynamic>? ?? const {},
      ),
      mouthOpening: json['mouthOpening'] as String? ?? '',
      neckMobility: json['neckMobility'] as String? ?? '',
      dentition: json['dentition'] as String? ?? '',
      difficultAirwayPredictors:
          (json['difficultAirwayPredictors'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      otherDifficultAirwayPredictors:
          json['otherDifficultAirwayPredictors'] as String? ?? '',
      difficultVentilationPredictors:
          (json['difficultVentilationPredictors'] as List<dynamic>? ??
                  const [])
              .map((item) => item.toString())
              .toList(),
      otherDifficultVentilationPredictors:
          json['otherDifficultVentilationPredictors'] as String? ?? '',
      otherAirwayDetails: json['otherAirwayDetails'] as String? ?? '',
      complementaryExamItems:
          (json['complementaryExamItems'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      complementaryExams: json['complementaryExams'] as String? ?? '',
      otherComplementaryExams:
          json['otherComplementaryExams'] as String? ?? '',
      fastingSolids: json['fastingSolids'] as String? ?? '',
      fastingLiquids: json['fastingLiquids'] as String? ?? '',
      fastingNotes: json['fastingNotes'] as String? ?? '',
      asaClassification: json['asaClassification'] as String? ?? '',
      asaNotes: json['asaNotes'] as String? ?? '',
      anestheticPlan: json['anestheticPlan'] as String? ?? '',
      otherAnestheticPlan: json['otherAnestheticPlan'] as String? ?? '',
      restrictionItems: (json['restrictionItems'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      patientRestrictions: json['patientRestrictions'] as String? ?? '',
      otherRestrictions: json['otherRestrictions'] as String? ?? '',
    );
  }
}
