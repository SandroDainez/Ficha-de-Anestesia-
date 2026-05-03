import 'anesthesia_record.dart';

enum AnesthesiaCaseStatus { preAnesthetic, inProgress, finalized }

extension AnesthesiaCaseStatusX on AnesthesiaCaseStatus {
  String get code => switch (this) {
    AnesthesiaCaseStatus.preAnesthetic => 'pre_anesthetic',
    AnesthesiaCaseStatus.inProgress => 'in_progress',
    AnesthesiaCaseStatus.finalized => 'finalized',
  };

  String get label => switch (this) {
    AnesthesiaCaseStatus.preAnesthetic => 'Pré-anestésico salvo',
    AnesthesiaCaseStatus.inProgress => 'Em andamento',
    AnesthesiaCaseStatus.finalized => 'Finalizado',
  };

  static AnesthesiaCaseStatus fromCode(String? code) => switch (code) {
    'pre_anesthetic' => AnesthesiaCaseStatus.preAnesthetic,
    'finalized' => AnesthesiaCaseStatus.finalized,
    _ => AnesthesiaCaseStatus.inProgress,
  };
}

class AnesthesiaCase {
  const AnesthesiaCase({
    required this.id,
    required this.createdAtIso,
    required this.updatedAtIso,
    required this.preAnestheticDate,
    required this.anesthesiaDate,
    required this.status,
    required this.record,
  });

  final String id;
  final String createdAtIso;
  final String updatedAtIso;
  final String preAnestheticDate;
  final String anesthesiaDate;
  final AnesthesiaCaseStatus status;
  final AnesthesiaRecord record;

  String get displayName {
    final name = record.patient.name.trim();
    if (name.isNotEmpty) return name;
    return 'Paciente sem identificação';
  }

  AnesthesiaCase copyWith({
    String? id,
    String? createdAtIso,
    String? updatedAtIso,
    String? preAnestheticDate,
    String? anesthesiaDate,
    AnesthesiaCaseStatus? status,
    AnesthesiaRecord? record,
  }) {
    return AnesthesiaCase(
      id: id ?? this.id,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      preAnestheticDate: preAnestheticDate ?? this.preAnestheticDate,
      anesthesiaDate: anesthesiaDate ?? this.anesthesiaDate,
      status: status ?? this.status,
      record: record ?? this.record,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAtIso': createdAtIso,
      'updatedAtIso': updatedAtIso,
      'preAnestheticDate': preAnestheticDate,
      'anesthesiaDate': anesthesiaDate,
      'status': status.code,
      'record': record.toJson(),
    };
  }

  factory AnesthesiaCase.fromJson(Map<dynamic, dynamic> json) {
    return AnesthesiaCase(
      id: json['id'] as String? ?? '',
      createdAtIso: json['createdAtIso'] as String? ?? '',
      updatedAtIso: json['updatedAtIso'] as String? ?? '',
      preAnestheticDate: json['preAnestheticDate'] as String? ?? '',
      anesthesiaDate: json['anesthesiaDate'] as String? ?? '',
      status: AnesthesiaCaseStatusX.fromCode(json['status'] as String?),
      record: AnesthesiaRecord.fromJson(
        json['record'] as Map<dynamic, dynamic>? ?? const {},
      ),
    );
  }
}
