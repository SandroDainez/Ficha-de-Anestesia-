class HemodynamicEntry {
  const HemodynamicEntry({
    required this.time,
    required this.heartRate,
    required this.systolic,
    required this.diastolic,
    required this.spo2,
  });

  final String time;
  final String heartRate;
  final String systolic;
  final String diastolic;
  final String spo2;

  double _parse(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  double get meanArterialPressure {
    final pas = _parse(systolic);
    final pad = _parse(diastolic);
    return (pas + (2 * pad)) / 3;
  }

  String get formattedMeanArterialPressure {
    final pam = meanArterialPressure;
    if (pam <= 0) return '--';
    final number = pam.toStringAsFixed(
      pam.truncateToDouble() == pam ? 0 : 1,
    );
    return '$number mmHg';
  }

  String get formattedBloodPressure {
    if (systolic.trim().isEmpty || diastolic.trim().isEmpty) {
      return '--';
    }
    return '$systolic / $diastolic';
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'heartRate': heartRate,
      'systolic': systolic,
      'diastolic': diastolic,
      'spo2': spo2,
    };
  }

  factory HemodynamicEntry.fromJson(Map<dynamic, dynamic> json) {
    return HemodynamicEntry(
      time: json['time'] as String? ?? '',
      heartRate: json['heartRate'] as String? ?? '',
      systolic: json['systolic'] as String? ?? '',
      diastolic: json['diastolic'] as String? ?? '',
      spo2: json['spo2'] as String? ?? '',
    );
  }
}
