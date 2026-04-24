import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../models/pre_anesthetic_assessment.dart';
import 'ui_tokens.dart';

class TopBarWidget extends StatelessWidget {
  const TopBarWidget({
    super.key,
    required this.onPreAnestheticTap,
    required this.onRecoveryTap,
    required this.caseStage,
    required this.recordStatus,
    required this.highlightMessage,
    required this.preAnestheticDateLabel,
    required this.anesthesiaDateLabel,
    this.onPreAnestheticDateTap,
    this.onAnesthesiaDateTap,
  });

  final VoidCallback onPreAnestheticTap;
  final VoidCallback onRecoveryTap;
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
              FilledButton.icon(
                onPressed: onRecoveryTap,
                style: FilledButton.styleFrom(
                  backgroundColor: UiColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(UiRadius.md),
                  ),
                ),
                icon: const Icon(Icons.local_hospital_outlined, size: 16),
                label: const Text('Abrir RPA'),
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
    required this.preAnestheticAssessment,
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
    this.onInformedConsentTap,
    this.onFunctionalCapacityTap,
    this.onDifficultAirwayTap,
    this.onDifficultVentilationTap,
    this.onFastingTap,
    this.onMallampatiTap,
    this.onAllergiesTap,
    this.onRestrictionsTap,
    this.onMedicationsTap,
  });

  final Patient patient;
  final String mallampati;
  final PreAnestheticAssessment preAnestheticAssessment;
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
  final VoidCallback? onInformedConsentTap;
  final VoidCallback? onFunctionalCapacityTap;
  final VoidCallback? onDifficultAirwayTap;
  final VoidCallback? onDifficultVentilationTap;
  final VoidCallback? onFastingTap;
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
    final weightLabel = patient.weightKg > 0
        ? '${patient.weightKg.toStringAsFixed(0)} kg'
        : '--';
    final heightLabel = patient.heightMeters > 0
        ? '${(patient.heightMeters * 100).toStringAsFixed(0)} cm'
        : '--';
    final isPediatric = patient.population == PatientPopulation.pediatric;
    final isNeonatal = patient.population == PatientPopulation.neonatal;
    final populationLabel = patient.population.label;
    final functionalCapacityLabel = _functionalCapacityValue(
      preAnestheticAssessment,
    );
    final difficultAirwayLabel = _airwayRiskValue(preAnestheticAssessment);
    final difficultVentilationLabel = _ventilationRiskValue(
      preAnestheticAssessment,
    );
    final fastingLabel = _fastingValue(
      preAnestheticAssessment,
      patient.population,
    );

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
              final clinicalChips = [
                ClinicalChip(
                  label: 'Perfil',
                  value: populationLabel,
                  color: _profileColor(patient.population),
                  onTap: onPopulationTap,
                ),
                ClinicalChip(
                  label: 'ASA',
                  value: patient.asa.trim().isEmpty
                      ? 'Não definido'
                      : patient.asa,
                  color: _asaColor(patient.asa),
                  onTap: onAsaTap,
                ),
                ClinicalChip(
                  label: 'Consentimento',
                  value: patient.informedConsentStatus.trim().isEmpty
                      ? 'Não informado'
                      : patient.informedConsentStatus,
                  color: patient.informedConsentStatus.trim() == 'Assinado'
                      ? UiColors.success
                      : patient.informedConsentStatus.trim() == 'Não assinado'
                      ? UiColors.danger
                      : UiColors.warning,
                  onTap: onInformedConsentTap,
                ),
                ClinicalChip(
                  label: 'METS / funcional',
                  value: functionalCapacityLabel,
                  color: _functionalCapacityColor(preAnestheticAssessment),
                  onTap: onFunctionalCapacityTap,
                ),
                ClinicalChip(
                  label: 'Via aérea difícil',
                  value: difficultAirwayLabel,
                  color: _airwayRiskColor(preAnestheticAssessment),
                  onTap: onDifficultAirwayTap,
                ),
                ClinicalChip(
                  label: 'Ventilação difícil',
                  value: difficultVentilationLabel,
                  color: _ventilationRiskColor(preAnestheticAssessment),
                  onTap: onDifficultVentilationTap,
                ),
                ClinicalChip(
                  label: 'Jejum',
                  value: fastingLabel,
                  color: _fastingColor(
                    preAnestheticAssessment,
                    patient.population,
                  ),
                  onTap: onFastingTap,
                ),
                if (patient.population == PatientPopulation.adult)
                  ClinicalChip(
                    label: 'Mallampati',
                    value: mallampati.trim().isEmpty
                        ? 'Não informado'
                        : 'Classe $mallampati',
                    color: _mallampatiColor(mallampati),
                    onTap: onMallampatiTap,
                  ),
                ClinicalChip(
                  label: 'Alergias',
                  value: patient.allergies.isEmpty
                      ? 'Nenhuma'
                      : patient.allergies.join(', '),
                  color: _allergiesColor(patient),
                  onTap: onAllergiesTap,
                ),
                ClinicalChip(
                  label: 'Restrições',
                  value: patient.restrictions.isEmpty
                      ? 'Nenhuma'
                      : patient.restrictions.join(', '),
                  color: _restrictionsColor(patient),
                  onTap: onRestrictionsTap,
                ),
                ClinicalChip(
                  label: 'Medicações',
                  value: patient.medications.isEmpty
                      ? 'Nenhuma'
                      : patient.medications.join(', '),
                  color: _medicationsColor(patient),
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

              return Wrap(
                spacing: UiSpace.xs,
                runSpacing: UiSpace.xs,
                children: clinicalChips
                    .map(
                      (clinicalChip) => ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 150,
                          maxWidth: 230,
                        ),
                        child: clinicalChip,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  static Color _asaColor(String asa) {
    final normalized = asa.trim().toUpperCase();
    if (normalized == 'III' ||
        normalized == 'IV' ||
        normalized == 'V' ||
        normalized == 'VI') {
      return UiColors.danger;
    }
    if (normalized.isEmpty) return UiColors.warning;
    return UiColors.success;
  }

  static Color _profileColor(PatientPopulation population) {
    return population.label.trim().isEmpty
        ? UiColors.warning
        : UiColors.success;
  }

  static String _functionalCapacityValue(PreAnestheticAssessment assessment) {
    final value = assessment.mets.trim();
    return value.isEmpty ? 'Não informado' : value;
  }

  static Color _functionalCapacityColor(PreAnestheticAssessment assessment) {
    final value = assessment.mets.trim().toLowerCase();
    if (value.isEmpty) return UiColors.warning;
    if (value.contains('1 met') ||
        value.contains('2-3 mets') ||
        value.contains('limitação importante') ||
        value.contains('apneia/bradicardia') ||
        value.contains('suporte ventilatório')) {
      return UiColors.danger;
    }
    if (value.contains('limitação leve') ||
        value.contains('oxigênio recente')) {
      return UiColors.warning;
    }
    return UiColors.success;
  }

  static String _airwayRiskValue(PreAnestheticAssessment assessment) {
    final predictors = assessment.difficultAirwayPredictors;
    final other = assessment.otherDifficultAirwayPredictors.trim();
    if (predictors.isEmpty && other.isEmpty) return 'Sem alerta';

    final segments = <String>[
      if (predictors.isNotEmpty) predictors.take(2).join(', '),
      if (predictors.length > 2) '+${predictors.length - 2} itens',
      if (other.isNotEmpty) other,
    ];
    return segments.join(' • ');
  }

  static Color _airwayRiskColor(PreAnestheticAssessment assessment) {
    final hasRisk =
        assessment.difficultAirwayPredictors.isNotEmpty ||
        assessment.otherDifficultAirwayPredictors.trim().isNotEmpty;
    return hasRisk ? UiColors.danger : UiColors.info;
  }

  static String _ventilationRiskValue(PreAnestheticAssessment assessment) {
    final predictors = assessment.difficultVentilationPredictors;
    final other = assessment.otherDifficultVentilationPredictors.trim();
    if (predictors.isEmpty && other.isEmpty) return 'Sem alerta';

    final segments = <String>[
      if (predictors.isNotEmpty) predictors.take(2).join(', '),
      if (predictors.length > 2) '+${predictors.length - 2} itens',
      if (other.isNotEmpty) other,
    ];
    return segments.join(' • ');
  }

  static Color _ventilationRiskColor(PreAnestheticAssessment assessment) {
    final hasRisk =
        assessment.difficultVentilationPredictors.isNotEmpty ||
        assessment.otherDifficultVentilationPredictors.trim().isNotEmpty;
    return hasRisk ? UiColors.danger : UiColors.info;
  }

  static String _fastingValue(
    PreAnestheticAssessment assessment,
    PatientPopulation population,
  ) {
    final solids = assessment.fastingSolids.trim();
    final liquids = assessment.fastingLiquids.trim();
    final breastMilk = assessment.fastingBreastMilk.trim();
    final notes = assessment.fastingNotes.trim();
    final segments = <String>[
      if (solids.isNotEmpty)
        population == PatientPopulation.adult
            ? 'Sólidos $solids'
            : 'Fórmula/refeição $solids',
      if (breastMilk.isNotEmpty) 'Leite materno $breastMilk',
      if (liquids.isNotEmpty) 'Líquidos $liquids',
      if (notes.isNotEmpty) notes,
    ];
    return segments.isEmpty ? 'Não informado' : segments.join(' • ');
  }

  static Color _fastingColor(
    PreAnestheticAssessment assessment,
    PatientPopulation population,
  ) {
    final solids = assessment.fastingSolids.trim().toLowerCase();
    final liquids = assessment.fastingLiquids.trim().toLowerCase();
    final breastMilk = assessment.fastingBreastMilk.trim().toLowerCase();
    final notes = assessment.fastingNotes.trim().toLowerCase();
    final highRisk =
        solids.startsWith('<') ||
        liquids.startsWith('<') ||
        breastMilk.startsWith('<') ||
        notes.contains('inadequado') ||
        notes.contains('não adequado') ||
        notes.contains('nao adequado');

    if (highRisk) return UiColors.danger;
    if (solids.isEmpty &&
        liquids.isEmpty &&
        (population == PatientPopulation.adult || breastMilk.isEmpty) &&
        notes.isEmpty) {
      return UiColors.warning;
    }
    return UiColors.success;
  }

  static Color _mallampatiColor(String mallampati) {
    final normalized = mallampati.trim().toUpperCase();
    if (normalized.isEmpty) return UiColors.warning;
    if (normalized == 'III' || normalized == 'IV') return UiColors.danger;
    if (normalized == 'I' || normalized == 'II') return UiColors.success;
    return UiColors.warning;
  }

  static Color _allergiesColor(Patient patient) {
    return patient.allergies.isEmpty ? UiColors.info : UiColors.danger;
  }

  static Color _restrictionsColor(Patient patient) {
    return patient.restrictions.isEmpty ? UiColors.info : UiColors.danger;
  }

  static Color _medicationsColor(Patient patient) {
    return patient.medications.isEmpty ? UiColors.warning : UiColors.success;
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
