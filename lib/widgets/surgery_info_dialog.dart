import 'package:flutter/material.dart';

import '../models/patient.dart';

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
  static const List<String> _commonProcedureOptions = [
    'Histerectomia por vídeo',
    'Histerectomia',
    'Colecistectomia por vídeo',
    'Colecistectomia',
    'Bariátrica sleeve',
    'Bariátrica bypass',
    'Nefrectomia direita',
    'Nefrectomia esquerda',
    'Herniorrafia umbilical',
    'Herniorrafia incisional',
    'Herniorrafia inguinal direita',
    'Herniorrafia inguinal esquerda',
    'Herniorrafia inguinal bilateral por vídeo',
    'Fratura de fêmur direito',
    'Fratura de fêmur esquerdo',
    'Apendicectomia por vídeo',
    'Apendicectomia',
    'Cesárea',
    'Mastectomia',
    'Quadrantectomia',
    'Prótese de mama',
    'Abdominoplastia',
    'Lipoaspiração',
    'Rinoplastia',
    'Septoplastia',
    'Artroscopia de joelho',
    'Artroplastia total de joelho',
    'Artroplastia total de quadril',
    'Tireoidectomia',
    'Amigdalectomia',
  ];
  static const List<String> _priorityOptions = [
    'Eletiva',
    'Urgência',
    'Emergência',
  ];
  static const List<String> _safeChecklistOptions = [
    'Paciente identificado',
    'Procedimento confirmado',
    'Lado / sitio cirurgico confirmado',
    'Consentimento confirmado',
    'Alergias conferidas',
    'Jejum confirmado',
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
        .where(_commonProcedureOptions.contains)
        .toSet();
    final otherProcedures = initialProcedures
        .where((item) => !_commonProcedureOptions.contains(item))
        .join('\n');

    _otherProceduresController = TextEditingController(
      text: otherProcedures,
    );
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
      ..._commonProcedureOptions.where(_selectedProcedures.contains),
      ..._lines(_otherProceduresController.text),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final showDescription = widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.description;
    final showPriority = widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.priority;
    final showSurgeon = widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.surgeon;
    final showAssistants = widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.assistants;
    final showDestination = widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.destination;
    final showNotes = widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.notes;
    final showChecklist = widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.checklist;
    final showTimeOut = widget.section == SurgeryInfoSection.all ||
        widget.section == SurgeryInfoSection.timeOut;

    final title = switch (widget.section) {
      SurgeryInfoSection.description => 'Cirurgia',
      SurgeryInfoSection.priority => 'Tipo de cirurgia',
      SurgeryInfoSection.surgeon => 'Cirurgião',
      SurgeryInfoSection.assistants => 'Auxiliares',
      SurgeryInfoSection.destination => 'Destino pós-operatório',
      SurgeryInfoSection.notes => 'Anotações relevantes',
      SurgeryInfoSection.checklist => 'Protocolo de cirurgia segura',
      SurgeryInfoSection.timeOut => 'Time-out',
      SurgeryInfoSection.all => 'Cirurgia e checklist',
    };

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 620,
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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _commonProcedureOptions
                      .map(
                        (item) => _ProcedureCard(
                          label: item,
                          selected: _selectedProcedures.contains(item),
                          onTap: () {
                            setState(() {
                              if (_selectedProcedures.contains(item)) {
                                _selectedProcedures.remove(item);
                              } else {
                                _selectedProcedures.add(item);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _priorityOptions
                      .map(
                        (item) => ChoiceChip(
                          label: Text(item),
                          selected: _selectedPriority == item,
                          onSelected: (_) {
                            setState(() => _selectedPriority = item);
                          },
                        ),
                      )
                      .toList(),
                ),
              if (showPriority &&
                  (showSurgeon || showAssistants || showDestination || showNotes || showChecklist))
                const SizedBox(height: 12),
              if (showSurgeon)
                TextField(
                  key: const Key('surgery-surgeon-field'),
                  controller: _surgeonController,
                  decoration: const InputDecoration(labelText: 'Cirurgião'),
                ),
              if (showSurgeon &&
                  (showAssistants || showDestination || showNotes || showChecklist))
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
              if (showAssistants && (showDestination || showNotes || showChecklist || showTimeOut))
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _destinationOptions
                      .map(
                        (item) => ChoiceChip(
                          label: Text(item),
                          selected: _selectedDestination == item,
                          onSelected: (_) {
                            setState(() => _selectedDestination = item);
                          },
                        ),
                      )
                      .toList(),
                ),
              if (showDestination) const SizedBox(height: 12),
              if (showDestination)
                TextField(
                  key: const Key('surgery-other-destination-field'),
                  controller: _otherDestinationController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Outro destino / detalhes',
                    hintText: 'Ex: observação prolongada, transporte ventilado, sala híbrida',
                  ),
                ),
              if (showDestination && (showNotes || showChecklist || showTimeOut))
                const SizedBox(height: 16),
              if (showNotes)
                TextField(
                  key: const Key('surgery-notes-field'),
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Anotações relevantes',
                    hintText: 'Ex: condições de chegada ao centro cirúrgico, cirurgia suspensa e motivo, intercorrências logísticas, observações relevantes',
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _safeChecklistOptions
                      .map(
                        (item) => FilterChip(
                          label: Text(item),
                          selected: _selectedChecklist.contains(item),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedChecklist.add(item);
                              } else {
                                _selectedChecklist.remove(item);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timeOutOptions
                      .map(
                        (item) => FilterChip(
                          label: Text(item),
                          selected: _selectedTimeOutChecklist.contains(item),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedTimeOutChecklist.add(item);
                              } else {
                                _selectedTimeOutChecklist.remove(item);
                              }
                              if (_selectedTimeOutChecklist.length !=
                                  _timeOutOptions.length) {
                                _timeOutCompleted = false;
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              if (showTimeOut) const SizedBox(height: 14),
              if (showTimeOut)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('surgery-complete-timeout-button'),
                    onPressed: _selectedTimeOutChecklist.length ==
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
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

class _ProcedureCard extends StatelessWidget {
  const _ProcedureCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 18,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
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
