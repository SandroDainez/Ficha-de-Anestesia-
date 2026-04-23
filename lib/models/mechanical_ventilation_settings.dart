class MechanicalVentilationSettings {
  const MechanicalVentilationSettings({
    required this.mode,
    this.fio2Percent = '',
    this.tidalVolumeMl = '',
    this.tidalVolumePerKg = '',
    this.respiratoryRate = '',
    this.peep = '',
    this.inspiratoryPressure = '',
    this.pressureSupport = '',
    this.ieRatio = '',
    this.targetEtco2 = '',
    this.notes = '',
  });

  const MechanicalVentilationSettings.empty()
    : mode = '',
      fio2Percent = '',
      tidalVolumeMl = '',
      tidalVolumePerKg = '',
      respiratoryRate = '',
      peep = '',
      inspiratoryPressure = '',
      pressureSupport = '',
      ieRatio = '',
      targetEtco2 = '',
      notes = '';

  final String mode;
  final String fio2Percent;
  final String tidalVolumeMl;
  final String tidalVolumePerKg;
  final String respiratoryRate;
  final String peep;
  final String inspiratoryPressure;
  final String pressureSupport;
  final String ieRatio;
  final String targetEtco2;
  final String notes;

  bool get isEmpty =>
      mode.trim().isEmpty &&
      fio2Percent.trim().isEmpty &&
      tidalVolumeMl.trim().isEmpty &&
      tidalVolumePerKg.trim().isEmpty &&
      respiratoryRate.trim().isEmpty &&
      peep.trim().isEmpty &&
      inspiratoryPressure.trim().isEmpty &&
      pressureSupport.trim().isEmpty &&
      ieRatio.trim().isEmpty &&
      targetEtco2.trim().isEmpty &&
      notes.trim().isEmpty;

  MechanicalVentilationSettings copyWith({
    String? mode,
    String? fio2Percent,
    String? tidalVolumeMl,
    String? tidalVolumePerKg,
    String? respiratoryRate,
    String? peep,
    String? inspiratoryPressure,
    String? pressureSupport,
    String? ieRatio,
    String? targetEtco2,
    String? notes,
  }) {
    return MechanicalVentilationSettings(
      mode: mode ?? this.mode,
      fio2Percent: fio2Percent ?? this.fio2Percent,
      tidalVolumeMl: tidalVolumeMl ?? this.tidalVolumeMl,
      tidalVolumePerKg: tidalVolumePerKg ?? this.tidalVolumePerKg,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      peep: peep ?? this.peep,
      inspiratoryPressure: inspiratoryPressure ?? this.inspiratoryPressure,
      pressureSupport: pressureSupport ?? this.pressureSupport,
      ieRatio: ieRatio ?? this.ieRatio,
      targetEtco2: targetEtco2 ?? this.targetEtco2,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'fio2Percent': fio2Percent,
      'tidalVolumeMl': tidalVolumeMl,
      'tidalVolumePerKg': tidalVolumePerKg,
      'respiratoryRate': respiratoryRate,
      'peep': peep,
      'inspiratoryPressure': inspiratoryPressure,
      'pressureSupport': pressureSupport,
      'ieRatio': ieRatio,
      'targetEtco2': targetEtco2,
      'notes': notes,
    };
  }

  factory MechanicalVentilationSettings.fromJson(Map<dynamic, dynamic> json) {
    return MechanicalVentilationSettings(
      mode: json['mode'] as String? ?? '',
      fio2Percent: json['fio2Percent'] as String? ?? '',
      tidalVolumeMl: json['tidalVolumeMl'] as String? ?? '',
      tidalVolumePerKg: json['tidalVolumePerKg'] as String? ?? '',
      respiratoryRate: json['respiratoryRate'] as String? ?? '',
      peep: json['peep'] as String? ?? '',
      inspiratoryPressure: json['inspiratoryPressure'] as String? ?? '',
      pressureSupport: json['pressureSupport'] as String? ?? '',
      ieRatio: json['ieRatio'] as String? ?? '',
      targetEtco2: json['targetEtco2'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}
