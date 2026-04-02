import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/patient.dart';

class AnesthesiologistsDialog extends StatefulWidget {
  const AnesthesiologistsDialog({
    super.key,
    required this.initialItems,
  });

  final List<String> initialItems;

  @override
  State<AnesthesiologistsDialog> createState() =>
      _AnesthesiologistsDialogState();
}

class _AnesthesiologistsDialogState extends State<AnesthesiologistsDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _crmController;
  late final TextEditingController _detailsController;
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _crmController = TextEditingController();
    _detailsController = TextEditingController();
    _items = List<String>.from(widget.initialItems);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _crmController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String? _buildDraftItem() {
    final name = _nameController.text.trim();
    final crm = _crmController.text.trim();
    final details = _detailsController.text.trim();
    if (name.isEmpty && crm.isEmpty && details.isEmpty) return null;
    if (name.isEmpty) return null;
    return '$name|$crm|$details';
  }

  void _addDraft() {
    final draft = _buildDraftItem();
    if (draft == null) return;
    setState(() {
      _items = [..._items, draft];
      _nameController.clear();
      _crmController.clear();
      _detailsController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Anestesiologistas'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('anesthesiologist-name-field'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('anesthesiologist-crm-field'),
                controller: _crmController,
                decoration: const InputDecoration(labelText: 'CRM'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('anesthesiologist-details-field'),
                controller: _detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Dados complementares',
                  hintText: 'Ex: UF, RQE, equipe, observações',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('anesthesiologist-add-button'),
                  onPressed: _addDraft,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar anestesiologista'),
                ),
              ),
              const SizedBox(height: 12),
              ..._items.asMap().entries.map((entry) {
                final parts = entry.value.split('|');
                final title = parts.isNotEmpty ? parts.first : '';
                final subtitle = [
                  if (parts.length > 1 && parts[1].trim().isNotEmpty)
                    'CRM ${parts[1].trim()}',
                  if (parts.length > 2 && parts[2].trim().isNotEmpty)
                    parts[2].trim(),
                ].join(' • ');
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(title),
                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        _items.removeAt(entry.key);
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                );
              }),
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
          key: const Key('anesthesiologist-save-button'),
          onPressed: () {
            final draft = _buildDraftItem();
            Navigator.of(context).pop(
              draft == null ? _items : [..._items, draft],
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class SingleFieldDialog extends StatefulWidget {
  const SingleFieldDialog({
    super.key,
    required this.title,
    required this.label,
    required this.initialValue,
    this.hintText,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final String title;
  final String label;
  final String initialValue;
  final String? hintText;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<SingleFieldDialog> createState() => _SingleFieldDialogState();
}

class _SingleFieldDialogState extends State<SingleFieldDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: widget.label,
            hintText: widget.hintText,
            alignLabelWithHint: widget.maxLines > 1,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class ChoiceFieldDialog extends StatelessWidget {
  const ChoiceFieldDialog({
    super.key,
    required this.title,
    required this.options,
    required this.initialValue,
    this.optionLabelBuilder,
  });

  final String title;
  final List<String> options;
  final String initialValue;
  final String Function(String option)? optionLabelBuilder;

  @override
  Widget build(BuildContext context) {
    var selectedValue = initialValue;

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 440,
        child: StatefulBuilder(
          builder: (context, setState) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map(
                    (option) => ChoiceChip(
                      label: Text(
                        optionLabelBuilder?.call(option) ?? option,
                      ),
                      selected: selectedValue == option,
                      onSelected: (_) {
                        setState(() {
                          selectedValue = option;
                        });
                      },
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(''),
          child: const Text('Limpar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(selectedValue),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class ListFieldDialog extends StatefulWidget {
  const ListFieldDialog({
    super.key,
    required this.title,
    required this.label,
    required this.initialItems,
    this.suggestions = const [],
    this.hintText,
  });

  final String title;
  final String label;
  final List<String> initialItems;
  final List<String> suggestions;
  final String? hintText;

  @override
  State<ListFieldDialog> createState() => _ListFieldDialogState();
}

class _ListFieldDialogState extends State<ListFieldDialog> {
  late final TextEditingController _controller;
  late Set<String> _selectedSuggestions;

  @override
  void initState() {
    super.initState();
    _selectedSuggestions = widget.initialItems
        .where(widget.suggestions.contains)
        .toSet();
    _controller = TextEditingController(
      text: widget.initialItems
          .where((item) => !widget.suggestions.contains(item))
          .join('\n'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _manualItems() {
    return _controller.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.suggestions.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.suggestions
                      .map(
                        (item) => FilterChip(
                          label: Text(item),
                          selected: _selectedSuggestions.contains(item),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSuggestions.add(item);
                              } else {
                                _selectedSuggestions.remove(item);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _controller,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hintText ?? 'Um item por linha',
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
          onPressed: () => Navigator.of(context).pop(const <String>[]),
          child: const Text('Limpar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop([
            ..._selectedSuggestions,
            ..._manualItems(),
          ]),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class PatientIdentificationDialog extends StatefulWidget {
  const PatientIdentificationDialog({
    super.key,
    required this.initialPatient,
  });

  final Patient initialPatient;

  @override
  State<PatientIdentificationDialog> createState() =>
      _PatientIdentificationDialogState();
}

class _PatientIdentificationDialogState
    extends State<PatientIdentificationDialog> {
  static const List<String> _asaOptions = ['I', 'II', 'III', 'IV', 'V'];
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
  static const List<String> _commonMedications = [
    'AAS',
    'Clopidogrel',
    'Insulina',
    'Metformina',
    'Beta-bloqueador',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _postnatalAgeController;
  late final TextEditingController _gestationalAgeController;
  late final TextEditingController _correctedGestationalAgeController;
  late final TextEditingController _birthWeightController;
  late final TextEditingController _asaController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _restrictionsController;
  late final TextEditingController _medicationsController;
  late Set<String> _selectedAllergies;
  late Set<String> _selectedRestrictions;
  late Set<String> _selectedMedications;
  late String _selectedAsa;
  late PatientPopulation _selectedPopulation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialPatient.name);
    _ageController = TextEditingController(
      text: widget.initialPatient.age > 0
          ? widget.initialPatient.age.toString()
          : '',
    );
    _weightController = TextEditingController(
      text: widget.initialPatient.weightKg > 0
          ? widget.initialPatient.weightKg.toStringAsFixed(0)
          : '',
    );
    _heightController = TextEditingController(
      text: widget.initialPatient.heightMeters > 0
          ? widget.initialPatient.heightMeters.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _postnatalAgeController = TextEditingController(
      text: widget.initialPatient.postnatalAgeDays > 0
          ? widget.initialPatient.postnatalAgeDays.toString()
          : '',
    );
    _gestationalAgeController = TextEditingController(
      text: widget.initialPatient.gestationalAgeWeeks > 0
          ? widget.initialPatient.gestationalAgeWeeks.toString()
          : '',
    );
    _correctedGestationalAgeController = TextEditingController(
      text: widget.initialPatient.correctedGestationalAgeWeeks > 0
          ? widget.initialPatient.correctedGestationalAgeWeeks.toString()
          : '',
    );
    _birthWeightController = TextEditingController(
      text: widget.initialPatient.birthWeightKg > 0
          ? widget.initialPatient.birthWeightKg.toStringAsFixed(2).replaceAll('.', ',')
          : '',
    );
    _asaController = TextEditingController(text: widget.initialPatient.asa);
    _allergiesController = TextEditingController(
      text: widget.initialPatient.allergies
          .where((item) => !_commonAllergies.contains(item))
          .join('\n'),
    );
    _restrictionsController = TextEditingController(
      text: widget.initialPatient.restrictions
          .where((item) => !_commonRestrictions.contains(item))
          .join('\n'),
    );
    _medicationsController = TextEditingController(
      text: widget.initialPatient.medications
          .where((item) => !_commonMedications.contains(item))
          .join('\n'),
    );
    _selectedAllergies = widget.initialPatient.allergies
        .where(_commonAllergies.contains)
        .toSet();
    _selectedRestrictions = widget.initialPatient.restrictions
        .where(_commonRestrictions.contains)
        .toSet();
    _selectedMedications = widget.initialPatient.medications
        .where(_commonMedications.contains)
        .toSet();
    _selectedAsa = _asaOptions.contains(widget.initialPatient.asa)
        ? widget.initialPatient.asa
        : '';
    _selectedPopulation = widget.initialPatient.population;
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
    _asaController.dispose();
    _allergiesController.dispose();
    _restrictionsController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  List<String> _lines(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Identificação do paciente'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                            setState(() => _selectedPopulation = item);
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: _selectedPopulation == PatientPopulation.neonatal
                            ? 'Idade (anos, se aplicável)'
                            : 'Idade (anos)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      ],
                      decoration: const InputDecoration(labelText: 'Peso (kg)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      ],
                      decoration: const InputDecoration(labelText: 'Altura (m)'),
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
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Idade pós-natal (dias)',
                        ),
                      ),
                    ),
                    if (_selectedPopulation == PatientPopulation.neonatal) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _birthWeightController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
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
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'IG corrigida (semanas)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _asaOptions
                      .map(
                        (item) => ChoiceChip(
                          label: Text('ASA $item'),
                          selected: _selectedAsa == item,
                          onSelected: (_) {
                            setState(() {
                              _selectedAsa = item;
                              _asaController.text = item;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonAllergies
                    .map(
                      (item) => FilterChip(
                        label: Text(item),
                        selected: _selectedAllergies.contains(item),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedAllergies.add(item);
                            } else {
                              _selectedAllergies.remove(item);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _allergiesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alergias',
                  hintText: 'Uma por linha',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonRestrictions
                    .map(
                      (item) => FilterChip(
                        label: Text(item),
                        selected: _selectedRestrictions.contains(item),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedRestrictions.add(item);
                            } else {
                              _selectedRestrictions.remove(item);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _restrictionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Restrições',
                  hintText: 'Uma por linha',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonMedications
                    .map(
                      (item) => FilterChip(
                        label: Text(item),
                        selected: _selectedMedications.contains(item),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedMedications.add(item);
                            } else {
                              _selectedMedications.remove(item);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _medicationsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Medicações em uso',
                  hintText: 'Uma por linha',
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
          onPressed: () => Navigator.of(context).pop(
            widget.initialPatient.copyWith(
              name: _nameController.text.trim(),
              age: int.tryParse(_ageController.text.trim()) ?? 0,
              weightKg:
                  double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0,
              heightMeters:
                  double.tryParse(_heightController.text.replaceAll(',', '.')) ??
                      0,
              population: _selectedPopulation,
              postnatalAgeDays:
                  int.tryParse(_postnatalAgeController.text.trim()) ?? 0,
              gestationalAgeWeeks:
                  int.tryParse(_gestationalAgeController.text.trim()) ?? 0,
              correctedGestationalAgeWeeks:
                  int.tryParse(_correctedGestationalAgeController.text.trim()) ?? 0,
              birthWeightKg:
                  double.tryParse(_birthWeightController.text.replaceAll(',', '.')) ??
                      0,
              asa: _selectedAsa.isNotEmpty
                  ? _selectedAsa
                  : _asaController.text.trim(),
              allergies: [
                ..._selectedAllergies,
                ..._lines(_allergiesController.text),
              ],
              restrictions: [
                ..._selectedRestrictions,
                ..._lines(_restrictionsController.text),
              ],
              medications: [
                ..._selectedMedications,
                ..._lines(_medicationsController.text),
              ],
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
