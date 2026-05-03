class PostAnesthesiaRecovery {
  const PostAnesthesiaRecovery({
    this.admissionTime = '',
    this.dischargeTime = '',
    this.admissionCriteria = const [],
    this.monitoringItems = const [],
    this.dischargeCriteria = const [],
    this.complications = const [],
    this.interventions = const [],
    this.admissionNotes = '',
    this.dischargeNotes = '',
    this.destinationAfterRecovery = '',
    this.painScore = '',
    this.nauseaScore = '',
    this.sedationScale = '',
    this.temperature = '',
    this.aldreteActivity = 0,
    this.aldreteRespiration = 0,
    this.aldreteCirculation = 0,
    this.aldreteConsciousness = 0,
    this.aldreteSpo2 = 0,
  });

  const PostAnesthesiaRecovery.empty()
    : admissionTime = '',
      dischargeTime = '',
      admissionCriteria = const [],
      monitoringItems = const [],
      dischargeCriteria = const [],
      complications = const [],
      interventions = const [],
      admissionNotes = '',
      dischargeNotes = '',
      destinationAfterRecovery = '',
      painScore = '',
      nauseaScore = '',
      sedationScale = '',
      temperature = '',
      aldreteActivity = 0,
      aldreteRespiration = 0,
      aldreteCirculation = 0,
      aldreteConsciousness = 0,
      aldreteSpo2 = 0;

  final String admissionTime;
  final String dischargeTime;
  final List<String> admissionCriteria;
  final List<String> monitoringItems;
  final List<String> dischargeCriteria;
  final List<String> complications;
  final List<String> interventions;
  final String admissionNotes;
  final String dischargeNotes;
  final String destinationAfterRecovery;
  final String painScore;
  final String nauseaScore;
  final String sedationScale;
  final String temperature;
  final int aldreteActivity;
  final int aldreteRespiration;
  final int aldreteCirculation;
  final int aldreteConsciousness;
  final int aldreteSpo2;

  int get aldreteTotal =>
      aldreteActivity +
      aldreteRespiration +
      aldreteCirculation +
      aldreteConsciousness +
      aldreteSpo2;

  bool get hasContent =>
      admissionTime.trim().isNotEmpty ||
      dischargeTime.trim().isNotEmpty ||
      admissionCriteria.isNotEmpty ||
      monitoringItems.isNotEmpty ||
      dischargeCriteria.isNotEmpty ||
      complications.isNotEmpty ||
      interventions.isNotEmpty ||
      admissionNotes.trim().isNotEmpty ||
      dischargeNotes.trim().isNotEmpty ||
      destinationAfterRecovery.trim().isNotEmpty ||
      painScore.trim().isNotEmpty ||
      nauseaScore.trim().isNotEmpty ||
      sedationScale.trim().isNotEmpty ||
      temperature.trim().isNotEmpty ||
      aldreteTotal > 0;

  PostAnesthesiaRecovery copyWith({
    String? admissionTime,
    String? dischargeTime,
    List<String>? admissionCriteria,
    List<String>? monitoringItems,
    List<String>? dischargeCriteria,
    List<String>? complications,
    List<String>? interventions,
    String? admissionNotes,
    String? dischargeNotes,
    String? destinationAfterRecovery,
    String? painScore,
    String? nauseaScore,
    String? sedationScale,
    String? temperature,
    int? aldreteActivity,
    int? aldreteRespiration,
    int? aldreteCirculation,
    int? aldreteConsciousness,
    int? aldreteSpo2,
  }) {
    return PostAnesthesiaRecovery(
      admissionTime: admissionTime ?? this.admissionTime,
      dischargeTime: dischargeTime ?? this.dischargeTime,
      admissionCriteria: admissionCriteria ?? this.admissionCriteria,
      monitoringItems: monitoringItems ?? this.monitoringItems,
      dischargeCriteria: dischargeCriteria ?? this.dischargeCriteria,
      complications: complications ?? this.complications,
      interventions: interventions ?? this.interventions,
      admissionNotes: admissionNotes ?? this.admissionNotes,
      dischargeNotes: dischargeNotes ?? this.dischargeNotes,
      destinationAfterRecovery:
          destinationAfterRecovery ?? this.destinationAfterRecovery,
      painScore: painScore ?? this.painScore,
      nauseaScore: nauseaScore ?? this.nauseaScore,
      sedationScale: sedationScale ?? this.sedationScale,
      temperature: temperature ?? this.temperature,
      aldreteActivity: aldreteActivity ?? this.aldreteActivity,
      aldreteRespiration: aldreteRespiration ?? this.aldreteRespiration,
      aldreteCirculation: aldreteCirculation ?? this.aldreteCirculation,
      aldreteConsciousness: aldreteConsciousness ?? this.aldreteConsciousness,
      aldreteSpo2: aldreteSpo2 ?? this.aldreteSpo2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admissionTime': admissionTime,
      'dischargeTime': dischargeTime,
      'admissionCriteria': admissionCriteria,
      'monitoringItems': monitoringItems,
      'dischargeCriteria': dischargeCriteria,
      'complications': complications,
      'interventions': interventions,
      'admissionNotes': admissionNotes,
      'dischargeNotes': dischargeNotes,
      'destinationAfterRecovery': destinationAfterRecovery,
      'painScore': painScore,
      'nauseaScore': nauseaScore,
      'sedationScale': sedationScale,
      'temperature': temperature,
      'aldreteActivity': aldreteActivity,
      'aldreteRespiration': aldreteRespiration,
      'aldreteCirculation': aldreteCirculation,
      'aldreteConsciousness': aldreteConsciousness,
      'aldreteSpo2': aldreteSpo2,
    };
  }

  factory PostAnesthesiaRecovery.fromJson(Map<dynamic, dynamic> json) {
    return PostAnesthesiaRecovery(
      admissionTime: json['admissionTime'] as String? ?? '',
      dischargeTime: json['dischargeTime'] as String? ?? '',
      admissionCriteria:
          (json['admissionCriteria'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      monitoringItems: (json['monitoringItems'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      dischargeCriteria:
          (json['dischargeCriteria'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      complications: (json['complications'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      interventions: (json['interventions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      admissionNotes: json['admissionNotes'] as String? ?? '',
      dischargeNotes: json['dischargeNotes'] as String? ?? '',
      destinationAfterRecovery:
          json['destinationAfterRecovery'] as String? ?? '',
      painScore: json['painScore'] as String? ?? '',
      nauseaScore: json['nauseaScore'] as String? ?? '',
      sedationScale: json['sedationScale'] as String? ?? '',
      temperature: json['temperature'] as String? ?? '',
      aldreteActivity: json['aldreteActivity'] as int? ?? 0,
      aldreteRespiration: json['aldreteRespiration'] as int? ?? 0,
      aldreteCirculation: json['aldreteCirculation'] as int? ?? 0,
      aldreteConsciousness: json['aldreteConsciousness'] as int? ?? 0,
      aldreteSpo2: json['aldreteSpo2'] as int? ?? 0,
    );
  }
}
