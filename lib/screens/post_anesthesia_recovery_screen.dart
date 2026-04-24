import 'package:flutter/material.dart';

import '../models/anesthesia_record.dart';
import '../models/post_anesthesia_recovery.dart';
import '../widgets/card_widget.dart';
import '../widgets/page_container.dart';

class PostAnesthesiaRecoveryScreen extends StatefulWidget {
  const PostAnesthesiaRecoveryScreen({super.key, required this.record});

  final AnesthesiaRecord record;

  @override
  State<PostAnesthesiaRecoveryScreen> createState() =>
      _PostAnesthesiaRecoveryScreenState();
}

class _PostAnesthesiaRecoveryScreenState
    extends State<PostAnesthesiaRecoveryScreen> {
  static const List<String> _admissionCriteriaOptions = [
    'Identificação conferida',
    'Via aérea pérvia',
    'Ventilação espontânea ou suporte adequado',
    'Monitorização instalada',
    'Acesso venoso pérvio',
    'Relato do procedimento recebido',
    'Prescrição e orientações recebidas',
  ];
  static const List<String> _monitoringOptions = [
    'ECG',
    'PA não invasiva',
    'SpO₂',
    'FR',
    'Temperatura',
    'Dor seriada',
    'Débito urinário',
    'Oxigênio suplementar',
  ];
  static const List<String> _dischargeCriteriaOptions = [
    'Sinais vitais estáveis',
    'Dor controlada',
    'Sem náuseas ou vômitos importantes',
    'Proteção de vias aéreas adequada',
    'Sangramento controlado',
    'Bloqueio motor regressivo ou compatível',
    'Orientado / desperto conforme esperado',
    'Critérios institucionais de alta preenchidos',
  ];
  static const List<String> _complicationOptions = [
    'Dor intensa',
    'Náuseas / vômitos',
    'Hipotensão',
    'Hipertensão',
    'Bradicardia',
    'Taquicardia',
    'Dessaturação',
    'Agitação',
    'Sangramento',
    'Retenção urinária',
  ];
  static const List<String> _interventionOptions = [
    'Oxigênio suplementar',
    'Analgesia complementar',
    'Antiemético',
    'Expansão volêmica',
    'Droga vasoativa',
    'Aquecimento',
    'Aspiração de vias aéreas',
    'Acionada equipe médica',
  ];
  static const List<String> _sedationScaleOptions = [
    'Ramsay 1',
    'Ramsay 2',
    'Ramsay 3',
    'Ramsay 4',
    'Ramsay 5',
    'Ramsay 6',
  ];
  static const List<String> _destinationOptions = [
    'Enfermaria',
    'UTI',
    'Centro cirúrgico',
    'Internação prolongada',
  ];

  late PostAnesthesiaRecovery _recovery;
  late final TextEditingController _admissionTimeController;
  late final TextEditingController _dischargeTimeController;
  late final TextEditingController _painScoreController;
  late final TextEditingController _nauseaScoreController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _admissionNotesController;
  late final TextEditingController _dischargeNotesController;

  @override
  void initState() {
    super.initState();
    _recovery = widget.record.postAnesthesiaRecovery;
    _admissionTimeController = TextEditingController(
      text: _recovery.admissionTime,
    );
    _dischargeTimeController = TextEditingController(
      text: _recovery.dischargeTime,
    );
    _painScoreController = TextEditingController(text: _recovery.painScore);
    _nauseaScoreController = TextEditingController(text: _recovery.nauseaScore);
    _temperatureController = TextEditingController(text: _recovery.temperature);
    _admissionNotesController = TextEditingController(
      text: _recovery.admissionNotes,
    );
    _dischargeNotesController = TextEditingController(
      text: _recovery.dischargeNotes,
    );
  }

  @override
  void dispose() {
    _admissionTimeController.dispose();
    _dischargeTimeController.dispose();
    _painScoreController.dispose();
    _nauseaScoreController.dispose();
    _temperatureController.dispose();
    _admissionNotesController.dispose();
    _dischargeNotesController.dispose();
    super.dispose();
  }

  void _toggleItem(
    List<String> current,
    String value,
    ValueChanged<List<String>> onChanged,
  ) {
    final next = List<String>.from(current);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    onChanged(next);
  }

  String get _caseSummary {
    final record = widget.record;
    final items = <String>[
      if (record.patient.name.trim().isNotEmpty)
        'Paciente: ${record.patient.name.trim()}',
      if (record.surgeryDescription.trim().isNotEmpty)
        'Cirurgia: ${record.surgeryDescription.trim().replaceAll('\n', ' • ')}',
      if (record.anesthesiaTechnique.trim().isNotEmpty)
        'Técnica: ${record.anesthesiaTechnique.trim().replaceAll('\n', ' • ')}',
      if (record.anesthesiaTechniqueDetails.trim().isNotEmpty)
        'Condução: ${record.anesthesiaTechniqueDetails.trim()}',
      if (record.operationalNotes.trim().isNotEmpty)
        'Anotações: ${record.operationalNotes.trim()}',
    ];
    return items.isEmpty
        ? 'Sem resumo integrado disponível.'
        : items.join('\n\n');
  }

  String get _intraoperativeEventsSummary {
    final items = <String>[
      if (widget.record.events.isNotEmpty)
        'Intercorrências/eventos legados: ${widget.record.events.join(' • ')}',
      if (widget.record.hemodynamicMarkers.isNotEmpty)
        'Marcos: ${widget.record.hemodynamicMarkers.map((item) => '${item.label} ${item.clockTime}').join(' • ')}',
      if (widget.record.vasoactiveDrugs.isNotEmpty)
        'Vasoativas: ${widget.record.vasoactiveDrugs.join(' • ')}',
      if (widget.record.drugs.isNotEmpty)
        'Drogas: ${widget.record.drugs.join(' • ')}',
    ];
    return items.isEmpty
        ? 'Sem intercorrências automáticas identificadas no prontuário.'
        : items.join('\n\n');
  }

  Widget _buildChipGroup({
    required String title,
    required List<String> options,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
  }) {
    return PanelCard(
      title: title,
      titleColor: const Color(0xFF2B76D2),
      icon: Icons.checklist_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (item) => OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _toggleItem(selected, item, onChanged);
                  });
                },
                icon: Icon(
                  selected.contains(item)
                      ? Icons.check_circle
                      : Icons.add_circle_outline,
                  size: 18,
                ),
                label: Text(item),
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected.contains(item)
                      ? const Color(0xFF2B76D2).withAlpha(16)
                      : Colors.white,
                  side: BorderSide(
                    color: selected.contains(item)
                        ? const Color(0xFF2B76D2)
                        : const Color(0xFFD6E1ED),
                  ),
                  foregroundColor: selected.contains(item)
                      ? const Color(0xFF2B76D2)
                      : const Color(0xFF4F6378),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAldreteSelector({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF17324D),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(
            3,
            (index) => OutlinedButton(
              onPressed: () => setState(() => onChanged(index)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 44),
                backgroundColor: value == index
                    ? const Color(0xFF8A5DD3).withAlpha(18)
                    : Colors.white,
                side: BorderSide(
                  color: value == index
                      ? const Color(0xFF8A5DD3)
                      : const Color(0xFFD6E1ED),
                ),
                foregroundColor: value == index
                    ? const Color(0xFF8A5DD3)
                    : const Color(0xFF4F6378),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(index.toString()),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final updated = _recovery.copyWith(
      admissionTime: _admissionTimeController.text.trim(),
      dischargeTime: _dischargeTimeController.text.trim(),
      painScore: _painScoreController.text.trim(),
      nauseaScore: _nauseaScoreController.text.trim(),
      temperature: _temperatureController.text.trim(),
      admissionNotes: _admissionNotesController.text.trim(),
      dischargeNotes: _dischargeNotesController.text.trim(),
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F7),
      appBar: AppBar(
        title: const Text('Recuperação Pós-Anestésica / Pós-Cirúrgica'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          child: PageContainer(
            child: Column(
              children: [
                PanelCard(
                  title: 'Resumo Integrado do Caso',
                  titleColor: const Color(0xFF5A6F86),
                  icon: Icons.link_outlined,
                  child: Text(
                    _caseSummary,
                    style: const TextStyle(
                      color: Color(0xFF17324D),
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PanelCard(
                  title: 'Intercorrências e Dados Intraoperatórios',
                  titleColor: const Color(0xFFAF5A7A),
                  icon: Icons.monitor_heart_outlined,
                  child: Text(
                    _intraoperativeEventsSummary,
                    style: const TextStyle(
                      color: Color(0xFF17324D),
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PanelCard(
                  title: 'Admissão na RPA',
                  titleColor: const Color(0xFF169653),
                  icon: Icons.login_outlined,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _admissionTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Horário de admissão',
                                hintText: 'HH:MM',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _temperatureController,
                              decoration: const InputDecoration(
                                labelText: 'Temperatura',
                                hintText: 'Ex: 36,2 °C',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _admissionNotesController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Admissão / handoff / observações',
                          hintText:
                              'Descrever condições na admissão, dados clínicos recebidos, cirurgia realizada, eventos relevantes da anestesia e plano imediato.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildChipGroup(
                  title: 'Critérios de Admissão',
                  options: _admissionCriteriaOptions,
                  selected: _recovery.admissionCriteria,
                  onChanged: (items) =>
                      _recovery = _recovery.copyWith(admissionCriteria: items),
                ),
                const SizedBox(height: 12),
                _buildChipGroup(
                  title: 'Monitorização na Recuperação',
                  options: _monitoringOptions,
                  selected: _recovery.monitoringItems,
                  onChanged: (items) =>
                      _recovery = _recovery.copyWith(monitoringItems: items),
                ),
                const SizedBox(height: 12),
                PanelCard(
                  title: 'Escalas e Avaliações',
                  titleColor: const Color(0xFF8A5DD3),
                  icon: Icons.rule_folder_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _painScoreController,
                              decoration: const InputDecoration(
                                labelText: 'Dor',
                                hintText: '0 a 10',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _nauseaScoreController,
                              decoration: const InputDecoration(
                                labelText: 'Náusea / vômito',
                                hintText: '0 a 3',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _sedationScaleOptions
                            .map(
                              (item) => OutlinedButton(
                                onPressed: () => setState(
                                  () => _recovery = _recovery.copyWith(
                                    sedationScale: item,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      _recovery.sedationScale == item
                                      ? const Color(0xFF8A5DD3).withAlpha(18)
                                      : Colors.white,
                                  side: BorderSide(
                                    color: _recovery.sedationScale == item
                                        ? const Color(0xFF8A5DD3)
                                        : const Color(0xFFD6E1ED),
                                  ),
                                  foregroundColor:
                                      _recovery.sedationScale == item
                                      ? const Color(0xFF8A5DD3)
                                      : const Color(0xFF4F6378),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(item),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aldrete: ${_recovery.aldreteTotal}/10',
                        style: const TextStyle(
                          color: Color(0xFF17324D),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: [
                          SizedBox(
                            width: 220,
                            child: _buildAldreteSelector(
                              label: 'Atividade',
                              value: _recovery.aldreteActivity,
                              onChanged: (value) => _recovery = _recovery
                                  .copyWith(aldreteActivity: value),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: _buildAldreteSelector(
                              label: 'Respiração',
                              value: _recovery.aldreteRespiration,
                              onChanged: (value) => _recovery = _recovery
                                  .copyWith(aldreteRespiration: value),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: _buildAldreteSelector(
                              label: 'Circulação',
                              value: _recovery.aldreteCirculation,
                              onChanged: (value) => _recovery = _recovery
                                  .copyWith(aldreteCirculation: value),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: _buildAldreteSelector(
                              label: 'Consciência',
                              value: _recovery.aldreteConsciousness,
                              onChanged: (value) => _recovery = _recovery
                                  .copyWith(aldreteConsciousness: value),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: _buildAldreteSelector(
                              label: 'SpO₂',
                              value: _recovery.aldreteSpo2,
                              onChanged: (value) => _recovery = _recovery
                                  .copyWith(aldreteSpo2: value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildChipGroup(
                  title: 'Complicações na Recuperação',
                  options: _complicationOptions,
                  selected: _recovery.complications,
                  onChanged: (items) =>
                      _recovery = _recovery.copyWith(complications: items),
                ),
                const SizedBox(height: 12),
                _buildChipGroup(
                  title: 'Intervenções na Recuperação',
                  options: _interventionOptions,
                  selected: _recovery.interventions,
                  onChanged: (items) =>
                      _recovery = _recovery.copyWith(interventions: items),
                ),
                const SizedBox(height: 12),
                _buildChipGroup(
                  title: 'Critérios de Alta',
                  options: _dischargeCriteriaOptions,
                  selected: _recovery.dischargeCriteria,
                  onChanged: (items) =>
                      _recovery = _recovery.copyWith(dischargeCriteria: items),
                ),
                const SizedBox(height: 12),
                PanelCard(
                  title: 'Alta da Recuperação',
                  titleColor: const Color(0xFF169653),
                  icon: Icons.logout_outlined,
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: 180,
                            child: TextField(
                              controller: _dischargeTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Horário de alta',
                                hintText: 'HH:MM',
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue:
                                  _recovery.destinationAfterRecovery.isEmpty
                                  ? null
                                  : _recovery.destinationAfterRecovery,
                              decoration: const InputDecoration(
                                labelText: 'Destino após recuperação',
                              ),
                              items: _destinationOptions
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(
                                () => _recovery = _recovery.copyWith(
                                  destinationAfterRecovery: value ?? '',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dischargeNotesController,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Condições de alta / orientações',
                          hintText:
                              'Descrever critérios de alta atingidos, avaliação final, encaminhamento e observações.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar recuperação'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
