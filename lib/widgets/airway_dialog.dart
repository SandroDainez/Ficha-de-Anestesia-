import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/airway.dart';
import '../models/patient.dart';
import 'anesthesia_basic_dialogs.dart';

enum AirwayEditSection { cormack, device, technique, observation }

bool _isAirwayLossEntry(String entry) => entry.startsWith('__LOSS__|');

String _encodeAirwayLossEntry({
  required String material,
  required String quantity,
  required String reason,
}) {
  return '__LOSS__|${material.trim()}|${quantity.trim()}|${reason.trim()}';
}

String _formatAirwayLossEntry(String entry) {
  final parts = entry.split('|');
  if (parts.length < 4) return entry;
  return 'Perda: ${parts[1]} • ${parts[2]} • ${parts[3]}';
}

class AirwayDialog extends StatefulWidget {
  const AirwayDialog({
    super.key,
    required this.initialAirway,
    required this.section,
    required this.patient,
  });

  final Airway initialAirway;
  final AirwayEditSection section;
  final Patient patient;

  @override
  State<AirwayDialog> createState() => _AirwayDialogState();
}

class _AirwayDialogState extends State<AirwayDialog> {
  static const List<String> _cormackOptions = ['I', 'II', 'III', 'IV'];
  static const List<String> _deviceOptions = [
    'TOT',
    'Máscara laríngea',
    'Tubo laríngeo',
    'Outro',
  ];
  static const List<String> _techniqueOptions = [
    'Videolaringoscopia',
    'Laringoscopia direta',
    'Fibroscopia',
  ];
  static const List<String> _observationOptions = ['Fio-guia', 'Bougie'];
  static const List<_AirwayReferenceItem> _cormackReferences = [
    _AirwayReferenceItem(
      grade: 'I',
      description: 'Glote totalmente visível.',
      technique: 'Intubação geralmente simples com laringoscopia direta.',
    ),
    _AirwayReferenceItem(
      grade: 'II',
      description: 'Glote parcialmente visível.',
      technique: 'Bougie ou manipulação externa podem ajudar.',
    ),
    _AirwayReferenceItem(
      grade: 'III',
      description: 'Apenas epiglote visível.',
      technique: 'Preferir videolaringoscópio e preparar resgate.',
    ),
    _AirwayReferenceItem(
      grade: 'IV',
      description: 'Nem epiglote nem glote visíveis.',
      technique: 'Via aérea difícil; considerar fibroscopia/plano avançado.',
    ),
  ];

  late String _selectedCormack;
  late String _selectedDevice;
  late final TextEditingController _tubeController;
  late final TextEditingController _otherDeviceController;
  late final TextEditingController _techniqueController;
  late final TextEditingController _observationController;
  late final TextEditingController _lossMaterialController;
  late final TextEditingController _lossQuantityController;
  late final TextEditingController _lossReasonController;
  late List<String> _lossEntries;
  late Set<String> _selectedObservationOptions;

  @override
  void initState() {
    super.initState();
    _selectedCormack = widget.initialAirway.cormackLehane;
    _selectedDevice = _deviceOptions.contains(widget.initialAirway.device)
        ? widget.initialAirway.device
        : (widget.initialAirway.device.trim().isEmpty ? '' : 'Outro');
    _tubeController = TextEditingController(
      text: widget.initialAirway.tubeNumber,
    );
    _otherDeviceController = TextEditingController(
      text: _deviceOptions.contains(widget.initialAirway.device)
          ? ''
          : widget.initialAirway.device,
    );
    _techniqueController = TextEditingController(
      text: widget.initialAirway.technique,
    );
    final observationParts = widget.initialAirway.observation
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    _lossEntries = observationParts.where(_isAirwayLossEntry).toList();
    _selectedObservationOptions = observationParts
        .where((item) => !_isAirwayLossEntry(item))
        .where(_observationOptions.contains)
        .toSet();
    _observationController = TextEditingController(
      text: observationParts
          .where((item) => !_isAirwayLossEntry(item))
          .where((item) => !_observationOptions.contains(item))
          .join('\n'),
    );
    _lossMaterialController = TextEditingController();
    _lossQuantityController = TextEditingController(text: '1 un');
    _lossReasonController = TextEditingController();
  }

  @override
  void dispose() {
    _tubeController.dispose();
    _otherDeviceController.dispose();
    _techniqueController.dispose();
    _observationController.dispose();
    _lossMaterialController.dispose();
    _lossQuantityController.dispose();
    _lossReasonController.dispose();
    super.dispose();
  }

  List<String> _observationLines({required bool includeEditedObservation}) {
    final baseLines = includeEditedObservation
        ? [
            ..._selectedObservationOptions,
            ..._observationController.text
                .split('\n')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty),
          ]
        : widget.initialAirway.observation
              .split('\n')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty && !_isAirwayLossEntry(item))
              .toList();
    return [...baseLines, ..._lossEntries];
  }

  void _addLossEntry() {
    final material = _lossMaterialController.text.trim();
    final quantity = _lossQuantityController.text.trim();
    final reason = _lossReasonController.text.trim();
    if (material.isEmpty || quantity.isEmpty || reason.isEmpty) return;
    setState(() {
      _lossEntries.add(
        _encodeAirwayLossEntry(
          material: material,
          quantity: quantity,
          reason: reason,
        ),
      );
      _lossMaterialController.clear();
      _lossQuantityController.text = '1 un';
      _lossReasonController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final showCormack = widget.section == AirwayEditSection.cormack;
    final showDevice = widget.section == AirwayEditSection.device;
    final showTechnique = widget.section == AirwayEditSection.technique;
    final showObservation = widget.section == AirwayEditSection.observation;

    return AlertDialog(
      backgroundColor: const Color(0xFFF9FBFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(_titleForSection(widget.section)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCormack) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectionGridSection(
                    options: _cormackOptions,
                    searchEnabled: false,
                    color: const Color(0xFF2B76D2),
                    optionDescriptionBuilder: (item) => 'Cormack $item',
                    isSelected: (item) => _selectedCormack == item,
                    onToggle: (item) {
                      setState(() {
                        _selectedCormack = _selectedCormack == item ? '' : item;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ..._cormackReferences.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AirwayReferenceInfo(
                      titlePrefix: 'Cormack',
                      reference: item,
                    ),
                  ),
                ),
              ],
              if (showDevice) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectionGridSection(
                    options: _deviceOptions,
                    searchEnabled: false,
                    color: const Color(0xFF2B76D2),
                    isSelected: (item) => _selectedDevice == item,
                    onToggle: (item) {
                      setState(() {
                        _selectedDevice = _selectedDevice == item ? '' : item;
                      });
                    },
                  ),
                ),
                if (_buildInlineAirwayHint(widget.patient)
                    case final hint?) ...[
                  const SizedBox(height: 12),
                  _InlineAirwayHintCard(title: hint.title, lines: hint.lines),
                ],
                const SizedBox(height: 14),
                TextField(
                  key: const Key('airway-device-tube-field'),
                  controller: _tubeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Número do tubo',
                  ),
                ),
                if (_selectedDevice == 'Outro') ...[
                  const SizedBox(height: 14),
                  TextField(
                    key: const Key('airway-other-device-field'),
                    controller: _otherDeviceController,
                    decoration: const InputDecoration(
                      labelText: 'Outro dispositivo',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _LossMaterialEditor(
                  title: 'Perda de material do dispositivo',
                  materialController: _lossMaterialController,
                  quantityController: _lossQuantityController,
                  reasonController: _lossReasonController,
                  entries: _lossEntries,
                  onAdd: _addLossEntry,
                  onRemove: (index) {
                    setState(() => _lossEntries.removeAt(index));
                  },
                ),
              ],
              if (showTechnique) ...[
                TextField(
                  key: const Key('airway-technique-field'),
                  controller: _techniqueController,
                  decoration: const InputDecoration(
                    labelText: 'Outros / técnica',
                    hintText:
                        'Videolaringoscopia, laringoscopia direta, fibroscopia...',
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectionGridSection(
                    options: _techniqueOptions,
                    searchEnabled: false,
                    color: const Color(0xFF2B76D2),
                    isSelected: (item) =>
                        _techniqueController.text.trim() == item,
                    onToggle: (item) {
                      setState(() {
                        _techniqueController.text =
                            _techniqueController.text.trim() == item
                            ? ''
                            : item;
                      });
                    },
                  ),
                ),
              ],
              if (showObservation)
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectionGridSection(
                        options: _observationOptions,
                        searchEnabled: false,
                        color: const Color(0xFF2B76D2),
                        isSelected: (item) =>
                            _selectedObservationOptions.contains(item),
                        onToggle: (item) {
                          setState(() {
                            if (_selectedObservationOptions.contains(item)) {
                              _selectedObservationOptions.remove(item);
                            } else {
                              _selectedObservationOptions.add(item);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('airway-observation-field'),
                      controller: _observationController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Outros'),
                    ),
                    const SizedBox(height: 16),
                    _LossMaterialEditor(
                      title: 'Perda de material de apoio',
                      materialController: _lossMaterialController,
                      quantityController: _lossQuantityController,
                      reasonController: _lossReasonController,
                      entries: _lossEntries,
                      onAdd: _addLossEntry,
                      onRemove: (index) {
                        setState(() => _lossEntries.removeAt(index));
                      },
                    ),
                  ],
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
          key: const Key('airway-save-button'),
          onPressed: () => Navigator.of(context).pop(
            widget.initialAirway.copyWith(
              cormackLehane: showCormack
                  ? _selectedCormack
                  : widget.initialAirway.cormackLehane,
              device: showDevice
                  ? (_selectedDevice == 'Outro'
                        ? _otherDeviceController.text.trim()
                        : _selectedDevice)
                  : widget.initialAirway.device,
              tubeNumber: showDevice
                  ? _tubeController.text.trim()
                  : widget.initialAirway.tubeNumber,
              technique: showTechnique
                  ? _techniqueController.text.trim()
                  : widget.initialAirway.technique,
              observation: (showDevice || showObservation)
                  ? _observationLines(
                      includeEditedObservation: showObservation,
                    ).join('\n')
                  : widget.initialAirway.observation,
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  String _titleForSection(AirwayEditSection section) {
    return switch (section) {
      AirwayEditSection.cormack => 'Cormack-Lehane',
      AirwayEditSection.device => 'Dispositivo e tubo',
      AirwayEditSection.technique => 'Técnica de intubação',
      AirwayEditSection.observation => 'Materiais de apoio',
    };
  }
}

class _InlineAirwayHint {
  const _InlineAirwayHint({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

_InlineAirwayHint? _buildInlineAirwayHint(Patient patient) {
  switch (patient.population) {
    case PatientPopulation.adult:
      return null;
    case PatientPopulation.pediatric:
      if (patient.age < 2) {
        return const _InlineAirwayHint(
          title: 'Referência pediátrica',
          lines: [
            'Lactente: individualizar o TOT por peso, escape e ventilação.',
            'As fórmulas etárias ficam menos precisas abaixo de 2 anos.',
          ],
        );
      }

      final cuffed = (patient.age / 4) + 3.5;
      final uncuffed = (patient.age / 4) + 4.0;
      final oralDepth = (patient.age / 2) + 12;
      return _InlineAirwayHint(
        title: 'Referência pediátrica',
        lines: [
          'TOT com cuff: ${cuffed.toStringAsFixed(cuffed.truncateToDouble() == cuffed ? 0 : 1)} mm',
          'TOT sem cuff: ${uncuffed.toStringAsFixed(uncuffed.truncateToDouble() == uncuffed ? 0 : 1)} mm',
          'Profundidade oral estimada: ${oralDepth.toStringAsFixed(0)} cm',
        ],
      );
    case PatientPopulation.neonatal:
      final weightKg = patient.weightKg > 0
          ? patient.weightKg
          : patient.birthWeightKg;
      if (weightKg <= 0) {
        return const _InlineAirwayHint(
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
      return _InlineAirwayHint(
        title: 'Referência neonatal',
        lines: [
          'TOT inicial por peso: $size',
          'Profundidade labial estimada: ${depth.toStringAsFixed(1).replaceAll('.', ',')} cm',
          'Confirmar posição por capnografia e avaliação clínica.',
        ],
      );
  }
}

class _InlineAirwayHintCard extends StatelessWidget {
  const _InlineAirwayHintCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2B76D2),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ...lines.map(
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
    );
  }
}

class _LossMaterialEditor extends StatelessWidget {
  const _LossMaterialEditor({
    required this.title,
    required this.materialController,
    required this.quantityController,
    required this.reasonController,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final TextEditingController materialController;
  final TextEditingController quantityController;
  final TextEditingController reasonController;
  final List<String> entries;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE7F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('airway-loss-material-field'),
            controller: materialController,
            decoration: const InputDecoration(
              labelText: 'Material',
              hintText: 'Ex: TOT 7,5; bougie; fio-guia; máscara laríngea',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('airway-loss-quantity-field'),
            controller: quantityController,
            decoration: const InputDecoration(
              labelText: 'Quantidade',
              hintText: 'Ex: 1 un',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('airway-loss-reason-field'),
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Justificativa',
              hintText: 'Ex: múltiplas tentativas; cuff roto; troca por escape',
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const Key('airway-add-loss-button'),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar perda/consumo'),
            ),
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...entries.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_formatAirwayLossEntry(entry.value)),
                trailing: IconButton(
                  onPressed: () => onRemove(entry.key),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AirwayReferenceItem {
  const _AirwayReferenceItem({
    required this.grade,
    required this.description,
    required this.technique,
  });

  final String grade;
  final String description;
  final String technique;
}

class _AirwayReferenceInfo extends StatelessWidget {
  const _AirwayReferenceInfo({
    required this.titlePrefix,
    required this.reference,
  });

  final String titlePrefix;
  final _AirwayReferenceItem reference;

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
          Text(
            '$titlePrefix ${reference.grade}',
            style: const TextStyle(
              color: Color(0xFF2B76D2),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reference.description,
            style: const TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tecnica sugerida: ${reference.technique}',
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
