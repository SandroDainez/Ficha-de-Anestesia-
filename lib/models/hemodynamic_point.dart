class HemodynamicPoint {
  const HemodynamicPoint({
    required this.type,
    required this.value,
    required this.time,
  });

  final String type;
  final double value;
  final double time;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'time': time,
    };
  }

  factory HemodynamicPoint.fromJson(Map<dynamic, dynamic> json) {
    return HemodynamicPoint(
      type: json['type'] as String? ?? '',
      value: (json['value'] as num? ?? 0).toDouble(),
      time: (json['time'] as num? ?? 0).toDouble(),
    );
  }
}

class HemodynamicMarker {
  const HemodynamicMarker({
    required this.label,
    required this.time,
    this.clockTime = '',
    this.recordedAtIso = '',
  });

  final String label;
  final double time;
  final String clockTime;
  final String recordedAtIso;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'time': time,
      'clockTime': clockTime,
      'recordedAtIso': recordedAtIso,
    };
  }

  factory HemodynamicMarker.fromJson(Map<dynamic, dynamic> json) {
    return HemodynamicMarker(
      label: json['label'] as String? ?? '',
      time: (json['time'] as num? ?? 0).toDouble(),
      clockTime: json['clockTime'] as String? ?? '',
      recordedAtIso: json['recordedAtIso'] as String? ?? '',
    );
  }
}
