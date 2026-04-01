import 'airway.dart';
import 'fluid_balance.dart';
import 'hemodynamic_entry.dart';
import 'hemodynamic_point.dart';
import 'patient.dart';
import 'pre_anesthetic_assessment.dart';

class AnesthesiaRecord {
  const AnesthesiaRecord({
    required this.patient,
    required this.preAnestheticAssessment,
    required this.airway,
    required this.fluidBalance,
    required this.anesthesiaTechnique,
    required this.maintenanceAgents,
    required this.hemodynamicEntries,
    required this.hemodynamicPoints,
    required this.hemodynamicMarkers,
    required this.events,
    required this.drugs,
    required this.adjuncts,
    required this.otherMedications,
    required this.vasoactiveDrugs,
    required this.prophylacticAntibiotics,
    required this.fastingHours,
    required this.venousAccesses,
    required this.arterialAccesses,
    required this.surgicalSize,
    required this.surgeryDescription,
    required this.surgeonName,
    required this.assistantNames,
    required this.safeSurgeryChecklist,
    required this.timeOutChecklist,
    required this.timeOutCompleted,
    required this.anesthesiologistName,
    required this.anesthesiologistCrm,
    required this.anesthesiologistDetails,
  });

  const AnesthesiaRecord.empty()
      : patient = const Patient.empty(),
        preAnestheticAssessment = const PreAnestheticAssessment.empty(),
        airway = const Airway.empty(),
        fluidBalance = const FluidBalance.empty(),
        anesthesiaTechnique = '',
        maintenanceAgents = '',
        hemodynamicEntries = const [],
        hemodynamicPoints = const [],
        hemodynamicMarkers = const [],
        events = const [],
        drugs = const [],
        adjuncts = const [],
        otherMedications = const [],
        vasoactiveDrugs = const [],
        prophylacticAntibiotics = const [],
        fastingHours = '',
        venousAccesses = const [],
        arterialAccesses = const [],
        surgicalSize = '',
        surgeryDescription = '',
        surgeonName = '',
        assistantNames = const [],
        safeSurgeryChecklist = const [],
        timeOutChecklist = const [],
        timeOutCompleted = false,
        anesthesiologistName = '',
        anesthesiologistCrm = '',
        anesthesiologistDetails = '';

  final Patient patient;
  final PreAnestheticAssessment preAnestheticAssessment;
  final Airway airway;
  final FluidBalance fluidBalance;
  final String anesthesiaTechnique;
  final String maintenanceAgents;
  final List<HemodynamicEntry> hemodynamicEntries;
  final List<HemodynamicPoint> hemodynamicPoints;
  final List<HemodynamicMarker> hemodynamicMarkers;
  final List<String> events;
  final List<String> drugs;
  final List<String> adjuncts;
  final List<String> otherMedications;
  final List<String> vasoactiveDrugs;
  final List<String> prophylacticAntibiotics;
  final String fastingHours;
  final List<String> venousAccesses;
  final List<String> arterialAccesses;
  final String surgicalSize;
  final String surgeryDescription;
  final String surgeonName;
  final List<String> assistantNames;
  final List<String> safeSurgeryChecklist;
  final List<String> timeOutChecklist;
  final bool timeOutCompleted;
  final String anesthesiologistName;
  final String anesthesiologistCrm;
  final String anesthesiologistDetails;

  AnesthesiaRecord copyWith({
    Patient? patient,
    PreAnestheticAssessment? preAnestheticAssessment,
    Airway? airway,
    FluidBalance? fluidBalance,
    String? anesthesiaTechnique,
    String? maintenanceAgents,
    List<HemodynamicEntry>? hemodynamicEntries,
    List<HemodynamicPoint>? hemodynamicPoints,
    List<HemodynamicMarker>? hemodynamicMarkers,
    List<String>? events,
    List<String>? drugs,
    List<String>? adjuncts,
    List<String>? otherMedications,
    List<String>? vasoactiveDrugs,
    List<String>? prophylacticAntibiotics,
    String? fastingHours,
    List<String>? venousAccesses,
    List<String>? arterialAccesses,
    String? surgicalSize,
    String? surgeryDescription,
    String? surgeonName,
    List<String>? assistantNames,
    List<String>? safeSurgeryChecklist,
    List<String>? timeOutChecklist,
    bool? timeOutCompleted,
    String? anesthesiologistName,
    String? anesthesiologistCrm,
    String? anesthesiologistDetails,
  }) {
    return AnesthesiaRecord(
      patient: patient ?? this.patient,
      preAnestheticAssessment:
          preAnestheticAssessment ?? this.preAnestheticAssessment,
      airway: airway ?? this.airway,
      fluidBalance: fluidBalance ?? this.fluidBalance,
      anesthesiaTechnique: anesthesiaTechnique ?? this.anesthesiaTechnique,
      maintenanceAgents: maintenanceAgents ?? this.maintenanceAgents,
      hemodynamicEntries: hemodynamicEntries ?? this.hemodynamicEntries,
      hemodynamicPoints: hemodynamicPoints ?? this.hemodynamicPoints,
      hemodynamicMarkers: hemodynamicMarkers ?? this.hemodynamicMarkers,
      events: events ?? this.events,
      drugs: drugs ?? this.drugs,
      adjuncts: adjuncts ?? this.adjuncts,
      otherMedications: otherMedications ?? this.otherMedications,
      vasoactiveDrugs: vasoactiveDrugs ?? this.vasoactiveDrugs,
      prophylacticAntibiotics:
          prophylacticAntibiotics ?? this.prophylacticAntibiotics,
      fastingHours: fastingHours ?? this.fastingHours,
      venousAccesses: venousAccesses ?? this.venousAccesses,
      arterialAccesses: arterialAccesses ?? this.arterialAccesses,
      surgicalSize: surgicalSize ?? this.surgicalSize,
      surgeryDescription: surgeryDescription ?? this.surgeryDescription,
      surgeonName: surgeonName ?? this.surgeonName,
      assistantNames: assistantNames ?? this.assistantNames,
      safeSurgeryChecklist:
          safeSurgeryChecklist ?? this.safeSurgeryChecklist,
      timeOutChecklist: timeOutChecklist ?? this.timeOutChecklist,
      timeOutCompleted: timeOutCompleted ?? this.timeOutCompleted,
      anesthesiologistName:
          anesthesiologistName ?? this.anesthesiologistName,
      anesthesiologistCrm: anesthesiologistCrm ?? this.anesthesiologistCrm,
      anesthesiologistDetails:
          anesthesiologistDetails ?? this.anesthesiologistDetails,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient': patient.toJson(),
      'preAnestheticAssessment': preAnestheticAssessment.toJson(),
      'airway': airway.toJson(),
      'fluidBalance': fluidBalance.toJson(),
      'anesthesiaTechnique': anesthesiaTechnique,
      'maintenanceAgents': maintenanceAgents,
      'hemodynamicEntries': hemodynamicEntries.map((item) => item.toJson()).toList(),
      'hemodynamicPoints': hemodynamicPoints.map((item) => item.toJson()).toList(),
      'hemodynamicMarkers':
          hemodynamicMarkers.map((item) => item.toJson()).toList(),
      'events': events,
      'drugs': drugs,
      'adjuncts': adjuncts,
      'otherMedications': otherMedications,
      'vasoactiveDrugs': vasoactiveDrugs,
      'prophylacticAntibiotics': prophylacticAntibiotics,
      'fastingHours': fastingHours,
      'venousAccesses': venousAccesses,
      'arterialAccesses': arterialAccesses,
      'surgicalSize': surgicalSize,
      'surgeryDescription': surgeryDescription,
      'surgeonName': surgeonName,
      'assistantNames': assistantNames,
      'safeSurgeryChecklist': safeSurgeryChecklist,
      'timeOutChecklist': timeOutChecklist,
      'timeOutCompleted': timeOutCompleted,
      'anesthesiologistName': anesthesiologistName,
      'anesthesiologistCrm': anesthesiologistCrm,
      'anesthesiologistDetails': anesthesiologistDetails,
    };
  }

  factory AnesthesiaRecord.fromJson(Map<dynamic, dynamic> json) {
    return AnesthesiaRecord(
      patient: Patient.fromJson(
        json['patient'] as Map<dynamic, dynamic>? ?? const {},
      ),
      preAnestheticAssessment: PreAnestheticAssessment.fromJson(
        json['preAnestheticAssessment'] as Map<dynamic, dynamic>? ?? const {},
      ),
      airway: Airway.fromJson(
        json['airway'] as Map<dynamic, dynamic>? ?? const {},
      ),
      fluidBalance: FluidBalance.fromJson(
        json['fluidBalance'] as Map<dynamic, dynamic>? ?? const {},
      ),
      anesthesiaTechnique: json['anesthesiaTechnique'] as String? ?? '',
      maintenanceAgents: json['maintenanceAgents'] as String? ?? '',
      hemodynamicEntries:
          (json['hemodynamicEntries'] as List<dynamic>? ?? const [])
              .map(
                (item) => HemodynamicEntry.fromJson(
                  Map<dynamic, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      hemodynamicPoints:
          (json['hemodynamicPoints'] as List<dynamic>? ?? const [])
              .map(
                (item) => HemodynamicPoint.fromJson(
                  Map<dynamic, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      hemodynamicMarkers:
          (json['hemodynamicMarkers'] as List<dynamic>? ?? const [])
              .map(
                (item) => HemodynamicMarker.fromJson(
                  Map<dynamic, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      events: (json['events'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      drugs: (json['drugs'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      adjuncts: (json['adjuncts'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      otherMedications:
          (json['otherMedications'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      vasoactiveDrugs:
          (json['vasoactiveDrugs'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      prophylacticAntibiotics:
          (json['prophylacticAntibiotics'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      fastingHours: json['fastingHours'] as String? ?? '',
      venousAccesses: (json['venousAccesses'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      arterialAccesses: (json['arterialAccesses'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      surgicalSize: json['surgicalSize'] as String? ?? '',
      surgeryDescription: json['surgeryDescription'] as String? ?? '',
      surgeonName: json['surgeonName'] as String? ?? '',
      assistantNames: (json['assistantNames'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      safeSurgeryChecklist:
          (json['safeSurgeryChecklist'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      timeOutChecklist: (json['timeOutChecklist'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      timeOutCompleted: json['timeOutCompleted'] as bool? ?? false,
      anesthesiologistName: json['anesthesiologistName'] as String? ?? '',
      anesthesiologistCrm: json['anesthesiologistCrm'] as String? ?? '',
      anesthesiologistDetails:
          json['anesthesiologistDetails'] as String? ?? '',
    );
  }
}
