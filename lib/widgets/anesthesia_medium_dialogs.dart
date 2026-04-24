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
  bool _updatingSuggestedDetails = false;

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
      if (_updatingSuggestedDetails) return;
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

  bool _containsAny(Iterable<String> values, List<String> needles) {
    return values.any((item) => needles.any((needle) => item.contains(needle)));
  }

  String _joinSelectedTechniques(List<String> techniques) {
    if (techniques.isEmpty) return '';
    if (techniques.length == 1) return techniques.first;
    if (techniques.length == 2) {
      return '${techniques.first} associada a ${techniques.last}';
    }
    final head = techniques.take(techniques.length - 1).join(', ');
    return '$head e ${techniques.last}';
  }

  String _buildSuggestedDetails() {
    final selectedOriginal = _allSelectedTechniques;
    final selected = selectedOriginal
        .map((item) => item.toLowerCase())
        .toList();

    if (selected.isEmpty) {
      return switch (widget.patient.population) {
        PatientPopulation.adult =>
          'Descrever de forma breve a técnica anestésica escolhida, as etapas principais, o tipo de monitorização e como será feita a condução intraoperatória.',
        PatientPopulation.pediatric =>
          'Descrever a técnica anestésica em linguagem objetiva, incluindo condução da sedação/anestesia, monitorização e cuidados específicos do paciente pediátrico.',
        PatientPopulation.neonatal =>
          'Descrever a técnica anestésica, a estratégia ventilatória, a monitorização e os cuidados específicos para o neonato durante o procedimento.',
      };
    }

    final hasTiva = _containsAny(selected, ['tiva', 'venosa total']);
    final hasBalancedGeneral = _containsAny(selected, [
      'anestesia geral balanceada',
    ]);
    final hasGeneral =
        hasTiva ||
        hasBalancedGeneral ||
        _containsAny(selected, [
          'anestesia geral',
          'máscara laríngea',
          'mascara laringea',
        ]);
    final hasSpinal = _containsAny(selected, ['raqui']);
    final hasEpidural = _containsAny(selected, ['peridural', 'epidural']);
    final hasRegional = _containsAny(selected, [
      'bloqueio',
      'regional',
      'caudal',
    ]);
    final hasSedation = _containsAny(selected, ['sedação', 'sedacao']);

    final combinedLabel = _joinSelectedTechniques(selectedOriginal);

    if ((hasSpinal || hasEpidural || hasRegional) && hasGeneral) {
      return '$combinedLabel planejada como técnica combinada, com componente regional realizado antes da incisão para analgesia e redução do consumo de anestésicos, seguido de anestesia geral com monitorização contínua, controle de via aérea, indução conforme o contexto e manutenção titulada até o despertar. O bloqueio deve ser conferido clinicamente, com vigilância hemodinâmica, respiratória e estratégia de resgate caso a cobertura regional seja incompleta.';
    }

    if (hasSpinal && hasSedation) {
      return 'Raquianestesia associada à sedação, com punção subaracnoidea, confirmação do bloqueio sensitivo-motor e início do procedimento após instalação adequada. A sedação deve ser titulada para conforto e imobilidade, preservando ventilação espontânea sempre que possível, com monitorização contínua da hemodinâmica, oxigenação, nível de consciência e regressão do bloqueio ao final.';
    }

    if (hasEpidural && hasSedation) {
      return 'Peridural associada à sedação, com identificação do espaço peridural, dose teste quando indicada, administração fracionada do anestésico local e avaliação seriada do nível de bloqueio. A sedação deve ser ajustada ao estímulo cirúrgico, mantendo conforto, vigilância respiratória e estabilidade hemodinâmica durante todo o procedimento.';
    }

    if (hasRegional && hasSedation) {
      return 'Bloqueio periférico/regional associado à sedação, com confirmação do território anestesiado, tempo de latência adequado e início cirúrgico apenas após analgesia satisfatória. A sedação deve ser titulada progressivamente para conforto e cooperação, com monitorização contínua da ventilação, oxigenação e resposta hemodinâmica.';
    }

    if (hasTiva) {
      return 'Anestesia venosa total (TIVA), com indução intravenosa, controle de via aérea conforme a necessidade e manutenção em infusão contínua titulada ao plano anestésico e ao estímulo cirúrgico. A condução deve integrar hipnose, analgesia, relaxamento quando indicado e monitorização contínua da hemodinâmica, ventilação, oxigenação e recuperação ao término do procedimento.';
    }

    if (hasBalancedGeneral) {
      return 'Anestesia geral balanceada, com indução venosa, controle de via aérea conforme o caso e manutenção combinando agente hipnótico/inalatório, analgésicos e adjuvantes de forma titulada. A condução deve incluir monitorização contínua, ventilação ajustada ao procedimento, controle hemodinâmico e planejamento de despertar, analgesia e extubação ao final.';
    }

    if (hasSpinal && hasEpidural) {
      return 'Técnica combinada raquiperidural, com punção para componente subaracnoideo seguida de acesso peridural para complementação e titulação do bloqueio conforme a duração e a necessidade analgésica do procedimento. Exige avaliação seriada do nível sensitivo-motor, vigilância hemodinâmica e planejamento de analgesia pós-operatória pelo cateter quando indicado.';
    }

    if (hasSpinal) {
      return 'Raquianestesia com punção subaracnoidea, confirmação da técnica, instalação do bloqueio sensitivo-motor e início cirúrgico após nível adequado. Requer monitorização contínua, vigilância de hipotensão/bradicardia, avaliação seriada da extensão do bloqueio e acompanhamento da recuperação motora e sensitiva ao final.';
    }

    if (hasEpidural) {
      return 'Peridural com identificação do espaço, dose teste quando indicada e administração fracionada do anestésico local para titulação progressiva do bloqueio. A condução deve incluir avaliação seriada do nível analgésico/anestésico, monitorização contínua e possibilidade de complementação intraoperatória e analgesia pós-operatória.';
    }

    if (hasRegional) {
      return 'Bloqueio periférico/regional com localização do alvo, realização do bloqueio, tempo de latência adequado e confirmação clínica de cobertura do território operatório antes do início da cirurgia. A condução inclui monitorização contínua, avaliação da eficácia analgésica e plano complementar caso o bloqueio seja parcial ou insuficiente.';
    }

    if (hasSedation) {
      return 'Sedação monitorizada com titulação progressiva conforme o estímulo cirúrgico e a resposta clínica, priorizando conforto, cooperação e segurança respiratória. A condução deve manter vigilância contínua do nível de consciência, ventilação, oxigenação e estabilidade hemodinâmica, com prontidão para suporte de via aérea se necessário.';
    }

    return 'Técnica anestésica planejada conforme seleção atual, com monitorização contínua, execução em etapas e titulação da condução intraoperatória de acordo com a resposta clínica e as necessidades do procedimento.';
  }

  void _refreshSuggestedDetails() {
    if (_detailsEditedManually || widget.initialDetails.trim().isNotEmpty) {
      return;
    }
    _updatingSuggestedDetails = true;
    _detailsController.text = _buildSuggestedDetails();
    _detailsController.selection = TextSelection.collapsed(
      offset: _detailsController.text.length,
    );
    _updatingSuggestedDetails = false;
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
                        _selectedTechniques.add(item);
                      }
                      _refreshSuggestedDetails();
                    });
                  },
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
