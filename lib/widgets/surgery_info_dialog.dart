import 'package:flutter/material.dart';

import '../models/patient.dart';
import 'anesthesia_basic_dialogs.dart';

class SurgeryInfoDialogResult {
  const SurgeryInfoDialogResult({
    required this.description,
    required this.priority,
    required this.surgeon,
    required this.assistants,
    required this.destination,
    required this.otherDestination,
    required this.notes,
    required this.checklist,
    required this.timeOutChecklist,
    required this.timeOutCompleted,
  });

  final String description;
  final String priority;
  final String surgeon;
  final List<String> assistants;
  final String destination;
  final String otherDestination;
  final String notes;
  final List<String> checklist;
  final List<String> timeOutChecklist;
  final bool timeOutCompleted;
}

const List<String> commonProcedureOptions = [
  'Histerectomia por vídeo',
  'Histerectomia',
  'Histerectomia abdominal',
  'Histerectomia vaginal',
  'Miomectomia',
  'Vídeo colecistectomia',
  'Colecistectomia',
  'Bariátrica sleeve',
  'Bariátrica by pass',
  'Nefrectomia por vídeo direita',
  'Nefrectomia por vídeo esquerda',
  'Nefrectomia direita',
  'Nefrectomia esquerda',
  'Herniorrafia umbilical',
  'Herniorrafia incisional',
  'Herniorrafia inguinal direita',
  'Herniorrafia inguinal esquerda',
  'Herniorrafia inguinal bilateral',
  'Herniorrafia inguinal direita por vídeo',
  'Herniorrafia inguinal esquerda por vídeo',
  'Herniorrafia inguinal bilateral por vídeo',
  'Hernioplastia ventral',
  'Hernioplastia epigástrica',
  'Fratura de fêmur direito',
  'Fratura de fêmur esquerdo',
  'Fratura de rádio distal direito',
  'Fratura de rádio distal esquerdo',
  'Fratura de tornozelo direito',
  'Fratura de tornozelo esquerdo',
  'Apendicectomia por vídeo',
  'Apendicectomia',
  'Cesárea',
  'Mastectomia',
  'Quadrantectomia',
  'Setorectomia de mama',
  'Prótese de mama',
  'Troca de prótese de mama',
  'Mamoplastia redutora',
  'Mastopexia',
  'Abdominoplastia',
  'Lipoaspiração',
  'Lipoescultura',
  'Ritidoplastia',
  'Blefaroplastia',
  'Rinoplastia',
  'Septoplastia',
  'Sinusectomia endoscópica',
  'Artroscopia de joelho',
  'Artroscopia de ombro',
  'Artroplastia total de joelho',
  'Artroplastia total de quadril',
  'Fixação de fratura de rádio distal',
  'Osteossíntese de tíbia',
  'Tireoidectomia',
  'Paratireoidectomia',
  'Amigdalectomia',
  'Adenoidectomia',
  'Hemorroidectomia',
  'Fissurectomia anal',
  'Colecistostomia',
  'Laparotomia exploradora',
  'Videolaparoscopia diagnóstica',
  'RTU de bexiga',
  'Varicocelectomia',
  'Orquidopexia',
  'RTU de próstata',
  'Cistoscopia',
  'Ureterolitotripsia',
  'Postectomia',
  'Vasectomia',
];

enum SurgeryInfoSection {
  all,
  description,
  priority,
  surgeon,
  assistants,
  destination,
  notes,
  checklist,
  timeOut,
}

class SurgeryInfoDialog extends StatefulWidget {
  const SurgeryInfoDialog({
    super.key,
    required this.section,
    required this.initialDescription,
    required this.initialPriority,
    required this.initialSurgeon,
    required this.initialAssistants,
    required this.initialDestination,
    required this.initialOtherDestination,
    required this.initialNotes,
    required this.initialChecklist,
    required this.initialTimeOutChecklist,
    required this.initialTimeOutCompleted,
    required this.patientPopulation,
  });

  final SurgeryInfoSection section;
  final String initialDescription;
  final String initialPriority;
  final String initialSurgeon;
  final List<String> initialAssistants;
  final String initialDestination;
  final String initialOtherDestination;
  final String initialNotes;
  final List<String> initialChecklist;
  final List<String> initialTimeOutChecklist;
  final bool initialTimeOutCompleted;
  final PatientPopulation patientPopulation;

  @override
  State<SurgeryInfoDialog> createState() => _SurgeryInfoDialogState();
}

class _SurgeryInfoDialogState extends State<SurgeryInfoDialog> {
  static const List<String> _priorityOptions = [
    'Eletiva',
    'Urgência',
    'Emergência',
  ];
  static const List<String> _safeChecklistOptions = [
    'Paciente identificado',
    'Procedimento confirmado',
    'Lado / sitio cirurgico confirmado',
    'Termo de consentimento assinado',
    'Alergias conferidas',
    'Jejum confirmado',
    'Equipamento de anestesia checado',
    'Materiais para intubação disponíveis e testados',
    'Pré-anestésico realizado',
    'Monitorização instalada e funcionando',
    'Acesso venoso pérvio',
    'Material para bloqueio / acesso disponível',
    'Antibioticoprofilaxia administrada',
    'Materiais e equipamentos conferidos',
    'Risco de perda sanguinea discutido',
  ];

  static const List<String> _timeOutOptions = [
    'Equipe identificada por nome e funcao',
    'Paciente, procedimento e sitio confirmados',
    'Alergias conferidas',
    'Antibioticoprofilaxia realizada no tempo correto',
    'Exames e imagens disponiveis',
    'Risco hemorragico discutido',
    'Plano anestesico e via aerea discutidos',
    'Instrumentais e equipamentos conferidos',
  ];

  late final TextEditingController _otherProceduresController;
  late final TextEditingController _surgeonController;
  late final TextEditingController _assistantsController;
  late final TextEditingController _otherDestinationController;
  late final TextEditingController _notesController;
  late Set<String> _selectedProcedures;
  late String _selectedPriority;
  late String _selectedDestination;
  late Set<String> _selectedChecklist;
  late Set<String> _selectedTimeOutChecklist;
  late bool _timeOutCompleted;

  List<String> get _destinationOptions {
    return switch (widget.patientPopulation) {
      PatientPopulation.adult => const ['RPA', 'Enfermaria', 'UTI'],
      PatientPopulation.pediatric => const [
        'RPA pediátrica',
        'Enfermaria pediátrica',
        'UTI pediátrica',
      ],
      PatientPopulation.neonatal => const [
        'UTI neonatal',
        'UCIN',
        'Recuperação monitorizada',
        'Alojamento conjunto',
      ],
    };
  }

  @override
  void initState() {
    super.initState();
    final initialProcedures = _lines(widget.initialDescription);
    final selectedProcedures = initialProcedures
        .where(commonProcedureOptions.contains)
        .toSet();
    final otherProcedures = initialProcedures
        .where((item) => !commonProcedureOptions.contains(item))
        .join('\n');

    _otherProceduresController = TextEditingController(text: otherProcedures);
    _surgeonController = TextEditingController(text: widget.initialSurgeon);
    _assistantsController = TextEditingController(
      text: widget.initialAssistants.join('\n'),
    );
    _otherDestinationController = TextEditingController(
      text: widget.initialOtherDestination,
    );
    _notesController = TextEditingController(text: widget.initialNotes);
    _selectedProcedures = selectedProcedures;
    _selectedPriority = widget.initialPriority;
    _selectedDestination = widget.initialDestination;
    _selectedChecklist = widget.initialChecklist.toSet();
    _selectedTimeOutChecklist = widget.initialTimeOutChecklist.toSet();
    _timeOutCompleted = widget.initialTimeOutCompleted;
  }

  @override
  void dispose() {
    _otherProceduresController.dispose();
    _surgeonController.dispose();
    _assistantsController.dispose();
    _otherDestinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> _lines(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _buildProcedureLines() {
    return [
      ...commonProcedureOptions.where(_selectedProcedures.contains),
      ..._lines(_otherProceduresController.text),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final showDescription =
        widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.description;
    final showPriority =
        widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.priority;
    final showSurgeon =
        widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.surgeon;
    final showAssistants =
        widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.assistants;
    final showDestination =
        widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.destination;
    final showNotes =
        widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.notes;
    final showChecklist =
        widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.checklist;
    final showTimeOut =
        widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.timeOut;

    final title = switch (widget.section) {
      SurgeryInfoSection.description => 'Cirurgia',
      SurgeryInfoSection.priority => 'Tipo de cirurgia',
      SurgeryInfoSection.surgeon => 'Cirurgião',
      SurgeryInfoSection.assistants => 'Auxiliares',
      SurgeryInfoSection.destination => 'Destino pós-operatório',
      SurgeryInfoSection.notes => 'Anotações relevantes',
      SurgeryInfoSection.checklist => 'Preparação da sala e checklist inicial',
      SurgeryInfoSection.timeOut => 'Time-out',
      SurgeryInfoSection.all => 'Cirurgia e checklist',
    };

    return AlertDialog(
      backgroundColor: const Color(0xFFF3F6FC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      titlePadding: const EdgeInsets.fromLTRB(56, 40, 56, 0),
      contentPadding: const EdgeInsets.fromLTRB(56, 28, 56, 24),
      actionsPadding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1F2630),
        ),
      ),
      content: SizedBox(
        width: 1120,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDescription)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Principais cirurgias',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (showDescription) const SizedBox(height: 8),
              if (showDescription)
                SelectionGridSection(
                  options: commonProcedureOptions,
                  color: const Color(0xFF2B76D2),
                  isSelected: (item) => _selectedProcedures.contains(item),
                  onToggle: (item) {
                    setState(() {
                      if (_selectedProcedures.contains(item)) {
                        _selectedProcedures.remove(item);
                      } else {
                        _selectedProcedures.add(item);
                      }
                    });
                  },
                ),
              if (showDescription) const SizedBox(height: 14),
              if (showDescription)
                TextField(
                  key: const Key('surgery-description-field'),
                  controller: _otherProceduresController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Outras',
                    hintText: 'Uma cirurgia / procedimento por linha',
                  ),
                ),
              if (showDescription &&
                  (showPriority ||
                      showSurgeon ||
                      showAssistants ||
                      showDestination ||
                      showNotes ||
                      showChecklist))
                const SizedBox(height: 12),
              if (showPriority)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tipo de cirurgia',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (showPriority) const SizedBox(height: 8),
              if (showPriority)
                SelectionGridSection(
                  options: _priorityOptions,
                  searchEnabled: false,
                  isSelected: (item) => _selectedPriority == item,
                  onToggle: (item) {
                    setState(() {
                      _selectedPriority = _selectedPriority == item ? '' : item;
                    });
                  },
                ),
              if (showPriority &&
                  (showSurgeon ||
                      showAssistants ||
                      showDestination ||
                      showNotes ||
                      showChecklist))
                const SizedBox(height: 12),
              if (showSurgeon)
                TextField(
                  key: const Key('surgery-surgeon-field'),
                  controller: _surgeonController,
                  decoration: const InputDecoration(labelText: 'Cirurgião'),
                ),
              if (showSurgeon &&
                  (showAssistants ||
                      showDestination ||
                      showNotes ||
                      showChecklist))
                const SizedBox(height: 12),
              if (showAssistants)
                TextField(
                  key: const Key('surgery-assistants-field'),
                  controller: _assistantsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Auxiliares',
                    hintText: 'Um por linha',
                  ),
                ),
              if (showAssistants &&
                  (showDestination ||
                      showNotes ||
                      showChecklist ||
                      showTimeOut))
                const SizedBox(height: 16),
              if (showDestination)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Destino pós-operatório',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (showDestination) const SizedBox(height: 10),
              if (showDestination)
                SelectionGridSection(
                  options: _destinationOptions,
                  searchEnabled: false,
                  isSelected: (item) => _selectedDestination == item,
                  onToggle: (item) {
                    setState(() {
                      _selectedDestination = _selectedDestination == item
                          ? ''
                          : item;
                    });
                  },
                ),
              if (showDestination) const SizedBox(height: 12),
              if (showDestination)
                TextField(
                  key: const Key('surgery-other-destination-field'),
                  controller: _otherDestinationController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Outro destino / detalhes',
                    hintText:
                        'Ex: observação prolongada, transporte ventilado, sala híbrida',
                  ),
                ),
              if (showDestination &&
                  (showNotes || showChecklist || showTimeOut))
                const SizedBox(height: 16),
              if (showNotes)
                TextField(
                  key: const Key('surgery-notes-field'),
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Anotações relevantes',
                    hintText:
                        'Ex: condições de chegada ao centro cirúrgico, cirurgia suspensa e motivo, intercorrências logísticas, observações relevantes',
                  ),
                ),
              if (showNotes && (showChecklist || showTimeOut))
                const SizedBox(height: 16),
              if (showChecklist)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Checklist de cirurgia segura',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (showChecklist) const SizedBox(height: 10),
              if (showChecklist)
                SelectionGridSection(
                  options: _safeChecklistOptions,
                  searchEnabled: false,
                  isSelected: (item) => _selectedChecklist.contains(item),
                  onToggle: (item) {
                    setState(() {
                      if (_selectedChecklist.contains(item)) {
                        _selectedChecklist.remove(item);
                      } else {
                        _selectedChecklist.add(item);
                      }
                    });
                  },
                ),
              if (showChecklist && showTimeOut) const SizedBox(height: 18),
              if (showTimeOut)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Etapa de time-out',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (showTimeOut) const SizedBox(height: 10),
              if (showTimeOut)
                SelectionGridSection(
                  options: _timeOutOptions,
                  searchEnabled: false,
                  isSelected: (item) =>
                      _selectedTimeOutChecklist.contains(item),
                  onToggle: (item) {
                    setState(() {
                      if (_selectedTimeOutChecklist.contains(item)) {
                        _selectedTimeOutChecklist.remove(item);
                      } else {
                        _selectedTimeOutChecklist.add(item);
                      }
                      if (_selectedTimeOutChecklist.length !=
                          _timeOutOptions.length) {
                        _timeOutCompleted = false;
                      }
                    });
                  },
                ),
              if (showTimeOut) const SizedBox(height: 14),
              if (showTimeOut)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('surgery-complete-timeout-button'),
                    onPressed:
                        _selectedTimeOutChecklist.length ==
                            _timeOutOptions.length
                        ? () {
                            setState(() {
                              _timeOutCompleted = true;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      _timeOutCompleted
                          ? 'Time-out finalizado'
                          : 'Finalizar time-out',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3C6C9C),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF3C6C9C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          key: const Key('surgery-save-button'),
          onPressed: () => Navigator.of(context).pop(
            SurgeryInfoDialogResult(
              description: _buildProcedureLines().join('\n'),
              priority: _selectedPriority,
              surgeon: _surgeonController.text.trim(),
              assistants: _lines(_assistantsController.text),
              destination: _selectedDestination,
              otherDestination: _otherDestinationController.text.trim(),
              notes: _notesController.text.trim(),
              checklist: _selectedChecklist.toList(),
              timeOutChecklist: _selectedTimeOutChecklist.toList(),
              timeOutCompleted: _timeOutCompleted,
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
