import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/airway.dart';
import '../models/patient.dart';

enum AirwayEditSection { cormack, device, technique, observation }

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
    _selectedObservationOptions = observationParts
        .where(_observationOptions.contains)
        .toSet();
    _observationController = TextEditingController(
      text: observationParts
          .where((item) => !_observationOptions.contains(item))
          .join('\n'),
    );
  }

  @override
  void dispose() {
    _tubeController.dispose();
    _otherDeviceController.dispose();
    _techniqueController.dispose();
    _observationController.dispose();
    super.dispose();
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
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cormackOptions
                        .map(
                          (item) => ChoiceChip(
                            label: Text('Cormack $item'),
                            selected: _selectedCormack == item,
                            onSelected: (_) {
                              setState(() => _selectedCormack = item);
                            },
                          ),
                        )
                        .toList(),
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
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _deviceOptions
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item),
                            selected: _selectedDevice == item,
                            onSelected: (_) {
                              setState(() => _selectedDevice = item);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (_buildInlineAirwayHint(widget.patient) case final hint?) ...[
                  const SizedBox(height: 12),
                  _InlineAirwayHintCard(
                    title: hint.title,
                    lines: hint.lines,
                  ),
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
                  decoration: const InputDecoration(labelText: 'Número do tubo'),
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
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _techniqueOptions
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item),
                            selected: _techniqueController.text.trim() == item,
                            onSelected: (_) {
                              setState(() => _techniqueController.text = item);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              if (showObservation)
                Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _observationOptions
                            .map(
                              (item) => FilterChip(
                                label: Text(item),
                                selected:
                                    _selectedObservationOptions.contains(item),
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      _selectedObservationOptions.add(item);
                                    } else {
                                      _selectedObservationOptions.remove(item);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('airway-observation-field'),
                      controller: _observationController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Outros',
                      ),
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
              observation: showObservation
                  ? [
                      ..._selectedObservationOptions,
                      ..._observationController.text
                          .split('\n')
                          .map((item) => item.trim())
                          .where((item) => item.isNotEmpty),
                    ].join('\n')
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
      AirwayEditSection.observation => 'Observações',
    };
  }
}

class _InlineAirwayHint {
  const _InlineAirwayHint({
    required this.title,
    required this.lines,
  });

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
      final weightKg =
          patient.weightKg > 0 ? patient.weightKg : patient.birthWeightKg;
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
  const _InlineAirwayHintCard({
    required this.title,
    required this.lines,
  });

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
