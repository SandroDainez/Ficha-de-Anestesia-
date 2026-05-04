import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/patient.dart';
import '../models/pre_anesthetic_assessment.dart';
import '../widgets/anesthesia_basic_dialogs.dart';
import '../widgets/surgery_info_dialog.dart';

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

class _MedicationOptionGroup {
  const _MedicationOptionGroup({required this.title, required this.options});

  final String title;
  final List<String> options;
}

class _OrientationOptionGroup {
  const _OrientationOptionGroup({
    required this.title,
    required this.options,
    this.freeTextField,
  });

  final String title;
  final List<String> options;
  final _OrientationFreeTextField? freeTextField;
}

class _OrientationFreeTextField {
  const _OrientationFreeTextField({
    required this.label,
    required this.hintText,
    required this.prefix,
  });

  final String label;
  final String hintText;
  final String prefix;
}

class _PreAnestheticScreenState extends State<PreAnestheticScreen> {
  static const Color _completedSelectionColor = Color(0xFF169653);
  static const Color _suspendedSelectionColor = Color(0xFFD2473F);

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
    'Apneia do sono',
    'Síndrome genética/craniofacial',
    'Epilepsia/doença neurológica',
    'Doença metabólica',
    'Obesidade',
  ];
  static const List<String> _neonatalComorbidityOptions = [
    'Prematuridade',
    'Cardiopatia congênita',
    'Apneia/bradicardia',
    'Suporte ventilatório recente',
    'Displasia broncopulmonar',
    'Sepse/infecção recente',
    'Anemia',
    'Malformação congênita',
    'Enterocolite necrosante / cirurgia abdominal',
  ];
  static const List<String> _medicationOptions = [
    'Metformina (antidiabético)',
    'Insulina (antidiabético)',
    'Glibenclamida (antidiabético)',
    'AAS (antiagregante)',
    'Clopidogrel (antiagregante)',
    'Varfarina (anticoagulante)',
    'Rivaroxabana (anticoagulante)',
    'Apixabana (anticoagulante)',
    'Atenolol (betabloqueador)',
    'Metoprolol (betabloqueador)',
    'Propranolol (betabloqueador)',
    'Salbutamol (broncodilatador)',
    'Formoterol (broncodilatador)',
    'Ipratrópio (broncodilatador)',
    'Prednisona (corticoide)',
    'Dexametasona (corticoide)',
    'Furosemida (diurético)',
    'Hidroclorotiazida (diurético)',
    'Captopril (IECA)',
    'Enalapril (IECA)',
    'Losartana (ARB)',
  ];
  static const List<_MedicationOptionGroup> _medicationOptionGroups = [
    _MedicationOptionGroup(
      title: 'Antidiabéticos',
      options: [
        'Metformina (antidiabético)',
        'Insulina (antidiabético)',
        'Glibenclamida (antidiabético)',
      ],
    ),
    _MedicationOptionGroup(
      title: 'Antiagregantes plaquetários',
      options: ['AAS (antiagregante)', 'Clopidogrel (antiagregante)'],
    ),
    _MedicationOptionGroup(
      title: 'Anticoagulantes',
      options: [
        'Varfarina (anticoagulante)',
        'Rivaroxabana (anticoagulante)',
        'Apixabana (anticoagulante)',
      ],
    ),
    _MedicationOptionGroup(
      title: 'Betabloqueadores',
      options: [
        'Atenolol (betabloqueador)',
        'Metoprolol (betabloqueador)',
        'Propranolol (betabloqueador)',
      ],
    ),
    _MedicationOptionGroup(
      title: 'Broncodilatadores',
      options: [
        'Salbutamol (broncodilatador)',
        'Formoterol (broncodilatador)',
        'Ipratrópio (broncodilatador)',
      ],
    ),
    _MedicationOptionGroup(
      title: 'Corticoides',
      options: ['Prednisona (corticoide)', 'Dexametasona (corticoide)'],
    ),
    _MedicationOptionGroup(
      title: 'Diuréticos',
      options: ['Furosemida (diurético)', 'Hidroclorotiazida (diurético)'],
    ),
    _MedicationOptionGroup(
      title: 'IECA / ARB',
      options: ['Captopril (IECA)', 'Enalapril (IECA)', 'Losartana (ARB)'],
    ),
  ];
  static const List<String> _pediatricMedicationOptions = [
    'Amoxicilina (antibiótico em uso)',
    'Cefalexina (antibiótico em uso)',
    'Azitromicina (antibiótico em uso)',
    'Valproato (anticonvulsivante)',
    'Levetiracetam (anticonvulsivante)',
    'Fenobarbital (anticonvulsivante)',
    'Salbutamol (broncodilatador)',
    'Ipratrópio (broncodilatador)',
    'Budesonida (corticoide inalatório)',
    'Fluticasona (corticoide inalatório)',
    'Insulina regular',
    'Insulina NPH',
    'Tacrolimo (imunossupressor)',
    'Ciclosporina (imunossupressor)',
    'Metotrexato (imunossupressor)',
  ];
  static const List<_MedicationOptionGroup> _pediatricMedicationOptionGroups = [
    _MedicationOptionGroup(
      title: 'Antibióticos em uso',
      options: [
        'Amoxicilina (antibiótico em uso)',
        'Cefalexina (antibiótico em uso)',
        'Azitromicina (antibiótico em uso)',
      ],
    ),
    _MedicationOptionGroup(
      title: 'Anticonvulsivantes',
      options: [
        'Valproato (anticonvulsivante)',
        'Levetiracetam (anticonvulsivante)',
        'Fenobarbital (anticonvulsivante)',
      ],
    ),
    _MedicationOptionGroup(
      title: 'Broncodilatadores',
      options: ['Salbutamol (broncodilatador)', 'Ipratrópio (broncodilatador)'],
    ),
    _MedicationOptionGroup(
      title: 'Corticoides inalatórios',
      options: [
        'Budesonida (corticoide inalatório)',
        'Fluticasona (corticoide inalatório)',
      ],
    ),
    _MedicationOptionGroup(
      title: 'Insulinas',
      options: ['Insulina regular', 'Insulina NPH'],
    ),
    _MedicationOptionGroup(
      title: 'Imunossupressores',
      options: [
        'Tacrolimo (imunossupressor)',
        'Ciclosporina (imunossupressor)',
        'Metotrexato (imunossupressor)',
      ],
    ),
  ];
  static const List<String> _neonatalMedicationOptions = [
    'Ampicilina (antibiótico)',
    'Gentamicina (antibiótico)',
    'Amicacina (antibiótico)',
    'Fenobarbital (anticonvulsivante)',
    'Levetiracetam (anticonvulsivante)',
    'Midazolam (anticonvulsivante)',
    'Furosemida (diurético)',
    'Cafeína',
    'Fentanil (sedação/analgesia contínua)',
    'Midazolam (sedação/analgesia contínua)',
    'Dobutamina (vasoativo)',
    'Dopamina (vasoativo)',
    'Adrenalina (vasoativo)',
  ];
  static const List<_MedicationOptionGroup> _neonatalMedicationOptionGroups = [
    _MedicationOptionGroup(
      title: 'Antibióticos',
      options: [
        'Ampicilina (antibiótico)',
        'Gentamicina (antibiótico)',
        'Amicacina (antibiótico)',
      ],
    ),
    _MedicationOptionGroup(
      title: 'Anticonvulsivantes',
      options: [
        'Fenobarbital (anticonvulsivante)',
        'Levetiracetam (anticonvulsivante)',
        'Midazolam (anticonvulsivante)',
      ],
    ),
    _MedicationOptionGroup(
      title: 'Diuréticos',
      options: ['Furosemida (diurético)'],
    ),
    _MedicationOptionGroup(
      title: 'Estimulante respiratório',
      options: ['Cafeína'],
    ),
    _MedicationOptionGroup(
      title: 'Sedação / analgesia contínua',
      options: [
        'Fentanil (sedação/analgesia contínua)',
        'Midazolam (sedação/analgesia contínua)',
      ],
    ),
    _MedicationOptionGroup(
      title: 'Vasoativos',
      options: [
        'Dobutamina (vasoativo)',
        'Dopamina (vasoativo)',
        'Adrenalina (vasoativo)',
      ],
    ),
  ];
  static const List<String> _adultAgePresetOptions = [
    '18',
    '30',
    '50',
    '70',
    '80',
  ];
  static const List<String> _pediatricAgePresetOptions = [
    '1',
    '3',
    '5',
    '8',
    '12',
  ];
  static const List<String> _neonatalAgePresetOptions = [
    '1',
    '3',
    '7',
    '14',
    '28',
  ];
  static const List<String> _adultWeightPresetOptions = [
    '50',
    '60',
    '70',
    '80',
    '90',
    '100',
  ];
  static const List<String> _pediatricWeightPresetOptions = [
    '10',
    '15',
    '20',
    '25',
    '30',
  ];
  static const List<String> _neonatalWeightPresetOptions = [
    '1,0',
    '1,5',
    '2,0',
    '2,5',
    '3,0',
  ];
  static const List<String> _adultHeightPresetOptions = [
    '150',
    '160',
    '170',
    '180',
    '190',
  ];
  static const List<String> _pediatricHeightPresetOptions = [
    '70',
    '90',
    '110',
    '130',
    '150',
  ];
  static const List<String> _neonatalHeightPresetOptions = [
    '35',
    '40',
    '45',
    '50',
    '55',
  ];
  static const List<String> _neonatalBirthWeightPresetOptions = [
    '0,8',
    '1,0',
    '1,5',
    '2,0',
    '2,5',
    '3,0',
  ];
  static const List<String> _gestationalAgePresetOptions = [
    '28',
    '30',
    '32',
    '34',
    '36',
    '38',
    '40',
  ];
  static const List<String> _correctedGestationalAgePresetOptions = [
    '30',
    '32',
    '34',
    '36',
    '38',
    '40',
  ];
  static const List<String> _adultAcPresetOptions = [
    'Rítmico',
    'Arrítmico',
    'Bulhas normofonéticas',
    'Sopro',
  ];
  static const List<String> _pediatricAcPresetOptions = [
    'Rítmico',
    'Arrítmico',
    'Bulhas normofonéticas',
  ];
  static const List<String> _neonatalAcPresetOptions = ['Rítmico', 'Arrítmico'];
  static const List<String> _adultFcPresetOptions = [
    '60 bpm',
    '80 bpm',
    '100 bpm',
    '120 bpm',
  ];
  static const List<String> _pediatricFcPresetOptions = [
    '100 bpm',
    '120 bpm',
    '140 bpm',
    '160 bpm',
  ];
  static const List<String> _neonatalFcPresetOptions = [
    '120 bpm',
    '140 bpm',
    '160 bpm',
    '180 bpm',
  ];
  static const List<String> _adultPasPresetOptions = [
    '100 mmHg',
    '120 mmHg',
    '140 mmHg',
    '160 mmHg',
  ];
  static const List<String> _pediatricPasPresetOptions = [
    '80 mmHg',
    '90 mmHg',
    '100 mmHg',
    '110 mmHg',
  ];
  static const List<String> _neonatalPasPresetOptions = [
    '50 mmHg',
    '60 mmHg',
    '70 mmHg',
    '80 mmHg',
  ];
  static const List<String> _adultPadPresetOptions = [
    '60 mmHg',
    '70 mmHg',
    '80 mmHg',
    '90 mmHg',
  ];
  static const List<String> _pediatricPadPresetOptions = [
    '40 mmHg',
    '50 mmHg',
    '60 mmHg',
    '70 mmHg',
  ];
  static const List<String> _neonatalPadPresetOptions = [
    '30 mmHg',
    '35 mmHg',
    '40 mmHg',
    '50 mmHg',
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
  static const Set<String> _intubationPredictorSet = {
    'Mallampati III/IV',
    'Abertura oral reduzida',
    'Mobilidade cervical limitada',
    'Distância tireomentoniana reduzida',
    'Micrognatia/retrognatia',
    'Macroglossia',
    'Pescoço curto',
    'Obesidade',
    'Limitação mandibular',
    'Hipertrofia adenotonsilar',
    'Síndrome craniofacial',
    'Malformação craniofacial',
    'Prematuridade',
  };
  static const Set<String> _ventilationPredictorSet = {
    'Barba',
    'Obesidade',
    'Sem dentes',
    'Apneia do sono',
    'Ronco importante',
    'Idade > 55 anos',
    'Limitação mandibular',
    'IVAS recente',
    'Secreção abundante',
    'Sibilância/broncoespasmo',
    'Hipertrofia adenotonsilar',
    'Apneia prévia',
    'Suporte ventilatório recente',
    'Distensão abdominal importante',
    'Macroglossia',
  };
  static const Set<String> _structuredAirwayAssessmentFindings = {
    'Mallampati III/IV',
    'Abertura oral reduzida',
    'Mobilidade cervical limitada',
    'Sem dentes',
  };
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
  static const List<String> _solidFastingOptions = ['6 horas', '8 horas'];
  static const List<String> _liquidFastingOptions = ['2 horas'];
  static const List<String> _breastMilkFastingOptions = ['4 horas'];
  static const List<String> _asaOptions = ['I', 'II', 'III', 'IV', 'V', 'VI'];
  static const List<String> _surgeryPriorityOptions = [
    'Eletiva',
    'Urgência',
    'Emergência',
  ];
  static const List<String> _anestheticPlanOptions = [
    'Anestesia geral',
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
    'Anestesia geral',
    'Intubação orotraqueal',
    'Ventilação controlada',
    'Analgesia opioide titulada',
    'Bloqueio regional selecionado',
    'Plano pós-operatório em UTI',
  ];
  static const List<String> _adultPostoperativePlanningOptions = [
    'UTI',
    'Sangue',
    'UTI + sangue',
    'Ventilação pós-operatória',
    'Monitorização prolongada',
  ];
  static const List<String> _pediatricPostoperativePlanningOptions = [
    'UTI pediátrica',
    'Sangue compatibilizado',
    'Ventilação pós-operatória',
    'Monitorização prolongada',
    'Observação respiratória',
  ];
  static const List<String> _neonatalPostoperativePlanningOptions = [
    'UTI neonatal',
    'UCIN',
    'Sangue compatibilizado',
    'Ventilação pós-operatória',
    'Monitorização de apneia/bradicardia',
  ];
  static const List<String> _preAnestheticOrientationOptions = [
    'Manter medicações de uso contínuo; suspender somente as que foram orientadas',
    'Suspender clopidogrel 5-7 dias se liberado pela equipe assistente',
    'Manter AAS quando alto risco trombótico ou prevenção secundária',
    'Suspender varfarina 5 dias e checar INR conforme protocolo',
    'Suspender DOAC 24-72h conforme função renal e risco de sangramento',
    'Avaliar ponte anticoagulante em alto risco trombótico',
    'Trazer lista de medicações',
    'Trazer exames / laudos',
    'Cumprir jejum recomendado',
    'Confirmar acompanhante / contato',
  ];
  static const List<_OrientationOptionGroup> _preAnestheticOrientationGroups = [
    _OrientationOptionGroup(
      title: 'Medicações a manter',
      options: [
        'Manter medicações de uso contínuo; suspender somente as que foram orientadas',
      ],
    ),
    _OrientationOptionGroup(
      title: 'Suspender',
      options: [],
      freeTextField: _OrientationFreeTextField(
        label: 'Medicações a suspender',
        hintText: 'Digite uma medicação por linha',
        prefix: 'Suspender medicação: ',
      ),
    ),
    _OrientationOptionGroup(
      title: 'Anticoagulantes / antiagregantes',
      options: [
        'Suspender clopidogrel 5-7 dias se liberado pela equipe assistente',
        'Manter AAS quando alto risco trombótico ou prevenção secundária',
        'Suspender varfarina 5 dias e checar INR conforme protocolo',
        'Suspender DOAC 24-72h conforme função renal e risco de sangramento',
        'Avaliar ponte anticoagulante em alto risco trombótico',
      ],
      freeTextField: _OrientationFreeTextField(
        label: 'Outros anticoagulantes / antiagregantes',
        hintText: 'Ex: dabigatrana, edoxabana, ticagrelor, prasugrel...',
        prefix: 'Anticoagulante/antiagregante: ',
      ),
    ),
    _OrientationOptionGroup(
      title: 'Documentos e exames',
      options: ['Trazer lista de medicações', 'Trazer exames / laudos'],
    ),
    _OrientationOptionGroup(
      title: 'Jejum e logística',
      options: [
        'Cumprir jejum recomendado',
        'Confirmar acompanhante / contato',
      ],
    ),
    _OrientationOptionGroup(
      title: 'Outras informações',
      options: [],
      freeTextField: _OrientationFreeTextField(
        label: 'Informações adicionais',
        hintText: 'Digite informações adicionais relevantes',
        prefix: 'Informação adicional: ',
      ),
    ),
  ];
  static const List<String> _pediatricPreAnestheticOrientationOptions = [
    'Manter anticonvulsivantes',
    'Manter broncodilatadores e corticoides inalatórios',
    'Manter corticoide crônico e avaliar dose de estresse',
    'Suspender anticoagulantes / antiagregantes conforme equipe assistente',
    'Ajustar insulina conforme glicemia e jejum',
    'Trazer lista de medicações',
    'Trazer exames / laudos',
    'Cumprir jejum recomendado',
    'Avisar febre / IVAS / sintomas respiratórios',
    'Confirmar acompanhante / contato',
    'Orientar responsável / consentimento',
  ];
  static const List<_OrientationOptionGroup>
  _pediatricPreAnestheticOrientationGroups = [
    _OrientationOptionGroup(
      title: 'Medicações pediátricas',
      options: [
        'Manter anticonvulsivantes',
        'Manter broncodilatadores e corticoides inalatórios',
        'Manter corticoide crônico e avaliar dose de estresse',
        'Suspender anticoagulantes / antiagregantes conforme equipe assistente',
        'Ajustar insulina conforme glicemia e jejum',
      ],
      freeTextField: _OrientationFreeTextField(
        label: 'Outras medicações pediátricas',
        hintText: 'Ex: medicação de uso contínuo, antibiótico em curso...',
        prefix: 'Medicação pediátrica: ',
      ),
    ),
    _OrientationOptionGroup(
      title: 'Documentos e exames',
      options: ['Trazer lista de medicações', 'Trazer exames / laudos'],
    ),
    _OrientationOptionGroup(
      title: 'Jejum e responsável',
      options: [
        'Cumprir jejum recomendado',
        'Confirmar acompanhante / contato',
        'Orientar responsável / consentimento',
      ],
    ),
    _OrientationOptionGroup(
      title: 'Avisos e recontato',
      options: ['Avisar febre / IVAS / sintomas respiratórios'],
      freeTextField: _OrientationFreeTextField(
        label: 'Outras orientações pediátricas',
        hintText: 'Ex: orientar responsável, reavaliar sintomas, logística...',
        prefix: 'Orientação pediátrica: ',
      ),
    ),
  ];
  static const List<String> _neonatalPreAnestheticOrientationOptions = [
    'Manter cafeína conforme prescrição',
    'Manter anticonvulsivantes conforme prescrição',
    'Confirmar antibióticos em uso com equipe assistente',
    'Confirmar vasoativos / infusões contínuas com UTI',
    'Confirmar glicemia seriada conforme risco',
    'Confirmar suporte ventilatório e transporte aquecido',
    'Trazer lista de medicações',
    'Trazer exames / laudos',
    'Cumprir jejum recomendado',
    'Avisar infecção / instabilidade clínica',
    'Confirmar equipe / responsável',
    'Confirmar termorregulação / glicemia / suporte neonatal',
  ];
  static const List<_OrientationOptionGroup>
  _neonatalPreAnestheticOrientationGroups = [
    _OrientationOptionGroup(
      title: 'Medicações neonatais',
      options: [
        'Manter cafeína conforme prescrição',
        'Manter anticonvulsivantes conforme prescrição',
        'Confirmar antibióticos em uso com equipe assistente',
        'Confirmar vasoativos / infusões contínuas com UTI',
      ],
      freeTextField: _OrientationFreeTextField(
        label: 'Outras medicações neonatais',
        hintText:
            'Ex: prostaglandina, nutrição/parenteral, sedação contínua...',
        prefix: 'Medicação neonatal: ',
      ),
    ),
    _OrientationOptionGroup(
      title: 'Suporte e segurança neonatal',
      options: [
        'Confirmar glicemia seriada conforme risco',
        'Confirmar suporte ventilatório e transporte aquecido',
        'Confirmar termorregulação / glicemia / suporte neonatal',
      ],
    ),
    _OrientationOptionGroup(
      title: 'Documentos, jejum e equipe',
      options: [
        'Trazer lista de medicações',
        'Trazer exames / laudos',
        'Cumprir jejum recomendado',
        'Confirmar equipe / responsável',
      ],
    ),
    _OrientationOptionGroup(
      title: 'Avisos e recontato',
      options: ['Avisar infecção / instabilidade clínica'],
      freeTextField: _OrientationFreeTextField(
        label: 'Outras orientações neonatais',
        hintText: 'Ex: transporte aquecido, alinhamento com UTI, suporte...',
        prefix: 'Orientação neonatal: ',
      ),
    ),
  ];
  static const List<String> _anesthesiaTeamRequestOptions = [
    'Avaliação cardiológica',
    'Avaliação pneumológica',
    'Outras avaliações',
    'Solicitação de exames',
  ];
  static const List<String> _surgeryClearanceOptions = [
    'Cirurgia liberada',
    'Cirurgia suspensa',
    'Pendente para liberação',
    'Retorno para reavaliação',
  ];
  static const List<String> _surgeryClearanceNoteOptions = [
    'Pendente de exame',
    'Pendente de avaliação',
    'Reavaliar após controle clínico',
    'Aguardar liberação',
    'Suspensa por risco clínico',
    'Retorno agendado',
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
  late final TextEditingController _pasController;
  late final TextEditingController _padController;
  late final TextEditingController _apController;
  late final TextEditingController _otherAirwayController;
  late final TextEditingController _otherDifficultAirwayPredictorsController;
  late final TextEditingController
  _otherDifficultVentilationPredictorsController;
  late final TextEditingController _otherComorbiditiesController;
  late final TextEditingController _otherMedicationsController;
  late final TextEditingController _otherHabitsController;
  late final TextEditingController _otherComplementaryExamsController;
  late final TextEditingController _otherProceduresController;
  late final TextEditingController _fastingNotesController;
  late final TextEditingController _asaNotesController;
  late final TextEditingController _otherAnestheticPlanController;
  late final TextEditingController _otherPostoperativePlanningController;
  late final TextEditingController _preAnestheticOrientationNotesController;
  late final Map<String, TextEditingController> _orientationFreeTextControllers;
  late final TextEditingController _anesthesiaTeamRequestNotesController;
  late final TextEditingController _surgeryClearanceNotesController;
  late final TextEditingController _freeNotesController;
  late final TextEditingController _otherRestrictionsController;
  late final TextEditingController _consultationDateController;
  late final ExpansibleController _surgerySectionController;

  late Set<String> _selectedComorbidities;
  late Set<String> _selectedMedications;
  late Set<String> _selectedExamItems;
  late Set<String> _selectedProcedures;
  late Set<String> _selectedAnestheticPlans;
  late Set<String> _selectedPostoperativePlanningItems;
  late Set<String> _selectedPreAnestheticOrientationItems;
  late Set<String> _selectedAnesthesiaTeamRequestItems;
  late Set<String> _selectedRestrictions;
  late Set<String> _selectedAirwayAssessmentFindings;
  late Set<String> _selectedDifficultAirwayPredictors;
  late Set<String> _selectedDifficultIntubationPredictors;
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
  String _selectedSurgeryClearanceStatus = '';
  String _selectedAsa = '';

  List<_OrientationFreeTextField> get _allOrientationFreeTextFields {
    final fields = <String, _OrientationFreeTextField>{};
    for (final group in [
      ..._preAnestheticOrientationGroups,
      ..._pediatricPreAnestheticOrientationGroups,
      ..._neonatalPreAnestheticOrientationGroups,
    ]) {
      final field = group.freeTextField;
      if (field != null) {
        fields[field.prefix] = field;
      }
    }
    return fields.values.toList();
  }

  late PatientPopulation _selectedPopulation;
  late final List<TextEditingController> _identificationControllers;
  late final Map<String, _ComplementaryExamEntry> _complementaryExamEntries;

  String _normalizePreAnestheticOrientationItem(String item) {
    return switch (item.trim()) {
      'Suspender medicações de risco' =>
        'Suspender IECA/ARB no dia da cirurgia se indicado',
      'Manter demais medicações' => 'Manter betabloqueador no dia da cirurgia',
      'Revisar anticoagulantes / antiagregantes' =>
        'Suspender DOAC 24-72h conforme função renal e risco de sangramento',
      'Suspender ou ajustar anticoagulantes / antiagregantes conforme orientação' =>
        'Suspender DOAC 24-72h conforme função renal e risco de sangramento',
      'Revisar antidiabéticos / insulina / GLP-1' =>
        'Ajustar insulina basal na véspera/no dia conforme glicemia',
      'Suspender ou ajustar antidiabéticos / insulina / GLP-1 conforme orientação' =>
        'Ajustar insulina basal na véspera/no dia conforme glicemia',
      final normalized => normalized,
    };
  }

  void _onIdentificationChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String _defaultNowLabel() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  DateTime? _parseConsultationDateTime(String value) {
    final match = RegExp(
      r'^(\d{2})/(\d{2})/(\d{4}) (\d{2}):(\d{2})$',
    ).firstMatch(value.trim());
    if (match == null) return null;

    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    final hour = int.tryParse(match.group(4) ?? '');
    final minute = int.tryParse(match.group(5) ?? '');
    if (day == null ||
        month == null ||
        year == null ||
        hour == null ||
        minute == null) {
      return null;
    }

    return DateTime(year, month, day, hour, minute);
  }

  String _formatConsultationDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _pickConsultationDateTime() async {
    final currentValue =
        _parseConsultationDateTime(_consultationDateController.text) ??
        DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentValue,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentValue),
    );
    if (selectedTime == null || !mounted) return;

    final combined = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    _consultationDateController.text = _formatConsultationDateTime(combined);
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

  List<_MedicationOptionGroup> get _profileMedicationOptionGroups {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _medicationOptionGroups;
      case PatientPopulation.pediatric:
        return _pediatricMedicationOptionGroups;
      case PatientPopulation.neonatal:
        return _neonatalMedicationOptionGroups;
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
          'Registrar antiagregantes, anticoagulantes, betabloqueadores, IECA/ARB, diuréticos, antidiabéticos, corticoides e broncodilatadores quando em uso crônico.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Rever broncodilatadores, corticoides inalatórios, anticonvulsivantes, antibióticos em curso, insulina e imunossupressores quando presentes.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Rever cafeína, antibióticos, diuréticos, anticonvulsivantes, suporte vasoativo e sedação/analgesia contínua em uso recente na UTI neonatal.',
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

  List<String> get _selectedProcedureLines => [
    ...commonProcedureOptions.where(_selectedProcedures.contains),
    ..._lines(_otherProceduresController.text),
  ];

  bool get _hasSurgeryContent =>
      _selectedProcedures.isNotEmpty ||
      _otherProceduresController.text.trim().isNotEmpty;

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

  List<String> get _profileAirwayAssessmentOptions {
    return {
          ..._profileDifficultAirwayPredictorOptions,
          ..._profileDifficultVentilationPredictorOptions,
        }
        .where((item) => !_structuredAirwayAssessmentFindings.contains(item))
        .toList();
  }

  List<String> get _allAirwayAssessmentOptions {
    return {
      ..._allDifficultAirwayPredictorOptions,
      ..._allDifficultVentilationPredictorOptions,
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

  String get _anestheticPlanSectionTitle {
    return switch (_selectedPopulation) {
      PatientPopulation.adult => 'Provável tipo de anestesia a ser realizada',
      PatientPopulation.pediatric =>
        'Provável tipo de anestesia a ser realizada',
      PatientPopulation.neonatal =>
        'Provável tipo de anestesia a ser realizada',
    };
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

  String get _strategicReserveSectionTitle =>
      'Reservas estratégicas (UTI / Sangue / Outros)';

  List<String> get _profilePreAnestheticOrientationOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _preAnestheticOrientationOptions;
      case PatientPopulation.pediatric:
        return _pediatricPreAnestheticOrientationOptions;
      case PatientPopulation.neonatal:
        return _neonatalPreAnestheticOrientationOptions;
    }
  }

  List<_OrientationOptionGroup> get _profilePreAnestheticOrientationGroups {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _preAnestheticOrientationGroups;
      case PatientPopulation.pediatric:
        return _pediatricPreAnestheticOrientationGroups;
      case PatientPopulation.neonatal:
        return _neonatalPreAnestheticOrientationGroups;
    }
  }

  List<String> get _profileAgePresetOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _adultAgePresetOptions;
      case PatientPopulation.pediatric:
        return _pediatricAgePresetOptions;
      case PatientPopulation.neonatal:
        return _neonatalAgePresetOptions;
    }
  }

  List<String> get _profileWeightPresetOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _adultWeightPresetOptions;
      case PatientPopulation.pediatric:
        return _pediatricWeightPresetOptions;
      case PatientPopulation.neonatal:
        return _neonatalWeightPresetOptions;
    }
  }

  List<String> get _profileHeightPresetOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _adultHeightPresetOptions;
      case PatientPopulation.pediatric:
        return _pediatricHeightPresetOptions;
      case PatientPopulation.neonatal:
        return _neonatalHeightPresetOptions;
    }
  }

  List<String> get _profileBirthWeightPresetOptions {
    return _neonatalBirthWeightPresetOptions;
  }

  List<String> get _profileGestationalAgePresetOptions {
    return _gestationalAgePresetOptions;
  }

  List<String> get _profileCorrectedGestationalAgePresetOptions {
    return _correctedGestationalAgePresetOptions;
  }

  List<String> get _profileAcPresetOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _adultAcPresetOptions;
      case PatientPopulation.pediatric:
        return _pediatricAcPresetOptions;
      case PatientPopulation.neonatal:
        return _neonatalAcPresetOptions;
    }
  }

  List<String> get _profileFcPresetOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _adultFcPresetOptions;
      case PatientPopulation.pediatric:
        return _pediatricFcPresetOptions;
      case PatientPopulation.neonatal:
        return _neonatalFcPresetOptions;
    }
  }

  List<String> get _profilePasPresetOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _adultPasPresetOptions;
      case PatientPopulation.pediatric:
        return _pediatricPasPresetOptions;
      case PatientPopulation.neonatal:
        return _neonatalPasPresetOptions;
    }
  }

  List<String> get _profilePadPresetOptions {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return _adultPadPresetOptions;
      case PatientPopulation.pediatric:
        return _pediatricPadPresetOptions;
      case PatientPopulation.neonatal:
        return _neonatalPadPresetOptions;
    }
  }

  String get _preAnestheticOrientationSectionTitle =>
      'Orientações de pré-anestésico';

  String get _anesthesiaTeamRequestSectionTitle =>
      'Solicitações pela equipe de anestesiologia';

  String get _surgeryClearanceSectionTitle => 'Situação da cirurgia';

  List<String> get _anesthesiaTeamRequestGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Registre avaliações externas e exames solicitados pela equipe para liberar a cirurgia com segurança.',
          'Deixe claro o que depende de cardiologia, pneumologia, outros especialistas ou exames complementares.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Aponte avaliações adicionais e exames solicitados pela equipe antes da cirurgia pediátrica.',
          'Use observações livres para combinar conduta com família e equipes assistentes.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Documente avaliações adicionais e exames solicitados para o recém-nascido antes da liberação cirúrgica.',
          'Registre pontos pendentes com UTI neonatal, cardiologia ou pneumologia quando necessário.',
        ];
    }
  }

  List<String> get _surgeryClearanceGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Use este campo para registrar se a cirurgia está liberada, suspensa ou pendente de liberação.',
          'Quando houver suspensão ou pendência, descreva o motivo ou a pendência para reavaliação.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Registre a situação da cirurgia e o motivo de suspensão ou pendência quando houver necessidade de nova avaliação.',
          'Anote retorno programado, intercorrências ou pendências da consulta anterior.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Registre se o procedimento está liberado ou se depende de suporte, estabilização ou reavaliação.',
          'Descreva motivos da suspensão e pendências clínicas, respiratórias ou logísticas.',
        ];
    }
  }

  List<String> get _postoperativeGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Defina reserva de leito crítico e suporte transfusional quando houver grande porte, sangramento esperado ou instabilidade clínica.',
          'Selecione apenas o que for relevante para a condução perioperatória e ajuste conforme protocolo local.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Reserve leito pediátrico, sangue compatibilizado ou observação prolongada quando houver risco respiratório, hemorrágico ou baixa reserva fisiológica.',
          'Ajuste a estratégia conforme idade, porte da cirurgia e necessidade de suporte pós-operatório.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Reserve UTI neonatal, UCIN e sangue compatibilizado quando houver prematuridade, apneia, suporte respiratório recente ou risco metabólico.',
          'Monitorização ampliada e ventilação pós-operatória devem ser definidas quando o risco clínico justificar.',
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

  List<String> get _preAnestheticOrientationGuidanceLines {
    switch (_selectedPopulation) {
      case PatientPopulation.adult:
        return const [
          'Revise a terapia medicamentosa na consulta e deixe claro o que deve ser suspenso ou mantido conforme risco trombótico, hemorrágico e metabólico.',
          'A avaliação pré-anestésica deve revisar medicações, alergias, exames pertinentes e o plano anestésico antes do procedimento.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Inclua orientações ao responsável sobre medicações em uso, jejum, sinais respiratórios e necessidade de reavaliação antes da cirurgia.',
          'A lista de medicações deve ser revisada em conjunto com a condição clínica e com a equipe assistente quando necessário.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Em neonatos, alinhe com a equipe o que deve ser mantido, suspenso ou reprogramado, considerando suporte ventilatório, glicemia e logística de UTI.',
          'Documente instruções de preparo, medicações em uso e sinais que exigem recontato antes do procedimento.',
        ];
    }
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

  List<String> get _profileSurgeryClearanceNoteOptions {
    return _surgeryClearanceNoteOptions;
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

  String _physicalExamField(List<String> labels, String source) {
    final pattern =
        '^(?:${labels.map(RegExp.escape).join('|')})\\s*:\\s*(.+)\$';
    final match = RegExp(
      pattern,
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
            r'^(AC|FC|PAS|PAD|PA|AP)\s*:',
            caseSensitive: false,
          ).hasMatch(line),
        )
        .join('\n');
  }

  String _normalizeComplementaryExamStatus(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'alterado' || normalized == 'alterada') {
      return 'alterado';
    }
    if (normalized == 'normal' || normalized == 'dentro da normalidade') {
      return 'normal';
    }
    return '';
  }

  String _normalizeFastingValue(
    String value,
    List<String> options,
    Map<String, String> legacyValues,
  ) {
    if (options.contains(value)) {
      return value;
    }
    return legacyValues[value.trim().toLowerCase()] ?? '';
  }

  void _restoreComplementaryExamEntries(String source) {
    final legacySelectedItems = _selectedExamItems.toSet();
    for (final exam in _profileComplementaryExamOptions) {
      _complementaryExamEntries[exam] = _ComplementaryExamEntry();
    }

    for (final line in _lines(source)) {
      final parts = line.split('||').map((item) => item.trim()).toList();
      if (parts.isEmpty) continue;
      final exam = parts.first;
      final entry = _complementaryExamEntries[exam];
      if (entry == null) continue;

      var status = '';
      var note = '';

      if (parts.length >= 2) {
        final maybeStatus = _normalizeComplementaryExamStatus(parts[1]);
        if (maybeStatus.isNotEmpty) {
          status = maybeStatus;
          if (parts.length >= 3) {
            note = parts.sublist(2).join(' || ');
          }
        } else {
          note = parts.sublist(1).join(' || ');
        }
      }

      if (status.isEmpty && legacySelectedItems.contains(exam)) {
        status = 'normal';
      }

      entry.status = status;
      entry.noteController.text = note;
      if (status.isNotEmpty) {
        _selectedExamItems.add(exam);
      }
    }

    for (final exam in legacySelectedItems) {
      final entry = _complementaryExamEntries[exam];
      if (entry == null) continue;
      if (entry.status.isEmpty) {
        entry.status = 'normal';
      }
    }
  }

  void _setComplementaryExamStatus(String exam, String status) {
    final entry = _complementaryExamEntries[exam];
    if (entry == null) return;

    setState(() {
      if (entry.status == status) {
        entry.status = '';
        _selectedExamItems.remove(exam);
        if (status == 'alterado') {
          entry.noteController.clear();
        }
        return;
      }

      entry.status = status;
      _selectedExamItems.add(exam);
      if (status != 'alterado') {
        entry.noteController.clear();
      }
    });
  }

  Widget _buildComplementaryExamRow(String exam) {
    final entry = _complementaryExamEntries[exam];
    if (entry == null) return const SizedBox.shrink();
    final isNormal = entry.status == 'normal';
    final isAltered = entry.status == 'alterado';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    exam,
                    style: const TextStyle(
                      color: Color(0xFF17324D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  _buildQuickActionChip(
                    label: 'Dentro da normalidade',
                    selected: isNormal,
                    color: const Color(0xFF169653),
                    onPressed: () =>
                        _setComplementaryExamStatus(exam, 'normal'),
                  ),
                  _buildQuickActionChip(
                    label: 'Alterado',
                    selected: isAltered,
                    color: const Color(0xFFCC3D3D),
                    onPressed: () =>
                        _setComplementaryExamStatus(exam, 'alterado'),
                  ),
                ],
              ),
            ],
          ),
          if (isAltered) ...[
            const SizedBox(height: 12),
            TextField(
              controller: entry.noteController,
              minLines: 2,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Principais alterações',
                hintText: 'Descreva a alteração mais relevante deste exame',
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildPhysicalExamSummary() {
    final parts = <String>[
      if (_acController.text.trim().isNotEmpty)
        'AC: ${_acController.text.trim()}',
      if (_fcController.text.trim().isNotEmpty)
        'FC: ${_fcController.text.trim()}',
      if (_pasController.text.trim().isNotEmpty)
        'PAS: ${_pasController.text.trim()}',
      if (_padController.text.trim().isNotEmpty)
        'PAD: ${_padController.text.trim()}',
      if (_apController.text.trim().isNotEmpty)
        'AP: ${_apController.text.trim()}',
      if (_physicalExamController.text.trim().isNotEmpty)
        _physicalExamController.text.trim(),
    ];
    return parts.join('\n');
  }

  void _syncAirwayPredictors() {
    _selectedDifficultIntubationPredictors =
        _difficultIntubationPredictorsFromAssessment();
    _selectedDifficultVentilationPredictors =
        _difficultVentilationPredictorsFromAssessment();
    _selectedDifficultAirwayPredictors = {
      ..._selectedDifficultIntubationPredictors,
      ..._selectedDifficultVentilationPredictors,
    };
  }

  Set<String> _difficultIntubationPredictorsFromAssessment() {
    final predictors = <String>{};
    for (final finding in _selectedAirwayAssessmentFindings) {
      if (_intubationPredictorSet.contains(finding)) {
        predictors.add(finding);
      }
    }
    if (_showMallampatiSection &&
        (_selectedMallampati == 'III' || _selectedMallampati == 'IV')) {
      predictors.add('Mallampati III/IV');
    }
    if (_selectedMouthOpening == '2-3 dedos (3-5 cm)' ||
        _selectedMouthOpening == '< 2 dedos (< 3 cm)' ||
        _selectedMouthOpening == 'Reduzida' ||
        _selectedMouthOpening == 'Muito reduzida') {
      predictors.add('Abertura oral reduzida');
    }
    if (_selectedNeckMobility == 'Limitada' ||
        _selectedNeckMobility == 'Muito limitada') {
      predictors.add('Mobilidade cervical limitada');
    }
    return predictors;
  }

  Set<String> _difficultVentilationPredictorsFromAssessment() {
    final predictors = <String>{};
    for (final finding in _selectedAirwayAssessmentFindings) {
      if (_ventilationPredictorSet.contains(finding)) {
        predictors.add(finding);
      }
    }
    if (_selectedMouthOpening == '< 2 dedos (< 3 cm)' ||
        _selectedMouthOpening == 'Muito reduzida') {
      predictors.add('Limitação mandibular');
    }
    if (_selectedDentition == 'Sem dentes') {
      predictors.add('Sem dentes');
    }
    return predictors;
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
          ? (widget.patient.heightMeters * 100)
                .toStringAsFixed(0)
                .replaceAll('.', ',')
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
      text: _physicalExamField(['AC'], assessment.physicalExam),
    );
    _fcController = TextEditingController(
      text: _physicalExamField(['FC'], assessment.physicalExam),
    );
    _pasController = TextEditingController(
      text: _physicalExamField(['PAS', 'PA'], assessment.physicalExam),
    );
    _padController = TextEditingController(
      text: _physicalExamField(['PAD'], assessment.physicalExam),
    );
    _apController = TextEditingController(
      text: _physicalExamField(['AP'], assessment.physicalExam),
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
    final initialProcedures = _lines(assessment.surgeryDescription);
    _otherComplementaryExamsController = TextEditingController(
      text: assessment.otherComplementaryExams,
    );
    _otherProceduresController = TextEditingController(
      text: initialProcedures
          .where((item) => !commonProcedureOptions.contains(item))
          .join('\n'),
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
    _preAnestheticOrientationNotesController = TextEditingController(
      text: assessment.preAnestheticOrientationNotes,
    );
    _orientationFreeTextControllers = {
      for (final field in _allOrientationFreeTextFields)
        field.prefix: TextEditingController(
          text: _orientationFreeTextValue(
            items: assessment.preAnestheticOrientationItems,
            prefix: field.prefix,
          ),
        ),
    };
    _anesthesiaTeamRequestNotesController = TextEditingController(
      text: assessment.anesthesiaTeamRequestNotes,
    );
    _surgeryClearanceNotesController = TextEditingController(
      text: assessment.surgeryClearanceNotes,
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
    _surgerySectionController = ExpansibleController();
    _selectedPopulation = widget.patient.population;

    _selectedComorbidities = assessment.comorbidities
        .where(_allComorbidityOptions.contains)
        .toSet();
    _selectedMedications = assessment.currentMedications
        .where(_allMedicationOptions.contains)
        .toSet();
    _selectedExamItems = assessment.complementaryExamItems
        .where(_allComplementaryExamOptions.contains)
        .toSet();
    _selectedProcedures = initialProcedures
        .where(commonProcedureOptions.contains)
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
    _selectedPreAnestheticOrientationItems = assessment
        .preAnestheticOrientationItems
        .map(_normalizePreAnestheticOrientationItem)
        .where(_profilePreAnestheticOrientationOptions.contains)
        .toSet();
    _selectedAnesthesiaTeamRequestItems = assessment.anesthesiaTeamRequestItems
        .where(_anesthesiaTeamRequestOptions.contains)
        .toSet();
    _selectedRestrictions = assessment.restrictionItems
        .where(_allRestrictionOptions.contains)
        .toSet();
    _selectedAirwayAssessmentFindings =
        {
              ...assessment.difficultAirwayPredictors,
              ...assessment.difficultIntubationPredictors,
              ...assessment.difficultVentilationPredictors,
            }
            .where(_allAirwayAssessmentOptions.contains)
            .where(
              (item) => !_structuredAirwayAssessmentFindings.contains(item),
            )
            .toSet();
    _selectedDifficultAirwayPredictors = assessment.difficultAirwayPredictors
        .where(_allAirwayAssessmentOptions.contains)
        .toSet();
    _selectedDifficultIntubationPredictors = assessment
        .difficultIntubationPredictors
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
    _syncAirwayPredictors();
    _selectedSolidFasting = _normalizeFastingValue(
      assessment.fastingSolids,
      _solidFastingOptions,
      const {'6h': '6 horas', '8h': '8 horas'},
    );
    _selectedLiquidFasting = _normalizeFastingValue(
      assessment.fastingLiquids,
      _liquidFastingOptions,
      const {'2h': '2 horas'},
    );
    _selectedBreastMilkFasting = _normalizeFastingValue(
      assessment.fastingBreastMilk,
      _breastMilkFastingOptions,
      const {'4h': '4 horas'},
    );
    _selectedSurgeryPriority =
        _surgeryPriorityOptions.contains(assessment.surgeryPriority)
        ? assessment.surgeryPriority
        : '';
    _selectedSurgeryClearanceStatus =
        _surgeryClearanceOptions.contains(assessment.surgeryClearanceStatus)
        ? assessment.surgeryClearanceStatus
        : '';
    _selectedAsa = _asaOptions.contains(assessment.asaClassification)
        ? assessment.asaClassification
        : widget.patient.asa;
    _complementaryExamEntries = {
      for (final exam in _profileComplementaryExamOptions)
        exam: _ComplementaryExamEntry(),
    };
    _restoreComplementaryExamEntries(assessment.complementaryExams);
    _identificationControllers = [
      _nameController,
      _ageController,
      _weightController,
      _heightController,
      _postnatalAgeController,
      _gestationalAgeController,
      _correctedGestationalAgeController,
      _birthWeightController,
      _consultationDateController,
      _otherProceduresController,
      _allergyController,
      _acController,
      _fcController,
      _pasController,
      _padController,
      _apController,
      _physicalExamController,
      _otherComplementaryExamsController,
      _fastingNotesController,
      _preAnestheticOrientationNotesController,
      _freeNotesController,
    ];
    for (final controller in _identificationControllers) {
      controller.addListener(_onIdentificationChanged);
    }
    _syncAirwayPredictors();
  }

  @override
  void dispose() {
    for (final controller in _identificationControllers) {
      controller.removeListener(_onIdentificationChanged);
    }
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
    _pasController.dispose();
    _padController.dispose();
    _apController.dispose();
    _otherAirwayController.dispose();
    _otherDifficultAirwayPredictorsController.dispose();
    _otherDifficultVentilationPredictorsController.dispose();
    _otherComorbiditiesController.dispose();
    _otherMedicationsController.dispose();
    _otherHabitsController.dispose();
    _otherComplementaryExamsController.dispose();
    _otherProceduresController.dispose();
    _fastingNotesController.dispose();
    _asaNotesController.dispose();
    _otherAnestheticPlanController.dispose();
    _otherPostoperativePlanningController.dispose();
    _preAnestheticOrientationNotesController.dispose();
    for (final controller in _orientationFreeTextControllers.values) {
      controller.dispose();
    }
    _anesthesiaTeamRequestNotesController.dispose();
    _surgeryClearanceNotesController.dispose();
    _freeNotesController.dispose();
    _otherRestrictionsController.dispose();
    _consultationDateController.dispose();
    _surgerySectionController.dispose();
    for (final entry in _complementaryExamEntries.values) {
      entry.dispose();
    }
    super.dispose();
  }

  List<String> _lines(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _orientationFreeTextValue({
    required List<String> items,
    required String prefix,
  }) {
    return items
        .where((item) => item.trim().startsWith(prefix))
        .map((item) => item.trim().substring(prefix.length).trim())
        .where((item) => item.isNotEmpty)
        .join('\n');
  }

  List<String> get _orientationFreeTextItems {
    final items = <String>[];
    for (final field in _allOrientationFreeTextFields) {
      final controller = _orientationFreeTextControllers[field.prefix];
      if (controller == null) continue;
      for (final line in _lines(controller.text)) {
        items.add('${field.prefix}$line');
      }
    }
    return items;
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

  Widget _buildMultiSelectButtons({
    required List<String> options,
    required Set<String> selectedValues,
    required ValueChanged<String> onToggle,
    Color color = const Color(0xFF2B76D2),
    Color Function(String option)? selectedColorBuilder,
  }) {
    return _buildOptionCardGrid(
      options: options,
      isSelected: selectedValues.contains,
      onTap: onToggle,
      color: color,
      selectedColorBuilder: selectedColorBuilder,
    );
  }

  Widget _buildMedicationOptionGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in _profileMedicationOptionGroups) ...[
          _sectionLabel(group.title),
          const SizedBox(height: 8),
          _buildMultiSelectButtons(
            options: group.options,
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
        ],
      ],
    );
  }

  Widget _buildPreAnestheticOrientationGroups() {
    return Column(
      children: [
        for (final group in _profilePreAnestheticOrientationGroups)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildExpandableOptionGroup(
              title: group.title,
              options: group.options,
              freeTextField: group.freeTextField,
              selectedValues: _selectedPreAnestheticOrientationItems,
              color: _completedSelectionColor,
              selectedColorBuilder: (option) =>
                  _isSuspendedOrientationOption(option)
                  ? _suspendedSelectionColor
                  : _completedSelectionColor,
              onToggle: (value) {
                setState(() {
                  if (_selectedPreAnestheticOrientationItems.contains(value)) {
                    _selectedPreAnestheticOrientationItems.remove(value);
                  } else {
                    _selectedPreAnestheticOrientationItems.add(value);
                  }
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildExpandableOptionGroup({
    required String title,
    required List<String> options,
    _OrientationFreeTextField? freeTextField,
    required Set<String> selectedValues,
    required ValueChanged<String> onToggle,
    required Color color,
    Color Function(String option)? selectedColorBuilder,
  }) {
    final selectedOptionCount = options
        .where((option) => selectedValues.contains(option))
        .length;
    final freeTextCount = freeTextField == null
        ? 0
        : _lines(
            _orientationFreeTextControllers[freeTextField.prefix]?.text ?? '',
          ).length;
    final selectedCount = selectedOptionCount + freeTextCount;
    final hasSuspendedSelection =
        options.any(
          (option) =>
              selectedValues.contains(option) &&
              _isSuspendedOrientationOption(option),
        ) ||
        (freeTextCount > 0 && _isSuspendedOrientationFreeText(freeTextField));
    final statusColor = hasSuspendedSelection
        ? _suspendedSelectionColor
        : color;
    final subtitle = selectedCount == 0
        ? 'Toque para escolher opções'
        : '$selectedCount opção(ões) selecionada(s)';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selectedCount == 0
              ? const Color(0xFFD5E4F7)
              : statusColor.withValues(alpha: 0.65),
          width: selectedCount == 0 ? 1 : 1.3,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF21364A),
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: selectedCount == 0 ? const Color(0xFF5D7288) : statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            if (options.isNotEmpty)
              _buildMultiSelectButtons(
                options: options,
                selectedValues: selectedValues,
                onToggle: onToggle,
                color: color,
                selectedColorBuilder: selectedColorBuilder,
              ),
            if (freeTextField != null) ...[
              if (options.isNotEmpty) const SizedBox(height: 14),
              _buildOrientationFreeTextField(freeTextField),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSuspendedOrientationOption(String option) {
    final normalized = option.trim().toLowerCase();
    return normalized.startsWith('suspender ') ||
        normalized.startsWith('suspender/ajustar ') ||
        normalized.contains(' suspender ');
  }

  bool _isSuspendedOrientationFreeText(_OrientationFreeTextField? field) {
    if (field == null) return false;
    return field.prefix.trim().toLowerCase().startsWith('suspender');
  }

  Widget _buildOrientationFreeTextField(_OrientationFreeTextField field) {
    final controller = _orientationFreeTextControllers[field.prefix];
    if (controller == null) return const SizedBox.shrink();
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 5,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hintText,
      ),
    );
  }

  Widget _buildAirwayClassificationPanel({
    required String title,
    required Set<String> predictors,
    required Color color,
  }) {
    final value = predictors.isEmpty
        ? 'Sem preditores classificados'
        : predictors.join(' • ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSelectButtons({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
    Color color = const Color(0xFF169653),
  }) {
    return _buildOptionCardGrid(
      options: options,
      isSelected: (option) => selectedValue == option,
      onTap: (option) => onSelected(selectedValue == option ? '' : option),
      color: color,
    );
  }

  Widget _buildOptionCardGrid({
    required List<String> options,
    required bool Function(String option) isSelected,
    required ValueChanged<String> onTap,
    required Color color,
    Color Function(String option)? selectedColorBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 2 : 1;
        final columnChildren = List.generate(columns, (_) => <Widget>[]);

        for (var i = 0; i < options.length; i++) {
          final option = options[i];
          final selected = isSelected(option);
          final effectiveColor = selected
              ? selectedColorBuilder?.call(option) ?? color
              : color;
          columnChildren[i % columns].add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildOptionCard(
                label: option,
                selected: selected,
                onTap: () => onTap(option),
                color: effectiveColor,
              ),
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns; i++) ...[
              Expanded(child: Column(children: columnChildren[i])),
              if (i != columns - 1) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOptionCard({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final borderColor = selected ? color : const Color(0xFFD5E4F7);
    final backgroundColor = selected
        ? color.withValues(alpha: 0.10)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A17324D),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? color : const Color(0xFF26384A),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 10),
                Icon(
                  color == _suspendedSelectionColor
                      ? Icons.block_outlined
                      : Icons.check_circle_outline,
                  color: color,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableInputWithQuickPresets({
    required TextEditingController controller,
    required String label,
    required List<String> presetOptions,
    required ValueChanged<String> onSelected,
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Color color = const Color(0xFF169653),
  }) {
    if (presetOptions.isEmpty) {
      return _buildAdaptiveInputField(
        controller: controller,
        label: label,
        hintText: hintText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      );
    }

    return _ExpandablePresetFieldCard(
      controller: controller,
      label: label,
      hintText: hintText,
      presetOptions: presetOptions,
      onSelected: onSelected,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      color: color,
    );
  }

  Widget _buildInputWithQuickPresets({
    required TextEditingController controller,
    required String label,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Color color = const Color(0xFF169653),
  }) {
    if (options.isEmpty) {
      return _buildAdaptiveInputField(
        controller: controller,
        label: label,
        hintText: hintText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAdaptiveInputField(
          controller: controller,
          label: label,
          hintText: hintText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Valores rápidos',
            style: TextStyle(
              color: Color(0xFF5F7288),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _buildSingleSelectButtons(
          options: options,
          selectedValue: selectedValue,
          onSelected: onSelected,
          color: color,
        ),
      ],
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
    final complementaryExamLines = _selectedExamItems.map((exam) {
      final entry = _complementaryExamEntries[exam];
      final status = entry?.status ?? 'normal';
      final note = entry?.noteController.text.trim() ?? '';
      return [exam, status, note].join(' || ');
    }).toList();
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
          ((double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0) /
                  100) >
              0
          ? (double.tryParse(_heightController.text.replaceAll(',', '.')) ??
                    0) /
                100
          : widget.patient.heightMeters,
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
      difficultIntubationPredictors: _selectedDifficultIntubationPredictors
          .toList(),
      otherDifficultIntubationPredictors: '',
      difficultVentilationPredictors: _selectedDifficultVentilationPredictors
          .toList(),
      otherDifficultVentilationPredictors:
          _otherDifficultVentilationPredictorsController.text.trim(),
      otherAirwayDetails: _otherAirwayController.text.trim(),
      complementaryExamItems: _selectedExamItems.toList(),
      complementaryExams: complementaryExamLines.join('\n'),
      otherComplementaryExams: _otherComplementaryExamsController.text.trim(),
      surgeryDescription: _selectedProcedureLines.join('\n'),
      anesthesiaTeamRequestItems: _selectedAnesthesiaTeamRequestItems.toList(),
      anesthesiaTeamRequestNotes: _anesthesiaTeamRequestNotesController.text
          .trim(),
      fastingSolids: _selectedSolidFasting,
      fastingLiquids: _selectedLiquidFasting,
      fastingBreastMilk: _showBreastMilkFastingSection
          ? _selectedBreastMilkFasting
          : '',
      fastingNotes: _fastingNotesController.text.trim(),
      surgeryPriority: _selectedSurgeryPriority,
      surgeryClearanceStatus: _selectedSurgeryClearanceStatus,
      surgeryClearanceNotes: _surgeryClearanceNotesController.text.trim(),
      asaClassification: _selectedAsa,
      asaNotes: _asaNotesController.text.trim(),
      anestheticPlan: anestheticPlanLines.join('\n'),
      otherAnestheticPlan: _otherAnestheticPlanController.text.trim(),
      postoperativePlanningItems: _selectedPostoperativePlanningItems.toList(),
      otherPostoperativePlanning: _otherPostoperativePlanningController.text
          .trim(),
      planningNotes: _freeNotesController.text.trim(),
      preAnestheticOrientationItems: [
        ..._selectedPreAnestheticOrientationItems,
        ..._orientationFreeTextItems,
      ],
      preAnestheticOrientationNotes: _preAnestheticOrientationNotesController
          .text
          .trim(),
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

  void _navigateHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta Pré-Anestésica'),
        actions: [
          TextButton.icon(
            onPressed: _navigateHome,
            icon: const Icon(Icons.home_outlined),
            label: const Text('Tela inicial'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Identificação do paciente',
            initiallyExpanded: true,
            isCompleted: _hasCompleteIdentification,
            summary: _identificationSummary(),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PatientPopulation.values
                        .map(
                          (item) => OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedPopulation = item;
                                _selectedPostoperativePlanningItems.removeWhere(
                                  (value) =>
                                      !_profilePostoperativePlanningOptions
                                          .contains(value),
                                );
                                _selectedPreAnestheticOrientationItems
                                    .removeWhere(
                                      (value) =>
                                          !_profilePreAnestheticOrientationOptions
                                              .contains(value),
                                    );
                                if (!_showMallampatiSection) {
                                  _selectedMallampati = '';
                                }
                                _syncAirwayPredictors();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _selectedPopulation == item
                                  ? const Color(0xFF2B76D2).withAlpha(18)
                                  : Colors.white,
                              side: BorderSide(
                                color: _selectedPopulation == item
                                    ? const Color(0xFF2B76D2)
                                    : const Color(0xFFD6E1ED),
                              ),
                              foregroundColor: _selectedPopulation == item
                                  ? const Color(0xFF2B76D2)
                                  : const Color(0xFF4F6378),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _buildAdaptiveInputField(
                  controller: _nameController,
                  label: 'Nome',
                  hintText: 'Digite o nome do paciente',
                ),
                const SizedBox(height: 12),
                _buildAdaptiveInputField(
                  controller: _consultationDateController,
                  label: 'Data da consulta pré-anestésica',
                  hintText: 'dd/mm/aaaa hh:mm',
                  readOnly: true,
                  onTap: _pickConsultationDateTime,
                  suffixIcon: IconButton(
                    tooltip: 'Selecionar data e hora',
                    icon: const Icon(Icons.calendar_month_outlined),
                    onPressed: _pickConsultationDateTime,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildExpandableInputWithQuickPresets(
                        controller:
                            _selectedPopulation == PatientPopulation.neonatal
                            ? _postnatalAgeController
                            : _ageController,
                        label: _selectedPopulation == PatientPopulation.neonatal
                            ? 'Idade pós-natal (dias)'
                            : 'Idade (anos)',
                        presetOptions: _profileAgePresetOptions,
                        onSelected: (option) {
                          setState(() {
                            (_selectedPopulation == PatientPopulation.neonatal
                                        ? _postnatalAgeController
                                        : _ageController)
                                    .text =
                                option;
                          });
                        },
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildExpandableInputWithQuickPresets(
                        controller: _weightController,
                        label: 'Peso (kg)',
                        presetOptions: _profileWeightPresetOptions,
                        onSelected: (option) {
                          setState(() => _weightController.text = option);
                        },
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildExpandableInputWithQuickPresets(
                        controller: _heightController,
                        label: 'Altura (cm)',
                        presetOptions: _profileHeightPresetOptions,
                        onSelected: (option) {
                          setState(() => _heightController.text = option);
                        },
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedPopulation == PatientPopulation.pediatric) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAdaptiveInputField(
                          controller: _postnatalAgeController,
                          label: 'Idade pós-natal (dias)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (_selectedPopulation == PatientPopulation.neonatal) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildExpandableInputWithQuickPresets(
                          controller: _birthWeightController,
                          label: 'Peso ao nascer (kg)',
                          presetOptions: _profileBirthWeightPresetOptions,
                          onSelected: (option) {
                            setState(
                              () => _birthWeightController.text = option,
                            );
                          },
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,.]'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildExpandableInputWithQuickPresets(
                          controller: _gestationalAgeController,
                          label: 'IG ao nascer (semanas)',
                          presetOptions: _profileGestationalAgePresetOptions,
                          onSelected: (option) {
                            setState(
                              () => _gestationalAgeController.text = option,
                            );
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildExpandableInputWithQuickPresets(
                          controller: _correctedGestationalAgeController,
                          label: 'IG corrigida (semanas)',
                          presetOptions:
                              _profileCorrectedGestationalAgePresetOptions,
                          onSelected: (option) {
                            setState(
                              () => _correctedGestationalAgeController.text =
                                  option,
                            );
                          },
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ],
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 900;

              final surgeryCard = _SectionCard(
                title: 'Cirurgia a ser realizada',
                isCompleted: _hasSurgeryContent,
                controller: _surgerySectionController,
                summary: _surgerySummary(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryBanner(_surgerySummary()),
                    const SizedBox(height: 14),
                    SelectionGridSection(
                      options: commonProcedureOptions,
                      isSelected: (option) =>
                          _selectedProcedures.contains(option),
                      onToggle: (value) {
                        setState(() {
                          if (_selectedProcedures.contains(value)) {
                            _selectedProcedures.remove(value);
                          } else {
                            _selectedProcedures.add(value);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _otherProceduresController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Outros',
                        hintText:
                            'Descreva a cirurgia ou procedimento quando não estiver na lista',
                      ),
                    ),
                  ],
                ),
              );

              final priorityCard = _SectionCard(
                title: 'Prioridade cirúrgica',
                isCompleted:
                    _selectedSurgeryPriority.isNotEmpty ||
                    _freeNotesController.text.trim().isNotEmpty,
                summary: _prioritySummary(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryBanner(_prioritySummary()),
                    const SizedBox(height: 14),
                    _buildSingleSelectButtons(
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
              );

              if (sideBySide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: surgeryCard),
                    const SizedBox(width: 12),
                    Expanded(child: priorityCard),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  surgeryCard,
                  const SizedBox(height: 12),
                  priorityCard,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 900;

              final requestsCard = _SectionCard(
                title: _anesthesiaTeamRequestSectionTitle,
                isCompleted:
                    _selectedAnesthesiaTeamRequestItems.isNotEmpty ||
                    _anesthesiaTeamRequestNotesController.text
                        .trim()
                        .isNotEmpty,
                summary: _requestsSummary(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryBanner(_requestsSummary()),
                    const SizedBox(height: 14),
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
                        children: _anesthesiaTeamRequestGuidanceLines
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
                    _buildMultiSelectButtons(
                      options: _anesthesiaTeamRequestOptions,
                      selectedValues: _selectedAnesthesiaTeamRequestItems,
                      color: const Color(0xFF2B76D2),
                      onToggle: (value) {
                        setState(() {
                          if (_selectedAnesthesiaTeamRequestItems.contains(
                            value,
                          )) {
                            _selectedAnesthesiaTeamRequestItems.remove(value);
                          } else {
                            _selectedAnesthesiaTeamRequestItems.add(value);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _anesthesiaTeamRequestNotesController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Outras solicitações',
                        hintText:
                            'Ex: avaliação cardiológica, pneumológica, exames, recomendações ou pendências adicionais',
                      ),
                    ),
                  ],
                ),
              );

              final clearanceCard = _SectionCard(
                title: _surgeryClearanceSectionTitle,
                isCompleted:
                    _selectedSurgeryClearanceStatus.isNotEmpty ||
                    _surgeryClearanceNotesController.text.trim().isNotEmpty,
                tone: _hasSurgeryClearanceAlert
                    ? _SectionCardTone.alert
                    : _selectedSurgeryClearanceStatus == 'Cirurgia liberada'
                    ? _SectionCardTone.completed
                    : _SectionCardTone.neutral,
                summary: _clearanceSummary(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryBanner(
                      _clearanceSummary(),
                      tone: _hasSurgeryClearanceAlert
                          ? _SectionCardTone.alert
                          : _selectedSurgeryClearanceStatus ==
                                'Cirurgia liberada'
                          ? _SectionCardTone.completed
                          : _SectionCardTone.neutral,
                    ),
                    const SizedBox(height: 14),
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
                        children: _surgeryClearanceGuidanceLines
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
                    _buildSingleSelectButtons(
                      options: _surgeryClearanceOptions,
                      selectedValue: _selectedSurgeryClearanceStatus,
                      color: const Color(0xFF169653),
                      onSelected: (value) {
                        setState(() => _selectedSurgeryClearanceStatus = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Motivos rápidos',
                      style: TextStyle(
                        color: Color(0xFF17324D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectionGridSection(
                      options: _profileSurgeryClearanceNoteOptions,
                      searchEnabled: false,
                      isSelected: (option) => _surgeryClearanceNotesController
                          .text
                          .split('\n')
                          .map((line) => line.trim())
                          .where((line) => line.isNotEmpty)
                          .contains(option),
                      onToggle: _toggleSurgeryClearanceNoteOption,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _surgeryClearanceNotesController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Motivos / pendências / retorno',
                        hintText:
                            'Ex: suspensa por HAS descompensada, pendência cardiológica, retorno após exame',
                      ),
                    ),
                  ],
                ),
              );

              if (sideBySide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: requestsCard),
                    const SizedBox(width: 12),
                    Expanded(child: clearanceCard),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  requestsCard,
                  const SizedBox(height: 12),
                  clearanceCard,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Antecedentes',
            isCompleted:
                _selectedComorbidities.isNotEmpty ||
                _otherComorbiditiesController.text.trim().isNotEmpty,
            summary: _antecedentsSummary(),
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
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FBF6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFE3C9)),
                  ),
                  child: Text(
                    _antecedentsSummary(),
                    style: const TextStyle(
                      color: Color(0xFF177245),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildMultiSelectButtons(
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
            isCompleted:
                _selectedMedications.isNotEmpty ||
                _otherMedicationsController.text.trim().isNotEmpty,
            summary: _medicationsSummary(),
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
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FBF6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFE3C9)),
                  ),
                  child: Text(
                    _medicationsSummary(),
                    style: const TextStyle(
                      color: Color(0xFF177245),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildMedicationOptionGroups(),
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
            isCompleted: true,
            summary: _allergySummary(),
            tone: _allergyController.text.trim().isEmpty
                ? _SectionCardTone.completed
                : _SectionCardTone.alert,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickActionChip(
                      label: 'Sem alergias',
                      selected: _allergyController.text.trim().isEmpty,
                      color: const Color(0xFF169653),
                      onPressed: () {
                        setState(() {
                          _allergyController.text = '';
                        });
                      },
                    ),
                    ...[
                      'AAS',
                      'Penicilina',
                      'Dipirona',
                      'Látex',
                      'Alimentos',
                    ].map(
                      (item) => _buildQuickActionChip(
                        label: item,
                        selected: _allergyController.text
                            .trim()
                            .toLowerCase()
                            .contains(item.toLowerCase()),
                        color: const Color(0xFFCC7A00),
                        onPressed: () {
                          setState(() {
                            _allergyController.text = item;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAdaptiveInputField(
                  controller: _allergyController,
                  label: 'Descrição das alergias',
                  hintText: 'Descreva alergias conhecidas',
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          _SectionCard(
            title: _contextSectionTitle,
            isCompleted: _hasHabitsContent,
            summary: _habitsSummary(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(_primaryExposureLabel),
                const SizedBox(height: 8),
                _buildSingleSelectButtons(
                  options: _profileSmokingExposureOptions,
                  selectedValue: _smokingStatus,
                  onSelected: (value) => setState(() => _smokingStatus = value),
                ),
                const SizedBox(height: 14),
                _sectionLabel(_secondaryExposureLabel),
                const SizedBox(height: 8),
                _buildSingleSelectButtons(
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
            isCompleted: _hasFunctionalContent,
            summary: _functionalSummary(),
            tone: _hasFunctionalRisk
                ? _SectionCardTone.alert
                : (_hasFunctionalContent
                      ? _SectionCardTone.completed
                      : _SectionCardTone.neutral),
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
                    return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedMets = option.value;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selected
                            ? const Color(0xFF2B76D2).withAlpha(18)
                            : Colors.white,
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF2B76D2)
                              : const Color(0xFFD6E1ED),
                        ),
                        foregroundColor: selected
                            ? const Color(0xFF2B76D2)
                            : const Color(0xFF4F6378),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            option.value,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.description,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
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
            title: 'Classificação ASA',
            isCompleted: _hasAsaContent,
            summary: _asaSummary(),
            tone: _hasHighRiskAsa
                ? _SectionCardTone.alert
                : (_hasAsaContent
                      ? _SectionCardTone.completed
                      : _SectionCardTone.neutral),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSingleSelectButtons(
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
            title: _physicalExamSectionTitle,
            isCompleted: _hasPhysicalExamContent,
            summary: _physicalExamSummary(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickActionChip(
                      label: 'Exame normal',
                      selected:
                          _acController.text.trim().isNotEmpty ||
                          _fcController.text.trim().isNotEmpty ||
                          _pasController.text.trim().isNotEmpty ||
                          _padController.text.trim().isNotEmpty ||
                          _apController.text.trim().isNotEmpty,
                      color: const Color(0xFF169653),
                      onPressed: () {
                        setState(() {
                          _acController.text = 'Rítmico';
                          _fcController.text = '80 bpm';
                          _pasController.text = '120 mmHg';
                          _padController.text = '80 mmHg';
                          _apController.text = 'Sem ruídos adventícios';
                        });
                      },
                    ),
                    _buildQuickActionChip(
                      label: 'Limpar exame',
                      selected: false,
                      color: const Color(0xFFCC3D3D),
                      onPressed: () {
                        setState(() {
                          _acController.clear();
                          _fcController.clear();
                          _pasController.clear();
                          _padController.clear();
                          _apController.clear();
                          _physicalExamController.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputWithQuickPresets(
                        controller: _acController,
                        label: 'AC',
                        options: _profileAcPresetOptions,
                        selectedValue: _acController.text.trim(),
                        onSelected: (option) =>
                            setState(() => _acController.text = option),
                        hintText: _acHint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputWithQuickPresets(
                        controller: _fcController,
                        label: 'FC',
                        options: _profileFcPresetOptions,
                        selectedValue: _fcController.text.trim(),
                        onSelected: (option) =>
                            setState(() => _fcController.text = option),
                        hintText: _fcHint,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputWithQuickPresets(
                        controller: _pasController,
                        label: 'PAS',
                        options: _profilePasPresetOptions,
                        selectedValue: _pasController.text.trim(),
                        onSelected: (option) =>
                            setState(() => _pasController.text = option),
                        hintText: 'Pressão sistólica',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputWithQuickPresets(
                        controller: _padController,
                        label: 'PAD',
                        options: _profilePadPresetOptions,
                        selectedValue: _padController.text.trim(),
                        onSelected: (option) =>
                            setState(() => _padController.text = option),
                        hintText: 'Pressão diastólica',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAdaptiveInputField(
                  controller: _apController,
                  label: 'AP',
                  hintText: _apHint,
                ),
                const SizedBox(height: 12),
                _buildAdaptiveInputField(
                  controller: _physicalExamController,
                  label: 'Outros achados',
                  hintText: _physicalOtherHint,
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Avaliação de via aérea',
            isCompleted: _hasAirwayContent,
            summary: _airwaySummary(),
            tone: _hasAirwayRisk
                ? _SectionCardTone.alert
                : (_hasAirwayContent
                      ? _SectionCardTone.completed
                      : _SectionCardTone.neutral),
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
                  _buildSingleSelectButtons(
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
                _buildSingleSelectButtons(
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
                _buildSingleSelectButtons(
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
                  _buildSingleSelectButtons(
                    options: _profileDentitionOptions,
                    selectedValue: _selectedDentition,
                    onSelected: (value) {
                      setState(() {
                        _selectedDentition = value;
                        _syncAirwayPredictors();
                      });
                    },
                    color: const Color(0xFFCC7A00),
                  ),
                ],
                const SizedBox(height: 14),
                _sectionLabel('Achados da avaliação de via aérea'),
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
                        ? 'Marque apenas os achados presentes. O sistema classifica automaticamente risco de via aérea, intubação e ventilação difícil.'
                        : _selectedPopulation == PatientPopulation.pediatric
                        ? 'Marque apenas os achados presentes na criança. Síndromes craniofaciais, IVAS, secreção e hipertrofia adenotonsilar são classificados conforme risco predominante.'
                        : 'Marque apenas os achados presentes no neonato. Micrognatia, secreção, suporte ventilatório e distensão abdominal são classificados conforme risco predominante.',
                    style: const TextStyle(
                      color: Color(0xFF5D7288),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildMultiSelectButtons(
                  options: _profileAirwayAssessmentOptions,
                  selectedValues: _selectedAirwayAssessmentFindings,
                  color: const Color(0xFF2B76D2),
                  onToggle: (value) {
                    setState(() {
                      if (_selectedAirwayAssessmentFindings.contains(value)) {
                        _selectedAirwayAssessmentFindings.remove(value);
                      } else {
                        _selectedAirwayAssessmentFindings.add(value);
                      }
                      _syncAirwayPredictors();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildAirwayClassificationPanel(
                  title: 'Preditores de via aérea difícil',
                  predictors: _selectedDifficultAirwayPredictors,
                  color: const Color(0xFFEA5455),
                ),
                const SizedBox(height: 10),
                _buildAirwayClassificationPanel(
                  title: 'Preditores de intubação difícil',
                  predictors: _selectedDifficultIntubationPredictors,
                  color: const Color(0xFF8A5DD3),
                ),
                const SizedBox(height: 10),
                _buildAirwayClassificationPanel(
                  title: 'Preditores de ventilação difícil',
                  predictors: _selectedDifficultVentilationPredictors,
                  color: const Color(0xFFCC7A00),
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
            isCompleted: _hasComplementaryExamsContent,
            summary: _complementaryExamsSummary(),
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
                _buildComplementaryExamsSummaryPanel(),
                const SizedBox(height: 14),
                ..._profileComplementaryExamOptions.map(
                  _buildComplementaryExamRow,
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
            title: 'Jejum recomendado',
            isCompleted: _hasFastingContent,
            summary: _fastingSummary(),
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
                _buildSummaryBanner(_fastingSummary()),
                const SizedBox(height: 14),
                _sectionLabel(_solidFastingLabel),
                const SizedBox(height: 8),
                _buildSingleSelectButtons(
                  options: _solidFastingOptions,
                  selectedValue: _selectedSolidFasting,
                  onSelected: (value) {
                    setState(() => _selectedSolidFasting = value);
                  },
                  color: const Color(0xFFCC7A00),
                ),
                const SizedBox(height: 14),
                _sectionLabel(_liquidFastingLabel),
                const SizedBox(height: 8),
                _buildSingleSelectButtons(
                  options: _liquidFastingOptions,
                  selectedValue: _selectedLiquidFasting,
                  onSelected: (value) {
                    setState(() => _selectedLiquidFasting = value);
                  },
                ),
                if (_showBreastMilkFastingSection) ...[
                  const SizedBox(height: 14),
                  _sectionLabel(_breastMilkFastingLabel),
                  const SizedBox(height: 8),
                  _buildSingleSelectButtons(
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
            title: _anestheticPlanSectionTitle,
            isCompleted:
                _selectedAnestheticPlans.isNotEmpty ||
                _otherAnestheticPlanController.text.trim().isNotEmpty,
            summary: _anestheticPlanSummary(),
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
                _buildSummaryBanner(_anestheticPlanSummary()),
                const SizedBox(height: 14),
                _buildMultiSelectButtons(
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
            title: _strategicReserveSectionTitle,
            isCompleted: _hasPostoperativePlanningContent,
            summary: _postoperativePlanningSummary(),
            tone: _hasPostoperativePlanningContent
                ? _SectionCardTone.alert
                : _SectionCardTone.neutral,
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
                _buildMultiSelectButtons(
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
                        'Detalhe necessidade de UTI, sangue, observações adicionais ou suporte específico',
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: _restrictionSectionTitle,
            isCompleted: _hasRestrictionContent,
            summary: _restrictionSummary(),
            tone: _hasRestrictionContent
                ? _SectionCardTone.alert
                : _SectionCardTone.neutral,
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
                _buildMultiSelectButtons(
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
          _SectionCard(
            title: _preAnestheticOrientationSectionTitle,
            isCompleted:
                _selectedPreAnestheticOrientationItems.isNotEmpty ||
                _orientationFreeTextItems.isNotEmpty ||
                _preAnestheticOrientationNotesController.text.trim().isNotEmpty,
            summary: _preAnestheticOrientationSummary(),
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
                    children: _preAnestheticOrientationGuidanceLines
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
                _buildPreAnestheticOrientationGroups(),
                const SizedBox(height: 14),
                TextField(
                  controller: _preAnestheticOrientationNotesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Detalhes complementares',
                    hintText:
                        'Ex: suspender medicações específicas, horários, recontato, preparo adicional',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saveAndReturn,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar pré-anestésico no banco'),
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

  bool get _hasCompleteIdentification {
    return switch (_selectedPopulation) {
      PatientPopulation.adult =>
        _nameController.text.trim().isNotEmpty &&
            _consultationDateController.text.trim().isNotEmpty &&
            _ageController.text.trim().isNotEmpty &&
            _weightController.text.trim().isNotEmpty &&
            _heightController.text.trim().isNotEmpty,
      PatientPopulation.pediatric =>
        _nameController.text.trim().isNotEmpty &&
            _consultationDateController.text.trim().isNotEmpty &&
            _ageController.text.trim().isNotEmpty &&
            _weightController.text.trim().isNotEmpty &&
            _heightController.text.trim().isNotEmpty &&
            _postnatalAgeController.text.trim().isNotEmpty,
      PatientPopulation.neonatal =>
        _nameController.text.trim().isNotEmpty &&
            _consultationDateController.text.trim().isNotEmpty &&
            _postnatalAgeController.text.trim().isNotEmpty &&
            _weightController.text.trim().isNotEmpty &&
            _heightController.text.trim().isNotEmpty &&
            _birthWeightController.text.trim().isNotEmpty &&
            _gestationalAgeController.text.trim().isNotEmpty &&
            _correctedGestationalAgeController.text.trim().isNotEmpty,
    };
  }

  bool get _hasPhysicalExamContent =>
      _acController.text.trim().isNotEmpty ||
      _fcController.text.trim().isNotEmpty ||
      _pasController.text.trim().isNotEmpty ||
      _padController.text.trim().isNotEmpty ||
      _apController.text.trim().isNotEmpty ||
      _physicalExamController.text.trim().isNotEmpty;

  bool get _hasComplementaryExamsContent =>
      _selectedExamItems.isNotEmpty ||
      _otherComplementaryExamsController.text.trim().isNotEmpty;

  bool get _hasFastingContent =>
      _selectedSolidFasting.isNotEmpty ||
      _selectedLiquidFasting.isNotEmpty ||
      _selectedBreastMilkFasting.isNotEmpty ||
      _fastingNotesController.text.trim().isNotEmpty;

  bool get _hasHabitsContent =>
      _smokingStatus.isNotEmpty ||
      _alcoholStatus.isNotEmpty ||
      _otherHabitsController.text.trim().isNotEmpty;

  bool get _hasFunctionalContent =>
      _selectedMets.isNotEmpty || _metsNotesController.text.trim().isNotEmpty;

  bool get _hasFunctionalRisk {
    return switch (_selectedPopulation) {
      PatientPopulation.adult =>
        _selectedMets == '1 MET' || _selectedMets == '2-3 METs',
      PatientPopulation.pediatric => _selectedMets == 'Limitação importante',
      PatientPopulation.neonatal =>
        _selectedMets == 'Oxigênio recente' ||
            _selectedMets == 'Apneia/bradicardia' ||
            _selectedMets == 'Suporte ventilatório',
    };
  }

  bool get _hasAsaContent =>
      _selectedAsa.isNotEmpty || _asaNotesController.text.trim().isNotEmpty;

  bool get _hasHighRiskAsa => switch (_selectedAsa) {
    'III' || 'IV' || 'V' || 'VI' => true,
    _ => false,
  };

  bool get _hasAirwayContent =>
      _selectedMallampati.isNotEmpty ||
      _selectedMouthOpening.isNotEmpty ||
      _selectedNeckMobility.isNotEmpty ||
      _selectedDentition.isNotEmpty ||
      _selectedAirwayAssessmentFindings.isNotEmpty ||
      _selectedDifficultAirwayPredictors.isNotEmpty ||
      _selectedDifficultIntubationPredictors.isNotEmpty ||
      _selectedDifficultVentilationPredictors.isNotEmpty ||
      _otherDifficultAirwayPredictorsController.text.trim().isNotEmpty ||
      _otherDifficultVentilationPredictorsController.text.trim().isNotEmpty ||
      _otherAirwayController.text.trim().isNotEmpty;

  bool get _hasAirwayRisk =>
      _selectedMallampati == 'III' ||
      _selectedMallampati == 'IV' ||
      _selectedMouthOpening == '< 2 dedos (< 3 cm)' ||
      _selectedMouthOpening == 'Reduzida' ||
      _selectedMouthOpening == 'Muito reduzida' ||
      _selectedNeckMobility == 'Limitada' ||
      _selectedNeckMobility == 'Muito limitada' ||
      _selectedDentition == 'Prótese móvel' ||
      _selectedDentition == 'Dentição frágil' ||
      _selectedDentition == 'Dente móvel' ||
      _selectedDentition == 'Aparelho ortodôntico' ||
      _selectedAirwayAssessmentFindings.isNotEmpty ||
      _selectedDifficultAirwayPredictors.isNotEmpty ||
      _selectedDifficultIntubationPredictors.isNotEmpty ||
      _selectedDifficultVentilationPredictors.isNotEmpty ||
      _otherDifficultAirwayPredictorsController.text.trim().isNotEmpty ||
      _otherDifficultVentilationPredictorsController.text.trim().isNotEmpty ||
      _otherAirwayController.text.trim().isNotEmpty;

  bool get _hasPostoperativePlanningContent =>
      _selectedPostoperativePlanningItems.isNotEmpty ||
      _otherPostoperativePlanningController.text.trim().isNotEmpty;

  bool get _hasRestrictionContent =>
      _selectedRestrictions.isNotEmpty ||
      _otherRestrictionsController.text.trim().isNotEmpty;

  bool get _hasSurgeryClearanceAlert =>
      _selectedSurgeryClearanceStatus.isNotEmpty &&
      _selectedSurgeryClearanceStatus != 'Cirurgia liberada';

  Widget _buildAdaptiveInputField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int minLines = 1,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasContent = value.text.trim().isNotEmpty;
        final accentColor = hasContent
            ? const Color(0xFF168B79)
            : const Color(0xFFBCD0E4);
        final fillColor = hasContent ? const Color(0xFFF1FBF6) : Colors.white;
        final labelColor = hasContent
            ? const Color(0xFF177245)
            : const Color(0xFF5F7288);

        return TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          minLines: minLines,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            labelStyle: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: fillColor,
            prefixIcon: hasContent
                ? const Icon(Icons.check_circle, color: Color(0xFF168B79))
                : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentColor, width: 1.6),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? color.withAlpha(18) : Colors.white,
        side: BorderSide(color: selected ? color : const Color(0xFFD6E1ED)),
        foregroundColor: selected ? color : const Color(0xFF4F6378),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  void _toggleSurgeryClearanceNoteOption(String option) {
    final lines = _surgeryClearanceNotesController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.contains(option)) {
      lines.remove(option);
    } else {
      lines.add(option);
    }
    _surgeryClearanceNotesController.text = lines.join('\n');
    _surgeryClearanceNotesController.selection = TextSelection.collapsed(
      offset: _surgeryClearanceNotesController.text.length,
    );
    setState(() {});
  }

  Widget _buildSummaryBanner(
    String summary, {
    _SectionCardTone tone = _SectionCardTone.completed,
  }) {
    final backgroundColor = switch (tone) {
      _SectionCardTone.completed => const Color(0xFFF4FBF6),
      _SectionCardTone.alert => const Color(0xFFFFF1F1),
      _SectionCardTone.neutral => const Color(0xFFF5F7FC),
    };
    final borderColor = switch (tone) {
      _SectionCardTone.completed => const Color(0xFFBFE3C9),
      _SectionCardTone.alert => const Color(0xFFE29B9B),
      _SectionCardTone.neutral => const Color(0xFFDCE6F2),
    };
    final textColor = switch (tone) {
      _SectionCardTone.completed => const Color(0xFF177245),
      _SectionCardTone.alert => const Color(0xFFB04141),
      _SectionCardTone.neutral => const Color(0xFF17324D),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        summary,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildComplementaryExamsSummaryPanel() {
    final selectedItems = _profileComplementaryExamOptions
        .where(_selectedExamItems.contains)
        .toList();
    final otherText = _otherComplementaryExamsController.text.trim();
    if (selectedItems.isEmpty && otherText.isEmpty) {
      return _buildSummaryBanner(_complementaryExamsSummary());
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFE3C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecionados',
            style: TextStyle(
              color: Color(0xFF177245),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (selectedItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedItems.map((exam) {
                final entry = _complementaryExamEntries[exam];
                final isAltered = entry?.status == 'alterado';
                final hasNote =
                    entry?.noteController.text.trim().isNotEmpty ?? false;
                final label = isAltered
                    ? (hasNote
                          ? '$exam • Alterado: ${entry!.noteController.text.trim()}'
                          : '$exam • Alterado')
                    : '$exam • Dentro da normalidade';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isAltered
                        ? const Color(0xFFFFF1F1)
                        : const Color(0xFFEAF8EF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isAltered
                          ? const Color(0xFFE29B9B)
                          : const Color(0xFFBFE3C9),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isAltered
                          ? const Color(0xFFB04141)
                          : const Color(0xFF177245),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (otherText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Outros: $otherText',
              style: const TextStyle(
                color: Color(0xFF4F6378),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _joinSummaryParts(Iterable<String> parts) {
    return parts
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join(' • ');
  }

  String _surgerySummary() {
    final parts = [
      _joinSummaryParts(
        commonProcedureOptions.where(_selectedProcedures.contains),
      ),
      _joinSummaryParts(_lines(_otherProceduresController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Selecione a cirurgia' : summary;
  }

  String _identificationSummary() {
    final ageLabel = _selectedPopulation == PatientPopulation.neonatal
        ? 'Idade pós-natal'
        : 'Idade';
    final ageValue = _selectedPopulation == PatientPopulation.neonatal
        ? _postnatalAgeController.text.trim()
        : _ageController.text.trim();
    final parts = <String>[
      _selectedPopulation.label,
      _nameController.text.trim(),
      _consultationDateController.text.trim(),
      if (ageValue.isNotEmpty) '$ageLabel: $ageValue',
      if (_weightController.text.trim().isNotEmpty)
        'Peso: ${_weightController.text.trim()} kg',
      if (_heightController.text.trim().isNotEmpty)
        'Altura: ${_heightController.text.trim()} cm',
      if (_selectedPopulation == PatientPopulation.pediatric &&
          _postnatalAgeController.text.trim().isNotEmpty)
        'Idade pós-natal: ${_postnatalAgeController.text.trim()}',
      if (_selectedPopulation == PatientPopulation.neonatal &&
          _birthWeightController.text.trim().isNotEmpty)
        'Peso ao nascer: ${_birthWeightController.text.trim()} kg',
      if (_selectedPopulation == PatientPopulation.neonatal &&
          _gestationalAgeController.text.trim().isNotEmpty)
        'IG: ${_gestationalAgeController.text.trim()}',
      if (_selectedPopulation == PatientPopulation.neonatal &&
          _correctedGestationalAgeController.text.trim().isNotEmpty)
        'IG corrigida: ${_correctedGestationalAgeController.text.trim()}',
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Preencha a identificação do paciente' : summary;
  }

  String _prioritySummary() {
    final parts = [
      _selectedSurgeryPriority,
      _joinSummaryParts(_lines(_freeNotesController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Selecione a prioridade' : summary;
  }

  String _requestsSummary() {
    final parts = [
      _joinSummaryParts(_selectedAnesthesiaTeamRequestItems),
      _joinSummaryParts(_lines(_anesthesiaTeamRequestNotesController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Selecione solicitações ou exames' : summary;
  }

  String _clearanceSummary() {
    final parts = [
      _selectedSurgeryClearanceStatus,
      _joinSummaryParts(_lines(_surgeryClearanceNotesController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Defina a situação da cirurgia' : summary;
  }

  String _fastingSummary() {
    final parts = [
      _selectedSolidFasting,
      _selectedLiquidFasting,
      _selectedBreastMilkFasting,
      _joinSummaryParts(_lines(_fastingNotesController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Defina o jejum recomendado' : summary;
  }

  String _anestheticPlanSummary() {
    final parts = [
      _joinSummaryParts(_selectedAnestheticPlans),
      _joinSummaryParts(_lines(_otherAnestheticPlanController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Selecione o provável tipo de anestesia' : summary;
  }

  String _antecedentsSummary() {
    final parts = [
      _joinSummaryParts(_selectedComorbidities),
      _joinSummaryParts(_lines(_otherComorbiditiesController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Selecione antecedentes relevantes' : summary;
  }

  String _medicationsSummary() {
    final parts = [
      _joinSummaryParts(_selectedMedications),
      _joinSummaryParts(_lines(_otherMedicationsController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Selecione medicações em uso' : summary;
  }

  String _allergySummary() {
    final summary = _allergyController.text.trim();
    return summary.isEmpty ? 'Sem alergias' : summary;
  }

  String _habitsSummary() {
    final parts = [
      _smokingStatus,
      _alcoholStatus,
      _joinSummaryParts(_lines(_otherHabitsController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Selecione hábitos relevantes' : summary;
  }

  String _functionalSummary() {
    final parts = [
      _selectedMets,
      _joinSummaryParts(_lines(_metsNotesController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Selecione a capacidade funcional' : summary;
  }

  String _asaSummary() {
    final parts = [
      _selectedAsa,
      _joinSummaryParts(_lines(_asaNotesController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Selecione a classificação ASA' : summary;
  }

  String _physicalExamSummary() {
    final parts = <String>[
      if (_acController.text.trim().isNotEmpty)
        'AC ${_acController.text.trim()}',
      if (_fcController.text.trim().isNotEmpty)
        'FC ${_fcController.text.trim()}',
      if (_pasController.text.trim().isNotEmpty)
        'PAS ${_pasController.text.trim()}',
      if (_padController.text.trim().isNotEmpty)
        'PAD ${_padController.text.trim()}',
      if (_apController.text.trim().isNotEmpty)
        'AP ${_apController.text.trim()}',
      _joinSummaryParts(_lines(_physicalExamController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Preencha o exame físico' : summary;
  }

  String _airwaySummary() {
    final riskParts = [
      if (_selectedDifficultIntubationPredictors.isNotEmpty)
        'Intubação difícil: ${_joinSummaryParts(_selectedDifficultIntubationPredictors)}',
      if (_selectedDifficultVentilationPredictors.isNotEmpty)
        'Ventilação difícil: ${_joinSummaryParts(_selectedDifficultVentilationPredictors)}',
      if (_otherDifficultAirwayPredictorsController.text.trim().isNotEmpty)
        'Preditores adicionais: ${_joinSummaryParts(_lines(_otherDifficultAirwayPredictorsController.text))}',
      if (_otherDifficultVentilationPredictorsController.text.trim().isNotEmpty)
        'Ventilação difícil adicional: ${_joinSummaryParts(_lines(_otherDifficultVentilationPredictorsController.text))}',
    ];
    if (riskParts.isNotEmpty) {
      return _joinSummaryParts(riskParts);
    }

    final assessmentParts = [
      if (_selectedMallampati.isNotEmpty) 'Mallampati $_selectedMallampati',
      if (_selectedMouthOpening.isNotEmpty)
        '$_mouthOpeningLabel: $_selectedMouthOpening',
      if (_selectedNeckMobility.isNotEmpty)
        'Mobilidade cervical: $_selectedNeckMobility',
      if (_selectedDentition.isNotEmpty)
        '$_dentitionLabel: $_selectedDentition',
      _joinSummaryParts(_lines(_otherAirwayController.text)),
    ];
    final summary = _joinSummaryParts(assessmentParts);
    return summary.isEmpty ? 'Selecione os achados da via aérea' : summary;
  }

  String _postoperativePlanningSummary() {
    final parts = [
      _joinSummaryParts(_selectedPostoperativePlanningItems),
      _joinSummaryParts(_lines(_otherPostoperativePlanningController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty
        ? 'Selecione o planejamento pós-operatório'
        : summary;
  }

  String _restrictionSummary() {
    final parts = [
      _joinSummaryParts(_selectedRestrictions),
      _joinSummaryParts(_lines(_otherRestrictionsController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty ? 'Selecione restrições ou preferências' : summary;
  }

  String _preAnestheticOrientationSummary() {
    final parts = [
      _joinSummaryParts(_selectedPreAnestheticOrientationItems),
      _joinSummaryParts(_orientationFreeTextItems),
      _joinSummaryParts(_lines(_preAnestheticOrientationNotesController.text)),
    ];
    final summary = _joinSummaryParts(parts);
    return summary.isEmpty
        ? 'Selecione as orientações pré-anestésicas'
        : summary;
  }

  String _complementaryExamsSummary() {
    final selected = _selectedExamItems.isEmpty
        ? ''
        : _joinSummaryParts(
            _profileComplementaryExamOptions.where(_selectedExamItems.contains),
          );
    final alteredNotes = _profileComplementaryExamOptions
        .map((exam) {
          final entry = _complementaryExamEntries[exam];
          if (entry == null || entry.status != 'alterado') {
            return '';
          }
          final note = entry.noteController.text.trim();
          return note.isEmpty ? exam : '$exam: $note';
        })
        .where((item) => item.isNotEmpty)
        .join(' • ');
    final other = _joinSummaryParts(
      _lines(_otherComplementaryExamsController.text),
    );
    final summary = _joinSummaryParts([selected, alteredNotes, other]);
    return summary.isEmpty ? 'Selecione exames complementares' : summary;
  }
}

enum _SectionCardTone { neutral, completed, alert }

class _ExpandablePresetFieldCard extends StatefulWidget {
  const _ExpandablePresetFieldCard({
    required this.controller,
    required this.label,
    required this.presetOptions,
    required this.onSelected,
    required this.color,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final List<String> presetOptions;
  final ValueChanged<String> onSelected;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Color color;

  @override
  State<_ExpandablePresetFieldCard> createState() =>
      _ExpandablePresetFieldCardState();
}

class _ExpandablePresetFieldCardState
    extends State<_ExpandablePresetFieldCard> {
  late final ExpansibleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExpansibleController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final text = value.text.trim();
        final hasContent = text.isNotEmpty;
        final borderColor = hasContent
            ? const Color(0xFF8DD0A3)
            : const Color(0xFFDCE6F2);
        final headerColor = hasContent
            ? const Color(0xFFE7F6EC)
            : const Color(0xFFF5F7FC);
        final titleColor = hasContent
            ? const Color(0xFF177245)
            : const Color(0xFF17324D);

        return TapRegion(
          onTapOutside: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
            _controller.collapse();
          },
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: borderColor),
            ),
            elevation: 0,
            child: ExpansionTile(
              controller: _controller,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              backgroundColor: headerColor,
              collapsedBackgroundColor: headerColor,
              iconColor: titleColor,
              collapsedIconColor: titleColor,
              title: Text(
                widget.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              subtitle: Text(
                hasContent ? text : 'Toque para selecionar ou digitar',
                style: TextStyle(
                  color: hasContent
                      ? titleColor.withAlpha(180)
                      : const Color(0xFF5D7288),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Valores pré-determinados',
                  style: TextStyle(
                    color: Color(0xFF17324D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPresetOptionCardGrid(
                  options: widget.presetOptions,
                  isSelected: (option) => text == option,
                  onTap: widget.onSelected,
                  color: widget.color,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.controller,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  decoration: InputDecoration(
                    labelText: 'Outro valor',
                    hintText: widget.hintText ?? 'Digite um valor',
                    filled: true,
                    fillColor: hasContent
                        ? const Color(0xFFF1FBF6)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: widget.color, width: 1.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetOptionCardGrid({
    required List<String> options,
    required bool Function(String option) isSelected,
    required ValueChanged<String> onTap,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 2 : 1;
        final columnChildren = List.generate(columns, (_) => <Widget>[]);

        for (var i = 0; i < options.length; i++) {
          final option = options[i];
          final selected = isSelected(option);
          columnChildren[i % columns].add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPresetOptionCard(
                label: option,
                selected: selected,
                onTap: () => onTap(option),
                color: color,
              ),
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns; i++) ...[
              Expanded(child: Column(children: columnChildren[i])),
              if (i != columns - 1) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPresetOptionCard({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final borderColor = selected ? color : const Color(0xFFD5E4F7);
    final backgroundColor = selected ? color.withAlpha(12) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A17324D),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF26384A),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatefulWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.isCompleted = false,
    this.controller,
    this.summary,
    this.tone,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final bool isCompleted;
  final ExpansibleController? controller;
  final String? summary;
  final _SectionCardTone? tone;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  ExpansibleController? _ownedController;

  ExpansibleController get _effectiveController =>
      widget.controller ?? (_ownedController ??= ExpansibleController());

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone =
        widget.tone ??
        (widget.isCompleted
            ? _SectionCardTone.completed
            : _SectionCardTone.neutral);
    final borderColor = switch (tone) {
      _SectionCardTone.completed => const Color(0xFF8DD0A3),
      _SectionCardTone.alert => const Color(0xFFE29B9B),
      _SectionCardTone.neutral => const Color(0xFFDCE6F2),
    };
    final headerColor = switch (tone) {
      _SectionCardTone.completed => const Color(0xFFE7F6EC),
      _SectionCardTone.alert => const Color(0xFFFFF1F1),
      _SectionCardTone.neutral => const Color(0xFFF5F7FC),
    };
    final titleColor = switch (tone) {
      _SectionCardTone.completed => const Color(0xFF177245),
      _SectionCardTone.alert => const Color(0xFFB04141),
      _SectionCardTone.neutral => const Color(0xFF17324D),
    };
    final cardColor = switch (tone) {
      _SectionCardTone.completed => const Color(0xFFF4FBF6),
      _SectionCardTone.alert => const Color(0xFFFFF7F7),
      _SectionCardTone.neutral => null,
    };

    return TapRegion(
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
        _effectiveController.collapse();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor),
        ),
        color: cardColor,
        elevation: 0,
        child: ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          controller: _effectiveController,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          backgroundColor: headerColor,
          collapsedBackgroundColor: headerColor,
          iconColor: titleColor,
          collapsedIconColor: titleColor,
          title: Text(
            widget.title,
            style: TextStyle(fontWeight: FontWeight.w800, color: titleColor),
          ),
          subtitle: widget.summary == null || widget.summary!.trim().isEmpty
              ? null
              : Text(
                  widget.summary!,
                  style: TextStyle(
                    color: titleColor.withAlpha(180),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          children: [widget.child],
        ),
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

class _ComplementaryExamEntry {
  _ComplementaryExamEntry({String note = ''})
    : status = '',
      noteController = TextEditingController(text: note);

  String status;
  final TextEditingController noteController;

  void dispose() {
    noteController.dispose();
  }
}
