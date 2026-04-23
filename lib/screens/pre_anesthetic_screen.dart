import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/patient.dart';
import '../models/pre_anesthetic_assessment.dart';

class PreAnestheticScreen extends StatefulWidget {
  const PreAnestheticScreen({
    super.key,
    required this.patient,
    required this.initialAssessment,
    required this.initialConsultationDate,
  });

  final Patient patient;
  final PreAnestheticAssessment initialAssessment;
  final String initialConsultationDate;

  @override
  State<PreAnestheticScreen> createState() => _PreAnestheticScreenState();
}

class _PreAnestheticScreenState extends State<PreAnestheticScreen> {
  static const List<String> _comorbiditiesOptions = [
    'HAS',
    'DM',
    'Cardiopatia',
    'Asma',
    'Pneumopatia',
    'DPOC',
    'Doença coronariana',
    'Insuficiência renal',
    'Apneia do sono',
    'Obesidade',
  ];
  static const List<String> _pediatricComorbidityOptions = [
    'Prematuridade',
    'Cardiopatia congênita',
    'IVAS recente',
    'Asma/broncoespasmo',
    'Apneia prévia',
    'Síndrome genética/craniofacial',
    'Epilepsia/doença neurológica',
    'Doença metabólica',
    'Alergia alimentar/medicamentosa',
  ];
  static const List<String> _neonatalComorbidityOptions = [
    'Prematuridade',
    'Cardiopatia congênita',
    'Apneia/bradicardia',
    'Suporte ventilatório recente',
    'Displasia broncopulmonar',
    'Sepse/infecção recente',
    'Icterícia importante',
    'Malformação congênita',
    'Enterocolite/cirurgia abdominal',
  ];
  static const List<String> _medicationOptions = [
    'AAS',
    'Clopidogrel',
    'Losartana',
    'Metformina',
    'Insulina',
    'Beta-bloqueador',
    'Anticoagulante',
    'Corticoide',
  ];
  static const List<String> _pediatricMedicationOptions = [
    'Broncodilatador',
    'Corticoide inalatório',
    'Anticonvulsivante',
    'Antibiótico recente',
    'Insulina',
    'Imunossupressor',
  ];
  static const List<String> _neonatalMedicationOptions = [
    'Cafeína',
    'Prostaglandina',
    'Diurético',
    'Anticonvulsivante',
    'Antibiótico',
    'Sedação/analgesia contínua',
  ];
  static const List<String> _smokingOptions = ['Não', 'Ex-tabagista', 'Sim'];
  static const List<String> _alcoholOptions = ['Não', 'Social', 'Frequente'];
  static const List<_OptionDetail> _metsOptions = [
    _OptionDetail('1 MET', 'Restrito a autocuidado'),
    _OptionDetail('2-3 METs', 'Caminha dentro de casa'),
    _OptionDetail('4 METs', 'Sobe 1 lance de escada'),
    _OptionDetail('>4 METs', 'Boa capacidade funcional'),
    _OptionDetail('>10 METs', 'Exercício vigoroso'),
  ];
  static const List<String> _pediatricSmokeExposureOptions = [
    'Não',
    'Eventual',
    'Importante',
  ];
  static const List<String> _pediatricRespiratoryStatusOptions = [
    'Sem sintomas',
    'IVAS recente',
    'Sintomático hoje',
  ];
  static const List<String> _neonatalRespiratorySupportOptions = [
    'Sem suporte',
    'Oxigênio recente',
    'CPAP/VM recente',
  ];
  static const List<String> _neonatalApneaOptions = [
    'Não',
    'Prévia',
    'Recente',
  ];
  static const List<_OptionDetail> _pediatricFunctionalOptions = [
    _OptionDetail(
      'Atividade preservada',
      'Brinca e acompanha a rotina habitual.',
    ),
    _OptionDetail('Limitação leve', 'Cansaço, tosse ou chiado aos esforços.'),
    _OptionDetail(
      'Limitação importante',
      'Dispneia, intolerância ou esforço reduzido.',
    ),
  ];
  static const List<_OptionDetail> _neonatalFunctionalOptions = [
    _OptionDetail(
      'Estável em ar ambiente',
      'Sem suporte atual e sem eventos recentes.',
    ),
    _OptionDetail(
      'Oxigênio recente',
      'Necessidade recente de oxigênio suplementar.',
    ),
    _OptionDetail('Apneia/bradicardia', 'Eventos recentes ou em investigação.'),
    _OptionDetail(
      'Suporte ventilatório',
      'CPAP ou ventilação mecânica recente.',
    ),
  ];
  static const List<String> _mallampatiOptions = ['I', 'II', 'III', 'IV'];
  static const List<_AsaReference> _asaReferences = [
    _AsaReference(
      grade: 'I',
      description:
          'Paciente saudavel, sem doenca sistemica clinicamente relevante.',
      examples:
          'Ex: adulto sem comorbidades ou crianca saudavel para cirurgia eletiva.',
    ),
    _AsaReference(
      grade: 'II',
      description: 'Doenca sistemica leve, sem limitacao funcional importante.',
      examples:
          'Ex: HAS controlada, obesidade leve, tabagismo, gestacao, asma leve.',
    ),
    _AsaReference(
      grade: 'III',
      description:
          'Doenca sistemica importante, com repercussao funcional ou clinica relevante.',
      examples:
          'Ex: DM descompensado, obesidade grave, DPOC, IRC dialitica, DAC estavel.',
    ),
    _AsaReference(
      grade: 'IV',
      description:
          'Doenca sistemica grave que representa ameaca constante a vida.',
      examples:
          'Ex: ICC descompensada, angina instavel, sepse, insuficiencia respiratoria.',
    ),
    _AsaReference(
      grade: 'V',
      description:
          'Paciente moribundo, sem expectativa de sobreviver sem a cirurgia.',
      examples:
          'Ex: ruptura de aneurisma, politrauma grave, choque refratario.',
    ),
    _AsaReference(
      grade: 'VI',
      description:
          'Paciente com morte encefalica mantido para doacao de orgaos.',
      examples: 'Usado em contexto de captacao de orgaos.',
    ),
  ];
  static const List<_AirwayReference> _mallampatiReferences = [
    _AirwayReference(
      grade: 'I',
      description: 'Palato mole, fauces, uvula e pilares visiveis.',
      technique: 'Laringoscopia direta usualmente adequada.',
    ),
    _AirwayReference(
      grade: 'II',
      description: 'Palato mole, fauces e parte da uvula visiveis.',
      technique:
          'Laringoscopia direta ou videolaringoscopio conforme contexto.',
    ),
    _AirwayReference(
      grade: 'III',
      description: 'Palato mole e base da uvula visiveis.',
      technique: 'Preferir videolaringoscopio e planejar via aerea dificil.',
    ),
    _AirwayReference(
      grade: 'IV',
      description: 'Somente palato duro visivel.',
      technique:
          'Videolaringoscopio/fibroscopia e estrategia de resgate pronta.',
    ),
  ];
  static const List<String> _mouthOpeningOptions = [
    '> 3 dedos (> 5 cm)',
    '2-3 dedos (3-5 cm)',
    '< 2 dedos (< 3 cm)',
  ];
  static const List<String> _pediatricMouthOpeningOptions = [
    'Adequada para a idade',
    'Reduzida',
    'Muito reduzida',
  ];
  static const List<String> _neonatalMouthOpeningOptions = [
    'Adequada',
    'Reduzida',
    'Muito reduzida',
  ];
  static const List<String> _neckMobilityOptions = [
    'Preservada',
    'Limitada',
    'Muito limitada',
  ];
  static const List<String> _dentitionOptions = [
    'Sem prótese',
    'Prótese móvel',
    'Dentição frágil',
    'Sem dentes',
  ];
  static const List<String> _pediatricDentitionOptions = [
    'Dentição decídua íntegra',
    'Dente móvel',
    'Dentição frágil',
    'Aparelho ortodôntico',
  ];
  static const List<String> _difficultAirwayPredictorOptions = [
    'Mallampati III/IV',
    'Abertura oral reduzida',
    'Mobilidade cervical limitada',
    'Distância tireomentoniana reduzida',
    'Micrognatia/retrognatia',
    'Pescoço curto',
    'Obesidade',
  ];
  static const List<String> _pediatricDifficultAirwayPredictorOptions = [
    'Micrognatia/retrognatia',
    'Macroglossia',
    'Hipertrofia adenotonsilar',
    'Síndrome craniofacial',
  ];
  static const List<String> _neonatalDifficultAirwayPredictorOptions = [
    'Micrognatia/retrognatia',
    'Macroglossia',
    'Malformação craniofacial',
    'Prematuridade',
  ];
  static const List<String> _difficultVentilationPredictorOptions = [
    'Barba',
    'Obesidade',
    'Sem dentes',
    'Apneia do sono',
    'Ronco importante',
    'Idade > 55 anos',
    'Limitação mandibular',
  ];
  static const List<String> _pediatricDifficultVentilationPredictorOptions = [
    'IVAS recente',
    'Secreção abundante',
    'Sibilância/broncoespasmo',
    'Hipertrofia adenotonsilar',
  ];
  static const List<String> _neonatalDifficultVentilationPredictorOptions = [
    'Apneia prévia',
    'Secreção abundante',
    'Suporte ventilatório recente',
    'Distensão abdominal importante',
  ];
  static const List<String> _complementaryExamOptions = [
    'ECG',
    'Hemograma',
    'Coagulograma',
    'Creatinina',
    'Glicemia',
    'Eletrólitos',
    'Rx tórax',
    'Ecocardiograma',
  ];
  static const List<String> _pediatricComplementaryExamOptions = [
    'Hemoglobina',
    'Gasometria',
    'Ecocardiograma',
  ];
  static const List<String> _neonatalComplementaryExamOptions = [
    'Hemoglobina',
    'Gasometria',
    'Glicemia',
    'Eletrólitos',
    'Ecocardiograma',
  ];
  static const List<String> _solidFastingOptions = ['<6h', '6-8h', '>8h'];
  static const List<String> _liquidFastingOptions = ['<2h', '2-4h', '>4h'];
  static const List<String> _breastMilkFastingOptions = ['<4h', '4-6h', '>6h'];
  static const List<String> _asaOptions = ['I', 'II', 'III', 'IV', 'V', 'VI'];
  static const List<String> _surgeryPriorityOptions = [
    'Eletiva',
    'Urgência',
    'Emergência',
  ];
  static const List<String> _anestheticPlanOptions = [
    'Anestesia geral balanceada',
    'Raquianestesia',
    'Peridural',
    'Bloqueio periférico',
    'Sedação',
  ];
  static const List<String> _pediatricAnestheticPlanOptions = [
    'Anestesia geral inalatória',
    'Anestesia geral venosa',
    'Máscara laríngea',
    'Intubação orotraqueal',
    'Bloqueio caudal/regional',
    'Analgesia multimodal',
  ];
  static const List<String> _neonatalAnestheticPlanOptions = [
    'Anestesia geral balanceada',
    'Intubação orotraqueal',
    'Ventilação controlada',
    'Analgesia opioide titulada',
    'Bloqueio regional selecionado',
    'Plano pós-operatório em UTI',
  ];
  static const List<String> _adultPostoperativePlanningOptions = [
    'Reserva de UTI',
    'Tipagem / pesquisa de anticorpos',
    'Prova cruzada / hemácias reservadas',
    'Hemocomponentes adicionais disponíveis',
    'Ventilação pós-operatória planejada',
    'Monitorização prolongada',
    'Dor aguda / PCA planejada',
  ];
  static const List<String> _pediatricPostoperativePlanningOptions = [
    'UTI pediátrica planejada',
    'Sangue compatibilizado disponível',
    'Observação respiratória prolongada',
    'Monitorização prolongada em RPA pediátrica',
    'Plano analgésico pediátrico',
    'Ventilação pós-operatória planejada',
  ];
  static const List<String> _neonatalPostoperativePlanningOptions = [
    'Reserva de UTI neonatal',
    'UCIN programada',
    'Hemocomponentes disponíveis',
    'Ventilação pós-operatória planejada',
    'Monitorização de apneia/bradicardia',
    'Termorregulação e transporte aquecido',
    'Glicemia seriada',
  ];
  static const List<String> _restrictionOptions = [
    'Não aceita transfusão',
    'Acompanhante obrigatório',
    'Recusa sedação',
    'Recusa opioide',
    'Recusa anestesia regional',
  ];
  static const List<String> _pediatricRestrictionOptions = [
    'Objeção familiar a hemocomponentes',
    'Acompanhante na indução',
    'Necessita consentimento do responsável',
    'Alergia ao látex',
    'História familiar de complicação anestésica',
  ];
  static const List<String> _neonatalRestrictionOptions = [
    'Objeção familiar a hemocomponentes',
    'Consentimento do responsável',
    'Necessita leito de UTI',
    'Necessita glicemia seriada',
    'Necessita termorregulação rigorosa',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _postnatalAgeController;
  late final TextEditingController _gestationalAgeController;
  late final TextEditingController _correctedGestationalAgeController;
  late final TextEditingController _birthWeightController;
  late final TextEditingController _allergyController;
  late final TextEditingController _metsNotesController;
  late final TextEditingController _physicalExamController;
  late final TextEditingController _acController;
  late final TextEditingController _fcController;
  late final TextEditingController _paController;
  late final TextEditingController _apController;
  late final TextEditingController _otherAirwayController;
  late final TextEditingController _otherDifficultAirwayPredictorsController;
  late final TextEditingController
  _otherDifficultVentilationPredictorsController;
  late final TextEditingController _otherComorbiditiesController;
  late final TextEditingController _otherMedicationsController;
  late final TextEditingController _otherHabitsController;
  late final TextEditingController _otherComplementaryExamsController;
  late final TextEditingController _fastingNotesController;
  late final TextEditingController _asaNotesController;
  late final TextEditingController _otherAnestheticPlanController;
  late final TextEditingController _otherPostoperativePlanningController;
  late final TextEditingController _freeNotesController;
  late final TextEditingController _otherRestrictionsController;
  late final TextEditingController _consultationDateController;

  late Set<String> _selectedComorbidities;
  late Set<String> _selectedMedications;
  late Set<String> _selectedExamItems;
  late Set<String> _selectedAnestheticPlans;
  late Set<String> _selectedPostoperativePlanningItems;
  late Set<String> _selectedRestrictions;
  late Set<String> _selectedDifficultAirwayPredictors;
  late Set<String> _selectedDifficultVentilationPredictors;
  String _smokingStatus = '';
  String _alcoholStatus = '';
  String _selectedMets = '';
  String _selectedMallampati = '';
  String _selectedMouthOpening = '';
  String _selectedNeckMobility = '';
  String _selectedDentition = '';
  String _selectedSolidFasting = '';
  String _selectedLiquidFasting = '';
  String _selectedBreastMilkFasting = '';
  String _selectedSurgeryPriority = '';
  String _selectedAsa = '';
  late PatientPopulation _selectedPopulation;

  String _defaultNowLabel() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String get _solidFastingLabel {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Sólidos / refeição leve',
      PatientPopulation.pediatric =>
        'Fórmula / leite não humano / refeição leve / sólidos',
      PatientPopulation.neonatal => 'Fórmula / leite não humano',
    };
  }

  String get _liquidFastingLabel {
    return switch (_selectedPopulation) {
      _ => 'Líquidos claros',
    };
  }

  bool get _showBreastMilkFastingSection =>
      _selectedPopulation != PatientPopulation.adult;

  String get _breastMilkFastingLabel => 'Leite materno';

  List<String> get _fastingGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Líquidos claros: até 2 h.',
          'Refeição leve: 6 h.',
          'Refeição gordurosa ou carne: 8 h ou mais.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Líquidos claros: até 2 h.',
          'Leite materno: 4 h.',
          'Fórmula infantil e leite não humano: 6 h.',
          'Criança maior: refeição leve ou sólidos leves 6 h; refeição gordurosa 8 h ou mais.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'RN estável em cirurgia eletiva: líquidos claros até 2 h.',
          'Leite materno: 4 h.',
          'Fórmula infantil ou leite não humano: 6 h.',
          'Prematuro, RN internado/UTI, com suporte ventilatório, distensão abdominal ou risco metabólico: individualizar o plano de jejum.',
        ];
    }
  }

  String? get _fastingReferenceText {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => null,
      PatientPopulation.pediatric =>
        'Base usada nesta tela: esquema conservador 2-4-6. Referências: ASA 2023 (PMID 36629465) e ESAIC 2022 (PMID 34857683). Alguns serviços pediátricos adotam 1 h para líquidos claros em casos eletivos conforme protocolo local.',
      PatientPopulation.neonatal =>
        'Base usada nesta tela: esquema conservador 2-4-6 para RN estáveis em contexto eletivo. As diretrizes ASA 2023 (PMID 36629465) se aplicam a pacientes saudáveis submetidos a procedimentos eletivos, e a ESAIC 2022 (PMID 34857683) traz recomendações pediátricas com regime mais liberal em cenários selecionados. Em prematuridade, internação/UTI, suporte ventilatório, sepse, distensão abdominal, risco metabólico ou urgência, individualizar conforme contexto clínico e protocolo institucional.',
    };
  }

  List<String> get _profileComorbidityOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _comorbiditiesOptions;
      case PatientPopulation.pediatric:
        return _pediatricComorbidityOptions;
      case PatientPopulation.neonatal:
        return _neonatalComorbidityOptions;
    }
  }

  List<String> get _allComorbidityOptions {
    return {
      ..._comorbiditiesOptions,
      ..._pediatricComorbidityOptions,
      ..._neonatalComorbidityOptions,
    }.toList();
  }

  List<String> get _profileMedicationOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _medicationOptions;
      case PatientPopulation.pediatric:
        return _pediatricMedicationOptions;
      case PatientPopulation.neonatal:
        return _neonatalMedicationOptions;
    }
  }

  List<String> get _allMedicationOptions {
    return {
      ..._medicationOptions,
      ..._pediatricMedicationOptions,
      ..._neonatalMedicationOptions,
    }.toList();
  }

  String get _medicationGuidanceTitle {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Revisão medicamentosa',
      PatientPopulation.pediatric => 'Foco pediátrico',
      PatientPopulation.neonatal => 'Foco neonatal',
    };
  }

  List<String> get _medicationGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Registrar antiagregantes, anticoagulantes, antidiabéticos, anti-hipertensivos e corticoides.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Rever broncodilatadores, corticoides inalatórios, anticonvulsivantes e medicações de uso contínuo.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Rever cafeína, prostaglandina, diuréticos, anticonvulsivantes e drogas em uso recente na UTI.',
        ];
    }
  }

  List<String> get _profileSmokingExposureOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _smokingOptions;
      case PatientPopulation.pediatric:
        return _pediatricSmokeExposureOptions;
      case PatientPopulation.neonatal:
        return _neonatalRespiratorySupportOptions;
    }
  }

  List<String> get _allSmokingExposureOptions {
    return {
      ..._smokingOptions,
      ..._pediatricSmokeExposureOptions,
      ..._neonatalRespiratorySupportOptions,
    }.toList();
  }

  List<String> get _profileSecondaryExposureOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _alcoholOptions;
      case PatientPopulation.pediatric:
        return _pediatricRespiratoryStatusOptions;
      case PatientPopulation.neonatal:
        return _neonatalApneaOptions;
    }
  }

  List<String> get _allSecondaryExposureOptions {
    return {
      ..._alcoholOptions,
      ..._pediatricRespiratoryStatusOptions,
      ..._neonatalApneaOptions,
    }.toList();
  }

  String get _contextSectionTitle {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Hábitos',
      PatientPopulation.pediatric => 'Exposição e sintomas recentes',
      PatientPopulation.neonatal => 'Contexto respiratório neonatal',
    };
  }

  String get _primaryExposureLabel {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Tabagismo',
      PatientPopulation.pediatric => 'Tabagismo passivo',
      PatientPopulation.neonatal => 'Suporte respiratório recente',
    };
  }

  String get _secondaryExposureLabel {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Álcool',
      PatientPopulation.pediatric => 'Sintomas respiratórios',
      PatientPopulation.neonatal => 'Apneia/bradicardia',
    };
  }

  String get _otherContextHint {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Ex: vape, drogas ilícitas, atividade física',
      PatientPopulation.pediatric =>
        'Ex: febre, tosse, chiado, internação recente, exposição domiciliar',
      PatientPopulation.neonatal =>
        'Ex: UTI neonatal, acesso venoso, intercorrências perinatais, jejum prolongado',
    };
  }

  List<_OptionDetail> get _profileFunctionalOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _metsOptions;
      case PatientPopulation.pediatric:
        return _pediatricFunctionalOptions;
      case PatientPopulation.neonatal:
        return _neonatalFunctionalOptions;
    }
  }

  List<String> get _allFunctionalValues {
    return {
      ..._metsOptions.map((item) => item.value),
      ..._pediatricFunctionalOptions.map((item) => item.value),
      ..._neonatalFunctionalOptions.map((item) => item.value),
    }.toList();
  }

  String get _functionalSectionTitle {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Avaliação funcional (METs)',
      PatientPopulation.pediatric => 'Reserva funcional pediátrica',
      PatientPopulation.neonatal => 'Reserva clínica neonatal',
    };
  }

  List<String> get _functionalGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Estime a capacidade funcional antes do procedimento e investigue limitação cardiovascular/respiratória.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Valorize brincadeira habitual, cansaço, chiado, tosse e tolerância às atividades do dia a dia.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Valorize estabilidade em ar ambiente, episódios de apneia/bradicardia e necessidade recente de suporte.',
        ];
    }
  }

  String get _functionalOtherHint {
    return switch (_selectedPopulation) {
      PatientPopulation.adult =>
        'Descreva limitação funcional, dispneia, angina',
      PatientPopulation.pediatric =>
        'Descreva cansaço, redução de brincadeiras, mamadas lentas ou pausas respiratórias',
      PatientPopulation.neonatal =>
        'Descreva apneias, dessaturações, necessidade de O2/CPAP e estabilidade térmica/hemodinâmica',
    };
  }

  List<String> get _profileComplementaryExamOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _complementaryExamOptions;
      case PatientPopulation.pediatric:
        return {
          'Hemograma',
          'Coagulograma',
          ..._pediatricComplementaryExamOptions,
          'Rx tórax',
        }.toList();
      case PatientPopulation.neonatal:
        return _neonatalComplementaryExamOptions;
    }
  }

  List<String> get _profileMouthOpeningOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _mouthOpeningOptions;
      case PatientPopulation.pediatric:
        return _pediatricMouthOpeningOptions;
      case PatientPopulation.neonatal:
        return _neonatalMouthOpeningOptions;
    }
  }

  List<String> get _allMouthOpeningOptions {
    return {
      ..._mouthOpeningOptions,
      ..._pediatricMouthOpeningOptions,
      ..._neonatalMouthOpeningOptions,
    }.toList();
  }

  List<String> get _profileNeckMobilityOptions {
    return _neckMobilityOptions;
  }

  List<String> get _profileDentitionOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _dentitionOptions;
      case PatientPopulation.pediatric:
        return _pediatricDentitionOptions;
      case PatientPopulation.neonatal:
        return const [];
    }
  }

  List<String> get _allDentitionOptions {
    return {..._dentitionOptions, ..._pediatricDentitionOptions}.toList();
  }

  List<String> get _allComplementaryExamOptions {
    return {
      ..._complementaryExamOptions,
      ..._pediatricComplementaryExamOptions,
      ..._neonatalComplementaryExamOptions,
    }.toList();
  }

  String get _examGuidanceTitle {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Exames complementares',
      PatientPopulation.pediatric => 'Exames por contexto clínico',
      PatientPopulation.neonatal => 'Exames por contexto neonatal',
    };
  }

  List<String> get _examGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Solicitar exames apenas se alterarem conduta perioperatória.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Em criança, exames não são rotineiros; considerar conforme doença de base, prematuridade e porte do procedimento.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'No neonato, priorizar glicemia, hemoglobina, gasometria, eletrólitos e ecocardiograma conforme quadro clínico.',
        ];
    }
  }

  List<String> get _profileDifficultAirwayPredictorOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _difficultAirwayPredictorOptions;
      case PatientPopulation.pediatric:
        return {
          'Abertura oral reduzida',
          'Mobilidade cervical limitada',
          'Micrognatia/retrognatia',
          'Macroglossia',
          'Hipertrofia adenotonsilar',
          'Síndrome craniofacial',
        }.toList();
      case PatientPopulation.neonatal:
        return {
          'Abertura oral reduzida',
          'Mobilidade cervical limitada',
          ..._neonatalDifficultAirwayPredictorOptions,
        }.toList();
    }
  }

  List<String> get _allDifficultAirwayPredictorOptions {
    return {
      ..._difficultAirwayPredictorOptions,
      ..._pediatricDifficultAirwayPredictorOptions,
      ..._neonatalDifficultAirwayPredictorOptions,
    }.toList();
  }

  List<String> get _profileDifficultVentilationPredictorOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _difficultVentilationPredictorOptions;
      case PatientPopulation.pediatric:
        return {
          ..._pediatricDifficultVentilationPredictorOptions,
          'Obesidade',
          'Limitação mandibular',
        }.toList();
      case PatientPopulation.neonatal:
        return _neonatalDifficultVentilationPredictorOptions;
    }
  }

  List<String> get _allDifficultVentilationPredictorOptions {
    return {
      ..._difficultVentilationPredictorOptions,
      ..._pediatricDifficultVentilationPredictorOptions,
      ..._neonatalDifficultVentilationPredictorOptions,
    }.toList();
  }

  String get _physicalExamSectionTitle {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Exame físico',
      PatientPopulation.pediatric => 'Exame clínico pediátrico',
      PatientPopulation.neonatal => 'Exame clínico neonatal',
    };
  }

  String get _acHint {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'RCR 2T, sem sopros',
      PatientPopulation.pediatric => 'Bulhas normofonéticas, sopros, perfusão',
      PatientPopulation.neonatal => 'Bulhas, sopro, pulsos, perfusão',
    };
  }

  String get _fcHint {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'bpm',
      PatientPopulation.pediatric => 'bpm para a faixa etária',
      PatientPopulation.neonatal => 'bpm neonatal',
    };
  }

  String get _paLabel {
    return switch (_selectedPopulation) {
      PatientPopulation.neonatal => 'Perfusão / PA',
      _ => 'PA',
    };
  }

  String get _paHint {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => '120/80 mmHg',
      PatientPopulation.pediatric => 'PA para a idade, enchimento capilar',
      PatientPopulation.neonatal => 'PA disponível, perfusão periférica, TEC',
    };
  }

  String get _apHint {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'MV presente, sem ruídos adventícios',
      PatientPopulation.pediatric => 'MV presente, sibilos, tosse, secreção',
      PatientPopulation.neonatal =>
        'Esforço respiratório, retrações, roncos, suporte',
    };
  }

  String get _physicalOtherHint {
    return switch (_selectedPopulation) {
      PatientPopulation.adult =>
        'Temperatura, perfusão, edema, estado geral e outros dados relevantes',
      PatientPopulation.pediatric =>
        'Estado geral, hidratação, febre, esforço respiratório e outros achados',
      PatientPopulation.neonatal =>
        'Tônus, perfusão, temperatura, glicemia, acessos e outros achados neonatais',
    };
  }

  List<String> get _airwayGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Documente preditores anatômicos e estratégia de resgate quando houver risco aumentado.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Valorize hipertrofia adenotonsilar, IVAS recente, síndromes craniofaciais e história de dificuldade prévia.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Valorize prematuridade, micrognatia, malformações craniofaciais, secreção e suporte ventilatório recente.',
        ];
    }
  }

  bool get _showMallampatiSection =>
      _selectedPopulation == PatientPopulation.adult;

  bool get _showMallampatiReferenceCards =>
      _selectedPopulation == PatientPopulation.adult;

  bool get _showDentitionSection =>
      _selectedPopulation != PatientPopulation.neonatal;

  String get _mouthOpeningLabel {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Abertura oral',
      PatientPopulation.pediatric => 'Abertura oral para a idade',
      PatientPopulation.neonatal => 'Abertura oral',
    };
  }

  String get _dentitionLabel {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Dentição / prótese',
      PatientPopulation.pediatric => 'Dentição',
      PatientPopulation.neonatal => 'Dentição',
    };
  }

  List<String> get _planGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Defina técnica principal, analgesia e condutas complementares.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Priorize via aérea planejada, estratégia de indução e analgesia regional quando indicada.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Priorize controle térmico, via aérea, ventilação, analgesia e destino pós-operatório.',
        ];
    }
  }

  List<String> get _profileAnestheticPlanOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _anestheticPlanOptions;
      case PatientPopulation.pediatric:
        return _pediatricAnestheticPlanOptions;
      case PatientPopulation.neonatal:
        return _neonatalAnestheticPlanOptions;
    }
  }

  List<String> get _profilePostoperativePlanningOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _adultPostoperativePlanningOptions;
      case PatientPopulation.pediatric:
        return _pediatricPostoperativePlanningOptions;
      case PatientPopulation.neonatal:
        return _neonatalPostoperativePlanningOptions;
    }
  }

  List<String> get _postoperativeGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Planeje leito crítico quando houver ventilação pós-operatória, instabilidade hemodinâmica esperada, grande porte ou risco elevado de sangramento.',
          'Tipagem, prova cruzada e hemocomponentes devem seguir risco do paciente/procedimento e protocolo local de hemoterapia, não reserva rotineira indiscriminada.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Planeje observação prolongada ou internação monitorizada em ex-prematuros, lactentes pequenos, OSA, cardiopatia, via aérea difícil ou uso relevante de opioides.',
          'Sangue compatibilizado e UTI pediátrica devem ser antecipados conforme risco hemorrágico, cirurgia e reserva fisiológica.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Ex-prematuros com idade pós-conceptual baixa, RN a termo com poucas semanas de vida, apneia prévia ou suporte respiratório recente exigem planejamento de monitorização ampliada.',
          'Defina previamente UTI/UCIN, termorregulação, glicemia, ventilação pós-operatória e disponibilidade de hemocomponentes quando o risco justificar.',
        ];
    }
  }

  String get _freeNotesHint {
    return switch (_selectedPopulation) {
      PatientPopulation.adult =>
        'Ex: paciente chegou hipertenso, cirurgia suspensa e motivo, necessidade de contato com hemoterapia',
      PatientPopulation.pediatric =>
        'Ex: criança chegou com tosse, responsável orientado, adiamento e motivo, intercorrência logística',
      PatientPopulation.neonatal =>
        'Ex: veio da UTI neonatal, em CPAP, atraso por incubadora, suspensão e motivo',
    };
  }

  List<String> get _allAnestheticPlanOptions {
    return {
      ..._anestheticPlanOptions,
      ..._pediatricAnestheticPlanOptions,
      ..._neonatalAnestheticPlanOptions,
    }.toList();
  }

  String get _restrictionSectionTitle {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Restrições do paciente',
      PatientPopulation.pediatric => 'Consentimento e cuidados especiais',
      PatientPopulation.neonatal => 'Consentimento e suporte necessário',
    };
  }

  List<String> get _profileRestrictionOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _restrictionOptions;
      case PatientPopulation.pediatric:
        return _pediatricRestrictionOptions;
      case PatientPopulation.neonatal:
        return _neonatalRestrictionOptions;
    }
  }

  List<String> get _allRestrictionOptions {
    return {
      ..._restrictionOptions,
      ..._pediatricRestrictionOptions,
      ..._neonatalRestrictionOptions,
    }.toList();
  }

  String get _restrictionHint {
    return switch (_selectedPopulation) {
      PatientPopulation.adult =>
        'Inclua recusas, crenças e preferências adicionais',
      PatientPopulation.pediatric =>
        'Inclua observações do responsável, jejum inadequado, intercorrências ou necessidade de preparo especial',
      PatientPopulation.neonatal =>
        'Inclua necessidades de incubadora, glicemia, termorregulação, sangue reservado ou suporte pós-operatório',
    };
  }

  List<String> get _restrictionGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Documente recusas e preferências do paciente capazes de modificar a conduta perioperatória.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Em pediatria, registre objeções familiares e necessidades especiais, mas a decisão terapêutica deve seguir o melhor interesse da criança.',
          'Se houver oposição do responsável a medida potencialmente necessária em situação de risco relevante, comunicar a direção técnica e a autoridade competente.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Em neonatologia, registre objeções familiares e necessidades de suporte, mas a condução deve priorizar proteção integral e melhor interesse do recém-nascido.',
          'Se houver conflito relevante entre responsável e equipe sobre medida potencialmente necessária, comunicar a direção técnica e a autoridade competente.',
        ];
    }
  }

  String _physicalExamField(String label, String source) {
    final match = RegExp(
      '^$label\\s*:\\s*(.+)\$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(source);
    return match?.group(1)?.trim() ?? '';
  }

  String _physicalExamOther(String source) {
    return source
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where(
          (line) => !RegExp(
            r'^(AC|FC|PA|AP)\s*:',
            caseSensitive: false,
          ).hasMatch(line),
        )
        .join('\n');
  }

  String _buildPhysicalExamSummary() {
    final parts = <String>[
      if (_acController.text.trim().isNotEmpty)
        'AC: ${_acController.text.trim()}',
      if (_fcController.text.trim().isNotEmpty)
        'FC: ${_fcController.text.trim()}',
      if (_paController.text.trim().isNotEmpty)
        'PA: ${_paController.text.trim()}',
      if (_apController.text.trim().isNotEmpty)
        'AP: ${_apController.text.trim()}',
      if (_physicalExamController.text.trim().isNotEmpty)
        _physicalExamController.text.trim(),
    ];
    return parts.join('\n');
  }

  void _syncMallampatiPredictor() {
    const predictor = 'Mallampati III/IV';
    if (_showMallampatiSection &&
        (_selectedMallampati == 'III' || _selectedMallampati == 'IV')) {
      _selectedDifficultAirwayPredictors.add(predictor);
    } else {
      _selectedDifficultAirwayPredictors.remove(predictor);
    }
  }

  void _syncMouthOpeningPredictor() {
    const predictor = 'Abertura oral reduzida';
    if (_selectedMouthOpening == '2-3 dedos (3-5 cm)' ||
        _selectedMouthOpening == '< 2 dedos (< 3 cm)' ||
        _selectedMouthOpening == 'Reduzida' ||
        _selectedMouthOpening == 'Muito reduzida') {
      _selectedDifficultAirwayPredictors.add(predictor);
    } else {
      _selectedDifficultAirwayPredictors.remove(predictor);
    }
  }

  void _syncNeckMobilityPredictor() {
    const predictor = 'Mobilidade cervical limitada';
    if (_selectedNeckMobility == 'Limitada' ||
        _selectedNeckMobility == 'Muito limitada') {
      _selectedDifficultAirwayPredictors.add(predictor);
    } else {
      _selectedDifficultAirwayPredictors.remove(predictor);
    }
  }

  void _syncAirwayPredictors() {
    _syncMallampatiPredictor();
    _syncMouthOpeningPredictor();
    _syncNeckMobilityPredictor();
  }

  String get _antecedentGuidanceTitle {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Foco do pré-anestésico',
      PatientPopulation.pediatric => 'Foco pediátrico',
      PatientPopulation.neonatal => 'Foco neonatal',
    };
  }

  List<String> get _antecedentGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Pesquisar comorbidades, medicações em uso, alergias e restrições.',
          'Exames complementares apenas quando alterarem a condução perioperatória.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Rever IVAS recente, asma/broncoespasmo, prematuridade e cardiopatia congênita.',
          'Valorizar história de complicações anestésicas e sintomas respiratórios atuais.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Rever prematuridade, episódios de apneia/bradicardia e necessidade recente de suporte respiratório.',
          'Valorizar cardiopatia congênita, idade gestacional e idade pós-natal.',
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    final assessment = widget.initialAssessment;
    _nameController = TextEditingController(text: widget.patient.name);
    _ageController = TextEditingController(
      text: widget.patient.age > 0 ? widget.patient.age.toString() : '',
    );
    _weightController = TextEditingController(
      text: widget.patient.weightKg > 0
          ? widget.patient.weightKg.toStringAsFixed(0)
          : '',
    );
    _heightController = TextEditingController(
      text: widget.patient.heightMeters > 0
          ? widget.patient.heightMeters.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _postnatalAgeController = TextEditingController(
      text: widget.patient.postnatalAgeDays > 0
          ? widget.patient.postnatalAgeDays.toString()
          : '',
    );
    _gestationalAgeController = TextEditingController(
      text: widget.patient.gestationalAgeWeeks > 0
          ? widget.patient.gestationalAgeWeeks.toString()
          : '',
    );
    _correctedGestationalAgeController = TextEditingController(
      text: widget.patient.correctedGestationalAgeWeeks > 0
          ? widget.patient.correctedGestationalAgeWeeks.toString()
          : '',
    );
    _birthWeightController = TextEditingController(
      text: widget.patient.birthWeightKg > 0
          ? widget.patient.birthWeightKg.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _allergyController = TextEditingController(
      text: assessment.allergyDescription,
    );
    _metsNotesController = TextEditingController();
    _acController = TextEditingController(
      text: _physicalExamField('AC', assessment.physicalExam),
    );
    _fcController = TextEditingController(
      text: _physicalExamField('FC', assessment.physicalExam),
    );
    _paController = TextEditingController(
      text: _physicalExamField('PA', assessment.physicalExam),
    );
    _apController = TextEditingController(
      text: _physicalExamField('AP', assessment.physicalExam),
    );
    _physicalExamController = TextEditingController(
      text: _physicalExamOther(assessment.physicalExam),
    );
    _otherAirwayController = TextEditingController(
      text: assessment.otherAirwayDetails,
    );
    _otherDifficultAirwayPredictorsController = TextEditingController(
      text: assessment.otherDifficultAirwayPredictors,
    );
    _otherDifficultVentilationPredictorsController = TextEditingController(
      text: assessment.otherDifficultVentilationPredictors,
    );
    _otherComorbiditiesController = TextEditingController(
      text: assessment.otherComorbidities,
    );
    _otherMedicationsController = TextEditingController(
      text: assessment.otherMedications,
    );
    _otherHabitsController = TextEditingController(
      text: assessment.otherHabits,
    );
    _otherComplementaryExamsController = TextEditingController(
      text: assessment.otherComplementaryExams,
    );
    _fastingNotesController = TextEditingController(
      text: assessment.fastingNotes,
    );
    _asaNotesController = TextEditingController(text: assessment.asaNotes);
    _otherAnestheticPlanController = TextEditingController(
      text: assessment.otherAnestheticPlan,
    );
    _otherPostoperativePlanningController = TextEditingController(
      text: assessment.otherPostoperativePlanning,
    );
    _freeNotesController = TextEditingController(
      text: assessment.planningNotes,
    );
    _otherRestrictionsController = TextEditingController(
      text: assessment.otherRestrictions,
    );
    _consultationDateController = TextEditingController(
      text: widget.initialConsultationDate.trim().isEmpty
          ? _defaultNowLabel()
          : widget.initialConsultationDate,
    );

    _selectedComorbidities = assessment.comorbidities
        .where(_allComorbidityOptions.contains)
        .toSet();
    _selectedMedications = assessment.currentMedications
        .where(_allMedicationOptions.contains)
        .toSet();
    _selectedExamItems = assessment.complementaryExamItems
        .where(_allComplementaryExamOptions.contains)
        .toSet();
    _selectedAnestheticPlans = assessment.anestheticPlan
        .split('\n')
        .map((item) => item.trim())
        .where(_allAnestheticPlanOptions.contains)
        .toSet();
    _selectedPostoperativePlanningItems = assessment.postoperativePlanningItems
        .where(
          (item) => {
            ..._adultPostoperativePlanningOptions,
            ..._pediatricPostoperativePlanningOptions,
            ..._neonatalPostoperativePlanningOptions,
          }.contains(item),
        )
        .toSet();
    _selectedRestrictions = assessment.restrictionItems
        .where(_allRestrictionOptions.contains)
        .toSet();
    _selectedDifficultAirwayPredictors = assessment.difficultAirwayPredictors
        .where(_allDifficultAirwayPredictorOptions.contains)
        .toSet();
    _selectedDifficultVentilationPredictors = assessment
        .difficultVentilationPredictors
        .where(_allDifficultVentilationPredictorOptions.contains)
        .toSet();
    _smokingStatus =
        _allSmokingExposureOptions.contains(assessment.smokingStatus)
        ? assessment.smokingStatus
        : '';
    _alcoholStatus =
        _allSecondaryExposureOptions.contains(assessment.alcoholStatus)
        ? assessment.alcoholStatus
        : '';
    _selectedMets = _allFunctionalValues.contains(assessment.mets)
        ? assessment.mets
        : '';
    _selectedMallampati =
        _mallampatiOptions.contains(assessment.airway.mallampati)
        ? assessment.airway.mallampati
        : '';
    _selectedMouthOpening =
        _allMouthOpeningOptions.contains(assessment.mouthOpening)
        ? assessment.mouthOpening
        : '';
    _selectedNeckMobility =
        _neckMobilityOptions.contains(assessment.neckMobility)
        ? assessment.neckMobility
        : '';
    _selectedDentition = _allDentitionOptions.contains(assessment.dentition)
        ? assessment.dentition
        : '';
    _selectedSolidFasting =
        _solidFastingOptions.contains(assessment.fastingSolids)
        ? assessment.fastingSolids
        : '';
    _selectedLiquidFasting =
        _liquidFastingOptions.contains(assessment.fastingLiquids)
        ? assessment.fastingLiquids
        : '';
    _selectedBreastMilkFasting =
        _breastMilkFastingOptions.contains(assessment.fastingBreastMilk)
        ? assessment.fastingBreastMilk
        : '';
    _selectedSurgeryPriority =
        _surgeryPriorityOptions.contains(assessment.surgeryPriority)
        ? assessment.surgeryPriority
        : '';
    _selectedAsa = _asaOptions.contains(assessment.asaClassification)
        ? assessment.asaClassification
        : widget.patient.asa;
    _selectedPopulation = widget.patient.population;
    _syncAirwayPredictors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _postnatalAgeController.dispose();
    _gestationalAgeController.dispose();
    _correctedGestationalAgeController.dispose();
    _birthWeightController.dispose();
    _allergyController.dispose();
    _metsNotesController.dispose();
    _physicalExamController.dispose();
    _acController.dispose();
    _fcController.dispose();
    _paController.dispose();
    _apController.dispose();
    _otherAirwayController.dispose();
    _otherDifficultAirwayPredictorsController.dispose();
    _otherDifficultVentilationPredictorsController.dispose();
    _otherComorbiditiesController.dispose();
    _otherMedicationsController.dispose();
    _otherHabitsController.dispose();
    _otherComplementaryExamsController.dispose();
    _fastingNotesController.dispose();
    _asaNotesController.dispose();
    _otherAnestheticPlanController.dispose();
    _otherPostoperativePlanningController.dispose();
    _freeNotesController.dispose();
    _otherRestrictionsController.dispose();
    _consultationDateController.dispose();
    super.dispose();
  }

  List<String> _lines(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF17324D),
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildFilterChips({
    required List<String> options,
    required Set<String> selectedValues,
    required ValueChanged<String> onToggle,
    Color color = const Color(0xFF2B76D2),
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = selectedValues.contains(option);
        return FilterChip(
          label: Text(option),
          selected: selected,
          onSelected: (_) => onToggle(option),
          selectedColor: color.withAlpha(36),
          checkmarkColor: color,
          side: BorderSide(color: selected ? color : const Color(0xFFD6E1ED)),
          labelStyle: TextStyle(
            color: selected ? color : const Color(0xFF4F6378),
            fontWeight: FontWeight.w700,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChoiceChips({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
    Color color = const Color(0xFF169653),
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = selectedValue == option;
        return ChoiceChip(
          label: Text(option),
          selected: selected,
          onSelected: (_) => onSelected(option),
          selectedColor: color.withAlpha(32),
          side: BorderSide(color: selected ? color : const Color(0xFFD6E1ED)),
          labelStyle: TextStyle(
            color: selected ? color : const Color(0xFF4F6378),
            fontWeight: FontWeight.w700,
          ),
        );
      }).toList(),
    );
  }

  void _saveAndReturn() {
    _syncAirwayPredictors();
    final medications = [
      ..._selectedMedications,
      ..._lines(_otherMedicationsController.text),
    ];
    final anestheticPlanLines = [
      ..._selectedAnestheticPlans,
      ..._lines(_otherAnestheticPlanController.text),
    ];
    final restrictionLines = [
      ..._selectedRestrictions,
      ..._lines(_otherRestrictionsController.text),
    ];
    final complementaryExamLines = [
      ..._selectedExamItems,
      ..._lines(_otherComplementaryExamsController.text),
    ];
    final metsValue = _selectedMets.isEmpty
        ? _metsNotesController.text.trim()
        : _selectedMets;

    final updatedPatient = widget.patient.copyWith(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()) ?? widget.patient.age,
      weightKg:
          double.tryParse(_weightController.text.replaceAll(',', '.')) ??
          widget.patient.weightKg,
      heightMeters:
          double.tryParse(_heightController.text.replaceAll(',', '.')) ??
          widget.patient.heightMeters,
      population: _selectedPopulation,
      postnatalAgeDays:
          int.tryParse(_postnatalAgeController.text.trim()) ??
          widget.patient.postnatalAgeDays,
      gestationalAgeWeeks:
          int.tryParse(_gestationalAgeController.text.trim()) ??
          widget.patient.gestationalAgeWeeks,
      correctedGestationalAgeWeeks:
          int.tryParse(_correctedGestationalAgeController.text.trim()) ??
          widget.patient.correctedGestationalAgeWeeks,
      birthWeightKg:
          double.tryParse(_birthWeightController.text.replaceAll(',', '.')) ??
          widget.patient.birthWeightKg,
      asa: _selectedAsa,
      allergies: _allergyController.text.trim().isEmpty
          ? const []
          : [_allergyController.text.trim()],
      restrictions: restrictionLines,
      medications: medications,
    );

    final updatedAssessment = widget.initialAssessment.copyWith(
      comorbidities: _selectedComorbidities.toList(),
      otherComorbidities: _otherComorbiditiesController.text.trim(),
      currentMedications: medications,
      otherMedications: _otherMedicationsController.text.trim(),
      allergyDescription: _allergyController.text.trim(),
      smokingStatus: _smokingStatus,
      alcoholStatus: _alcoholStatus,
      otherHabits: _otherHabitsController.text.trim(),
      mets: metsValue,
      physicalExam: _buildPhysicalExamSummary(),
      airway: widget.initialAssessment.airway.copyWith(
        mallampati: _showMallampatiSection ? _selectedMallampati : '',
      ),
      mouthOpening: _selectedMouthOpening,
      neckMobility: _selectedNeckMobility,
      dentition: _selectedDentition,
      difficultAirwayPredictors: _selectedDifficultAirwayPredictors.toList(),
      otherDifficultAirwayPredictors: _otherDifficultAirwayPredictorsController
          .text
          .trim(),
      difficultVentilationPredictors: _selectedDifficultVentilationPredictors
          .toList(),
      otherDifficultVentilationPredictors:
          _otherDifficultVentilationPredictorsController.text.trim(),
      otherAirwayDetails: _otherAirwayController.text.trim(),
      complementaryExamItems: _selectedExamItems.toList(),
      complementaryExams: complementaryExamLines.join('\n'),
      otherComplementaryExams: _otherComplementaryExamsController.text.trim(),
      fastingSolids: _selectedSolidFasting,
      fastingLiquids: _selectedLiquidFasting,
      fastingBreastMilk: _showBreastMilkFastingSection
          ? _selectedBreastMilkFasting
          : '',
      fastingNotes: _fastingNotesController.text.trim(),
      surgeryPriority: _selectedSurgeryPriority,
      asaClassification: _selectedAsa,
      asaNotes: _asaNotesController.text.trim(),
      anestheticPlan: anestheticPlanLines.join('\n'),
      otherAnestheticPlan: _otherAnestheticPlanController.text.trim(),
      postoperativePlanningItems: _selectedPostoperativePlanningItems.toList(),
      otherPostoperativePlanning: _otherPostoperativePlanningController.text
          .trim(),
      planningNotes: _freeNotesController.text.trim(),
      restrictionItems: _selectedRestrictions.toList(),
      patientRestrictions: restrictionLines.join('\n'),
      otherRestrictions: _otherRestrictionsController.text.trim(),
    );

    Navigator.of(context).pop(
      PreAnestheticScreenResult(
        patient: updatedPatient,
        assessment: updatedAssessment,
        consultationDate: _consultationDateController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consulta Pré-Anestésica')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Identificação do paciente',
            initiallyExpanded: true,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PatientPopulation.values
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item.label),
                            selected: _selectedPopulation == item,
                            onSelected: (_) {
                              setState(() {
                                _selectedPopulation = item;
                                _selectedPostoperativePlanningItems.removeWhere(
                                  (value) =>
                                      !_profilePostoperativePlanningOptions
                                          .contains(value),
                                );
                                if (!_showMallampatiSection) {
                                  _selectedMallampati = '';
                                }
                                _syncAirwayPredictors();
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _consultationDateController,
                  decoration: const InputDecoration(
                    labelText: 'Data da consulta pré-anestésica',
                    hintText: 'dd/mm/aaaa hh:mm',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText:
                              _selectedPopulation == PatientPopulation.neonatal
                              ? 'Idade (anos, se aplicável)'
                              : 'Idade (anos)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Altura (m)',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedPopulation != PatientPopulation.adult) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _postnatalAgeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Idade pós-natal (dias)',
                          ),
                        ),
                      ),
                      if (_selectedPopulation ==
                          PatientPopulation.neonatal) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _birthWeightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9,.]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Peso ao nascer (kg)',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (_selectedPopulation == PatientPopulation.neonatal) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _gestationalAgeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'IG ao nascer (semanas)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _correctedGestationalAgeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'IG corrigida (semanas)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _SectionCard(
            title: 'Antecedentes',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5ECF6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _antecedentGuidanceTitle,
                        style: const TextStyle(
                          color: Color(0xFF2B76D2),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._antecedentGuidanceLines.map(
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
                const SizedBox(height: 14),
                _buildFilterChips(
                  options: _profileComorbidityOptions,
                  selectedValues: _selectedComorbidities,
                  color: const Color(0xFFCC7A00),
                  onToggle: (value) {
                    setState(() {
                      if (_selectedComorbidities.contains(value)) {
                        _selectedComorbidities.remove(value);
                      } else {
                        _selectedComorbidities.add(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _otherComorbiditiesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Outros',
                    hintText: 'Descreva antecedentes não listados',
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Medicações em uso',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5ECF6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _medicationGuidanceTitle,
                        style: const TextStyle(
                          color: Color(0xFF2B76D2),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._medicationGuidanceLines.map(
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
                const SizedBox(height: 14),
                _buildFilterChips(
                  options: _profileMedicationOptions,
                  selectedValues: _selectedMedications,
                  onToggle: (value) {
                    setState(() {
                      if (_selectedMedications.contains(value)) {
                        _selectedMedications.remove(value);
                      } else {
                        _selectedMedications.add(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _otherMedicationsController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Outros',
                    hintText:
                        'Inclua dose, frequência e medicações não listadas',
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Alergias',
            child: TextField(
              controller: _allergyController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descrição das alergias',
              ),
            ),
          ),
          _SectionCard(
            title: _contextSectionTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(_primaryExposureLabel),
                const SizedBox(height: 8),
                _buildChoiceChips(
                  options: _profileSmokingExposureOptions,
                  selectedValue: _smokingStatus,
                  onSelected: (value) => setState(() => _smokingStatus = value),
                ),
                const SizedBox(height: 14),
                _sectionLabel(_secondaryExposureLabel),
                const SizedBox(height: 8),
                _buildChoiceChips(
                  options: _profileSecondaryExposureOptions,
                  selectedValue: _alcoholStatus,
                  onSelected: (value) => setState(() => _alcoholStatus = value),
                  color: const Color(0xFF8A5DD3),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _otherHabitsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Outros',
                    hintText: _otherContextHint,
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: _functionalSectionTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5ECF6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _functionalSectionTitle,
                        style: const TextStyle(
                          color: Color(0xFF2B76D2),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._functionalGuidanceLines.map(
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
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _profileFunctionalOptions.map((option) {
                    final selected = _selectedMets == option.value;
                    return ChoiceChip(
                      label: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(option.value),
                          Text(
                            option.description,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedMets = option.value;
                        });
                      },
                      selectedColor: const Color(0xFF2B76D2).withAlpha(28),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF2B76D2)
                            : const Color(0xFFD6E1ED),
                      ),
                      labelStyle: TextStyle(
                        color: selected
                            ? const Color(0xFF2B76D2)
                            : const Color(0xFF4F6378),
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _metsNotesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Outros',
                    hintText: _functionalOtherHint,
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: _physicalExamSectionTitle,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _acController,
                        decoration: InputDecoration(
                          labelText: 'AC',
                          hintText: _acHint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _fcController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'FC',
                          hintText: _fcHint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _paController,
                        decoration: InputDecoration(
                          labelText: _paLabel,
                          hintText: _paHint,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apController,
                  decoration: InputDecoration(
                    labelText: 'AP',
                    hintText: _apHint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _physicalExamController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Outros achados',
                    hintText: _physicalOtherHint,
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Avaliação de via aérea',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5ECF6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _airwayGuidanceLines
                        .map(
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
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                if (_showMallampatiSection) ...[
                  _sectionLabel('Mallampati'),
                  const SizedBox(height: 8),
                  _buildChoiceChips(
                    options: _mallampatiOptions,
                    selectedValue: _selectedMallampati,
                    onSelected: (value) {
                      setState(() {
                        _selectedMallampati = value;
                        _syncAirwayPredictors();
                      });
                    },
                    color: const Color(0xFF8A5DD3),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_showMallampatiReferenceCards) ...[
                  const Text(
                    'Referencia rapida de Mallampati (classe e significado)',
                    style: TextStyle(
                      color: Color(0xFF17324D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._mallampatiReferences.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AirwayReferenceCard(reference: item),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _sectionLabel(_mouthOpeningLabel),
                const SizedBox(height: 8),
                _buildChoiceChips(
                  options: _profileMouthOpeningOptions,
                  selectedValue: _selectedMouthOpening,
                  onSelected: (value) {
                    setState(() {
                      _selectedMouthOpening = value;
                      _syncAirwayPredictors();
                    });
                  },
                  color: const Color(0xFF2B76D2),
                ),
                const SizedBox(height: 14),
                _sectionLabel('Mobilidade cervical'),
                const SizedBox(height: 8),
                _buildChoiceChips(
                  options: _profileNeckMobilityOptions,
                  selectedValue: _selectedNeckMobility,
                  onSelected: (value) {
                    setState(() {
                      _selectedNeckMobility = value;
                      _syncAirwayPredictors();
                    });
                  },
                  color: const Color(0xFF169653),
                ),
                if (_showDentitionSection) ...[
                  const SizedBox(height: 14),
                  _sectionLabel(_dentitionLabel),
                  const SizedBox(height: 8),
                  _buildChoiceChips(
                    options: _profileDentitionOptions,
                    selectedValue: _selectedDentition,
                    onSelected: (value) {
                      setState(() => _selectedDentition = value);
                    },
                    color: const Color(0xFFCC7A00),
                  ),
                ],
                const SizedBox(height: 14),
                _sectionLabel('Preditores de via aérea difícil'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5ECF6)),
                  ),
                  child: Text(
                    _selectedPopulation == PatientPopulation.adult
                        ? 'Referência rápida: distância tireomentoniana menor que 6 cm sugere maior risco de laringoscopia/intubação difícil.'
                        : _selectedPopulation == PatientPopulation.pediatric
                        ? 'Referência rápida pediátrica: valorize síndromes craniofaciais, hipertrofia adenotonsilar, limitação de abertura oral e história de dificuldade prévia.'
                        : 'Referência rápida neonatal: valorize micrognatia, macroglossia, malformações craniofaciais, secreção e suporte ventilatório recente.',
                    style: const TextStyle(
                      color: Color(0xFF5D7288),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildFilterChips(
                  options: _profileDifficultAirwayPredictorOptions,
                  selectedValues: _selectedDifficultAirwayPredictors,
                  color: const Color(0xFFEA5455),
                  onToggle: (value) {
                    setState(() {
                      if (_selectedDifficultAirwayPredictors.contains(value)) {
                        _selectedDifficultAirwayPredictors.remove(value);
                      } else {
                        _selectedDifficultAirwayPredictors.add(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _otherDifficultAirwayPredictorsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Outros - via aérea difícil',
                    hintText: 'Descreva outros preditores relevantes',
                  ),
                ),
                const SizedBox(height: 14),
                _sectionLabel('Preditores de ventilação difícil'),
                const SizedBox(height: 8),
                _buildFilterChips(
                  options: _profileDifficultVentilationPredictorOptions,
                  selectedValues: _selectedDifficultVentilationPredictors,
                  color: const Color(0xFFCC7A00),
                  onToggle: (value) {
                    setState(() {
                      if (_selectedDifficultVentilationPredictors.contains(
                        value,
                      )) {
                        _selectedDifficultVentilationPredictors.remove(value);
                      } else {
                        _selectedDifficultVentilationPredictors.add(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _otherDifficultVentilationPredictorsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Outros - ventilação difícil',
                    hintText: 'Descreva outros preditores relevantes',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _otherAirwayController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Outros',
                    hintText: _selectedPopulation == PatientPopulation.adult
                        ? 'Ex: barba, limitação mandibular, pescoço curto'
                        : _selectedPopulation == PatientPopulation.pediatric
                        ? 'Ex: laringomalácia, estenose subglótica, intubação difícil prévia'
                        : 'Ex: via aérea difícil prévia, anomalia craniofacial, necessidade de fibroscopia',
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Exames complementares',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5ECF6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _examGuidanceTitle,
                        style: const TextStyle(
                          color: Color(0xFF2B76D2),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._examGuidanceLines.map(
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
                const SizedBox(height: 14),
                _buildFilterChips(
                  options: _profileComplementaryExamOptions,
                  selectedValues: _selectedExamItems,
                  color: const Color(0xFF2B76D2),
                  onToggle: (value) {
                    setState(() {
                      if (_selectedExamItems.contains(value)) {
                        _selectedExamItems.remove(value);
                      } else {
                        _selectedExamItems.add(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _otherComplementaryExamsController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Outros',
                    hintText:
                        'Descreva alterações relevantes ou exames adicionais',
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Jejum',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5ECF6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referência rápida de jejum',
                        style: const TextStyle(
                          color: Color(0xFF2B76D2),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._fastingGuidanceLines.map(
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
                      if (_fastingReferenceText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _fastingReferenceText!,
                          style: const TextStyle(
                            color: Color(0xFF5F7288),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sectionLabel('$_solidFastingLabel (horas)'),
                const SizedBox(height: 8),
                _buildChoiceChips(
                  options: _solidFastingOptions,
                  selectedValue: _selectedSolidFasting,
                  onSelected: (value) {
                    setState(() => _selectedSolidFasting = value);
                  },
                  color: const Color(0xFFCC7A00),
                ),
                const SizedBox(height: 14),
                _sectionLabel('$_liquidFastingLabel (horas)'),
                const SizedBox(height: 8),
                _buildChoiceChips(
                  options: _liquidFastingOptions,
                  selectedValue: _selectedLiquidFasting,
                  onSelected: (value) {
                    setState(() => _selectedLiquidFasting = value);
                  },
                ),
                if (_showBreastMilkFastingSection) ...[
                  const SizedBox(height: 14),
                  _sectionLabel('$_breastMilkFastingLabel (horas)'),
                  const SizedBox(height: 8),
                  _buildChoiceChips(
                    options: _breastMilkFastingOptions,
                    selectedValue: _selectedBreastMilkFasting,
                    onSelected: (value) {
                      setState(() => _selectedBreastMilkFasting = value);
                    },
                    color: const Color(0xFF169653),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _fastingNotesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Observações do jejum',
                    hintText: _selectedPopulation == PatientPopulation.adult
                        ? 'Ex: jejum inadequado, horário da última refeição'
                        : _selectedPopulation == PatientPopulation.pediatric
                        ? 'Ex: discriminar se foi leite materno, fórmula ou refeição sólida conforme a idade'
                        : 'Ex: horário da última mamada, fórmula, glicemia, risco de hipoglicemia',
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Classificação do caso',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChoiceChips(
                  options: _surgeryPriorityOptions,
                  selectedValue: _selectedSurgeryPriority,
                  onSelected: (value) {
                    setState(() => _selectedSurgeryPriority = value);
                  },
                  color: const Color(0xFFCC3D3D),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _freeNotesController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Anotações livres do caso',
                    hintText: _freeNotesHint,
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Classificação ASA',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChoiceChips(
                  options: _asaOptions,
                  selectedValue: _selectedAsa,
                  onSelected: (value) => setState(() => _selectedAsa = value),
                  color: const Color(0xFFCC3D3D),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Referencia rapida de ASA (classe e significado)',
                  style: TextStyle(
                    color: Color(0xFF17324D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ..._asaReferences.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AsaReferenceCard(reference: item),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Use o sufixo E em urgencia/emergencia quando aplicavel.',
                  style: TextStyle(
                    color: Color(0xFF5D7288),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _asaNotesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Outros',
                    hintText:
                        'Justifique a classificação ASA quando necessário',
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Plano anestésico',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5ECF6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _planGuidanceLines
                        .map(
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
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFilterChips(
                  options: _profileAnestheticPlanOptions,
                  selectedValues: _selectedAnestheticPlans,
                  color: const Color(0xFF8A5DD3),
                  onToggle: (value) {
                    setState(() {
                      if (_selectedAnestheticPlans.contains(value)) {
                        _selectedAnestheticPlans.remove(value);
                      } else {
                        _selectedAnestheticPlans.add(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _otherAnestheticPlanController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Outros',
                    hintText:
                        'Detalhe analgesia, bloqueios e condutas adicionais',
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Planejamento pós-operatório e logística',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5ECF6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _postoperativeGuidanceLines
                        .map(
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
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFilterChips(
                  options: _profilePostoperativePlanningOptions,
                  selectedValues: _selectedPostoperativePlanningItems,
                  color: const Color(0xFF169653),
                  onToggle: (value) {
                    setState(() {
                      if (_selectedPostoperativePlanningItems.contains(value)) {
                        _selectedPostoperativePlanningItems.remove(value);
                      } else {
                        _selectedPostoperativePlanningItems.add(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _otherPostoperativePlanningController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Outros',
                    hintText:
                        'Detalhe reserva de leito, hemoterapia, ventilação, transporte ou observações logísticas',
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: _restrictionSectionTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5ECF6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _restrictionGuidanceLines
                        .map(
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
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFilterChips(
                  options: _profileRestrictionOptions,
                  selectedValues: _selectedRestrictions,
                  color: const Color(0xFFCC3D3D),
                  onToggle: (value) {
                    setState(() {
                      if (_selectedRestrictions.contains(value)) {
                        _selectedRestrictions.remove(value);
                      } else {
                        _selectedRestrictions.add(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _otherRestrictionsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Outros',
                    hintText: _restrictionHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saveAndReturn,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar e enviar para ficha de anestesia'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17324D),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/gabs_logo.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GABS',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Grupo de Anestesiologistas da Baixada Santista',
                style: TextStyle(
                  color: Color(0xFF5F7288),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _selectedPopulation == PatientPopulation.adult
                    ? 'Consulta pré-anestésica do adulto'
                    : _selectedPopulation == PatientPopulation.pediatric
                    ? 'Consulta pré-anestésica pediátrica'
                    : 'Consulta pré-anestésica neonatal',
                style: const TextStyle(
                  color: Color(0xFF5F7288),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        children: [child],
      ),
    );
  }
}

class PreAnestheticScreenResult {
  const PreAnestheticScreenResult({
    required this.patient,
    required this.assessment,
    required this.consultationDate,
  });

  final Patient patient;
  final PreAnestheticAssessment assessment;
  final String consultationDate;
}

class _AirwayReferenceCard extends StatelessWidget {
  const _AirwayReferenceCard({required this.reference});

  final _AirwayReference reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5ECF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8A5DD3).withAlpha(22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Mallampati ${reference.grade}',
                  style: TextStyle(
                    color: const Color(0xFF8A5DD3),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reference.description,
            style: const TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tecnica sugerida: ${reference.technique}',
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AsaReferenceCard extends StatelessWidget {
  const _AsaReferenceCard({required this.reference});

  final _AsaReference reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1D3D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFCC3D3D).withAlpha(18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ASA ${reference.grade}',
                  style: const TextStyle(
                    color: Color(0xFFCC3D3D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reference.description,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reference.examples,
            style: const TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionDetail {
  const _OptionDetail(this.value, this.description);

  final String value;
  final String description;
}

class _AirwayReference {
  const _AirwayReference({
    required this.grade,
    required this.description,
    required this.technique,
  });

  final String grade;
  final String description;
  final String technique;
}

class _AsaReference {
  const _AsaReference({
    required this.grade,
    required this.description,
    required this.examples,
  });

  final String grade;
  final String description;
  final String examples;
}
