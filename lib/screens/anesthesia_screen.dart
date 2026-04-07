import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../models/anesthesia_case.dart';
import '../models/anesthesia_record.dart';
import '../models/airway.dart';
import '../models/fluid_balance.dart';
import '../models/hemodynamic_point.dart';
import '../models/patient.dart';
import '../services/ai_record_analysis_service.dart';
import '../services/hemodynamic_record_service.dart';
import '../services/record_validation_service.dart';
import '../services/record_storage_service.dart';
import '../services/report_export_service.dart';
import 'pre_anesthetic_screen.dart';
import '../widgets/anesthesia_basic_dialogs.dart';
import '../widgets/anesthesia_footer_widget.dart';
import '../widgets/anesthesia_medium_dialogs.dart';
import '../widgets/airway_dialog.dart';
import '../widgets/card_widget.dart';
import '../widgets/event_list_widget.dart';
import '../widgets/header_widget.dart';
import '../widgets/intraoperative_entry_dialogs.dart';
import '../widgets/hemodynamic_chart_card.dart';
import '../widgets/json_export_dialog.dart';
import '../widgets/page_container.dart';
import '../widgets/surgery_info_dialog.dart';

class _FluidSupportRecommendation {
  const _FluidSupportRecommendation({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;
}

class _AirwaySupportRecommendation {
  const _AirwaySupportRecommendation({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;
}

double _adultReferenceWeightKg({
  required double actualWeightKg,
  required double heightMeters,
}) {
  if (actualWeightKg <= 0) return 70;
  if (heightMeters <= 0) return actualWeightKg;
  final bmi = actualWeightKg / (heightMeters * heightMeters);
  if (bmi < 30) return actualWeightKg;
  final referenceWeight = 25 * heightMeters * heightMeters;
  return referenceWeight < actualWeightKg ? referenceWeight : actualWeightKg;
}

double _pediatricMaintenanceRateMlPerHour(double weightKg) {
  if (weightKg <= 0) return 0;
  if (weightKg <= 10) return weightKg * 4;
  if (weightKg <= 20) return 40 + ((weightKg - 10) * 2);
  return 60 + (weightKg - 20);
}

(double lowerMlPerHour, double upperMlPerHour)? _termNeonateMaintenanceRange({
  required double weightKg,
  required int postnatalAgeDays,
}) {
  if (weightKg <= 0 || postnatalAgeDays <= 0) return null;

  final (lowerPerDay, upperPerDay) = switch (postnatalAgeDays) {
    <= 1 => (50.0, 60.0),
    2 => (70.0, 80.0),
    3 => (80.0, 100.0),
    4 => (100.0, 120.0),
    _ => (120.0, 150.0),
  };

  return (
    (weightKg * lowerPerDay) / 24,
    (weightKg * upperPerDay) / 24,
  );
}

_FluidSupportRecommendation _buildFluidSupportRecommendation({
  required Patient patient,
  required double documentedLossesMl,
  required String fastingHoursText,
}) {
  final fasting = fastingHoursText.trim();

  switch (patient.population) {
    case PatientPopulation.adult:
      final referenceWeight = _adultReferenceWeightKg(
        actualWeightKg: patient.weightKg,
        heightMeters: patient.heightMeters,
      );
      final lower = (referenceWeight * 25) / 24;
      final upper = (referenceWeight * 30) / 24;

      return _FluidSupportRecommendation(
        title: 'Apoio clínico adulto',
        lines: [
          'Manutenção: ${lower.toStringAsFixed(0)}-${upper.toStringAsFixed(0)} mL/h',
          'Manutenção inicial por 25-30 mL/kg/dia; usar peso de referência se obesidade.',
          'Perdas registradas: ${documentedLossesMl.toStringAsFixed(0)} mL',
          if (fasting.isNotEmpty) 'Jejum informado: $fasting h; não repor déficit fixo automaticamente.',
        ],
      );

    case PatientPopulation.pediatric:
      final maintenance = _pediatricMaintenanceRateMlPerHour(patient.weightKg);
      final glucoseLine = patient.age > 0 && patient.age < 2
          ? 'Em lactentes pequenos, considerar glicose 1-2,5% com monitorização de glicemia.'
          : 'Glicose não é rotineira fora do período neonatal; considerar se risco de hipoglicemia.';

      return _FluidSupportRecommendation(
        title: 'Apoio clínico pediátrico',
        lines: [
          'Manutenção: ${maintenance.toStringAsFixed(0)} mL/h',
          'Cálculo basal por Holliday-Segar (4-2-1).',
          'Preferir cristalóide isotônico com sódio 131-154 mmol/L.',
          glucoseLine,
          'Perdas registradas: ${documentedLossesMl.toStringAsFixed(0)} mL',
        ],
      );

    case PatientPopulation.neonatal:
      final isTerm = patient.gestationalAgeWeeks >= 37;
      final range = isTerm
          ? _termNeonateMaintenanceRange(
              weightKg: patient.weightKg > 0
                  ? patient.weightKg
                  : patient.birthWeightKg,
              postnatalAgeDays: patient.postnatalAgeDays,
            )
          : null;

      final lines = <String>[
        if (range != null)
          'Manutenção: ${range.$1.toStringAsFixed(0)}-${range.$2.toStringAsFixed(0)} mL/h'
        else
          'Sem taxa automática fixa no sistema.',
        if (isTerm && patient.postnatalAgeDays > 0)
          'Neonato termo, ${patient.postnatalAgeDays} dia(s) de vida.'
        else if (patient.gestationalAgeWeeks <= 0)
          'Informar idade gestacional para sugerir faixa de manutenção neonatal.'
        else
          'Prematuro: individualizar com glicemia, sódio e contexto cirúrgico.',
        'Manutenção inicial: cristalóide isotônico com sódio 131-154 mmol/L e glicose 5-10%.',
        'Perdas registradas: ${documentedLossesMl.toStringAsFixed(0)} mL',
      ];

      return _FluidSupportRecommendation(
        title: 'Apoio clínico neonatal',
        lines: lines,
      );
  }
}

String _fastingSummaryForProfile({
  required Patient patient,
  required String fastingText,
}) {
  final value = fastingText.trim();
  if (value.isEmpty) {
    return 'Toque para informar o tempo de jejum';
  }

  switch (patient.population) {
    case PatientPopulation.adult:
      return value.contains('>8')
          ? 'Jejum prolongado: reavaliar volemia clinicamente'
          : 'Líquidos claros até 2 h e refeição leve 6 h';
    case PatientPopulation.pediatric:
      return 'Referência pediátrica: claros 2 h, leite materno 4 h, fórmula 6 h';
    case PatientPopulation.neonatal:
      return 'Referência neonatal: claros 2 h, leite materno 4 h, fórmula 6 h';
  }
}

_AirwaySupportRecommendation? _buildAirwaySupportRecommendation(Patient patient) {
  switch (patient.population) {
    case PatientPopulation.adult:
      return null;
    case PatientPopulation.pediatric:
      if (patient.age < 2) {
        return const _AirwaySupportRecommendation(
          title: 'Referência pediátrica',
          lines: [
            'Lactente: individualizar o TOT por peso, escape e mecânica ventilatória.',
            'Fórmulas etárias ficam menos precisas abaixo de 2 anos.',
          ],
        );
      }

      final cuffed = (patient.age / 4) + 3.5;
      final uncuffed = (patient.age / 4) + 4.0;
      final oralDepth = (patient.age / 2) + 12;

      return _AirwaySupportRecommendation(
        title: 'Referência pediátrica',
        lines: [
          'TOT com cuff: ${cuffed.toStringAsFixed(cuffed.truncateToDouble() == cuffed ? 0 : 1)} mm',
          'TOT sem cuff: ${uncuffed.toStringAsFixed(uncuffed.truncateToDouble() == uncuffed ? 0 : 1)} mm',
          'Profundidade oral estimada: ${oralDepth.toStringAsFixed(0)} cm',
        ],
      );
    case PatientPopulation.neonatal:
      final weightKg = patient.weightKg > 0 ? patient.weightKg : patient.birthWeightKg;
      if (weightKg <= 0) {
        return const _AirwaySupportRecommendation(
          title: 'Referência neonatal',
          lines: [
            'Informar peso atual ou peso ao nascer para sugerir o TOT inicial.',
          ],
        );
      }

      final size = switch (weightKg) {
        < 1.0 => '2,5 mm',
        >= 1.0 && <= 2.0 => '3,0 mm',
        > 2.0 && <= 3.2 => '3,5 mm',
        _ => '3,5-4,0 mm',
      };
      final depth = 6 + weightKg;

      return _AirwaySupportRecommendation(
        title: 'Referência neonatal',
        lines: [
          'TOT inicial por peso: $size',
          'Profundidade labial estimada: ${depth.toStringAsFixed(1).replaceAll('.', ',')} cm',
          'Confirmar posição por capnografia, ausculta e imagem quando aplicável.',
        ],
      );
  }
}

List<String> _recommendedMonitoringItems(Patient patient) {
  switch (patient.population) {
    case PatientPopulation.adult:
    case PatientPopulation.pediatric:
    case PatientPopulation.neonatal:
      return const [
        'ECG (5 derivações)',
        'PA não invasiva',
        'SpO₂',
        'Capnografia',
        'Temperatura',
      ];
  }
}

class AnesthesiaScreen extends StatefulWidget {
  const AnesthesiaScreen({
    super.key,
    this.initialRecord,
    this.loadPersistedRecord = false,
    this.autoOpenPreAnesthetic = false,
    this.caseId,
    this.initialCaseStatus = AnesthesiaCaseStatus.inProgress,
    this.createdAtIso,
    this.initialPreAnestheticDate = '',
    this.initialAnesthesiaDate = '',
  });

  final AnesthesiaRecord? initialRecord;
  final bool loadPersistedRecord;
  final bool autoOpenPreAnesthetic;
  final String? caseId;
  final AnesthesiaCaseStatus initialCaseStatus;
  final String? createdAtIso;
  final String initialPreAnestheticDate;
  final String initialAnesthesiaDate;

  @override
  State<AnesthesiaScreen> createState() => _AnesthesiaScreenState();
}

class _AnesthesiaScreenState extends State<AnesthesiaScreen> {
  static const Color _surgeryRowColor = Color(0xFF5A6F86);
  static const Color _timeoutRowColor = Color(0xFFB07A1E);
  static const Color _accessRowColor = Color(0xFF2B76D2);
  static const Color _techniqueRowColor = Color(0xFF8A5DD3);
  static const Color _medicationsRowColor = Color(0xFFAF5A7A);
  static const Color _airwayFluidRowColor = Color(0xFF168B79);
  static const List<String> _asaOptions = ['I', 'II', 'III', 'IV', 'V', 'VI'];
  static const List<String> _mallampatiOptions = ['I', 'II', 'III', 'IV'];
  static const List<String> _commonAllergies = [
    'Látex',
    'Dipirona',
    'Penicilina',
    'Iodo/contraste',
  ];
  static const List<String> _commonRestrictions = [
    'Não aceita transfusão',
    'Recusa opioide',
    'Recusa anestesia regional',
  ];
  static const List<String> _pediatricRestrictions = [
    'Objeção familiar a hemocomponentes',
    'Acompanhante na indução',
    'Consentimento do responsável',
    'Alergia ao látex',
  ];
  static const List<String> _neonatalRestrictions = [
    'Objeção familiar a hemocomponentes',
    'Consentimento do responsável',
    'Necessita leito de UTI',
    'Necessita termorregulação rigorosa',
  ];
  static const List<String> _commonMedications = [
    'AAS',
    'Clopidogrel',
    'Insulina',
    'Metformina',
    'Beta-bloqueador',
  ];
  static const List<String> _pediatricCommonMedications = [
    'Broncodilatador',
    'Corticoide inalatório',
    'Anticonvulsivante',
    'Insulina',
  ];
  static const List<String> _neonatalCommonMedications = [
    'Cafeína',
    'Prostaglandina',
    'Diurético',
    'Antibiótico',
  ];
  static const Map<String, String> _adultProphylacticAntibioticOptions = {
    'Cefazolina': '2 g',
    'Cefuroxima': '1,5 g',
    'Clindamicina': '600-900 mg',
    'Vancomicina': '15 mg/kg',
    'Metronidazol': '500 mg',
  };
  static const Map<String, String> _pediatricProphylacticAntibioticOptions = {
    'Cefazolina': '30 mg/kg',
    'Clindamicina': '10 mg/kg',
    'Vancomicina': '15 mg/kg',
    'Metronidazol': '7,5 mg/kg',
  };
  static const Map<String, String> _neonatalProphylacticAntibioticOptions = {
    'Cefazolina': '25 mg/kg',
    'Vancomicina': '15 mg/kg',
    'Gentamicina': '4-5 mg/kg',
  };
  static const Map<String, Duration> _prophylacticRedoseIntervals = {
    'Cefazolina': Duration(hours: 4),
    'Cefuroxima': Duration(hours: 4),
    'Clindamicina': Duration(hours: 6),
  };
  static const Map<String, String> _adultOtherMedicationOptions = {
    'Dexametasona': '4-10 mg',
    'Ondansetrona': '4-8 mg',
    'Droperidol': '0,625-1,25 mg',
    'Metoclopramida': '10 mg',
    'Dipirona': '1 g',
    'Paracetamol': '1 g',
    'Parecoxibe': '40 mg',
    'Cetorolaco': '30 mg',
    'Hidrocortisona': '100 mg',
  };
  static const Map<String, String> _pediatricOtherMedicationOptions = {
    'Dexametasona': '0,1-0,15 mg/kg',
    'Ondansetrona': '0,1 mg/kg',
    'Paracetamol': '10-15 mg/kg',
    'Dipirona': '15-25 mg/kg',
    'Atropina': '0,02 mg/kg',
    'Hidrocortisona': '2 mg/kg',
  };
  static const Map<String, String> _neonatalOtherMedicationOptions = {
    'Atropina': '0,02 mg/kg',
    'Glicose 10%': '2-5 mL/kg',
    'Cálcio gluconato': '50-100 mg/kg',
    'Hidrocortisona': '1-2 mg/kg',
    'Paracetamol': '10-15 mg/kg',
  };
  static const Map<String, String> _adultVasoactiveDrugOptions = {
    'Etilefrina': '2 mg',
    'Metaraminol': '0,5-2 mg',
    'Efedrina': '5-10 mg',
    'Noradrenalina': '0,02-0,2 mcg/kg/min',
    'Fenilefrina': '50-100 mcg',
    'Adrenalina': '5-20 mcg',
    'Dobutamina': '2-10 mcg/kg/min',
    'Dopamina': '3-10 mcg/kg/min',
    'Vasopressina': '0,5-2 U',
  };
  static const Map<String, String> _pediatricVasoactiveDrugOptions = {
    'Efedrina': '0,1-0,2 mg/kg',
    'Fenilefrina': '1-2 mcg/kg',
    'Adrenalina': '0,5-1 mcg/kg',
    'Noradrenalina': '0,02-0,2 mcg/kg/min',
    'Dobutamina': '2-10 mcg/kg/min',
    'Dopamina': '3-10 mcg/kg/min',
    'Vasopressina': '0,0003-0,0007 U/kg/min',
  };
  static const Map<String, String> _neonatalVasoactiveDrugOptions = {
    'Adrenalina': '0,05-0,3 mcg/kg/min',
    'Noradrenalina': '0,02-0,2 mcg/kg/min',
    'Dobutamina': '2-10 mcg/kg/min',
    'Dopamina': '3-10 mcg/kg/min',
    'Vasopressina': '0,0002-0,0007 U/kg/min',
  };

  final AiRecordAnalysisService _analysisService =
      const AiRecordAnalysisService();
  final HemodynamicRecordService _hemodynamicService =
      const HemodynamicRecordService();
  final RecordValidationService _validationService =
      const RecordValidationService();
  final RecordStorageService _storageService = RecordStorageService();
  final ReportExportService _reportExportService = const ReportExportService();

  late final AnesthesiaRecord _initialRecord;
  late AnesthesiaRecord _record;
  late AnesthesiaCaseStatus _caseStatus;
  late List<String> _venousAccesses;
  late List<String> _arterialAccesses;
  late List<String> _monitoringItems;
  late String _preAnestheticDate;
  late String _anesthesiaDate;
  String _inlineHemodynamicType = 'PAS';
  bool _inlineHemodynamicRemoveMode = false;
  Timer? _hemodynamicTicker;
  final GlobalKey _patientSummaryKey = GlobalKey();
  final GlobalKey _airwaySectionKey = GlobalKey();
  final GlobalKey _techniqueSectionKey = GlobalKey();
  final GlobalKey _drugsSectionKey = GlobalKey();
  final GlobalKey _otherMedicationsSectionKey = GlobalKey();
  final GlobalKey _vasoactiveSectionKey = GlobalKey();
  final GlobalKey _eventsSectionKey = GlobalKey();
  final GlobalKey _fluidSectionKey = GlobalKey();

  bool get _usesMallampatiInCase =>
      _record.patient.population == PatientPopulation.adult;

  List<String> get _profileRestrictionSuggestions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _commonRestrictions;
      case PatientPopulation.pediatric:
        return _pediatricRestrictions;
      case PatientPopulation.neonatal:
        return _neonatalRestrictions;
    }
  }

  List<String> get _profileMedicationSuggestions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _commonMedications;
      case PatientPopulation.pediatric:
        return _pediatricCommonMedications;
      case PatientPopulation.neonatal:
        return _neonatalCommonMedications;
    }
  }

  Map<String, String> get _profileProphylacticAntibioticOptions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _adultProphylacticAntibioticOptions;
      case PatientPopulation.pediatric:
        return _pediatricProphylacticAntibioticOptions;
      case PatientPopulation.neonatal:
        return _neonatalProphylacticAntibioticOptions;
    }
  }

  Map<String, String> get _profileOtherMedicationOptions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _adultOtherMedicationOptions;
      case PatientPopulation.pediatric:
        return _pediatricOtherMedicationOptions;
      case PatientPopulation.neonatal:
        return _neonatalOtherMedicationOptions;
    }
  }

  Map<String, String> get _profileVasoactiveDrugOptions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _adultVasoactiveDrugOptions;
      case PatientPopulation.pediatric:
        return _pediatricVasoactiveDrugOptions;
      case PatientPopulation.neonatal:
        return _neonatalVasoactiveDrugOptions;
    }
  }

  String _valueOrPlaceholder(
    String value, {
    String placeholder = 'Toque para preencher',
  }) {
    return value.trim().isEmpty ? placeholder : value;
  }

  String _medicationDoseSummary(List<String> parts) {
    final segments = <String>[];
    final initialDose = parts.length > 1 ? parts[1].trim() : '';
    final repeats = parts.length > 3 ? parts[3].trim() : '';
    final infusion = parts.length > 4 ? parts[4].trim() : '';

    if (initialDose.isNotEmpty) {
      segments.add('Inicial: $initialDose');
    }
    if (repeats.isNotEmpty) {
      segments.add('Repiques: $repeats');
    }
    if (infusion.isNotEmpty) {
      segments.add('IC: $infusion');
    }

    if (segments.isEmpty) {
      return parts.length == 1 ? parts.first : 'Sem dose';
    }

    return segments.join(' • ');
  }

  String get _displayFastingHours {
    final manual = _record.fastingHours.trim();
    if (manual.isNotEmpty) return manual;
    final assessment = _record.preAnestheticAssessment;
    final population = _record.patient.population;
    if (population == PatientPopulation.adult) {
      return assessment.fastingSolids.trim();
    }

    final segments = <String>[];
    final solids = assessment.fastingSolids.trim();
    final liquids = assessment.fastingLiquids.trim();
    final breastMilk = assessment.fastingBreastMilk.trim();

    if (solids.isNotEmpty) {
      segments.add(
        population == PatientPopulation.neonatal
            ? 'Formula/leite nao humano: $solids'
            : 'Formula/refeicao: $solids',
      );
    }
    if (breastMilk.isNotEmpty) {
      segments.add('Leite materno: $breastMilk');
    }
    if (liquids.isNotEmpty) {
      segments.add('Liquidos claros: $liquids');
    }

    return segments.join(' • ');
  }

  String get _displaySurgeryPriority {
    final recordPriority = _record.surgeryPriority.trim();
    if (recordPriority.isNotEmpty) return recordPriority;
    return _record.preAnestheticAssessment.surgeryPriority.trim();
  }

  String get _displayPatientDestination {
    final destination = _record.patientDestination.trim();
    final other = _record.otherPatientDestination.trim();
    if (destination.isEmpty && other.isEmpty) {
      return 'Toque para preencher';
    }
    if (destination.isEmpty) return other;
    if (other.isEmpty) return destination;
    return '$destination • $other';
  }

  List<String> _lineItems(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _multilineSummary(String value, {String empty = 'Toque para preencher'}) {
    final items = _lineItems(value);
    if (items.isEmpty) return empty;
    return items.join(' • ');
  }

  List<String> get _anesthesiologistEntries {
    if (_record.anesthesiologists.isNotEmpty) return _record.anesthesiologists;
    final legacy = [
      _record.anesthesiologistName.trim(),
      _record.anesthesiologistCrm.trim(),
      _record.anesthesiologistDetails.trim(),
    ];
    if (legacy.every((item) => item.isEmpty)) return const [];
    return ['${legacy[0]}|${legacy[1]}|${legacy[2]}'];
  }

  String get _displayAnesthesiologists {
    if (_anesthesiologistEntries.isEmpty) return 'Toque para preencher';
    return _anesthesiologistEntries
        .map((item) => item.split('|').first.trim())
        .where((item) => item.isNotEmpty)
        .join(', ');
  }

  double get _documentedLossesMl {
    double parse(String value) =>
        double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
    return parse(_record.fluidBalance.diuresis) +
        parse(_record.fluidBalance.bleeding) +
        parse(_record.fluidBalance.otherLosses) +
        _record.fluidBalance.estimatedSpongeLoss;
  }

  double get _documentedInputsMl {
    double parse(String value) =>
        double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
    return parse(_record.fluidBalance.crystalloids) +
        parse(_record.fluidBalance.colloids) +
        parse(_record.fluidBalance.blood);
  }

  DateTime? _parseClockTimeToday(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatClockTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<_AntibioticRedoseAlert> get _antibioticRedoseAlerts {
    final now = DateTime.now();
    final alerts = <_AntibioticRedoseAlert>[];

    for (final item in _record.prophylacticAntibiotics) {
      final parts = item.split('|');
      if (parts.isEmpty) continue;
      final name = parts[0].trim();
      final interval = _prophylacticRedoseIntervals[name];
      if (interval == null) continue;

      final clock = parts.length > 2 ? parts[2].trim() : '';
      final administeredAt = _parseClockTimeToday(clock);
      if (administeredAt == null) continue;

      final redoseAt = administeredAt.add(interval);
      final minutesUntil = redoseAt.difference(now).inMinutes;

      if (minutesUntil <= 0) {
        alerts.add(
          _AntibioticRedoseAlert(
            name: name,
            message: 'Redose sugerida agora',
            detail:
                'Dose inicial às $clock. Intervalo de redose de ${interval.inHours} h.',
            isOverdue: true,
          ),
        );
      } else if (minutesUntil <= 30) {
        alerts.add(
          _AntibioticRedoseAlert(
            name: name,
            message: 'Próxima redose às ${_formatClockTime(redoseAt)}',
            detail:
                'Dose inicial às $clock. Intervalo de redose de ${interval.inHours} h.',
            isOverdue: false,
          ),
        );
      }
    }

    return alerts;
  }

  List<String> _splitListText(String value) {
    return value
        .split(RegExp(r'[\n,;]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> _updatePatient({
    String? name,
    int? age,
    double? weightKg,
    double? heightMeters,
    String? asa,
    List<String>? allergies,
    List<String>? restrictions,
    List<String>? medications,
    String? informedConsentStatus,
    String? mallampati,
    PatientPopulation? population,
    int? postnatalAgeDays,
    int? gestationalAgeWeeks,
    int? correctedGestationalAgeWeeks,
    double? birthWeightKg,
  }) async {
    setState(() {
      final updatedPatient = _record.patient.copyWith(
        name: name,
        age: age,
        weightKg: weightKg,
        heightMeters: heightMeters,
        asa: asa,
        allergies: allergies,
        restrictions: restrictions,
        medications: medications,
        informedConsentStatus: informedConsentStatus,
        population: population,
        postnatalAgeDays: postnatalAgeDays,
        gestationalAgeWeeks: gestationalAgeWeeks,
        correctedGestationalAgeWeeks: correctedGestationalAgeWeeks,
        birthWeightKg: birthWeightKg,
      );

      final updatedAssessment = _record.preAnestheticAssessment.copyWith(
        asaClassification: asa,
        allergyDescription: allergies?.join(', '),
        patientRestrictions: restrictions?.join('\n'),
        currentMedications: medications,
        airway: mallampati == null
            ? null
            : _record.preAnestheticAssessment.airway.copyWith(
                mallampati: mallampati,
              ),
      );

      _record = _record.copyWith(
        patient: updatedPatient,
        preAnestheticAssessment: updatedAssessment,
        airway: mallampati == null
            ? _record.airway
            : _record.airway.copyWith(mallampati: mallampati),
      );
    });

    await _persistRecord();
  }

  Future<void> _editPatientInformedConsentStatus() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Termo de Consentimento Informado para Anestesia',
        options: const ['Assinado', 'Não assinado'],
        initialValue: _record.patient.informedConsentStatus,
      ),
    );

    if (result == null) return;
    await _updatePatient(informedConsentStatus: result.trim());
  }

  HemodynamicPoint? _latestPointOfType(String type) =>
      _hemodynamicService.latestPointOfType(_record.hemodynamicPoints, type);

  HemodynamicPoint? get _latestFcPoint => _latestPointOfType('FC');
  HemodynamicPoint? get _latestSpo2Point => _latestPointOfType('SpO2');
  HemodynamicPoint? get _latestPaiPoint => _latestPointOfType('PAI');

  String get _latestBloodPressure {
    return _hemodynamicService.latestBloodPressure(_record.hemodynamicPoints);
  }

  String get _latestPam {
    return _hemodynamicService.latestPam(_record.hemodynamicPoints);
  }

  DateTime? get _hemodynamicAnesthesiaStartAt => _hemodynamicService
      .markerStartAt(_record.hemodynamicMarkers, 'Início da anestesia');

  DateTime? get _hemodynamicSurgeryStartAt => _hemodynamicService
      .markerStartAt(_record.hemodynamicMarkers, 'Início da cirurgia');

  bool get _hasAnesthesiaEndMarker => _record.hemodynamicMarkers.any(
        (item) => item.label == 'Fim da anestesia',
      );

  bool get _hasSurgeryEndMarker => _record.hemodynamicMarkers.any(
        (item) => item.label == 'Fim da cirurgia',
      );

  String get _paiSummary {
    if (_latestPaiPoint != null) {
      return _latestPaiPoint!.value.round().toString();
    }
    if (_arterialAccesses.isEmpty) return 'Não';
    if (_arterialAccesses.length == 1) return _arterialAccesses.first;
    return '${_arterialAccesses.length} acessos';
  }

  bool get _hasAnesthesiaStartMarker => _record.hemodynamicMarkers.any(
        (item) => item.label == 'Início da anestesia',
      );

  bool get _hasSurgeryStartMarker => _record.hemodynamicMarkers.any(
        (item) => item.label == 'Início da cirurgia',
      );

  List<String> get _missingRequiredFields =>
      _validationService.validateRequiredFields(_record);

  bool get _hasPendingAirway => _missingRequiredFields.contains('Via aérea');
  bool get _hasPendingTechnique =>
      _missingRequiredFields.contains('Técnica anestésica');
  bool get _hasPendingDrugs =>
      _missingRequiredFields.contains('Drogas e infusões');
  bool get _hasPendingEvents =>
      _missingRequiredFields.contains('Eventos intraoperatórios');
  bool get _hasPendingFluidBalance =>
      _missingRequiredFields.contains('Balanço hídrico');
  bool get _hasPendingTimeOut =>
      _record.timeOutChecklist.isEmpty || !_record.timeOutCompleted;

  String get _caseStageLabel {
    if (!_hasAnesthesiaStartMarker) return 'Aguardando início';
    if (!_hasSurgeryStartMarker) return 'Anestesia iniciada';
    return 'Cirurgia em andamento';
  }

  String get _recordStatusLabel {
    if (_caseStatus == AnesthesiaCaseStatus.finalized) {
      return 'Finalizado';
    }
    if (_missingRequiredFields.isEmpty && !_hasPendingTimeOut) {
      return 'Ficha segura';
    }
    return 'Em preenchimento';
  }

  String _nowLabel() {
    final now = DateTime.now();
    return _formatDateTimeLabel(now);
  }

  String _formatDateTimeLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String get _displayPreAnestheticDate =>
      _preAnestheticDate.trim().isEmpty ? 'Toque para informar' : _preAnestheticDate;

  String get _displayAnesthesiaDate =>
      _anesthesiaDate.trim().isEmpty ? 'Toque para informar' : _anesthesiaDate;

  String get _topHighlightMessage {
    if (_caseStatus == AnesthesiaCaseStatus.finalized) {
      return 'Caso finalizado e guardado no arquivo local.';
    }
    if (_missingRequiredFields.isEmpty && !_hasPendingTimeOut) {
      return 'Registro pronto para condução e revisão.';
    }
    return 'Priorize pendências críticas antes de seguir.';
  }

  AnesthesiaCaseStatus get _persistedCaseStatus {
    if (_caseStatus == AnesthesiaCaseStatus.finalized) {
      return AnesthesiaCaseStatus.finalized;
    }

    final hasPreAnesthetic =
        _record.preAnestheticAssessment.asaClassification.trim().isNotEmpty ||
        _record.preAnestheticAssessment.anestheticPlan.trim().isNotEmpty ||
        _record.preAnestheticAssessment.comorbidities.isNotEmpty ||
        _record.preAnestheticAssessment.currentMedications.isNotEmpty ||
        _record.preAnestheticAssessment.allergyDescription.trim().isNotEmpty;

    final hasIntraoperativeContent =
        _record.surgeryDescription.trim().isNotEmpty ||
        _record.surgeonName.trim().isNotEmpty ||
        _record.airway.device.trim().isNotEmpty ||
        _record.anesthesiaTechnique.trim().isNotEmpty ||
        _record.drugs.isNotEmpty ||
        _record.events.isNotEmpty ||
        _record.hemodynamicMarkers.isNotEmpty ||
        _record.hemodynamicPoints.isNotEmpty;

    if (hasIntraoperativeContent) {
      return AnesthesiaCaseStatus.inProgress;
    }
    if (hasPreAnesthetic) {
      return AnesthesiaCaseStatus.preAnesthetic;
    }
    return _caseStatus;
  }

  Future<void> _addHemodynamicMarker(String label) async {
    final now = DateTime.now();
    final updatedMarkers = _hemodynamicService.addMarker(
      markers: _record.hemodynamicMarkers,
      label: label,
      now: now,
    );

    if (identical(updatedMarkers, _record.hemodynamicMarkers)) return;

    setState(() {
      _record = _record.copyWith(hemodynamicMarkers: updatedMarkers);
      if (label == 'Início da anestesia') {
        _anesthesiaDate = _formatDateTimeLabel(now);
      }
    });
    _startHemodynamicTickerIfNeeded();
    await _persistRecord();
  }

  double _currentHemodynamicElapsedMinutes() {
    return _hemodynamicService.currentElapsedMinutes(
      _hemodynamicAnesthesiaStartAt,
      DateTime.now(),
    );
  }

  String _formatElapsedFrom(DateTime? startedAt) =>
      _hemodynamicService.formatElapsedFrom(startedAt, DateTime.now());

  Future<void> _addInlineHemodynamicPoint(double value) async {
    if (!_hasAnesthesiaStartMarker) return;
    final time = _currentHemodynamicElapsedMinutes();
    final updatedPoints = _hemodynamicService.addPoint(
      points: _record.hemodynamicPoints,
      type: _inlineHemodynamicType,
      value: value,
      time: time,
    );

    setState(() {
      _record = _record.copyWith(hemodynamicPoints: updatedPoints);
    });
    await _persistRecord();
  }

  Future<void> _removeInlineHemodynamicPoint(HemodynamicPoint point) async {
    final updatedPoints = _hemodynamicService.removePoint(
      points: _record.hemodynamicPoints,
      point: point,
    );
    setState(() {
      _record = _record.copyWith(hemodynamicPoints: updatedPoints);
    });
    await _persistRecord();
  }

  void _applyInlineHemodynamicPointMove(
    String type,
    double matchTime,
    double matchValue,
    double newValue,
    double newTime,
  ) {
    if (!_hasAnesthesiaStartMarker || _inlineHemodynamicRemoveMode) return;
    final updatedPoints = _hemodynamicService.updatePoint(
      points: _record.hemodynamicPoints,
      type: type,
      matchTime: matchTime,
      matchValue: matchValue,
      newTime: newTime,
      newValue: newValue,
    );
    if (identical(updatedPoints, _record.hemodynamicPoints)) return;
    setState(() {
      _record = _record.copyWith(hemodynamicPoints: updatedPoints);
    });
  }

  AnesthesiaRecord _migrateLegacyHemodynamics(AnesthesiaRecord record) =>
      _hemodynamicService.migrateLegacyHemodynamics(record);

  @override
  void initState() {
    super.initState();
    _initialRecord = widget.initialRecord ?? const AnesthesiaRecord.empty();
    _record = _migrateLegacyHemodynamics(_initialRecord);
    _caseStatus = widget.initialCaseStatus;
    _venousAccesses = List<String>.from(_record.venousAccesses);
    _arterialAccesses = List<String>.from(_record.arterialAccesses);
    _monitoringItems = List<String>.from(_record.monitoringItems);
    _preAnestheticDate = widget.initialPreAnestheticDate;
    _anesthesiaDate = widget.initialAnesthesiaDate.trim().isEmpty
        ? _nowLabel()
        : widget.initialAnesthesiaDate;
    if (widget.loadPersistedRecord) {
      _loadPersistedRecord();
    }
    if (widget.autoOpenPreAnesthetic) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showPreAnestheticDialog();
        }
      });
    }
    _startHemodynamicTickerIfNeeded();
  }

  @override
  void dispose() {
    _hemodynamicTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadPersistedRecord() async {
    final storedRecord = await _storageService.loadRecord();
    if (!mounted || storedRecord == null) return;

    setState(() {
      _record = _migrateLegacyHemodynamics(storedRecord);
      _venousAccesses = List<String>.from(_record.venousAccesses);
      _arterialAccesses = List<String>.from(_record.arterialAccesses);
      _monitoringItems = List<String>.from(_record.monitoringItems);
    });
    _startHemodynamicTickerIfNeeded();
  }

  Future<void> _persistRecord() async {
    final caseId = widget.caseId;
    if (caseId == null) {
      await _storageService.saveRecord(_record);
      return;
    }

    final now = DateTime.now().toIso8601String();
    await _storageService.upsertCase(
      AnesthesiaCase(
        id: caseId,
        createdAtIso: widget.createdAtIso ?? now,
        updatedAtIso: now,
        preAnestheticDate: _preAnestheticDate,
        anesthesiaDate: _anesthesiaDate,
        status: _persistedCaseStatus,
        record: _record,
      ),
    );
  }

  void _startHemodynamicTickerIfNeeded() {
    _hemodynamicTicker?.cancel();
    if (_hemodynamicAnesthesiaStartAt == null) return;
    _hemodynamicTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _runAiAnalysis() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Enviando ficha para análise...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 900),
      ),
    );

    final analysis = await _analysisService.analyzeRecord(_record);
    if (!mounted) return;

    messenger.clearSnackBars();
    await showDialog<void>(
      context: context,
      builder: (_) => RecordAnalysisDialog(analysis: analysis),
    );
  }

  Future<void> _exportCasePdf() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Gerando PDF da ficha...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 900),
      ),
    );

    final bytes = await _reportExportService.buildCasePdf(
      record: _record,
      status: _persistedCaseStatus,
      caseId: widget.caseId,
    );
    if (!mounted) return;
    messenger.clearSnackBars();

    final filename = _reportExportService.buildFileName(_record);
    await showDialog<void>(
      context: context,
      builder: (_) => _ExportCaseDialog(
        onPreviewPressed: () => _previewPdf(bytes),
        onPrintPressed: () => _previewPdf(bytes),
        onSharePressed: () => _sharePdf(bytes, filename),
      ),
    );
  }

  Future<void> _exportCaseJson() async {
    final jsonText = _reportExportService.buildCaseJson(
      record: _record,
      status: _persistedCaseStatus,
      caseId: widget.caseId,
    );
    final subject = 'Ficha de ${_record.patient.name.isNotEmpty ? _record.patient.name : 'paciente'}';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => JsonExportDialog(content: jsonText, subject: subject),
    );
  }

  Future<void> _previewPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _sharePdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<void> _finalizarCaso() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar caso'),
        content: const Text(
          'A ficha será marcada como finalizada e ficará guardada no arquivo local para reabertura posterior.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _caseStatus = AnesthesiaCaseStatus.finalized;
    });
    await _persistRecord();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _showPreAnestheticDialog() async {
    final result = await Navigator.of(context).push<PreAnestheticScreenResult>(
      MaterialPageRoute<PreAnestheticScreenResult>(
        builder: (_) => PreAnestheticScreen(
          patient: _record.patient,
          initialAssessment: _record.preAnestheticAssessment,
          initialConsultationDate: _preAnestheticDate.trim().isEmpty
              ? _nowLabel()
              : _preAnestheticDate,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      final updatedPatient = result.patient.copyWith(
        asa: result.assessment.asaClassification,
        allergies: result.assessment.allergyDescription.trim().isEmpty
            ? result.patient.allergies
            : _splitListText(result.assessment.allergyDescription),
        restrictions: result.assessment.patientRestrictions.trim().isEmpty
            ? result.patient.restrictions
            : _splitListText(result.assessment.patientRestrictions),
        medications: result.assessment.currentMedications,
      );

      _record = _record.copyWith(
        patient: updatedPatient,
        preAnestheticAssessment: result.assessment,
        airway: result.assessment.airway,
        fastingHours: _record.fastingHours.trim().isEmpty
            ? result.assessment.fastingSolids
            : _record.fastingHours,
        anesthesiaTechnique: result.assessment.anestheticPlan.trim().isEmpty
            ? _record.anesthesiaTechnique
            : result.assessment.anestheticPlan.trim(),
      );
      _preAnestheticDate = result.consultationDate.trim();
    });
    await _persistRecord();
  }

  Future<void> _editPreAnestheticDate() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Data da consulta pré-anestésica',
        label: 'Consulta pré-anestésica',
        initialValue: _preAnestheticDate.trim().isEmpty
            ? _nowLabel()
            : _preAnestheticDate,
        hintText: 'dd/mm/aaaa hh:mm',
      ),
    );

    if (result == null) return;
    setState(() {
      _preAnestheticDate = result.trim();
    });
    await _persistRecord();
  }

  Future<void> _editAnesthesiaDate() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Data da anestesia / cirurgia',
        label: 'Anestesia / cirurgia',
        initialValue: _anesthesiaDate.trim().isEmpty
            ? _nowLabel()
            : _anesthesiaDate,
        hintText: 'dd/mm/aaaa hh:mm',
      ),
    );

    if (result == null) return;
    setState(() {
      _anesthesiaDate = result.trim();
    });
    await _persistRecord();
  }

  Future<void> _editPatientName() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Nome do paciente',
        label: 'Nome',
        initialValue: _record.patient.name,
        hintText: 'Digite o nome do paciente',
      ),
    );

    if (result == null) return;
    await _updatePatient(name: result);
  }

  Future<void> _editPatientAge() async {
    final initialValue =
        _record.patient.age > 0 ? _record.patient.age.toString() : '';
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Idade do paciente',
        label: 'Idade',
        initialValue: initialValue,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        hintText: 'Digite a idade em anos',
      ),
    );

    if (result == null) return;
    await _updatePatient(age: int.tryParse(result) ?? 0);
  }

  Future<void> _editPatientWeight() async {
    final initialValue = _record.patient.weightKg > 0
        ? _record.patient.weightKg.toStringAsFixed(0)
        : '';
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Peso do paciente',
        label: 'Peso (kg)',
        initialValue: initialValue,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        ],
        hintText: 'Digite o peso em kg',
      ),
    );

    if (result == null) return;
    await _updatePatient(
      weightKg: double.tryParse(result.replaceAll(',', '.')) ?? 0,
    );
  }

  Future<void> _editPatientHeight() async {
    final initialValue = _record.patient.heightMeters > 0
        ? _record.patient.heightMeters.toStringAsFixed(2).replaceAll('.', ',')
        : '';
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Altura do paciente',
        label: 'Altura (m)',
        initialValue: initialValue,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        ],
        hintText: 'Digite a altura em metros',
      ),
    );

    if (result == null) return;
    await _updatePatient(
      heightMeters: double.tryParse(result.replaceAll(',', '.')) ?? 0,
    );
  }

  Future<void> _editPatientAsa() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Classificação ASA',
        options: _asaOptions,
        initialValue: _record.patient.asa,
        optionLabelBuilder: (option) => 'ASA $option',
      ),
    );

    if (result == null) return;
    await _updatePatient(asa: result);
  }

  Future<void> _editPatientMallampati() async {
    final currentMallampati =
        _record.preAnestheticAssessment.airway.mallampati.trim().isNotEmpty
            ? _record.preAnestheticAssessment.airway.mallampati
            : _record.airway.mallampati;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Mallampati',
        options: _mallampatiOptions,
        initialValue: currentMallampati,
        optionLabelBuilder: (option) => 'Classe $option',
      ),
    );

    if (result == null) return;
    await _updatePatient(mallampati: result);
  }

  Future<void> _editPatientPopulation() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Perfil do paciente',
        options: PatientPopulation.values.map((item) => item.code).toList(),
        initialValue: _record.patient.population.code,
        optionLabelBuilder: (option) =>
            PatientPopulationX.fromCode(option).label,
      ),
    );

    if (result == null) return;
    await _updatePatient(population: PatientPopulationX.fromCode(result));
  }

  Future<void> _editPatientPostnatalAge() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Idade pós-natal',
        label: 'Idade pós-natal (dias)',
        initialValue: _record.patient.postnatalAgeDays > 0
            ? _record.patient.postnatalAgeDays.toString()
            : '',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );

    if (result == null) return;
    await _updatePatient(postnatalAgeDays: int.tryParse(result) ?? 0);
  }

  Future<void> _editPatientGestationalAge() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Idade gestacional ao nascer',
        label: 'IG ao nascer (semanas)',
        initialValue: _record.patient.gestationalAgeWeeks > 0
            ? _record.patient.gestationalAgeWeeks.toString()
            : '',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );

    if (result == null) return;
    await _updatePatient(gestationalAgeWeeks: int.tryParse(result) ?? 0);
  }

  Future<void> _editPatientCorrectedGestationalAge() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Idade gestacional corrigida',
        label: 'IG corrigida (semanas)',
        initialValue: _record.patient.correctedGestationalAgeWeeks > 0
            ? _record.patient.correctedGestationalAgeWeeks.toString()
            : '',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );

    if (result == null) return;
    await _updatePatient(
      correctedGestationalAgeWeeks: int.tryParse(result) ?? 0,
    );
  }

  Future<void> _editPatientBirthWeight() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Peso ao nascer',
        label: 'Peso ao nascer (kg)',
        initialValue: _record.patient.birthWeightKg > 0
            ? _record.patient.birthWeightKg.toStringAsFixed(2).replaceAll('.', ',')
            : '',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        ],
      ),
    );

    if (result == null) return;
    await _updatePatient(
      birthWeightKg: double.tryParse(result.replaceAll(',', '.')) ?? 0,
    );
  }

  Future<void> _editPatientAllergies() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: 'Alergias',
        label: 'Alergias',
        initialItems: _record.patient.allergies,
        suggestions: _commonAllergies,
        hintText: 'Uma alergia por linha',
      ),
    );

    if (result == null) return;
    await _updatePatient(allergies: result);
  }

  Future<void> _editPatientRestrictions() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: 'Restrições',
        label: 'Restrições',
        initialItems: _record.patient.restrictions,
        suggestions: _profileRestrictionSuggestions,
        hintText: 'Uma restrição por linha',
      ),
    );

    if (result == null) return;
    await _updatePatient(restrictions: result);
  }

  Future<void> _editPatientMedications() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: 'Medicações em uso',
        label: 'Medicações',
        initialItems: _record.patient.medications,
        suggestions: _profileMedicationSuggestions,
        hintText: 'Uma medicação por linha',
      ),
    );

    if (result == null) return;
    await _updatePatient(medications: result);
  }

  Future<void> _editViaAereaSection(AirwayEditSection section) async {
    final result = await showDialog<Airway>(
      context: context,
      builder: (_) =>
          AirwayDialog(
            initialAirway: _record.airway,
            section: section,
            patient: _record.patient,
          ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(
        airway: result,
        preAnestheticAssessment: _record.preAnestheticAssessment.copyWith(
          airway: result,
        ),
      );
    });
    await _persistRecord();
  }

  Future<void> _editBalancoHidrico() async {
    final result = await showDialog<FluidBalance>(
      context: context,
      builder: (_) => BalanceOnlyDialog(
        initialFluidBalance: _record.fluidBalance,
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(fluidBalance: result);
    });
    await _persistRecord();
  }

  Future<void> _editReposicaoVolemica() async {
    final result = await showDialog<FluidBalanceDialogResult>(
      context: context,
      builder: (_) => FluidBalanceDialog(
        initialFluidBalance: _record.fluidBalance,
        initialSurgicalSize: _record.surgicalSize,
        initialFastingHours: _displayFastingHours,
        patientWeightKg: _record.patient.weightKg,
        patientHeightMeters: _record.patient.heightMeters,
        patientPopulation: _record.patient.population,
        patientAgeYears: _record.patient.age,
        patientPostnatalAgeDays: _record.patient.postnatalAgeDays,
        patientGestationalAgeWeeks: _record.patient.gestationalAgeWeeks,
        patientBirthWeightKg: _record.patient.birthWeightKg,
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(
        fluidBalance: result.fluidBalance,
        surgicalSize: result.surgicalSize,
        fastingHours: result.fastingHours,
      );
    });
    await _persistRecord();
  }

  Future<void> _editFastingHours() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Jejum',
        label: 'Tempo de jejum (h)',
        initialValue: _displayFastingHours,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.><hH -]')),
        ],
        hintText: 'Ex: 8, >8h, 6',
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(fastingHours: result.trim());
    });
    await _persistRecord();
  }

  Future<void> _editMaintenanceAgents() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: 'Manutenção da anestesia',
        label: 'Agentes / estratégia de manutenção',
        initialItems: _lineItems(_record.maintenanceAgents),
        hintText: 'Um item por linha',
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(maintenanceAgents: result.join('\n'));
    });
    await _persistRecord();
  }

  Future<void> _editTecnicaAnestesica() async {
    final result = await showDialog<TechniqueDialogResult>(
      context: context,
      builder: (_) => TechniqueDialog(
        initialTechnique: _record.anesthesiaTechnique,
        patient: _record.patient,
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(
        anesthesiaTechnique: result.technique,
        preAnestheticAssessment: _record.preAnestheticAssessment.copyWith(
          anestheticPlan: result.technique,
        ),
      );
    });
    await _persistRecord();
  }

  Future<void> _editAcessoVenoso() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => VenousAccessDialog(
        initialItems: _venousAccesses,
      ),
    );
    if (result == null) return;
    setState(() {
      _venousAccesses = result;
      _record = _record.copyWith(venousAccesses: result);
    });
    await _persistRecord();
  }

  Future<void> _editAcessoArterial() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => ArterialAccessDialog(
        initialItems: _arterialAccesses,
      ),
    );
    if (result == null) return;
    setState(() {
      _arterialAccesses = result;
      _record = _record.copyWith(arterialAccesses: result);
    });
    await _persistRecord();
  }

  Future<void> _editMonitorizacao() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => MonitoringDialog(
        initialItems: _monitoringItems,
        patient: _record.patient,
      ),
    );
    if (result == null) return;
    setState(() {
      _monitoringItems = result;
      _record = _record.copyWith(monitoringItems: result);
    });
    await _persistRecord();
  }

  Future<void> _openManualHemodynamicEntry() async {
    if (!_hasAnesthesiaStartMarker || _inlineHemodynamicRemoveMode) return;

    final label = switch (_inlineHemodynamicType) {
      'SpO2' => 'SpO₂ (%)',
      'FC' => 'FC (bpm)',
      'PAI' => 'PAI (mmHg)',
      'PAS' => 'PAS (mmHg)',
      'PAD' => 'PAD (mmHg)',
      _ => 'Valor',
    };

    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Lançar $_inlineHemodynamicType',
        label: label,
        initialValue: '',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        ],
        hintText: 'Digite o valor e salve',
      ),
    );

    if (result == null) return;
    final value = double.tryParse(result.replaceAll(',', '.'));
    if (value == null) return;
    await _addInlineHemodynamicPoint(value);
  }

  Future<void> _editEventos() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => EventsDialog(initialItems: _record.events),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(events: result);
    });
    await _persistRecord();
  }

  Future<void> _editDrogasInfusoes() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => DrugInfusionsDialog(initialItems: _record.drugs),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(drugs: result);
    });
    await _persistRecord();
  }

  Future<void> _editAdjuvantes() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => AdjunctsDialog(initialItems: _record.adjuncts),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(adjuncts: result);
    });
    await _persistRecord();
  }

  Future<void> _editOtherMedications() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => CatalogMedicationDialog(
        title: 'Editar Outras medicações',
        catalogItems: _profileOtherMedicationOptions,
        initialItems: _record.otherMedications,
      ),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(otherMedications: result);
    });
    await _persistRecord();
  }

  Future<void> _editVasoactiveDrugs() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => VasoactiveDrugsDialog(
        catalogItems: _profileVasoactiveDrugOptions,
        initialItems: _record.vasoactiveDrugs,
      ),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(vasoactiveDrugs: result);
    });
    await _persistRecord();
  }

  Future<void> _editProphylacticAntibiotics() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => CatalogMedicationDialog(
        title: 'Editar Antibiótico profilaxia',
        catalogItems: _profileProphylacticAntibioticOptions,
        initialItems: _record.prophylacticAntibiotics,
      ),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(prophylacticAntibiotics: result);
    });
    await _persistRecord();
  }

  Future<void> _editSurgerySection(SurgeryInfoSection section) async {
    if (section == SurgeryInfoSection.description) {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (_) => ListFieldDialog(
          title: 'Cirurgia',
          label: 'Cirurgia',
          initialItems: _lineItems(_record.surgeryDescription),
          hintText: 'Uma cirurgia / procedimento por linha',
        ),
      );
      if (result == null) return;
      setState(() {
        _record = _record.copyWith(surgeryDescription: result.join('\n'));
      });
      await _persistRecord();
      return;
    }

    if (section == SurgeryInfoSection.surgeon) {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (_) => ListFieldDialog(
          title: 'Cirurgião',
          label: 'Cirurgião',
          initialItems: _lineItems(_record.surgeonName),
          hintText: 'Um nome por linha',
        ),
      );
      if (result == null) return;
      setState(() {
        _record = _record.copyWith(surgeonName: result.join('\n'));
      });
      await _persistRecord();
      return;
    }

    if (section == SurgeryInfoSection.assistants) {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (_) => ListFieldDialog(
          title: 'Auxiliares',
          label: 'Auxiliares',
          initialItems: _record.assistantNames,
          hintText: 'Um nome por linha',
        ),
      );
      if (result == null) return;
      setState(() {
        _record = _record.copyWith(assistantNames: result);
      });
      await _persistRecord();
      return;
    }

    if (section == SurgeryInfoSection.notes) {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (_) => ListFieldDialog(
          title: 'Anotações relevantes',
          label: 'Anotações relevantes',
          initialItems: _lineItems(_record.operationalNotes),
          hintText: 'Uma anotação por linha',
        ),
      );
      if (result == null) return;
      setState(() {
        _record = _record.copyWith(operationalNotes: result.join('\n'));
      });
      await _persistRecord();
      return;
    }

    final result = await showDialog<SurgeryInfoDialogResult>(
      context: context,
      builder: (_) => SurgeryInfoDialog(
        section: section,
        initialDescription: _record.surgeryDescription,
        initialPriority: _displaySurgeryPriority,
        initialSurgeon: _record.surgeonName,
        initialAssistants: _record.assistantNames,
        initialDestination: _record.patientDestination,
        initialOtherDestination: _record.otherPatientDestination,
        initialNotes: _record.operationalNotes,
        initialChecklist: _record.safeSurgeryChecklist,
        initialTimeOutChecklist: _record.timeOutChecklist,
        initialTimeOutCompleted: _record.timeOutCompleted,
        patientPopulation: _record.patient.population,
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(
        surgeryDescription: result.description,
        surgeryPriority: result.priority,
        surgeonName: result.surgeon,
        assistantNames: result.assistants,
        patientDestination: result.destination,
        otherPatientDestination: result.otherDestination,
        operationalNotes: result.notes,
        safeSurgeryChecklist: result.checklist,
        timeOutChecklist: result.timeOutChecklist,
        timeOutCompleted: result.timeOutCompleted,
      );
    });
    await _persistRecord();
  }

  Future<void> _editAnesthesiologists() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => AnesthesiologistsDialog(
        initialItems: _anesthesiologistEntries,
      ),
    );

    if (result == null) return;

    final first = result.isEmpty ? ['', '', ''] : [...result.first.split('|'), '', '', ''];
    setState(() {
      _record = _record.copyWith(
        anesthesiologists: result,
        anesthesiologistName: first[0].trim(),
        anesthesiologistCrm: first[1].trim(),
        anesthesiologistDetails: first[2].trim(),
      );
    });
    await _persistRecord();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1100;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              child: PageContainer(
                child: Column(
                  children: [
                    TopBarWidget(
                      onPreAnestheticTap: _showPreAnestheticDialog,
                      caseStage: _caseStageLabel,
                      recordStatus: _recordStatusLabel,
                      highlightMessage: _topHighlightMessage,
                      preAnestheticDateLabel: _displayPreAnestheticDate,
                      anesthesiaDateLabel: _displayAnesthesiaDate,
                      onPreAnestheticDateTap: _editPreAnestheticDate,
                      onAnesthesiaDateTap: _editAnesthesiaDate,
                    ),
                    const SizedBox(height: 10),
                    AnesthesiaHeaderWidget(
                      key: _patientSummaryKey,
                      patient: _record.patient,
                      mallampati:
                          _usesMallampatiInCase &&
                                  _record.preAnestheticAssessment.airway.mallampati.trim().isNotEmpty
                              ? _record.preAnestheticAssessment.airway.mallampati
                              : _usesMallampatiInCase
                                  ? _record.airway.mallampati
                                  : '',
                      onNameTap: _editPatientName,
                      onAgeTap: _editPatientAge,
                      onWeightTap: _editPatientWeight,
                      onHeightTap: _editPatientHeight,
                      onPopulationTap: _editPatientPopulation,
                      onPostnatalAgeTap: _editPatientPostnatalAge,
                      onGestationalAgeTap: _editPatientGestationalAge,
                      onCorrectedGestationalAgeTap:
                          _editPatientCorrectedGestationalAge,
                      onBirthWeightTap: _editPatientBirthWeight,
                      onAsaTap: _editPatientAsa,
                      onInformedConsentTap: _editPatientInformedConsentStatus,
                      onMallampatiTap: _usesMallampatiInCase
                          ? _editPatientMallampati
                          : null,
                      onAllergiesTap: _editPatientAllergies,
                      onRestrictionsTap: _editPatientRestrictions,
                      onMedicationsTap: _editPatientMedications,
                    ),
                    const SizedBox(height: 10),
                    desktop
                        ? _buildDesktopTopCardsAndFullWidthChart()
                        : Column(
                            children: [
                              _buildMobileOverview(),
                              const SizedBox(height: 12),
                              _buildChartSection(dominant: false),
                              const SizedBox(height: 12),
                              _buildIntraoperativeSection(),
                            ],
                          ),
                    const SizedBox(height: 12),
                    FooterBar(
                      onExportPressed: _exportCasePdf,
                      onVerifyPressed: _runAiAnalysis,
                      onFinalizePressed: _finalizarCaso,
                      onExportJsonPressed: _exportCaseJson,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDesktopOverview() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildSectionHeader(
                title: 'Preparo e Monitorização',
                subtitle: 'Via aérea, acessos e monitorização contínua',
                accent: const Color(0xFF2B76D2),
              ),
              const SizedBox(height: 10),
              _buildAirwayCard(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildVenousAccessCard(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildArterialAccessCard(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMonitoringCard(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _buildSectionHeader(
                title: 'Procedimento e Anestesia',
                subtitle: 'Cirurgia, time-out, técnica, medicações e balanço',
                accent: const Color(0xFF8A5DD3),
              ),
              const SizedBox(height: 10),
              _buildSurgeryCards(desktop: true),
              const SizedBox(height: 12),
              _buildTechniqueCard(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDrugsCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildAdjunctsCard()),
                ],
              ),
              const SizedBox(height: 12),
              _buildFluidBalanceCard(),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildDesktopHemodynamicFirstLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 9,
          child: Column(
            children: [
              _buildSectionHeader(
                title: 'Registro Intraoperatório',
                subtitle: 'Área principal de condução do caso e registro hemodinâmico',
                accent: const Color(0xFF2B76D2),
              ),
              const SizedBox(height: 10),
              _buildChartSection(dominant: true),
              const SizedBox(height: 12),
              SizedBox(height: 240, child: _buildEventsCard()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildSectionHeader(
                title: 'Blocos de Apoio',
                subtitle: 'Informações clínicas, preparo e documentação complementar',
                accent: const Color(0xFF6B7CF6),
              ),
              const SizedBox(height: 10),
              _buildSurgeryCards(desktop: true),
              const SizedBox(height: 12),
              _buildTechniqueCard(),
              const SizedBox(height: 12),
              _buildAirwayCard(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildVenousAccessCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildArterialAccessCard()),
                ],
              ),
              const SizedBox(height: 12),
              _buildMonitoringCard(),
              const SizedBox(height: 12),
              _buildDrugsCard(),
              const SizedBox(height: 12),
              _buildAdjunctsCard(),
              const SizedBox(height: 12),
              _buildFluidBalanceCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTopCardsAndFullWidthChart() {
    return Column(
      children: [
        _buildEqualWidthTripletRow(
          first: _buildSurgerySummaryCard(
            key: const Key('surgery-description-card'),
            tapKey: const Key('surgery-description-entry'),
            title: '1) Cirurgia',
            icon: Icons.content_paste_search_outlined,
            value: _multilineSummary(_record.surgeryDescription),
            section: SurgeryInfoSection.description,
            isCompleted: _record.surgeryDescription.trim().isNotEmpty,
          ),
          second: _buildSurgerySummaryCard(
            key: const Key('surgery-priority-card'),
            tapKey: const Key('surgery-priority-entry'),
            title: '2) Tipo de cirurgia',
            icon: Icons.priority_high_outlined,
            value: _valueOrPlaceholder(_displaySurgeryPriority),
            section: SurgeryInfoSection.priority,
            isCompleted: _displaySurgeryPriority.trim().isNotEmpty,
          ),
          third: _buildSurgerySummaryCard(
            key: const Key('surgery-surgeon-card'),
            tapKey: const Key('surgery-surgeon-entry'),
            title: '3) Cirurgião',
            icon: Icons.person_outline,
            value: _multilineSummary(_record.surgeonName),
            section: SurgeryInfoSection.surgeon,
            isCompleted: _record.surgeonName.trim().isNotEmpty,
          ),
        ),
        const SizedBox(height: 12),
        _buildEqualWidthTripletRow(
          first: _buildSurgerySummaryCard(
            key: const Key('surgery-assistants-card'),
            tapKey: const Key('surgery-assistants-entry'),
            title: '4) Auxiliares',
            icon: Icons.groups_outlined,
            value: _record.assistantNames.isEmpty
                ? 'Toque para preencher'
                : _record.assistantNames.join(', '),
            section: SurgeryInfoSection.assistants,
            isCompleted: _record.assistantNames.isNotEmpty,
          ),
          second: _buildSurgerySummaryCard(
            key: const Key('surgery-anesthesiologists-card'),
            tapKey: const Key('surgery-anesthesiologists-entry'),
            title: '5) Anestesiologistas',
            icon: Icons.badge_outlined,
            value: _displayAnesthesiologists,
            onTap: _editAnesthesiologists,
            isCompleted: _anesthesiologistEntries.isNotEmpty,
          ),
          third: _buildSurgerySummaryCard(
            key: const Key('surgery-notes-card'),
            tapKey: const Key('surgery-notes-entry'),
            title: '6) Anotações relevantes',
            icon: Icons.note_alt_outlined,
            value: _multilineSummary(_record.operationalNotes),
            section: SurgeryInfoSection.notes,
            isCompleted: _record.operationalNotes.trim().isNotEmpty,
          ),
        ),
        const SizedBox(height: 12),
        _buildEqualWidthTripletRow(
          first: _buildFastingCard(),
          second: _buildAntibioticProphylaxisCard(),
          third: _buildVenousAccessCard(),
        ),
        const SizedBox(height: 12),
        _buildEqualWidthTripletRow(
          first: _buildMonitoringCard(),
          second: _buildTimeOutCard(),
          third: _buildTechniqueCard(),
        ),
        const SizedBox(height: 12),
        _buildEqualWidthTripletRow(
          first: _buildDrugsCard(),
          second: _buildAdjunctsCard(),
          third: _buildAirwayCard(),
        ),
        const SizedBox(height: 12),
        _buildEqualWidthTripletRow(
          first: _buildMaintenanceCard(),
          second: _buildOtherMedicationsCard(),
          third: _buildVasoactiveDrugsCard(),
        ),
        const SizedBox(height: 12),
        _buildEqualWidthTripletRow(
          first: _buildVolumeReplacementCard(),
          second: _buildFluidBalanceCard(),
          third: const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        _buildEqualWidthTripletRow(
          first: _buildArterialAccessCard(),
          second: _buildSurgerySummaryCard(
            key: const Key('surgery-destination-card'),
            tapKey: const Key('surgery-destination-entry'),
            title: '21) Destino pós-operatório',
            icon: Icons.local_hospital_outlined,
            value: _displayPatientDestination,
            section: SurgeryInfoSection.destination,
            isCompleted: _record.patientDestination.trim().isNotEmpty,
          ),
          third: const SizedBox.shrink(),
        ),
        const SizedBox(height: 14),
        _buildSectionHeader(
          title: 'Registro Intraoperatório',
          subtitle: 'Área principal fixa para condução hemodinâmica e eventos',
          accent: const Color(0xFF2B76D2),
        ),
        const SizedBox(height: 10),
        _buildChartSection(dominant: true),
        const SizedBox(height: 12),
        SizedBox(height: 220, child: _buildEventsCard()),
      ],
    );
  }

  Widget _buildEqualWidthTripletRow({
    required Widget first,
    required Widget second,
    required Widget third,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - (spacing * 2)) / 3;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: cardWidth, child: first),
              const SizedBox(width: spacing),
              SizedBox(width: cardWidth, child: second),
              const SizedBox(width: spacing),
              SizedBox(width: cardWidth, child: third),
            ],
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildSurgerySummaryStrip() {
    return _buildEqualWidthTripletRow(
      first: _buildSurgerySummaryCard(
        key: const Key('surgery-description-card'),
        tapKey: const Key('surgery-description-entry'),
        title: 'Cirurgia',
        icon: Icons.content_paste_search_outlined,
        value: _valueOrPlaceholder(_record.surgeryDescription),
        section: SurgeryInfoSection.description,
        isCompleted: _record.surgeryDescription.trim().isNotEmpty,
      ),
      second: _buildSurgerySummaryCard(
        key: const Key('surgery-surgeon-card'),
        tapKey: const Key('surgery-surgeon-entry'),
        title: 'Cirurgião',
        icon: Icons.person_outline,
        value: _valueOrPlaceholder(_record.surgeonName),
        section: SurgeryInfoSection.surgeon,
        isCompleted: _record.surgeonName.trim().isNotEmpty,
      ),
      third: _buildSurgerySummaryCard(
        key: const Key('surgery-priority-card'),
        tapKey: const Key('surgery-priority-entry'),
        title: 'Prioridade',
        icon: Icons.priority_high_outlined,
        value: _valueOrPlaceholder(_displaySurgeryPriority),
        section: SurgeryInfoSection.priority,
        isCompleted: _displaySurgeryPriority.trim().isNotEmpty,
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSurgeryPlanningStrip() {
    return _buildEqualWidthTripletRow(
      first: _buildSurgerySummaryCard(
        key: const Key('surgery-destination-card'),
        tapKey: const Key('surgery-destination-entry'),
        title: 'Destino pós-op',
        icon: Icons.local_hospital_outlined,
        value: _displayPatientDestination,
        section: SurgeryInfoSection.destination,
        isCompleted: _record.patientDestination.trim().isNotEmpty,
      ),
      second: _buildSurgerySummaryCard(
        key: const Key('surgery-assistants-card'),
        tapKey: const Key('surgery-assistants-entry'),
        title: 'Auxiliares',
        icon: Icons.groups_outlined,
        value: _record.assistantNames.isEmpty
            ? 'Toque para preencher'
            : _record.assistantNames.join(', '),
        section: SurgeryInfoSection.assistants,
        isCompleted: _record.assistantNames.isNotEmpty,
      ),
      third: _buildSurgerySummaryCard(
        key: const Key('surgery-anesthesiologists-card'),
        tapKey: const Key('surgery-anesthesiologists-entry'),
        title: 'Anestesiologistas',
        icon: Icons.badge_outlined,
        value: _displayAnesthesiologists,
        onTap: _editAnesthesiologists,
        isCompleted: _anesthesiologistEntries.isNotEmpty,
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSurgeryNotesStrip() {
    return _buildEqualWidthTripletRow(
      first: _buildSurgerySummaryCard(
        key: const Key('surgery-notes-card'),
        tapKey: const Key('surgery-notes-entry'),
        title: 'Chegada ao CC / anotações',
        icon: Icons.note_alt_outlined,
        value: _valueOrPlaceholder(_record.operationalNotes),
        section: SurgeryInfoSection.notes,
        isCompleted: _record.operationalNotes.trim().isNotEmpty,
      ),
      second: _buildTimeOutCard(),
      third: _buildAntibioticProphylaxisCard(),
    );
  }

  Widget _buildMobileOverview() {
    return Column(
      children: [
        _buildSurgerySummaryCard(
          key: const Key('surgery-description-card'),
          tapKey: const Key('surgery-description-entry'),
          title: '1) Cirurgia',
          icon: Icons.content_paste_search_outlined,
          value: _multilineSummary(_record.surgeryDescription),
          section: SurgeryInfoSection.description,
          isCompleted: _record.surgeryDescription.trim().isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildSurgerySummaryCard(
          key: const Key('surgery-priority-card'),
          tapKey: const Key('surgery-priority-entry'),
          title: '2) Tipo de cirurgia',
          icon: Icons.priority_high_outlined,
          value: _valueOrPlaceholder(_displaySurgeryPriority),
          section: SurgeryInfoSection.priority,
          isCompleted: _displaySurgeryPriority.trim().isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildSurgerySummaryCard(
          key: const Key('surgery-surgeon-card'),
          tapKey: const Key('surgery-surgeon-entry'),
          title: '3) Cirurgião',
          icon: Icons.person_outline,
          value: _multilineSummary(_record.surgeonName),
          section: SurgeryInfoSection.surgeon,
          isCompleted: _record.surgeonName.trim().isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildSurgerySummaryCard(
          key: const Key('surgery-assistants-card'),
          tapKey: const Key('surgery-assistants-entry'),
          title: '4) Auxiliares',
          icon: Icons.groups_outlined,
          value: _record.assistantNames.isEmpty
              ? 'Toque para preencher'
              : _record.assistantNames.join(', '),
          section: SurgeryInfoSection.assistants,
          isCompleted: _record.assistantNames.isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildSurgerySummaryCard(
          key: const Key('surgery-anesthesiologists-card'),
          tapKey: const Key('surgery-anesthesiologists-entry'),
          title: '5) Anestesiologistas',
          icon: Icons.badge_outlined,
          value: _displayAnesthesiologists,
          onTap: _editAnesthesiologists,
          isCompleted: _anesthesiologistEntries.isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildSurgerySummaryCard(
          key: const Key('surgery-notes-card'),
          tapKey: const Key('surgery-notes-entry'),
          title: '6) Anotações relevantes',
          icon: Icons.note_alt_outlined,
          value: _multilineSummary(_record.operationalNotes),
          section: SurgeryInfoSection.notes,
          isCompleted: _record.operationalNotes.trim().isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildFastingCard(),
        const SizedBox(height: 12),
        _buildAntibioticProphylaxisCard(),
        const SizedBox(height: 12),
        _buildVenousAccessCard(),
        const SizedBox(height: 12),
        _buildMonitoringCard(),
        const SizedBox(height: 12),
        _buildTimeOutCard(),
        const SizedBox(height: 12),
        _buildTechniqueCard(),
        const SizedBox(height: 12),
        _buildDrugsCard(),
        const SizedBox(height: 12),
        _buildAdjunctsCard(),
        const SizedBox(height: 12),
        _buildAirwayCard(),
        const SizedBox(height: 12),
        _buildMaintenanceCard(),
        const SizedBox(height: 12),
        _buildOtherMedicationsCard(),
        const SizedBox(height: 12),
        _buildVasoactiveDrugsCard(),
        const SizedBox(height: 12),
        _buildVolumeReplacementCard(),
        const SizedBox(height: 12),
        _buildFluidBalanceCard(),
        const SizedBox(height: 12),
        _buildArterialAccessCard(),
        const SizedBox(height: 12),
        _buildSurgerySummaryCard(
          key: const Key('surgery-destination-card'),
          tapKey: const Key('surgery-destination-entry'),
          title: '21) Destino pós-operatório',
          icon: Icons.local_hospital_outlined,
          value: _displayPatientDestination,
          section: SurgeryInfoSection.destination,
          isCompleted: _record.patientDestination.trim().isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(190),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD2E0EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 38,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF17324D),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6F8498),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirwayCard() {
    final airwaySupport = _buildAirwaySupportRecommendation(_record.patient);

    return KeyedSubtree(
      key: _airwaySectionKey,
      child: Column(
        children: [
          PanelCard(
          key: const Key('airway-card'),
          title: '15) Via aérea',
          titleColor: _airwayFluidRowColor,
          icon: Icons.air,
          minHeight: 286,
          isAttention: _hasPendingAirway,
          isCompleted:
              _record.airway.device.trim().isNotEmpty ||
              _record.airway.technique.trim().isNotEmpty ||
              _record.airway.observation.trim().isNotEmpty ||
              _record.airway.cormackLehane.trim().isNotEmpty,
          trailing: const Icon(
            Icons.keyboard_arrow_up,
            color: Color(0xFF7D93AA),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              children: [
                _buildAirwayInfoCard(
                  key: const Key('airway-cormack-field'),
                  label: 'Cormack-Lehane',
                  value: _record.airway.cormackLehane.trim().isEmpty
                      ? 'Toque para preencher após laringoscopia'
                      : 'Cormack ${_record.airway.cormackLehane}',
                  onTap: () => _editViaAereaSection(AirwayEditSection.cormack),
                ),
                const SizedBox(height: 10),
                _buildAirwayInfoCard(
                  key: const Key('airway-device-field'),
                  label: 'Dispositivo',
                  value: _record.airway.device.trim().isEmpty
                      ? 'Toque para preencher'
                      : '${_record.airway.device} ${_record.airway.tubeNumber}'
                            .trim(),
                  onTap: () => _editViaAereaSection(AirwayEditSection.device),
                ),
                if (airwaySupport != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F8FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7E5F5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          airwaySupport.title,
                          style: const TextStyle(
                            color: Color(0xFF2B76D2),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...airwaySupport.lines.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              line,
                              style: const TextStyle(
                                color: Color(0xFF5D7288),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _buildAirwayInfoCard(
                  key: const Key('airway-technique-entry'),
                  label: 'Técnica de intubação',
                  value: _valueOrPlaceholder(_record.airway.technique),
                  onTap: () =>
                      _editViaAereaSection(AirwayEditSection.technique),
                ),
                const SizedBox(height: 10),
                _buildAirwayInfoCard(
                  key: const Key('airway-observation-entry'),
                  label: 'Observações',
                  value: _valueOrPlaceholder(_record.airway.observation),
                  onTap: () =>
                      _editViaAereaSection(AirwayEditSection.observation),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenousAccessCard() {
    final status = _venousAccesses.isEmpty
        ? 'Nenhum acesso venoso registrado'
        : _venousAccesses.first;
    final summary = _venousAccesses.isEmpty
        ? 'Toque para adicionar'
        : _venousAccesses.length == 1
            ? '1 acesso registrado'
            : '${_venousAccesses.length} acessos registrados';
    return _buildCompactOperationalCard(
      key: const Key('venous-access-card'),
      tapKey: const Key('venous-access-entry'),
      title: '9) Acesso venoso',
      titleColor: _accessRowColor,
      icon: Icons.vaccines_outlined,
      minHeight: 92,
      status: status,
      summary: summary,
      onTap: _editAcessoVenoso,
      isCompleted: _venousAccesses.isNotEmpty,
    );
  }

  Widget _buildArterialAccessCard() {
    final status = _arterialAccesses.isEmpty
        ? 'Nenhum acesso arterial registrado'
        : _arterialAccesses.first;
    final summary = _arterialAccesses.isEmpty
        ? 'Toque para adicionar'
        : _arterialAccesses.length == 1
            ? '1 acesso registrado'
            : '${_arterialAccesses.length} acessos registrados';
    return _buildCompactOperationalCard(
      key: const Key('arterial-access-card'),
      tapKey: const Key('arterial-access-entry'),
      title: 'Cateter de PAI',
      titleColor: _accessRowColor,
      icon: Icons.timeline_outlined,
      minHeight: 92,
      status: status,
      summary: summary,
      onTap: _editAcessoArterial,
      isCompleted: _arterialAccesses.isNotEmpty,
    );
  }

  Widget _buildMonitoringCard() {
    final recommended = _recommendedMonitoringItems(_record.patient);
    final missingRecommended = recommended
        .where((item) => !_monitoringItems.contains(item))
        .toList();
    final status = _monitoringItems.isEmpty
        ? 'Nenhum item de monitorização'
        : _monitoringItems.join(', ');
    final summary = _monitoringItems.isEmpty
        ? 'Toque para definir'
        : missingRecommended.isEmpty
            ? '${_monitoringItems.length} item(ns) ativos'
            : 'Sugeridos ausentes: ${missingRecommended.join(', ')}';
    return _buildCompactOperationalCard(
      key: const Key('monitoring-card'),
      tapKey: const Key('monitoring-entry'),
      title: '10) Monitorização',
      titleColor: _accessRowColor,
      icon: Icons.monitor_heart_outlined,
      minHeight: 92,
      status: status,
      summary: summary,
      onTap: _editMonitorizacao,
      isCompleted: _monitoringItems.isNotEmpty,
    );
  }

  Widget _buildIntraoperativeSection() {
    return Column(
      children: [
        _buildSectionHeader(
          title: 'Registro Intraoperatório',
          subtitle: 'Eventos cronológicos do caso',
          accent: const Color(0xFF4A5568),
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: _eventsSectionKey,
          child: SizedBox(height: 220, child: _buildEventsCard()),
        ),
      ],
    );
  }

  Widget _buildChartSection({required bool dominant}) {
    return HemodynamicChartCard(
      dominant: dominant,
      inlineHemodynamicRemoveMode: _inlineHemodynamicRemoveMode,
      hasAnesthesiaStartMarker: _hasAnesthesiaStartMarker,
      hasSurgeryStartMarker: _hasSurgeryStartMarker,
      inlineHemodynamicType: _inlineHemodynamicType,
      currentInlineTime: _currentHemodynamicElapsedMinutes(),
      anesthesiaElapsed: _formatElapsedFrom(_hemodynamicAnesthesiaStartAt),
      surgeryElapsed: _formatElapsedFrom(_hemodynamicSurgeryStartAt),
      points: _record.hemodynamicPoints,
      markers: _record.hemodynamicMarkers,
      latestFc: _latestFcPoint == null
          ? '--'
          : _latestFcPoint!.value.round().toString(),
      latestBloodPressure: _latestBloodPressure,
      latestPam: _latestPam,
      paiSummary: _paiSummary,
      latestSpo2: _latestSpo2Point == null
          ? '--'
          : _latestSpo2Point!.value.round().toString(),
      onAddAnesthesiaStart: () => _addHemodynamicMarker('Início da anestesia'),
      onAddSurgeryStart: () => _addHemodynamicMarker('Início da cirurgia'),
      onAddAnesthesiaEnd: () => _addHemodynamicMarker('Fim da anestesia'),
      onAddSurgeryEnd: () => _addHemodynamicMarker('Fim da cirurgia'),
      hasAnesthesiaEndMarker: _hasAnesthesiaEndMarker,
      hasSurgeryEndMarker: _hasSurgeryEndMarker,
      onToggleRemoveMode: () {
        setState(() {
          _inlineHemodynamicRemoveMode = !_inlineHemodynamicRemoveMode;
        });
      },
      onManualEntry: _openManualHemodynamicEntry,
      onSelectType: (type) {
        setState(() => _inlineHemodynamicType = type);
      },
      onQuickSpo2: _addInlineHemodynamicPoint,
      onPointTap:
          _inlineHemodynamicRemoveMode ? _removeInlineHemodynamicPoint : null,
      onChartTap:
          _hasAnesthesiaStartMarker && !_inlineHemodynamicRemoveMode
              ? _addInlineHemodynamicPoint
              : null,
      onPointMoved:
          _hasAnesthesiaStartMarker && !_inlineHemodynamicRemoveMode
              ? _applyInlineHemodynamicPointMove
              : null,
      onPointDragEnd:
          _hasAnesthesiaStartMarker && !_inlineHemodynamicRemoveMode
              ? () => _persistRecord()
              : null,
    );
  }

  Widget _buildAirwayInfoCard({
    Key? key,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE7F3)),
        ),
        child: DetailLine(label: label, value: value),
      ),
    );
  }

  Widget _buildSurgeryCards({required bool desktop}) {
    final cards = [
      _buildSurgerySummaryCard(
        key: const Key('surgery-description-card'),
        tapKey: const Key('surgery-description-entry'),
        title: 'Cirurgia',
        icon: Icons.content_paste_search_outlined,
        value: _multilineSummary(_record.surgeryDescription),
        section: SurgeryInfoSection.description,
        isCompleted: _record.surgeryDescription.trim().isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-surgeon-card'),
        tapKey: const Key('surgery-surgeon-entry'),
        title: 'Cirurgião',
        icon: Icons.person_outline,
        value: _multilineSummary(_record.surgeonName),
        section: SurgeryInfoSection.surgeon,
        isCompleted: _record.surgeonName.trim().isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-priority-card'),
        tapKey: const Key('surgery-priority-entry'),
        title: 'Prioridade',
        icon: Icons.priority_high_outlined,
        value: _valueOrPlaceholder(_displaySurgeryPriority),
        section: SurgeryInfoSection.priority,
        isCompleted: _displaySurgeryPriority.trim().isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-assistants-card'),
        tapKey: const Key('surgery-assistants-entry'),
        title: 'Auxiliares',
        icon: Icons.groups_outlined,
        value: _record.assistantNames.isEmpty
            ? 'Toque para preencher'
            : _record.assistantNames.join(', '),
        section: SurgeryInfoSection.assistants,
        isCompleted: _record.assistantNames.isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-destination-card'),
        tapKey: const Key('surgery-destination-entry'),
        title: 'Destino pós-op',
        icon: Icons.local_hospital_outlined,
        value: _displayPatientDestination,
        section: SurgeryInfoSection.destination,
        isCompleted: _record.patientDestination.trim().isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-anesthesiologists-card'),
        tapKey: const Key('surgery-anesthesiologists-entry'),
        title: 'Anestesiologistas',
        icon: Icons.badge_outlined,
        value: _displayAnesthesiologists,
        onTap: _editAnesthesiologists,
        isCompleted: _anesthesiologistEntries.isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-notes-card'),
        tapKey: const Key('surgery-notes-entry'),
        title: 'Chegada ao CC / anotações',
        icon: Icons.note_alt_outlined,
        value: _multilineSummary(_record.operationalNotes),
        section: SurgeryInfoSection.notes,
        isCompleted: _record.operationalNotes.trim().isNotEmpty,
      ),
      _buildTimeOutCard(),
    ];

    if (!desktop) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[3]),
            const SizedBox(width: 12),
            Expanded(child: cards[5]),
            const SizedBox(width: 12),
            Expanded(child: cards[4]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[6]),
            const SizedBox(width: 12),
            Expanded(child: cards[7]),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildSurgerySummaryCard({
    Key? key,
    Key? tapKey,
    required String title,
    required IconData icon,
    required String value,
    SurgeryInfoSection? section,
    VoidCallback? onTap,
    bool isCompleted = false,
  }) {
    return PanelCard(
      key: key,
      title: title,
      titleColor: _surgeryRowColor,
      icon: icon,
      isCompleted: isCompleted,
      child: InkWell(
        key: tapKey,
        borderRadius: BorderRadius.circular(10),
        onTap: onTap ?? (section == null ? null : () => _editSurgerySection(section)),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactOperationalCard({
    Key? key,
    Key? tapKey,
    required String title,
    required Color titleColor,
    required IconData icon,
    required String status,
    required String summary,
    required VoidCallback onTap,
    Color statusColor = const Color(0xFF17324D),
    bool isAttention = false,
    bool isCompleted = false,
    double minHeight = 92,
  }) {
    return PanelCard(
      key: key,
      title: title,
      titleColor: titleColor,
      icon: icon,
      minHeight: minHeight,
      isAttention: isAttention,
      isCompleted: isCompleted,
      child: InkWell(
        key: tapKey,
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5D7288),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8CA0B5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOutCard() {
    final completed = _record.timeOutCompleted;
    final summary = _record.timeOutChecklist.isEmpty
        ? 'Toque para preencher'
        : '${_record.timeOutChecklist.length} itens confirmados';
    return _buildCompactOperationalCard(
      key: const Key('surgery-timeout-card'),
      title: '11) Time-out',
      titleColor: _timeoutRowColor,
      icon: Icons.alarm_on_outlined,
      isAttention: _hasPendingTimeOut,
      tapKey: const Key('surgery-timeout-entry'),
      status: completed ? 'Time-out finalizado' : 'Time-out pendente',
      statusColor:
          completed ? const Color(0xFF169653) : const Color(0xFFF59E0B),
      summary: summary,
      onTap: () => _editSurgerySection(SurgeryInfoSection.timeOut),
      isCompleted: completed,
    );
  }

  Widget _buildAntibioticProphylaxisCard() {
    final redoseAlerts = _antibioticRedoseAlerts;
    final antibiotics = _record.prophylacticAntibiotics;
    final status = redoseAlerts.isNotEmpty
        ? '${redoseAlerts.first.name}: ${redoseAlerts.first.message}'
        : antibiotics.isEmpty
            ? 'Nenhum antibiótico registrado'
            : antibiotics.length == 1
                ? antibiotics.first.split('|').first
                : '${antibiotics.length} antibióticos registrados';
    final summary = redoseAlerts.isNotEmpty
        ? redoseAlerts.first.detail
        : antibiotics.isEmpty
            ? 'Toque para registrar dose e horário'
            : () {
                final first = antibiotics.first.split('|');
                final dose = _medicationDoseSummary(first);
                final time = first.length > 2 && first[2].trim().isNotEmpty
                    ? first[2].trim()
                    : '--:--';
                return '$dose • $time';
              }();
    return _buildCompactOperationalCard(
      key: const Key('antibiotic-entry-card'),
      tapKey: const Key('antibiotic-entry'),
      title: '8) Antibiótico profilaxia',
      titleColor: _timeoutRowColor,
      icon: Icons.medical_services_outlined,
      minHeight: 92,
      isAttention: redoseAlerts.isNotEmpty,
      status: status,
      statusColor: redoseAlerts.isNotEmpty
          ? (redoseAlerts.first.isOverdue
              ? const Color(0xFFD64545)
              : const Color(0xFFF0A11F))
          : const Color(0xFF17324D),
      summary: summary,
      onTap: _editProphylacticAntibiotics,
      isCompleted: antibiotics.isNotEmpty && redoseAlerts.isEmpty,
    );
  }

  Widget _buildFastingCard() {
    final fasting = _displayFastingHours;

    return _buildCompactOperationalCard(
      title: '7) Jejum',
      titleColor: _timeoutRowColor,
      icon: Icons.schedule_outlined,
      minHeight: 92,
      status: fasting.isEmpty ? 'Jejum não informado' : '$fasting h',
      summary: _fastingSummaryForProfile(
        patient: _record.patient,
        fastingText: fasting,
      ),
      onTap: _editFastingHours,
      isCompleted: fasting.isNotEmpty,
    );
  }

  Widget _buildEventsCard() {
    return PanelCard(
      key: const Key('events-card'),
      title: 'Eventos',
      titleColor: const Color(0xFF4A5568),
      icon: Icons.event_note_outlined,
      fillChild: true,
      isAttention: _hasPendingEvents,
      isCompleted: _record.events.isNotEmpty,
      trailing: AddButton(label: 'Adicionar evento', onTap: _editEventos),
      child: InkWell(
        key: const Key('events-entry'),
        borderRadius: BorderRadius.circular(18),
        onTap: _editEventos,
        child: _record.events.isEmpty
            ? const Center(
                child: SizedBox(
                  width: 280,
                  child: StatusHint(
                    text: 'Nenhum evento registrado ainda',
                    icon: Icons.event_busy_outlined,
                  ),
                ),
              )
            : EventListWidget(events: _record.events),
      ),
    );
  }

  Widget _buildTechniqueCard() {
    return KeyedSubtree(
      key: _techniqueSectionKey,
      child: PanelCard(
      key: const Key('technique-card'),
      title: '12) Técnica anestésica',
      titleColor: _techniqueRowColor,
      icon: Icons.local_hospital_outlined,
      minHeight: 168,
      isAttention: _hasPendingTechnique,
      isCompleted: _record.anesthesiaTechnique.trim().isNotEmpty,
      child: InkWell(
        key: const Key('technique-entry'),
        borderRadius: BorderRadius.circular(18),
        onTap: _editTecnicaAnestesica,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledSurface(
              label: 'Técnicas selecionadas',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _record.anesthesiaTechnique.trim().isEmpty
                    ? const [
                        Text(
                          'Toque para preencher',
                          style: TextStyle(
                            color: Color(0xFF7A8EA5),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]
                    : _record.anesthesiaTechnique
                        .split('\n')
                        .where((item) => item.trim().isNotEmpty)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: CheckLine(text: item),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDrugsCard() {
    return KeyedSubtree(
      key: _drugsSectionKey,
      child: PanelCard(
      key: const Key('drugs-card'),
      title: '13) Indução',
      titleColor: _techniqueRowColor,
      icon: Icons.medication_outlined,
      minHeight: 168,
      isAttention: _hasPendingDrugs,
      isCompleted: _record.drugs.isNotEmpty,
      child: InkWell(
        key: const Key('drugs-entry'),
        borderRadius: BorderRadius.circular(18),
        onTap: _editDrogasInfusoes,
        child: Column(
          children: [
            if (_record.drugs.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: StatusHint(text: 'Nenhuma droga de indução registrada'),
              ),
            ..._record.drugs.map(
              (drug) {
                final parts = drug.split('|');
                final name = parts.isEmpty ? drug : parts.first;
                final doseSummary = _medicationDoseSummary(parts);
                final time = parts.length > 2 ? parts[2] : '--:--';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DoseRow(
                    drug: name,
                    dose: doseSummary,
                    time: time.isEmpty ? '--:--' : time,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            AddButton(
              label: 'Adicionar droga',
              onTap: _editDrogasInfusoes,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAdjunctsCard() {
    return PanelCard(
      title: '14) Adjuvantes',
      titleColor: _techniqueRowColor,
      icon: Icons.auto_awesome_outlined,
      minHeight: 168,
      isCompleted: _record.adjuncts.isNotEmpty,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _editAdjuvantes,
        child: Column(
          children: [
            if (_record.adjuncts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: StatusHint(text: 'Nenhum adjuvante registrado'),
              ),
            ..._record.adjuncts.map(
              (item) {
                final parts = item.split('|');
                final name = parts.isNotEmpty ? parts[0] : '';
                final doseSummary = _medicationDoseSummary(parts);
                final time = parts.length > 2 ? parts[2] : '--:--';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DoseRow(
                    drug: name,
                    dose: doseSummary,
                    time: time.isEmpty ? '--:--' : time,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            AddButton(
              label: 'Adicionar adjuvante',
              onTap: _editAdjuvantes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherMedicationsCard() {
    return KeyedSubtree(
      key: _otherMedicationsSectionKey,
      child: PanelCard(
        key: const Key('other-medications-card'),
        title: '17) Outras medicações',
        titleColor: _medicationsRowColor,
        icon: Icons.healing_outlined,
        minHeight: 168,
        isCompleted: _record.otherMedications.isNotEmpty,
        child: InkWell(
          key: const Key('other-medications-entry'),
          borderRadius: BorderRadius.circular(18),
          onTap: _editOtherMedications,
          child: Column(
            children: [
              if (_record.otherMedications.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: StatusHint(text: 'Nenhuma medicação complementar registrada'),
                ),
              ..._record.otherMedications.map(
                (item) {
                  final parts = item.split('|');
                  final name = parts.isNotEmpty ? parts[0] : '';
                  final doseSummary = _medicationDoseSummary(parts);
                  final time = parts.length > 2 ? parts[2] : '--:--';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DoseRow(
                      drug: name,
                      dose: doseSummary,
                      time: time.isEmpty ? '--:--' : time,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              AddButton(
                label: 'Adicionar medicação',
                onTap: _editOtherMedications,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVasoactiveDrugsCard() {
    return KeyedSubtree(
      key: _vasoactiveSectionKey,
      child: PanelCard(
        key: const Key('vasoactive-card'),
        title: '18) Drogas vasoativas',
        titleColor: _medicationsRowColor,
        icon: Icons.show_chart_outlined,
        minHeight: 168,
        isCompleted: _record.vasoactiveDrugs.isNotEmpty,
        child: InkWell(
          key: const Key('vasoactive-entry'),
          borderRadius: BorderRadius.circular(18),
          onTap: _editVasoactiveDrugs,
          child: Column(
            children: [
              if (_record.vasoactiveDrugs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: StatusHint(text: 'Nenhuma droga vasoativa registrada'),
                ),
              ..._record.vasoactiveDrugs.map(
                (item) {
                  final parts = item.split('|');
                  final name = parts.isNotEmpty ? parts[0] : '';
                  final doseSummary = _medicationDoseSummary(parts);
                  final time = parts.length > 2 ? parts[2] : '--:--';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DoseRow(
                      drug: name,
                      dose: doseSummary,
                      time: time.isEmpty ? '--:--' : time,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              AddButton(
                label: 'Adicionar vasoativa',
                onTap: _editVasoactiveDrugs,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFluidBalanceCard() {
    final documentedInputs = _documentedInputsMl;
    final documentedLosses = _documentedLossesMl;
    final spongeEstimatedLoss = _record.fluidBalance.estimatedSpongeLoss;
    return KeyedSubtree(
      key: _fluidSectionKey,
      child: PanelCard(
      key: const Key('fluid-balance-card'),
      title: '20) Balanço hídrico',
      titleColor: _airwayFluidRowColor,
      icon: Icons.opacity_outlined,
      minHeight: 286,
      isAttention: _hasPendingFluidBalance,
      isCompleted: _record.fluidBalance.isComplete,
      child: InkWell(
        key: const Key('fluid-balance-entry'),
        borderRadius: BorderRadius.circular(18),
        onTap: _editBalancoHidrico,
        child: Column(
          children: [
            KeyValueLine(
              label: 'Entradas',
              value: '${documentedInputs.toStringAsFixed(0)} mL',
            ),
            const Divider(height: 18),
            KeyValueLine(
              label: 'Saídas',
              value: '${documentedLosses.toStringAsFixed(0)} mL',
            ),
            const Divider(height: 18),
            KeyValueLine(
              label: 'Diurese',
              value: _record.fluidBalance.diuresis.trim().isEmpty
                  ? '--'
                  : '${_record.fluidBalance.diuresis} mL',
            ),
            const Divider(height: 18),
            KeyValueLine(
              label: 'Sangramento',
              value: _record.fluidBalance.bleeding.trim().isEmpty
                  ? '--'
                  : '${_record.fluidBalance.bleeding} mL',
            ),
            const Divider(height: 18),
            KeyValueLine(
              label: 'Compressas',
              value: _record.fluidBalance.spongeCount.trim().isEmpty
                  ? '--'
                  : '${_record.fluidBalance.spongeCount} un • ${spongeEstimatedLoss.toStringAsFixed(0)} mL',
            ),
            const Divider(height: 18),
            KeyValueLine(
              label: 'Outras perdas',
              value: _record.fluidBalance.otherLosses.trim().isEmpty
                  ? '--'
                  : '${_record.fluidBalance.otherLosses} mL',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F8EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: KeyValueLine(
                label: 'Balanço total',
                value: _record.fluidBalance.isComplete
                    ? _record.fluidBalance.formattedBalance
                    : '--',
                labelColor: const Color(0xFF169653),
                valueColor: const Color(0xFF169653),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildVolumeReplacementCard() {
    final recommendation = _buildFluidSupportRecommendation(
      patient: _record.patient,
      documentedLossesMl: _documentedLossesMl,
      fastingHoursText: _displayFastingHours,
    );

    return PanelCard(
      title: '19) Reposição volêmica / sangue',
      titleColor: _airwayFluidRowColor,
      icon: Icons.bloodtype_outlined,
      minHeight: 286,
      isCompleted:
          _record.fluidBalance.blood.trim().isNotEmpty ||
          _record.fluidBalance.colloids.trim().isNotEmpty ||
          _record.fluidBalance.crystalloids.trim().isNotEmpty,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _editReposicaoVolemica,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD7E5F5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: const TextStyle(
                      color: Color(0xFF2B76D2),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...recommendation.lines.map(
                    (line) => Text(
                      line,
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            KeyValueLine(
              label: 'Sangue / hemoderivados',
              value: _record.fluidBalance.blood.trim().isEmpty
                  ? '--'
                  : '${_record.fluidBalance.blood} mL',
            ),
            const Divider(height: 18),
            KeyValueLine(
              label: 'Coloides',
              value: _record.fluidBalance.colloids.trim().isEmpty
                  ? '--'
                  : '${_record.fluidBalance.colloids} mL',
            ),
            const Divider(height: 18),
            KeyValueLine(
              label: 'Cristaloides',
              value: _record.fluidBalance.crystalloids.trim().isEmpty
                  ? '--'
                  : '${_record.fluidBalance.crystalloids} mL',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard() {
    return PanelCard(
      key: const Key('maintenance-card'),
      title: '16) Manutenção da anestesia',
      titleColor: _medicationsRowColor,
      icon: Icons.tune_outlined,
      minHeight: 168,
      isCompleted: _record.maintenanceAgents.trim().isNotEmpty,
      child: InkWell(
        key: const Key('maintenance-entry'),
        borderRadius: BorderRadius.circular(18),
        onTap: _editMaintenanceAgents,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_record.maintenanceAgents.trim().isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: StatusHint(
                  text: 'Nenhum agente de manutenção registrado',
                ),
              )
            else
              ..._record.maintenanceAgents
                  .split('\n')
                  .where((item) => item.trim().isNotEmpty)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: CheckLine(text: item.trim()),
                    ),
                  ),
            const SizedBox(height: 4),
            AddButton(
              label: 'Editar manutenção',
              onTap: _editMaintenanceAgents,
            ),
          ],
        ),
      ),
    );
  }
}

class _AntibioticRedoseAlert {
  const _AntibioticRedoseAlert({
    required this.name,
    required this.message,
    required this.detail,
    required this.isOverdue,
  });

  final String name;
  final String message;
  final String detail;
  final bool isOverdue;
}

class HemodynamicDialog extends StatefulWidget {
  const HemodynamicDialog({
    super.key,
    required this.initialPoints,
    required this.initialMarkers,
  });

  final List<HemodynamicPoint> initialPoints;
  final List<HemodynamicMarker> initialMarkers;

  @override
  State<HemodynamicDialog> createState() => _HemodynamicDialogState();
}

class HemodynamicDialogResult {
  const HemodynamicDialogResult({
    required this.points,
    required this.markers,
  });

  final List<HemodynamicPoint> points;
  final List<HemodynamicMarker> markers;
}

class _HemodynamicDialogState extends State<HemodynamicDialog> {
  static const List<String> _types = ['PAS', 'PAD', 'FC', 'SpO2'];

  late List<HemodynamicPoint> _points;
  late List<HemodynamicMarker> _markers;
  late double _currentTime;
  late double _measurementTime;
  late String _selectedType;
  bool _removeMode = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _points = List<HemodynamicPoint>.from(widget.initialPoints)
      ..sort((a, b) => a.time.compareTo(b.time));
    _markers = List<HemodynamicMarker>.from(widget.initialMarkers)
      ..sort((a, b) => a.time.compareTo(b.time));
    _currentTime = _computeElapsedMinutes();
    _measurementTime = _currentTime;
    _selectedType = 'PAS';
    _startTickerIfNeeded();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  double get _maxTime {
    final double pointMax = _points.isEmpty
        ? 0
        : _points.map((item) => item.time).reduce((a, b) => a > b ? a : b);
    final double markerMax = _markers.isEmpty
        ? 0
        : _markers.map((item) => item.time).reduce((a, b) => a > b ? a : b);
    return pointMax > markerMax ? pointMax : markerMax;
  }

  HemodynamicMarker? get _anesthesiaStartMarker {
    try {
      return _markers.firstWhere((item) => item.label == 'Início da anestesia');
    } catch (_) {
      return null;
    }
  }

  HemodynamicMarker? get _surgeryStartMarker {
    try {
      return _markers.firstWhere((item) => item.label == 'Início da cirurgia');
    } catch (_) {
      return null;
    }
  }

  bool get _hasSurgeryEndMarker =>
      _markers.any((item) => item.label == 'Fim da cirurgia');

  bool get _hasAnesthesiaEndMarker =>
      _markers.any((item) => item.label == 'Fim da anestesia');

  DateTime? get _anesthesiaStartAt {
    final marker = _anesthesiaStartMarker;
    if (marker == null || marker.recordedAtIso.trim().isEmpty) return null;
    return DateTime.tryParse(marker.recordedAtIso);
  }

  void _startTickerIfNeeded() {
    _ticker?.cancel();
    if (_anesthesiaStartAt == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentTime = _computeElapsedMinutes();
        if (_points.isEmpty) {
          _measurementTime = _currentTime;
        }
      });
    });
  }

  double _computeElapsedMinutes() {
    final startedAt = _anesthesiaStartAt;
    if (startedAt == null) return _maxTime <= 0 ? 0 : _maxTime;
    final now = DateTime.now();
    final minutes = now.difference(startedAt).inSeconds / 60;
    return minutes < 0 ? 0 : minutes;
  }

  String _formatClock(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _addPointAtValue(double value) {
    setState(() {
      _points.add(
        HemodynamicPoint(
          type: _selectedType,
          value: value,
          time: _measurementTime,
        ),
      );
      _points.sort((a, b) => a.time.compareTo(b.time));
    });
  }

  void _undoLastPoint() {
    if (_points.isEmpty) return;
    setState(() {
      _points.removeLast();
    });
  }

  void _removePoint(HemodynamicPoint point) {
    setState(() {
      _points.remove(point);
    });
  }

  void _addMarker(String label) {
    final now = DateTime.now();
    setState(() {
      if (label == 'Início da anestesia') {
        _markers.removeWhere((item) => item.label == label);
        _markers.add(
          HemodynamicMarker(
            label: label,
            time: 0,
            clockTime: _formatClock(now),
            recordedAtIso: now.toIso8601String(),
          ),
        );
        _currentTime = 0;
        _measurementTime = 0;
      } else {
        _markers.removeWhere((item) => item.label == label);
        _markers.add(
          HemodynamicMarker(
            label: label,
            time: _measurementTime,
            clockTime: _formatClock(now),
            recordedAtIso: now.toIso8601String(),
          ),
        );
      }
      _markers.sort((a, b) => a.time.compareTo(b.time));
    });
    _startTickerIfNeeded();
  }

  String _formatTime(double time) {
    final totalSeconds = (time * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _captureMeasurementTime() {
    setState(() {
      _measurementTime = _currentTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lançamentos hemodinâmicos'),
      content: SizedBox(
        width: 820,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 440,
                child: HemodynamicChart(
                  points: _points,
                  markers: _markers,
                  selectedType: _selectedType,
                  onPointTap: _removeMode ? _removePoint : null,
                  onChartTap: _anesthesiaStartMarker == null
                      ? null
                      : _addPointAtValue,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _anesthesiaStartMarker == null
                              ? 'Início da anestesia ainda não registrado'
                              : 'Tempo decorrido: ${_formatTime(_currentTime)}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _anesthesiaStartMarker == null
                              ? 'Clique em "Início da anestesia" para começar o cronômetro.'
                              : 'Horário do início: ${_anesthesiaStartMarker!.clockTime}  •  Aferição atual: ${_formatTime(_measurementTime)}',
                          style: const TextStyle(
                            color: Color(0xFF5D7288),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_anesthesiaStartMarker != null) const SizedBox(height: 8),
                        if (_anesthesiaStartMarker != null)
                          OutlinedButton.icon(
                            onPressed: _captureMeasurementTime,
                            icon: const Icon(Icons.schedule),
                            label: const Text('Nova aferição neste tempo'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _types
                        .map(
                          (type) => ChoiceChip(
                            label: Text(type),
                            selected: _selectedType == type,
                            onSelected: (_) {
                              setState(() => _selectedType = type);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _anesthesiaStartMarker == null
                        ? () => _addMarker('Início da anestesia')
                        : null,
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Início da anestesia'),
                  ),
                  FilledButton.icon(
                    onPressed: _anesthesiaStartMarker == null
                            || _surgeryStartMarker != null
                        ? null
                        : () => _addMarker('Início da cirurgia'),
                    icon: const Icon(Icons.flag),
                    label: const Text('Início da cirurgia'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _surgeryStartMarker == null || _hasSurgeryEndMarker
                        ? null
                        : () => _addMarker('Fim da cirurgia'),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Fim da cirurgia'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        _anesthesiaStartMarker == null || _hasAnesthesiaEndMarker
                            ? null
                            : () => _addMarker('Fim da anestesia'),
                    icon: const Icon(Icons.stop_circle),
                    label: const Text('Fim da anestesia'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _points.isEmpty ? null : _undoLastPoint,
                    icon: const Icon(Icons.undo),
                    label: const Text('Desfazer'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _points.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _removeMode = !_removeMode;
                            });
                          },
                    icon: Icon(
                      _removeMode ? Icons.delete_forever : Icons.delete_outline,
                    ),
                    label: Text(
                      _removeMode ? 'Removendo pontos' : 'Remover ponto',
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _removeMode
                      ? 'Modo remoção ativo: clique em um ponto para apagá-lo.'
                      : 'Selecione PAS, PAD, FC ou SpO₂ e clique na altura desejada do gráfico. Os quatro parâmetros podem ser lançados na mesma aferição e no mesmo tempo.',
                  style: const TextStyle(
                    color: Color(0xFF7A8EA5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            HemodynamicDialogResult(points: _points, markers: _markers),
          ),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class VenousAccessDialog extends StatefulWidget {
  const VenousAccessDialog({
    super.key,
    required this.initialItems,
  });

  final List<String> initialItems;

  @override
  State<VenousAccessDialog> createState() => _VenousAccessDialogState();
}

class _VenousAccessDialogState extends State<VenousAccessDialog> {
  static const List<String> _avpSizes = ['24', '22', '20', '18', '16', '14'];
  static const List<String> _centralOptions = [
    'CVC SCD',
    'CVC SCE',
    'CVC JID',
    'CVC JIE',
    'CVC AXILAR D',
    'CVC AXILAR E',
    'CVC Femural D',
    'CVC Femural E',
  ];

  late List<String> _items;
  String _selectedAvpSize = '';
  String _selectedCentral = '';
  late final TextEditingController _avpSiteController;

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.initialItems);
    _avpSiteController = TextEditingController();
  }

  @override
  void dispose() {
    _avpSiteController.dispose();
    super.dispose();
  }

  void _addAvp() {
    final site = _avpSiteController.text.trim();
    if (site.isEmpty || _selectedAvpSize.isEmpty) return;
    setState(() {
      _items.add('AVP $site - ${_selectedAvpSize}G');
      _avpSiteController.clear();
      _selectedAvpSize = '';
    });
  }

  void _addCentral() {
    if (_selectedCentral.isEmpty) return;
    setState(() {
      _items.add(_selectedCentral);
      _selectedCentral = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9FBFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Editar Acesso venoso'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AVP',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _avpSiteController,
                decoration: const InputDecoration(
                  labelText: 'Local do acesso periférico',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _avpSizes
                    .map(
                      (size) => ChoiceChip(
                        label: Text(size),
                        selected: _selectedAvpSize == size,
                        onSelected: (_) {
                          setState(() => _selectedAvpSize = size);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _addAvp,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar AVP'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'CVC',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _centralOptions
                    .map(
                      (item) => ChoiceChip(
                        label: Text(item),
                        selected: _selectedCentral == item,
                        onSelected: (_) {
                          setState(() => _selectedCentral = item);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _addCentral,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar CVC'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Acessos lançados',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (_items.isEmpty)
                const Text(
                  'Nenhum acesso venoso lançado.',
                  style: TextStyle(color: Color(0xFF7A8EA5)),
                ),
              ..._items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCE7F3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              color: Color(0xFF17324D),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _items.removeAt(entry.key));
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_items),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class ArterialAccessDialog extends StatefulWidget {
  const ArterialAccessDialog({
    super.key,
    required this.initialItems,
  });

  final List<String> initialItems;

  @override
  State<ArterialAccessDialog> createState() => _ArterialAccessDialogState();
}

class _ArterialAccessDialogState extends State<ArterialAccessDialog> {
  late List<String> _items;
  bool _paiSelected = true;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.initialItems);
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _addArterialAccess() {
    final description = _descriptionController.text.trim();
    if (!_paiSelected || description.isEmpty) return;
    setState(() {
      _items.add('PAI - $description');
      _descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9FBFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Editar Acesso arterial'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChoiceChip(
                label: const Text('PAI'),
                selected: _paiSelected,
                onSelected: (_) {
                  setState(() => _paiSelected = true);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Dispositivo / local',
                  hintText: 'Ex: radial esquerda 20G',
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _addArterialAccess,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar PAI'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Acessos lançados',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (_items.isEmpty)
                const Text(
                  'Nenhum acesso arterial lançado.',
                  style: TextStyle(color: Color(0xFF7A8EA5)),
                ),
              ..._items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCE7F3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              color: Color(0xFF17324D),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _items.removeAt(entry.key));
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_items),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class FluidBalanceDialog extends StatefulWidget {
  const FluidBalanceDialog({
    super.key,
    required this.initialFluidBalance,
    required this.initialSurgicalSize,
    required this.initialFastingHours,
    required this.patientWeightKg,
    required this.patientHeightMeters,
    required this.patientPopulation,
    required this.patientAgeYears,
    required this.patientPostnatalAgeDays,
    required this.patientGestationalAgeWeeks,
    required this.patientBirthWeightKg,
  });

  final FluidBalance initialFluidBalance;
  final String initialSurgicalSize;
  final String initialFastingHours;
  final double patientWeightKg;
  final double patientHeightMeters;
  final PatientPopulation patientPopulation;
  final int patientAgeYears;
  final int patientPostnatalAgeDays;
  final int patientGestationalAgeWeeks;
  final double patientBirthWeightKg;

  @override
  State<FluidBalanceDialog> createState() => _FluidBalanceDialogState();
}

class _FluidBalanceDialogState extends State<FluidBalanceDialog> {
  static const List<String> _commonVolumes = [
    '0',
    '250',
    '500',
    '1000',
    '1500',
    '2000',
  ];
  static const List<String> _surgicalSizes = ['Pequeno', 'Medio', 'Grande'];
  static const List<_CrystalloidOption> _crystalloidOptions = [
    _CrystalloidOption('RL', 500),
    _CrystalloidOption('SF 0,9%', 500),
    _CrystalloidOption('Plasma-Lyte', 500),
    _CrystalloidOption('RL', 1000),
  ];
  static const List<_CrystalloidOption> _colloidOptions = [
    _CrystalloidOption('Albumina 5%', 100),
    _CrystalloidOption('Albumina 5%', 250),
    _CrystalloidOption('Albumina 20%', 100),
    _CrystalloidOption('Gelatina', 500),
  ];

  late final TextEditingController _crystalloidsController;
  late final TextEditingController _colloidsController;
  late final TextEditingController _bloodController;
  late final TextEditingController _fastingHoursController;
  late String _selectedSurgicalSize;
  late List<String> _crystalloidEntries;
  late List<String> _colloidEntries;

  @override
  void initState() {
    super.initState();
    _crystalloidsController = TextEditingController(
      text: widget.initialFluidBalance.crystalloids,
    )..addListener(_onChange);
    _colloidsController = TextEditingController(
      text: widget.initialFluidBalance.colloids,
    )..addListener(_onChange);
    _bloodController = TextEditingController(
      text: widget.initialFluidBalance.blood,
    )..addListener(_onChange);
    _fastingHoursController = TextEditingController(
      text: widget.initialFastingHours,
    )..addListener(_onChange);
    _selectedSurgicalSize = widget.initialSurgicalSize;
    _crystalloidEntries =
        List<String>.from(widget.initialFluidBalance.crystalloidEntries);
    _colloidEntries = List<String>.from(widget.initialFluidBalance.colloidEntries);
  }

  @override
  void dispose() {
    _crystalloidsController
      ..removeListener(_onChange)
      ..dispose();
    _colloidsController
      ..removeListener(_onChange)
      ..dispose();
    _bloodController
      ..removeListener(_onChange)
      ..dispose();
    _fastingHoursController
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  void _onChange() {
    setState(() {});
  }

  double _parse(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void _addToController(TextEditingController controller, double amount) {
    final current = _parse(controller.text);
    final next = current + amount;
    controller.text = next.toStringAsFixed(
      next.truncateToDouble() == next ? 0 : 1,
    );
  }

  void _addFluidEntry({
    required List<String> target,
    required TextEditingController controller,
    required String label,
    required int volumeMl,
  }) {
    setState(() {
      target.add('$label|$volumeMl');
      _addToController(controller, volumeMl.toDouble());
    });
  }

  void _removeFluidEntry({
    required List<String> target,
    required TextEditingController controller,
    required int index,
  }) {
    final entry = target[index].split('|');
    final volume = entry.length > 1 ? _parse(entry[1]) : 0;
    setState(() {
      target.removeAt(index);
      final current = _parse(controller.text);
      final next = (current - volume).clamp(0, double.infinity);
      controller.text = next.toStringAsFixed(
        next.truncateToDouble() == next ? 0 : 1,
      );
    });
  }

  double get _documentedLossesMl => widget.initialFluidBalance.diuresis.isEmpty &&
          widget.initialFluidBalance.bleeding.isEmpty &&
          widget.initialFluidBalance.spongeCount.isEmpty &&
          widget.initialFluidBalance.otherLosses.isEmpty
      ? 0
      : (double.tryParse(widget.initialFluidBalance.diuresis.replaceAll(',', '.')) ?? 0) +
          (double.tryParse(widget.initialFluidBalance.bleeding.replaceAll(',', '.')) ?? 0) +
          widget.initialFluidBalance.estimatedSpongeLoss +
          (double.tryParse(widget.initialFluidBalance.otherLosses.replaceAll(',', '.')) ?? 0);

  @override
  Widget build(BuildContext context) {
    final preview = FluidBalance(
      crystalloids: _crystalloidsController.text.trim(),
      colloids: _colloidsController.text.trim(),
      blood: _bloodController.text.trim(),
      diuresis: widget.initialFluidBalance.diuresis,
      bleeding: widget.initialFluidBalance.bleeding,
      spongeCount: widget.initialFluidBalance.spongeCount,
      otherLosses: widget.initialFluidBalance.otherLosses,
      crystalloidEntries: _crystalloidEntries,
      colloidEntries: _colloidEntries,
    );
    final recommendation = _buildFluidSupportRecommendation(
      patient: Patient(
        name: '',
        age: widget.patientAgeYears,
        weightKg: widget.patientWeightKg,
        heightMeters: widget.patientHeightMeters,
        asa: '',
        allergies: const [],
        restrictions: const [],
        medications: const [],
        population: widget.patientPopulation,
        postnatalAgeDays: widget.patientPostnatalAgeDays,
        gestationalAgeWeeks: widget.patientGestationalAgeWeeks,
        correctedGestationalAgeWeeks: 0,
        birthWeightKg: widget.patientBirthWeightKg,
      ),
      documentedLossesMl: _documentedLossesMl,
      fastingHoursText: _fastingHoursController.text.trim(),
    );

    return AlertDialog(
      backgroundColor: const Color(0xFFF9FBFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Editar Reposição volêmica / sangue e derivados'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Porte cirúrgico',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _surgicalSizes
                    .map(
                      (item) => ChoiceChip(
                        label: Text(item),
                        selected: _selectedSurgicalSize == item,
                        onSelected: (_) {
                          setState(() => _selectedSurgicalSize = item);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD9E6F7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: const TextStyle(
                        color: Color(0xFF365FD5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recommendation.lines.map(
                      (line) => Text(
                        line,
                        style: const TextStyle(
                          color: Color(0xFF5D7288),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _fastingHoursController.text.trim().isEmpty
                          ? 'Jejum não informado. Conduzir pela manutenção, perdas e hemodinâmica.'
                          : 'Jejum: ${_fastingHoursController.text.trim()} h • Porte: ${_selectedSurgicalSize.isEmpty ? "não definido" : _selectedSurgicalSize}',
                      style: const TextStyle(
                        color: Color(0xFF17324D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fastingHoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.><hH -]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Jejum',
                  suffixText: 'h',
                ),
              ),
              const SizedBox(height: 16),
              FluidField(
                key: const Key('fluid-crystalloids-field'),
                controller: _crystalloidsController,
                label: 'Cristaloides',
              ),
              const SizedBox(height: 8),
              _QuickVolumeChips(
                values: _commonVolumes,
                onSelected: (value) => _crystalloidsController.text = value,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Adicionar solução cristaloide',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _crystalloidOptions
                    .map(
                      (item) => ActionChip(
                        label: Text('${item.label} +${item.volumeMl} mL'),
                        onPressed: () => _addFluidEntry(
                          target: _crystalloidEntries,
                          controller: _crystalloidsController,
                          label: item.label,
                          volumeMl: item.volumeMl,
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (_crystalloidEntries.isNotEmpty) ...[
                const SizedBox(height: 10),
                _FluidEntryList(
                  entries: _crystalloidEntries,
                  onRemove: (index) => _removeFluidEntry(
                    target: _crystalloidEntries,
                    controller: _crystalloidsController,
                    index: index,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FluidField(
                controller: _colloidsController,
                label: 'Coloides',
              ),
              const SizedBox(height: 8),
              _QuickVolumeChips(
                values: _commonVolumes,
                onSelected: (value) => _colloidsController.text = value,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Adicionar colóide',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colloidOptions
                    .map(
                      (item) => ActionChip(
                        label: Text('${item.label} +${item.volumeMl} mL'),
                        onPressed: () => _addFluidEntry(
                          target: _colloidEntries,
                          controller: _colloidsController,
                          label: item.label,
                          volumeMl: item.volumeMl,
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (_colloidEntries.isNotEmpty) ...[
                const SizedBox(height: 10),
                _FluidEntryList(
                  entries: _colloidEntries,
                  onRemove: (index) => _removeFluidEntry(
                    target: _colloidEntries,
                    controller: _colloidsController,
                    index: index,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FluidField(
                key: const Key('fluid-blood-field'),
                controller: _bloodController,
                label: 'Sangue',
              ),
              const SizedBox(height: 8),
              _QuickVolumeChips(
                values: _commonVolumes,
                onSelected: (value) => _bloodController.text = value,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: KeyValueLine(
                  label: 'Balanço atual',
                  value: preview.formattedBalance,
                  labelColor: const Color(0xFF169653),
                  valueColor: const Color(0xFF169653),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('fluid-save-button'),
          onPressed: () {
            Navigator.of(context).pop(
              FluidBalanceDialogResult(
                fluidBalance: FluidBalance(
                  crystalloids: _crystalloidsController.text.trim(),
                  colloids: _colloidsController.text.trim(),
                  blood: _bloodController.text.trim(),
                  diuresis: widget.initialFluidBalance.diuresis,
                  bleeding: widget.initialFluidBalance.bleeding,
                  spongeCount: widget.initialFluidBalance.spongeCount,
                  otherLosses: widget.initialFluidBalance.otherLosses,
                  crystalloidEntries: _crystalloidEntries,
                  colloidEntries: _colloidEntries,
                ),
                surgicalSize: _selectedSurgicalSize,
                fastingHours: _fastingHoursController.text.trim(),
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class FluidField extends StatelessWidget {
  const FluidField({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'mL',
      ),
    );
  }
}

class FluidBalanceDialogResult {
  const FluidBalanceDialogResult({
    required this.fluidBalance,
    required this.surgicalSize,
    required this.fastingHours,
  });

  final FluidBalance fluidBalance;
  final String surgicalSize;
  final String fastingHours;
}

class BalanceOnlyDialog extends StatefulWidget {
  const BalanceOnlyDialog({
    super.key,
    required this.initialFluidBalance,
  });

  final FluidBalance initialFluidBalance;

  @override
  State<BalanceOnlyDialog> createState() => _BalanceOnlyDialogState();
}

class _BalanceOnlyDialogState extends State<BalanceOnlyDialog> {
  late final TextEditingController _diuresisController;
  late final TextEditingController _bleedingController;
  late final TextEditingController _spongeCountController;
  late final TextEditingController _otherLossesController;

  double _parse(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  double get _inputsMl =>
      _parse(widget.initialFluidBalance.crystalloids) +
      _parse(widget.initialFluidBalance.colloids) +
      _parse(widget.initialFluidBalance.blood);

  double get _estimatedSpongeLoss => _parse(_spongeCountController.text) * 100;

  double get _outputsMl =>
      _parse(_diuresisController.text) +
      _parse(_bleedingController.text) +
      _estimatedSpongeLoss +
      _parse(_otherLossesController.text);

  FluidBalance get _preview => widget.initialFluidBalance.copyWith(
        diuresis: _diuresisController.text.trim(),
        bleeding: _bleedingController.text.trim(),
        spongeCount: _spongeCountController.text.trim(),
        otherLosses: _otherLossesController.text.trim(),
      );

  @override
  void initState() {
    super.initState();
    _diuresisController =
        TextEditingController(text: widget.initialFluidBalance.diuresis)
          ..addListener(_onChange);
    _bleedingController =
        TextEditingController(text: widget.initialFluidBalance.bleeding)
          ..addListener(_onChange);
    _spongeCountController =
        TextEditingController(text: widget.initialFluidBalance.spongeCount)
          ..addListener(_onChange);
    _otherLossesController =
        TextEditingController(text: widget.initialFluidBalance.otherLosses)
          ..addListener(_onChange);
  }

  void _onChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _diuresisController
      ..removeListener(_onChange)
      ..dispose();
    _bleedingController
      ..removeListener(_onChange)
      ..dispose();
    _spongeCountController
      ..removeListener(_onChange)
      ..dispose();
    _otherLossesController
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9FBFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Editar Balanço hídrico'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD9E6F7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entradas já registradas',
                      style: TextStyle(
                        color: Color(0xFF365FD5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cristaloides: ${widget.initialFluidBalance.crystalloids.trim().isEmpty ? "--" : "${widget.initialFluidBalance.crystalloids} mL"}',
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Coloides: ${widget.initialFluidBalance.colloids.trim().isEmpty ? "--" : "${widget.initialFluidBalance.colloids} mL"}',
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Sangue / hemoderivados: ${widget.initialFluidBalance.blood.trim().isEmpty ? "--" : "${widget.initialFluidBalance.blood} mL"}',
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entradas totais: ${_inputsMl.toStringAsFixed(0)} mL',
                      style: const TextStyle(
                        color: Color(0xFF17324D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FluidField(
                key: const Key('fluid-diuresis-field'),
                controller: _diuresisController,
                label: 'Diurese',
              ),
              const SizedBox(height: 12),
              FluidField(
                key: const Key('fluid-bleeding-field'),
                controller: _bleedingController,
                label: 'Sangramento',
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('fluid-sponge-count-field'),
                controller: _spongeCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Compressas',
                  suffixText: 'un',
                  helperText: 'Estimativa média: 100 mL por compressa grande saturada',
                ),
              ),
              const SizedBox(height: 12),
              FluidField(
                key: const Key('fluid-other-losses-field'),
                controller: _otherLossesController,
                label: 'Outras perdas',
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    KeyValueLine(
                      label: 'Saídas totais',
                      value: '${_outputsMl.toStringAsFixed(0)} mL',
                      labelColor: const Color(0xFF169653),
                      valueColor: const Color(0xFF169653),
                    ),
                    const SizedBox(height: 8),
                    KeyValueLine(
                      label: 'Balanço atual',
                      value: _preview.formattedBalance,
                      labelColor: const Color(0xFF169653),
                      valueColor: const Color(0xFF169653),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('fluid-save-button'),
          onPressed: () => Navigator.of(context).pop(_preview),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _CrystalloidOption {
  const _CrystalloidOption(this.label, this.volumeMl);

  final String label;
  final int volumeMl;
}

class _QuickVolumeChips extends StatelessWidget {
  const _QuickVolumeChips({
    required this.values,
    required this.onSelected,
  });

  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => ActionChip(
              label: Text('$value mL'),
              onPressed: () => onSelected(value),
            ),
          )
          .toList(),
    );
  }
}

class _FluidEntryList extends StatelessWidget {
  const _FluidEntryList({
    required this.entries,
    required this.onRemove,
  });

  final List<String> entries;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0EAF3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entries[i].replaceAll('|', ' • '),
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(i),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ExportCaseDialog extends StatelessWidget {
  const _ExportCaseDialog({
    required this.onPreviewPressed,
    required this.onPrintPressed,
    required this.onSharePressed,
  });

  final Future<void> Function() onPreviewPressed;
  final Future<void> Function() onPrintPressed;
  final Future<void> Function() onSharePressed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportar ficha completa'),
      content: const Text(
        'O arquivo reúne a ficha de anestesia e, abaixo dela, o pré-anestésico completo.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await onPreviewPressed();
          },
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Visualizar'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await onPrintPressed();
          },
          icon: const Icon(Icons.print_outlined),
          label: const Text('Imprimir'),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await onSharePressed();
          },
          icon: const Icon(Icons.share_outlined),
          label: const Text('Compartilhar / salvar'),
        ),
      ],
    );
  }
}

class EditSectionScreen extends StatefulWidget {
  const EditSectionScreen({
    super.key,
    required this.title,
    required this.initialContent,
  });

  final String title;
  final String initialContent;

  @override
  State<EditSectionScreen> createState() => _EditSectionScreenState();
}

class _EditSectionScreenState extends State<EditSectionScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF17324D),
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Atualize as informações deste módulo da ficha.',
                style: TextStyle(
                  color: Color(0xFF6C8096),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: TextField(
                  controller: _controller,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Digite o conteúdo',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_controller.text.trim()),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
