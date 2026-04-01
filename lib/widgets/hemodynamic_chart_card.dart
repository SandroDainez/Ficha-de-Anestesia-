import 'package:flutter/material.dart';

import '../models/hemodynamic_point.dart';
import 'card_widget.dart';

class HemodynamicChartCard extends StatelessWidget {
  const HemodynamicChartCard({
    super.key,
    required this.dominant,
    required this.inlineHemodynamicRemoveMode,
    required this.hasAnesthesiaStartMarker,
    required this.hasSurgeryStartMarker,
    required this.inlineHemodynamicType,
    required this.currentInlineTime,
    required this.anesthesiaElapsed,
    required this.surgeryElapsed,
    required this.points,
    required this.markers,
    required this.latestFc,
    required this.latestBloodPressure,
    required this.latestPam,
    required this.paiSummary,
    required this.latestSpo2,
    required this.onAddAnesthesiaStart,
    required this.onAddSurgeryStart,
    required this.onToggleRemoveMode,
    required this.onManualEntry,
    required this.onSelectType,
    required this.onQuickSpo2,
    required this.onPointTap,
    required this.onChartTap,
  });

  final bool dominant;
  final bool inlineHemodynamicRemoveMode;
  final bool hasAnesthesiaStartMarker;
  final bool hasSurgeryStartMarker;
  final String inlineHemodynamicType;
  final double currentInlineTime;
  final String anesthesiaElapsed;
  final String surgeryElapsed;
  final List<HemodynamicPoint> points;
  final List<HemodynamicMarker> markers;
  final String latestFc;
  final String latestBloodPressure;
  final String latestPam;
  final String paiSummary;
  final String latestSpo2;
  final VoidCallback onAddAnesthesiaStart;
  final VoidCallback onAddSurgeryStart;
  final VoidCallback onToggleRemoveMode;
  final VoidCallback onManualEntry;
  final ValueChanged<String> onSelectType;
  final ValueChanged<double> onQuickSpo2;
  final ValueChanged<HemodynamicPoint>? onPointTap;
  final ValueChanged<double>? onChartTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPoints = points.isNotEmpty;
    final showEmptyOverlay = !hasAnesthesiaStartMarker && !hasPoints;
    final chartHeight = dominant ? 680.0 : 540.0;
    final instructionText = inlineHemodynamicRemoveMode
        ? 'Modo correção ativo. Toque em um ponto do gráfico para apagar.'
        : (hasAnesthesiaStartMarker
            ? 'Selecione o parâmetro, confirme o modo de registro e toque no gráfico.'
            : 'Marque o início da anestesia para liberar os lançamentos.');

    return PanelCard(
      key: const Key('hemodynamic-chart-section'),
      title: 'Gráfico hemodinâmico',
      titleColor: const Color(0xFF4A5568),
      icon: Icons.show_chart,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCE7F3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBanner(
                  title: inlineHemodynamicRemoveMode
                      ? 'Modo correção'
                      : (hasAnesthesiaStartMarker
                          ? 'Modo lançamento'
                          : 'Aguardando início'),
                  description: instructionText,
                  accent: inlineHemodynamicRemoveMode
                      ? const Color(0xFFCC3D3D)
                      : (hasAnesthesiaStartMarker
                          ? const Color(0xFF2B76D2)
                          : const Color(0xFF7A8EA5)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    _ControlGroup(
                      title: 'Marcos',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            key: const Key('hemo-start-anesthesia-button'),
                            onPressed: hasAnesthesiaStartMarker
                                ? null
                                : onAddAnesthesiaStart,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2B76D2),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.flag_outlined),
                            label: const Text('Início da anestesia'),
                          ),
                          FilledButton.tonalIcon(
                            key: const Key('hemo-start-surgery-button'),
                            onPressed:
                                !hasAnesthesiaStartMarker || hasSurgeryStartMarker
                                    ? null
                                    : onAddSurgeryStart,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF169653),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.flag),
                            label: const Text('Início da cirurgia'),
                          ),
                        ],
                      ),
                    ),
                    _ControlGroup(
                      title: 'Modo',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ModePill(
                            label: inlineHemodynamicRemoveMode
                                ? 'Correção'
                                : 'Registro',
                            activeColor: inlineHemodynamicRemoveMode
                                ? const Color(0xFFCC3D3D)
                                : const Color(0xFF2B76D2),
                          ),
                          OutlinedButton.icon(
                            key: const Key('hemo-toggle-mode-button'),
                            onPressed: points.isEmpty ? null : onToggleRemoveMode,
                            icon: Icon(
                              inlineHemodynamicRemoveMode
                                  ? Icons.edit_location_alt
                                  : Icons.delete_outline,
                            ),
                            label: Text(
                              inlineHemodynamicRemoveMode
                                  ? 'Voltar para registro'
                                  : 'Ativar correção',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Parâmetro selecionado',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF17324D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final type in const ['PAS', 'PAD', 'FC', 'SpO2', 'PAI']) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(type == 'SpO2' ? 'SpO₂' : type),
                            selected: inlineHemodynamicType == type,
                            onSelected: (_) => onSelectType(type),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      key: const Key('hemo-manual-entry-button'),
                      onPressed: hasAnesthesiaStartMarker &&
                              !inlineHemodynamicRemoveMode
                          ? onManualEntry
                          : null,
                      icon: const Icon(Icons.add_chart_outlined),
                      label: Text(
                        'Lançar ${inlineHemodynamicType == 'SpO2' ? 'SpO₂' : inlineHemodynamicType}',
                      ),
                    ),
                    if (!inlineHemodynamicRemoveMode)
                      Text(
                        'Você também pode tocar no gráfico para registrar.',
                        style: const TextStyle(
                          color: Color(0xFF7A8EA5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  hasAnesthesiaStartMarker
                      ? 'Aferição atual: ${_formatHemodynamicClock(currentInlineTime)}'
                      : 'Sem cronômetro iniciado.',
                  style: TextStyle(
                    color: hasAnesthesiaStartMarker
                        ? const Color(0xFF2B76D2)
                        : const Color(0xFF7A8EA5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (inlineHemodynamicType == 'SpO2' &&
                    !inlineHemodynamicRemoveMode) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'SpO₂ rápida',
                    style: TextStyle(
                      color: Color(0xFF17324D),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in const [
                        85,
                        88,
                        90,
                        92,
                        94,
                        95,
                        96,
                        97,
                        98,
                        99,
                        100,
                      ])
                        ActionChip(
                          label: Text('$value%'),
                          onPressed: hasAnesthesiaStartMarker
                              ? () => onQuickSpo2(value.toDouble())
                              : null,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HemodynamicTimerChip(
                      label: 'Tempo de anestesia',
                      value: anesthesiaElapsed,
                      color: const Color(0xFF2B76D2),
                    ),
                    _HemodynamicTimerChip(
                      label: 'Tempo de cirurgia',
                      value: surgeryElapsed,
                      color: const Color(0xFF169653),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const LegendRow(),
          const SizedBox(height: 10),
          SizedBox(
            height: chartHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: HemodynamicChart(
                    points: points,
                    markers: markers,
                    selectedType: inlineHemodynamicType,
                    onPointTap: onPointTap,
                    onChartTap: onChartTap,
                  ),
                ),
                if (showEmptyOverlay)
                  Positioned(
                    left: 18,
                    bottom: 18,
                    child: _HemodynamicEmptyOverlay(
                      onAddAnesthesiaStart: onAddAnesthesiaStart,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 140,
                child: MetricTile(
                  label: 'FC atual',
                  value: latestFc,
                  background: const Color(0xFFFFF1F1),
                  valueColor: const Color(0xFFDD3B3B),
                  icon: Icons.favorite,
                ),
              ),
              SizedBox(
                width: 140,
                child: MetricTile(
                  label: 'PA atual',
                  value: latestBloodPressure,
                  background: const Color(0xFFF0F5FF),
                  valueColor: const Color(0xFF2B76D2),
                  icon: Icons.water_drop_outlined,
                ),
              ),
              SizedBox(
                width: 140,
                child: MetricTile(
                  label: 'PAM',
                  value: latestPam,
                  background: const Color(0xFFEFF5FF),
                  valueColor: const Color(0xFF365FD5),
                  icon: Icons.monitor_heart_outlined,
                ),
              ),
              SizedBox(
                width: 140,
                child: MetricTile(
                  label: 'PAI',
                  value: paiSummary,
                  background: const Color(0xFFF5F7FF),
                  valueColor: const Color(0xFF365FD5),
                  icon: Icons.timeline_outlined,
                ),
              ),
              SizedBox(
                width: 140,
                child: MetricTile(
                  label: 'SpO₂',
                  value: latestSpo2,
                  background: const Color(0xFFEFFAF2),
                  valueColor: const Color(0xFF169653),
                  icon: Icons.air,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatHemodynamicClock(double time) {
    final totalSeconds = (time * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _HemodynamicEmptyOverlay extends StatelessWidget {
  const _HemodynamicEmptyOverlay({
    required this.onAddAnesthesiaStart,
  });

  final VoidCallback onAddAnesthesiaStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1217324D),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gráfico pronto para lançamento.',
            style: TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Marque o início da anestesia para liberar cronômetro e lançamentos.',
            style: TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAddAnesthesiaStart,
            icon: const Icon(Icons.play_arrow_outlined),
            label: const Text('Iniciar anestesia'),
          ),
        ],
      ),
    );
  }
}

class _HemodynamicTimerChip extends StatelessWidget {
  const _HemodynamicTimerChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.title,
    required this.description,
    required this.accent,
  });

  final String title;
  final String description;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7F3)),
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
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.activeColor,
  });

  final String label;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: activeColor.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: activeColor.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: activeColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
