class FluidBalance {
  const FluidBalance({
    required this.crystalloids,
    required this.colloids,
    required this.blood,
    required this.diuresis,
    required this.bleeding,
    required this.spongeCount,
    required this.otherLosses,
    this.crystalloidEntries = const [],
    this.colloidEntries = const [],
  });

  const FluidBalance.empty()
      : crystalloids = '',
        colloids = '',
        blood = '',
        diuresis = '',
        bleeding = '',
        spongeCount = '',
        otherLosses = '',
        crystalloidEntries = const [],
        colloidEntries = const [];

  final String crystalloids;
  final String colloids;
  final String blood;
  final String diuresis;
  final String bleeding;
  final String spongeCount;
  final String otherLosses;
  final List<String> crystalloidEntries;
  final List<String> colloidEntries;

  bool get isComplete =>
      crystalloids.trim().isNotEmpty &&
      blood.trim().isNotEmpty &&
      diuresis.trim().isNotEmpty &&
      bleeding.trim().isNotEmpty;

  double _parse(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  double get estimatedSpongeLoss =>
      _parse(spongeCount) * 100;

  double get totalBalance =>
      (_parse(crystalloids) + _parse(colloids) + _parse(blood)) -
      (_parse(diuresis) +
          _parse(bleeding) +
          estimatedSpongeLoss +
          _parse(otherLosses));

  String get formattedBalance {
    final prefix = totalBalance >= 0 ? '+' : '-';
    final abs = totalBalance.abs();
    final number = abs.toStringAsFixed(abs.truncateToDouble() == abs ? 0 : 1);
    return '$prefix$number mL';
  }

  FluidBalance copyWith({
    String? crystalloids,
    String? colloids,
    String? blood,
    String? diuresis,
    String? bleeding,
    String? spongeCount,
    String? otherLosses,
    List<String>? crystalloidEntries,
    List<String>? colloidEntries,
  }) {
    return FluidBalance(
      crystalloids: crystalloids ?? this.crystalloids,
      colloids: colloids ?? this.colloids,
      blood: blood ?? this.blood,
      diuresis: diuresis ?? this.diuresis,
      bleeding: bleeding ?? this.bleeding,
      spongeCount: spongeCount ?? this.spongeCount,
      otherLosses: otherLosses ?? this.otherLosses,
      crystalloidEntries: crystalloidEntries ?? this.crystalloidEntries,
      colloidEntries: colloidEntries ?? this.colloidEntries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crystalloids': crystalloids,
      'colloids': colloids,
      'blood': blood,
      'diuresis': diuresis,
      'bleeding': bleeding,
      'spongeCount': spongeCount,
      'otherLosses': otherLosses,
      'crystalloidEntries': crystalloidEntries,
      'colloidEntries': colloidEntries,
    };
  }

  factory FluidBalance.fromJson(Map<dynamic, dynamic> json) {
    return FluidBalance(
      crystalloids: json['crystalloids'] as String? ?? '',
      colloids: json['colloids'] as String? ?? '',
      blood: json['blood'] as String? ?? '',
      diuresis: json['diuresis'] as String? ?? '',
      bleeding: json['bleeding'] as String? ?? '',
      spongeCount: json['spongeCount'] as String? ?? '',
      otherLosses: json['otherLosses'] as String? ?? '',
      crystalloidEntries:
          (json['crystalloidEntries'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      colloidEntries: (json['colloidEntries'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}
