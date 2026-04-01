import 'package:flutter/material.dart';

import '../models/patient.dart';
import 'ui_tokens.dart';

class TopBarWidget extends StatelessWidget {
  const TopBarWidget({
    super.key,
    required this.onPreAnestheticTap,
    required this.caseStage,
    required this.recordStatus,
    required this.highlightMessage,
    required this.preAnestheticDateLabel,
    required this.anesthesiaDateLabel,
    this.onPreAnestheticDateTap,
    this.onAnesthesiaDateTap,
  });

  final VoidCallback onPreAnestheticTap;
  final String caseStage;
  final String recordStatus;
  final String highlightMessage;
  final String preAnestheticDateLabel;
  final String anesthesiaDateLabel;
  final VoidCallback? onPreAnestheticDateTap;
  final VoidCallback? onAnesthesiaDateTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UiSpace.md),
      decoration: BoxDecoration(
        color: UiColors.surface,
        borderRadius: BorderRadius.circular(UiRadius.lg),
        border: Border.all(color: UiColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17324D),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: UiSpace.md,
        runSpacing: UiSpace.sm,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _GabsBrandLogo(size: 44),
              const SizedBox(width: UiSpace.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GABS',
                    style: TextStyle(
                      color: UiColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Grupo de Anestesiologistas da Baixada Santista',
                    style: TextStyle(
                      color: UiColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    highlightMessage,
                    style: const TextStyle(
                      color: UiColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: UiSpace.xs,
            runSpacing: UiSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TopBarPill(
                label: recordStatus,
                color: UiColors.success,
                icon: Icons.shield_outlined,
              ),
              _TopBarPill(
                label: caseStage,
                color: UiColors.info,
                icon: Icons.play_circle_outline,
              ),
              _TopBarPill(
                label: 'Consulta: $preAnestheticDateLabel',
                color: UiColors.warning,
                icon: Icons.event_note_outlined,
                onTap: onPreAnestheticDateTap,
              ),
              _TopBarPill(
                label: 'Anestesia: $anesthesiaDateLabel',
                color: UiColors.accent,
                icon: Icons.schedule_outlined,
                onTap: onAnesthesiaDateTap,
              ),
              FilledButton.icon(
                onPressed: onPreAnestheticTap,
                style: FilledButton.styleFrom(
                  backgroundColor: UiColors.info,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UiRadius.md),
                  ),
                ),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Abrir pré-anestésico'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBarPill extends StatelessWidget {
  const _TopBarPill({
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(UiRadius.pill),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiRadius.pill),
        child: content,
      ),
    );
  }
}

class _GabsBrandLogo extends StatelessWidget {
  const _GabsBrandLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(UiRadius.md),
      child: Image.asset(
        'assets/images/gabs_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class AnesthesiaHeaderWidget extends StatelessWidget {
  const AnesthesiaHeaderWidget({
    super.key,
    required this.patient,
    required this.mallampati,
    this.onNameTap,
    this.onAgeTap,
    this.onWeightTap,
    this.onHeightTap,
    this.onPopulationTap,
    this.onPostnatalAgeTap,
    this.onGestationalAgeTap,
    this.onCorrectedGestationalAgeTap,
    this.onBirthWeightTap,
    this.onAsaTap,
    this.onMallampatiTap,
    this.onAllergiesTap,
    this.onRestrictionsTap,
    this.onMedicationsTap,
  });

  final Patient patient;
  final String mallampati;
  final VoidCallback? onNameTap;
  final VoidCallback? onAgeTap;
  final VoidCallback? onWeightTap;
  final VoidCallback? onHeightTap;
  final VoidCallback? onPopulationTap;
  final VoidCallback? onPostnatalAgeTap;
  final VoidCallback? onGestationalAgeTap;
  final VoidCallback? onCorrectedGestationalAgeTap;
  final VoidCallback? onBirthWeightTap;
  final VoidCallback? onAsaTap;
  final VoidCallback? onMallampatiTap;
  final VoidCallback? onAllergiesTap;
  final VoidCallback? onRestrictionsTap;
  final VoidCallback? onMedicationsTap;

  @override
  Widget build(BuildContext context) {
    final patientName = patient.name.trim().isEmpty
        ? 'Toque para preencher'
        : patient.name;
    final ageLabel = patient.age > 0 ? '${patient.age} anos' : '--';
    final weightLabel =
        patient.weightKg > 0 ? '${patient.weightKg.toStringAsFixed(0)} kg' : '--';
    final heightLabel = patient.heightMeters > 0
        ? '${patient.heightMeters.toStringAsFixed(2).replaceAll('.', ',')} m'
        : '--';
    final isPediatric = patient.population == PatientPopulation.pediatric;
    final isNeonatal = patient.population == PatientPopulation.neonatal;
    final populationLabel = patient.population.label;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UiSpace.md),
      decoration: BoxDecoration(
        color: UiColors.surface,
        borderRadius: BorderRadius.circular(UiRadius.lg),
        border: Border.all(color: UiColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17324D),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth >= 1100;

              if (!compact) {
                return Column(
                  children: [
                    _EditableIdentityField(
                      label: 'Nome',
                      value: patientName,
                      onTap: onNameTap,
                    ),
                    const SizedBox(height: UiSpace.xs),
                    Row(
                      children: [
                        Expanded(
                          child: _EditableIdentityField(
                            label: 'Idade',
                            value: ageLabel,
                            onTap: onAgeTap,
                          ),
                        ),
                        const SizedBox(width: UiSpace.xs),
                        Expanded(
                          child: _EditableIdentityField(
                            label: 'Peso',
                            value: weightLabel,
                            onTap: onWeightTap,
                          ),
                        ),
                        const SizedBox(width: UiSpace.xs),
                        Expanded(
                          child: _EditableIdentityField(
                            label: 'Altura',
                            value: heightLabel,
                            onTap: onHeightTap,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _EditableIdentityField(
                      label: 'Nome',
                      value: patientName,
                      onTap: onNameTap,
                    ),
                  ),
                  const SizedBox(width: UiSpace.xs),
                  Expanded(
                    child: _EditableIdentityField(
                      label: 'Idade',
                      value: ageLabel,
                      onTap: onAgeTap,
                    ),
                  ),
                  const SizedBox(width: UiSpace.xs),
                  Expanded(
                    child: _EditableIdentityField(
                      label: 'Peso',
                      value: weightLabel,
                      onTap: onWeightTap,
                    ),
                  ),
                  const SizedBox(width: UiSpace.xs),
                  Expanded(
                    child: _EditableIdentityField(
                      label: 'Altura',
                      value: heightLabel,
                      onTap: onHeightTap,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: UiSpace.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth >= 1100;
              final chips = [
                ClinicalChip(
                  label: 'Perfil',
                  value: populationLabel,
                  color: UiColors.textSecondary,
                  onTap: onPopulationTap,
                ),
                ClinicalChip(
                  label: 'ASA',
                  value:
                      patient.asa.trim().isEmpty ? 'Não definido' : patient.asa,
                  color: UiColors.success,
                  onTap: onAsaTap,
                ),
                ClinicalChip(
                  label: 'Mallampati',
                  value: mallampati.trim().isEmpty
                      ? 'Não informado'
                      : 'Classe $mallampati',
                  color: UiColors.info,
                  onTap: onMallampatiTap,
                ),
                ClinicalChip(
                  label: 'Alergias',
                  value: patient.allergies.isEmpty
                      ? 'Nenhuma'
                      : patient.allergies.join(', '),
                  color: patient.allergies.isEmpty
                      ? UiColors.info
                      : UiColors.danger,
                  onTap: onAllergiesTap,
                ),
                ClinicalChip(
                  label: 'Restrições',
                  value: patient.restrictions.isEmpty
                      ? 'Nenhuma'
                      : patient.restrictions.join(', '),
                  color: patient.restrictions.isEmpty
                      ? UiColors.info
                      : UiColors.warning,
                  onTap: onRestrictionsTap,
                ),
                ClinicalChip(
                  label: 'Medicações',
                  value: patient.medications.isEmpty
                      ? 'Nenhuma'
                      : patient.medications.join(', '),
                  color: UiColors.accent,
                  onTap: onMedicationsTap,
                ),
                if (isPediatric || isNeonatal)
                  ClinicalChip(
                    label: 'Idade pós-natal',
                    value: patient.postnatalAgeDays > 0
                        ? '${patient.postnatalAgeDays} dia(s)'
                        : 'Não informada',
                    color: UiColors.info,
                    onTap: onPostnatalAgeTap,
                  ),
                if (isNeonatal)
                  ClinicalChip(
                    label: 'IG ao nascer',
                    value: patient.gestationalAgeWeeks > 0
                        ? '${patient.gestationalAgeWeeks} sem'
                        : 'Não informada',
                    color: UiColors.warning,
                    onTap: onGestationalAgeTap,
                  ),
                if (isNeonatal)
                  ClinicalChip(
                    label: 'IG corrigida',
                    value: patient.correctedGestationalAgeWeeks > 0
                        ? '${patient.correctedGestationalAgeWeeks} sem'
                        : 'Não informada',
                    color: UiColors.warning,
                    onTap: onCorrectedGestationalAgeTap,
                  ),
                if (isNeonatal)
                  ClinicalChip(
                    label: 'Peso ao nascer',
                    value: patient.birthWeightKg > 0
                        ? '${patient.birthWeightKg.toStringAsFixed(2).replaceAll('.', ',')} kg'
                        : 'Não informado',
                    color: UiColors.accent,
                    onTap: onBirthWeightTap,
                  ),
              ];

              if (!compact) {
                return Wrap(
                  spacing: UiSpace.xs,
                  runSpacing: UiSpace.xs,
                  children: chips,
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    Expanded(child: chips[i]),
                    if (i != chips.length - 1) const SizedBox(width: UiSpace.xs),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EditableIdentityField extends StatelessWidget {
  const _EditableIdentityField({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: UiColors.surfaceMuted,
        borderRadius: BorderRadius.circular(UiRadius.md),
        border: Border.all(color: UiColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: UiColors.info,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: UiColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiRadius.md),
        child: content,
      ),
    );
  }
}

class ClinicalChip extends StatelessWidget {
  const ClinicalChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(UiRadius.md),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: UiColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}
