import 'package:flutter/material.dart';

import 'anesthesia_basic_dialogs.dart';

class MedicationCatalogSuggestion {
  const MedicationCatalogSuggestion({
    required this.title,
    required this.subtitle,
    required this.medicationName,
    required this.dose,
    required this.repeatGuidance,
    this.additionalNotes = '',
  });

  final String title;
  final String subtitle;
  final String medicationName;
  final String dose;
  final String repeatGuidance;
  final String additionalNotes;
}

class MedicationEntryEditResult {
  const MedicationEntryEditResult({
    required this.encodedEntry,
    required this.remove,
  });

  final String encodedEntry;
  final bool remove;
}

class MaintenanceEntryEditResult {
  const MaintenanceEntryEditResult({
    required this.category,
    required this.detail,
    this.freshGasFlowLPerMin,
    this.volumePercent,
    this.oxygenFlowLPerMin,
    this.compressedAirFlowLPerMin,
    this.nitrousOxideFlowLPerMin,
    required this.remove,
  });

  final String category;
  final String detail;
  final double? freshGasFlowLPerMin;
  final double? volumePercent;
  final double? oxygenFlowLPerMin;
  final double? compressedAirFlowLPerMin;
  final double? nitrousOxideFlowLPerMin;
  final bool remove;
}

class MaintenanceEntryEditDialog extends StatefulWidget {
  const MaintenanceEntryEditDialog({
    super.key,
    required this.title,
    required this.initialCategory,
    required this.initialDetail,
    this.initialFreshGasFlowLPerMin,
    this.initialVolumePercent,
    this.initialOxygenFlowLPerMin,
    this.initialCompressedAirFlowLPerMin,
    this.initialNitrousOxideFlowLPerMin,
    this.isInhalational = false,
    this.defaultCategory = '',
    this.onInhalationalChanged,
  });

  final String title;
  final String initialCategory;
  final String initialDetail;
  final double? initialFreshGasFlowLPerMin;
  final double? initialVolumePercent;
  final double? initialOxygenFlowLPerMin;
  final double? initialCompressedAirFlowLPerMin;
  final double? initialNitrousOxideFlowLPerMin;
  final bool isInhalational;
  final String defaultCategory;
  final String Function(
    double volumePercent,
    double oxygenFlowLPerMin,
    double compressedAirFlowLPerMin,
    double nitrousOxideFlowLPerMin,
  )?
  onInhalationalChanged;

  @override
  State<MaintenanceEntryEditDialog> createState() =>
      _MaintenanceEntryEditDialogState();
}

class _MaintenanceEntryEditDialogState
    extends State<MaintenanceEntryEditDialog> {
  late final TextEditingController _categoryController;
  late final TextEditingController _detailController;
  late final TextEditingController _fgfController;
  late final TextEditingController _volumeController;
  late final TextEditingController _oxygenController;
  late final TextEditingController _compressedAirController;
  late final TextEditingController _nitrousOxideController;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(
      text: widget.initialCategory.isNotEmpty
          ? widget.initialCategory
          : widget.defaultCategory,
    );
    _detailController = TextEditingController(text: widget.initialDetail);
    _fgfController = TextEditingController(
      text: widget.initialFreshGasFlowLPerMin == null
          ? ''
          : widget.initialFreshGasFlowLPerMin!
                .toStringAsFixed(1)
                .replaceAll('.', ','),
    );
    _volumeController = TextEditingController(
      text: widget.initialVolumePercent == null
          ? ''
          : widget.initialVolumePercent!
                .toStringAsFixed(1)
                .replaceAll('.', ','),
    );
    _oxygenController = TextEditingController(
      text: widget.initialOxygenFlowLPerMin == null
          ? ''
          : widget.initialOxygenFlowLPerMin!
                .toStringAsFixed(1)
                .replaceAll('.', ','),
    );
    _compressedAirController = TextEditingController(
      text: widget.initialCompressedAirFlowLPerMin == null
          ? ''
          : widget.initialCompressedAirFlowLPerMin!
                .toStringAsFixed(1)
                .replaceAll('.', ','),
    );
    _nitrousOxideController = TextEditingController(
      text: widget.initialNitrousOxideFlowLPerMin == null
          ? ''
          : widget.initialNitrousOxideFlowLPerMin!
                .toStringAsFixed(1)
                .replaceAll('.', ','),
    );
    if (widget.isInhalational) {
      _volumeController.addListener(_refreshInhalationalEstimate);
      _oxygenController.addListener(_refreshInhalationalEstimate);
      _compressedAirController.addListener(_refreshInhalationalEstimate);
      _nitrousOxideController.addListener(_refreshInhalationalEstimate);
    }
  }

  @override
  void dispose() {
    if (widget.isInhalational) {
      _volumeController.removeListener(_refreshInhalationalEstimate);
      _oxygenController.removeListener(_refreshInhalationalEstimate);
      _compressedAirController.removeListener(_refreshInhalationalEstimate);
      _nitrousOxideController.removeListener(_refreshInhalationalEstimate);
    }
    _categoryController.dispose();
    _detailController.dispose();
    _fgfController.dispose();
    _volumeController.dispose();
    _oxygenController.dispose();
    _compressedAirController.dispose();
    _nitrousOxideController.dispose();
    super.dispose();
  }

  double? _parseDecimal(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  double _flowOrZero(TextEditingController controller) {
    return _parseDecimal(controller.text) ?? 0;
  }

  void _refreshInhalationalEstimate() {
    final builder = widget.onInhalationalChanged;
    if (builder == null) return;
    final volumePercent = _parseDecimal(_volumeController.text);
    if (volumePercent == null) return;
    final next = builder(
      volumePercent,
      _flowOrZero(_oxygenController),
      _flowOrZero(_compressedAirController),
      _flowOrZero(_nitrousOxideController),
    );
    if (_detailController.text == next) return;
    _detailController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    final totalFlow =
        _flowOrZero(_oxygenController) +
        _flowOrZero(_compressedAirController) +
        _flowOrZero(_nitrousOxideController);
    final totalText = totalFlow <= 0
        ? ''
        : totalFlow.toStringAsFixed(1).replaceAll('.', ',');
    if (_fgfController.text != totalText) {
      _fgfController.value = TextEditingValue(
        text: totalText,
        selection: TextSelection.collapsed(offset: totalText.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  hintText: 'Ex: Manutenção TIVA',
                ),
              ),
              const SizedBox(height: 12),
              if (widget.isInhalational) ...[
                TextField(
                  controller: _volumeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Concentração expirada / vaporizador',
                    hintText: 'Ex: 2,0 vol%',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _oxygenController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Oxigênio (O₂)',
                    hintText: 'Ex: 1,0 L/min',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _compressedAirController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Ar comprimido',
                    hintText: 'Ex: 1,0 L/min',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nitrousOxideController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Óxido nitroso (N₂O)',
                    hintText: 'Ex: 0,0 L/min',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fgfController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Fluxo de gases frescos (FGF)',
                    hintText: 'Soma automática dos gases',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _detailController,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: widget.isInhalational
                      ? 'Dose / consumo estimado'
                      : 'Dose / estratégia',
                  hintText: widget.isInhalational
                      ? 'Ex: 2,0 vol% • O₂ 1,0 + ar 1,0 + N₂O 0,0 = FGF 2,0 L/min • ~4,9 mL/h'
                      : 'Ex: 100-200 mcg/kg/min',
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const MaintenanceEntryEditResult(
              category: '',
              detail: '',
              remove: true,
            ),
          ),
          child: const Text('Remover'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            MaintenanceEntryEditResult(
              category: _categoryController.text.trim(),
              detail: _detailController.text.trim(),
              freshGasFlowLPerMin: widget.isInhalational
                  ? _parseDecimal(_fgfController.text)
                  : null,
              volumePercent: widget.isInhalational
                  ? _parseDecimal(_volumeController.text)
                  : null,
              oxygenFlowLPerMin: widget.isInhalational
                  ? _parseDecimal(_oxygenController.text)
                  : null,
              compressedAirFlowLPerMin: widget.isInhalational
                  ? _parseDecimal(_compressedAirController.text)
                  : null,
              nitrousOxideFlowLPerMin: widget.isInhalational
                  ? _parseDecimal(_nitrousOxideController.text)
                  : null,
              remove: false,
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class MedicationEntryEditDialog extends StatefulWidget {
  const MedicationEntryEditDialog({
    super.key,
    required this.title,
    required this.name,
    required this.initialDose,
    required this.initialTime,
    required this.initialRepeats,
    this.initialInfusion = '',
    this.initialAmpoules = '',
  });

  final String title;
  final String name;
  final String initialDose;
  final String initialTime;
  final String initialRepeats;
  final String initialInfusion;
  final String initialAmpoules;

  @override
  State<MedicationEntryEditDialog> createState() =>
      _MedicationEntryEditDialogState();
}

class _MedicationEntryEditDialogState extends State<MedicationEntryEditDialog> {
  late final TextEditingController _doseController;
  late final TextEditingController _timeController;
  late final TextEditingController _repeatController;
  late final TextEditingController _infusionController;
  late final TextEditingController _ampoulesController;

  @override
  void initState() {
    super.initState();
    _doseController = TextEditingController(text: widget.initialDose);
    _timeController = TextEditingController(text: widget.initialTime);
    _repeatController = TextEditingController(text: widget.initialRepeats);
    _infusionController = TextEditingController(text: widget.initialInfusion);
    _ampoulesController = TextEditingController(text: widget.initialAmpoules);
  }

  @override
  void dispose() {
    _doseController.dispose();
    _timeController.dispose();
    _repeatController.dispose();
    _infusionController.dispose();
    _ampoulesController.dispose();
    super.dispose();
  }

  String _encode() {
    return '${widget.name}|${_doseController.text.trim()}|'
        '${_timeController.text.trim()}|${_repeatController.text.trim()}|'
        '${_infusionController.text.trim()}|${_ampoulesController.text.trim()}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
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
                child: const Text(
                  'Registre o que foi realmente administrado: dose da primeira aplicação, horário, redoses/observações, infusão contínua se houver e quantidade total usada.',
                  style: TextStyle(
                    color: Color(0xFF5D7288),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _doseController,
                decoration: const InputDecoration(
                  labelText: 'Dose administrada na 1ª aplicação',
                  hintText: 'Ex: 140 mg (14 mL)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: 'Horário da 1ª dose',
                  hintText: 'Ex: 08:30',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _repeatController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Redoses / bolus adicionais / observações',
                  hintText:
                      'Ex: 50 mcg às 08:40; repetir se necessário após 40-60 min',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _infusionController,
                decoration: const InputDecoration(
                  labelText: 'Infusão contínua / bomba',
                  hintText: 'Ex: 0,06 mcg/kg/min; deixar em branco se não usou',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ampoulesController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade total usada (ampolas / frascos)',
                  hintText: 'Ex: 2 ampolas; 1 frasco',
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const MedicationEntryEditResult(encodedEntry: '', remove: true),
          ),
          child: const Text('Remover'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            MedicationEntryEditResult(encodedEntry: _encode(), remove: false),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class DrugInfusionsDialog extends StatefulWidget {
  const DrugInfusionsDialog({super.key, required this.initialItems});

  final List<String> initialItems;

  @override
  State<DrugInfusionsDialog> createState() => _DrugInfusionsDialogState();
}

class _DrugInfusionsDialogState extends State<DrugInfusionsDialog> {
  static const List<String> _hypnotics = ['Propofol', 'Etomidato', 'Cetamina'];
  static const List<String> _analgesics = [
    'Fentanil',
    'Alfentanil',
    'Sufentanil',
    'Remifentanil',
  ];
  static const List<String> _neuromuscularBlockers = [
    'Rocurônio',
    'Cisatracúrio',
    'Atracúrio',
    'Succinilcolina',
  ];
  static const List<String> _drugNames = [
    ..._hypnotics,
    ..._analgesics,
    ..._neuromuscularBlockers,
  ];
  static const Map<String, String> _defaultDoseLabels = {
    'Propofol': '1,5-2,5 mg/kg',
    'Etomidato': '0,2-0,3 mg/kg',
    'Cetamina': '1-2 mg/kg',
    'Fentanil': '2-5 mcg/kg',
    'Alfentanil': '10-30 mcg/kg',
    'Sufentanil': '0,2-0,5 mcg/kg',
    'Remifentanil': '0,5-1 mcg/kg',
    'Rocurônio': '0,6-1,2 mg/kg',
    'Cisatracúrio': '0,1-0,2 mg/kg',
    'Atracúrio': '0,4-0,5 mg/kg',
    'Succinilcolina': '1-1,5 mg/kg',
  };

  late final Map<String, TextEditingController> _doseControllers;
  late final Map<String, TextEditingController> _timeControllers;
  late final Map<String, TextEditingController> _repeatControllers;
  late final Map<String, TextEditingController> _infusionControllers;
  late final Map<String, TextEditingController> _ampouleControllers;
  late final TextEditingController _otherHypnoticsController;
  late final TextEditingController _otherAnalgesicsController;
  late final TextEditingController _otherBlockersController;

  @override
  void initState() {
    super.initState();
    final parsed = <String, List<String>>{};
    final others = <String>[];
    for (final item in widget.initialItems) {
      final parts = item.split('|');
      final name = parts.isEmpty ? '' : parts.first;
      if (_drugNames.contains(name)) {
        parsed[name] = [
          parts.length > 1 ? parts[1] : '',
          parts.length > 2 ? parts[2] : '',
          parts.length > 3 ? parts[3] : '',
          parts.length > 4 ? parts[4] : '',
          parts.length > 5 ? parts[5] : '',
        ];
      } else if (item.trim().isNotEmpty) {
        others.add(item);
      }
    }

    _doseControllers = {
      for (final name in _drugNames)
        name: TextEditingController(text: parsed[name]?[0] ?? ''),
    };
    _timeControllers = {
      for (final name in _drugNames)
        name: TextEditingController(text: parsed[name]?[1] ?? ''),
    };
    _repeatControllers = {
      for (final name in _drugNames)
        name: TextEditingController(text: parsed[name]?[2] ?? ''),
    };
    _infusionControllers = {
      for (final name in _drugNames)
        name: TextEditingController(text: parsed[name]?[3] ?? ''),
    };
    _ampouleControllers = {
      for (final name in _drugNames)
        name: TextEditingController(text: parsed[name]?[4] ?? ''),
    };
    _otherHypnoticsController = TextEditingController();
    _otherAnalgesicsController = TextEditingController();
    _otherBlockersController = TextEditingController(text: others.join('\n'));
  }

  @override
  void dispose() {
    for (final controller in _doseControllers.values) {
      controller.dispose();
    }
    for (final controller in _timeControllers.values) {
      controller.dispose();
    }
    for (final controller in _repeatControllers.values) {
      controller.dispose();
    }
    for (final controller in _infusionControllers.values) {
      controller.dispose();
    }
    for (final controller in _ampouleControllers.values) {
      controller.dispose();
    }
    _otherHypnoticsController.dispose();
    _otherAnalgesicsController.dispose();
    _otherBlockersController.dispose();
    super.dispose();
  }

  List<String> _lines(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _buildResult() {
    final selected = _drugNames
        .where(
          (name) =>
              _doseControllers[name]!.text.trim().isNotEmpty ||
              _timeControllers[name]!.text.trim().isNotEmpty ||
              _repeatControllers[name]!.text.trim().isNotEmpty ||
              _infusionControllers[name]!.text.trim().isNotEmpty ||
              _ampouleControllers[name]!.text.trim().isNotEmpty,
        )
        .map(
          (name) =>
              '$name|${_doseControllers[name]!.text.trim()}|'
              '${_timeControllers[name]!.text.trim()}|'
              '${_repeatControllers[name]!.text.trim()}|'
              '${_infusionControllers[name]!.text.trim()}|'
              '${_ampouleControllers[name]!.text.trim()}',
        )
        .toList();

    final others = [
      ..._lines(_otherHypnoticsController.text),
      ..._lines(_otherAnalgesicsController.text),
      ..._lines(_otherBlockersController.text),
    ];

    return [...selected, ...others];
  }

  Widget _buildDrugSection({
    required String title,
    required List<String> drugs,
    required TextEditingController otherController,
    required String otherKeyPrefix,
  }) {
    return Column(
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
        const SizedBox(height: 10),
        ...drugs.map(
          (name) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name • dose de referência usual: ${_defaultDoseLabels[name] ?? 'dose padrão'}',
                  style: const TextStyle(
                    color: Color(0xFF17324D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: Key('drug-dose-field-$name'),
                        controller: _doseControllers[name],
                        decoration: const InputDecoration(
                          labelText: 'Dose administrada na 1ª aplicação',
                          hintText: 'Ex: 150 mg',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        key: Key('drug-time-field-$name'),
                        controller: _timeControllers[name],
                        decoration: const InputDecoration(
                          labelText: 'Horário da 1ª dose',
                          hintText: 'Ex: 08:12',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  key: Key('drug-repeat-field-$name'),
                  controller: _repeatControllers[name],
                  decoration: const InputDecoration(
                    labelText: 'Redoses / bolus adicionais',
                    hintText: 'Ex: 50 mcg às 08:20; 50 mcg às 08:35',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: Key('drug-infusion-field-$name'),
                  controller: _infusionControllers[name],
                  decoration: const InputDecoration(
                    labelText: 'Infusão contínua / bomba',
                    hintText: 'Ex: 0,08 mcg/kg/min a partir de 08:40',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: Key('drug-ampoules-field-$name'),
                  controller: _ampouleControllers[name],
                  decoration: const InputDecoration(
                    labelText: 'Quantidade total usada (ampolas / frascos)',
                    hintText: 'Ex: 3 ampolas',
                  ),
                ),
              ],
            ),
          ),
        ),
        TextField(
          key: Key('drug-other-items-field-$otherKeyPrefix'),
          controller: otherController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Outros',
            hintText: 'Um item por linha',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Indução (Drogas)'),
      content: SizedBox(
        width: 640,
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
                child: const Text(
                  'As doses mostradas ao lado de cada droga são referências usuais. Registre abaixo o que foi realmente administrado na indução, com primeira dose, horário, redoses, infusão contínua se houver e quantidade total utilizada.',
                  style: TextStyle(
                    color: Color(0xFF5D7288),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildDrugSection(
                title: 'Hipnóticos',
                drugs: _hypnotics,
                otherController: _otherHypnoticsController,
                otherKeyPrefix: 'hypnotics',
              ),
              const SizedBox(height: 18),
              _buildDrugSection(
                title: 'Analgésicos',
                drugs: _analgesics,
                otherController: _otherAnalgesicsController,
                otherKeyPrefix: 'analgesics',
              ),
              const SizedBox(height: 18),
              _buildDrugSection(
                title: 'Bloqueadores neuromusculares',
                drugs: _neuromuscularBlockers,
                otherController: _otherBlockersController,
                otherKeyPrefix: 'blockers',
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
          key: const Key('drug-save-button'),
          onPressed: () => Navigator.of(context).pop(_buildResult()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class EventsDialog extends StatefulWidget {
  const EventsDialog({super.key, required this.initialItems});

  final List<String> initialItems;

  @override
  State<EventsDialog> createState() => _EventsDialogState();
}

class _EventsDialogState extends State<EventsDialog> {
  static const List<String> _commonEvents = [
    'Indução',
    'Intubação',
    'Incisão cirúrgica',
    'Hipotensão',
    'Bradicardia',
    'Extubação',
  ];

  late List<String> _items;
  late String _selectedEvent;
  late final TextEditingController _timeController;
  late final TextEditingController _customEventController;
  late final TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.initialItems);
    _selectedEvent = '';
    _timeController = TextEditingController();
    _customEventController = TextEditingController();
    _detailsController = TextEditingController();
  }

  @override
  void dispose() {
    _timeController.dispose();
    _customEventController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String? _buildDraftItem() {
    final event = _selectedEvent.isNotEmpty
        ? _selectedEvent
        : _customEventController.text.trim();
    final details = _detailsController.text.trim();
    final time = _timeController.text.trim();
    if (event.isEmpty && details.isEmpty && time.isEmpty) return null;
    if (event.isEmpty) return null;
    return '$time|$event|$details';
  }

  void _commitDraftIfNeeded() {
    final encoded = _buildDraftItem();
    if (encoded == null) return;
    setState(() {
      _items = [..._items, encoded];
      _timeController.clear();
      _customEventController.clear();
      _detailsController.clear();
      _selectedEvent = '';
    });
  }

  Future<void> _selectCommonEvent() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Evento comum',
        options: _commonEvents,
        initialValue: _selectedEvent,
      ),
    );

    if (result == null) return;
    setState(() => _selectedEvent = result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Eventos'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectCommonEvent,
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.local_offer_outlined),
                  label: Text(
                    _selectedEvent.isEmpty
                        ? 'Selecionar evento comum'
                        : 'Evento comum: $_selectedEvent',
                  ),
                ),
              ),
              if (_selectedEvent.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _selectedEvent = ''),
                    child: const Text('Limpar seleção'),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: TextField(
                      key: const Key('event-time-field'),
                      controller: _timeController,
                      decoration: const InputDecoration(labelText: 'Horário'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('event-custom-field'),
                      controller: _customEventController,
                      decoration: const InputDecoration(
                        labelText: 'Evento / outro',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('event-details-field'),
                controller: _detailsController,
                decoration: const InputDecoration(labelText: 'Detalhes'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('event-add-button'),
                  onPressed: _commitDraftIfNeeded,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar evento'),
                ),
              ),
              const SizedBox(height: 12),
              ..._items.asMap().entries.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.value.replaceAll('|', ' • ')),
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        _items.removeAt(item.key);
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
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
          key: const Key('event-save-button'),
          onPressed: () {
            final pending = _buildDraftItem();
            Navigator.of(
              context,
            ).pop(pending == null ? _items : [..._items, pending]);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class AdjunctsDialog extends StatefulWidget {
  const AdjunctsDialog({super.key, required this.initialItems});

  final List<String> initialItems;

  @override
  State<AdjunctsDialog> createState() => _AdjunctsDialogState();
}

class _AdjunctsDialogState extends State<AdjunctsDialog> {
  static const List<String> _adjunctNames = [
    'Sulfato de Mg',
    'Cetamina',
    'Clonidina',
    'Metadona',
    'Dexmedetomidina (Precedex)',
    'Lidocaína',
  ];
  static const Map<String, String> _defaultDoseLabels = {
    'Sulfato de Mg': '30-50 mg/kg',
    'Cetamina': '0,1-0,5 mg/kg',
    'Clonidina': '1-2 mcg/kg',
    'Metadona': '0,1-0,2 mg/kg',
    'Dexmedetomidina (Precedex)': '0,5-1 mcg/kg',
    'Lidocaína': '1-1,5 mg/kg',
  };

  late final Map<String, TextEditingController> _doseControllers;
  late final Map<String, TextEditingController> _timeControllers;
  late final Map<String, TextEditingController> _repeatControllers;
  late final Map<String, TextEditingController> _infusionControllers;
  late final Map<String, TextEditingController> _ampouleControllers;
  late final TextEditingController _otherItemsController;

  @override
  void initState() {
    super.initState();
    final parsed = <String, List<String>>{};
    final others = <String>[];
    for (final item in widget.initialItems) {
      final parts = item.split('|');
      if (parts.isEmpty) continue;
      if (_adjunctNames.contains(parts[0])) {
        parsed[parts[0]] = [
          parts.length > 1 ? parts[1] : '',
          parts.length > 2 ? parts[2] : '',
          parts.length > 3 ? parts[3] : '',
          parts.length > 4 ? parts[4] : '',
          parts.length > 5 ? parts[5] : '',
        ];
      } else if (item.trim().isNotEmpty) {
        others.add(item);
      }
    }

    _doseControllers = {
      for (final name in _adjunctNames)
        name: TextEditingController(text: parsed[name]?[0] ?? ''),
    };
    _timeControllers = {
      for (final name in _adjunctNames)
        name: TextEditingController(text: parsed[name]?[1] ?? ''),
    };
    _repeatControllers = {
      for (final name in _adjunctNames)
        name: TextEditingController(text: parsed[name]?[2] ?? ''),
    };
    _infusionControllers = {
      for (final name in _adjunctNames)
        name: TextEditingController(text: parsed[name]?[3] ?? ''),
    };
    _ampouleControllers = {
      for (final name in _adjunctNames)
        name: TextEditingController(text: parsed[name]?[4] ?? ''),
    };
    _otherItemsController = TextEditingController(text: others.join('\n'));
  }

  @override
  void dispose() {
    for (final controller in _doseControllers.values) {
      controller.dispose();
    }
    for (final controller in _timeControllers.values) {
      controller.dispose();
    }
    for (final controller in _repeatControllers.values) {
      controller.dispose();
    }
    for (final controller in _infusionControllers.values) {
      controller.dispose();
    }
    for (final controller in _ampouleControllers.values) {
      controller.dispose();
    }
    _otherItemsController.dispose();
    super.dispose();
  }

  List<String> _buildResult() {
    final selected = _adjunctNames
        .where(
          (name) =>
              _doseControllers[name]!.text.trim().isNotEmpty ||
              _timeControllers[name]!.text.trim().isNotEmpty ||
              _repeatControllers[name]!.text.trim().isNotEmpty ||
              _infusionControllers[name]!.text.trim().isNotEmpty ||
              _ampouleControllers[name]!.text.trim().isNotEmpty,
        )
        .map(
          (name) =>
              '$name|${_doseControllers[name]!.text.trim()}|'
              '${_timeControllers[name]!.text.trim()}|'
              '${_repeatControllers[name]!.text.trim()}|'
              '${_infusionControllers[name]!.text.trim()}|'
              '${_ampouleControllers[name]!.text.trim()}',
        )
        .toList();

    final others = _otherItemsController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return [...selected, ...others];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Adjuvantes'),
      content: SizedBox(
        width: 620,
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
                child: const Text(
                  'A dose ao lado de cada adjuvante é uma referência usual. Preencha o que foi efetivamente administrado no caso, incluindo primeira dose, horário, redoses, infusão contínua se houver e quantidade total usada.',
                  style: TextStyle(
                    color: Color(0xFF5D7288),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ..._adjunctNames.map((name) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name • dose de referência usual: ${_defaultDoseLabels[name] ?? 'dose padrão'}',
                        style: const TextStyle(
                          color: Color(0xFF17324D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: Key('catalog-dose-field-$name'),
                              controller: _doseControllers[name],
                              decoration: const InputDecoration(
                                labelText: 'Dose administrada na 1ª aplicação',
                                hintText: 'Ex: 100 mg',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              key: Key('catalog-time-field-$name'),
                              controller: _timeControllers[name],
                              decoration: const InputDecoration(
                                labelText: 'Horário da 1ª dose',
                                hintText: 'Ex: 08:30',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: Key('catalog-repeat-field-$name'),
                        controller: _repeatControllers[name],
                        decoration: const InputDecoration(
                          labelText: 'Redoses / bolus adicionais',
                          hintText: 'Ex: 25 mg às 09:10; 25 mg às 09:30',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: Key('catalog-infusion-field-$name'),
                        controller: _infusionControllers[name],
                        decoration: const InputDecoration(
                          labelText: 'Infusão contínua / bomba',
                          hintText:
                              'Ex: 0,2 mg/kg/h; deixar em branco se não usou',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: Key('catalog-ampoules-field-$name'),
                        controller: _ampouleControllers[name],
                        decoration: const InputDecoration(
                          labelText:
                              'Quantidade total usada (ampolas / frascos)',
                          hintText: 'Ex: 2 ampolas',
                        ),
                      ),
                    ],
                  ),
                );
              }),
              TextField(
                key: const Key('catalog-other-items-field'),
                controller: _otherItemsController,
                maxLines: 4,
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
          onPressed: () => Navigator.of(context).pop(_buildResult()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class CatalogMedicationDialog extends StatefulWidget {
  const CatalogMedicationDialog({
    super.key,
    required this.title,
    required this.catalogItems,
    required this.initialItems,
    this.suggestions = const [],
  });

  final String title;
  final Map<String, String> catalogItems;
  final List<String> initialItems;
  final List<MedicationCatalogSuggestion> suggestions;

  @override
  State<CatalogMedicationDialog> createState() =>
      _CatalogMedicationDialogState();
}

class _CatalogMedicationDialogState extends State<CatalogMedicationDialog> {
  late final Map<String, TextEditingController> _doseControllers;
  late final Map<String, TextEditingController> _timeControllers;
  late final Map<String, TextEditingController> _repeatControllers;
  late final Map<String, TextEditingController> _infusionControllers;
  late final Map<String, TextEditingController> _ampouleControllers;
  late final TextEditingController _otherItemsController;

  @override
  void initState() {
    super.initState();
    final parsed = <String, List<String>>{};
    final others = <String>[];
    for (final item in widget.initialItems) {
      final parts = item.split('|');
      if (parts.isEmpty) continue;
      if (widget.catalogItems.containsKey(parts[0])) {
        parsed[parts[0]] = [
          parts.length > 1 ? parts[1] : '',
          parts.length > 2 ? parts[2] : '',
          parts.length > 3 ? parts[3] : '',
          parts.length > 4 ? parts[4] : '',
          parts.length > 5 ? parts[5] : '',
        ];
      } else if (item.trim().isNotEmpty) {
        others.add(item);
      }
    }

    _doseControllers = {
      for (final name in widget.catalogItems.keys)
        name: TextEditingController(text: parsed[name]?[0] ?? ''),
    };
    _timeControllers = {
      for (final name in widget.catalogItems.keys)
        name: TextEditingController(text: parsed[name]?[1] ?? ''),
    };
    _repeatControllers = {
      for (final name in widget.catalogItems.keys)
        name: TextEditingController(text: parsed[name]?[2] ?? ''),
    };
    _infusionControllers = {
      for (final name in widget.catalogItems.keys)
        name: TextEditingController(text: parsed[name]?[3] ?? ''),
    };
    _ampouleControllers = {
      for (final name in widget.catalogItems.keys)
        name: TextEditingController(text: parsed[name]?[4] ?? ''),
    };
    _otherItemsController = TextEditingController(text: others.join('\n'));
  }

  @override
  void dispose() {
    for (final controller in _doseControllers.values) {
      controller.dispose();
    }
    for (final controller in _timeControllers.values) {
      controller.dispose();
    }
    for (final controller in _repeatControllers.values) {
      controller.dispose();
    }
    for (final controller in _infusionControllers.values) {
      controller.dispose();
    }
    for (final controller in _ampouleControllers.values) {
      controller.dispose();
    }
    _otherItemsController.dispose();
    super.dispose();
  }

  List<String> _buildResult() {
    final selected = widget.catalogItems.keys
        .where(
          (name) =>
              _doseControllers[name]!.text.trim().isNotEmpty ||
              _timeControllers[name]!.text.trim().isNotEmpty ||
              _repeatControllers[name]!.text.trim().isNotEmpty ||
              _infusionControllers[name]!.text.trim().isNotEmpty ||
              _ampouleControllers[name]!.text.trim().isNotEmpty,
        )
        .map(
          (name) =>
              '$name|${_doseControllers[name]!.text.trim()}|'
              '${_timeControllers[name]!.text.trim()}|'
              '${_repeatControllers[name]!.text.trim()}|'
              '${_infusionControllers[name]!.text.trim()}|'
              '${_ampouleControllers[name]!.text.trim()}',
        )
        .toList();

    final others = _otherItemsController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return [...selected, ...others];
  }

  void _applySuggestion(MedicationCatalogSuggestion suggestion) {
    if (!widget.catalogItems.containsKey(suggestion.medicationName)) return;
    setState(() {
      _doseControllers[suggestion.medicationName]!.text = suggestion.dose;
      _repeatControllers[suggestion.medicationName]!.text =
          suggestion.repeatGuidance;
      if (suggestion.additionalNotes.trim().isNotEmpty) {
        final lines = _otherItemsController.text
            .split('\n')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
        if (!lines.contains(suggestion.additionalNotes.trim())) {
          _otherItemsController.text = [
            ...lines,
            suggestion.additionalNotes.trim(),
          ].join('\n');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSedationDialog =
        widget.title.toLowerCase().contains('sedação') ||
        widget.title.toLowerCase().contains('sedacao');

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSedationDialog) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5ECF6)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como preencher a sedação',
                        style: TextStyle(
                          color: Color(0xFF17324D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'O valor entre parênteses ao lado de cada medicação é apenas uma dose de referência usual. Preencha abaixo o que foi realmente administrado no caso, com horário da primeira dose, redoses/bolus adicionais, infusão contínua se houver e quantidade total utilizada.',
                        style: TextStyle(
                          color: Color(0xFF5D7288),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (widget.suggestions.isNotEmpty) ...[
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
                      const Text(
                        'Sugestões pela cirurgia selecionada',
                        style: TextStyle(
                          color: Color(0xFF17324D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Aplique uma sugestão e ajuste livremente se precisar trocar esquema, dose ou repique.',
                        style: TextStyle(
                          color: Color(0xFF5D7288),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.suggestions.map(
                        (suggestion) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD9E6F7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion.title,
                                style: const TextStyle(
                                  color: Color(0xFF17324D),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                suggestion.subtitle,
                                style: const TextStyle(
                                  color: Color(0xFF5D7288),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${suggestion.medicationName} • Dose: ${suggestion.dose}',
                                style: const TextStyle(
                                  color: Color(0xFF17324D),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Repique/redose: ${suggestion.repeatGuidance}',
                                style: const TextStyle(
                                  color: Color(0xFF5D7288),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (suggestion.additionalNotes
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  suggestion.additionalNotes,
                                  style: const TextStyle(
                                    color: Color(0xFF5D7288),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: () => _applySuggestion(suggestion),
                                  icon: const Icon(
                                    Icons.auto_fix_high_outlined,
                                  ),
                                  label: const Text('Aplicar sugestão'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              ...widget.catalogItems.entries.map((entry) {
                final name = entry.key;
                final defaultDose = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name • dose de referência usual: $defaultDose',
                        style: const TextStyle(
                          color: Color(0xFF17324D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: Key('catalog-dose-field-$name'),
                              controller: _doseControllers[name],
                              decoration: const InputDecoration(
                                labelText: 'Dose administrada na 1ª aplicação',
                                hintText: 'Ex: 1 g IV',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              key: Key('catalog-time-field-$name'),
                              controller: _timeControllers[name],
                              decoration: const InputDecoration(
                                labelText: 'Horário da 1ª dose',
                                hintText: 'Ex: 08:30',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: Key('catalog-repeat-field-$name'),
                        controller: _repeatControllers[name],
                        decoration: const InputDecoration(
                          labelText: 'Redoses / bolus adicionais',
                          hintText: 'Ex: 25 mcg às 09:10; 25 mcg às 09:30',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: Key('catalog-infusion-field-$name'),
                        controller: _infusionControllers[name],
                        decoration: const InputDecoration(
                          labelText: 'Infusão contínua / bomba',
                          hintText:
                              'Ex: 0,4 mcg/kg/h; deixar em branco se não usou',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: Key('catalog-ampoules-field-$name'),
                        controller: _ampouleControllers[name],
                        decoration: const InputDecoration(
                          labelText:
                              'Quantidade total usada (ampolas / frascos)',
                          hintText: 'Ex: 2 ampolas',
                        ),
                      ),
                    ],
                  ),
                );
              }),
              TextField(
                key: const Key('catalog-other-items-field'),
                controller: _otherItemsController,
                maxLines: 4,
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
          onPressed: () => Navigator.of(context).pop(_buildResult()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class VasoactiveDrugsDialog extends StatefulWidget {
  const VasoactiveDrugsDialog({
    super.key,
    required this.catalogItems,
    required this.initialItems,
  });

  final Map<String, String> catalogItems;
  final List<String> initialItems;

  @override
  State<VasoactiveDrugsDialog> createState() => _VasoactiveDrugsDialogState();
}

class _VasoactiveDrugsDialogState extends State<VasoactiveDrugsDialog> {
  late final Map<String, TextEditingController> _doseControllers;
  late final Map<String, TextEditingController> _timeControllers;
  late final Map<String, TextEditingController> _repeatControllers;
  late final Map<String, TextEditingController> _infusionControllers;
  late final Map<String, TextEditingController> _ampouleControllers;
  late final TextEditingController _otherItemsController;

  @override
  void initState() {
    super.initState();
    final parsed = <String, List<String>>{};
    final others = <String>[];
    for (final item in widget.initialItems) {
      final parts = item.split('|');
      if (parts.isEmpty) continue;
      if (widget.catalogItems.containsKey(parts[0])) {
        parsed[parts[0]] = [
          parts.length > 1 ? parts[1] : '',
          parts.length > 2 ? parts[2] : '',
          parts.length > 3 ? parts[3] : '',
          parts.length > 4 ? parts[4] : '',
          parts.length > 5 ? parts[5] : '',
        ];
      } else if (item.trim().isNotEmpty) {
        others.add(item);
      }
    }

    _doseControllers = {
      for (final name in widget.catalogItems.keys)
        name: TextEditingController(text: parsed[name]?[0] ?? ''),
    };
    _timeControllers = {
      for (final name in widget.catalogItems.keys)
        name: TextEditingController(text: parsed[name]?[1] ?? ''),
    };
    _repeatControllers = {
      for (final name in widget.catalogItems.keys)
        name: TextEditingController(text: parsed[name]?[2] ?? ''),
    };
    _infusionControllers = {
      for (final name in widget.catalogItems.keys)
        name: TextEditingController(text: parsed[name]?[3] ?? ''),
    };
    _ampouleControllers = {
      for (final name in widget.catalogItems.keys)
        name: TextEditingController(text: parsed[name]?[4] ?? ''),
    };
    _otherItemsController = TextEditingController(text: others.join('\n'));
  }

  @override
  void dispose() {
    for (final controller in _doseControllers.values) {
      controller.dispose();
    }
    for (final controller in _timeControllers.values) {
      controller.dispose();
    }
    for (final controller in _repeatControllers.values) {
      controller.dispose();
    }
    for (final controller in _infusionControllers.values) {
      controller.dispose();
    }
    for (final controller in _ampouleControllers.values) {
      controller.dispose();
    }
    _otherItemsController.dispose();
    super.dispose();
  }

  List<String> _buildResult() {
    final selected = widget.catalogItems.keys
        .where(
          (name) =>
              _doseControllers[name]!.text.trim().isNotEmpty ||
              _timeControllers[name]!.text.trim().isNotEmpty ||
              _repeatControllers[name]!.text.trim().isNotEmpty ||
              _infusionControllers[name]!.text.trim().isNotEmpty ||
              _ampouleControllers[name]!.text.trim().isNotEmpty,
        )
        .map(
          (name) =>
              '$name|${_doseControllers[name]!.text.trim()}|'
              '${_timeControllers[name]!.text.trim()}|'
              '${_repeatControllers[name]!.text.trim()}|'
              '${_infusionControllers[name]!.text.trim()}|'
              '${_ampouleControllers[name]!.text.trim()}',
        )
        .toList();

    final others = _otherItemsController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return [...selected, ...others];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Drogas vasoativas'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...widget.catalogItems.entries.map((entry) {
                final name = entry.key;
                final defaultDose = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$name ($defaultDose)',
                        style: const TextStyle(
                          color: Color(0xFF17324D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: Key('vasoactive-dose-field-$name'),
                              controller: _doseControllers[name],
                              decoration: const InputDecoration(
                                labelText: 'Dose intermitente / bolus',
                                hintText: 'Ex: 10 mg',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              key: Key('vasoactive-time-field-$name'),
                              controller: _timeControllers[name],
                              decoration: const InputDecoration(
                                labelText: 'Horário',
                                hintText: '08:30',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: Key('vasoactive-repeat-field-$name'),
                        controller: _repeatControllers[name],
                        decoration: const InputDecoration(
                          labelText: 'Bolus / repiques intermitentes',
                          hintText: 'Ex: 5 mg às 08:40; 5 mg às 08:55',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: Key('vasoactive-infusion-field-$name'),
                        controller: _infusionControllers[name],
                        decoration: const InputDecoration(
                          labelText: 'Infusão contínua / BIC',
                          hintText: 'Ex: 0,06 mcg/kg/min a partir de 08:45',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: Key('vasoactive-ampoules-field-$name'),
                        controller: _ampouleControllers[name],
                        decoration: const InputDecoration(
                          labelText:
                              'Quantidade total usada (ampolas / frascos)',
                          hintText: 'Ex: 1 ampola; 1 seringa preparada',
                        ),
                      ),
                    ],
                  ),
                );
              }),
              TextField(
                key: const Key('vasoactive-other-items-field'),
                controller: _otherItemsController,
                maxLines: 4,
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
          onPressed: () => Navigator.of(context).pop(_buildResult()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
