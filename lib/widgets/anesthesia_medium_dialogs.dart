import 'package:flutter/material.dart';

import '../models/patient.dart';
import 'anesthesia_basic_dialogs.dart';

class TechniqueDialogResult {
  const TechniqueDialogResult({required this.technique, required this.details});

  final String technique;
  final String details;
}

class MonitoringDialog extends StatefulWidget {
  const MonitoringDialog({
    super.key,
    required this.initialItems,
    required this.patient,
  });

  final List<String> initialItems;
  final Patient patient;

  @override
  State<MonitoringDialog> createState() => _MonitoringDialogState();
}

class _MonitoringDialogState extends State<MonitoringDialog> {
  static const List<String> _availableItems = [
    'ECG (5 derivações)',
    'PA não invasiva',
    'PAI',
    'SpO₂',
    'Capnografia',
    'Temperatura',
    'BIS',
  ];

  late List<String> _selectedItems;
  late final TextEditingController _otherItemsController;

  List<String> get _recommendedItems {
    switch (widget.patient.population) {
      case PatientPopulation.adult:
        return const [
          'ECG (5 derivações)',
          'PA não invasiva',
          'SpO₂',
          'Capnografia',
          'Temperatura',
        ];
      case PatientPopulation.pediatric:
        return const [
          'ECG (5 derivações)',
          'PA não invasiva',
          'SpO₂',
          'Capnografia',
          'Temperatura',
        ];
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

  String get _recommendationTitle {
    return switch (widget.patient.population) {
      PatientPopulation.adult => 'Sugestão intraoperatória',
      PatientPopulation.pediatric => 'Sugestão pediátrica',
      PatientPopulation.neonatal => 'Sugestão neonatal',
    };
  }

  List<String> get _recommendationLines {
    switch (widget.patient.population) {
      case PatientPopulation.adult:
        return const [
          'Usar ECG, PA não invasiva, SpO₂ e capnografia durante anestesia geral.',
          'Temperatura é recomendada quando houver risco de alteração térmica clinicamente relevante.',
        ];
      case PatientPopulation.pediatric:
        return const [
          'Monitorização básica intraoperatória: ECG, PA não invasiva, SpO₂, capnografia e temperatura.',
          'Temperatura contínua ganha maior importância em lactentes e crianças pequenas.',
        ];
      case PatientPopulation.neonatal:
        return const [
          'Monitorização básica neonatal: ECG, PA não invasiva, SpO₂, capnografia e temperatura.',
          'Temperatura e ventilação merecem vigilância reforçada no neonato.',
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedItems = List<String>.from(widget.initialItems);
    _otherItemsController = TextEditingController(
      text: widget.initialItems
          .where((item) => !_availableItems.contains(item))
          .join('\n'),
    );
  }

  @override
  void dispose() {
    _otherItemsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Monitorização'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      _recommendationTitle,
                      style: const TextStyle(
                        color: Color(0xFF2B76D2),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._recommendationLines.map(
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
              SelectionGridSection(
                options: _availableItems,
                color: const Color(0xFF2B76D2),
                optionDescriptionBuilder: (item) =>
                    _recommendedItems.contains(item)
                    ? 'Monitorização recomendada para este perfil.'
                    : null,
                isSelected: (item) => _selectedItems.contains(item),
                onToggle: (item) {
                  setState(() {
                    if (_selectedItems.contains(item)) {
                      _selectedItems.remove(item);
                    } else {
                      _selectedItems.add(item);
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _otherItemsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Outros',
                  hintText: 'Um item por linha',
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
          onPressed: () {
            final customItems = _otherItemsController.text
                .split('\n')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList();
            Navigator.of(context).pop([..._selectedItems, ...customItems]);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class TechniqueDialog extends StatefulWidget {
  const TechniqueDialog({
    super.key,
    required this.initialTechnique,
    required this.patient,
  });

  final String initialTechnique;
  final Patient patient;

  @override
  State<TechniqueDialog> createState() => _TechniqueDialogState();
}

class _TechniqueDialogState extends State<TechniqueDialog> {
  static const List<String> _adultTechniqueOptions = [
    'Anestesia geral balanceada',
    'TIVA',
    'Raquianestesia',
    'Peridural',
    'Bloqueio periférico',
    'Sedação',
  ];
  static const List<String> _pediatricTechniqueOptions = [
    'Anestesia geral inalatória',
    'Anestesia geral venosa',
    'Máscara laríngea',
    'Intubação orotraqueal',
    'Bloqueio caudal/regional',
    'Analgesia multimodal',
  ];
  static const List<String> _neonatalTechniqueOptions = [
    'Anestesia geral balanceada',
    'Intubação orotraqueal',
    'Ventilação controlada',
    'Analgesia opioide titulada',
    'Bloqueio regional selecionado',
    'Plano pós-operatório em UTI',
  ];
  late Set<String> _selectedTechniques;
  late final TextEditingController _otherTechniqueController;

  List<String> get _techniqueOptions {
    switch (widget.patient.population) {
      case PatientPopulation.adult:
        return _adultTechniqueOptions;
      case PatientPopulation.pediatric:
        return _pediatricTechniqueOptions;
      case PatientPopulation.neonatal:
        return _neonatalTechniqueOptions;
    }
  }

  @override
  void initState() {
    super.initState();
    final initialTechniques = widget.initialTechnique
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    _selectedTechniques = initialTechniques
        .where(_techniqueOptions.contains)
        .toSet();
    _otherTechniqueController = TextEditingController(
      text: initialTechniques
          .where((item) => !_techniqueOptions.contains(item))
          .join('\n'),
    );
  }

  @override
  void dispose() {
    _otherTechniqueController.dispose();
    super.dispose();
  }

  List<String> get _allSelectedTechniques => [
    ..._selectedTechniques,
    ..._otherTechniqueController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty),
  ];

  bool _isGeneralTechnique(String technique) {
    final normalized = technique.toLowerCase();
    return normalized.contains('anestesia geral') ||
        normalized.contains('tiva') ||
        normalized.contains('intubação') ||
        normalized.contains('intubacao') ||
        normalized.contains('máscara laríngea') ||
        normalized.contains('mascara laringea') ||
        normalized.contains('ventilação controlada') ||
        normalized.contains('ventilacao controlada');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Técnica anestésica'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SelectionGridSection(
                  options: _techniqueOptions,
                  color: const Color(0xFF8A5DD3),
                  isSelected: (item) => _selectedTechniques.contains(item),
                  onToggle: (item) {
                    setState(() {
                      if (_selectedTechniques.contains(item)) {
                        _selectedTechniques.remove(item);
                      } else {
                        if (!_isGeneralTechnique(item)) {
                          _selectedTechniques.removeWhere(_isGeneralTechnique);
                        }
                        _selectedTechniques.add(item);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('technique-other-technique-field'),
                controller: _otherTechniqueController,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Outros / outras',
                  hintText: 'Uma técnica por linha',
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
          key: const Key('technique-save-button'),
          onPressed: () => Navigator.of(context).pop(
            TechniqueDialogResult(
              technique: _allSelectedTechniques.join('\n'),
              details: '',
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
