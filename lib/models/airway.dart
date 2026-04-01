class Airway {
  const Airway({
    required this.mallampati,
    required this.cormackLehane,
    required this.device,
    required this.tubeNumber,
    required this.technique,
    required this.observation,
  });

  const Airway.empty()
      : mallampati = '',
        cormackLehane = '',
        device = '',
        tubeNumber = '',
        technique = '',
        observation = '';

  final String mallampati;
  final String cormackLehane;
  final String device;
  final String tubeNumber;
  final String technique;
  final String observation;

  bool get isComplete =>
      mallampati.trim().isNotEmpty &&
      device.trim().isNotEmpty &&
      tubeNumber.trim().isNotEmpty &&
      technique.trim().isNotEmpty;

  Airway copyWith({
    String? mallampati,
    String? cormackLehane,
    String? device,
    String? tubeNumber,
    String? technique,
    String? observation,
  }) {
    return Airway(
      mallampati: mallampati ?? this.mallampati,
      cormackLehane: cormackLehane ?? this.cormackLehane,
      device: device ?? this.device,
      tubeNumber: tubeNumber ?? this.tubeNumber,
      technique: technique ?? this.technique,
      observation: observation ?? this.observation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mallampati': mallampati,
      'cormackLehane': cormackLehane,
      'device': device,
      'tubeNumber': tubeNumber,
      'technique': technique,
      'observation': observation,
    };
  }

  factory Airway.fromJson(Map<dynamic, dynamic> json) {
    return Airway(
      mallampati: json['mallampati'] as String? ?? '',
      cormackLehane: json['cormackLehane'] as String? ?? '',
      device: json['device'] as String? ?? '',
      tubeNumber: json['tubeNumber'] as String? ?? '',
      technique: json['technique'] as String? ?? '',
      observation: json['observation'] as String? ?? '',
    );
  }
}
