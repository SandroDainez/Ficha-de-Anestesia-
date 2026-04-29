import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../models/anesthesia_case.dart';
import '../models/anesthesia_record.dart';
import '../models/airway.dart';
import '../models/fluid_balance.dart';
import '../models/hemodynamic_point.dart';
import '../models/mechanical_ventilation_settings.dart';
import '../models/patient.dart';
import '../models/post_anesthesia_recovery.dart';
import '../models/pre_anesthetic_assessment.dart';
import '../services/ai_record_analysis_service.dart';
import '../services/hemodynamic_record_service.dart';
import '../services/record_validation_service.dart';
import '../services/record_storage_service.dart';
import '../services/report_export_service.dart';
import '../utils/team_member_entry.dart';
import 'post_anesthesia_recovery_screen.dart';
import 'pre_anesthetic_screen.dart';
import '../widgets/anesthesia_basic_dialogs.dart';
import '../widgets/anesthesia_footer_widget.dart';
import '../widgets/anesthesia_medium_dialogs.dart';
import '../widgets/airway_dialog.dart';
import '../widgets/card_widget.dart';
import '../widgets/header_widget.dart';
import '../widgets/intraoperative_entry_dialogs.dart';
import '../widgets/hemodynamic_chart_card.dart';
import '../widgets/json_export_dialog.dart';
import '../widgets/page_container.dart';
import '../widgets/surgery_info_dialog.dart';

class _FluidSupportRecommendation {
  const _FluidSupportRecommendation({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

class _SurgeryAntibioticSuggestionRule {
  const _SurgeryAntibioticSuggestionRule({
    required this.matchTerms,
    required this.title,
    required this.antibioticName,
    required this.dose,
    required this.repeatGuidance,
    this.additionalNotes = '',
  });

  final List<String> matchTerms;
  final String title;
  final String antibioticName;
  final String dose;
  final String repeatGuidance;
  final String additionalNotes;
}

class _MaintenancePreset {
  const _MaintenancePreset({
    required this.name,
    required this.summary,
    required this.defaultDetails,
    this.category = '',
    this.tivaCategory,
    this.tivaSummary,
    this.tivaDetails,
    this.isInhalational = false,
    this.defaultVolPercent = 0,
    this.molecularWeight = 0,
    this.density = 0,
  });

  final String name;
  final String summary;
  final String defaultDetails;
  final String category;
  final String? tivaCategory;
  final String? tivaSummary;
  final String? tivaDetails;
  final bool isInhalational;
  final double defaultVolPercent;
  final double molecularWeight;
  final double density;
}

class _InductionPreset {
  const _InductionPreset({
    required this.name,
    required this.category,
    required this.dosePerKg,
    required this.unit,
    required this.concentrationPerMl,
    required this.concentrationLabel,
  });

  final String name;
  final String category;
  final double dosePerKg;
  final String unit;
  final double concentrationPerMl;
  final String concentrationLabel;
}

class _AdjunctPreset {
  const _AdjunctPreset({
    required this.name,
    required this.dosePerKg,
    required this.unit,
    required this.concentrationPerMl,
    required this.concentrationLabel,
  });

  final String name;
  final double dosePerKg;
  final String unit;
  final double concentrationPerMl;
  final String concentrationLabel;
}

class _UsageSummaryItem {
  const _UsageSummaryItem({
    required this.group,
    required this.name,
    this.quantity = '',
    this.note = '',
    this.priority = 0,
  });

  final String group;
  final String name;
  final String quantity;
  final String note;
  final int priority;
}

class _LossEntry {
  const _LossEntry({
    required this.material,
    required this.quantity,
    required this.reason,
  });

  final String material;
  final String quantity;
  final String reason;
}

class _OxygenTherapyEntry {
  const _OxygenTherapyEntry({
    required this.device,
    required this.flowLPerMin,
    required this.minutes,
  });

  final String device;
  final double flowLPerMin;
  final int minutes;

  double get totalLiters => flowLPerMin * minutes;
}

class _TechniqueProfile {
  const _TechniqueProfile({
    required this.isEmpty,
    required this.hasGeneral,
    required this.hasTiva,
    required this.hasInhalationalGeneral,
    required this.hasGeneralIntravenous,
    required this.hasSedation,
    required this.hasNeuraxial,
    required this.hasRegional,
  });

  final bool isEmpty;
  final bool hasGeneral;
  final bool hasTiva;
  final bool hasInhalationalGeneral;
  final bool hasGeneralIntravenous;
  final bool hasSedation;
  final bool hasNeuraxial;
  final bool hasRegional;

  bool get hasPureRegionalOrNeuraxialFlow =>
      (hasNeuraxial || hasRegional) && !hasGeneral;
}

class _VentilationSuggestion {
  const _VentilationSuggestion({required this.reason, required this.settings});

  final String reason;
  final MechanicalVentilationSettings settings;
}

class _EmergenceDialogResult {
  const _EmergenceDialogResult({required this.status, required this.notes});

  final String status;
  final String notes;
}

double _bodyMassIndex({
  required double weightKg,
  required double heightMeters,
}) {
  if (weightKg <= 0 || heightMeters <= 0) return 0;
  return weightKg / (heightMeters * heightMeters);
}

bool _isEncodedLossEntry(String entry) => entry.startsWith('__LOSS__|');

_LossEntry? _decodeEncodedLossEntry(String entry) {
  if (!_isEncodedLossEntry(entry)) return null;
  final parts = entry.split('|');
  if (parts.length < 4) return null;
  return _LossEntry(
    material: parts[1].trim(),
    quantity: parts[2].trim(),
    reason: parts.sublist(3).join(' | ').trim(),
  );
}

String _encodeLossEntry({
  required String material,
  required String quantity,
  required String reason,
}) {
  return '__LOSS__|$material|$quantity|$reason';
}

String _formatLossEntryLabel(String entry, {String prefix = 'Perda'}) {
  final decoded = _decodeEncodedLossEntry(entry);
  if (decoded == null) return entry;
  final quantity = decoded.quantity.isEmpty
      ? 'quantidade não informada'
      : decoded.quantity;
  final reason = decoded.reason.isEmpty
      ? 'motivo não informado'
      : decoded.reason;
  return '$prefix: ${decoded.material} • $quantity • $reason';
}

bool _isEncodedOxygenTherapyEntry(String entry) => entry.startsWith('__OXY__|');

_OxygenTherapyEntry? _decodeEncodedOxygenTherapyEntry(String entry) {
  if (!_isEncodedOxygenTherapyEntry(entry)) return null;
  final parts = entry.split('|');
  if (parts.length < 4) return null;
  final flowLPerMin = double.tryParse(parts[2].trim());
  final minutes = int.tryParse(parts[3].trim());
  if (flowLPerMin == null ||
      minutes == null ||
      flowLPerMin <= 0 ||
      minutes <= 0) {
    return null;
  }
  return _OxygenTherapyEntry(
    device: parts[1].trim(),
    flowLPerMin: flowLPerMin,
    minutes: minutes,
  );
}

String _encodeOxygenTherapyEntry({
  required String device,
  required double flowLPerMin,
  required int minutes,
}) {
  return '__OXY__|$device|${flowLPerMin.toStringAsFixed(1)}|$minutes';
}

String _oxygenTherapyDeviceLabel(String device) {
  switch (device.trim().toLowerCase()) {
    case 'cateter':
      return 'Cateter de O₂';
    case 'mascara':
      return 'Máscara de O₂';
    default:
      return device.trim().isEmpty ? 'Dispositivo de O₂' : device.trim();
  }
}

String _formatFlowLabel(double flowLPerMin) {
  return flowLPerMin.toStringAsFixed(1).replaceAll('.', ',');
}

String _formatLitersLabel(double liters) {
  final rounded = liters.roundToDouble();
  final decimals = (liters - rounded).abs() < 0.05 ? 0 : 1;
  return liters.toStringAsFixed(decimals).replaceAll('.', ',');
}

String _formatDurationMinutesLabel(int minutes) {
  if (minutes <= 0) return '--';
  if (minutes < 60) return '$minutes min';
  final hours = minutes / 60;
  if (minutes % 60 == 0) {
    return '${hours.toStringAsFixed(0)} h';
  }
  return '${hours.toStringAsFixed(1).replaceAll('.', ',')} h';
}

String _formatOxygenTherapyEntryLabel(String entry) {
  final decoded = _decodeEncodedOxygenTherapyEntry(entry);
  if (decoded == null) return entry;
  return '${_oxygenTherapyDeviceLabel(decoded.device)} • ${_formatFlowLabel(decoded.flowLPerMin)} L/min • ${_formatDurationMinutesLabel(decoded.minutes)} • consumo ${_formatLitersLabel(decoded.totalLiters)} L';
}

class _AirwaySupportRecommendation {
  const _AirwaySupportRecommendation({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;
}

class _QuickChoiceOption {
  const _QuickChoiceOption({
    required this.value,
    required this.title,
    required this.description,
    this.supportingText = '',
  });

  final String value;
  final String title;
  final String description;
  final String supportingText;
}

class _DetailedChoiceDialog extends StatefulWidget {
  const _DetailedChoiceDialog({
    required this.title,
    required this.options,
    required this.color,
    this.initialValue = '',
    this.customLabel,
    this.customHintText,
    this.footerText = '',
  });

  final String title;
  final List<_QuickChoiceOption> options;
  final Color color;
  final String initialValue;
  final String? customLabel;
  final String? customHintText;
  final String footerText;

  @override
  State<_DetailedChoiceDialog> createState() => _DetailedChoiceDialogState();
}

class _DetailedChoiceDialogState extends State<_DetailedChoiceDialog> {
  late String _selectedValue;
  late final TextEditingController _customController;
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final matchesPreset = widget.options.any(
      (option) => option.value == widget.initialValue,
    );
    _selectedValue = matchesPreset ? widget.initialValue : '';
    _customController = TextEditingController(
      text: matchesPreset ? '' : widget.initialValue,
    );
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _customController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allowsCustom = widget.customLabel != null;
    return AlertDialog(
      backgroundColor: const Color(0xFFF3F6FC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      titlePadding: const EdgeInsets.fromLTRB(56, 40, 56, 0),
      contentPadding: const EdgeInsets.fromLTRB(56, 28, 56, 24),
      actionsPadding: const EdgeInsets.fromLTRB(40, 0, 40, 30),
      title: Text(
        widget.title,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF6A7E94),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFBF8EF),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFD5E4F7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFFD5E4F7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: widget.color, width: 1.2),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 22),
              Builder(
                builder: (context) {
                  final normalizedQuery = _query.trim().toLowerCase();
                  final filteredOptions = widget.options.where((option) {
                    final haystack =
                        '${option.title} ${option.description} ${option.supportingText}'
                            .toLowerCase();
                    return normalizedQuery.isEmpty ||
                        haystack.contains(normalizedQuery);
                  }).toList();

                  if (filteredOptions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 56),
                      child: Center(
                        child: Text(
                          'Nenhuma opção encontrada para a busca.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF7A8EA5),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900 ? 2 : 1;
                      final columnChildren = List.generate(
                        columns,
                        (_) => <Widget>[],
                      );

                      for (var i = 0; i < filteredOptions.length; i++) {
                        final option = filteredOptions[i];
                        final selected =
                            _selectedValue == option.value &&
                            _customController.text.trim().isEmpty;
                        columnChildren[i % columns].add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () {
                                  setState(() {
                                    _selectedValue = option.value;
                                    if (allowsCustom) {
                                      _customController.clear();
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? widget.color.withAlpha(12)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: selected
                                          ? widget.color
                                          : const Color(0xFFD5E4F7),
                                      width: selected ? 1.4 : 1,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0A17324D),
                                        blurRadius: 14,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (selected) ...[
                                        Icon(
                                          Icons.check_rounded,
                                          color: widget.color,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              option.title,
                                              style: TextStyle(
                                                color: widget.color,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              option.description,
                                              style: const TextStyle(
                                                color: Color(0xFF17324D),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (option
                                                .supportingText
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                option.supportingText,
                                                style: const TextStyle(
                                                  color: Color(0xFF5D7288),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < columns; i++) ...[
                            Expanded(
                              child: Column(children: columnChildren[i]),
                            ),
                            if (i != columns - 1) const SizedBox(width: 16),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
              if (allowsCustom) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: widget.customLabel,
                    hintText: widget.customHintText,
                  ),
                  onTap: () {
                    if (_selectedValue.isNotEmpty) {
                      setState(() {
                        _selectedValue = '';
                      });
                    }
                  },
                  onChanged: (_) {
                    if (_selectedValue.isNotEmpty) {
                      setState(() {
                        _selectedValue = '';
                      });
                    }
                  },
                ),
              ],
              if (widget.footerText.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  widget.footerText,
                  style: const TextStyle(
                    color: Color(0xFF5D7288),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3C6C9C),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
          onPressed: () => Navigator.of(context).pop(''),
          child: const Text('Limpar'),
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
          onPressed: () => Navigator.of(context).pop(
            _customController.text.trim().isNotEmpty
                ? _customController.text.trim()
                : _selectedValue,
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _FastingQuickEditResult {
  const _FastingQuickEditResult({
    required this.solids,
    required this.liquids,
    required this.breastMilk,
    required this.notes,
  });

  final String solids;
  final String liquids;
  final String breastMilk;
  final String notes;
}

class _FastingQuickEditDialog extends StatefulWidget {
  const _FastingQuickEditDialog({
    required this.population,
    required this.initialSolids,
    required this.initialLiquids,
    required this.initialBreastMilk,
    required this.initialNotes,
  });

  final PatientPopulation population;
  final String initialSolids;
  final String initialLiquids;
  final String initialBreastMilk;
  final String initialNotes;

  @override
  State<_FastingQuickEditDialog> createState() =>
      _FastingQuickEditDialogState();
}

class _FastingQuickEditDialogState extends State<_FastingQuickEditDialog> {
  static const List<String> _solidOptions = ['<6h', '6-8h', '>8h'];
  static const List<String> _liquidOptions = ['<2h', '2-4h', '>4h'];
  static const List<String> _breastMilkOptions = ['<4h', '4-6h', '>6h'];

  late String _selectedSolids;
  late String _selectedLiquids;
  late String _selectedBreastMilk;
  late final TextEditingController _notesController;

  bool get _showBreastMilk => widget.population != PatientPopulation.adult;

  @override
  void initState() {
    super.initState();
    _selectedSolids = _solidOptions.contains(widget.initialSolids)
        ? widget.initialSolids
        : '';
    _selectedLiquids = _liquidOptions.contains(widget.initialLiquids)
        ? widget.initialLiquids
        : '';
    _selectedBreastMilk = _breastMilkOptions.contains(widget.initialBreastMilk)
        ? widget.initialBreastMilk
        : '';
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildOptionGroup({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF17324D),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SelectionGridSection(
          options: options,
          searchEnabled: false,
          isSelected: (option) => selectedValue == option,
          onToggle: (option) =>
              setState(() => onSelected(selectedValue == option ? '' : option)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final solidsLabel = widget.population == PatientPopulation.adult
        ? 'Sólidos'
        : 'Fórmula / refeição';
    return AlertDialog(
      title: const Text('Jejum'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOptionGroup(
                title: solidsLabel,
                options: _solidOptions,
                selectedValue: _selectedSolids,
                onSelected: (value) => _selectedSolids = value,
              ),
              const SizedBox(height: 14),
              if (_showBreastMilk) ...[
                _buildOptionGroup(
                  title: 'Leite materno',
                  options: _breastMilkOptions,
                  selectedValue: _selectedBreastMilk,
                  onSelected: (value) => _selectedBreastMilk = value,
                ),
                const SizedBox(height: 14),
              ],
              _buildOptionGroup(
                title: 'Líquidos claros',
                options: _liquidOptions,
                selectedValue: _selectedLiquids,
                onSelected: (value) => _selectedLiquids = value,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText:
                      'Ex: jejum inadequado, horário informado pela família',
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
            const _FastingQuickEditResult(
              solids: '',
              liquids: '',
              breastMilk: '',
              notes: '',
            ),
          ),
          child: const Text('Limpar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _FastingQuickEditResult(
              solids: _selectedSolids,
              liquids: _selectedLiquids,
              breastMilk: _showBreastMilk ? _selectedBreastMilk : '',
              notes: _notesController.text.trim(),
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

double _adultReferenceWeightKg({
  required double actualWeightKg,
  required double heightMeters,
}) {
  if (actualWeightKg <= 0) return 70;
  if (heightMeters <= 0) return actualWeightKg;
  final bmi = actualWeightKg / (heightMeters * heightMeters);
  if (bmi < 30) return actualWeightKg;
  final referenceWeight = 25 * heightMeters * heightMeters;
  return referenceWeight < actualWeightKg ? referenceWeight : actualWeightKg;
}

double _pediatricMaintenanceRateMlPerHour(double weightKg) {
  if (weightKg <= 0) return 0;
  if (weightKg <= 10) return weightKg * 4;
  if (weightKg <= 20) return 40 + ((weightKg - 10) * 2);
  return 60 + (weightKg - 20);
}

(double lowerMlPerHour, double upperMlPerHour)? _termNeonateMaintenanceRange({
  required double weightKg,
  required int postnatalAgeDays,
}) {
  if (weightKg <= 0 || postnatalAgeDays <= 0) return null;

  final (lowerPerDay, upperPerDay) = switch (postnatalAgeDays) {
    <= 1 => (50.0, 60.0),
    2 => (70.0, 80.0),
    3 => (80.0, 100.0),
    4 => (100.0, 120.0),
    _ => (120.0, 150.0),
  };

  return ((weightKg * lowerPerDay) / 24, (weightKg * upperPerDay) / 24);
}

String _formatHoursReferenceLabel(double hours) {
  if (hours <= 0) return '--';
  if (hours < 1) return '${(hours * 60).round()} min';
  return '${hours.toStringAsFixed(1).replaceAll('.', ',')} h';
}

_FluidSupportRecommendation _buildFluidSupportRecommendation({
  required Patient patient,
  required double documentedLossesMl,
  required String fastingHoursText,
  required String surgicalSize,
}) {
  final fasting = fastingHoursText.trim();
  final sizeFactor = switch (surgicalSize) {
    'Pequeno' => 2.0,
    'Medio' => 4.0,
    'Grande' => 6.0,
    _ => 0.0,
  };

  switch (patient.population) {
    case PatientPopulation.adult:
      final referenceWeight = _adultReferenceWeightKg(
        actualWeightKg: patient.weightKg,
        heightMeters: patient.heightMeters,
      );
      final lower = (referenceWeight * 25) / 24;
      final upper = (referenceWeight * 30) / 24;

      return _FluidSupportRecommendation(
        title: 'Apoio clínico adulto',
        lines: [
          'Manutenção basal: 25-30 mL/kg/dia (~${lower.toStringAsFixed(0)}-${upper.toStringAsFixed(0)} mL/h).',
          'Preferir peso de referência se obesidade.',
          'Jejum: não repor déficit fixo automaticamente; considerar só se prolongado, com hipovolemia ou conforme protocolo local.',
          'Reposição intraoperatória: individualizar por perdas mensuráveis, sangramento, diurese, exposição cirúrgica e resposta hemodinâmica.',
          'Evitar regra fixa de terceiro espaço.',
          'Perdas registradas: ${documentedLossesMl.toStringAsFixed(0)} mL',
          if (fasting.isNotEmpty) 'Jejum informado: $fasting h',
        ],
      );

    case PatientPopulation.pediatric:
      final maintenance = _pediatricMaintenanceRateMlPerHour(patient.weightKg);
      final intraopRate = patient.weightKg * sizeFactor;
      final glucoseLine = patient.age > 0 && patient.age < 2
          ? 'Em lactentes pequenos, considerar glicose 1-2,5% com monitorização de glicemia.'
          : 'Glicose não é rotineira fora do período neonatal; considerar se risco de hipoglicemia.';

      return _FluidSupportRecommendation(
        title: 'Apoio clínico pediátrico',
        lines: [
          'Manutenção: ${maintenance.toStringAsFixed(0)} mL/h',
          if (intraopRate > 0)
            'Intraoperatória sugerida: ${intraopRate.toStringAsFixed(0)} mL/h pelo porte $surgicalSize',
          'Cálculo basal por Holliday-Segar (4-2-1).',
          'Preferir cristalóide isotônico com sódio 131-154 mmol/L.',
          glucoseLine,
          'Perdas registradas: ${documentedLossesMl.toStringAsFixed(0)} mL',
        ],
      );

    case PatientPopulation.neonatal:
      final isTerm = patient.gestationalAgeWeeks >= 37;
      final range = isTerm
          ? _termNeonateMaintenanceRange(
              weightKg: patient.weightKg > 0
                  ? patient.weightKg
                  : patient.birthWeightKg,
              postnatalAgeDays: patient.postnatalAgeDays,
            )
          : null;

      final lines = <String>[
        if (range != null)
          'Manutenção: ${range.$1.toStringAsFixed(0)}-${range.$2.toStringAsFixed(0)} mL/h'
        else
          'Sem taxa automática fixa no sistema.',
        if (sizeFactor > 0 &&
            (patient.weightKg > 0 || patient.birthWeightKg > 0))
          'Intraoperatória sugerida: ${((patient.weightKg > 0 ? patient.weightKg : patient.birthWeightKg) * (sizeFactor + 2)).toStringAsFixed(0)} mL/h pelo porte $surgicalSize',
        if (isTerm && patient.postnatalAgeDays > 0)
          'Neonato termo, ${patient.postnatalAgeDays} dia(s) de vida.'
        else if (patient.gestationalAgeWeeks <= 0)
          'Informar idade gestacional para sugerir faixa de manutenção neonatal.'
        else
          'Prematuro: individualizar com glicemia, sódio e contexto cirúrgico.',
        'Manutenção inicial: cristalóide isotônico com sódio 131-154 mmol/L e glicose 5-10%.',
        'Perdas registradas: ${documentedLossesMl.toStringAsFixed(0)} mL',
      ];

      return _FluidSupportRecommendation(
        title: 'Apoio clínico neonatal',
        lines: lines,
      );
  }
}

_AirwaySupportRecommendation? _buildAirwaySupportRecommendation(
  Patient patient,
) {
  switch (patient.population) {
    case PatientPopulation.adult:
      return null;
    case PatientPopulation.pediatric:
      if (patient.age < 2) {
        return const _AirwaySupportRecommendation(
          title: 'Referência pediátrica',
          lines: [
            'Lactente: individualizar o TOT por peso, escape e mecânica ventilatória.',
            'Fórmulas etárias ficam menos precisas abaixo de 2 anos.',
          ],
        );
      }

      final cuffed = (patient.age / 4) + 3.5;
      final uncuffed = (patient.age / 4) + 4.0;
      final oralDepth = (patient.age / 2) + 12;

      return _AirwaySupportRecommendation(
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
        return const _AirwaySupportRecommendation(
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

      return _AirwaySupportRecommendation(
        title: 'Referência neonatal',
        lines: [
          'TOT inicial por peso: $size',
          'Profundidade labial estimada: ${depth.toStringAsFixed(1).replaceAll('.', ',')} cm',
          'Confirmar posição por capnografia, ausculta e imagem quando aplicável.',
        ],
      );
  }
}

List<String> _recommendedMonitoringItems(Patient patient) {
  switch (patient.population) {
    case PatientPopulation.adult:
    case PatientPopulation.pediatric:
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

class AnesthesiaScreen extends StatefulWidget {
  const AnesthesiaScreen({
    super.key,
    this.initialRecord,
    this.loadPersistedRecord = false,
    this.autoOpenPreAnesthetic = false,
    this.caseId,
    this.initialCaseStatus = AnesthesiaCaseStatus.inProgress,
    this.createdAtIso,
    this.initialPreAnestheticDate = '',
    this.initialAnesthesiaDate = '',
  });

  final AnesthesiaRecord? initialRecord;
  final bool loadPersistedRecord;
  final bool autoOpenPreAnesthetic;
  final String? caseId;
  final AnesthesiaCaseStatus initialCaseStatus;
  final String? createdAtIso;
  final String initialPreAnestheticDate;
  final String initialAnesthesiaDate;

  @override
  State<AnesthesiaScreen> createState() => _AnesthesiaScreenState();
}

class _AnesthesiaScreenState extends State<AnesthesiaScreen> {
  static const Color _surgeryRowColor = Color(0xFF5A6F86);
  static const Color _preInductionPhaseColor = Color(0xFF2B76D2);
  static const Color _inductionPhaseColor = Color(0xFF8A5DD3);
  static const Color _maintenancePhaseColor = Color(0xFF168B79);
  static const Color _emergencePhaseColor = Color(0xFFD27A1F);
  static const Color _timeoutRowColor = _preInductionPhaseColor;
  static const Color _accessRowColor = _preInductionPhaseColor;
  static const Color _techniqueRowColor = _inductionPhaseColor;
  static const Color _medicationsRowColor = _maintenancePhaseColor;
  static const Color _airwayFluidRowColor = _inductionPhaseColor;
  static const List<_QuickChoiceOption> _adultFunctionalOptions = [
    _QuickChoiceOption(
      value: '1 MET',
      title: '1 MET',
      description: 'Restrito a autocuidado.',
      supportingText: 'Dependente para atividades básicas ou esforço mínimo.',
    ),
    _QuickChoiceOption(
      value: '2-3 METs',
      title: '2-3',
      description: 'Caminha dentro de casa.',
      supportingText: 'Baixa reserva funcional para esforços leves.',
    ),
    _QuickChoiceOption(
      value: '4 METs',
      title: '4',
      description: 'Sobe 1 lance de escada.',
      supportingText: 'Capacidade funcional intermediária.',
    ),
    _QuickChoiceOption(
      value: '>4 METs',
      title: '>4',
      description: 'Boa capacidade funcional.',
      supportingText: 'Tolera esforço habitual sem limitação relevante.',
    ),
    _QuickChoiceOption(
      value: '>10 METs',
      title: '>10',
      description: 'Exercício vigoroso.',
      supportingText: 'Alta reserva funcional.',
    ),
  ];
  static const List<_QuickChoiceOption> _pediatricFunctionalOptions = [
    _QuickChoiceOption(
      value: 'Atividade preservada',
      title: 'OK',
      description: 'Brinca e acompanha a rotina habitual.',
      supportingText: 'Sem limitação funcional relevante.',
    ),
    _QuickChoiceOption(
      value: 'Limitação leve',
      title: 'Leve',
      description: 'Cansaço, tosse ou chiado aos esforços.',
      supportingText: 'Sintomas leves ao brincar ou correr.',
    ),
    _QuickChoiceOption(
      value: 'Limitação importante',
      title: 'Alta',
      description: 'Dispneia, intolerância ou esforço reduzido.',
      supportingText: 'Reserva funcional baixa para a idade.',
    ),
  ];
  static const List<_QuickChoiceOption> _neonatalFunctionalOptions = [
    _QuickChoiceOption(
      value: 'Estável em ar ambiente',
      title: 'AA',
      description: 'Sem suporte atual e sem eventos recentes.',
      supportingText: 'Bom padrão clínico neonatal.',
    ),
    _QuickChoiceOption(
      value: 'Oxigênio recente',
      title: 'O2',
      description: 'Necessidade recente de oxigênio suplementar.',
      supportingText: 'Alerta intermediário.',
    ),
    _QuickChoiceOption(
      value: 'Apneia/bradicardia',
      title: 'A/B',
      description: 'Eventos recentes ou em investigação.',
      supportingText: 'Maior risco perioperatório.',
    ),
    _QuickChoiceOption(
      value: 'Suporte ventilatório',
      title: 'VM',
      description: 'CPAP ou ventilação mecânica recente.',
      supportingText: 'Reserva clínica reduzida.',
    ),
  ];
  static const List<_QuickChoiceOption> _asaReferenceOptions = [
    _QuickChoiceOption(
      value: 'I',
      title: 'I',
      description:
          'Paciente saudavel, sem doenca sistemica clinicamente relevante.',
      supportingText:
          'Ex: adulto sem comorbidades ou crianca saudavel para cirurgia eletiva.',
    ),
    _QuickChoiceOption(
      value: 'II',
      title: 'II',
      description: 'Doenca sistemica leve, sem limitacao funcional importante.',
      supportingText:
          'Ex: HAS controlada, obesidade leve, tabagismo, gestacao, asma leve.',
    ),
    _QuickChoiceOption(
      value: 'III',
      title: 'III',
      description:
          'Doenca sistemica importante, com repercussao funcional ou clinica relevante.',
      supportingText:
          'Ex: DM descompensado, obesidade grave, DPOC, IRC dialitica, DAC estavel.',
    ),
    _QuickChoiceOption(
      value: 'IV',
      title: 'IV',
      description:
          'Doenca sistemica grave que representa ameaca constante a vida.',
      supportingText:
          'Ex: ICC descompensada, angina instavel, sepse, insuficiencia respiratoria.',
    ),
    _QuickChoiceOption(
      value: 'V',
      title: 'V',
      description:
          'Paciente moribundo, sem expectativa de sobreviver sem a cirurgia.',
      supportingText:
          'Ex: ruptura de aneurisma, politrauma grave, choque refratario.',
    ),
    _QuickChoiceOption(
      value: 'VI',
      title: 'VI',
      description:
          'Paciente com morte encefalica mantido para doacao de orgaos.',
      supportingText: 'Usado em contexto de captacao de orgaos.',
    ),
  ];
  static const List<_QuickChoiceOption> _mallampatiReferenceOptions = [
    _QuickChoiceOption(
      value: 'I',
      title: 'I',
      description: 'Palato mole, fauces, uvula e pilares visiveis.',
      supportingText: 'Laringoscopia direta usualmente adequada.',
    ),
    _QuickChoiceOption(
      value: 'II',
      title: 'II',
      description: 'Palato mole, fauces e parte da uvula visiveis.',
      supportingText:
          'Laringoscopia direta ou videolaringoscopio conforme contexto.',
    ),
    _QuickChoiceOption(
      value: 'III',
      title: 'III',
      description: 'Palato mole e base da uvula visiveis.',
      supportingText:
          'Preferir videolaringoscopio e planejar via aerea dificil.',
    ),
    _QuickChoiceOption(
      value: 'IV',
      title: 'IV',
      description: 'Somente palato duro visivel.',
      supportingText:
          'Videolaringoscopio/fibroscopia e estrategia de resgate pronta.',
    ),
  ];
  static const List<String> _adultDifficultAirwayPredictorOptions = [
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
  static const List<String> _adultDifficultVentilationPredictorOptions = [
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
  static const List<String> _pediatricRestrictions = [
    'Objeção familiar a hemocomponentes',
    'Acompanhante na indução',
    'Consentimento do responsável',
    'Alergia ao látex',
  ];
  static const List<String> _neonatalRestrictions = [
    'Objeção familiar a hemocomponentes',
    'Consentimento do responsável',
    'Necessita leito de UTI',
    'Necessita termorregulação rigorosa',
  ];
  static const List<String> _commonMedications = [
    'AAS',
    'Clopidogrel',
    'Insulina',
    'Metformina',
    'Beta-bloqueador',
  ];
  static const List<String> _pediatricCommonMedications = [
    'Broncodilatador',
    'Corticoide inalatório',
    'Anticonvulsivante',
    'Insulina',
  ];
  static const List<String> _neonatalCommonMedications = [
    'Cafeína',
    'Prostaglandina',
    'Diurético',
    'Antibiótico',
  ];
  static const Map<String, String> _adultProphylacticAntibioticOptions = {
    'Cefazolina': '2 g',
    'Cefuroxima': '1,5 g',
    'Clindamicina': '600-900 mg',
    'Vancomicina': '15 mg/kg',
    'Metronidazol': '500 mg',
  };
  static const Map<String, String> _pediatricProphylacticAntibioticOptions = {
    'Cefazolina': '30 mg/kg',
    'Clindamicina': '10 mg/kg',
    'Vancomicina': '15 mg/kg',
    'Metronidazol': '7,5 mg/kg',
  };
  static const Map<String, String> _neonatalProphylacticAntibioticOptions = {
    'Cefazolina': '25 mg/kg',
    'Vancomicina': '15 mg/kg',
    'Gentamicina': '4-5 mg/kg',
  };
  static const List<String> _monitoringOptions = [
    'ECG (5 derivações)',
    'PA não invasiva',
    'PAI',
    'SpO₂',
    'Capnografia',
    'Temperatura',
    'BIS',
  ];
  static const List<String> _preAnesthesiaChecklistOptions = [
    'Equipamento de anestesia checado',
    'Materiais para intubação disponíveis e testados',
    'Termo de consentimento assinado',
    'Pré-anestésico realizado',
    'Monitorização instalada e funcionando',
    'Acesso venoso pérvio',
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
  static const Map<String, Duration> _prophylacticRedoseIntervals = {
    'Cefazolina': Duration(hours: 4),
    'Cefuroxima': Duration(hours: 4),
    'Clindamicina': Duration(hours: 6),
  };
  static const List<_InductionPreset> _inductionPresets = [
    _InductionPreset(
      name: 'Propofol',
      category: 'Hipnótico',
      dosePerKg: 2.0,
      unit: 'mg',
      concentrationPerMl: 10,
      concentrationLabel: '10 mg/mL',
    ),
    _InductionPreset(
      name: 'Etomidato',
      category: 'Hipnótico',
      dosePerKg: 0.25,
      unit: 'mg',
      concentrationPerMl: 2,
      concentrationLabel: '2 mg/mL',
    ),
    _InductionPreset(
      name: 'Cetamina',
      category: 'Hipnótico',
      dosePerKg: 1.5,
      unit: 'mg',
      concentrationPerMl: 50,
      concentrationLabel: '50 mg/mL',
    ),
    _InductionPreset(
      name: 'Fentanil',
      category: 'Opioide',
      dosePerKg: 3.0,
      unit: 'mcg',
      concentrationPerMl: 50,
      concentrationLabel: '50 mcg/mL',
    ),
    _InductionPreset(
      name: 'Alfentanil',
      category: 'Opioide',
      dosePerKg: 20.0,
      unit: 'mcg',
      concentrationPerMl: 500,
      concentrationLabel: '500 mcg/mL',
    ),
    _InductionPreset(
      name: 'Sufentanil',
      category: 'Opioide',
      dosePerKg: 0.3,
      unit: 'mcg',
      concentrationPerMl: 50,
      concentrationLabel: '50 mcg/mL',
    ),
    _InductionPreset(
      name: 'Remifentanil',
      category: 'Opioide',
      dosePerKg: 1.0,
      unit: 'mcg',
      concentrationPerMl: 50,
      concentrationLabel: '50 mcg/mL (diluição usual)',
    ),
    _InductionPreset(
      name: 'Rocurônio',
      category: 'Bloqueador neuromuscular',
      dosePerKg: 0.6,
      unit: 'mg',
      concentrationPerMl: 10,
      concentrationLabel: '10 mg/mL',
    ),
    _InductionPreset(
      name: 'Cisatracúrio',
      category: 'Bloqueador neuromuscular',
      dosePerKg: 0.15,
      unit: 'mg',
      concentrationPerMl: 2,
      concentrationLabel: '2 mg/mL',
    ),
    _InductionPreset(
      name: 'Atracúrio',
      category: 'Bloqueador neuromuscular',
      dosePerKg: 0.5,
      unit: 'mg',
      concentrationPerMl: 10,
      concentrationLabel: '10 mg/mL',
    ),
    _InductionPreset(
      name: 'Succinilcolina',
      category: 'Bloqueador neuromuscular',
      dosePerKg: 1.0,
      unit: 'mg',
      concentrationPerMl: 20,
      concentrationLabel: '20 mg/mL',
    ),
  ];
  static const List<_AdjunctPreset> _adjunctPresets = [
    _AdjunctPreset(
      name: 'Sulfato de Mg',
      dosePerKg: 40,
      unit: 'mg',
      concentrationPerMl: 100,
      concentrationLabel: '100 mg/mL',
    ),
    _AdjunctPreset(
      name: 'Cetamina',
      dosePerKg: 0.25,
      unit: 'mg',
      concentrationPerMl: 50,
      concentrationLabel: '50 mg/mL',
    ),
    _AdjunctPreset(
      name: 'Clonidina',
      dosePerKg: 1.5,
      unit: 'mcg',
      concentrationPerMl: 150,
      concentrationLabel: '150 mcg/mL',
    ),
    _AdjunctPreset(
      name: 'Metadona',
      dosePerKg: 0.15,
      unit: 'mg',
      concentrationPerMl: 10,
      concentrationLabel: '10 mg/mL',
    ),
    _AdjunctPreset(
      name: 'Dexmedetomidina (Precedex)',
      dosePerKg: 0.7,
      unit: 'mcg',
      concentrationPerMl: 4,
      concentrationLabel: '4 mcg/mL',
    ),
    _AdjunctPreset(
      name: 'Lidocaína',
      dosePerKg: 1.0,
      unit: 'mg',
      concentrationPerMl: 20,
      concentrationLabel: '20 mg/mL (2%)',
    ),
  ];
  static const List<_MaintenancePreset> _maintenancePresets = [
    _MaintenancePreset(
      name: 'Propofol em BIC',
      category: 'Anestésicos EV contínuos em bomba',
      summary: 'EV contínua em bomba',
      defaultDetails: '50-100 mcg/kg/min (3-6 mg/kg/h)',
      tivaCategory: 'Manutenção TIVA',
      tivaSummary: 'TIVA em bomba',
      tivaDetails: '100-200 mcg/kg/min (6-12 mg/kg/h)',
    ),
    _MaintenancePreset(
      name: 'Remifentanil em BIC',
      category: 'Opioides EV contínuos em bomba',
      summary: 'EV contínua em bomba',
      defaultDetails: '0,05-0,2 mcg/kg/min',
      tivaCategory: 'Manutenção TIVA',
      tivaSummary: 'TIVA em bomba',
      tivaDetails: '0,05-0,25 mcg/kg/min',
    ),
    _MaintenancePreset(
      name: 'Fentanil em repiques',
      category: 'Opioides',
      summary: 'Reforços intraoperatórios',
      defaultDetails: '25-50 mcg conforme estímulo',
    ),
    _MaintenancePreset(
      name: 'Rocurônio em repiques',
      category: 'Bloqueadores neuromusculares',
      summary: 'Reforços guiados por TOF',
      defaultDetails: '0,1-0,2 mg/kg por repique',
    ),
    _MaintenancePreset(
      name: 'Cisatracúrio em repiques',
      category: 'Bloqueadores neuromusculares',
      summary: 'Reforços guiados por TOF',
      defaultDetails: '0,03 mg/kg por repique',
    ),
    _MaintenancePreset(
      name: 'Sevoflurano',
      category: 'Anestésicos inalatórios',
      summary: 'Inalatório',
      defaultDetails: '2,0 vol%',
      isInhalational: true,
      defaultVolPercent: 2.0,
      molecularWeight: 200.05,
      density: 1.52,
    ),
    _MaintenancePreset(
      name: 'Isoflurano',
      category: 'Anestésicos inalatórios',
      summary: 'Inalatório',
      defaultDetails: '1,2 vol%',
      isInhalational: true,
      defaultVolPercent: 1.2,
      molecularWeight: 184.5,
      density: 1.50,
    ),
    _MaintenancePreset(
      name: 'Desflurano',
      category: 'Anestésicos inalatórios',
      summary: 'Inalatório',
      defaultDetails: '6,0 vol%',
      isInhalational: true,
      defaultVolPercent: 6.0,
      molecularWeight: 168.0,
      density: 1.47,
    ),
  ];
  static const List<_SurgeryAntibioticSuggestionRule>
  _adultSurgeryAntibioticSuggestionRules = [
    _SurgeryAntibioticSuggestionRule(
      matchTerms: ['histerectomia', 'colecistectomia', 'apendicectomia'],
      title: 'Ginecológica / abdominal limpa-contaminada',
      antibioticName: 'Cefazolina',
      dose: '2 g IV',
      repeatGuidance:
          'Redose em 4 h se cirurgia prolongada ou perda sanguínea importante.',
      additionalNotes:
          'Indicação habitual para profilaxia de procedimentos ginecológicos e abdominais sem alergia beta-lactâmica.',
    ),
    _SurgeryAntibioticSuggestionRule(
      matchTerms: ['bariátrica', 'sleeve', 'bypass'],
      title: 'Bariátrica',
      antibioticName: 'Cefazolina',
      dose: '2 g IV (3 g se peso >= 120 kg)',
      repeatGuidance: 'Redose em 4 h ou antes se grande perda sanguínea.',
      additionalNotes:
          'Ajustar para 3 g em obesidade importante quando aplicável.',
    ),
    _SurgeryAntibioticSuggestionRule(
      matchTerms: [
        'herniorrafia',
        'hernia',
        'inguinal',
        'umbilical',
        'incisional',
      ],
      title: 'Parede abdominal / hernioplastia',
      antibioticName: 'Cefazolina',
      dose: '2 g IV',
      repeatGuidance:
          'Redose em 4 h se tela, duração prolongada ou sangramento.',
      additionalNotes:
          'Considerar profilaxia sobretudo quando houver implante de tela.',
    ),
    _SurgeryAntibioticSuggestionRule(
      matchTerms: [
        'fratura de fêmur',
        'artroplastia',
        'joelho',
        'quadril',
        'ortop',
      ],
      title: 'Ortopédica',
      antibioticName: 'Cefazolina',
      dose: '2 g IV',
      repeatGuidance:
          'Redose em 4 h; considerar cobertura adicional conforme implante e protocolo local.',
      additionalNotes:
          'Em prótese/implante, respeitar tempo de infusão antes da incisão.',
    ),
    _SurgeryAntibioticSuggestionRule(
      matchTerms: ['nefrectomia', 'urol'],
      title: 'Urológica',
      antibioticName: 'Cefazolina',
      dose: '2 g IV',
      repeatGuidance: 'Redose em 4 h se procedimento prolongado.',
      additionalNotes:
          'Se manipulação de trato urinário contaminado, individualizar conforme urocultura e protocolo local.',
    ),
    _SurgeryAntibioticSuggestionRule(
      matchTerms: ['mastectomia', 'quadrantectomia', 'mama', 'prótese de mama'],
      title: 'Mama / plástica com implante',
      antibioticName: 'Cefazolina',
      dose: '2 g IV',
      repeatGuidance: 'Redose em 4 h se cirurgia prolongada.',
      additionalNotes:
          'Em cirurgia com implante, manter administração antes da incisão.',
    ),
    _SurgeryAntibioticSuggestionRule(
      matchTerms: ['abdominoplastia', 'lipoaspiração', 'rinoplastia'],
      title: 'Cirurgia plástica',
      antibioticName: 'Cefazolina',
      dose: '2 g IV',
      repeatGuidance: 'Redose em 4 h se procedimento extenso.',
      additionalNotes:
          'Ajustar conforme associação com implantes ou cirurgia combinada.',
    ),
    _SurgeryAntibioticSuggestionRule(
      matchTerms: ['septoplastia', 'amigdalectomia', 'tireoidectomia'],
      title: 'Otorrino / cabeça e pescoço',
      antibioticName: 'Cefazolina',
      dose: '2 g IV',
      repeatGuidance: 'Redose em 4 h se duração prolongada.',
      additionalNotes:
          'Em procedimentos selecionados, validar real necessidade de profilaxia pelo protocolo do serviço.',
    ),
    _SurgeryAntibioticSuggestionRule(
      matchTerms: ['cesárea', 'cesarea'],
      title: 'Cesárea',
      antibioticName: 'Cefazolina',
      dose: '2 g IV',
      repeatGuidance:
          'Redose em 4 h se cirurgia prolongada ou hemorragia importante.',
      additionalNotes:
          'Administrar antes da incisão; considerar azitromicina conforme contexto e protocolo local.',
    ),
  ];
  static const Map<String, String> _adultOtherMedicationOptions = {
    'Dexametasona': '4-10 mg',
    'Ondansetrona': '4-8 mg',
    'Droperidol': '0,625-1,25 mg',
    'Metoclopramida': '10 mg',
    'Dipirona': '1 g',
    'Paracetamol': '1 g',
    'Parecoxibe': '40 mg',
    'Cetorolaco': '30 mg',
    'Hidrocortisona': '100 mg',
  };
  static const Map<String, String> _pediatricOtherMedicationOptions = {
    'Dexametasona': '0,1-0,15 mg/kg',
    'Ondansetrona': '0,1 mg/kg',
    'Paracetamol': '10-15 mg/kg',
    'Dipirona': '15-25 mg/kg',
    'Atropina': '0,02 mg/kg',
    'Hidrocortisona': '2 mg/kg',
  };
  static const Map<String, String> _neonatalOtherMedicationOptions = {
    'Atropina': '0,02 mg/kg',
    'Glicose 10%': '2-5 mL/kg',
    'Cálcio gluconato': '50-100 mg/kg',
    'Hidrocortisona': '1-2 mg/kg',
    'Paracetamol': '10-15 mg/kg',
  };
  static const Map<String, String> _adultSedationMedicationOptions = {
    'Midazolam': '1-2 mg',
    'Fentanil': '25-50 mcg',
    'Propofol': '20-50 mg em bolus / titular',
    'Dexmedetomidina': '0,2-0,7 mcg/kg/h',
    'Cetamina': '10-25 mg',
    'Remifentanil': '0,025-0,1 mcg/kg/min',
  };
  static const Map<String, String> _pediatricSedationMedicationOptions = {
    'Midazolam': '0,03-0,05 mg/kg',
    'Fentanil': '0,5-1 mcg/kg',
    'Propofol': '0,5-1 mg/kg em bolus / titular',
    'Dexmedetomidina': '0,2-0,7 mcg/kg/h',
    'Cetamina': '0,25-0,5 mg/kg',
  };
  static const Map<String, String> _neonatalSedationMedicationOptions = {
    'Fentanil': '0,5-1 mcg/kg',
    'Dexmedetomidina': '0,1-0,5 mcg/kg/h',
    'Cetamina': '0,25-0,5 mg/kg',
    'Midazolam': 'individualizar conforme contexto',
  };
  static const Map<String, String> _adultVasoactiveDrugOptions = {
    'Etilefrina': 'Bolus 1-2 mg IV; repetir conforme resposta',
    'Metaraminol': 'Bolus 0,5-2 mg IV; considerar diluição',
    'Efedrina': 'Bolus 5-10 mg IV; repetir conforme resposta',
    'Noradrenalina': 'EV contínua 0,02-0,2 mcg/kg/min; preferir bomba',
    'Fenilefrina': 'Bolus 50-100 mcg IV ou EV contínua 0,1-1 mcg/kg/min',
    'Adrenalina': 'Bolus 5-20 mcg IV ou EV contínua 0,02-0,1 mcg/kg/min',
    'Dobutamina': 'EV contínua 2-10 mcg/kg/min',
    'Dopamina': 'EV contínua 3-10 mcg/kg/min',
    'Vasopressina': 'Bolus 0,5-2 U ou EV contínua 0,01-0,04 U/min',
  };
  static const Map<String, String> _pediatricVasoactiveDrugOptions = {
    'Efedrina': 'Bolus 0,1-0,2 mg/kg',
    'Fenilefrina': 'Bolus 1-2 mcg/kg ou EV contínua 0,1-1 mcg/kg/min',
    'Adrenalina': 'Bolus 0,5-1 mcg/kg ou EV contínua 0,02-0,1 mcg/kg/min',
    'Noradrenalina': 'EV contínua 0,02-0,2 mcg/kg/min',
    'Dobutamina': 'EV contínua 2-10 mcg/kg/min',
    'Dopamina': 'EV contínua 3-10 mcg/kg/min',
    'Vasopressina': 'EV contínua 0,0003-0,0007 U/kg/min',
  };
  static const Map<String, String> _neonatalVasoactiveDrugOptions = {
    'Adrenalina': 'EV contínua 0,05-0,3 mcg/kg/min',
    'Noradrenalina': 'EV contínua 0,02-0,2 mcg/kg/min',
    'Dobutamina': 'EV contínua 2-10 mcg/kg/min',
    'Dopamina': 'EV contínua 3-10 mcg/kg/min',
    'Vasopressina': 'EV contínua 0,0002-0,0007 U/kg/min',
  };

  final AiRecordAnalysisService _analysisService =
      const AiRecordAnalysisService();
  final HemodynamicRecordService _hemodynamicService =
      const HemodynamicRecordService();
  final RecordValidationService _validationService =
      const RecordValidationService();
  final RecordStorageService _storageService = RecordStorageService();
  final ReportExportService _reportExportService = const ReportExportService();

  late final AnesthesiaRecord _initialRecord;
  late AnesthesiaRecord _record;
  late AnesthesiaCaseStatus _caseStatus;
  late List<String> _venousAccesses;
  late List<String> _arterialAccesses;
  late List<String> _monitoringItems;
  late String _preAnestheticDate;
  late String _anesthesiaDate;
  String _inlineHemodynamicType = 'PAS';
  bool _inlineHemodynamicRemoveMode = false;
  Timer? _hemodynamicTicker;
  final GlobalKey _patientSummaryKey = GlobalKey();
  final GlobalKey _airwaySectionKey = GlobalKey();
  final GlobalKey _ventilationSectionKey = GlobalKey();
  final GlobalKey _techniqueSectionKey = GlobalKey();
  final GlobalKey _drugsSectionKey = GlobalKey();
  final GlobalKey _neuraxialNeedlesSectionKey = GlobalKey();
  final GlobalKey _materialsSectionKey = GlobalKey();
  final GlobalKey _otherMedicationsSectionKey = GlobalKey();
  final GlobalKey _vasoactiveSectionKey = GlobalKey();
  final GlobalKey _eventsSectionKey = GlobalKey();
  final GlobalKey _fluidSectionKey = GlobalKey();

  bool get _usesMallampatiInCase =>
      _record.patient.population == PatientPopulation.adult;

  List<String> get _profileRestrictionSuggestions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _commonRestrictions;
      case PatientPopulation.pediatric:
        return _pediatricRestrictions;
      case PatientPopulation.neonatal:
        return _neonatalRestrictions;
    }
  }

  List<String> get _profileMedicationSuggestions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _commonMedications;
      case PatientPopulation.pediatric:
        return _pediatricCommonMedications;
      case PatientPopulation.neonatal:
        return _neonatalCommonMedications;
    }
  }

  Map<String, String> get _profileProphylacticAntibioticOptions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _adultProphylacticAntibioticOptions;
      case PatientPopulation.pediatric:
        return _pediatricProphylacticAntibioticOptions;
      case PatientPopulation.neonatal:
        return _neonatalProphylacticAntibioticOptions;
    }
  }

  Map<String, String> get _profileOtherMedicationOptions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _adultOtherMedicationOptions;
      case PatientPopulation.pediatric:
        return _pediatricOtherMedicationOptions;
      case PatientPopulation.neonatal:
        return _neonatalOtherMedicationOptions;
    }
  }

  Map<String, String> get _profileSedationMedicationOptions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _adultSedationMedicationOptions;
      case PatientPopulation.pediatric:
        return _pediatricSedationMedicationOptions;
      case PatientPopulation.neonatal:
        return _neonatalSedationMedicationOptions;
    }
  }

  Map<String, String> get _profileVasoactiveDrugOptions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _adultVasoactiveDrugOptions;
      case PatientPopulation.pediatric:
        return _pediatricVasoactiveDrugOptions;
      case PatientPopulation.neonatal:
        return _neonatalVasoactiveDrugOptions;
    }
  }

  List<MedicationCatalogSuggestion> get _surgeryBasedAntibioticSuggestions {
    if (_record.patient.population != PatientPopulation.adult) return const [];
    final surgeries = _lineItems(_record.surgeryDescription);
    final suggestions = <MedicationCatalogSuggestion>[];
    final seenTitles = <String>{};

    for (final surgery in surgeries) {
      final normalized = surgery.toLowerCase();
      for (final rule in _adultSurgeryAntibioticSuggestionRules) {
        if (rule.matchTerms.any(normalized.contains)) {
          final suggestion = MedicationCatalogSuggestion(
            title: surgery,
            subtitle: rule.title,
            medicationName: rule.antibioticName,
            dose: rule.dose,
            repeatGuidance: rule.repeatGuidance,
            additionalNotes: rule.additionalNotes,
          );
          final key =
              '${suggestion.title}|${suggestion.medicationName}|${suggestion.dose}';
          if (seenTitles.add(key)) {
            suggestions.add(suggestion);
          }
          break;
        }
      }
    }

    return suggestions;
  }

  String _valueOrPlaceholder(
    String value, {
    String placeholder = 'Toque para preencher',
  }) {
    return value.trim().isEmpty ? placeholder : value;
  }

  String _medicationDoseSummary(List<String> parts) {
    final segments = <String>[];
    final initialDose = parts.length > 1 ? parts[1].trim() : '';
    final repeats = parts.length > 3 ? parts[3].trim() : '';
    final infusion = parts.length > 4 ? parts[4].trim() : '';
    final ampoules = parts.length > 5 ? parts[5].trim() : '';

    if (initialDose.isNotEmpty) {
      segments.add('Inicial: $initialDose');
    }
    if (repeats.isNotEmpty) {
      segments.add('Repiques: $repeats');
    }
    if (infusion.isNotEmpty) {
      segments.add('IC: $infusion');
    }
    if (ampoules.isNotEmpty) {
      segments.add('Ampolas: $ampoules');
    }

    if (segments.isEmpty) {
      return parts.length == 1 ? parts.first : 'Sem dose';
    }

    return segments.join(' • ');
  }

  String get _displayFastingHours {
    final manual = _record.fastingHours.trim();
    if (manual.isNotEmpty) return manual;
    final assessment = _record.preAnestheticAssessment;
    final population = _record.patient.population;
    if (population == PatientPopulation.adult) {
      return assessment.fastingSolids.trim();
    }

    final segments = <String>[];
    final solids = assessment.fastingSolids.trim();
    final liquids = assessment.fastingLiquids.trim();
    final breastMilk = assessment.fastingBreastMilk.trim();

    if (solids.isNotEmpty) {
      segments.add(
        population == PatientPopulation.neonatal
            ? 'Formula/leite nao humano: $solids'
            : 'Formula/refeicao: $solids',
      );
    }
    if (breastMilk.isNotEmpty) {
      segments.add('Leite materno: $breastMilk');
    }
    if (liquids.isNotEmpty) {
      segments.add('Liquidos claros: $liquids');
    }

    return segments.join(' • ');
  }

  String get _displaySurgeryPriority {
    final recordPriority = _record.surgeryPriority.trim();
    if (recordPriority.isNotEmpty) return recordPriority;
    return _record.preAnestheticAssessment.surgeryPriority.trim();
  }

  String get _displayPatientDestination {
    final destination = _record.patientDestination.trim();
    final other = _record.otherPatientDestination.trim();
    if (destination.isEmpty && other.isEmpty) {
      return 'Toque para preencher';
    }
    if (destination.isEmpty) return other;
    if (other.isEmpty) return destination;
    return '$destination • $other';
  }

  List<String> _lineItems(String value) {
    return value
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _multilineSummary(
    String value, {
    String empty = 'Toque para preencher',
  }) {
    final items = _lineItems(value);
    if (items.isEmpty) return empty;
    return items.join(' • ');
  }

  List<String> get _anesthesiologistEntries {
    if (_record.anesthesiologists.isNotEmpty) return _record.anesthesiologists;
    final legacy = [
      _record.anesthesiologistName.trim(),
      _record.anesthesiologistCrm.trim(),
      _record.anesthesiologistDetails.trim(),
    ];
    if (legacy.every((item) => item.isEmpty)) return const [];
    return ['${legacy[0]}|${legacy[1]}|${legacy[2]}'];
  }

  String get _displayAnesthesiologists {
    return _displayStructuredEntries(_anesthesiologistEntries);
  }

  String _displayStructuredEntries(
    Iterable<String> items, {
    String empty = 'Toque para preencher',
  }) {
    final normalized = items
        .map(TeamMemberEntry.parse)
        .map((item) => item.name)
        .where((item) => item.trim().isNotEmpty)
        .toList();
    if (normalized.isEmpty) return empty;
    return normalized.join(', ');
  }

  String _displayLineEntries(
    String value, {
    String empty = 'Toque para preencher',
  }) {
    final items = _lineItems(value);
    if (items.isEmpty) return empty;
    return items.join(', ');
  }

  String _displayStructuredLineEntries(
    String value, {
    String empty = 'Toque para preencher',
  }) {
    return _displayStructuredEntries(_lineItems(value), empty: empty);
  }

  String _displayListEntries(
    List<String> items, {
    String empty = 'Toque para preencher',
  }) {
    return _displayStructuredEntries(items, empty: empty);
  }

  String? _findMaintenanceEntry(String name) {
    for (final item in _lineItems(_record.maintenanceAgents)) {
      if (item.split('|').first.trim() == name) return item;
    }
    return null;
  }

  List<String> _upsertMaintenanceEntry(String encodedEntry) {
    final name = encodedEntry.split('|').first.trim();
    final items = _lineItems(_record.maintenanceAgents);
    final updated = <String>[];
    var replaced = false;
    for (final item in items) {
      if (item.split('|').first.trim() == name) {
        updated.add(encodedEntry);
        replaced = true;
      } else {
        updated.add(item);
      }
    }
    if (!replaced) updated.add(encodedEntry);
    return updated;
  }

  List<String> _removeMaintenanceEntry(String name) {
    return _lineItems(
      _record.maintenanceAgents,
    ).where((item) => item.split('|').first.trim() != name).toList();
  }

  _TechniqueProfile get _techniqueProfile {
    final technique = _record.anesthesiaTechnique.toLowerCase();
    final details = _record.anesthesiaTechniqueDetails.toLowerCase();
    final isEmpty = technique.trim().isEmpty && details.trim().isEmpty;
    final hasTiva =
        technique.contains('tiva') ||
        technique.contains('venosa total') ||
        (details.contains('convers') && details.contains('tiva'));
    final hasInhalationalGeneral =
        technique.contains('balanceada') || technique.contains('inalat');
    final hasGeneralIntravenous =
        technique.contains('geral venosa') || technique.contains('geral ev');
    final hasGeneral =
        hasTiva ||
        technique.contains('anestesia geral') ||
        technique.contains('intubação orotraqueal') ||
        technique.contains('intubacao orotraqueal') ||
        technique.contains('máscara laríngea') ||
        technique.contains('mascara laringea') ||
        technique.contains('ventilação controlada') ||
        technique.contains('ventilacao controlada') ||
        (details.contains('convers') && details.contains('geral'));
    final hasSedation =
        technique.contains('sedação') || technique.contains('sedacao');
    final hasNeuraxial =
        technique.contains('raqui') ||
        technique.contains('peridural') ||
        technique.contains('neurax');
    final hasRegional =
        technique.contains('bloqueio') ||
        technique.contains('regional') ||
        technique.contains('caudal');

    return _TechniqueProfile(
      isEmpty: isEmpty,
      hasGeneral: hasGeneral,
      hasTiva: hasTiva,
      hasInhalationalGeneral: hasInhalationalGeneral,
      hasGeneralIntravenous: hasGeneralIntravenous,
      hasSedation: hasSedation,
      hasNeuraxial: hasNeuraxial,
      hasRegional: hasRegional,
    );
  }

  bool get _isTivaTechnique {
    return _techniqueProfile.hasTiva;
  }

  bool get _showsGeneralWorkflowCards =>
      _techniqueProfile.isEmpty || _techniqueProfile.hasGeneral;

  bool get _showsSedationWorkflowCard =>
      _techniqueProfile.isEmpty ||
      _techniqueProfile.hasSedation ||
      _techniqueProfile.hasPureRegionalOrNeuraxialFlow;

  bool get _showsNeuraxialWorkflowCard =>
      _techniqueProfile.isEmpty || _techniqueProfile.hasNeuraxial;

  bool get _showsMechanicalVentilationCard =>
      _techniqueProfile.isEmpty || _techniqueProfile.hasGeneral;

  bool get _hasAdvancedAirwayDevice {
    final device = _record.airway.device.toLowerCase();
    return device.contains('tot') ||
        device.contains('tubo') ||
        device.contains('intub') ||
        device.contains('traque') ||
        device.contains('máscara laríngea') ||
        device.contains('mascara laringea') ||
        device.contains('mla');
  }

  bool get _hasNeuromuscularBlocker {
    final entries = [
      ..._record.drugs,
      ..._lineItems(_record.maintenanceAgents),
    ].map((item) => item.toLowerCase());
    return entries.any(
      (item) =>
          item.contains('rocur') ||
          item.contains('cisatra') ||
          item.contains('atrac') ||
          item.contains('vecur') ||
          item.contains('pancur') ||
          item.contains('succin') ||
          item.contains('suxa'),
    );
  }

  bool get _suggestsControlledVentilation {
    final technique = _record.anesthesiaTechnique.toLowerCase();
    return _hasAdvancedAirwayDevice ||
        _hasNeuromuscularBlocker ||
        technique.contains('ventilação controlada') ||
        technique.contains('ventilacao controlada');
  }

  int _roundedPositiveInt(double value) => value <= 0 ? 0 : value.round();

  String _formatVentilationNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  int _suggestedRespiratoryRate() {
    final age = _record.patient.age;
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return 12;
      case PatientPopulation.pediatric:
        if (age <= 1) return 25;
        if (age <= 3) return 22;
        if (age <= 6) return 20;
        if (age <= 12) return 16;
        return 14;
      case PatientPopulation.neonatal:
        return 30;
    }
  }

  String _formatHeightCentimeters(double heightMeters) {
    if (heightMeters <= 0) return '';
    return (heightMeters * 100).toStringAsFixed(0);
  }

  double _adultVentilationReferenceWeightKg() {
    final patient = _record.patient;
    if (patient.weightKg > 0 && patient.heightMeters > 0) {
      return _adultReferenceWeightKg(
        actualWeightKg: patient.weightKg,
        heightMeters: patient.heightMeters,
      );
    }
    if (patient.weightKg > 0) return patient.weightKg;
    if (patient.heightMeters > 0) {
      return 25 * patient.heightMeters * patient.heightMeters;
    }
    return 70;
  }

  _VentilationSuggestion get _suggestedMechanicalVentilation {
    final patient = _record.patient;
    final weightKg = patient.weightKg > 0
        ? patient.weightKg
        : patient.birthWeightKg;
    final hasLaparoscopy = _record.surgeryDescription.toLowerCase().contains(
      'lapar',
    );
    final hasDifficultVentilationRisk =
        _record
            .preAnestheticAssessment
            .difficultVentilationPredictors
            .isNotEmpty ||
        _record.preAnestheticAssessment.otherDifficultVentilationPredictors
            .trim()
            .isNotEmpty;
    final bodyMassIndex = _bodyMassIndex(
      weightKg: patient.weightKg,
      heightMeters: patient.heightMeters,
    );
    final hasObesity = bodyMassIndex >= 30;
    final hasSevereObesity = bodyMassIndex >= 35;

    switch (patient.population) {
      case PatientPopulation.adult:
        final referenceWeightKg = _adultVentilationReferenceWeightKg();
        final vtPerKg = hasSevereObesity || hasLaparoscopy ? 6.0 : 6.5;
        final vtMl = _roundedPositiveInt(referenceWeightKg * vtPerKg);
        final mode = hasLaparoscopy || hasDifficultVentilationRisk || hasObesity
            ? 'PCV-VG'
            : 'VCV';
        final respiratoryRate =
            _suggestedRespiratoryRate() +
            (hasLaparoscopy ? 2 : 0) +
            (hasSevereObesity ? 2 : 0);
        final peep = hasSevereObesity
            ? '8'
            : hasLaparoscopy || hasObesity
            ? '6'
            : '5';
        final fio2 = hasSevereObesity
            ? '60'
            : hasLaparoscopy || hasDifficultVentilationRisk
            ? '50'
            : '40';
        final basis = <String>[
          if (patient.weightKg > 0)
            'peso ${_formatVentilationNumber(patient.weightKg)} kg',
          if (patient.heightMeters > 0)
            'altura ${_formatHeightCentimeters(patient.heightMeters)} cm',
          if (hasObesity && patient.heightMeters > 0)
            'VT calculado pelo peso de referência ${_formatVentilationNumber(referenceWeightKg)} kg',
        ];
        return _VentilationSuggestion(
          reason: [
            if (_suggestsControlledVentilation)
              'Via aérea avançada ou bloqueador neuromuscular favorecem ventilação controlada protetora.'
            else
              'Plano ventilatório inicial ajustado ao biotipo e ao contexto do caso.',
            if (basis.isNotEmpty) 'Base: ${basis.join(' • ')}.',
            if (hasLaparoscopy)
              'Laparoscopia pede PEEP e FR um pouco mais altas para manter recrutamento e ETCO₂.',
          ].join(' '),
          settings: MechanicalVentilationSettings(
            mode: mode,
            fio2Percent: fio2,
            tidalVolumeMl: vtMl > 0 ? '$vtMl' : '',
            tidalVolumePerKg: _formatVentilationNumber(vtPerKg),
            respiratoryRate: '$respiratoryRate',
            peep: peep,
            ieRatio: '1:2',
            targetEtco2: '35-40',
            notes: mode == 'PCV-VG'
                ? 'Ajustar pressão/volume para manter VT protetor, driving pressure baixa e ETCO₂ na meta.'
                : 'Estratégia protetora intraoperatória com VT baixo, PEEP titulada e revisão seriada da complacência.',
          ),
        );
      case PatientPopulation.pediatric:
        final mode = hasLaparoscopy ? 'PCV-VG' : 'PCV';
        final vtPerKg = patient.weightKg >= 30 ? 6.0 : 6.5;
        final vtMl = weightKg > 0 ? _roundedPositiveInt(weightKg * vtPerKg) : 0;
        final peep = hasLaparoscopy ? '6' : '5';
        final fio2 = hasLaparoscopy ? '50' : '40';
        return _VentilationSuggestion(
          reason: [
            'Em pediatria, o plano inicial deve acompanhar peso, complacência, escape e ETCO₂.',
            if (weightKg > 0)
              'Base: peso ${_formatVentilationNumber(weightKg)} kg.',
            if (hasLaparoscopy)
              'Laparoscopia pede um pouco mais de PEEP e vigilância maior do CO₂.',
          ].join(' '),
          settings: MechanicalVentilationSettings(
            mode: mode,
            fio2Percent: fio2,
            tidalVolumeMl: vtMl > 0 ? '$vtMl' : '',
            tidalVolumePerKg: _formatVentilationNumber(vtPerKg),
            respiratoryRate: '${_suggestedRespiratoryRate()}',
            peep: peep,
            inspiratoryPressure: '14',
            ieRatio: '1:2',
            targetEtco2: '35-40',
            notes:
                'Titular pressão e FR para manter VT protetor, menor escape possível e ETCO₂ adequado à idade.',
          ),
        );
      case PatientPopulation.neonatal:
        final vtPerKg = 5.0;
        final vtMl = weightKg > 0 ? _roundedPositiveInt(weightKg * vtPerKg) : 0;
        return _VentilationSuggestion(
          reason: [
            'No neonato, priorizar pressões e volumes baixos, com atenção a escape, complacência e ETCO₂.',
            if (weightKg > 0)
              'Base: peso ${_formatVentilationNumber(weightKg)} kg.',
          ].join(' '),
          settings: MechanicalVentilationSettings(
            mode: 'PCV',
            fio2Percent: '30',
            tidalVolumeMl: vtMl > 0 ? '$vtMl' : '',
            tidalVolumePerKg: _formatVentilationNumber(vtPerKg),
            respiratoryRate: '${_suggestedRespiratoryRate()}',
            peep: '4',
            inspiratoryPressure: '12',
            ieRatio: '1:2',
            targetEtco2: '35-45',
            notes:
                'Objetivar VT ~4-6 mL/kg com menor FiO₂ necessária e vigilância térmica/respiratória.',
          ),
        );
    }
  }

  MechanicalVentilationSettings get _effectiveMechanicalVentilation {
    if (_record.mechanicalVentilation.isEmpty) {
      return _suggestedMechanicalVentilation.settings;
    }
    return _record.mechanicalVentilation;
  }

  DateTime? get _hemodynamicAnesthesiaEndAt => _hemodynamicService
      .markerStartAt(_record.hemodynamicMarkers, 'Fim da anestesia');

  double get _anesthesiaElapsedHours {
    final startedAt = _hemodynamicAnesthesiaStartAt;
    if (startedAt == null) return 0;
    final endedAt = _hemodynamicAnesthesiaEndAt ?? DateTime.now();
    final elapsedMinutes = endedAt.difference(startedAt).inSeconds / 60;
    if (elapsedMinutes <= 0) return 0;
    return elapsedMinutes / 60;
  }

  String _formatElapsedHoursLabel(double hours) {
    if (hours <= 0) return '--';
    if (hours < 1) return '${(hours * 60).round()} min';
    return '${hours.toStringAsFixed(1).replaceAll('.', ',')} h';
  }

  String get _techniqueWorkflowSummary {
    final profile = _techniqueProfile;
    if (profile.isEmpty) {
      return 'Escolha primeiro a técnica principal para priorizar os cards abaixo e reduzir campos desnecessários.';
    }
    if (profile.hasTiva) {
      return 'Fluxo de anestesia geral TIVA ativo: via aérea, indução e manutenção em bomba ficam priorizadas, com presets EV contínua/TIVA.';
    }
    if (profile.hasInhalationalGeneral) {
      return 'Fluxo de anestesia geral balanceada/inalatória ativo: via aérea, indução e manutenção destacam agentes inalatórios e consumo automático por FGF.';
    }
    if (profile.hasGeneralIntravenous) {
      return 'Fluxo de anestesia geral venosa ativo: via aérea, indução e manutenção EV contínua ficam em destaque.';
    }
    if (profile.hasPureRegionalOrNeuraxialFlow && profile.hasSedation) {
      return 'Fluxo regional/neuraxial com sedação ativo: sedação associada e materiais específicos seguem visíveis; anestesia geral aparece apenas se houver associação ou conversão.';
    }
    if (profile.hasPureRegionalOrNeuraxialFlow) {
      return 'Fluxo regional/neuraxial ativo: priorize bloqueios, agulhas e materiais; campos de anestesia geral ficam recolhidos até uma combinação ou conversão.';
    }
    if (profile.hasSedation) {
      return 'Fluxo de sedação ativo: mantenha sedação e adjuvantes em foco; via aérea e manutenção geral só entram se a técnica evoluir para anestesia geral.';
    }
    return 'Fluxo técnico configurado conforme a seleção atual.';
  }

  String _maintenanceCategoryForPreset(_MaintenancePreset preset) {
    if (_isTivaTechnique && preset.tivaCategory != null) {
      return preset.tivaCategory!;
    }
    return preset.category;
  }

  String _maintenanceBaseDetailsForPreset(_MaintenancePreset preset) {
    if (_isTivaTechnique && preset.tivaDetails != null) {
      return preset.tivaDetails!;
    }
    return preset.defaultDetails;
  }

  String _maintenanceDetailPrefixForPreset(_MaintenancePreset preset) {
    if (_isTivaTechnique && preset.tivaSummary != null) {
      return preset.tivaSummary!;
    }
    return preset.summary;
  }

  double _maintenanceFreshGasFlowFromEntry(
    _MaintenancePreset preset,
    String? encodedEntry,
  ) {
    if (!preset.isInhalational || encodedEntry == null) return 2.0;
    final oxygen = _maintenanceOxygenFlowFromEntry(preset, encodedEntry);
    final compressedAir = _maintenanceCompressedAirFlowFromEntry(
      preset,
      encodedEntry,
    );
    final nitrousOxide = _maintenanceNitrousOxideFlowFromEntry(
      preset,
      encodedEntry,
    );
    final summedFlow = oxygen + compressedAir + nitrousOxide;
    if (summedFlow > 0) return summedFlow;
    final parts = encodedEntry.split('|');
    if (parts.length > 3) {
      final stored = double.tryParse(parts[3].trim());
      if (stored != null && stored > 0) return stored;
    }
    return 2.0;
  }

  double _maintenanceOxygenFlowFromEntry(
    _MaintenancePreset preset,
    String? encodedEntry,
  ) {
    if (!preset.isInhalational || encodedEntry == null) return 1.0;
    final parts = encodedEntry.split('|');
    if (parts.length > 5) {
      final stored = double.tryParse(parts[5].trim());
      if (stored != null && stored >= 0) return stored;
    }
    final legacyTotal = parts.length > 3
        ? double.tryParse(parts[3].trim())
        : null;
    if (legacyTotal != null && legacyTotal > 0) return legacyTotal;
    return 1.0;
  }

  double _maintenanceCompressedAirFlowFromEntry(
    _MaintenancePreset preset,
    String? encodedEntry,
  ) {
    if (!preset.isInhalational || encodedEntry == null) return 1.0;
    final parts = encodedEntry.split('|');
    if (parts.length > 6) {
      final stored = double.tryParse(parts[6].trim());
      if (stored != null && stored >= 0) return stored;
    }
    return parts.length > 5 ? 0 : 1.0;
  }

  double _maintenanceNitrousOxideFlowFromEntry(
    _MaintenancePreset preset,
    String? encodedEntry,
  ) {
    if (!preset.isInhalational || encodedEntry == null) return 0.0;
    final parts = encodedEntry.split('|');
    if (parts.length > 7) {
      final stored = double.tryParse(parts[7].trim());
      if (stored != null && stored >= 0) return stored;
    }
    return 0.0;
  }

  double _maintenanceVolPercentFromEntry(
    _MaintenancePreset preset,
    String? encodedEntry,
  ) {
    if (!preset.isInhalational || encodedEntry == null) {
      return preset.defaultVolPercent;
    }
    final parts = encodedEntry.split('|');
    if (parts.length > 4) {
      final stored = double.tryParse(parts[4].trim());
      if (stored != null && stored > 0) return stored;
    }
    final detail = parts.length > 2 ? parts[2].trim() : '';
    final match = RegExp(r'([0-9]+(?:[.,][0-9]+)?)\s*vol%').firstMatch(detail);
    if (match != null) {
      final parsed = double.tryParse(match.group(1)!.replaceAll(',', '.'));
      if (parsed != null && parsed > 0) return parsed;
    }
    return preset.defaultVolPercent;
  }

  String _inferSurgicalSizeFromDescription() {
    final text = _record.surgeryDescription.toLowerCase();
    if (text.trim().isEmpty) return _record.surgicalSize;

    const largeTerms = [
      'bariátrica',
      'bypass',
      'sleeve',
      'nefrectomia',
      'histerectomia',
      'artroplastia',
      'fratura de fêmur',
      'mastectomia',
      'abdominoplastia',
    ];
    const mediumTerms = [
      'colecistectomia',
      'herniorrafia',
      'apendicectomia',
      'cesárea',
      'septoplastia',
      'tireoidectomia',
      'quadrantectomia',
      'prótese de mama',
      'rinoplastia',
    ];

    if (largeTerms.any(text.contains)) return 'Grande';
    if (mediumTerms.any(text.contains)) return 'Medio';
    return 'Pequeno';
  }

  double _estimateInhalationalMlPerHour(
    _MaintenancePreset preset, {
    required double freshGasFlowLPerMin,
    required double volumePercent,
  }) {
    if (!preset.isInhalational ||
        preset.density <= 0 ||
        preset.molecularWeight <= 0) {
      return 0;
    }
    return (60 * freshGasFlowLPerMin * volumePercent * preset.molecularWeight) /
        (2412 * preset.density);
  }

  String _maintenancePresetDetails(
    _MaintenancePreset preset, {
    double? freshGasFlowLPerMin,
    double? volumePercent,
    double? oxygenFlowLPerMin,
    double? compressedAirFlowLPerMin,
    double? nitrousOxideFlowLPerMin,
  }) {
    if (!preset.isInhalational) {
      return '${_maintenanceDetailPrefixForPreset(preset)} • ${_maintenanceBaseDetailsForPreset(preset)}';
    }
    final effectiveOxygen = oxygenFlowLPerMin ?? 1.0;
    final effectiveCompressedAir = compressedAirFlowLPerMin ?? 1.0;
    final effectiveNitrousOxide = nitrousOxideFlowLPerMin ?? 0.0;
    final effectiveFlow =
        freshGasFlowLPerMin ??
        (effectiveOxygen + effectiveCompressedAir + effectiveNitrousOxide);
    final effectiveVol = volumePercent ?? preset.defaultVolPercent;
    final mlPerHour = _estimateInhalationalMlPerHour(
      preset,
      freshGasFlowLPerMin: effectiveFlow,
      volumePercent: effectiveVol,
    );
    final flowLabel = effectiveFlow.toStringAsFixed(1).replaceAll('.', ',');
    final volLabel = effectiveVol.toStringAsFixed(1).replaceAll('.', ',');
    final oxygenLabel = effectiveOxygen.toStringAsFixed(1).replaceAll('.', ',');
    final compressedAirLabel = effectiveCompressedAir
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    final nitrousOxideLabel = effectiveNitrousOxide
        .toStringAsFixed(1)
        .replaceAll('.', ',');
    return '$volLabel vol% • O₂ $oxygenLabel + ar $compressedAirLabel + N₂O $nitrousOxideLabel = FGF $flowLabel L/min • ~${mlPerHour.toStringAsFixed(1)} mL/h';
  }

  String _encodeMaintenanceEntry(
    _MaintenancePreset preset, {
    required String category,
    required String detail,
    double? freshGasFlowLPerMin,
    double? volumePercent,
    double? oxygenFlowLPerMin,
    double? compressedAirFlowLPerMin,
    double? nitrousOxideFlowLPerMin,
  }) {
    final parts = <String>[preset.name, category, detail];
    if (preset.isInhalational) {
      final oxygen = oxygenFlowLPerMin ?? 1.0;
      final compressedAir = compressedAirFlowLPerMin ?? 1.0;
      final nitrousOxide = nitrousOxideFlowLPerMin ?? 0.0;
      final totalFlow =
          freshGasFlowLPerMin ?? (oxygen + compressedAir + nitrousOxide);
      parts.add(totalFlow.toStringAsFixed(1));
      parts.add((volumePercent ?? preset.defaultVolPercent).toStringAsFixed(1));
      parts.add(oxygen.toStringAsFixed(1));
      parts.add(compressedAir.toStringAsFixed(1));
      parts.add(nitrousOxide.toStringAsFixed(1));
    }
    return parts.join('|');
  }

  List<String> _refreshMaintenanceEntriesForCurrentTechnique(
    List<String> items,
  ) {
    final refreshed = <String>[];
    for (final item in items) {
      final parts = item.split('|');
      final name = parts.isNotEmpty ? parts.first.trim() : '';
      final preset = _maintenancePresets.where((entry) => entry.name == name);
      if (preset.isEmpty) {
        refreshed.add(item);
        continue;
      }
      final currentPreset = preset.first;
      final category = _maintenanceCategoryForPreset(currentPreset);
      final detail = parts.length > 2 ? parts[2].trim() : '';
      final defaultOld = currentPreset.defaultDetails;
      final defaultNew = _maintenanceBaseDetailsForPreset(currentPreset);
      final normalizedDetail =
          detail == defaultOld || detail == defaultNew || detail.isEmpty
          ? _maintenancePresetDetails(
              currentPreset,
              freshGasFlowLPerMin: _maintenanceFreshGasFlowFromEntry(
                currentPreset,
                item,
              ),
              volumePercent: _maintenanceVolPercentFromEntry(
                currentPreset,
                item,
              ),
              oxygenFlowLPerMin: _maintenanceOxygenFlowFromEntry(
                currentPreset,
                item,
              ),
              compressedAirFlowLPerMin: _maintenanceCompressedAirFlowFromEntry(
                currentPreset,
                item,
              ),
              nitrousOxideFlowLPerMin: _maintenanceNitrousOxideFlowFromEntry(
                currentPreset,
                item,
              ),
            )
          : detail;
      refreshed.add(
        _encodeMaintenanceEntry(
          currentPreset,
          category: category,
          detail: normalizedDetail,
          freshGasFlowLPerMin: _maintenanceFreshGasFlowFromEntry(
            currentPreset,
            item,
          ),
          volumePercent: _maintenanceVolPercentFromEntry(currentPreset, item),
          oxygenFlowLPerMin: _maintenanceOxygenFlowFromEntry(
            currentPreset,
            item,
          ),
          compressedAirFlowLPerMin: _maintenanceCompressedAirFlowFromEntry(
            currentPreset,
            item,
          ),
          nitrousOxideFlowLPerMin: _maintenanceNitrousOxideFlowFromEntry(
            currentPreset,
            item,
          ),
        ),
      );
    }
    return refreshed;
  }

  String? _findDrugEntry(String name) {
    try {
      return _record.drugs.firstWhere(
        (item) => item.split('|').first.trim() == name,
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _upsertDrugEntry(String encodedEntry) {
    final name = encodedEntry.split('|').first.trim();
    final updated = <String>[];
    var replaced = false;
    for (final item in _record.drugs) {
      if (item.split('|').first.trim() == name) {
        updated.add(encodedEntry);
        replaced = true;
      } else {
        updated.add(item);
      }
    }
    if (!replaced) updated.add(encodedEntry);
    return updated;
  }

  List<String> _removeDrugEntry(String name) {
    return _record.drugs
        .where((item) => item.split('|').first.trim() != name)
        .toList();
  }

  double _inductionReferenceWeightKg() {
    final patient = _record.patient;
    if (patient.weightKg > 0) return patient.weightKg;
    if (patient.birthWeightKg > 0) return patient.birthWeightKg;
    return 0;
  }

  String _formatMedicationAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }

  String _inductionPresetDose(_InductionPreset preset) {
    final weightKg = _inductionReferenceWeightKg();
    if (weightKg <= 0) return 'Informe o peso para calcular';
    final totalDose = preset.dosePerKg * weightKg;
    final totalMl = totalDose / preset.concentrationPerMl;
    return '${_formatMedicationAmount(totalDose)} ${preset.unit} • ~${_formatMedicationAmount(totalMl)} mL (${preset.concentrationLabel})';
  }

  Future<void> _toggleInductionPreset(_InductionPreset preset) async {
    final existing = _findDrugEntry(preset.name);
    final updated = existing == null
        ? _upsertDrugEntry(
            '${preset.name}|${_inductionPresetDose(preset)}|||1 ampola',
          )
        : _removeDrugEntry(preset.name);
    setState(() {
      _record = _record.copyWith(drugs: updated);
    });
    await _persistRecord();
  }

  Future<void> _editInductionPreset(_InductionPreset preset) async {
    final existing = _findDrugEntry(preset.name);
    final parts = existing?.split('|') ?? const <String>[];
    final result = await showDialog<MedicationEntryEditResult>(
      context: context,
      builder: (_) => MedicationEntryEditDialog(
        title: preset.name,
        name: preset.name,
        initialDose: parts.length > 1 && parts[1].trim().isNotEmpty
            ? parts[1].trim()
            : _inductionPresetDose(preset),
        initialTime: parts.length > 2 ? parts[2].trim() : '',
        initialRepeats: parts.length > 3 ? parts[3].trim() : '',
        initialInfusion: parts.length > 4 ? parts[4].trim() : '',
        initialAmpoules: parts.length > 5 && parts[5].trim().isNotEmpty
            ? parts[5].trim()
            : '1 ampola',
      ),
    );
    if (result == null) return;
    final updated = result.remove
        ? _removeDrugEntry(preset.name)
        : _upsertDrugEntry(result.encodedEntry);
    setState(() {
      _record = _record.copyWith(drugs: updated);
    });
    await _persistRecord();
  }

  String? _findAdjunctEntry(String name) {
    try {
      return _record.adjuncts.firstWhere(
        (item) => item.split('|').first.trim() == name,
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _upsertAdjunctEntry(String encodedEntry) {
    final name = encodedEntry.split('|').first.trim();
    final updated = <String>[];
    var replaced = false;
    for (final item in _record.adjuncts) {
      if (item.split('|').first.trim() == name) {
        updated.add(encodedEntry);
        replaced = true;
      } else {
        updated.add(item);
      }
    }
    if (!replaced) updated.add(encodedEntry);
    return updated;
  }

  List<String> _removeAdjunctEntry(String name) {
    return _record.adjuncts
        .where((item) => item.split('|').first.trim() != name)
        .toList();
  }

  String _adjunctPresetDose(_AdjunctPreset preset) {
    final weightKg = _inductionReferenceWeightKg();
    if (weightKg <= 0) return 'Informe o peso para calcular';
    final totalDose = preset.dosePerKg * weightKg;
    final totalMl = totalDose / preset.concentrationPerMl;
    return '${_formatMedicationAmount(totalDose)} ${preset.unit} • ~${_formatMedicationAmount(totalMl)} mL (${preset.concentrationLabel})';
  }

  Future<void> _toggleAdjunctPreset(_AdjunctPreset preset) async {
    final existing = _findAdjunctEntry(preset.name);
    final updated = existing == null
        ? _upsertAdjunctEntry(
            '${preset.name}|${_adjunctPresetDose(preset)}|||1 ampola',
          )
        : _removeAdjunctEntry(preset.name);
    setState(() {
      _record = _record.copyWith(adjuncts: updated);
    });
    await _persistRecord();
  }

  Future<void> _editAdjunctPreset(_AdjunctPreset preset) async {
    final existing = _findAdjunctEntry(preset.name);
    final parts = existing?.split('|') ?? const <String>[];
    final result = await showDialog<MedicationEntryEditResult>(
      context: context,
      builder: (_) => MedicationEntryEditDialog(
        title: preset.name,
        name: preset.name,
        initialDose: parts.length > 1 && parts[1].trim().isNotEmpty
            ? parts[1].trim()
            : _adjunctPresetDose(preset),
        initialTime: parts.length > 2 ? parts[2].trim() : '',
        initialRepeats: parts.length > 3 ? parts[3].trim() : '',
        initialInfusion: parts.length > 4 ? parts[4].trim() : '',
        initialAmpoules: parts.length > 5 && parts[5].trim().isNotEmpty
            ? parts[5].trim()
            : '1 ampola',
      ),
    );
    if (result == null) return;
    final updated = result.remove
        ? _removeAdjunctEntry(preset.name)
        : _upsertAdjunctEntry(result.encodedEntry);
    setState(() {
      _record = _record.copyWith(adjuncts: updated);
    });
    await _persistRecord();
  }

  Future<void> _toggleMaintenancePreset(_MaintenancePreset preset) async {
    final existing = _findMaintenanceEntry(preset.name);
    final updated = existing == null
        ? _upsertMaintenanceEntry(
            _encodeMaintenanceEntry(
              preset,
              category: _maintenanceCategoryForPreset(preset),
              detail: _maintenancePresetDetails(preset),
              freshGasFlowLPerMin: preset.isInhalational ? 2.0 : null,
              volumePercent: preset.isInhalational
                  ? preset.defaultVolPercent
                  : null,
              oxygenFlowLPerMin: preset.isInhalational ? 1.0 : null,
              compressedAirFlowLPerMin: preset.isInhalational ? 1.0 : null,
              nitrousOxideFlowLPerMin: preset.isInhalational ? 0.0 : null,
            ),
          )
        : _removeMaintenanceEntry(preset.name);
    setState(() {
      _record = _record.copyWith(maintenanceAgents: updated.join('\n'));
    });
    await _persistRecord();
  }

  Future<void> _editMaintenancePreset(_MaintenancePreset preset) async {
    final existing = _findMaintenanceEntry(preset.name);
    final parts = existing?.split('|') ?? const <String>[];
    final initialCategory = parts.length > 1 && parts[1].trim().isNotEmpty
        ? parts[1].trim()
        : _maintenanceCategoryForPreset(preset);
    final initialDetail = parts.length > 2 && parts[2].trim().isNotEmpty
        ? parts[2].trim()
        : _maintenancePresetDetails(
            preset,
            freshGasFlowLPerMin: _maintenanceFreshGasFlowFromEntry(
              preset,
              existing,
            ),
            volumePercent: _maintenanceVolPercentFromEntry(preset, existing),
            oxygenFlowLPerMin: _maintenanceOxygenFlowFromEntry(
              preset,
              existing,
            ),
            compressedAirFlowLPerMin: _maintenanceCompressedAirFlowFromEntry(
              preset,
              existing,
            ),
            nitrousOxideFlowLPerMin: _maintenanceNitrousOxideFlowFromEntry(
              preset,
              existing,
            ),
          );
    final result = await showDialog<MaintenanceEntryEditResult>(
      context: context,
      builder: (_) => MaintenanceEntryEditDialog(
        title: preset.name,
        initialCategory: initialCategory,
        defaultCategory: _maintenanceCategoryForPreset(preset),
        initialDetail: initialDetail,
        isInhalational: preset.isInhalational,
        initialFreshGasFlowLPerMin: _maintenanceFreshGasFlowFromEntry(
          preset,
          existing,
        ),
        initialVolumePercent: _maintenanceVolPercentFromEntry(preset, existing),
        initialOxygenFlowLPerMin: _maintenanceOxygenFlowFromEntry(
          preset,
          existing,
        ),
        initialCompressedAirFlowLPerMin: _maintenanceCompressedAirFlowFromEntry(
          preset,
          existing,
        ),
        initialNitrousOxideFlowLPerMin: _maintenanceNitrousOxideFlowFromEntry(
          preset,
          existing,
        ),
        onInhalationalChanged:
            (
              volumePercent,
              oxygenFlowLPerMin,
              compressedAirFlowLPerMin,
              nitrousOxideFlowLPerMin,
            ) => _maintenancePresetDetails(
              preset,
              volumePercent: volumePercent,
              oxygenFlowLPerMin: oxygenFlowLPerMin,
              compressedAirFlowLPerMin: compressedAirFlowLPerMin,
              nitrousOxideFlowLPerMin: nitrousOxideFlowLPerMin,
            ),
      ),
    );
    if (result == null) return;
    final updated = result.remove
        ? _removeMaintenanceEntry(preset.name)
        : _upsertMaintenanceEntry(
            _encodeMaintenanceEntry(
              preset,
              category: result.category.isNotEmpty
                  ? result.category
                  : _maintenanceCategoryForPreset(preset),
              detail: result.detail.isNotEmpty
                  ? result.detail
                  : _maintenancePresetDetails(
                      preset,
                      freshGasFlowLPerMin: result.freshGasFlowLPerMin,
                      volumePercent: result.volumePercent,
                      oxygenFlowLPerMin: result.oxygenFlowLPerMin,
                      compressedAirFlowLPerMin: result.compressedAirFlowLPerMin,
                      nitrousOxideFlowLPerMin: result.nitrousOxideFlowLPerMin,
                    ),
              freshGasFlowLPerMin: result.freshGasFlowLPerMin,
              volumePercent: result.volumePercent,
              oxygenFlowLPerMin: result.oxygenFlowLPerMin,
              compressedAirFlowLPerMin: result.compressedAirFlowLPerMin,
              nitrousOxideFlowLPerMin: result.nitrousOxideFlowLPerMin,
            ),
          );
    setState(() {
      _record = _record.copyWith(maintenanceAgents: updated.join('\n'));
    });
    await _persistRecord();
  }

  double get _documentedLossesMl {
    return _parseFluidField(_record.fluidBalance.diuresis) +
        _parseFluidField(_record.fluidBalance.bleeding) +
        _sumFluidEntries(_record.fluidBalance.bloodLossEntries) +
        _parseFluidField(_record.fluidBalance.otherLosses) +
        _sumFluidEntries(_record.fluidBalance.otherLossEntries) +
        _record.fluidBalance.estimatedSpongeLoss;
  }

  double get _documentedInputsMl {
    return _parseFluidField(_record.fluidBalance.crystalloids) +
        _parseFluidField(_record.fluidBalance.colloids) +
        _parseFluidField(_record.fluidBalance.blood);
  }

  double _parseFluidField(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

  double _sumFluidEntries(List<String> entries) {
    return entries.fold<double>(0, (total, item) {
      final parts = item.split('|');
      return total + (parts.isNotEmpty ? _parseFluidField(parts.last) : 0);
    });
  }

  DateTime? _parseClockTimeToday(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatClockTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<_AntibioticRedoseAlert> get _antibioticRedoseAlerts {
    final now = DateTime.now();
    final alerts = <_AntibioticRedoseAlert>[];

    for (final item in _record.prophylacticAntibiotics) {
      final parts = item.split('|');
      if (parts.isEmpty) continue;
      final name = parts[0].trim();
      final interval = _prophylacticRedoseIntervals[name];
      if (interval == null) continue;

      final clock = parts.length > 2 ? parts[2].trim() : '';
      final administeredAt = _parseClockTimeToday(clock);
      if (administeredAt == null) continue;

      final redoseAt = administeredAt.add(interval);
      final minutesUntil = redoseAt.difference(now).inMinutes;

      if (minutesUntil <= 0) {
        alerts.add(
          _AntibioticRedoseAlert(
            name: name,
            message: 'Redose sugerida agora',
            detail:
                'Dose inicial às $clock. Intervalo de redose de ${interval.inHours} h.',
            isOverdue: true,
          ),
        );
      } else if (minutesUntil <= 30) {
        alerts.add(
          _AntibioticRedoseAlert(
            name: name,
            message: 'Próxima redose às ${_formatClockTime(redoseAt)}',
            detail:
                'Dose inicial às $clock. Intervalo de redose de ${interval.inHours} h.',
            isOverdue: false,
          ),
        );
      }
    }

    return alerts;
  }

  List<String> _splitListText(String value) {
    return value
        .split(RegExp(r'[\n,;]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  AnesthesiaRecord _syncRecordFromPreAnesthetic(AnesthesiaRecord record) {
    final assessment = record.preAnestheticAssessment;
    final allergies = record.patient.allergies.isNotEmpty
        ? record.patient.allergies
        : _splitListText(assessment.allergyDescription);
    final restrictions = record.patient.restrictions.isNotEmpty
        ? record.patient.restrictions
        : _splitListText(assessment.patientRestrictions);
    final medications = record.patient.medications.isNotEmpty
        ? record.patient.medications
        : assessment.currentMedications;

    return record.copyWith(
      patient: record.patient.copyWith(
        asa: record.patient.asa.trim().isNotEmpty
            ? record.patient.asa
            : assessment.asaClassification,
        allergies: allergies,
        restrictions: restrictions,
        medications: medications,
      ),
      airway: record.airway.mallampati.trim().isNotEmpty
          ? record.airway
          : record.airway.copyWith(mallampati: assessment.airway.mallampati),
      surgeryDescription: record.surgeryDescription.trim().isNotEmpty
          ? record.surgeryDescription
          : assessment.surgeryDescription,
      surgeryPriority: record.surgeryPriority.trim().isNotEmpty
          ? record.surgeryPriority
          : assessment.surgeryPriority,
      anesthesiaTechnique: record.anesthesiaTechnique.trim().isNotEmpty
          ? record.anesthesiaTechnique
          : assessment.anestheticPlan.trim(),
      fastingHours: record.fastingHours.trim().isNotEmpty
          ? record.fastingHours
          : assessment.fastingSolids.trim(),
    );
  }

  Future<void> _updatePatient({
    String? name,
    int? age,
    double? weightKg,
    double? heightMeters,
    String? asa,
    List<String>? allergies,
    List<String>? restrictions,
    List<String>? medications,
    bool? allergiesMarkedNone,
    bool? restrictionsMarkedNone,
    bool? medicationsMarkedNone,
    String? informedConsentStatus,
    String? mallampati,
    PatientPopulation? population,
    int? postnatalAgeDays,
    int? gestationalAgeWeeks,
    int? correctedGestationalAgeWeeks,
    double? birthWeightKg,
  }) async {
    setState(() {
      final updatedPatient = _record.patient.copyWith(
        name: name,
        age: age,
        weightKg: weightKg,
        heightMeters: heightMeters,
        asa: asa,
        allergies: allergies,
        restrictions: restrictions,
        medications: medications,
        allergiesMarkedNone: allergiesMarkedNone,
        restrictionsMarkedNone: restrictionsMarkedNone,
        medicationsMarkedNone: medicationsMarkedNone,
        informedConsentStatus: informedConsentStatus,
        population: population,
        postnatalAgeDays: postnatalAgeDays,
        gestationalAgeWeeks: gestationalAgeWeeks,
        correctedGestationalAgeWeeks: correctedGestationalAgeWeeks,
        birthWeightKg: birthWeightKg,
      );

      final updatedAssessment = _record.preAnestheticAssessment.copyWith(
        asaClassification: asa,
        allergyDescription: allergies?.join(', '),
        patientRestrictions: restrictions?.join('\n'),
        currentMedications: medications,
        airway: mallampati == null
            ? null
            : _record.preAnestheticAssessment.airway.copyWith(
                mallampati: mallampati,
              ),
      );

      _record = _record.copyWith(
        patient: updatedPatient,
        preAnestheticAssessment: updatedAssessment,
        airway: mallampati == null
            ? _record.airway
            : _record.airway.copyWith(mallampati: mallampati),
      );
    });

    await _persistRecord();
  }

  Future<void> _updatePreAnestheticAssessment(
    PreAnestheticAssessment assessment, {
    String? asaForPatient,
    String? mallampatiForAirway,
  }) async {
    setState(() {
      _record = _record.copyWith(
        patient: asaForPatient == null
            ? _record.patient
            : _record.patient.copyWith(asa: asaForPatient),
        preAnestheticAssessment: assessment,
        airway: mallampatiForAirway == null
            ? _record.airway
            : _record.airway.copyWith(mallampati: mallampatiForAirway),
      );
    });

    await _persistRecord();
  }

  List<_QuickChoiceOption> get _functionalQuickOptions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _adultFunctionalOptions;
      case PatientPopulation.pediatric:
        return _pediatricFunctionalOptions;
      case PatientPopulation.neonatal:
        return _neonatalFunctionalOptions;
    }
  }

  List<String> get _difficultAirwayPredictorOptions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _adultDifficultAirwayPredictorOptions;
      case PatientPopulation.pediatric:
        return _pediatricDifficultAirwayPredictorOptions;
      case PatientPopulation.neonatal:
        return _neonatalDifficultAirwayPredictorOptions;
    }
  }

  List<String> get _difficultVentilationPredictorOptions {
    switch (_record.patient.population) {
      case PatientPopulation.adult:
        return _adultDifficultVentilationPredictorOptions;
      case PatientPopulation.pediatric:
        return _pediatricDifficultVentilationPredictorOptions;
      case PatientPopulation.neonatal:
        return _neonatalDifficultVentilationPredictorOptions;
    }
  }

  Future<void> _editPatientFunctionalCapacityQuick() async {
    final assessment = _record.preAnestheticAssessment;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _DetailedChoiceDialog(
        title: 'METS / capacidade funcional',
        options: _functionalQuickOptions,
        color: const Color(0xFFD98C16),
        initialValue: assessment.mets,
        customLabel: 'Outros / observações',
        customHintText: 'Descreva limitação funcional se necessário',
      ),
    );

    if (result == null) return;
    await _updatePreAnestheticAssessment(assessment.copyWith(mets: result));
  }

  Future<void> _editPatientDifficultAirwayQuick() async {
    final assessment = _record.preAnestheticAssessment;
    final initialItems = [
      ...assessment.difficultAirwayPredictors,
      if (assessment.otherDifficultAirwayPredictors.trim().isNotEmpty)
        assessment.otherDifficultAirwayPredictors.trim(),
    ];
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: 'Via aérea difícil',
        label: 'Outros achados (um por linha)',
        initialItems: initialItems,
        suggestions: _difficultAirwayPredictorOptions,
        hintText: 'Ex: massa cervical, limitação mandibular, trauma facial',
      ),
    );

    if (result == null) return;
    final selectedSuggestions = result
        .where(_difficultAirwayPredictorOptions.contains)
        .toList();
    final manualItems = result
        .where((item) => !_difficultAirwayPredictorOptions.contains(item))
        .toList();
    await _updatePreAnestheticAssessment(
      assessment.copyWith(
        difficultAirwayPredictors: selectedSuggestions,
        otherDifficultAirwayPredictors: manualItems.join('\n'),
      ),
    );
  }

  Future<void> _editPatientDifficultVentilationQuick() async {
    final assessment = _record.preAnestheticAssessment;
    final initialItems = [
      ...assessment.difficultVentilationPredictors,
      if (assessment.otherDifficultVentilationPredictors.trim().isNotEmpty)
        assessment.otherDifficultVentilationPredictors.trim(),
    ];
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: 'Ventilação difícil',
        label: 'Outros achados (um por linha)',
        initialItems: initialItems,
        suggestions: _difficultVentilationPredictorOptions,
        hintText: 'Ex: vedação difícil, barba densa, edema facial',
      ),
    );

    if (result == null) return;
    final selectedSuggestions = result
        .where(_difficultVentilationPredictorOptions.contains)
        .toList();
    final manualItems = result
        .where((item) => !_difficultVentilationPredictorOptions.contains(item))
        .toList();
    await _updatePreAnestheticAssessment(
      assessment.copyWith(
        difficultVentilationPredictors: selectedSuggestions,
        otherDifficultVentilationPredictors: manualItems.join('\n'),
      ),
    );
  }

  Future<void> _editPatientFastingQuick() async {
    final assessment = _record.preAnestheticAssessment;
    final result = await showDialog<_FastingQuickEditResult>(
      context: context,
      builder: (_) => _FastingQuickEditDialog(
        population: _record.patient.population,
        initialSolids: assessment.fastingSolids,
        initialLiquids: assessment.fastingLiquids,
        initialBreastMilk: assessment.fastingBreastMilk,
        initialNotes: assessment.fastingNotes,
      ),
    );

    if (result == null) return;
    await _updatePreAnestheticAssessment(
      assessment.copyWith(
        fastingSolids: result.solids,
        fastingLiquids: result.liquids,
        fastingBreastMilk: result.breastMilk,
        fastingNotes: result.notes,
      ),
    );
  }

  Future<void> _editPatientInformedConsentStatus() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Termo de Consentimento Informado para Anestesia',
        options: const ['Assinado', 'Não assinado'],
        initialValue: _record.patient.informedConsentStatus,
      ),
    );

    if (result == null) return;
    await _updatePatient(informedConsentStatus: result.trim());
  }

  HemodynamicPoint? _latestPointOfType(String type) =>
      _hemodynamicService.latestPointOfType(_record.hemodynamicPoints, type);

  HemodynamicPoint? get _latestFcPoint => _latestPointOfType('FC');
  HemodynamicPoint? get _latestSpo2Point => _latestPointOfType('SpO2');
  HemodynamicPoint? get _latestPaiPoint => _latestPointOfType('PAI');

  String get _latestBloodPressure {
    return _hemodynamicService.latestBloodPressure(_record.hemodynamicPoints);
  }

  String get _latestPam {
    return _hemodynamicService.latestPam(_record.hemodynamicPoints);
  }

  DateTime? get _hemodynamicAnesthesiaStartAt => _hemodynamicService
      .markerStartAt(_record.hemodynamicMarkers, 'Início da anestesia');

  DateTime? get _hemodynamicSurgeryStartAt => _hemodynamicService.markerStartAt(
    _record.hemodynamicMarkers,
    'Início da cirurgia',
  );

  bool get _hasAnesthesiaEndMarker => _record.hemodynamicMarkers.any(
    (item) => item.label == 'Fim da anestesia',
  );

  bool get _hasSurgeryEndMarker =>
      _record.hemodynamicMarkers.any((item) => item.label == 'Fim da cirurgia');

  String get _paiSummary {
    if (_latestPaiPoint != null) {
      return _latestPaiPoint!.value.round().toString();
    }
    if (_arterialAccesses.isEmpty) return 'Não';
    if (_arterialAccesses.length == 1) return _arterialAccesses.first;
    return '${_arterialAccesses.length} acessos';
  }

  bool get _hasAnesthesiaStartMarker => _record.hemodynamicMarkers.any(
    (item) => item.label == 'Início da anestesia',
  );

  bool get _hasSurgeryStartMarker => _record.hemodynamicMarkers.any(
    (item) => item.label == 'Início da cirurgia',
  );

  List<String> get _missingRequiredFields =>
      _validationService.validateRequiredFields(_record);

  bool get _hasPendingAirway => _missingRequiredFields.contains('Via aérea');
  bool get _hasPendingTechnique =>
      _missingRequiredFields.contains('Técnica anestésica');
  bool get _hasPendingTechniqueDetails =>
      _missingRequiredFields.contains('Descrição da técnica anestésica');
  bool get _hasPendingDrugs =>
      _missingRequiredFields.contains('Drogas e infusões');
  bool get _hasPendingFluidBalance =>
      _missingRequiredFields.contains('Balanço hídrico');
  bool get _hasPendingTimeOut =>
      _record.timeOutChecklist.isEmpty || !_record.timeOutCompleted;

  bool get _usesNeuraxialTechnique => _techniqueProfile.hasNeuraxial;

  String get _caseStageLabel {
    if (!_hasAnesthesiaStartMarker) return 'Aguardando início';
    if (!_hasSurgeryStartMarker) return 'Anestesia iniciada';
    return 'Cirurgia em andamento';
  }

  String get _recordStatusLabel {
    if (_caseStatus == AnesthesiaCaseStatus.finalized) {
      return 'Finalizado';
    }
    if (_missingRequiredFields.isEmpty && !_hasPendingTimeOut) {
      return 'Ficha segura';
    }
    return 'Em preenchimento';
  }

  String _nowLabel() {
    final now = DateTime.now();
    return _formatDateTimeLabel(now);
  }

  DateTime? _parseDateTimeLabel(String value) {
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

  String _formatDateTimeLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String get _displayPreAnestheticDate => _preAnestheticDate.trim().isEmpty
      ? 'Toque para informar'
      : _preAnestheticDate;

  String get _displayAnesthesiaDate =>
      _anesthesiaDate.trim().isEmpty ? 'Toque para informar' : _anesthesiaDate;

  String get _topHighlightMessage {
    if (_caseStatus == AnesthesiaCaseStatus.finalized) {
      return 'Caso finalizado e guardado no arquivo local.';
    }
    if (_missingRequiredFields.isEmpty && !_hasPendingTimeOut) {
      return 'Registro pronto para condução e revisão.';
    }
    return 'Priorize pendências críticas antes de seguir.';
  }

  AnesthesiaCaseStatus get _persistedCaseStatus {
    if (_caseStatus == AnesthesiaCaseStatus.finalized) {
      return AnesthesiaCaseStatus.finalized;
    }

    final hasPreAnesthetic =
        _record.preAnestheticAssessment.asaClassification.trim().isNotEmpty ||
        _record.preAnestheticAssessment.anestheticPlan.trim().isNotEmpty ||
        _record.preAnestheticAssessment.surgeryDescription.trim().isNotEmpty ||
        _record.preAnestheticAssessment.comorbidities.isNotEmpty ||
        _record.preAnestheticAssessment.currentMedications.isNotEmpty ||
        _record.preAnestheticAssessment.allergyDescription.trim().isNotEmpty;

    final hasIntraoperativeContent =
        _record.surgeryDescription.trim().isNotEmpty ||
        _record.surgeonName.trim().isNotEmpty ||
        _record.airway.device.trim().isNotEmpty ||
        _record.anesthesiaTechnique.trim().isNotEmpty ||
        _record.drugs.isNotEmpty ||
        _record.events.isNotEmpty ||
        _record.hemodynamicMarkers.isNotEmpty ||
        _record.hemodynamicPoints.isNotEmpty;

    if (hasIntraoperativeContent) {
      return AnesthesiaCaseStatus.inProgress;
    }
    if (hasPreAnesthetic) {
      return AnesthesiaCaseStatus.preAnesthetic;
    }
    return _caseStatus;
  }

  Future<void> _addHemodynamicMarker(String label) async {
    if (label == 'Início da anestesia' && _hasAnesthesiaStartMarker) {
      return;
    }
    final now = DateTime.now();
    final updatedMarkers = _hemodynamicService.addMarker(
      markers: _record.hemodynamicMarkers,
      label: label,
      now: now,
    );

    if (identical(updatedMarkers, _record.hemodynamicMarkers)) return;

    setState(() {
      _record = _record.copyWith(hemodynamicMarkers: updatedMarkers);
      if (label == 'Início da anestesia') {
        _anesthesiaDate = _formatDateTimeLabel(now);
      }
    });
    _startHemodynamicTickerIfNeeded();
    await _persistRecord();
  }

  double _currentHemodynamicElapsedMinutes() {
    return _hemodynamicService.currentElapsedMinutes(
      _hemodynamicAnesthesiaStartAt,
      DateTime.now(),
    );
  }

  String _formatElapsedFrom(DateTime? startedAt) =>
      _hemodynamicService.formatElapsedFrom(startedAt, DateTime.now());

  Future<void> _addInlineHemodynamicPoint(double value) async {
    if (!_hasAnesthesiaStartMarker) return;
    final time = _currentHemodynamicElapsedMinutes();
    final updatedPoints = _hemodynamicService.addPoint(
      points: _record.hemodynamicPoints,
      type: _inlineHemodynamicType,
      value: value,
      time: time,
    );

    setState(() {
      _record = _record.copyWith(hemodynamicPoints: updatedPoints);
    });
    await _persistRecord();
  }

  Future<void> _removeInlineHemodynamicPoint(HemodynamicPoint point) async {
    final updatedPoints = _hemodynamicService.removePoint(
      points: _record.hemodynamicPoints,
      point: point,
    );
    setState(() {
      _record = _record.copyWith(hemodynamicPoints: updatedPoints);
    });
    await _persistRecord();
  }

  void _applyInlineHemodynamicPointMove(
    String type,
    double matchTime,
    double matchValue,
    double newValue,
    double newTime,
  ) {
    if (!_hasAnesthesiaStartMarker || _inlineHemodynamicRemoveMode) return;
    final updatedPoints = _hemodynamicService.updatePoint(
      points: _record.hemodynamicPoints,
      type: type,
      matchTime: matchTime,
      matchValue: matchValue,
      newTime: newTime,
      newValue: newValue,
    );
    if (identical(updatedPoints, _record.hemodynamicPoints)) return;
    setState(() {
      _record = _record.copyWith(hemodynamicPoints: updatedPoints);
    });
  }

  AnesthesiaRecord _migrateLegacyHemodynamics(AnesthesiaRecord record) =>
      _hemodynamicService.migrateLegacyHemodynamics(record);

  @override
  void initState() {
    super.initState();
    _initialRecord = widget.initialRecord ?? const AnesthesiaRecord.empty();
    _record = _syncRecordFromPreAnesthetic(
      _migrateLegacyHemodynamics(_initialRecord),
    );
    _caseStatus = widget.initialCaseStatus;
    _venousAccesses = List<String>.from(_record.venousAccesses);
    _arterialAccesses = List<String>.from(_record.arterialAccesses);
    _monitoringItems = List<String>.from(_record.monitoringItems);
    _preAnestheticDate = widget.initialPreAnestheticDate;
    _anesthesiaDate = widget.initialAnesthesiaDate.trim().isEmpty
        ? _nowLabel()
        : widget.initialAnesthesiaDate;
    if (widget.loadPersistedRecord) {
      _loadPersistedRecord();
    }
    if (widget.autoOpenPreAnesthetic) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showPreAnestheticDialog();
        }
      });
    }
    _startHemodynamicTickerIfNeeded();
  }

  @override
  void dispose() {
    _hemodynamicTicker?.cancel();
    super.dispose();
  }

  Future<void> _loadPersistedRecord() async {
    final storedRecord = await _storageService.loadRecord();
    if (!mounted || storedRecord == null) return;

    setState(() {
      _record = _syncRecordFromPreAnesthetic(
        _migrateLegacyHemodynamics(storedRecord),
      );
      _venousAccesses = List<String>.from(_record.venousAccesses);
      _arterialAccesses = List<String>.from(_record.arterialAccesses);
      _monitoringItems = List<String>.from(_record.monitoringItems);
    });
    _startHemodynamicTickerIfNeeded();
  }

  Future<bool> _persistRecord() async {
    final messenger = ScaffoldMessenger.of(context);
    final caseId = widget.caseId;
    try {
      if (caseId == null) {
        await _storageService.saveRecord(_record);
        return true;
      }

      final now = DateTime.now().toIso8601String();
      await _storageService.upsertCase(
        AnesthesiaCase(
          id: caseId,
          createdAtIso: widget.createdAtIso ?? now,
          updatedAtIso: now,
          preAnestheticDate: _preAnestheticDate,
          anesthesiaDate: _anesthesiaDate,
          status: _persistedCaseStatus,
          record: _record,
        ),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
      return false;
    }
  }

  void _startHemodynamicTickerIfNeeded() {
    _hemodynamicTicker?.cancel();
    if (_hemodynamicAnesthesiaStartAt == null) return;
    _hemodynamicTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _runAiAnalysis() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Enviando ficha para análise...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 900),
      ),
    );

    final analysis = await _analysisService.analyzeRecord(_record);
    if (!mounted) return;

    messenger.clearSnackBars();
    await showDialog<void>(
      context: context,
      builder: (_) => RecordAnalysisDialog(analysis: analysis),
    );
  }

  Future<void> _exportCasePdf() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Gerando PDF da ficha...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 900),
      ),
    );

    try {
      final bytes = await _reportExportService.buildCasePdf(
        record: _record,
        status: _persistedCaseStatus,
        caseId: widget.caseId,
      );
      if (!mounted) return;
      messenger.clearSnackBars();

      final filename = _reportExportService.buildFileName(_record);
      await showDialog<void>(
        context: context,
        builder: (_) => _ExportCaseDialog(
          onPreviewPressed: () => _previewPdf(bytes),
          onPrintPressed: () => _previewPdf(bytes),
          onSharePressed: () => _sharePdf(bytes, filename),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Falha ao gerar o PDF da ficha: $error'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _exportCaseJson() async {
    final jsonText = _reportExportService.buildCaseJson(
      record: _record,
      status: _persistedCaseStatus,
      caseId: widget.caseId,
    );
    final subject =
        'Ficha de ${_record.patient.name.isNotEmpty ? _record.patient.name : 'paciente'}';
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => JsonExportDialog(content: jsonText, subject: subject),
    );
  }

  Future<void> _previewPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _sharePdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<void> _finalizarCaso() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar caso'),
        content: const Text(
          'A ficha será marcada como finalizada e ficará guardada no arquivo local para reabertura posterior.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final previousStatus = _caseStatus;
    setState(() {
      _caseStatus = AnesthesiaCaseStatus.finalized;
    });
    final saved = await _persistRecord();
    if (!mounted) return;
    if (!saved) {
      setState(() {
        _caseStatus = previousStatus;
      });
      return;
    }
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Caso finalizado e salvo com sucesso.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _showPreAnestheticDialog() async {
    final result = await Navigator.of(context).push<PreAnestheticScreenResult>(
      MaterialPageRoute<PreAnestheticScreenResult>(
        builder: (_) => PreAnestheticScreen(
          patient: _record.patient,
          initialAssessment: _record.preAnestheticAssessment,
          initialConsultationDate: _preAnestheticDate.trim().isEmpty
              ? _nowLabel()
              : _preAnestheticDate,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      final updatedPatient = result.patient.copyWith(
        asa: result.assessment.asaClassification,
        allergies: result.assessment.allergyDescription.trim().isEmpty
            ? result.patient.allergies
            : _splitListText(result.assessment.allergyDescription),
        restrictions: result.assessment.patientRestrictions.trim().isEmpty
            ? result.patient.restrictions
            : _splitListText(result.assessment.patientRestrictions),
        medications: result.assessment.currentMedications,
      );

      _record = _syncRecordFromPreAnesthetic(
        _record.copyWith(
          patient: updatedPatient,
          preAnestheticAssessment: result.assessment,
          airway: result.assessment.airway,
          surgeryDescription: result.assessment.surgeryDescription.trim(),
          surgeryPriority: result.assessment.surgeryPriority.trim(),
          fastingHours: _record.fastingHours.trim().isEmpty
              ? result.assessment.fastingSolids
              : _record.fastingHours,
          anesthesiaTechnique: result.assessment.anestheticPlan.trim().isEmpty
              ? _record.anesthesiaTechnique
              : result.assessment.anestheticPlan.trim(),
        ),
      );
      _preAnestheticDate = result.consultationDate.trim();
    });
    await _persistRecord();
  }

  Future<void> _openPostAnesthesiaRecoveryScreen() async {
    final result = await Navigator.of(context).push<PostAnesthesiaRecovery>(
      MaterialPageRoute<PostAnesthesiaRecovery>(
        builder: (_) => PostAnesthesiaRecoveryScreen(record: _record),
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(postAnesthesiaRecovery: result);
    });
    await _persistRecord();
  }

  Future<void> _editPreAnestheticDate() async {
    final currentValue =
        _parseDateTimeLabel(_preAnestheticDate) ?? DateTime.now();
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

    final result = _formatDateTimeLabel(
      DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
    );
    setState(() {
      _preAnestheticDate = result.trim();
    });
    await _persistRecord();
  }

  Future<void> _editAnesthesiaDate() async {
    final currentValue = _parseDateTimeLabel(_anesthesiaDate) ?? DateTime.now();
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

    final result = _formatDateTimeLabel(
      DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
    );
    setState(() {
      _anesthesiaDate = result.trim();
    });
    await _persistRecord();
  }

  Future<void> _editPatientName() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Nome do paciente',
        label: 'Nome',
        initialValue: _record.patient.name,
        hintText: 'Digite o nome do paciente',
      ),
    );

    if (result == null) return;
    await _updatePatient(name: result);
  }

  Future<void> _editPatientAge() async {
    final initialValue = _record.patient.age > 0
        ? _record.patient.age.toString()
        : '';
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Idade do paciente',
        label: 'Idade',
        initialValue: initialValue,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        hintText: 'Digite a idade em anos',
      ),
    );

    if (result == null) return;
    await _updatePatient(age: int.tryParse(result) ?? 0);
  }

  Future<void> _editPatientWeight() async {
    final initialValue = _record.patient.weightKg > 0
        ? _record.patient.weightKg.toStringAsFixed(0)
        : '';
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Peso do paciente',
        label: 'Peso (kg)',
        initialValue: initialValue,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        ],
        hintText: 'Digite o peso em kg',
      ),
    );

    if (result == null) return;
    await _updatePatient(
      weightKg: double.tryParse(result.replaceAll(',', '.')) ?? 0,
    );
  }

  Future<void> _editPatientHeight() async {
    final initialValue = _record.patient.heightMeters > 0
        ? (_record.patient.heightMeters * 100)
              .toStringAsFixed(0)
              .replaceAll('.', ',')
        : '';
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Altura do paciente',
        label: 'Altura (cm)',
        initialValue: initialValue,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        ],
        hintText: 'Digite a altura em centímetros',
      ),
    );

    if (result == null) return;
    await _updatePatient(
      heightMeters: (double.tryParse(result.replaceAll(',', '.')) ?? 0) / 100,
    );
  }

  Future<void> _editPatientAsa() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _DetailedChoiceDialog(
        title: 'Classificação ASA',
        options: _asaReferenceOptions,
        initialValue: _record.patient.asa,
        color: const Color(0xFFD98C16),
        footerText: 'Use o sufixo E em urgencia/emergencia quando aplicavel.',
      ),
    );

    if (result == null) return;
    await _updatePatient(asa: result);
  }

  Future<void> _editPatientMallampati() async {
    final currentMallampati =
        _record.preAnestheticAssessment.airway.mallampati.trim().isNotEmpty
        ? _record.preAnestheticAssessment.airway.mallampati
        : _record.airway.mallampati;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _DetailedChoiceDialog(
        title: 'Mallampati',
        options: _mallampatiReferenceOptions,
        initialValue: currentMallampati,
        color: const Color(0xFF2B76D2),
      ),
    );

    if (result == null) return;
    await _updatePatient(mallampati: result);
  }

  Future<void> _editPatientPopulation() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Perfil do paciente',
        options: PatientPopulation.values.map((item) => item.code).toList(),
        initialValue: _record.patient.population.code,
        optionLabelBuilder: (option) =>
            PatientPopulationX.fromCode(option).label,
      ),
    );

    if (result == null) return;
    await _updatePatient(population: PatientPopulationX.fromCode(result));
  }

  Future<void> _editPatientPostnatalAge() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Idade pós-natal',
        label: 'Idade pós-natal (dias)',
        initialValue: _record.patient.postnatalAgeDays > 0
            ? _record.patient.postnatalAgeDays.toString()
            : '',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );

    if (result == null) return;
    await _updatePatient(postnatalAgeDays: int.tryParse(result) ?? 0);
  }

  Future<void> _editPatientGestationalAge() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Idade gestacional ao nascer',
        label: 'IG ao nascer (semanas)',
        initialValue: _record.patient.gestationalAgeWeeks > 0
            ? _record.patient.gestationalAgeWeeks.toString()
            : '',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );

    if (result == null) return;
    await _updatePatient(gestationalAgeWeeks: int.tryParse(result) ?? 0);
  }

  Future<void> _editPatientCorrectedGestationalAge() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Idade gestacional corrigida',
        label: 'IG corrigida (semanas)',
        initialValue: _record.patient.correctedGestationalAgeWeeks > 0
            ? _record.patient.correctedGestationalAgeWeeks.toString()
            : '',
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );

    if (result == null) return;
    await _updatePatient(
      correctedGestationalAgeWeeks: int.tryParse(result) ?? 0,
    );
  }

  Future<void> _editPatientBirthWeight() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SingleFieldDialog(
        title: 'Peso ao nascer',
        label: 'Peso ao nascer (kg)',
        initialValue: _record.patient.birthWeightKg > 0
            ? _record.patient.birthWeightKg
                  .toStringAsFixed(2)
                  .replaceAll('.', ',')
            : '',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        ],
      ),
    );

    if (result == null) return;
    await _updatePatient(
      birthWeightKg: double.tryParse(result.replaceAll(',', '.')) ?? 0,
    );
  }

  Future<void> _editPatientAllergies() async {
    final result = await showDialog<ListFieldDialogResult>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: 'Alergias',
        label: 'Alergias',
        initialItems: _record.patient.allergies,
        suggestions: _commonAllergies,
        hintText: 'Uma alergia por linha',
        clearButtonLabel: 'Sem alergias',
        initialMarkedNone: _record.patient.allergiesMarkedNone,
        supportsMarkedNone: true,
      ),
    );

    if (result == null) return;
    await _updatePatient(
      allergies: result.items,
      allergiesMarkedNone: result.markedNone,
    );
  }

  Future<void> _editPatientRestrictions() async {
    final result = await showDialog<ListFieldDialogResult>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: 'Restrições',
        label: 'Restrições',
        initialItems: _record.patient.restrictions,
        suggestions: _profileRestrictionSuggestions,
        hintText: 'Uma restrição por linha',
        clearButtonLabel: 'Sem restrições',
        initialMarkedNone: _record.patient.restrictionsMarkedNone,
        supportsMarkedNone: true,
      ),
    );

    if (result == null) return;
    await _updatePatient(
      restrictions: result.items,
      restrictionsMarkedNone: result.markedNone,
    );
  }

  Future<void> _editPatientMedications() async {
    final result = await showDialog<ListFieldDialogResult>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: 'Medicações em uso',
        label: 'Medicações',
        initialItems: _record.patient.medications,
        suggestions: _profileMedicationSuggestions,
        hintText: 'Uma medicação por linha',
        clearButtonLabel: 'Sem medicações',
        initialMarkedNone: _record.patient.medicationsMarkedNone,
        supportsMarkedNone: true,
      ),
    );

    if (result == null) return;
    await _updatePatient(
      medications: result.items,
      medicationsMarkedNone: result.markedNone,
    );
  }

  Future<void> _editViaAereaSection(AirwayEditSection section) async {
    final result = await showDialog<Airway>(
      context: context,
      builder: (_) => AirwayDialog(
        initialAirway: _record.airway,
        section: section,
        patient: _record.patient,
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(
        airway: result,
        preAnestheticAssessment: _record.preAnestheticAssessment.copyWith(
          airway: result,
        ),
      );
    });
    await _persistRecord();
  }

  Future<void> _editBalancoHidrico() async {
    final result = await showDialog<FluidBalance>(
      context: context,
      builder: (_) => BalanceOnlyDialog(
        initialFluidBalance: _record.fluidBalance,
        anesthesiaElapsedHours: _anesthesiaElapsedHours,
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(fluidBalance: result);
    });
    await _persistRecord();
  }

  Future<void> _editMechanicalVentilation() async {
    final suggestion = _suggestedMechanicalVentilation;
    final current = _record.mechanicalVentilation.isEmpty
        ? suggestion.settings
        : _record.mechanicalVentilation;
    final result = await showDialog<MechanicalVentilationSettings>(
      context: context,
      builder: (_) => MechanicalVentilationDialog(
        initialSettings: current,
        suggestedSettings: suggestion.settings,
        suggestionReason: suggestion.reason,
        population: _record.patient.population,
      ),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(mechanicalVentilation: result);
    });
    await _persistRecord();
  }

  Future<void> _editEmergence() async {
    final result = await showDialog<_EmergenceDialogResult>(
      context: context,
      builder: (_) => _EmergenceDialog(
        initialStatus: _record.emergenceStatus,
        initialNotes: _record.emergenceNotes,
        patientDestination: _displayPatientDestination,
      ),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(
        emergenceStatus: result.status,
        emergenceNotes: result.notes,
      );
    });
    await _persistRecord();
  }

  Future<void> _editReposicaoVolemica() async {
    final inferredSurgicalSize = _inferSurgicalSizeFromDescription();
    final result = await showDialog<FluidBalanceDialogResult>(
      context: context,
      builder: (_) => FluidBalanceDialog(
        initialFluidBalance: _record.fluidBalance,
        initialSurgicalSize: _record.surgicalSize,
        suggestedSurgicalSize: inferredSurgicalSize,
        initialFastingHours: _displayFastingHours,
        patientWeightKg: _record.patient.weightKg,
        patientHeightMeters: _record.patient.heightMeters,
        patientPopulation: _record.patient.population,
        patientAgeYears: _record.patient.age,
        patientPostnatalAgeDays: _record.patient.postnatalAgeDays,
        patientGestationalAgeWeeks: _record.patient.gestationalAgeWeeks,
        patientBirthWeightKg: _record.patient.birthWeightKg,
        anesthesiaElapsedHours: _anesthesiaElapsedHours,
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(
        fluidBalance: result.fluidBalance,
        surgicalSize: result.surgicalSize,
        fastingHours: result.fastingHours,
      );
    });
    await _persistRecord();
  }

  Future<void> _editMaintenanceAgents() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: 'Manutenção da anestesia',
        label: 'Agentes / estratégia de manutenção',
        initialItems: _lineItems(_record.maintenanceAgents),
        hintText: 'Um item por linha',
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(maintenanceAgents: result.join('\n'));
    });
    await _persistRecord();
  }

  Future<void> _editTecnicaAnestesica() async {
    final result = await showDialog<TechniqueDialogResult>(
      context: context,
      builder: (_) => TechniqueDialog(
        initialTechnique: _record.anesthesiaTechnique,
        initialDetails: _record.anesthesiaTechniqueDetails,
        patient: _record.patient,
      ),
    );

    if (result == null) return;

    final nextRecord = _record.copyWith(
      anesthesiaTechnique: result.technique,
      anesthesiaTechniqueDetails: result.details,
      preAnestheticAssessment: _record.preAnestheticAssessment.copyWith(
        anestheticPlan: result.technique,
      ),
    );
    final refreshedMaintenanceItems =
        _refreshMaintenanceEntriesForCurrentTechnique(
          _lineItems(nextRecord.maintenanceAgents),
        );

    setState(() {
      _record = nextRecord.copyWith(
        maintenanceAgents: refreshedMaintenanceItems.join('\n'),
      );
    });
    await _persistRecord();
  }

  Future<void> _editAcessoVenoso() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => VenousAccessDialog(initialItems: _venousAccesses),
    );
    if (result == null) return;
    setState(() {
      _venousAccesses = result;
      _record = _record.copyWith(venousAccesses: result);
    });
    await _persistRecord();
  }

  Future<void> _editAcessoArterial() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => ArterialAccessDialog(initialItems: _arterialAccesses),
    );
    if (result == null) return;
    setState(() {
      _arterialAccesses = result;
      _record = _record.copyWith(arterialAccesses: result);
    });
    await _persistRecord();
  }

  Future<void> _editNeuraxialNeedles() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) =>
          NeuraxialNeedlesDialog(initialItems: _record.neuraxialNeedles),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(neuraxialNeedles: result);
    });
    await _persistRecord();
  }

  Future<void> _editAnesthesiaMaterials() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) =>
          _AnesthesiaMaterialsDialog(initialItems: _record.anesthesiaMaterials),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(anesthesiaMaterials: result);
    });
    await _persistRecord();
  }

  Future<void> _toggleMonitoringItem(String item) async {
    final next = List<String>.from(_monitoringItems);
    if (next.contains(item)) {
      next.remove(item);
    } else {
      next.add(item);
    }
    final customItems = next
        .where((entry) => !_monitoringOptions.contains(entry))
        .toList();
    final orderedStandardItems = _monitoringOptions
        .where(next.contains)
        .toList();

    setState(() {
      _monitoringItems = [...orderedStandardItems, ...customItems];
      _record = _record.copyWith(monitoringItems: _monitoringItems);
    });
    await _persistRecord();
  }

  Future<void> _editCustomMonitoringItems() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: 'Outros itens de monitorização',
        label: 'Outros',
        initialItems: _monitoringItems
            .where((item) => !_monitoringOptions.contains(item))
            .toList(),
        hintText: 'Um item por linha',
      ),
    );
    if (result == null) return;
    final orderedStandardItems = _monitoringOptions
        .where(_monitoringItems.contains)
        .toList();
    setState(() {
      _monitoringItems = [...orderedStandardItems, ...result];
      _record = _record.copyWith(monitoringItems: _monitoringItems);
    });
    await _persistRecord();
  }

  Future<void> _editSedationMedications() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => CatalogMedicationDialog(
        title: 'Editar Sedação associada',
        catalogItems: _profileSedationMedicationOptions,
        initialItems: _record.sedationMedications,
      ),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(sedationMedications: result);
    });
    await _persistRecord();
  }

  Future<void> _editDrogasInfusoes() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => DrugInfusionsDialog(initialItems: _record.drugs),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(drugs: result);
    });
    await _persistRecord();
  }

  Future<void> _editAdjuvantes() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => AdjunctsDialog(initialItems: _record.adjuncts),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(adjuncts: result);
    });
    await _persistRecord();
  }

  Future<void> _editOtherMedications() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => CatalogMedicationDialog(
        title: 'Editar Outras medicações',
        catalogItems: _profileOtherMedicationOptions,
        initialItems: _record.otherMedications,
      ),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(otherMedications: result);
    });
    await _persistRecord();
  }

  Future<void> _editVasoactiveDrugs() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => VasoactiveDrugsDialog(
        catalogItems: _profileVasoactiveDrugOptions,
        initialItems: _record.vasoactiveDrugs,
      ),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(vasoactiveDrugs: result);
    });
    await _persistRecord();
  }

  Future<void> _editProphylacticAntibiotics() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => CatalogMedicationDialog(
        title: 'Editar Antibiótico profilaxia',
        catalogItems: _profileProphylacticAntibioticOptions,
        initialItems: _record.prophylacticAntibiotics,
        suggestions: _surgeryBasedAntibioticSuggestions,
      ),
    );
    if (result == null) return;
    setState(() {
      _record = _record.copyWith(prophylacticAntibiotics: result);
    });
    await _persistRecord();
  }

  Future<void> _editSurgerySection(SurgeryInfoSection section) async {
    if (section == SurgeryInfoSection.surgeon) {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (_) => StructuredTeamMembersDialog(
          dialogTitle: 'Cirurgiões',
          dialogAddButtonLabel: 'Adicionar cirurgião',
          dialogEmptyStateText: 'Nenhum cirurgião adicionado.',
          initialItems: _lineItems(_record.surgeonName),
        ),
      );
      if (result == null) return;
      setState(() {
        _record = _record.copyWith(surgeonName: result.join('\n'));
      });
      await _persistRecord();
      return;
    }

    if (section == SurgeryInfoSection.assistants) {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (_) => StructuredTeamMembersDialog(
          dialogTitle: 'Auxiliares',
          dialogAddButtonLabel: 'Adicionar auxiliar',
          dialogEmptyStateText: 'Nenhum auxiliar adicionado.',
          initialItems: _record.assistantNames,
        ),
      );
      if (result == null) return;
      setState(() {
        _record = _record.copyWith(assistantNames: result);
      });
      await _persistRecord();
      return;
    }

    if (section == SurgeryInfoSection.notes) {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (_) => ListFieldDialog(
          title: 'Anotações relevantes',
          label: 'Anotações relevantes',
          initialItems: _lineItems(_record.operationalNotes),
          hintText: 'Uma anotação por linha',
        ),
      );
      if (result == null) return;
      setState(() {
        _record = _record.copyWith(operationalNotes: result.join('\n'));
      });
      await _persistRecord();
      return;
    }

    final result = await showDialog<SurgeryInfoDialogResult>(
      context: context,
      builder: (_) => SurgeryInfoDialog(
        section: section,
        initialDescription: _record.surgeryDescription,
        initialPriority: _displaySurgeryPriority,
        initialSurgeon: _record.surgeonName,
        initialAssistants: _record.assistantNames,
        initialDestination: _record.patientDestination,
        initialOtherDestination: _record.otherPatientDestination,
        initialNotes: _record.operationalNotes,
        initialChecklist: _record.safeSurgeryChecklist,
        initialTimeOutChecklist: _record.timeOutChecklist,
        initialTimeOutCompleted: _record.timeOutCompleted,
        patientPopulation: _record.patient.population,
      ),
    );

    if (result == null) return;

    setState(() {
      _record = _record.copyWith(
        surgeryDescription: result.description,
        surgeryPriority: result.priority,
        surgeonName: result.surgeon,
        assistantNames: result.assistants,
        patientDestination: result.destination,
        otherPatientDestination: result.otherDestination,
        operationalNotes: result.notes,
        safeSurgeryChecklist: result.checklist,
        timeOutChecklist: result.timeOutChecklist,
        timeOutCompleted: result.timeOutCompleted,
      );
    });
    await _persistRecord();
  }

  Future<void> _editAnesthesiologists() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) =>
          AnesthesiologistsDialog(initialItems: _anesthesiologistEntries),
    );

    if (result == null) return;

    final first = result.isEmpty
        ? ['', '', '']
        : [...result.first.split('|'), '', '', ''];
    setState(() {
      _record = _record.copyWith(
        anesthesiologists: result,
        anesthesiologistName: first[0].trim(),
        anesthesiologistCrm: first[1].trim(),
        anesthesiologistDetails: first[2].trim(),
      );
    });
    await _persistRecord();
  }

  Future<void> _toggleTimeOutChecklistItem(String item) async {
    final next = List<String>.from(_record.timeOutChecklist);
    if (next.contains(item)) {
      next.remove(item);
    } else {
      next.add(item);
    }

    setState(() {
      _record = _record.copyWith(
        timeOutChecklist: next,
        timeOutCompleted: next.length == _timeOutOptions.length
            ? _record.timeOutCompleted
            : false,
      );
    });
    await _persistRecord();
  }

  bool _hasPreparationChecklistItem(String item) {
    const aliases = <String, List<String>>{
      'Equipamento de anestesia checado': [
        'Equipamento de anestesia checado',
        'Aparelho de anestesia checado',
        'Oxigênio, aspirador e ventilador testados',
        'Materiais e equipamentos conferidos',
      ],
      'Materiais para intubação disponíveis e testados': [
        'Materiais para intubação disponíveis e testados',
        'Material de via aérea disponível',
      ],
      'Termo de consentimento assinado': [
        'Termo de consentimento assinado',
        'Consentimento confirmado',
      ],
      'Pré-anestésico realizado': ['Pré-anestésico realizado'],
      'Monitorização instalada e funcionando': [
        'Monitorização instalada e funcionando',
      ],
      'Acesso venoso pérvio': ['Acesso venoso pérvio'],
    };
    return aliases[item]!.any(_record.safeSurgeryChecklist.contains);
  }

  Future<void> _togglePreparationChecklistItem(String item) async {
    const aliases = <String, List<String>>{
      'Equipamento de anestesia checado': [
        'Equipamento de anestesia checado',
        'Aparelho de anestesia checado',
        'Oxigênio, aspirador e ventilador testados',
        'Materiais e equipamentos conferidos',
      ],
      'Materiais para intubação disponíveis e testados': [
        'Materiais para intubação disponíveis e testados',
        'Material de via aérea disponível',
      ],
      'Termo de consentimento assinado': [
        'Termo de consentimento assinado',
        'Consentimento confirmado',
      ],
      'Pré-anestésico realizado': ['Pré-anestésico realizado'],
      'Monitorização instalada e funcionando': [
        'Monitorização instalada e funcionando',
      ],
      'Acesso venoso pérvio': ['Acesso venoso pérvio'],
    };
    final next = List<String>.from(_record.safeSurgeryChecklist)
      ..removeWhere((entry) => aliases[item]!.contains(entry));
    if (!_hasPreparationChecklistItem(item)) {
      next.add(item);
    }

    setState(() {
      _record = _record.copyWith(safeSurgeryChecklist: next);
    });
    await _persistRecord();
  }

  Future<void> _finalizeTimeOutFromCard() async {
    if (_record.timeOutChecklist.length != _timeOutOptions.length) return;
    setState(() {
      _record = _record.copyWith(timeOutCompleted: true);
    });
    await _persistRecord();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1100;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              child: PageContainer(
                child: Column(
                  children: [
                    TopBarWidget(
                      onPreAnestheticTap: _showPreAnestheticDialog,
                      onRecoveryTap: _openPostAnesthesiaRecoveryScreen,
                      caseStage: _caseStageLabel,
                      recordStatus: _recordStatusLabel,
                      highlightMessage: _topHighlightMessage,
                      preAnestheticDateLabel: _displayPreAnestheticDate,
                      anesthesiaDateLabel: _displayAnesthesiaDate,
                      onPreAnestheticDateTap: _editPreAnestheticDate,
                      onAnesthesiaDateTap: _editAnesthesiaDate,
                    ),
                    const SizedBox(height: 10),
                    AnesthesiaHeaderWidget(
                      key: _patientSummaryKey,
                      patient: _record.patient,
                      preAnestheticAssessment: _record.preAnestheticAssessment,
                      mallampati:
                          _usesMallampatiInCase &&
                              _record.preAnestheticAssessment.airway.mallampati
                                  .trim()
                                  .isNotEmpty
                          ? _record.preAnestheticAssessment.airway.mallampati
                          : _usesMallampatiInCase
                          ? _record.airway.mallampati
                          : '',
                      onNameTap: _editPatientName,
                      onAgeTap: _editPatientAge,
                      onWeightTap: _editPatientWeight,
                      onHeightTap: _editPatientHeight,
                      onPopulationTap: _editPatientPopulation,
                      onPostnatalAgeTap: _editPatientPostnatalAge,
                      onGestationalAgeTap: _editPatientGestationalAge,
                      onCorrectedGestationalAgeTap:
                          _editPatientCorrectedGestationalAge,
                      onBirthWeightTap: _editPatientBirthWeight,
                      onAsaTap: _editPatientAsa,
                      onInformedConsentTap: _editPatientInformedConsentStatus,
                      onFunctionalCapacityTap:
                          _editPatientFunctionalCapacityQuick,
                      onDifficultAirwayTap: _editPatientDifficultAirwayQuick,
                      onDifficultVentilationTap:
                          _editPatientDifficultVentilationQuick,
                      onFastingTap: _editPatientFastingQuick,
                      onMallampatiTap: _usesMallampatiInCase
                          ? _editPatientMallampati
                          : null,
                      onAllergiesTap: _editPatientAllergies,
                      onRestrictionsTap: _editPatientRestrictions,
                      onMedicationsTap: _editPatientMedications,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(height: 240, child: _buildEventsCard()),
                    const SizedBox(height: 12),
                    desktop
                        ? _buildDesktopTopCardsAndFullWidthChart()
                        : Column(
                            children: [
                              _buildMobileOverview(),
                              const SizedBox(height: 12),
                              _buildChartSection(dominant: false),
                              const SizedBox(height: 12),
                              _buildIntraoperativeSection(),
                            ],
                          ),
                    const SizedBox(height: 12),
                    FooterBar(
                      onExportPressed: _exportCasePdf,
                      onVerifyPressed: _runAiAnalysis,
                      onFinalizePressed: _finalizarCaso,
                      onExportJsonPressed: _exportCaseJson,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDesktopOverview() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildSectionHeader(
                title: 'Preparo e Monitorização',
                subtitle: 'Via aérea, acessos e monitorização contínua',
                accent: const Color(0xFF2B76D2),
              ),
              const SizedBox(height: 10),
              _buildAirwayCard(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildVenousAccessCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildArterialAccessCard()),
                ],
              ),
              const SizedBox(height: 12),
              _buildMonitoringCard(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _buildSectionHeader(
                title: 'Procedimento e Anestesia',
                subtitle: 'Cirurgia, time-out, técnica, medicações e balanço',
                accent: const Color(0xFF8A5DD3),
              ),
              const SizedBox(height: 10),
              _buildSurgeryCards(desktop: true),
              const SizedBox(height: 12),
              _buildTechniqueCard(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDrugsCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildAdjunctsCard()),
                ],
              ),
              const SizedBox(height: 12),
              _buildFluidBalanceCard(),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildDesktopHemodynamicFirstLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 9,
          child: Column(
            children: [
              _buildSectionHeader(
                title: 'Registro Intraoperatório',
                subtitle:
                    'Área principal de condução do caso e registro hemodinâmico',
                accent: const Color(0xFF2B76D2),
              ),
              const SizedBox(height: 10),
              _buildChartSection(dominant: true),
              const SizedBox(height: 12),
              SizedBox(height: 240, child: _buildEventsCard()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildSectionHeader(
                title: 'Blocos de Apoio',
                subtitle:
                    'Informações clínicas, preparo e documentação complementar',
                accent: const Color(0xFF6B7CF6),
              ),
              const SizedBox(height: 10),
              _buildSurgeryCards(desktop: true),
              const SizedBox(height: 12),
              _buildTechniqueCard(),
              const SizedBox(height: 12),
              _buildAirwayCard(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildVenousAccessCard()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildArterialAccessCard()),
                ],
              ),
              const SizedBox(height: 12),
              _buildMonitoringCard(),
              const SizedBox(height: 12),
              _buildDrugsCard(),
              const SizedBox(height: 12),
              _buildAdjunctsCard(),
              const SizedBox(height: 12),
              _buildFluidBalanceCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTopCardsAndFullWidthChart() {
    return Column(
      children: [
        _buildEqualWidthTripletRow(
          first: _buildSurgerySummaryCard(
            key: const Key('surgery-description-card'),
            tapKey: const Key('surgery-description-entry'),
            title: '1) Cirurgia',
            icon: Icons.content_paste_search_outlined,
            value: _multilineSummary(_record.surgeryDescription),
            section: SurgeryInfoSection.description,
            isCompleted: _record.surgeryDescription.trim().isNotEmpty,
          ),
          second: _buildSurgerySummaryCard(
            key: const Key('surgery-priority-card'),
            tapKey: const Key('surgery-priority-entry'),
            title: '2) Tipo de cirurgia',
            icon: Icons.priority_high_outlined,
            value: _valueOrPlaceholder(_displaySurgeryPriority),
            section: SurgeryInfoSection.priority,
            isCompleted: _displaySurgeryPriority.trim().isNotEmpty,
          ),
          third: _buildSurgerySummaryCard(
            key: const Key('surgery-surgeon-card'),
            tapKey: const Key('surgery-surgeon-entry'),
            title: '3) Cirurgião',
            icon: Icons.person_outline,
            value: _displayStructuredLineEntries(_record.surgeonName),
            section: SurgeryInfoSection.surgeon,
            isCompleted: _record.surgeonName.trim().isNotEmpty,
          ),
        ),
        const SizedBox(height: 12),
        _buildEqualWidthTripletRow(
          first: _buildSurgerySummaryCard(
            key: const Key('surgery-assistants-card'),
            tapKey: const Key('surgery-assistants-entry'),
            title: '4) Auxiliares',
            icon: Icons.groups_outlined,
            value: _displayListEntries(_record.assistantNames),
            section: SurgeryInfoSection.assistants,
            isCompleted: _record.assistantNames.isNotEmpty,
          ),
          second: _buildSurgerySummaryCard(
            key: const Key('surgery-anesthesiologists-card'),
            tapKey: const Key('surgery-anesthesiologists-entry'),
            title: '5) Anestesiologistas',
            icon: Icons.badge_outlined,
            value: _displayAnesthesiologists,
            onTap: _editAnesthesiologists,
            isCompleted: _anesthesiologistEntries.isNotEmpty,
          ),
          third: _buildSurgerySummaryCard(
            key: const Key('surgery-notes-card'),
            tapKey: const Key('surgery-notes-entry'),
            title: '6) Anotações relevantes',
            icon: Icons.note_alt_outlined,
            value: _multilineSummary(_record.operationalNotes),
            section: SurgeryInfoSection.notes,
            isCompleted: _record.operationalNotes.trim().isNotEmpty,
          ),
        ),
        const SizedBox(height: 12),
        _buildPhaseGroup(
          title: 'Antes De Anestesiar',
          subtitle:
              'Preparação da sala, profilaxia, monitorização, acessos e time-out antes de iniciar a anestesia',
          accent: _preInductionPhaseColor,
          cards: _buildPreInductionCards(),
        ),
        const SizedBox(height: 14),
        _buildPhaseGroup(
          title: 'Anestesia Em Curso',
          subtitle:
              'Técnica, bloqueios, via aérea, ventilação e passos iniciais da anestesia conforme o contexto clínico',
          accent: _inductionPhaseColor,
          cards: _buildInductionAndConductionCards(),
        ),
        const SizedBox(height: 14),
        _buildPhaseGroup(
          title: 'Suporte Intraoperatório',
          subtitle:
              'Manutenção anestésica, vasoativos, medicações, balanço e materiais durante o procedimento',
          accent: _maintenancePhaseColor,
          cards: _buildMaintenanceCards(),
        ),
        const SizedBox(height: 14),
        _buildPhaseGroup(
          title: 'Despertar E Encaminhamento',
          subtitle:
              'Extubação ou saída ventilada, encaminhamento pós-operatório e consolidado final do caso',
          accent: _emergencePhaseColor,
          cards: _buildEmergenceAndDispositionCards(),
        ),
        const SizedBox(height: 14),
        _buildSectionHeader(
          title: 'Registro Intraoperatório',
          subtitle: 'Área principal fixa para condução hemodinâmica e eventos',
          accent: _maintenancePhaseColor,
        ),
        const SizedBox(height: 10),
        _buildChartSection(dominant: true),
      ],
    );
  }

  Widget _buildEqualWidthTripletRow({
    required Widget first,
    required Widget second,
    required Widget third,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - (spacing * 2)) / 3;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: cardWidth, child: first),
              const SizedBox(width: spacing),
              SizedBox(width: cardWidth, child: second),
              const SizedBox(width: spacing),
              SizedBox(width: cardWidth, child: third),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPreInductionCards() {
    return [
      _buildPreparationCard(),
      _buildAntibioticProphylaxisCard(),
      _buildMonitoringCard(),
      _buildVenousAccessCard(),
      _buildArterialAccessCard(),
      _buildTimeOutCard(),
    ];
  }

  List<Widget> _buildInductionAndConductionCards() {
    return [
      if (_showsSedationWorkflowCard) _buildTechniqueCard(),
      if (_showsNeuraxialWorkflowCard) _buildNeuraxialNeedlesCard(),
      if (_showsGeneralWorkflowCards) _buildDrugsCard(),
      _buildAdjunctsCard(),
      if (_showsGeneralWorkflowCards) _buildAirwayCard(),
      if (_showsMechanicalVentilationCard) _buildMechanicalVentilationCard(),
    ];
  }

  List<Widget> _buildMaintenanceCards() {
    return [
      if (_showsGeneralWorkflowCards) _buildMaintenanceCard(),
      _buildVasoactiveDrugsCard(),
      _buildOtherMedicationsCard(),
      _buildVolumeReplacementCard(),
      _buildFluidBalanceCard(),
      _buildAnesthesiaMaterialsCard(),
    ];
  }

  List<Widget> _buildEmergenceAndDispositionCards() {
    return [
      _buildEmergenceCard(),
      _buildSurgerySummaryCard(
        key: const Key('surgery-destination-card'),
        tapKey: const Key('surgery-destination-entry'),
        title: '22) Destino pós-operatório',
        icon: Icons.local_hospital_outlined,
        value: _displayPatientDestination,
        section: SurgeryInfoSection.destination,
        isCompleted: _record.patientDestination.trim().isNotEmpty,
      ),
      _buildUsageSummaryCard(),
    ];
  }

  Widget _buildPhaseGroup({
    required String title,
    required String subtitle,
    required Color accent,
    required List<Widget> cards,
  }) {
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        _buildSectionHeader(title: title, subtitle: subtitle, accent: accent),
        const SizedBox(height: 10),
        _buildOperationalCardGrid(cards),
      ],
    );
  }

  Widget _buildOperationalCardGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth = (constraints.maxWidth - (spacing * 2)) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }

  List<Widget> _withVerticalSpacing(
    List<Widget> widgets, {
    double spacing = 12,
  }) {
    if (widgets.isEmpty) return const [];
    final result = <Widget>[];
    for (var index = 0; index < widgets.length; index++) {
      if (index > 0) result.add(SizedBox(height: spacing));
      result.add(widgets[index]);
    }
    return result;
  }

  // ignore: unused_element
  Widget _buildSurgerySummaryStrip() {
    return _buildEqualWidthTripletRow(
      first: _buildSurgerySummaryCard(
        key: const Key('surgery-description-card'),
        tapKey: const Key('surgery-description-entry'),
        title: 'Cirurgia',
        icon: Icons.content_paste_search_outlined,
        value: _valueOrPlaceholder(_record.surgeryDescription),
        section: SurgeryInfoSection.description,
        isCompleted: _record.surgeryDescription.trim().isNotEmpty,
      ),
      second: _buildSurgerySummaryCard(
        key: const Key('surgery-surgeon-card'),
        tapKey: const Key('surgery-surgeon-entry'),
        title: 'Cirurgião',
        icon: Icons.person_outline,
        value: _displayStructuredLineEntries(_record.surgeonName),
        section: SurgeryInfoSection.surgeon,
        isCompleted: _record.surgeonName.trim().isNotEmpty,
      ),
      third: _buildSurgerySummaryCard(
        key: const Key('surgery-priority-card'),
        tapKey: const Key('surgery-priority-entry'),
        title: 'Prioridade',
        icon: Icons.priority_high_outlined,
        value: _valueOrPlaceholder(_displaySurgeryPriority),
        section: SurgeryInfoSection.priority,
        isCompleted: _displaySurgeryPriority.trim().isNotEmpty,
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSurgeryPlanningStrip() {
    return _buildEqualWidthTripletRow(
      first: _buildSurgerySummaryCard(
        key: const Key('surgery-destination-card'),
        tapKey: const Key('surgery-destination-entry'),
        title: 'Destino pós-op',
        icon: Icons.local_hospital_outlined,
        value: _displayPatientDestination,
        section: SurgeryInfoSection.destination,
        isCompleted: _record.patientDestination.trim().isNotEmpty,
      ),
      second: _buildSurgerySummaryCard(
        key: const Key('surgery-assistants-card'),
        tapKey: const Key('surgery-assistants-entry'),
        title: 'Auxiliares',
        icon: Icons.groups_outlined,
        value: _displayListEntries(_record.assistantNames),
        section: SurgeryInfoSection.assistants,
        isCompleted: _record.assistantNames.isNotEmpty,
      ),
      third: _buildSurgerySummaryCard(
        key: const Key('surgery-anesthesiologists-card'),
        tapKey: const Key('surgery-anesthesiologists-entry'),
        title: 'Anestesiologistas',
        icon: Icons.badge_outlined,
        value: _displayAnesthesiologists,
        onTap: _editAnesthesiologists,
        isCompleted: _anesthesiologistEntries.isNotEmpty,
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSurgeryNotesStrip() {
    return _buildEqualWidthTripletRow(
      first: _buildSurgerySummaryCard(
        key: const Key('surgery-notes-card'),
        tapKey: const Key('surgery-notes-entry'),
        title: 'Chegada ao CC / anotações',
        icon: Icons.note_alt_outlined,
        value: _valueOrPlaceholder(_record.operationalNotes),
        section: SurgeryInfoSection.notes,
        isCompleted: _record.operationalNotes.trim().isNotEmpty,
      ),
      second: _buildTimeOutCard(),
      third: _buildAntibioticProphylaxisCard(),
    );
  }

  Widget _buildMobileOverview() {
    return Column(
      children: [
        _buildSurgerySummaryCard(
          key: const Key('surgery-description-card'),
          tapKey: const Key('surgery-description-entry'),
          title: '1) Cirurgia',
          icon: Icons.content_paste_search_outlined,
          value: _multilineSummary(_record.surgeryDescription),
          section: SurgeryInfoSection.description,
          isCompleted: _record.surgeryDescription.trim().isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildSurgerySummaryCard(
          key: const Key('surgery-priority-card'),
          tapKey: const Key('surgery-priority-entry'),
          title: '2) Tipo de cirurgia',
          icon: Icons.priority_high_outlined,
          value: _valueOrPlaceholder(_displaySurgeryPriority),
          section: SurgeryInfoSection.priority,
          isCompleted: _displaySurgeryPriority.trim().isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildSurgerySummaryCard(
          key: const Key('surgery-surgeon-card'),
          tapKey: const Key('surgery-surgeon-entry'),
          title: '3) Cirurgião',
          icon: Icons.person_outline,
          value: _displayStructuredLineEntries(_record.surgeonName),
          section: SurgeryInfoSection.surgeon,
          isCompleted: _record.surgeonName.trim().isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildSurgerySummaryCard(
          key: const Key('surgery-assistants-card'),
          tapKey: const Key('surgery-assistants-entry'),
          title: '4) Auxiliares',
          icon: Icons.groups_outlined,
          value: _displayListEntries(_record.assistantNames),
          section: SurgeryInfoSection.assistants,
          isCompleted: _record.assistantNames.isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildSurgerySummaryCard(
          key: const Key('surgery-anesthesiologists-card'),
          tapKey: const Key('surgery-anesthesiologists-entry'),
          title: '5) Anestesiologistas',
          icon: Icons.badge_outlined,
          value: _displayAnesthesiologists,
          onTap: _editAnesthesiologists,
          isCompleted: _anesthesiologistEntries.isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildSurgerySummaryCard(
          key: const Key('surgery-notes-card'),
          tapKey: const Key('surgery-notes-entry'),
          title: '6) Anotações relevantes',
          icon: Icons.note_alt_outlined,
          value: _multilineSummary(_record.operationalNotes),
          section: SurgeryInfoSection.notes,
          isCompleted: _record.operationalNotes.trim().isNotEmpty,
        ),
        const SizedBox(height: 12),
        _buildSectionHeader(
          title: 'Antes De Anestesiar',
          subtitle:
              'Checklist inicial, profilaxia, monitorização, acessos e time-out antes do início da anestesia',
          accent: _preInductionPhaseColor,
        ),
        ..._withVerticalSpacing(_buildPreInductionCards()),
        const SizedBox(height: 12),
        _buildSectionHeader(
          title: 'Anestesia Em Curso',
          subtitle:
              'Técnica, bloqueios, via aérea, ventilação e primeiros passos da condução anestésica',
          accent: _inductionPhaseColor,
        ),
        ..._withVerticalSpacing(_buildInductionAndConductionCards()),
        const SizedBox(height: 12),
        _buildSectionHeader(
          title: 'Suporte Intraoperatório',
          subtitle:
              'Manutenção, medicações de suporte, balanço e materiais usados durante o procedimento',
          accent: _maintenancePhaseColor,
        ),
        ..._withVerticalSpacing(_buildMaintenanceCards()),
        const SizedBox(height: 12),
        _buildSectionHeader(
          title: 'Despertar E Encaminhamento',
          subtitle:
              'Extubação ou saída ventilada, destino pós-operatório e consolidado final',
          accent: _emergencePhaseColor,
        ),
        ..._withVerticalSpacing(_buildEmergenceAndDispositionCards()),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    const headerAccent = Color(0xFF7D93AA);
    const backgroundColor = Color(0xFFF5F7FC);
    const borderColor = Color(0xFFBCD0E4);
    const subtitleColor = Color(0xFF6F8498);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 44,
            decoration: BoxDecoration(
              color: headerAccent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF17324D),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirwayCard() {
    final airwaySupport = _buildAirwaySupportRecommendation(_record.patient);
    final airwayHighlights = <String>[
      if (_record.airway.cormackLehane.trim().isNotEmpty)
        'Cormack ${_record.airway.cormackLehane}',
      if (_record.airway.device.trim().isNotEmpty)
        '${_record.airway.device} ${_record.airway.tubeNumber}'.trim(),
      if (_record.airway.technique.trim().isNotEmpty) _record.airway.technique,
      if (_record.airway.observation.trim().isNotEmpty)
        _record.airway.observation,
    ];
    final airwayStatus = airwayHighlights.isEmpty
        ? 'Via aérea pendente'
        : '${airwayHighlights.length} item(ns) preenchido(s)';
    final airwaySummary = airwayHighlights.isEmpty
        ? 'Toque para preencher'
        : airwayHighlights.take(2).join(' • ');

    return KeyedSubtree(
      key: _airwaySectionKey,
      child: Column(
        children: [
          PanelCard(
            key: const Key('airway-card'),
            title: '15) Via aérea',
            titleColor: _airwayFluidRowColor,
            icon: Icons.air,
            minHeight: 286,
            isAttention: _hasPendingAirway,
            isCompleted:
                _record.airway.device.trim().isNotEmpty ||
                _record.airway.technique.trim().isNotEmpty ||
                _record.airway.observation.trim().isNotEmpty ||
                _record.airway.cormackLehane.trim().isNotEmpty,
            collapsedChild: _buildCollapsedPanelSummary(
              status: airwayStatus,
              summary: airwaySummary,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                children: [
                  _buildAirwayInfoCard(
                    key: const Key('airway-cormack-field'),
                    label: 'Cormack-Lehane',
                    value: _record.airway.cormackLehane.trim().isEmpty
                        ? 'Toque para preencher após laringoscopia'
                        : 'Cormack ${_record.airway.cormackLehane}',
                    onTap: () =>
                        _editViaAereaSection(AirwayEditSection.cormack),
                  ),
                  const SizedBox(height: 10),
                  _buildAirwayInfoCard(
                    key: const Key('airway-device-field'),
                    label: 'Dispositivo',
                    value: _record.airway.device.trim().isEmpty
                        ? 'Toque para preencher'
                        : '${_record.airway.device} ${_record.airway.tubeNumber}'
                              .trim(),
                    onTap: () => _editViaAereaSection(AirwayEditSection.device),
                  ),
                  if (airwaySupport != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD7E5F5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            airwaySupport.title,
                            style: const TextStyle(
                              color: Color(0xFF2B76D2),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...airwaySupport.lines.map(
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
                  ],
                  const SizedBox(height: 10),
                  _buildAirwayInfoCard(
                    key: const Key('airway-technique-entry'),
                    label: 'Técnica de intubação',
                    value: _valueOrPlaceholder(_record.airway.technique),
                    onTap: () =>
                        _editViaAereaSection(AirwayEditSection.technique),
                  ),
                  const SizedBox(height: 10),
                  _buildAirwayInfoCard(
                    key: const Key('airway-observation-entry'),
                    label: 'Materiais de apoio',
                    value: _valueOrPlaceholder(_record.airway.observation),
                    onTap: () =>
                        _editViaAereaSection(AirwayEditSection.observation),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _mechanicalVentilationSummarySegments(
    MechanicalVentilationSettings settings,
  ) {
    return [
      if (settings.mode.trim().isNotEmpty) settings.mode.trim(),
      if (settings.tidalVolumeMl.trim().isNotEmpty)
        'VT ${settings.tidalVolumeMl.trim()} mL',
      if (settings.tidalVolumePerKg.trim().isNotEmpty)
        '${settings.tidalVolumePerKg.trim()} mL/kg',
      if (settings.respiratoryRate.trim().isNotEmpty)
        'FR ${settings.respiratoryRate.trim()}',
      if (settings.peep.trim().isNotEmpty) 'PEEP ${settings.peep.trim()}',
      if (settings.fio2Percent.trim().isNotEmpty)
        'FiO₂ ${settings.fio2Percent.trim()}%',
    ];
  }

  Widget _buildMechanicalVentilationCard() {
    final suggestion = _suggestedMechanicalVentilation;
    final settings = _effectiveMechanicalVentilation;
    final summarySegments = _mechanicalVentilationSummarySegments(settings);
    final status = _record.mechanicalVentilation.isEmpty
        ? 'Sugestão: ${suggestion.settings.mode}'
        : settings.mode.trim().isEmpty
        ? 'Ventilação mecânica sem modo definido'
        : settings.mode.trim();
    final summary = summarySegments.isEmpty
        ? 'Registrar modo e parâmetros ventilatórios'
        : summarySegments.take(3).join(' • ');

    return KeyedSubtree(
      key: _ventilationSectionKey,
      child: PanelCard(
        key: const Key('ventilation-card'),
        title: '16) Ventilação mecânica',
        titleColor: _airwayFluidRowColor,
        icon: Icons.air_outlined,
        minHeight: 248,
        isAttention:
            _suggestsControlledVentilation &&
            _record.mechanicalVentilation.isEmpty,
        isCompleted: !_record.mechanicalVentilation.isEmpty,
        collapsedChild: _buildCollapsedPanelSummary(
          status: status,
          summary: summary,
        ),
        trailing: AddButton(
          label: _record.mechanicalVentilation.isEmpty
              ? 'Aplicar plano'
              : 'Editar',
          onTap: _editMechanicalVentilation,
        ),
        child: InkWell(
          key: const Key('ventilation-entry'),
          borderRadius: BorderRadius.circular(18),
          onTap: _editMechanicalVentilation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8E6F4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sugestão contextual',
                      style: TextStyle(
                        color: Color(0xFF17324D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      suggestion.reason,
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  if (settings.mode.trim().isNotEmpty)
                    _detailChip('Modo', settings.mode.trim()),
                  if (settings.tidalVolumeMl.trim().isNotEmpty)
                    _detailChip('VT', '${settings.tidalVolumeMl.trim()} mL'),
                  if (settings.tidalVolumePerKg.trim().isNotEmpty)
                    _detailChip(
                      'VT/kg',
                      '${settings.tidalVolumePerKg.trim()} mL/kg',
                    ),
                  if (settings.respiratoryRate.trim().isNotEmpty)
                    _detailChip('FR', settings.respiratoryRate.trim()),
                  if (settings.peep.trim().isNotEmpty)
                    _detailChip('PEEP', settings.peep.trim()),
                  if (settings.fio2Percent.trim().isNotEmpty)
                    _detailChip('FiO₂', '${settings.fio2Percent.trim()}%'),
                  if (settings.ieRatio.trim().isNotEmpty)
                    _detailChip('I:E', settings.ieRatio.trim()),
                  if (settings.targetEtco2.trim().isNotEmpty)
                    _detailChip('ETCO₂ alvo', settings.targetEtco2.trim()),
                ],
              ),
              if (settings.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  settings.notes.trim(),
                  style: const TextStyle(
                    color: Color(0xFF5D7288),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7F3)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF17324D),
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildVenousAccessCard() {
    final successfulEntries = _venousAccesses
        .where((item) => !_isLossEntry(item))
        .toList();
    final lossEntries = _venousAccesses.where(_isLossEntry).toList();
    final status = _venousAccesses.isEmpty
        ? 'Nenhum acesso venoso registrado'
        : successfulEntries.isNotEmpty
        ? successfulEntries.first
        : _lossEntryLabel(lossEntries.first);
    final summary = _venousAccesses.isEmpty
        ? 'Toque para adicionar'
        : '${successfulEntries.length} acesso(s) válido(s) • ${lossEntries.length} perda(s)';
    return _buildCompactOperationalCard(
      key: const Key('venous-access-card'),
      tapKey: const Key('venous-access-entry'),
      title: '8) Acesso venoso',
      titleColor: _accessRowColor,
      icon: Icons.vaccines_outlined,
      minHeight: 92,
      status: status,
      summary: summary,
      onTap: _editAcessoVenoso,
      isCompleted: _venousAccesses.isNotEmpty,
    );
  }

  Widget _buildArterialAccessCard() {
    final successfulEntries = _arterialAccesses
        .where((item) => !_isLossEntry(item))
        .toList();
    final lossEntries = _arterialAccesses.where(_isLossEntry).toList();
    final status = _arterialAccesses.isEmpty
        ? 'Nenhum acesso arterial registrado'
        : successfulEntries.isNotEmpty
        ? successfulEntries.first
        : _lossEntryLabel(lossEntries.first);
    final summary = _arterialAccesses.isEmpty
        ? 'Toque para adicionar'
        : '${successfulEntries.length} acesso(s) válido(s) • ${lossEntries.length} perda(s)';
    return _buildCompactOperationalCard(
      key: const Key('arterial-access-card'),
      tapKey: const Key('arterial-access-entry'),
      title: '9) Acesso arterial',
      titleColor: _accessRowColor,
      icon: Icons.timeline_outlined,
      minHeight: 92,
      status: status,
      summary: summary,
      onTap: _editAcessoArterial,
      isCompleted: _arterialAccesses.isNotEmpty,
    );
  }

  Widget _buildMonitoringCard() {
    final recommended = _recommendedMonitoringItems(_record.patient);
    final missingRecommended = recommended
        .where((item) => !_monitoringItems.contains(item))
        .toList();
    final customItems = _monitoringItems
        .where((item) => !_monitoringOptions.contains(item))
        .toList();
    final status = _monitoringItems.isEmpty
        ? 'Monitorização pendente'
        : '${_monitoringItems.length} item(ns) selecionados';
    final summary = missingRecommended.isEmpty
        ? _displayListEntries(
            _monitoringItems,
            empty: 'Toque para selecionar a monitorização',
          )
        : 'Sugeridos ausentes: ${missingRecommended.join(', ')}';
    return PanelCard(
      key: const Key('monitoring-card'),
      title: '10) Monitorização',
      titleColor: _accessRowColor,
      icon: Icons.monitor_heart_outlined,
      minHeight: 250,
      isCompleted: _monitoringItems.isNotEmpty,
      collapsedChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _monitoringItems.isEmpty ? 'Toque para preencher' : summary,
            style: const TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._monitoringOptions.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                key: Key('monitoring-item-${entry.key + 1}'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleMonitoringItem(entry.value),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _monitoringItems.contains(entry.value)
                        ? const Color(0xFFEAF2FF)
                        : const Color(0xFFF8FAFE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _monitoringItems.contains(entry.value)
                          ? const Color(0xFF2B76D2)
                          : recommended.contains(entry.value)
                          ? const Color(0xFF9CC0EC)
                          : const Color(0xFFDCE7F3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _monitoringItems.contains(entry.value)
                              ? const Color(0xFF2B76D2)
                              : const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: _monitoringItems.contains(entry.value)
                                ? Colors.white
                                : const Color(0xFF2B76D2),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: recommended.contains(entry.value)
                                ? const Color(0xFF315E8D)
                                : const Color(0xFF17324D),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              OutlinedButton.icon(
                key: const Key('monitoring-other-items-button'),
                onPressed: _editCustomMonitoringItems,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Outros'),
              ),
              if (customItems.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customItems.join(', '),
                    style: const TextStyle(
                      color: Color(0xFF5D7288),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntraoperativeSection() {
    return Column(
      children: [
        _buildSectionHeader(
          title: 'Registro Intraoperatório',
          subtitle: 'Condução hemodinâmica e documentação contínua do caso',
          accent: const Color(0xFF4A5568),
        ),
        const SizedBox(height: 10),
        _buildChartSection(dominant: true),
      ],
    );
  }

  Widget _buildChartSection({required bool dominant}) {
    return HemodynamicChartCard(
      dominant: dominant,
      inlineHemodynamicRemoveMode: _inlineHemodynamicRemoveMode,
      hasAnesthesiaStartMarker: _hasAnesthesiaStartMarker,
      hasSurgeryStartMarker: _hasSurgeryStartMarker,
      inlineHemodynamicType: _inlineHemodynamicType,
      currentInlineTime: _currentHemodynamicElapsedMinutes(),
      anesthesiaElapsed: _formatElapsedFrom(_hemodynamicAnesthesiaStartAt),
      surgeryElapsed: _formatElapsedFrom(_hemodynamicSurgeryStartAt),
      points: _record.hemodynamicPoints,
      markers: _record.hemodynamicMarkers,
      latestFc: _latestFcPoint == null
          ? '--'
          : _latestFcPoint!.value.round().toString(),
      latestBloodPressure: _latestBloodPressure,
      latestPam: _latestPam,
      paiSummary: _paiSummary,
      latestSpo2: _latestSpo2Point == null
          ? '--'
          : _latestSpo2Point!.value.round().toString(),
      onAddAnesthesiaStart: () => _addHemodynamicMarker('Início da anestesia'),
      onAddSurgeryStart: () => _addHemodynamicMarker('Início da cirurgia'),
      onAddAnesthesiaEnd: () => _addHemodynamicMarker('Fim da anestesia'),
      onAddSurgeryEnd: () => _addHemodynamicMarker('Fim da cirurgia'),
      hasAnesthesiaEndMarker: _hasAnesthesiaEndMarker,
      hasSurgeryEndMarker: _hasSurgeryEndMarker,
      onToggleRemoveMode: () {
        setState(() {
          _inlineHemodynamicRemoveMode = !_inlineHemodynamicRemoveMode;
        });
      },
      onSelectType: (type) {
        setState(() => _inlineHemodynamicType = type);
      },
      onQuickSpo2: _addInlineHemodynamicPoint,
      onPointTap: _inlineHemodynamicRemoveMode
          ? _removeInlineHemodynamicPoint
          : null,
      onChartTap: _hasAnesthesiaStartMarker && !_inlineHemodynamicRemoveMode
          ? _addInlineHemodynamicPoint
          : null,
      onPointMoved: _hasAnesthesiaStartMarker && !_inlineHemodynamicRemoveMode
          ? _applyInlineHemodynamicPointMove
          : null,
      onPointDragEnd: _hasAnesthesiaStartMarker && !_inlineHemodynamicRemoveMode
          ? () => _persistRecord()
          : null,
    );
  }

  Widget _buildAirwayInfoCard({
    Key? key,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBFE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE7F3)),
        ),
        child: DetailLine(label: label, value: value),
      ),
    );
  }

  Widget _buildSurgeryCards({required bool desktop}) {
    final cards = [
      _buildSurgerySummaryCard(
        key: const Key('surgery-description-card'),
        tapKey: const Key('surgery-description-entry'),
        title: 'Cirurgia',
        icon: Icons.content_paste_search_outlined,
        value: _multilineSummary(_record.surgeryDescription),
        section: SurgeryInfoSection.description,
        isCompleted: _record.surgeryDescription.trim().isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-surgeon-card'),
        tapKey: const Key('surgery-surgeon-entry'),
        title: 'Cirurgião',
        icon: Icons.person_outline,
        value: _displayStructuredLineEntries(_record.surgeonName),
        section: SurgeryInfoSection.surgeon,
        isCompleted: _record.surgeonName.trim().isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-priority-card'),
        tapKey: const Key('surgery-priority-entry'),
        title: 'Prioridade',
        icon: Icons.priority_high_outlined,
        value: _valueOrPlaceholder(_displaySurgeryPriority),
        section: SurgeryInfoSection.priority,
        isCompleted: _displaySurgeryPriority.trim().isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-assistants-card'),
        tapKey: const Key('surgery-assistants-entry'),
        title: 'Auxiliares',
        icon: Icons.groups_outlined,
        value: _displayListEntries(_record.assistantNames),
        section: SurgeryInfoSection.assistants,
        isCompleted: _record.assistantNames.isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-destination-card'),
        tapKey: const Key('surgery-destination-entry'),
        title: 'Destino pós-op',
        icon: Icons.local_hospital_outlined,
        value: _displayPatientDestination,
        section: SurgeryInfoSection.destination,
        isCompleted: _record.patientDestination.trim().isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-anesthesiologists-card'),
        tapKey: const Key('surgery-anesthesiologists-entry'),
        title: 'Anestesiologistas',
        icon: Icons.badge_outlined,
        value: _displayAnesthesiologists,
        onTap: _editAnesthesiologists,
        isCompleted: _anesthesiologistEntries.isNotEmpty,
      ),
      _buildSurgerySummaryCard(
        key: const Key('surgery-notes-card'),
        tapKey: const Key('surgery-notes-entry'),
        title: 'Chegada ao CC / anotações',
        icon: Icons.note_alt_outlined,
        value: _multilineSummary(_record.operationalNotes),
        section: SurgeryInfoSection.notes,
        isCompleted: _record.operationalNotes.trim().isNotEmpty,
      ),
      _buildTimeOutCard(),
    ];

    if (!desktop) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[3]),
            const SizedBox(width: 12),
            Expanded(child: cards[5]),
            const SizedBox(width: 12),
            Expanded(child: cards[4]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[6]),
            const SizedBox(width: 12),
            Expanded(child: cards[7]),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildSurgerySummaryCard({
    Key? key,
    Key? tapKey,
    required String title,
    required IconData icon,
    required String value,
    SurgeryInfoSection? section,
    VoidCallback? onTap,
    bool isCompleted = false,
  }) {
    final resolvedOnTap =
        onTap ?? (section == null ? null : () => _editSurgerySection(section));
    return InkWell(
      key: tapKey,
      borderRadius: BorderRadius.circular(14),
      onTap: resolvedOnTap,
      child: PanelCard(
        key: key,
        title: title,
        titleColor: _surgeryRowColor,
        icon: icon,
        isCompleted: isCompleted,
        collapsible: false,
        child: SizedBox(
          width: double.infinity,
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactOperationalCard({
    Key? key,
    Key? tapKey,
    required String title,
    required Color titleColor,
    required IconData icon,
    required String status,
    required String summary,
    required VoidCallback onTap,
    Color statusColor = const Color(0xFF17324D),
    bool isAttention = false,
    bool isCompleted = false,
    double minHeight = 92,
  }) {
    return PanelCard(
      key: key,
      title: title,
      titleColor: titleColor,
      icon: icon,
      minHeight: minHeight,
      isAttention: isAttention,
      isCompleted: isCompleted,
      collapsible: false,
      child: InkWell(
        key: tapKey,
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5D7288),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8CA0B5)),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedPanelSummary({
    required String status,
    required String summary,
    Color statusColor = const Color(0xFF17324D),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          status,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          summary,
          style: const TextStyle(
            color: Color(0xFF5D7288),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetActionCard({
    Key? key,
    Key? confirmKey,
    Key? editKey,
    required String title,
    String? badge,
    String? subtitle,
    required String detail,
    required bool selected,
    required Color accentColor,
    required VoidCallback onConfirm,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    String confirmLabel = 'Confirmar',
    String selectedLabel = 'Confirmado',
  }) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? accentColor.withAlpha(16) : const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? accentColor : const Color(0xFFDCE7F3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null || subtitle != null)
            Row(
              children: [
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? accentColor.withAlpha(24)
                          : const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: selected ? accentColor : const Color(0xFF2B76D2),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (badge != null && subtitle != null)
                  const SizedBox(width: 10),
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          if (badge != null || subtitle != null) const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: confirmKey,
                onPressed: onConfirm,
                icon: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.add_task_rounded,
                ),
                label: Text(selected ? selectedLabel : confirmLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
              if (onEdit != null)
                OutlinedButton.icon(
                  key: editKey,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: BorderSide(color: accentColor.withAlpha(140)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return KeyedSubtree(key: key, child: content);
    }

    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: content,
    );
  }

  Widget _buildMaintenancePresetTile(_MaintenancePreset preset) {
    final encodedEntry = _findMaintenanceEntry(preset.name);
    final selected = encodedEntry != null;
    final parts = encodedEntry?.split('|') ?? const <String>[];
    final detail = parts.length > 2 && parts[2].trim().isNotEmpty
        ? parts[2].trim()
        : _maintenancePresetDetails(preset);
    final category = parts.length > 1 && parts[1].trim().isNotEmpty
        ? parts[1].trim()
        : _maintenanceCategoryForPreset(preset);
    return _buildPresetActionCard(
      confirmKey: Key(
        'maintenance-confirm-${preset.name.toLowerCase().replaceAll(' ', '-')}',
      ),
      editKey: Key(
        'maintenance-edit-${preset.name.toLowerCase().replaceAll(' ', '-')}',
      ),
      title: preset.name,
      subtitle: category,
      detail: detail,
      selected: selected,
      accentColor: _medicationsRowColor,
      onConfirm: () => _toggleMaintenancePreset(preset),
      onEdit: () => _editMaintenancePreset(preset),
    );
  }

  List<String> _inhalationalConsumptionSummaries() {
    final summaries = <String>[];
    final elapsedHours = _anesthesiaElapsedHours;
    for (final preset in _maintenancePresets.where(
      (item) => item.isInhalational,
    )) {
      final encodedEntry = _findMaintenanceEntry(preset.name);
      if (encodedEntry == null) continue;
      final mlPerHour = _estimateInhalationalMlPerHour(
        preset,
        freshGasFlowLPerMin: _maintenanceFreshGasFlowFromEntry(
          preset,
          encodedEntry,
        ),
        volumePercent: _maintenanceVolPercentFromEntry(preset, encodedEntry),
      );
      final accumulated = mlPerHour * elapsedHours;
      final hourlyLabel = mlPerHour.toStringAsFixed(1).replaceAll('.', ',');
      final accumulatedLabel = accumulated
          .toStringAsFixed(1)
          .replaceAll('.', ',');
      summaries.add(
        '${preset.name}: $hourlyLabel mL/h${elapsedHours > 0 ? ' • acumulado $accumulatedLabel mL em ${_formatElapsedHoursLabel(elapsedHours)}' : ''}',
      );
    }
    return summaries;
  }

  Widget _buildPreparationCard() {
    final completedCount = _preAnesthesiaChecklistOptions
        .where(_hasPreparationChecklistItem)
        .length;
    final status = completedCount == 0
        ? 'Preparação da sala pendente'
        : completedCount == _preAnesthesiaChecklistOptions.length
        ? 'Checklist pré-anestésico OK'
        : '$completedCount/${_preAnesthesiaChecklistOptions.length} item(ns) confirmados';
    final summary = completedCount == 0
        ? 'Confirme equipamento, intubação, consentimento e avaliação pré-anestésica antes de iniciar.'
        : _preAnesthesiaChecklistOptions
              .where(_hasPreparationChecklistItem)
              .take(2)
              .join(' • ');
    return PanelCard(
      key: const Key('preparation-card'),
      title: 'Checklist pré-anestesia',
      titleColor: _timeoutRowColor,
      icon: Icons.fact_check_outlined,
      minHeight: 240,
      isAttention: completedCount < _preAnesthesiaChecklistOptions.length,
      isCompleted: completedCount == _preAnesthesiaChecklistOptions.length,
      collapsedChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: TextStyle(
              color: completedCount == _preAnesthesiaChecklistOptions.length
                  ? const Color(0xFF169653)
                  : const Color(0xFFF59E0B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key('preparation-entry'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => _editSurgerySection(SurgeryInfoSection.checklist),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color:
                        completedCount == _preAnesthesiaChecklistOptions.length
                        ? const Color(0xFF169653)
                        : const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: const TextStyle(
                    color: Color(0xFF5D7288),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._preAnesthesiaChecklistOptions.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildPresetActionCard(
                key: Key('preparation-item-${entry.key + 1}'),
                title: entry.value,
                badge: '${entry.key + 1}',
                subtitle: 'Checklist antes da anestesia',
                detail: _hasPreparationChecklistItem(entry.value)
                    ? 'OK'
                    : 'Toque em confirmar para registrar este item.',
                selected: _hasPreparationChecklistItem(entry.value),
                accentColor: const Color(0xFF169653),
                onConfirm: () => _togglePreparationChecklistItem(entry.value),
                onTap: () => _togglePreparationChecklistItem(entry.value),
                confirmLabel: 'Confirmar',
                selectedLabel: 'OK',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOutCard() {
    final completed = _record.timeOutCompleted;
    final summary = _record.timeOutChecklist.isEmpty
        ? 'Toque para preencher'
        : '${_record.timeOutChecklist.length} itens confirmados';
    return PanelCard(
      key: const Key('surgery-timeout-card'),
      title: '11) Time-out',
      titleColor: _timeoutRowColor,
      icon: Icons.alarm_on_outlined,
      minHeight: 220,
      isAttention: _hasPendingTimeOut,
      isCompleted: completed,
      collapsedChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            completed ? 'Time-out finalizado' : 'Time-out pendente',
            style: TextStyle(
              color: completed
                  ? const Color(0xFF169653)
                  : const Color(0xFFF59E0B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: const Key('surgery-timeout-entry'),
            borderRadius: BorderRadius.circular(14),
            onTap: () => _editSurgerySection(SurgeryInfoSection.timeOut),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completed ? 'Time-out finalizado' : 'Time-out pendente',
                  style: TextStyle(
                    color: completed
                        ? const Color(0xFF169653)
                        : const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: const TextStyle(
                    color: Color(0xFF5D7288),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._timeOutOptions.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildPresetActionCard(
                key: Key('surgery-timeout-item-${entry.key + 1}'),
                title: entry.value,
                badge: '${entry.key + 1}',
                subtitle: 'Item do checklist de seguranca',
                detail: _record.timeOutChecklist.contains(entry.value)
                    ? 'Item confirmado no time-out.'
                    : 'Toque em confirmar para registrar este item.',
                selected: _record.timeOutChecklist.contains(entry.value),
                accentColor: const Color(0xFF169653),
                onConfirm: () => _toggleTimeOutChecklistItem(entry.value),
                onTap: () => _toggleTimeOutChecklistItem(entry.value),
                confirmLabel: 'Confirmar',
                selectedLabel: 'Confirmado',
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('surgery-complete-timeout-button'),
              onPressed:
                  _record.timeOutChecklist.length == _timeOutOptions.length
                  ? _finalizeTimeOutFromCard
                  : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                completed ? 'Time-out finalizado' : 'Finalizar time-out',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAntibioticProphylaxisCard() {
    final redoseAlerts = _antibioticRedoseAlerts;
    final antibiotics = _record.prophylacticAntibiotics;
    final suggestedScheme = _surgeryBasedAntibioticSuggestions.isEmpty
        ? null
        : _surgeryBasedAntibioticSuggestions.first;
    final status = redoseAlerts.isNotEmpty
        ? '${redoseAlerts.first.name}: ${redoseAlerts.first.message}'
        : antibiotics.isEmpty
        ? suggestedScheme == null
              ? 'Nenhum antibiótico registrado'
              : 'Sugestão: ${suggestedScheme.title}'
        : antibiotics.length == 1
        ? antibiotics.first.split('|').first
        : '${antibiotics.length} antibióticos registrados';
    final summary = redoseAlerts.isNotEmpty
        ? redoseAlerts.first.detail
        : antibiotics.isEmpty
        ? suggestedScheme == null
              ? 'Toque para registrar dose e horário'
              : '${suggestedScheme.medicationName} ${suggestedScheme.dose} • ${suggestedScheme.repeatGuidance}'
        : () {
            final first = antibiotics.first.split('|');
            final dose = _medicationDoseSummary(first);
            final repeat = first.length > 3 ? first[3].trim() : '';
            final time = first.length > 2 && first[2].trim().isNotEmpty
                ? first[2].trim()
                : '--:--';
            final segments = <String>['$dose • $time'];
            if (repeat.isNotEmpty) {
              segments.add(repeat);
            }
            return segments.join(' • ');
          }();
    return _buildCompactOperationalCard(
      key: const Key('antibiotic-entry-card'),
      tapKey: const Key('antibiotic-entry'),
      title: '7) Antibioticoprofilaxia',
      titleColor: _timeoutRowColor,
      icon: Icons.medical_services_outlined,
      minHeight: 92,
      isAttention: redoseAlerts.isNotEmpty,
      status: status,
      statusColor: redoseAlerts.isNotEmpty
          ? (redoseAlerts.first.isOverdue
                ? const Color(0xFFD64545)
                : const Color(0xFFF0A11F))
          : const Color(0xFF17324D),
      summary: summary,
      onTap: _editProphylacticAntibiotics,
      isCompleted: antibiotics.isNotEmpty && redoseAlerts.isEmpty,
    );
  }

  Widget _buildEventsCard() {
    final selectedTechniques = _record.anesthesiaTechnique
        .split('\n')
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final hasTechniques = selectedTechniques.isNotEmpty;
    final hasDetails = _record.anesthesiaTechniqueDetails.trim().isNotEmpty;
    final collapsedStatus = hasTechniques
        ? selectedTechniques.length == 1
              ? selectedTechniques.first
              : '${selectedTechniques.first} +${selectedTechniques.length - 1}'
        : 'Nenhuma técnica selecionada';
    final detailsPreview = _record.anesthesiaTechniqueDetails.trim().replaceAll(
      '\n',
      ' ',
    );
    final collapsedSummary = hasDetails
        ? detailsPreview.length > 88
              ? '${detailsPreview.substring(0, 88).trimRight()}...'
              : detailsPreview
        : 'Use o botão "Editar técnica" para definir a técnica principal e a descrição breve.';
    return KeyedSubtree(
      key: _eventsSectionKey,
      child: PanelCard(
        key: const Key('events-card'),
        title: 'Técnica anestésica',
        titleColor: _techniqueRowColor,
        icon: Icons.description_outlined,
        fillChild: true,
        isAttention: _hasPendingTechnique || _hasPendingTechniqueDetails,
        isCompleted:
            _record.anesthesiaTechnique.trim().isNotEmpty &&
            _record.anesthesiaTechniqueDetails.trim().isNotEmpty,
        collapsedChild: _buildCollapsedPanelSummary(
          status: collapsedStatus,
          summary: collapsedSummary,
          statusColor: hasTechniques
              ? _techniqueRowColor
              : const Color(0xFF7A8EA5),
        ),
        onTap: _editTecnicaAnestesica,
        trailing: AddButton(
          label: 'Editar técnica',
          onTap: _editTecnicaAnestesica,
        ),
        child: SingleChildScrollView(
          key: const Key('events-entry'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasTechniques)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedTechniques
                      .map(
                        (item) => SoftTag(
                          text: item,
                          color: const Color(0xFFF1EAFE),
                          textColor: _techniqueRowColor,
                        ),
                      )
                      .toList(),
                )
              else
                const StatusHint(
                  text:
                      'Nenhuma técnica definida. Use "Editar técnica" para configurar o plano anestésico.',
                ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDE7F3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasDetails
                          ? _record.anesthesiaTechniqueDetails.trim()
                          : 'Resumo ainda não preenchido.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasDetails
                            ? const Color(0xFF17324D)
                            : const Color(0xFF7A8EA5),
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      key: const Key('technique-workflow-summary'),
                      _techniqueWorkflowSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechniqueCard() {
    final status = _record.sedationMedications.isEmpty
        ? 'Nenhuma sedação registrada'
        : _record.sedationMedications.first.split('|').first;
    final summary = _record.sedationMedications.isEmpty
        ? 'Registrar medicações de sedação para anestesia local, bloqueios, raqui e técnicas associadas.'
        : '${_record.sedationMedications.length} medicação(ões) registradas';
    return KeyedSubtree(
      key: _techniqueSectionKey,
      child: _buildCompactOperationalCard(
        key: const Key('technique-card'),
        tapKey: const Key('technique-entry'),
        title: '12) Sedação complementar',
        titleColor: _techniqueRowColor,
        icon: Icons.air_outlined,
        minHeight: 92,
        status: status,
        summary: summary,
        onTap: _editSedationMedications,
        isCompleted: _record.sedationMedications.isNotEmpty,
      ),
    );
  }

  Widget _buildDrugsCard() {
    final status = _record.drugs.isEmpty
        ? 'Nenhuma droga de indução registrada'
        : _record.drugs.first.split('|').first;
    final summary = _record.drugs.isEmpty
        ? 'Toque para registrar indução, doses, infusões e ampolas'
        : '${_record.drugs.length} item(ns) registrados';
    return KeyedSubtree(
      key: _drugsSectionKey,
      child: PanelCard(
        key: const Key('drugs-card'),
        title: '13) Indução',
        titleColor: _techniqueRowColor,
        icon: Icons.medication_outlined,
        minHeight: 320,
        isAttention: _hasPendingDrugs,
        isCompleted: _record.drugs.isNotEmpty,
        collapsedChild: _buildCollapsedPanelSummary(
          status: status,
          summary: _record.drugs.isEmpty ? 'Toque para preencher' : summary,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status,
              style: const TextStyle(
                color: Color(0xFF17324D),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              summary,
              style: const TextStyle(
                color: Color(0xFF5D7288),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._inductionPresets.map((preset) {
              final encodedEntry = _findDrugEntry(preset.name);
              final selected = encodedEntry != null;
              final parts = encodedEntry?.split('|') ?? const <String>[];
              final detail = parts.length > 1 && parts[1].trim().isNotEmpty
                  ? parts[1].trim()
                  : _inductionPresetDose(preset);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildPresetActionCard(
                  title: preset.name,
                  subtitle: preset.category,
                  detail: detail,
                  selected: selected,
                  accentColor: _techniqueRowColor,
                  onConfirm: () => _toggleInductionPreset(preset),
                  onEdit: () => _editInductionPreset(preset),
                ),
              );
            }),
            AddButton(label: 'Edição avançada', onTap: _editDrogasInfusoes),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjunctsCard() {
    final status = _record.adjuncts.isEmpty
        ? 'Nenhum adjuvante registrado'
        : _record.adjuncts.first.split('|').first;
    final summary = _record.adjuncts.isEmpty
        ? 'Toque para registrar adjuvantes e doses'
        : '${_record.adjuncts.length} item(ns) registrados';
    return PanelCard(
      title: '14) Adjuvantes anestésicos',
      titleColor: _techniqueRowColor,
      icon: Icons.auto_awesome_outlined,
      minHeight: 280,
      isCompleted: _record.adjuncts.isNotEmpty,
      collapsedChild: _buildCollapsedPanelSummary(
        status: status,
        summary: _record.adjuncts.isEmpty ? 'Toque para preencher' : summary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: const TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._adjunctPresets.map((preset) {
            final encodedEntry = _findAdjunctEntry(preset.name);
            final selected = encodedEntry != null;
            final parts = encodedEntry?.split('|') ?? const <String>[];
            final detail = parts.length > 1 && parts[1].trim().isNotEmpty
                ? parts[1].trim()
                : _adjunctPresetDose(preset);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildPresetActionCard(
                title: preset.name,
                detail: detail,
                selected: selected,
                accentColor: _techniqueRowColor,
                onConfirm: () => _toggleAdjunctPreset(preset),
                onEdit: () => _editAdjunctPreset(preset),
              ),
            );
          }),
          AddButton(label: 'Edição avançada', onTap: _editAdjuvantes),
        ],
      ),
    );
  }

  Widget _buildOtherMedicationsCard() {
    final status = _record.otherMedications.isEmpty
        ? 'Nenhuma medicação complementar registrada'
        : _record.otherMedications.first.split('|').first;
    final summary = _record.otherMedications.isEmpty
        ? 'Toque para registrar medicações complementares'
        : '${_record.otherMedications.length} item(ns) registrados';
    return KeyedSubtree(
      key: _otherMedicationsSectionKey,
      child: _buildCompactOperationalCard(
        key: const Key('other-medications-card'),
        tapKey: const Key('other-medications-entry'),
        title: '18) Medicações complementares',
        titleColor: _medicationsRowColor,
        icon: Icons.healing_outlined,
        minHeight: 92,
        status: status,
        summary: summary,
        onTap: _editOtherMedications,
        isCompleted: _record.otherMedications.isNotEmpty,
      ),
    );
  }

  Widget _buildNeuraxialNeedlesCard() {
    final successfulEntries = _record.neuraxialNeedles
        .where((item) => !_isLossEntry(item))
        .toList();
    final lossEntries = _record.neuraxialNeedles.where(_isLossEntry).toList();
    final status = _record.neuraxialNeedles.isEmpty
        ? 'Nenhuma agulha neuraxial registrada'
        : successfulEntries.isNotEmpty
        ? successfulEntries.first
        : _lossEntryLabel(lossEntries.first);
    final summary = _record.neuraxialNeedles.isEmpty
        ? (_usesNeuraxialTechnique
              ? 'Relacionar agulhas usadas na raqui/peridural'
              : 'Preencha se houver técnica neuraxial')
        : '${successfulEntries.length} agulha(s) principal(is) • ${lossEntries.length} consumo(s) extra';
    return KeyedSubtree(
      key: _neuraxialNeedlesSectionKey,
      child: _buildCompactOperationalCard(
        key: const Key('neuraxial-needles-card'),
        title: 'Agulhas raqui / peridural',
        titleColor: _airwayFluidRowColor,
        icon: Icons.vaccines_outlined,
        minHeight: 92,
        status: status,
        summary: summary,
        onTap: _editNeuraxialNeedles,
        isAttention:
            _usesNeuraxialTechnique && _record.neuraxialNeedles.isEmpty,
        isCompleted: _record.neuraxialNeedles.isNotEmpty,
      ),
    );
  }

  Widget _buildAnesthesiaMaterialsCard() {
    final displayEntries = _record.anesthesiaMaterials
        .map(_manualMaterialEntryLabel)
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final status = _record.anesthesiaMaterials.isEmpty
        ? 'Nenhum item adicional registrado'
        : displayEntries.first;
    final summary = _record.anesthesiaMaterials.isEmpty
        ? 'Use este campo apenas para itens adicionais ou ajustes manuais que nao apareceram automaticamente no consolidado'
        : '${_record.anesthesiaMaterials.length} item(ns) registrados';
    return KeyedSubtree(
      key: _materialsSectionKey,
      child: _buildCompactOperationalCard(
        key: const Key('materials-card'),
        tapKey: const Key('materials-entry'),
        title: 'Itens adicionais / ajuste manual',
        titleColor: _medicationsRowColor,
        icon: Icons.inventory_2_outlined,
        minHeight: 92,
        status: status,
        summary: summary,
        onTap: _editAnesthesiaMaterials,
        isCompleted: _record.anesthesiaMaterials.isNotEmpty,
      ),
    );
  }

  String _usageNormalizedName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áàâãéèêíïóôõöúç]+'), ' ')
        .trim();
  }

  String _usageItemKey(String group, String name) {
    final normalizedGroup = group.toLowerCase().trim();
    final normalizedName = _usageNormalizedName(name);
    return '$normalizedGroup|$normalizedName';
  }

  bool _isLossEntry(String entry) => _isEncodedLossEntry(entry);

  _LossEntry? _decodeLossEntry(String entry) => _decodeEncodedLossEntry(entry);

  String _lossEntryLabel(String entry) => _formatLossEntryLabel(entry);

  bool _isOxygenTherapyEntry(String entry) =>
      _isEncodedOxygenTherapyEntry(entry);

  _OxygenTherapyEntry? _decodeOxygenTherapyEntry(String entry) =>
      _decodeEncodedOxygenTherapyEntry(entry);

  String _manualMaterialEntryLabel(String entry) {
    if (_isLossEntry(entry)) return _lossEntryLabel(entry);
    if (_isOxygenTherapyEntry(entry)) {
      return _formatOxygenTherapyEntryLabel(entry);
    }
    return entry.trim();
  }

  void _addUsageItem(
    Map<String, _UsageSummaryItem> items,
    _UsageSummaryItem item,
  ) {
    if (item.group == 'Ajuste manual') {
      final normalizedName = _usageNormalizedName(item.name);
      final alreadyTracked = items.values.any((current) {
        final currentName = _usageNormalizedName(current.name);
        return currentName == normalizedName ||
            currentName.startsWith(normalizedName) ||
            normalizedName.startsWith(currentName);
      });
      if (alreadyTracked) return;
    }
    final key = _usageItemKey(item.group, item.name);
    final current = items[key];
    if (current == null) {
      items[key] = item;
      return;
    }
    final currentHasQuantity = current.quantity.trim().isNotEmpty;
    final nextHasQuantity = item.quantity.trim().isNotEmpty;
    if (!currentHasQuantity && nextHasQuantity) {
      items[key] = item;
      return;
    }
    if (currentHasQuantity == nextHasQuantity &&
        item.priority > current.priority) {
      items[key] = item;
    }
  }

  List<_UsageSummaryItem> _usageItemsFromMedicationEntries(
    String group,
    List<String> entries, {
    int priority = 10,
  }) {
    return entries.where((entry) => entry.trim().isNotEmpty).map((entry) {
      final parts = entry.split('|');
      final name = parts.isNotEmpty ? parts.first.trim() : entry.trim();
      final quantity = parts.length > 4 ? parts[4].trim() : '';
      final note = quantity.isEmpty ? 'quantidade não informada' : '';
      return _UsageSummaryItem(
        group: group,
        name: name,
        quantity: quantity,
        note: note,
        priority: priority,
      );
    }).toList();
  }

  List<_UsageSummaryItem> _usageItemsFromPlainEntries(
    String group,
    List<String> entries, {
    String quantity = '1 un',
    int priority = 20,
  }) {
    return entries
        .map((entry) => entry.trim())
        .where(
          (entry) =>
              entry.isNotEmpty &&
              !_isLossEntry(entry) &&
              !_isOxygenTherapyEntry(entry),
        )
        .map(
          (entry) => _UsageSummaryItem(
            group: group,
            name: entry,
            quantity: quantity,
            priority: priority,
          ),
        )
        .toList();
  }

  List<_UsageSummaryItem> _usageItemsFromNeuraxialNeedles() {
    return _record.neuraxialNeedles
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty && !_isLossEntry(entry))
        .map(
          (entry) => _UsageSummaryItem(
            group: 'Agulhas neuraxiais',
            name: entry,
            quantity: '1 un',
            priority: 20,
          ),
        )
        .toList();
  }

  List<_UsageSummaryItem> _usageItemsFromLossEntries(
    String group,
    List<String> entries, {
    int priority = 90,
  }) {
    return entries
        .map(_decodeLossEntry)
        .whereType<_LossEntry>()
        .map(
          (entry) => _UsageSummaryItem(
            group: group,
            name: entry.material,
            quantity: entry.quantity,
            note: entry.reason,
            priority: priority,
          ),
        )
        .toList();
  }

  List<_UsageSummaryItem> _usageItemsFromFluidEntries(
    String group,
    List<String> entries, {
    int priority = 15,
  }) {
    return entries.where((entry) => entry.trim().isNotEmpty).map((entry) {
      final parts = entry.split('|').map((item) => item.trim()).toList();
      final name = parts.isNotEmpty ? parts[0] : entry.trim();
      final quantity = parts.length > 2
          ? '${parts[1]} • ${parts[2]} mL'
          : parts.length > 1
          ? '${parts[1]} mL'
          : '';
      return _UsageSummaryItem(
        group: group,
        name: name,
        quantity: quantity,
        note: quantity.isEmpty ? 'quantidade não informada' : '',
        priority: priority,
      );
    }).toList();
  }

  List<_UsageSummaryItem> _usageItemsFromAirway() {
    final items = <_UsageSummaryItem>[];
    final device = _record.airway.device.trim();
    final tubeNumber = _record.airway.tubeNumber.trim();
    if (device.isNotEmpty) {
      final label = tubeNumber.isEmpty ? device : '$device $tubeNumber';
      items.add(
        _UsageSummaryItem(
          group: 'Via aérea',
          name: label,
          quantity: '1 un',
          priority: 25,
        ),
      );
    }
    return items;
  }

  List<_UsageSummaryItem> _usageItemsFromManualMaterials() {
    return _record.anesthesiaMaterials
        .map((entry) => entry.trim())
        .where(
          (entry) =>
              entry.isNotEmpty &&
              !_isLossEntry(entry) &&
              !_isOxygenTherapyEntry(entry),
        )
        .map(
          (entry) => _UsageSummaryItem(
            group: 'Ajuste manual',
            name: entry,
            priority: 100,
          ),
        )
        .toList();
  }

  List<_UsageSummaryItem> _usageItemsFromManualOxygenTherapy() {
    return _record.anesthesiaMaterials
        .map(_decodeOxygenTherapyEntry)
        .whereType<_OxygenTherapyEntry>()
        .map(
          (entry) => _UsageSummaryItem(
            group: 'Oxigenoterapia',
            name: _oxygenTherapyDeviceLabel(entry.device),
            quantity: '${_formatLitersLabel(entry.totalLiters)} L',
            note:
                '${_formatFlowLabel(entry.flowLPerMin)} L/min • ${_formatDurationMinutesLabel(entry.minutes)}',
            priority: 18,
          ),
        )
        .toList();
  }

  List<_UsageSummaryItem> _usageItemsFromMaintenanceGasFlows() {
    final elapsedHours = _anesthesiaElapsedHours;
    final elapsedMinutes = elapsedHours * 60;
    final oxygenNotes = <String>[];
    final compressedAirNotes = <String>[];
    final nitrousOxideNotes = <String>[];
    double oxygenTotalLiters = 0;
    double compressedAirTotalLiters = 0;
    double nitrousOxideTotalLiters = 0;

    for (final preset in _maintenancePresets.where(
      (item) => item.isInhalational,
    )) {
      final encodedEntry = _findMaintenanceEntry(preset.name);
      if (encodedEntry == null) continue;

      final oxygenFlow = _maintenanceOxygenFlowFromEntry(preset, encodedEntry);
      final compressedAirFlow = _maintenanceCompressedAirFlowFromEntry(
        preset,
        encodedEntry,
      );
      final nitrousOxideFlow = _maintenanceNitrousOxideFlowFromEntry(
        preset,
        encodedEntry,
      );

      void addGasUsage({
        required double flowLPerMin,
        required List<String> notes,
        required void Function(double liters) addToTotal,
        required String source,
      }) {
        if (flowLPerMin <= 0) return;
        final flowLabel = _formatFlowLabel(flowLPerMin);
        if (elapsedMinutes > 0) {
          final liters = flowLPerMin * elapsedMinutes;
          addToTotal(liters);
          notes.add(
            '$source $flowLabel L/min • ${_formatElapsedHoursLabel(elapsedHours)}',
          );
          return;
        }
        notes.add('$source $flowLabel L/min • tempo anestésico não informado');
      }

      addGasUsage(
        flowLPerMin: oxygenFlow,
        notes: oxygenNotes,
        addToTotal: (liters) => oxygenTotalLiters += liters,
        source: '${preset.name} (O₂)',
      );
      addGasUsage(
        flowLPerMin: compressedAirFlow,
        notes: compressedAirNotes,
        addToTotal: (liters) => compressedAirTotalLiters += liters,
        source: '${preset.name} (ar)',
      );
      addGasUsage(
        flowLPerMin: nitrousOxideFlow,
        notes: nitrousOxideNotes,
        addToTotal: (liters) => nitrousOxideTotalLiters += liters,
        source: '${preset.name} (N₂O)',
      );
    }

    _UsageSummaryItem? buildGasItem({
      required String name,
      required double liters,
      required List<String> notes,
    }) {
      if (liters <= 0 && notes.isEmpty) return null;
      return _UsageSummaryItem(
        group: 'Gases medicinais',
        name: name,
        quantity: liters > 0 ? '${_formatLitersLabel(liters)} L' : '',
        note: notes.join(' • '),
        priority: 17,
      );
    }

    return [
      buildGasItem(
        name: 'Oxigênio (O₂)',
        liters: oxygenTotalLiters,
        notes: oxygenNotes,
      ),
      buildGasItem(
        name: 'Ar comprimido',
        liters: compressedAirTotalLiters,
        notes: compressedAirNotes,
      ),
      buildGasItem(
        name: 'Óxido nitroso (N₂O)',
        liters: nitrousOxideTotalLiters,
        notes: nitrousOxideNotes,
      ),
    ].whereType<_UsageSummaryItem>().toList();
  }

  List<_UsageSummaryItem> _buildUsageSummaryItems() {
    final items = <String, _UsageSummaryItem>{};
    final collected = <_UsageSummaryItem>[
      ..._usageItemsFromMedicationEntries('Indução', _record.drugs),
      ..._usageItemsFromMedicationEntries('Adjuvantes', _record.adjuncts),
      ..._usageItemsFromMedicationEntries(
        'Manutenção',
        _lineItems(_record.maintenanceAgents),
      ),
      ..._usageItemsFromMedicationEntries(
        'Sedação',
        _record.sedationMedications,
      ),
      ..._usageItemsFromMedicationEntries(
        'Outras medicações',
        _record.otherMedications,
      ),
      ..._usageItemsFromMedicationEntries(
        'Vasoativas',
        _record.vasoactiveDrugs,
      ),
      ..._usageItemsFromAirway(),
      ..._usageItemsFromPlainEntries('Acesso venoso', _record.venousAccesses),
      ..._usageItemsFromLossEntries(
        'Perda de material',
        _record.venousAccesses,
      ),
      ..._usageItemsFromPlainEntries(
        'Acesso arterial',
        _record.arterialAccesses,
      ),
      ..._usageItemsFromLossEntries(
        'Perda de material',
        _record.arterialAccesses,
      ),
      ..._usageItemsFromNeuraxialNeedles(),
      ..._usageItemsFromLossEntries(
        'Consumo extra neuraxial',
        _record.neuraxialNeedles,
      ),
      ..._usageItemsFromFluidEntries(
        'Cristaloides',
        _record.fluidBalance.crystalloidEntries,
      ),
      ..._usageItemsFromFluidEntries(
        'Coloides',
        _record.fluidBalance.colloidEntries,
      ),
      ..._usageItemsFromFluidEntries(
        'Sangue e derivados',
        _record.fluidBalance.bloodEntries,
      ),
      ..._usageItemsFromMaintenanceGasFlows(),
      ..._usageItemsFromManualOxygenTherapy(),
      ..._usageItemsFromManualMaterials(),
    ];
    for (final item in collected) {
      _addUsageItem(items, item);
    }
    final result = items.values.toList();
    result.sort((a, b) {
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;
      final groupCompare = a.group.compareTo(b.group);
      if (groupCompare != 0) return groupCompare;
      return a.name.compareTo(b.name);
    });
    return result;
  }

  Widget _buildUsageSummaryCard() {
    final summary = _buildUsageSummaryItems();

    return PanelCard(
      title: 'Consolidado de uso',
      titleColor: _emergencePhaseColor,
      icon: Icons.summarize_outlined,
      minHeight: 168,
      isCompleted: summary.isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: summary.isEmpty
            ? const [
                StatusHint(
                  text:
                      'O consolidado é montado automaticamente com drogas, manutenção, via aérea, acessos, agulhas, fluidos e itens adicionais.',
                ),
              ]
            : summary
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: CheckLine(
                        text:
                            '${item.group}: ${item.name}'
                            '${item.quantity.trim().isNotEmpty ? ' • ${item.quantity.trim()}' : ''}'
                            '${item.note.trim().isNotEmpty ? ' • ${item.note.trim()}' : ''}',
                      ),
                    ),
                  )
                  .toList(),
      ),
    );
  }

  Widget _buildVasoactiveDrugsCard() {
    final status = _record.vasoactiveDrugs.isEmpty
        ? 'Nenhuma droga vasoativa registrada'
        : _record.vasoactiveDrugs.first.split('|').first;
    final summary = _record.vasoactiveDrugs.isEmpty
        ? 'Toque para registrar bolus, infusão contínua e ampolas'
        : '${_record.vasoactiveDrugs.length} item(ns) registrados';
    return KeyedSubtree(
      key: _vasoactiveSectionKey,
      child: _buildCompactOperationalCard(
        key: const Key('vasoactive-card'),
        tapKey: const Key('vasoactive-entry'),
        title: '19) Drogas vasoativas',
        titleColor: _medicationsRowColor,
        icon: Icons.show_chart_outlined,
        minHeight: 92,
        status: status,
        summary: summary,
        onTap: _editVasoactiveDrugs,
        isCompleted: _record.vasoactiveDrugs.isNotEmpty,
      ),
    );
  }

  Widget _buildFluidBalanceCard() {
    final documentedInputs = _documentedInputsMl;
    final documentedLosses = _documentedLossesMl;
    final spongeEstimatedLoss = _record.fluidBalance.estimatedSpongeLoss;
    final status = _record.fluidBalance.isComplete
        ? 'Balanço hídrico preenchido'
        : 'Balanço hídrico pendente';
    final summary = documentedInputs == 0 && documentedLosses == 0
        ? 'Toque para preencher'
        : 'Entradas ${documentedInputs.toStringAsFixed(0)} mL • Saídas ${documentedLosses.toStringAsFixed(0)} mL';
    return KeyedSubtree(
      key: _fluidSectionKey,
      child: PanelCard(
        key: const Key('fluid-balance-card'),
        title: '21) Balanço hídrico',
        titleColor: _airwayFluidRowColor,
        icon: Icons.opacity_outlined,
        minHeight: 286,
        isAttention: _hasPendingFluidBalance,
        isCompleted: _record.fluidBalance.isComplete,
        collapsedChild: _buildCollapsedPanelSummary(
          status: status,
          summary: summary,
        ),
        child: InkWell(
          key: const Key('fluid-balance-entry'),
          borderRadius: BorderRadius.circular(18),
          onTap: _editBalancoHidrico,
          child: Column(
            children: [
              KeyValueLine(
                label: 'Entradas',
                value: '${documentedInputs.toStringAsFixed(0)} mL',
              ),
              const Divider(height: 18),
              KeyValueLine(
                label: 'Saídas',
                value: '${documentedLosses.toStringAsFixed(0)} mL',
              ),
              const Divider(height: 18),
              KeyValueLine(
                label: 'Diurese',
                value: _record.fluidBalance.diuresis.trim().isEmpty
                    ? '--'
                    : '${_record.fluidBalance.diuresis} mL',
              ),
              const Divider(height: 18),
              KeyValueLine(
                label: 'Sangramento',
                value:
                    (_record.fluidBalance.bleeding.trim().isEmpty &&
                        _record.fluidBalance.bloodLossEntries.isEmpty)
                    ? '--'
                    : '${(_parseFluidField(_record.fluidBalance.bleeding) + _sumFluidEntries(_record.fluidBalance.bloodLossEntries)).toStringAsFixed(0)} mL',
              ),
              const Divider(height: 18),
              KeyValueLine(
                label: 'Compressas',
                value: _record.fluidBalance.spongeCount.trim().isEmpty
                    ? '--'
                    : '${_record.fluidBalance.spongeCount} un • ${spongeEstimatedLoss.toStringAsFixed(0)} mL',
              ),
              const Divider(height: 18),
              KeyValueLine(
                label: 'Outras perdas',
                value:
                    (_record.fluidBalance.otherLosses.trim().isEmpty &&
                        _record.fluidBalance.otherLossEntries.isEmpty)
                    ? '--'
                    : '${(_parseFluidField(_record.fluidBalance.otherLosses) + _sumFluidEntries(_record.fluidBalance.otherLossEntries)).toStringAsFixed(0)} mL',
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F8EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: KeyValueLine(
                  label: 'Balanço total',
                  value: _record.fluidBalance.isComplete
                      ? _record.fluidBalance.formattedBalance
                      : '--',
                  labelColor: const Color(0xFF169653),
                  valueColor: const Color(0xFF169653),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeReplacementCard() {
    final recommendation = _buildFluidSupportRecommendation(
      patient: _record.patient,
      documentedLossesMl: _documentedLossesMl,
      fastingHoursText: _displayFastingHours,
      surgicalSize: _record.surgicalSize.trim().isEmpty
          ? _inferSurgicalSizeFromDescription()
          : _record.surgicalSize,
    );
    final hasReplacementData =
        _record.fluidBalance.blood.trim().isNotEmpty ||
        _record.fluidBalance.colloids.trim().isNotEmpty ||
        _record.fluidBalance.crystalloids.trim().isNotEmpty;
    final replacementSegments = <String>[
      if (_record.fluidBalance.crystalloids.trim().isNotEmpty)
        'Cristaloides ${_record.fluidBalance.crystalloids} mL',
      if (_record.fluidBalance.colloids.trim().isNotEmpty)
        'Coloides ${_record.fluidBalance.colloids} mL',
      if (_record.fluidBalance.blood.trim().isNotEmpty)
        'Sangue ${_record.fluidBalance.blood} mL',
    ];

    return PanelCard(
      title: '20) Reposição volêmica, sangue e derivados',
      titleColor: _airwayFluidRowColor,
      icon: Icons.bloodtype_outlined,
      minHeight: 286,
      isCompleted: hasReplacementData,
      collapsedChild: _buildCollapsedPanelSummary(
        status: hasReplacementData
            ? 'Reposição registrada'
            : 'Nenhuma reposição registrada',
        summary: hasReplacementData
            ? replacementSegments.join(' • ')
            : 'Toque para preencher',
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _editReposicaoVolemica,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD7E5F5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: const TextStyle(
                      color: Color(0xFF2B76D2),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...recommendation.lines.map(
                    (line) => Text(
                      line,
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            KeyValueLine(
              label: 'Porte cirúrgico',
              value: _record.surgicalSize.trim().isEmpty
                  ? _inferSurgicalSizeFromDescription()
                  : _record.surgicalSize,
            ),
            const Divider(height: 18),
            KeyValueLine(
              label: 'Sangue / hemoderivados',
              value: _record.fluidBalance.bloodEntries.isEmpty
                  ? (_record.fluidBalance.blood.trim().isEmpty
                        ? '--'
                        : '${_record.fluidBalance.blood} mL')
                  : '${_record.fluidBalance.bloodEntries.length} item(ns) • ${_record.fluidBalance.blood} mL',
            ),
            const Divider(height: 18),
            KeyValueLine(
              label: 'Coloides',
              value: _record.fluidBalance.colloids.trim().isEmpty
                  ? '--'
                  : '${_record.fluidBalance.colloids} mL',
            ),
            const Divider(height: 18),
            KeyValueLine(
              label: 'Cristaloides',
              value: _record.fluidBalance.crystalloids.trim().isEmpty
                  ? '--'
                  : '${_record.fluidBalance.crystalloids} mL',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergenceCard() {
    final status = _record.emergenceStatus.trim().isEmpty
        ? 'Saída da anestesia pendente'
        : _record.emergenceStatus.trim();
    final summary = _record.emergenceNotes.trim().isEmpty
        ? 'Registrar reversão, aspiração, extubação ou encaminhamento ventilado conforme o desfecho.'
        : _record.emergenceNotes.trim();
    return _buildCompactOperationalCard(
      key: const Key('emergence-card'),
      tapKey: const Key('emergence-entry'),
      title: 'Despertar / extubação',
      titleColor: _emergencePhaseColor,
      icon: Icons.logout_outlined,
      minHeight: 92,
      status: status,
      summary: summary,
      onTap: _editEmergence,
      isCompleted:
          _record.emergenceStatus.trim().isNotEmpty ||
          _record.emergenceNotes.trim().isNotEmpty,
    );
  }

  Widget _buildMaintenanceCard() {
    final categories = _maintenancePresets
        .map(_maintenanceCategoryForPreset)
        .toSet()
        .toList();
    final maintenanceItems = _lineItems(_record.maintenanceAgents);
    final inhalationalSummaries = _inhalationalConsumptionSummaries();
    final maintenanceStatus = maintenanceItems.isEmpty
        ? 'Nenhum agente de manutenção registrado'
        : maintenanceItems.first.split('|').first.trim();
    final maintenanceSummary = maintenanceItems.isEmpty
        ? 'Toque para preencher'
        : '${maintenanceItems.length} item(ns) registrados';
    return PanelCard(
      key: const Key('maintenance-card'),
      title: '17) Manutenção da anestesia',
      titleColor: _medicationsRowColor,
      icon: Icons.tune_outlined,
      minHeight: 320,
      isCompleted: _record.maintenanceAgents.trim().isNotEmpty,
      collapsedChild: _buildCollapsedPanelSummary(
        status: maintenanceStatus,
        summary: maintenanceSummary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...categories.map((category) {
            final items = _maintenancePresets
                .where(
                  (item) => _maintenanceCategoryForPreset(item) == category,
                )
                .toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      color: Color(0xFF17324D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildMaintenancePresetTile(item),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Text(
            'Nos inalatórios, o consumo em mL/h é recalculado conforme a concentração vol% e o FGF informados no editor.',
            style: TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (inhalationalSummaries.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCE7F3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consumo estimado do vaporizador',
                    style: TextStyle(
                      color: Color(0xFF17324D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...inhalationalSummaries.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFF5D7288),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          AddButton(label: 'Edição avançada', onTap: _editMaintenanceAgents),
        ],
      ),
    );
  }
}

class _EmergenceDialog extends StatefulWidget {
  const _EmergenceDialog({
    required this.initialStatus,
    required this.initialNotes,
    required this.patientDestination,
  });

  final String initialStatus;
  final String initialNotes;
  final String patientDestination;

  @override
  State<_EmergenceDialog> createState() => _EmergenceDialogState();
}

class _EmergenceDialogState extends State<_EmergenceDialog> {
  static const List<String> _statusOptions = [
    'Extubado em sala',
    'Mantido intubado para UTI',
    'Mantido em dispositivo supraglótico / máscara',
    'Sem via aérea avançada',
  ];
  static const List<String> _noteOptions = [
    'Desperto',
    'Ventilando espontaneamente',
    'Sem broncoespasmo',
    'Secreções aspiradas',
    'Hemodinamicamente estável',
    'TOF > 0,9',
  ];

  late String _selectedStatus;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _statusOptions.contains(widget.initialStatus)
        ? widget.initialStatus
        : '';
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleNoteOption(String option) {
    final lines = _notesController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.contains(option)) {
      lines.remove(option);
    } else {
      lines.add(option);
    }
    _notesController.text = lines.join('\n');
    _notesController.selection = TextSelection.collapsed(
      offset: _notesController.text.length,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedNoteLines = _notesController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toSet();

    return AlertDialog(
      title: const Text('Despertar / extubação'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Desfecho imediato da via aérea / extubação',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              SelectionGridSection(
                options: _statusOptions,
                searchEnabled: false,
                isSelected: (option) => _selectedStatus == option,
                onToggle: (option) {
                  setState(() {
                    _selectedStatus = _selectedStatus == option ? '' : option;
                  });
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Achados pós-extubação',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SelectionGridSection(
                options: _noteOptions,
                searchEnabled: false,
                isSelected: (option) => selectedNoteLines.contains(option),
                onToggle: _toggleNoteOption,
              ),
              const SizedBox(height: 14),
              if (widget.patientDestination.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD7E5F5)),
                  ),
                  child: Text(
                    'Destino planejado: ${widget.patientDestination}',
                    style: const TextStyle(
                      color: Color(0xFF2B76D2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (widget.patientDestination.trim().isNotEmpty)
                const SizedBox(height: 14),
              TextField(
                key: const Key('emergence-notes-field'),
                controller: _notesController,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Observações complementares',
                  hintText:
                      'Ex: critérios específicos, intercorrências, destino final, necessidade de suporte ou condutas adicionais.',
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
          key: const Key('emergence-save-button'),
          onPressed: () => Navigator.of(context).pop(
            _EmergenceDialogResult(
              status: _selectedStatus,
              notes: _notesController.text.trim(),
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class MechanicalVentilationDialog extends StatefulWidget {
  const MechanicalVentilationDialog({
    super.key,
    required this.initialSettings,
    required this.suggestedSettings,
    required this.suggestionReason,
    required this.population,
  });

  final MechanicalVentilationSettings initialSettings;
  final MechanicalVentilationSettings suggestedSettings;
  final String suggestionReason;
  final PatientPopulation population;

  @override
  State<MechanicalVentilationDialog> createState() =>
      _MechanicalVentilationDialogState();
}

class _MechanicalVentilationDialogState
    extends State<MechanicalVentilationDialog> {
  static const List<String> _targetEtco2Options = [
    '35-40',
    '30-35',
    '40-45',
    'Conforme necessidade',
  ];

  late final TextEditingController _modeController;
  late final TextEditingController _fio2Controller;
  late final TextEditingController _tidalVolumeMlController;
  late final TextEditingController _tidalVolumePerKgController;
  late final TextEditingController _respiratoryRateController;
  late final TextEditingController _peepController;
  late final TextEditingController _inspiratoryPressureController;
  late final TextEditingController _pressureSupportController;
  late final TextEditingController _ieRatioController;
  late final TextEditingController _targetEtco2Controller;
  late final TextEditingController _notesController;

  List<String> get _modeSuggestions {
    switch (widget.population) {
      case PatientPopulation.adult:
        return const ['VCV', 'PCV', 'PCV-VG', 'PSV/CPAP'];
      case PatientPopulation.pediatric:
        return const ['PCV', 'PCV-VG', 'VCV', 'PSV/CPAP'];
      case PatientPopulation.neonatal:
        return const ['PCV', 'VCV', 'PSV/CPAP'];
    }
  }

  @override
  void initState() {
    super.initState();
    _modeController = TextEditingController(text: widget.initialSettings.mode);
    _fio2Controller = TextEditingController(
      text: widget.initialSettings.fio2Percent,
    );
    _tidalVolumeMlController = TextEditingController(
      text: widget.initialSettings.tidalVolumeMl,
    );
    _tidalVolumePerKgController = TextEditingController(
      text: widget.initialSettings.tidalVolumePerKg,
    );
    _respiratoryRateController = TextEditingController(
      text: widget.initialSettings.respiratoryRate,
    );
    _peepController = TextEditingController(text: widget.initialSettings.peep);
    _inspiratoryPressureController = TextEditingController(
      text: widget.initialSettings.inspiratoryPressure,
    );
    _pressureSupportController = TextEditingController(
      text: widget.initialSettings.pressureSupport,
    );
    _ieRatioController = TextEditingController(
      text: widget.initialSettings.ieRatio,
    );
    _targetEtco2Controller = TextEditingController(
      text: widget.initialSettings.targetEtco2,
    );
    _notesController = TextEditingController(
      text: widget.initialSettings.notes,
    );
  }

  @override
  void dispose() {
    _modeController.dispose();
    _fio2Controller.dispose();
    _tidalVolumeMlController.dispose();
    _tidalVolumePerKgController.dispose();
    _respiratoryRateController.dispose();
    _peepController.dispose();
    _inspiratoryPressureController.dispose();
    _pressureSupportController.dispose();
    _ieRatioController.dispose();
    _targetEtco2Controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applySuggestedSettings() {
    final suggested = widget.suggestedSettings;
    setState(() {
      _modeController.text = suggested.mode;
      _fio2Controller.text = suggested.fio2Percent;
      _tidalVolumeMlController.text = suggested.tidalVolumeMl;
      _tidalVolumePerKgController.text = suggested.tidalVolumePerKg;
      _respiratoryRateController.text = suggested.respiratoryRate;
      _peepController.text = suggested.peep;
      _inspiratoryPressureController.text = suggested.inspiratoryPressure;
      _pressureSupportController.text = suggested.pressureSupport;
      _ieRatioController.text = suggested.ieRatio;
      _targetEtco2Controller.text = suggested.targetEtco2;
      _notesController.text = suggested.notes;
    });
  }

  MechanicalVentilationSettings _buildResult() {
    return MechanicalVentilationSettings(
      mode: _modeController.text.trim(),
      fio2Percent: _fio2Controller.text.trim(),
      tidalVolumeMl: _tidalVolumeMlController.text.trim(),
      tidalVolumePerKg: _tidalVolumePerKgController.text.trim(),
      respiratoryRate: _respiratoryRateController.text.trim(),
      peep: _peepController.text.trim(),
      inspiratoryPressure: _inspiratoryPressureController.text.trim(),
      pressureSupport: _pressureSupportController.text.trim(),
      ieRatio: _ieRatioController.text.trim(),
      targetEtco2: _targetEtco2Controller.text.trim(),
      notes: _notesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ventilação mecânica'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8E6F4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plano sugerido',
                      style: TextStyle(
                        color: Color(0xFF17324D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.suggestionReason,
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      key: const Key('ventilation-apply-suggestion'),
                      onPressed: _applySuggestedSettings,
                      icon: const Icon(Icons.auto_fix_high_outlined),
                      label: const Text('Aplicar sugestão'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Modos mais usados em anestesia',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              SelectionGridSection(
                options: _modeSuggestions,
                searchEnabled: false,
                isSelected: (mode) => _modeController.text.trim() == mode,
                onToggle: (mode) {
                  setState(() {
                    _modeController.text = _modeController.text.trim() == mode
                        ? ''
                        : mode;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('ventilation-mode-field'),
                controller: _modeController,
                decoration: const InputDecoration(
                  labelText: 'Modo ventilatório',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('ventilation-fio2-field'),
                      controller: _fio2Controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'FiO₂ (%)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('ventilation-peep-field'),
                      controller: _peepController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'PEEP (cmH₂O)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('ventilation-tidal-volume-ml-field'),
                      controller: _tidalVolumeMlController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'VT (mL)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('ventilation-tidal-volume-kg-field'),
                      controller: _tidalVolumePerKgController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'VT (mL/kg)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('ventilation-rr-field'),
                      controller: _respiratoryRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'FR (irpm)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('ventilation-ie-field'),
                      controller: _ieRatioController,
                      decoration: const InputDecoration(labelText: 'I:E'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('ventilation-pinsp-field'),
                      controller: _inspiratoryPressureController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'P inspiratória (cmH₂O)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('ventilation-ps-field'),
                      controller: _pressureSupportController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'PS (cmH₂O)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Meta de ETCO₂',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              SelectionGridSection(
                options: _targetEtco2Options,
                searchEnabled: false,
                isSelected: (option) =>
                    _targetEtco2Controller.text.trim() == option,
                onToggle: (option) {
                  setState(() => _targetEtco2Controller.text = option);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('ventilation-etco2-field'),
                controller: _targetEtco2Controller,
                decoration: const InputDecoration(
                  labelText: 'ETCO₂ alvo',
                  hintText: 'Ex: 35-40',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('ventilation-notes-field'),
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observações / estratégia',
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
          onPressed: () => Navigator.of(
            context,
          ).pop(const MechanicalVentilationSettings.empty()),
          child: const Text('Limpar'),
        ),
        FilledButton(
          key: const Key('ventilation-save-button'),
          onPressed: () => Navigator.of(context).pop(_buildResult()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _AntibioticRedoseAlert {
  const _AntibioticRedoseAlert({
    required this.name,
    required this.message,
    required this.detail,
    required this.isOverdue,
  });

  final String name;
  final String message;
  final String detail;
  final bool isOverdue;
}

class HemodynamicDialog extends StatefulWidget {
  const HemodynamicDialog({
    super.key,
    required this.initialPoints,
    required this.initialMarkers,
  });

  final List<HemodynamicPoint> initialPoints;
  final List<HemodynamicMarker> initialMarkers;

  @override
  State<HemodynamicDialog> createState() => _HemodynamicDialogState();
}

class HemodynamicDialogResult {
  const HemodynamicDialogResult({required this.points, required this.markers});

  final List<HemodynamicPoint> points;
  final List<HemodynamicMarker> markers;
}

class _HemodynamicDialogState extends State<HemodynamicDialog> {
  static const List<String> _types = ['PAS', 'PAD', 'FC', 'SpO2'];

  late List<HemodynamicPoint> _points;
  late List<HemodynamicMarker> _markers;
  late double _currentTime;
  late double _measurementTime;
  late String _selectedType;
  bool _removeMode = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _points = List<HemodynamicPoint>.from(widget.initialPoints)
      ..sort((a, b) => a.time.compareTo(b.time));
    _markers = List<HemodynamicMarker>.from(widget.initialMarkers)
      ..sort((a, b) => a.time.compareTo(b.time));
    _currentTime = _computeElapsedMinutes();
    _measurementTime = _currentTime;
    _selectedType = 'PAS';
    _startTickerIfNeeded();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  double get _maxTime {
    final double pointMax = _points.isEmpty
        ? 0
        : _points.map((item) => item.time).reduce((a, b) => a > b ? a : b);
    final double markerMax = _markers.isEmpty
        ? 0
        : _markers.map((item) => item.time).reduce((a, b) => a > b ? a : b);
    return pointMax > markerMax ? pointMax : markerMax;
  }

  HemodynamicMarker? get _anesthesiaStartMarker {
    try {
      return _markers.firstWhere((item) => item.label == 'Início da anestesia');
    } catch (_) {
      return null;
    }
  }

  HemodynamicMarker? get _surgeryStartMarker {
    try {
      return _markers.firstWhere((item) => item.label == 'Início da cirurgia');
    } catch (_) {
      return null;
    }
  }

  bool get _hasSurgeryEndMarker =>
      _markers.any((item) => item.label == 'Fim da cirurgia');

  bool get _hasAnesthesiaEndMarker =>
      _markers.any((item) => item.label == 'Fim da anestesia');

  DateTime? get _anesthesiaStartAt {
    final marker = _anesthesiaStartMarker;
    if (marker == null || marker.recordedAtIso.trim().isEmpty) return null;
    return DateTime.tryParse(marker.recordedAtIso);
  }

  void _startTickerIfNeeded() {
    _ticker?.cancel();
    if (_anesthesiaStartAt == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentTime = _computeElapsedMinutes();
        if (_points.isEmpty) {
          _measurementTime = _currentTime;
        }
      });
    });
  }

  double _computeElapsedMinutes() {
    final startedAt = _anesthesiaStartAt;
    if (startedAt == null) return _maxTime <= 0 ? 0 : _maxTime;
    final now = DateTime.now();
    final minutes = now.difference(startedAt).inSeconds / 60;
    return minutes < 0 ? 0 : minutes;
  }

  String _formatClock(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _addPointAtValue(double value) {
    setState(() {
      _points.add(
        HemodynamicPoint(
          type: _selectedType,
          value: value,
          time: _measurementTime,
        ),
      );
      _points.sort((a, b) => a.time.compareTo(b.time));
    });
  }

  void _undoLastPoint() {
    if (_points.isEmpty) return;
    setState(() {
      _points.removeLast();
    });
  }

  void _removePoint(HemodynamicPoint point) {
    setState(() {
      _points.remove(point);
    });
  }

  void _addMarker(String label) {
    final now = DateTime.now();
    setState(() {
      if (label == 'Início da anestesia') {
        _markers.removeWhere((item) => item.label == label);
        _markers.add(
          HemodynamicMarker(
            label: label,
            time: 0,
            clockTime: _formatClock(now),
            recordedAtIso: now.toIso8601String(),
          ),
        );
        _currentTime = 0;
        _measurementTime = 0;
      } else {
        _markers.removeWhere((item) => item.label == label);
        _markers.add(
          HemodynamicMarker(
            label: label,
            time: _measurementTime,
            clockTime: _formatClock(now),
            recordedAtIso: now.toIso8601String(),
          ),
        );
      }
      _markers.sort((a, b) => a.time.compareTo(b.time));
    });
    _startTickerIfNeeded();
  }

  String _formatTime(double time) {
    final totalSeconds = (time * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _captureMeasurementTime() {
    setState(() {
      _measurementTime = _currentTime;
    });
  }

  Future<void> _selectHemodynamicType() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Parâmetro hemodinâmico',
        options: _types,
        initialValue: _selectedType,
        optionLabelBuilder: (option) => option == 'SpO2' ? 'Sat' : option,
      ),
    );

    if (result == null) return;
    setState(() => _selectedType = result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lançamentos hemodinâmicos'),
      content: SizedBox(
        width: 820,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 440,
                child: HemodynamicChart(
                  points: _points,
                  markers: _markers,
                  selectedType: _selectedType,
                  onPointTap: _removeMode ? _removePoint : null,
                  onChartTap: _anesthesiaStartMarker == null
                      ? null
                      : _addPointAtValue,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _anesthesiaStartMarker == null
                              ? 'Início da anestesia ainda não registrado'
                              : 'Tempo decorrido: ${_formatTime(_currentTime)}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _anesthesiaStartMarker == null
                              ? 'Clique em "Início da anestesia" para começar o cronômetro.'
                              : 'Horário do início: ${_anesthesiaStartMarker!.clockTime}  •  Aferição atual: ${_formatTime(_measurementTime)}',
                          style: const TextStyle(
                            color: Color(0xFF5D7288),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_anesthesiaStartMarker != null)
                          const SizedBox(height: 8),
                        if (_anesthesiaStartMarker != null)
                          OutlinedButton.icon(
                            onPressed: _captureMeasurementTime,
                            icon: const Icon(Icons.schedule),
                            label: const Text('Nova aferição neste tempo'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 190,
                    child: OutlinedButton.icon(
                      onPressed: _selectHemodynamicType,
                      icon: const Icon(Icons.tune),
                      label: Text(
                        _selectedType == 'SpO2'
                            ? 'Parâmetro: Sat'
                            : 'Parâmetro: $_selectedType',
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _anesthesiaStartMarker == null
                        ? () => _addMarker('Início da anestesia')
                        : null,
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Início da anestesia'),
                  ),
                  FilledButton.icon(
                    onPressed:
                        _anesthesiaStartMarker == null ||
                            _surgeryStartMarker != null
                        ? null
                        : () => _addMarker('Início da cirurgia'),
                    icon: const Icon(Icons.flag),
                    label: const Text('Início da cirurgia'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        _surgeryStartMarker == null || _hasSurgeryEndMarker
                        ? null
                        : () => _addMarker('Fim da cirurgia'),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Fim da cirurgia'),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        _anesthesiaStartMarker == null ||
                            _hasAnesthesiaEndMarker
                        ? null
                        : () => _addMarker('Fim da anestesia'),
                    icon: const Icon(Icons.stop_circle),
                    label: const Text('Fim da anestesia'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _points.isEmpty ? null : _undoLastPoint,
                    icon: const Icon(Icons.undo),
                    label: const Text('Desfazer'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _points.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _removeMode = !_removeMode;
                            });
                          },
                    icon: Icon(
                      _removeMode ? Icons.delete_forever : Icons.delete_outline,
                    ),
                    label: Text(
                      _removeMode ? 'Removendo pontos' : 'Remover ponto',
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _removeMode
                      ? 'Modo remoção ativo: clique em um ponto para apagá-lo.'
                      : 'Selecione PAS, PAD, FC ou SpO₂ e clique na altura desejada do gráfico. Os quatro parâmetros podem ser lançados na mesma aferição e no mesmo tempo.',
                  style: const TextStyle(
                    color: Color(0xFF7A8EA5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(HemodynamicDialogResult(points: _points, markers: _markers)),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class VenousAccessDialog extends StatefulWidget {
  const VenousAccessDialog({super.key, required this.initialItems});

  final List<String> initialItems;

  @override
  State<VenousAccessDialog> createState() => _VenousAccessDialogState();
}

class _VenousAccessDialogState extends State<VenousAccessDialog> {
  static const List<String> _avpSizes = ['24', '22', '20', '18', '16', '14'];
  static const List<String> _centralOptions = [
    'CVC SCD',
    'CVC SCE',
    'CVC JID',
    'CVC JIE',
    'CVC AXILAR D',
    'CVC AXILAR E',
    'CVC Femural D',
    'CVC Femural E',
  ];

  late List<String> _items;
  late List<String> _lossEntries;
  String _selectedAvpSize = '';
  String _selectedCentral = '';
  late final TextEditingController _avpSiteController;
  late final TextEditingController _lossMaterialController;
  late final TextEditingController _lossQuantityController;
  late final TextEditingController _lossReasonController;

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems
        .where((item) => !_isEncodedLossEntry(item))
        .toList();
    _lossEntries = widget.initialItems.where(_isEncodedLossEntry).toList();
    _avpSiteController = TextEditingController();
    _lossMaterialController = TextEditingController();
    _lossQuantityController = TextEditingController();
    _lossReasonController = TextEditingController();
  }

  @override
  void dispose() {
    _avpSiteController.dispose();
    _lossMaterialController.dispose();
    _lossQuantityController.dispose();
    _lossReasonController.dispose();
    super.dispose();
  }

  void _addAvp() {
    final site = _avpSiteController.text.trim();
    if (site.isEmpty || _selectedAvpSize.isEmpty) return;
    setState(() {
      _items.add('AVP $site - ${_selectedAvpSize}G');
      _avpSiteController.clear();
      _selectedAvpSize = '';
    });
  }

  void _addCentral() {
    if (_selectedCentral.isEmpty) return;
    setState(() {
      _items.add(_selectedCentral);
      _selectedCentral = '';
    });
  }

  void _addLossEntry() {
    final material = _lossMaterialController.text.trim();
    final quantity = _lossQuantityController.text.trim();
    final reason = _lossReasonController.text.trim();
    if (material.isEmpty || quantity.isEmpty || reason.isEmpty) return;
    setState(() {
      _lossEntries.add(
        _encodeLossEntry(
          material: material,
          quantity: quantity,
          reason: reason,
        ),
      );
      _lossMaterialController.clear();
      _lossQuantityController.clear();
      _lossReasonController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9FBFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Editar Acesso venoso'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AVP',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _avpSiteController,
                decoration: const InputDecoration(
                  labelText: 'Local do acesso periférico',
                ),
              ),
              const SizedBox(height: 10),
              SelectionGridSection(
                options: _avpSizes,
                searchEnabled: false,
                isSelected: (size) => _selectedAvpSize == size,
                onToggle: (size) {
                  setState(() {
                    _selectedAvpSize = _selectedAvpSize == size ? '' : size;
                  });
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _addAvp,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar AVP'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'CVC',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              SelectionGridSection(
                options: _centralOptions,
                searchEnabled: true,
                isSelected: (item) => _selectedCentral == item,
                onToggle: (item) {
                  setState(() {
                    _selectedCentral = _selectedCentral == item ? '' : item;
                  });
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _addCentral,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar CVC'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Perda de material / múltiplas tentativas / justificativa',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _lossMaterialController,
                decoration: const InputDecoration(
                  labelText: 'Material',
                  hintText: 'Ex: AVP mse - 20G; CVC JID',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _lossQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  hintText: 'Ex: 2 un; 3 tentativas',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _lossReasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Justificativa',
                  hintText:
                      'Ex: punção sem sucesso; perda de acesso; troca por infiltração',
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _addLossEntry,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar perda/consumo'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Acessos lançados',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (_items.isEmpty)
                const Text(
                  'Nenhum acesso venoso lançado.',
                  style: TextStyle(color: Color(0xFF7A8EA5)),
                ),
              ..._items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCE7F3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              color: Color(0xFF17324D),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _items.removeAt(entry.key));
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_lossEntries.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Perdas e consumos extras',
                  style: TextStyle(
                    color: Color(0xFF17324D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ..._lossEntries.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCE7F3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatLossEntryLabel(entry.value),
                              style: const TextStyle(
                                color: Color(0xFF17324D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _lossEntries.removeAt(entry.key));
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
          onPressed: () =>
              Navigator.of(context).pop([..._items, ..._lossEntries]),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class ArterialAccessDialog extends StatefulWidget {
  const ArterialAccessDialog({super.key, required this.initialItems});

  final List<String> initialItems;

  @override
  State<ArterialAccessDialog> createState() => _ArterialAccessDialogState();
}

class _ArterialAccessDialogState extends State<ArterialAccessDialog> {
  late List<String> _items;
  late List<String> _lossEntries;
  bool _paiSelected = true;
  late final TextEditingController _descriptionController;
  late final TextEditingController _lossMaterialController;
  late final TextEditingController _lossQuantityController;
  late final TextEditingController _lossReasonController;

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems
        .where((item) => !_isEncodedLossEntry(item))
        .toList();
    _lossEntries = widget.initialItems.where(_isEncodedLossEntry).toList();
    _descriptionController = TextEditingController();
    _lossMaterialController = TextEditingController();
    _lossQuantityController = TextEditingController();
    _lossReasonController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _lossMaterialController.dispose();
    _lossQuantityController.dispose();
    _lossReasonController.dispose();
    super.dispose();
  }

  void _addArterialAccess() {
    final description = _descriptionController.text.trim();
    if (!_paiSelected || description.isEmpty) return;
    setState(() {
      _items.add('PAI - $description');
      _descriptionController.clear();
    });
  }

  void _addLossEntry() {
    final material = _lossMaterialController.text.trim();
    final quantity = _lossQuantityController.text.trim();
    final reason = _lossReasonController.text.trim();
    if (material.isEmpty || quantity.isEmpty || reason.isEmpty) return;
    setState(() {
      _lossEntries.add(
        _encodeLossEntry(
          material: material,
          quantity: quantity,
          reason: reason,
        ),
      );
      _lossMaterialController.clear();
      _lossQuantityController.clear();
      _lossReasonController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9FBFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Editar Acesso arterial'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectionGridSection(
                options: const ['PAI'],
                searchEnabled: false,
                isSelected: (item) => _paiSelected,
                onToggle: (item) {
                  setState(() => _paiSelected = !_paiSelected);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Dispositivo / local',
                  hintText: 'Ex: radial esquerda 20G',
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _addArterialAccess,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar PAI'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Perda de material / múltiplas tentativas / justificativa',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _lossMaterialController,
                decoration: const InputDecoration(
                  labelText: 'Material',
                  hintText: 'Ex: PAI radial esquerda 20G',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _lossQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  hintText: 'Ex: 2 un; 3 tentativas',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _lossReasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Justificativa',
                  hintText: 'Ex: sem refluxo; trombose; troca por disfunção',
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _addLossEntry,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar perda/consumo'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Acessos lançados',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (_items.isEmpty)
                const Text(
                  'Nenhum acesso arterial lançado.',
                  style: TextStyle(color: Color(0xFF7A8EA5)),
                ),
              ..._items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCE7F3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              color: Color(0xFF17324D),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _items.removeAt(entry.key));
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_lossEntries.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Perdas e consumos extras',
                  style: TextStyle(
                    color: Color(0xFF17324D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ..._lossEntries.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDCE7F3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatLossEntryLabel(entry.value),
                              style: const TextStyle(
                                color: Color(0xFF17324D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() => _lossEntries.removeAt(entry.key));
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
          onPressed: () =>
              Navigator.of(context).pop([..._items, ..._lossEntries]),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class NeuraxialNeedlesDialog extends StatefulWidget {
  const NeuraxialNeedlesDialog({super.key, required this.initialItems});

  final List<String> initialItems;

  @override
  State<NeuraxialNeedlesDialog> createState() => _NeuraxialNeedlesDialogState();
}

class _NeuraxialNeedlesDialogState extends State<NeuraxialNeedlesDialog> {
  static const List<String> _spinalNeedles = [
    'Quincke 25G',
    'Quincke 26G',
    'Quincke 27G',
    'Whitacre 25G',
    'Whitacre 27G',
  ];
  static const List<String> _epiduralNeedles = [
    'Tuohy 16G',
    'Tuohy 17G',
    'Tuohy 18G',
    'Cateter peridural 19G',
    'Cateter peridural 20G',
  ];

  late Set<String> _selectedMainItems;
  late List<String> _extraEntries;
  late final TextEditingController _otherMainController;
  late final TextEditingController _extraMaterialController;
  late final TextEditingController _extraQuantityController;
  late final TextEditingController _extraReasonController;

  @override
  void initState() {
    super.initState();
    final presetItems = {..._spinalNeedles, ..._epiduralNeedles};
    _selectedMainItems = widget.initialItems
        .where((item) => presetItems.contains(item.trim()))
        .map((item) => item.trim())
        .toSet();
    _extraEntries = widget.initialItems
        .where((item) => !presetItems.contains(item.trim()))
        .where((item) => item.trim().isNotEmpty)
        .toList();
    _otherMainController = TextEditingController();
    _extraMaterialController = TextEditingController();
    _extraQuantityController = TextEditingController();
    _extraReasonController = TextEditingController();
  }

  @override
  void dispose() {
    _otherMainController.dispose();
    _extraMaterialController.dispose();
    _extraQuantityController.dispose();
    _extraReasonController.dispose();
    super.dispose();
  }

  void _addOtherMainItem() {
    final lines = _otherMainController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    setState(() {
      _extraEntries.addAll(lines);
      _otherMainController.clear();
    });
  }

  void _addExtraUsage() {
    final material = _extraMaterialController.text.trim();
    final quantity = _extraQuantityController.text.trim();
    final reason = _extraReasonController.text.trim();
    if (material.isEmpty || quantity.isEmpty || reason.isEmpty) return;
    setState(() {
      _extraEntries.add(
        _encodeLossEntry(
          material: material,
          quantity: quantity,
          reason: reason,
        ),
      );
      _extraMaterialController.clear();
      _extraQuantityController.clear();
      _extraReasonController.clear();
    });
  }

  String _displayExtraEntry(String entry) {
    return _formatLossEntryLabel(entry, prefix: 'Consumo extra');
  }

  Future<void> _editPresetNeedles({
    required String title,
    required List<String> options,
  }) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => ListFieldDialog(
        title: title,
        label: 'Outros itens',
        initialItems: _selectedMainItems.where(options.contains).toList(),
        suggestions: options,
      ),
    );

    if (result == null) return;
    setState(() {
      _selectedMainItems.removeWhere(options.contains);
      _selectedMainItems.addAll(result.where(options.contains));
      _extraEntries.addAll(result.where((item) => !options.contains(item)));
    });
  }

  String _presetSummary(List<String> options) {
    final selected = _selectedMainItems.where(options.contains).toList();
    if (selected.isEmpty) return 'Nenhum item selecionado';
    if (selected.length <= 2) return selected.join(' • ');
    return '${selected.take(2).join(' • ')} +${selected.length - 2}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF3F6FC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      title: const Text('Agulhas para raqui / peridural'),
      content: SizedBox(
        width: 1120,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Raqui',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _editPresetNeedles(
                    title: 'Agulhas para raqui',
                    options: _spinalNeedles,
                  ),
                  icon: const Icon(Icons.vaccines_outlined),
                  label: Text(_presetSummary(_spinalNeedles)),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Peridural',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _editPresetNeedles(
                    title: 'Agulhas para peridural',
                    options: _epiduralNeedles,
                  ),
                  icon: const Icon(Icons.medical_services_outlined),
                  label: Text(_presetSummary(_epiduralNeedles)),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _otherMainController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Outras agulhas / materiais neuraxiais',
                  hintText: 'Ex: Sprotte 24G; conjunto CSE; introdutor 20G',
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _addOtherMainItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar item'),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Uso de mais de uma / perda de material com justificativa',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('neuraxial-extra-material-field'),
                controller: _extraMaterialController,
                decoration: const InputDecoration(
                  labelText: 'Material',
                  hintText: 'Ex: Quincke 27G; Tuohy 18G',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('neuraxial-extra-quantity-field'),
                controller: _extraQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade usada',
                  hintText: 'Ex: 2 un',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('neuraxial-extra-reason-field'),
                controller: _extraReasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Justificativa',
                  hintText:
                      'Ex: segunda punção por bloqueio insuficiente; troca por deformação',
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  key: const Key('neuraxial-extra-add-button'),
                  onPressed: _addExtraUsage,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar consumo extra'),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedMainItems.isEmpty && _extraEntries.isEmpty)
                const Text(
                  'Nenhuma agulha neuraxial registrada.',
                  style: TextStyle(color: Color(0xFF7A8EA5)),
                ),
              ..._selectedMainItems.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCE7F3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry,
                            style: const TextStyle(
                              color: Color(0xFF17324D),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _selectedMainItems.remove(entry));
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ..._extraEntries.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDCE7F3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayExtraEntry(entry.value),
                            style: const TextStyle(
                              color: Color(0xFF17324D),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _extraEntries.removeAt(entry.key));
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(const <String>[]),
          child: const Text('Limpar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop([
            ..._selectedMainItems,
            ..._extraEntries,
            ..._otherMainController.text
                .split('\n')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty),
          ]),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class FluidBalanceDialog extends StatefulWidget {
  const FluidBalanceDialog({
    super.key,
    required this.initialFluidBalance,
    required this.initialSurgicalSize,
    required this.suggestedSurgicalSize,
    required this.initialFastingHours,
    required this.patientWeightKg,
    required this.patientHeightMeters,
    required this.patientPopulation,
    required this.patientAgeYears,
    required this.patientPostnatalAgeDays,
    required this.patientGestationalAgeWeeks,
    required this.patientBirthWeightKg,
    required this.anesthesiaElapsedHours,
  });

  final FluidBalance initialFluidBalance;
  final String initialSurgicalSize;
  final String suggestedSurgicalSize;
  final String initialFastingHours;
  final double patientWeightKg;
  final double patientHeightMeters;
  final PatientPopulation patientPopulation;
  final int patientAgeYears;
  final int patientPostnatalAgeDays;
  final int patientGestationalAgeWeeks;
  final double patientBirthWeightKg;
  final double anesthesiaElapsedHours;

  @override
  State<FluidBalanceDialog> createState() => _FluidBalanceDialogState();
}

class _FluidBalanceDialogState extends State<FluidBalanceDialog> {
  static const List<String> _commonVolumes = [
    '0',
    '250',
    '500',
    '1000',
    '1500',
    '2000',
  ];
  static const List<String> _surgicalSizes = ['Pequeno', 'Medio', 'Grande'];
  static const List<_CrystalloidOption> _crystalloidOptions = [
    _CrystalloidOption('RL', 500),
    _CrystalloidOption('SF 0,9%', 500),
    _CrystalloidOption('Plasma-Lyte', 500),
    _CrystalloidOption('RL', 1000),
  ];
  static const List<_CrystalloidOption> _colloidOptions = [
    _CrystalloidOption('Albumina 5%', 100),
    _CrystalloidOption('Albumina 5%', 250),
    _CrystalloidOption('Albumina 20%', 100),
  ];
  static const List<_BloodComponentOption> _bloodComponentOptions = [
    _BloodComponentOption('Concentrado de hemácias', 'UI', 280),
    _BloodComponentOption('Plasma fresco congelado', 'UI', 270),
    _BloodComponentOption('Plaquetas', 'UI', 270),
    _BloodComponentOption('Crioprecipitado (pool)', 'UI', 175),
  ];

  late final TextEditingController _crystalloidsController;
  late final TextEditingController _colloidsController;
  late final TextEditingController _bloodController;
  late final TextEditingController _fastingHoursController;
  late String _selectedSurgicalSize;
  late List<String> _crystalloidEntries;
  late List<String> _colloidEntries;
  late List<String> _bloodEntries;

  @override
  void initState() {
    super.initState();
    _crystalloidsController = TextEditingController(
      text: widget.initialFluidBalance.crystalloids,
    )..addListener(_onChange);
    _colloidsController = TextEditingController(
      text: widget.initialFluidBalance.colloids,
    )..addListener(_onChange);
    _bloodController = TextEditingController(
      text: widget.initialFluidBalance.blood,
    )..addListener(_onChange);
    _fastingHoursController = TextEditingController(
      text: widget.initialFastingHours,
    )..addListener(_onChange);
    _selectedSurgicalSize = widget.initialSurgicalSize.trim().isNotEmpty
        ? widget.initialSurgicalSize
        : widget.suggestedSurgicalSize;
    _crystalloidEntries = List<String>.from(
      widget.initialFluidBalance.crystalloidEntries,
    );
    _colloidEntries = List<String>.from(
      widget.initialFluidBalance.colloidEntries,
    );
    _bloodEntries = List<String>.from(widget.initialFluidBalance.bloodEntries);
    if (_bloodEntries.isEmpty &&
        widget.initialFluidBalance.blood.trim().isNotEmpty) {
      _bloodEntries = ['Sangue|${widget.initialFluidBalance.blood}|mL'];
    }
  }

  @override
  void dispose() {
    _crystalloidsController
      ..removeListener(_onChange)
      ..dispose();
    _colloidsController
      ..removeListener(_onChange)
      ..dispose();
    _bloodController
      ..removeListener(_onChange)
      ..dispose();
    _fastingHoursController
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  void _onChange() {
    setState(() {});
  }

  double _parse(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  double _parsedFastingHours() {
    final raw = _fastingHoursController.text
        .replaceAll('>', '')
        .replaceAll('<', '')
        .replaceAll('h', '')
        .replaceAll('H', '')
        .trim();
    return _parse(raw);
  }

  double get _referenceWeightKg {
    return switch (widget.patientPopulation) {
      PatientPopulation.adult => _adultReferenceWeightKg(
        actualWeightKg: widget.patientWeightKg,
        heightMeters: widget.patientHeightMeters,
      ),
      PatientPopulation.pediatric => widget.patientWeightKg,
      PatientPopulation.neonatal =>
        widget.patientWeightKg > 0
            ? widget.patientWeightKg
            : widget.patientBirthWeightKg,
    };
  }

  double get _maintenanceSuggestedMlPerHour {
    return switch (widget.patientPopulation) {
      PatientPopulation.adult => (_referenceWeightKg * 27.5) / 24,
      PatientPopulation.pediatric => _pediatricMaintenanceRateMlPerHour(
        widget.patientWeightKg,
      ),
      PatientPopulation.neonatal =>
        widget.patientWeightKg > 0
            ? widget.patientWeightKg * 5
            : widget.patientBirthWeightKg * 5,
    };
  }

  double get _intraoperativeSuggestedMlPerHour {
    return switch (widget.patientPopulation) {
      PatientPopulation.adult => 0,
      PatientPopulation.pediatric =>
        _referenceWeightKg *
            switch (_selectedSurgicalSize) {
              'Pequeno' => 2.0,
              'Medio' => 4.0,
              'Grande' => 6.0,
              _ => 0.0,
            },
      PatientPopulation.neonatal =>
        _referenceWeightKg *
            switch (_selectedSurgicalSize) {
              'Pequeno' => 4.0,
              'Medio' => 6.0,
              'Grande' => 8.0,
              _ => 0.0,
            },
    };
  }

  double get _fastingSuggestedMl {
    if (widget.patientPopulation == PatientPopulation.adult) return 0;
    final hours = _parsedFastingHours();
    if (hours <= 0) return 0;
    return _maintenanceSuggestedMlPerHour * hours;
  }

  double get _suggestedHourlyReferenceHours =>
      widget.anesthesiaElapsedHours > 0 ? widget.anesthesiaElapsedHours : 1;

  double get _intraoperativeSuggestedMl =>
      _intraoperativeSuggestedMlPerHour * _suggestedHourlyReferenceHours;

  void _addToController(TextEditingController controller, double amount) {
    final current = _parse(controller.text);
    final next = current + amount;
    controller.text = next.toStringAsFixed(
      next.truncateToDouble() == next ? 0 : 1,
    );
  }

  void _addFluidEntry({
    required List<String> target,
    required TextEditingController controller,
    required String label,
    required int volumeMl,
  }) {
    setState(() {
      target.add('$label|$volumeMl');
      _addToController(controller, volumeMl.toDouble());
    });
  }

  void _addBloodComponentEntry(_BloodComponentOption option) {
    setState(() {
      _bloodEntries.add(
        '${option.label}|1 ${option.unitLabel}|${option.averageVolumeMl}',
      );
      _addToController(_bloodController, option.averageVolumeMl.toDouble());
    });
  }

  void _removeBloodEntry(int index) {
    final parts = _bloodEntries[index].split('|');
    final volume = parts.length > 2 ? _parse(parts[2]) : 0;
    setState(() {
      _bloodEntries.removeAt(index);
      final current = _parse(_bloodController.text);
      final next = (current - volume).clamp(0, double.infinity);
      _bloodController.text = next.toStringAsFixed(
        next.truncateToDouble() == next ? 0 : 1,
      );
    });
  }

  void _removeFluidEntry({
    required List<String> target,
    required TextEditingController controller,
    required int index,
  }) {
    final entry = target[index].split('|');
    final volume = entry.length > 1 ? _parse(entry[1]) : 0;
    setState(() {
      target.removeAt(index);
      final current = _parse(controller.text);
      final next = (current - volume).clamp(0, double.infinity);
      controller.text = next.toStringAsFixed(
        next.truncateToDouble() == next ? 0 : 1,
      );
    });
  }

  void _applySuggestedCrystalloid(double amount) {
    if (amount <= 0) return;
    setState(() {
      _addToController(_crystalloidsController, amount);
    });
  }

  double get _documentedLossesMl =>
      widget.initialFluidBalance.diuresis.isEmpty &&
          widget.initialFluidBalance.bleeding.isEmpty &&
          widget.initialFluidBalance.spongeCount.isEmpty &&
          widget.initialFluidBalance.otherLosses.isEmpty
      ? 0
      : (double.tryParse(
                  widget.initialFluidBalance.diuresis.replaceAll(',', '.'),
                ) ??
                0) +
            (double.tryParse(
                  widget.initialFluidBalance.bleeding.replaceAll(',', '.'),
                ) ??
                0) +
            widget.initialFluidBalance.estimatedSpongeLoss +
            (double.tryParse(
                  widget.initialFluidBalance.otherLosses.replaceAll(',', '.'),
                ) ??
                0);

  Future<void> _selectSurgicalSize() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ChoiceFieldDialog(
        title: 'Porte cirúrgico',
        options: _surgicalSizes,
        initialValue: _selectedSurgicalSize,
      ),
    );

    if (result == null) return;
    setState(() => _selectedSurgicalSize = result);
  }

  @override
  Widget build(BuildContext context) {
    final preview = FluidBalance(
      crystalloids: _crystalloidsController.text.trim(),
      colloids: _colloidsController.text.trim(),
      blood: _bloodController.text.trim(),
      diuresis: widget.initialFluidBalance.diuresis,
      bleeding: widget.initialFluidBalance.bleeding,
      spongeCount: widget.initialFluidBalance.spongeCount,
      otherLosses: widget.initialFluidBalance.otherLosses,
      crystalloidEntries: _crystalloidEntries,
      colloidEntries: _colloidEntries,
      bloodEntries: _bloodEntries,
      bloodLossEntries: widget.initialFluidBalance.bloodLossEntries,
      otherLossEntries: widget.initialFluidBalance.otherLossEntries,
    );
    final recommendation = _buildFluidSupportRecommendation(
      patient: Patient(
        name: '',
        age: widget.patientAgeYears,
        weightKg: widget.patientWeightKg,
        heightMeters: widget.patientHeightMeters,
        asa: '',
        allergies: const [],
        restrictions: const [],
        medications: const [],
        population: widget.patientPopulation,
        postnatalAgeDays: widget.patientPostnatalAgeDays,
        gestationalAgeWeeks: widget.patientGestationalAgeWeeks,
        correctedGestationalAgeWeeks: 0,
        birthWeightKg: widget.patientBirthWeightKg,
      ),
      documentedLossesMl: _documentedLossesMl,
      fastingHoursText: _fastingHoursController.text.trim(),
      surgicalSize: _selectedSurgicalSize,
    );

    return AlertDialog(
      backgroundColor: const Color(0xFFF9FBFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Editar Reposição volêmica, sangue e derivados'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Porte cirúrgico',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectSurgicalSize,
                  icon: const Icon(Icons.straighten_outlined),
                  label: Text(
                    _selectedSurgicalSize.trim().isEmpty
                        ? 'Selecionar porte cirúrgico'
                        : _selectedSurgicalSize,
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.suggestedSurgicalSize.trim().isEmpty
                      ? 'Sem sugestão automática disponível'
                      : 'Sugestão automática: ${widget.suggestedSurgicalSize}',
                  style: const TextStyle(
                    color: Color(0xFF5D7288),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD9E6F7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: const TextStyle(
                        color: Color(0xFF365FD5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recommendation.lines.map(
                      (line) => Text(
                        line,
                        style: const TextStyle(
                          color: Color(0xFF5D7288),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _fastingHoursController.text.trim().isEmpty
                          ? 'Jejum não informado. Conduzir pela manutenção, perdas e hemodinâmica.'
                          : 'Jejum: ${_fastingHoursController.text.trim()} h • Porte: ${_selectedSurgicalSize.isEmpty ? "não definido" : _selectedSurgicalSize}',
                      style: const TextStyle(
                        color: Color(0xFF17324D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fastingHoursController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.><hH -]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Jejum informado',
                  suffixText: 'h',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _fastingSuggestedMl > 0
                          ? () =>
                                _applySuggestedCrystalloid(_fastingSuggestedMl)
                          : null,
                      child: Text(
                        _fastingSuggestedMl > 0
                            ? 'Aplicar jejum sugerido (${_fastingSuggestedMl.toStringAsFixed(0)} mL)'
                            : 'Jejum sem sugestão',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _intraoperativeSuggestedMlPerHour > 0
                          ? () => _applySuggestedCrystalloid(
                              _intraoperativeSuggestedMl,
                            )
                          : null,
                      child: Text(
                        _intraoperativeSuggestedMlPerHour > 0
                            ? 'Aplicar intraop sugerida (${_intraoperativeSuggestedMlPerHour.toStringAsFixed(0)} mL/h${_suggestedHourlyReferenceHours > 0 ? ' • ${_intraoperativeSuggestedMl.toStringAsFixed(0)} mL em ${_formatHoursReferenceLabel(_suggestedHourlyReferenceHours)}' : ''})'
                            : 'Sem intraop sugerida',
                      ),
                    ),
                  ),
                ],
              ),
              if (_intraoperativeSuggestedMlPerHour > 0) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.anesthesiaElapsedHours > 0
                        ? 'Taxa expressa em mL/h e convertida para o tempo anestésico registrado.'
                        : 'Taxa expressa em mL/h; sem tempo anestésico registrado, o botão aplica 1 h.',
                    style: const TextStyle(
                      color: Color(0xFF5D7288),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FluidField(
                key: const Key('fluid-crystalloids-field'),
                controller: _crystalloidsController,
                label: 'Reposição volêmica - cristaloides',
              ),
              const SizedBox(height: 8),
              _QuickVolumeChips(
                values: _commonVolumes,
                onSelected: (value) =>
                    _addToController(_crystalloidsController, _parse(value)),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Adicionar solução cristaloide',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _crystalloidOptions
                    .map(
                      (item) => ActionChip(
                        label: Text('${item.label} +${item.volumeMl} mL'),
                        onPressed: () => _addFluidEntry(
                          target: _crystalloidEntries,
                          controller: _crystalloidsController,
                          label: item.label,
                          volumeMl: item.volumeMl,
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (_crystalloidEntries.isNotEmpty) ...[
                const SizedBox(height: 10),
                _FluidEntryList(
                  entries: _crystalloidEntries,
                  onRemove: (index) => _removeFluidEntry(
                    target: _crystalloidEntries,
                    controller: _crystalloidsController,
                    index: index,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FluidField(controller: _colloidsController, label: 'Coloides'),
              const SizedBox(height: 8),
              _QuickVolumeChips(
                values: _commonVolumes,
                onSelected: (value) =>
                    _addToController(_colloidsController, _parse(value)),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Adicionar colóide',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colloidOptions
                    .map(
                      (item) => ActionChip(
                        label: Text('${item.label} +${item.volumeMl} mL'),
                        onPressed: () => _addFluidEntry(
                          target: _colloidEntries,
                          controller: _colloidsController,
                          label: item.label,
                          volumeMl: item.volumeMl,
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (_colloidEntries.isNotEmpty) ...[
                const SizedBox(height: 10),
                _FluidEntryList(
                  entries: _colloidEntries,
                  onRemove: (index) => _removeFluidEntry(
                    target: _colloidEntries,
                    controller: _colloidsController,
                    index: index,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FluidField(
                key: const Key('fluid-blood-field'),
                controller: _bloodController,
                label: 'Sangue e derivados',
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Adicionar sangue / derivados por unidade',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _bloodComponentOptions
                    .map(
                      (item) => ActionChip(
                        label: Text('+1 ${item.unitLabel} ${item.label}'),
                        onPressed: () => _addBloodComponentEntry(item),
                      ),
                    )
                    .toList(),
              ),
              if (_bloodEntries.isNotEmpty) ...[
                const SizedBox(height: 10),
                _FluidEntryList(
                  entries: _bloodEntries,
                  onRemove: _removeBloodEntry,
                ),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: KeyValueLine(
                  label: 'Balanço atual',
                  value: preview.formattedBalance,
                  labelColor: const Color(0xFF169653),
                  valueColor: const Color(0xFF169653),
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
          key: const Key('fluid-save-button'),
          onPressed: () {
            Navigator.of(context).pop(
              FluidBalanceDialogResult(
                fluidBalance: FluidBalance(
                  crystalloids: _crystalloidsController.text.trim(),
                  colloids: _colloidsController.text.trim(),
                  blood: _bloodController.text.trim(),
                  diuresis: widget.initialFluidBalance.diuresis,
                  bleeding: widget.initialFluidBalance.bleeding,
                  spongeCount: widget.initialFluidBalance.spongeCount,
                  otherLosses: widget.initialFluidBalance.otherLosses,
                  crystalloidEntries: _crystalloidEntries,
                  colloidEntries: _colloidEntries,
                  bloodEntries: _bloodEntries,
                  bloodLossEntries: widget.initialFluidBalance.bloodLossEntries,
                  otherLossEntries: widget.initialFluidBalance.otherLossEntries,
                ),
                surgicalSize: _selectedSurgicalSize,
                fastingHours: _fastingHoursController.text.trim(),
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class FluidField extends StatelessWidget {
  const FluidField({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
      decoration: InputDecoration(labelText: label, suffixText: 'mL'),
    );
  }
}

class FluidBalanceDialogResult {
  const FluidBalanceDialogResult({
    required this.fluidBalance,
    required this.surgicalSize,
    required this.fastingHours,
  });

  final FluidBalance fluidBalance;
  final String surgicalSize;
  final String fastingHours;
}

class BalanceOnlyDialog extends StatefulWidget {
  const BalanceOnlyDialog({
    super.key,
    required this.initialFluidBalance,
    required this.anesthesiaElapsedHours,
  });

  final FluidBalance initialFluidBalance;
  final double anesthesiaElapsedHours;

  @override
  State<BalanceOnlyDialog> createState() => _BalanceOnlyDialogState();
}

class _BalanceOnlyDialogState extends State<BalanceOnlyDialog> {
  static const List<String> _partialBloodLossVolumes = [
    '50',
    '100',
    '200',
    '500',
  ];
  late final TextEditingController _diuresisController;
  late final TextEditingController _bleedingController;
  late final TextEditingController _spongeCountController;
  late final TextEditingController _otherLossesController;
  late List<String> _bloodLossEntries;
  late List<String> _otherLossEntries;

  double _parse(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  double get _inputsMl =>
      _parse(widget.initialFluidBalance.crystalloids) +
      _parse(widget.initialFluidBalance.colloids) +
      _parse(widget.initialFluidBalance.blood);

  double get _estimatedSpongeLoss => _parse(_spongeCountController.text) * 100;

  double get _hourlyReferenceHours =>
      widget.anesthesiaElapsedHours > 0 ? widget.anesthesiaElapsedHours : 1;

  double _sumEntries(List<String> entries) {
    return entries.fold<double>(0, (total, item) {
      final parts = item.split('|');
      return total + (parts.isNotEmpty ? _parse(parts.last) : 0);
    });
  }

  double get _outputsMl =>
      _parse(_diuresisController.text) +
      _parse(_bleedingController.text) +
      _sumEntries(_bloodLossEntries) +
      _estimatedSpongeLoss +
      _parse(_otherLossesController.text) +
      _sumEntries(_otherLossEntries);

  FluidBalance get _preview => widget.initialFluidBalance.copyWith(
    diuresis: _diuresisController.text.trim(),
    bleeding: _bleedingController.text.trim(),
    spongeCount: _spongeCountController.text.trim(),
    otherLosses: _otherLossesController.text.trim(),
    bloodLossEntries: _bloodLossEntries,
    otherLossEntries: _otherLossEntries,
  );

  @override
  void initState() {
    super.initState();
    _diuresisController = TextEditingController(
      text: widget.initialFluidBalance.diuresis,
    )..addListener(_onChange);
    _bleedingController = TextEditingController(
      text: widget.initialFluidBalance.bleeding,
    )..addListener(_onChange);
    _spongeCountController = TextEditingController(
      text: widget.initialFluidBalance.spongeCount,
    )..addListener(_onChange);
    _otherLossesController = TextEditingController(
      text: widget.initialFluidBalance.otherLosses,
    )..addListener(_onChange);
    _bloodLossEntries = List<String>.from(
      widget.initialFluidBalance.bloodLossEntries,
    );
    _otherLossEntries = List<String>.from(
      widget.initialFluidBalance.otherLossEntries,
    );
  }

  void _onChange() {
    setState(() {});
  }

  void _addBloodLossEntry(String value) {
    final amount = _parse(value);
    if (amount <= 0) return;
    setState(() {
      _bloodLossEntries.add('Perda parcial|${amount.toStringAsFixed(0)}');
    });
  }

  void _addOtherLossEntry(String label, double amountPerHour) {
    if (amountPerHour <= 0) return;
    final applied = amountPerHour * _hourlyReferenceHours;
    setState(() {
      _otherLossEntries.add(
        '$label|${amountPerHour.toStringAsFixed(0)} mL/h|${applied.toStringAsFixed(0)}',
      );
    });
  }

  void _removeEntry(List<String> entries, int index) {
    setState(() {
      entries.removeAt(index);
    });
  }

  @override
  void dispose() {
    _diuresisController
      ..removeListener(_onChange)
      ..dispose();
    _bleedingController
      ..removeListener(_onChange)
      ..dispose();
    _spongeCountController
      ..removeListener(_onChange)
      ..dispose();
    _otherLossesController
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9FBFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Editar Balanço hídrico'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD9E6F7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entradas já registradas',
                      style: TextStyle(
                        color: Color(0xFF365FD5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cristaloides: ${widget.initialFluidBalance.crystalloids.trim().isEmpty ? "--" : "${widget.initialFluidBalance.crystalloids} mL"}',
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Coloides: ${widget.initialFluidBalance.colloids.trim().isEmpty ? "--" : "${widget.initialFluidBalance.colloids} mL"}',
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Sangue / hemoderivados: ${widget.initialFluidBalance.blood.trim().isEmpty ? "--" : "${widget.initialFluidBalance.blood} mL"}',
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entradas totais: ${_inputsMl.toStringAsFixed(0)} mL',
                      style: const TextStyle(
                        color: Color(0xFF17324D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FluidField(
                key: const Key('fluid-diuresis-field'),
                controller: _diuresisController,
                label: 'Diurese',
              ),
              const SizedBox(height: 12),
              FluidField(
                key: const Key('fluid-bleeding-field'),
                controller: _bleedingController,
                label: 'Sangramento',
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Adicionar perdas sanguíneas parciais',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              _QuickVolumeChips(
                values: _partialBloodLossVolumes,
                onSelected: _addBloodLossEntry,
              ),
              if (_bloodLossEntries.isNotEmpty) ...[
                const SizedBox(height: 10),
                _FluidEntryList(
                  entries: _bloodLossEntries,
                  onRemove: (index) => _removeEntry(_bloodLossEntries, index),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                key: const Key('fluid-sponge-count-field'),
                controller: _spongeCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Compressas',
                  suffixText: 'un',
                  helperText:
                      'Estimativa média: 100 mL por compressa grande saturada',
                ),
              ),
              const SizedBox(height: 12),
              FluidField(
                key: const Key('fluid-other-losses-field'),
                controller: _otherLossesController,
                label: 'Outras perdas',
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.anesthesiaElapsedHours > 0
                      ? 'Perdas insensíveis e ventilação mecânica abaixo estão em mL/h e são convertidas pelo tempo anestésico registrado (${_formatHoursReferenceLabel(widget.anesthesiaElapsedHours)}).'
                      : 'Perdas insensíveis e ventilação mecânica abaixo estão em mL/h; sem tempo anestésico registrado, cada toque aplica 1 h.',
                  style: const TextStyle(
                    color: Color(0xFF5D7288),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in const [
                    _LossOption('Perdas insensíveis', 50),
                    _LossOption('Ventilação mecânica', 50),
                    _LossOption('Outras perdas', 100),
                  ])
                    ActionChip(
                      label: Text(
                        '${item.label} ${item.defaultMl.toStringAsFixed(0)} mL/h',
                      ),
                      onPressed: () =>
                          _addOtherLossEntry(item.label, item.defaultMl),
                    ),
                ],
              ),
              if (_otherLossEntries.isNotEmpty) ...[
                const SizedBox(height: 10),
                _FluidEntryList(
                  entries: _otherLossEntries,
                  onRemove: (index) => _removeEntry(_otherLossEntries, index),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    KeyValueLine(
                      label: 'Saídas totais',
                      value: '${_outputsMl.toStringAsFixed(0)} mL',
                      labelColor: const Color(0xFF169653),
                      valueColor: const Color(0xFF169653),
                    ),
                    const SizedBox(height: 8),
                    KeyValueLine(
                      label: 'Balanço atual',
                      value: _preview.formattedBalance,
                      labelColor: const Color(0xFF169653),
                      valueColor: const Color(0xFF169653),
                    ),
                  ],
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
          key: const Key('fluid-save-button'),
          onPressed: () => Navigator.of(context).pop(_preview),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _CrystalloidOption {
  const _CrystalloidOption(this.label, this.volumeMl);

  final String label;
  final int volumeMl;
}

class _BloodComponentOption {
  const _BloodComponentOption(this.label, this.unitLabel, this.averageVolumeMl);

  final String label;
  final String unitLabel;
  final int averageVolumeMl;
}

class _LossOption {
  const _LossOption(this.label, this.defaultMl);

  final String label;
  final double defaultMl;
}

class _QuickVolumeChips extends StatelessWidget {
  const _QuickVolumeChips({required this.values, required this.onSelected});

  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => ActionChip(
              label: Text('$value mL'),
              onPressed: () => onSelected(value),
            ),
          )
          .toList(),
    );
  }
}

class _FluidEntryList extends StatelessWidget {
  const _FluidEntryList({required this.entries, required this.onRemove});

  final List<String> entries;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0EAF3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entries[i].replaceAll('|', ' • '),
                      style: const TextStyle(
                        color: Color(0xFF5D7288),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(i),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ExportCaseDialog extends StatelessWidget {
  const _ExportCaseDialog({
    required this.onPreviewPressed,
    required this.onPrintPressed,
    required this.onSharePressed,
  });

  final Future<void> Function() onPreviewPressed;
  final Future<void> Function() onPrintPressed;
  final Future<void> Function() onSharePressed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportar ficha completa'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'O arquivo reúne a ficha de anestesia e, abaixo dela, o pré-anestésico completo.',
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await onPreviewPressed();
              },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Visualizar PDF'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await onPrintPressed();
              },
              icon: const Icon(Icons.print_outlined),
              label: const Text('Imprimir'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await onSharePressed();
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartilhar / salvar'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class EditSectionScreen extends StatefulWidget {
  const EditSectionScreen({
    super.key,
    required this.title,
    required this.initialContent,
  });

  final String title;
  final String initialContent;

  @override
  State<EditSectionScreen> createState() => _EditSectionScreenState();
}

class _EditSectionScreenState extends State<EditSectionScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF17324D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Atualize as informações deste módulo da ficha.',
                style: TextStyle(
                  color: Color(0xFF6C8096),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: TextField(
                  controller: _controller,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Digite o conteúdo',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(_controller.text.trim()),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnesthesiaMaterialsDialog extends StatefulWidget {
  const _AnesthesiaMaterialsDialog({required this.initialItems});

  final List<String> initialItems;

  @override
  State<_AnesthesiaMaterialsDialog> createState() =>
      _AnesthesiaMaterialsDialogState();
}

class _AnesthesiaMaterialsDialogState
    extends State<_AnesthesiaMaterialsDialog> {
  late final TextEditingController _manualController;
  late final TextEditingController _oxygenFlowController;
  late final TextEditingController _oxygenMinutesController;
  late List<String> _manualEntries;
  late List<String> _oxygenEntries;
  String _selectedOxygenDevice = 'cateter';

  @override
  void initState() {
    super.initState();
    _manualEntries = widget.initialItems
        .where(
          (item) =>
              item.trim().isNotEmpty &&
              !_isEncodedOxygenTherapyEntry(item) &&
              !_isEncodedLossEntry(item),
        )
        .toList();
    _oxygenEntries = widget.initialItems
        .where(_isEncodedOxygenTherapyEntry)
        .toList();
    _manualController = TextEditingController();
    _oxygenFlowController = TextEditingController();
    _oxygenMinutesController = TextEditingController();
  }

  @override
  void dispose() {
    _manualController.dispose();
    _oxygenFlowController.dispose();
    _oxygenMinutesController.dispose();
    super.dispose();
  }

  List<String> _draftManualItems() {
    return _manualController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _addManualItems() {
    final draftItems = _draftManualItems();
    if (draftItems.isEmpty) return;
    setState(() {
      _manualEntries = [..._manualEntries, ...draftItems];
      _manualController.clear();
    });
  }

  double? _parseFlow(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _addOxygenEntry() {
    final flowLPerMin = _parseFlow(_oxygenFlowController.text);
    final minutes = int.tryParse(_oxygenMinutesController.text.trim());
    if (flowLPerMin == null ||
        flowLPerMin <= 0 ||
        minutes == null ||
        minutes <= 0) {
      return;
    }
    setState(() {
      _oxygenEntries.add(
        _encodeOxygenTherapyEntry(
          device: _selectedOxygenDevice,
          flowLPerMin: flowLPerMin,
          minutes: minutes,
        ),
      );
      _oxygenFlowController.clear();
      _oxygenMinutesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Itens adicionais / ajuste manual'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _manualController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Itens extras / ajustes / quantidades',
                  hintText:
                      'Ex: equipo de infusão 1 un; filtro HME 1 un; item não capturado automaticamente',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _addManualItems,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar item'),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Oxigênio por dispositivo',
                style: TextStyle(
                  color: Color(0xFF17324D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'cateter',
                      label: Text('O₂ em cateter'),
                      icon: Icon(Icons.air_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'mascara',
                      label: Text('O₂ em máscara'),
                      icon: Icon(Icons.masks_outlined),
                    ),
                  ],
                  selected: {_selectedOxygenDevice},
                  multiSelectionEnabled: false,
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) return;
                    setState(() => _selectedOxygenDevice = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _oxygenFlowController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Fluxo de O₂ (L/min)',
                  hintText: 'Ex: 3,0',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _oxygenMinutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tempo utilizado (min)',
                  hintText: 'Ex: 45',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _addOxygenEntry,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar oxigenoterapia'),
                ),
              ),
              const SizedBox(height: 16),
              if (_manualEntries.isNotEmpty) ...[
                const Text(
                  'Itens manuais lançados',
                  style: TextStyle(
                    color: Color(0xFF17324D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ..._manualEntries.asMap().entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.value),
                    trailing: IconButton(
                      onPressed: () {
                        setState(() => _manualEntries.removeAt(entry.key));
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ),
              ],
              if (_oxygenEntries.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Oxigenoterapia lançada',
                  style: TextStyle(
                    color: Color(0xFF17324D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ..._oxygenEntries.asMap().entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_formatOxygenTherapyEntryLabel(entry.value)),
                    trailing: IconButton(
                      onPressed: () {
                        setState(() => _oxygenEntries.removeAt(entry.key));
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ),
              ],
              if (_manualEntries.isEmpty && _oxygenEntries.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Nenhum item adicional registrado.',
                    style: TextStyle(color: Color(0xFF7A8EA5)),
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
          onPressed: () => Navigator.of(
            context,
          ).pop([..._manualEntries, ..._oxygenEntries, ..._draftManualItems()]),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
