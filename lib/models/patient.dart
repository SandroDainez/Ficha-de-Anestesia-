enum PatientPopulation { adult, pediatric, neonatal }

extension PatientPopulationX on PatientPopulation {
  String get code => switch (this) {
    PatientPopulation.adult => 'adult',
    PatientPopulation.pediatric => 'pediatric',
    PatientPopulation.neonatal => 'neonatal',
  };

  String get label => switch (this) {
    PatientPopulation.adult => 'Adulto',
    PatientPopulation.pediatric => 'Pediátrico',
    PatientPopulation.neonatal => 'Neonatal',
  };

  static PatientPopulation fromCode(String? code) => switch (code) {
    'pediatric' => PatientPopulation.pediatric,
    'neonatal' => PatientPopulation.neonatal,
    _ => PatientPopulation.adult,
  };
}

class Patient {
  const Patient({
    required this.name,
    required this.age,
    required this.weightKg,
    required this.heightMeters,
    required this.asa,
    required this.allergies,
    required this.restrictions,
    required this.medications,
    this.informedConsentStatus = '',
    this.population = PatientPopulation.adult,
    this.postnatalAgeDays = 0,
    this.gestationalAgeWeeks = 0,
    this.correctedGestationalAgeWeeks = 0,
    this.birthWeightKg = 0,
    this.allergiesMarkedNone = false,
    this.restrictionsMarkedNone = false,
    this.medicationsMarkedNone = false,
  });

  const Patient.empty()
    : name = '',
      age = 0,
      weightKg = 0,
      heightMeters = 0,
      asa = '',
      allergies = const [],
      restrictions = const [],
      medications = const [],
      informedConsentStatus = '',
      population = PatientPopulation.adult,
      postnatalAgeDays = 0,
      gestationalAgeWeeks = 0,
      correctedGestationalAgeWeeks = 0,
      birthWeightKg = 0,
      allergiesMarkedNone = false,
      restrictionsMarkedNone = false,
      medicationsMarkedNone = false;

  final String name;
  final int age;
  final double weightKg;
  final double heightMeters;
  final String asa;
  final List<String> allergies;
  final List<String> restrictions;
  final List<String> medications;
  final String informedConsentStatus;
  final PatientPopulation population;
  final int postnatalAgeDays;
  final int gestationalAgeWeeks;
  final int correctedGestationalAgeWeeks;
  final double birthWeightKg;
  final bool allergiesMarkedNone;
  final bool restrictionsMarkedNone;
  final bool medicationsMarkedNone;

  Patient copyWith({
    String? name,
    int? age,
    double? weightKg,
    double? heightMeters,
    String? asa,
    List<String>? allergies,
    List<String>? restrictions,
    List<String>? medications,
    String? informedConsentStatus,
    PatientPopulation? population,
    int? postnatalAgeDays,
    int? gestationalAgeWeeks,
    int? correctedGestationalAgeWeeks,
    double? birthWeightKg,
    bool? allergiesMarkedNone,
    bool? restrictionsMarkedNone,
    bool? medicationsMarkedNone,
  }) {
    return Patient(
      name: name ?? this.name,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightMeters: heightMeters ?? this.heightMeters,
      asa: asa ?? this.asa,
      allergies: allergies ?? this.allergies,
      restrictions: restrictions ?? this.restrictions,
      medications: medications ?? this.medications,
      informedConsentStatus:
          informedConsentStatus ?? this.informedConsentStatus,
      population: population ?? this.population,
      postnatalAgeDays: postnatalAgeDays ?? this.postnatalAgeDays,
      gestationalAgeWeeks: gestationalAgeWeeks ?? this.gestationalAgeWeeks,
      correctedGestationalAgeWeeks:
          correctedGestationalAgeWeeks ?? this.correctedGestationalAgeWeeks,
      birthWeightKg: birthWeightKg ?? this.birthWeightKg,
      allergiesMarkedNone: allergiesMarkedNone ?? this.allergiesMarkedNone,
      restrictionsMarkedNone:
          restrictionsMarkedNone ?? this.restrictionsMarkedNone,
      medicationsMarkedNone:
          medicationsMarkedNone ?? this.medicationsMarkedNone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'weightKg': weightKg,
      'heightMeters': heightMeters,
      'asa': asa,
      'allergies': allergies,
      'restrictions': restrictions,
      'medications': medications,
      'informedConsentStatus': informedConsentStatus,
      'population': population.code,
      'postnatalAgeDays': postnatalAgeDays,
      'gestationalAgeWeeks': gestationalAgeWeeks,
      'correctedGestationalAgeWeeks': correctedGestationalAgeWeeks,
      'birthWeightKg': birthWeightKg,
      'allergiesMarkedNone': allergiesMarkedNone,
      'restrictionsMarkedNone': restrictionsMarkedNone,
      'medicationsMarkedNone': medicationsMarkedNone,
    };
  }

  factory Patient.fromJson(Map<dynamic, dynamic> json) {
    return Patient(
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      weightKg: (json['weightKg'] as num? ?? 0).toDouble(),
      heightMeters: (json['heightMeters'] as num? ?? 0).toDouble(),
      asa: json['asa'] as String? ?? '',
      allergies: (json['allergies'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      restrictions: (json['restrictions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      medications: (json['medications'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      informedConsentStatus: json['informedConsentStatus'] as String? ?? '',
      population: PatientPopulationX.fromCode(json['population'] as String?),
      postnatalAgeDays: json['postnatalAgeDays'] as int? ?? 0,
      gestationalAgeWeeks: json['gestationalAgeWeeks'] as int? ?? 0,
      correctedGestationalAgeWeeks:
          json['correctedGestationalAgeWeeks'] as int? ?? 0,
      birthWeightKg: (json['birthWeightKg'] as num? ?? 0).toDouble(),
      allergiesMarkedNone: json['allergiesMarkedNone'] as bool? ?? false,
      restrictionsMarkedNone: json['restrictionsMarkedNone'] as bool? ?? false,
      medicationsMarkedNone: json['medicationsMarkedNone'] as bool? ?? false,
    );
  }
}
