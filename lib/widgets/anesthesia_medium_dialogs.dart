import 'package:flutter/material.dart';

import '../models/patient.dart';

class TechniqueDialogResult {
  const TechniqueDialogResult({
    required this.technique,
    required this.details,
  });

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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableItems
                    .map(
                      (item) => FilterChip(
                        label: Text(item),
                        selected: _selectedItems.contains(item),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedItems.add(item);
                            } else {
                              _selectedItems.remove(item);
                            }
                          });
                        },
                        selectedColor: const Color(0xFF2B76D2).withAlpha(28),
                        checkmarkColor: const Color(0xFF2B76D2),
                        side: BorderSide(
                          color: _selectedItems.contains(item)
                              ? const Color(0xFF2B76D2)
                              : _recommendedItems.contains(item)
                                  ? const Color(0xFF9CC0EC)
                                  : const Color(0xFFD6E1ED),
                        ),
                        labelStyle: TextStyle(
                          color: _selectedItems.contains(item)
                              ? const Color(0xFF2B76D2)
                              : _recommendedItems.contains(item)
                                  ? const Color(0xFF315E8D)
                                  : const Color(0xFF4F6378),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .toList(),
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
            Navigator.of(context).pop([
              ..._selectedItems,
              ...customItems,
            ]);
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
    required this.initialDetails,
    required this.patient,
  });

  final String initialTechnique;
  final String initialDetails;
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
  late final TextEditingController _detailsController;
  bool _detailsEditedManually = false;

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
    _detailsController = TextEditingController(
      text: widget.initialDetails.trim().isEmpty
          ? _buildSuggestedDetails()
          : widget.initialDetails,
    );
    _detailsController.addListener(() {
      _detailsEditedManually = true;
    });
  }

  @override
  void dispose() {
    _otherTechniqueController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  List<String> get _allSelectedTechniques => [
        ..._selectedTechniques,
        ..._otherTechniqueController.text
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      ];

  String _buildSuggestedDetails() {
    final selected = _allSelectedTechniques.map((item) => item.toLowerCase()).toList();
    final lines = <String>[];

    if (selected.any((item) => item.contains('raqui'))) {
      lines.add(
        'Raquianestesia planejada com punção, confirmação do bloqueio, instalação sensitivo-motora e acompanhamento da regressão, mantendo vigilância hemodinâmica e conforto durante o procedimento.',
      );
    }
    if (selected.any((item) => item.contains('peridural'))) {
      lines.add(
        'Peridural com identificação do espaço, dose teste quando indicada, administração fracionada e avaliação seriada do nível analgésico/anestésico e da estabilidade clínica.',
      );
    }
    if (selected.any(
      (item) => item.contains('bloqueio') || item.contains('regional'),
    )) {
      lines.add(
        'Bloqueio regional com confirmação do território anestesiado, latência adequada e monitorização da eficácia analgésica, associado a sedação titulada conforme a necessidade clínica.',
      );
    }
    if (selected.any((item) => item.contains('sedação') || item.contains('sedacao'))) {
      lines.add(
        'Sedação titulada ao estímulo cirúrgico, ventilação espontânea e conforto do paciente, com ajuste progressivo das doses e vigilância respiratória contínua.',
      );
    }
    if (selected.any((item) => item.contains('geral') || item.contains('tiva'))) {
      lines.add(
        'Anestesia geral conduzida com indução, manutenção e recuperação planejadas conforme o contexto do caso, com controle de via aérea, analgesia, hipnose e monitorização contínua.',
      );
    }
    if (lines.isEmpty) {
      return switch (widget.patient.population) {
        PatientPopulation.adult =>
          'Descrever de forma breve a técnica anestésica escolhida, as etapas principais, o tipo de monitorização e como será feita a condução intraoperatória.',
        PatientPopulation.pediatric =>
          'Descrever a técnica anestésica em linguagem objetiva, incluindo condução da sedação/anestesia, monitorização e cuidados específicos do paciente pediátrico.',
        PatientPopulation.neonatal =>
          'Descrever a técnica anestésica, a estratégia ventilatória, a monitorização e os cuidados específicos para o neonato durante o procedimento.',
      };
    }
    return lines.join('\n\n');
  }

  void _refreshSuggestedDetails() {
    if (_detailsEditedManually || widget.initialDetails.trim().isNotEmpty) return;
    _detailsController.text = _buildSuggestedDetails();
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
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _techniqueOptions
                      .map(
                        (item) => FilterChip(
                          label: Text(item),
                          selected: _selectedTechniques.contains(item),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedTechniques.add(item);
                              } else {
                                _selectedTechniques.remove(item);
                              }
                              _refreshSuggestedDetails();
                            });
                          },
                          selectedColor: const Color(0xFF8A5DD3).withAlpha(28),
                          side: BorderSide(
                            color: _selectedTechniques.contains(item)
                                ? const Color(0xFF8A5DD3)
                                : const Color(0xFFD6E1ED),
                          ),
                          labelStyle: TextStyle(
                            color: _selectedTechniques.contains(item)
                                ? const Color(0xFF8A5DD3)
                                : const Color(0xFF4F6378),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('technique-other-technique-field'),
                controller: _otherTechniqueController,
                maxLines: 2,
                onChanged: (_) {
                  setState(() {
                    _refreshSuggestedDetails();
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Outras técnicas',
                  hintText: 'Uma técnica por linha',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('technique-details-field'),
                controller: _detailsController,
                minLines: 5,
                maxLines: 9,
                decoration: const InputDecoration(
                  labelText: 'Descrição breve da técnica',
                  hintText:
                      'Ex: fases da raqui, estratégia da peridural, bloqueios, sedação associada e condução da anestesia geral conforme o contexto.',
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
              details: _detailsController.text.trim(),
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
