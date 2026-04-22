import 'package:anestesia_app/models/anesthesia_case.dart';
import 'package:anestesia_app/models/anesthesia_record.dart';
import 'package:anestesia_app/models/patient.dart';
import 'package:anestesia_app/services/record_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('upserts and restores a saved case with monitoring and accesses', () async {
    final service = RecordStorageService();
    final now = DateTime.now().toIso8601String();
    final caseId = service.createCaseId();

    final caseFile = AnesthesiaCase(
      id: caseId,
      createdAtIso: now,
      updatedAtIso: now,
      preAnestheticDate: '',
      anesthesiaDate: '',
      status: AnesthesiaCaseStatus.inProgress,
      record: AnesthesiaRecord.empty().copyWith(
        venousAccesses: const ['Jelco 18G MSD'],
        arterialAccesses: const ['PAI - radial esquerda'],
        monitoringItems: const ['ECG (5 derivações)', 'SpO₂'],
      ),
    );

    await service.upsertCase(caseFile);

    final restored = await service.loadCase(caseId);

    expect(restored, isNotNull);
    expect(restored!.record.venousAccesses, ['Jelco 18G MSD']);
    expect(restored.record.arterialAccesses, ['PAI - radial esquerda']);
    expect(restored.record.monitoringItems, ['ECG (5 derivações)', 'SpO₂']);
  });

  test('merges local and remote cases and keeps the newest version by id', () {
    final localOlder = AnesthesiaCase(
      id: 'same-case',
      createdAtIso: '2026-04-18T10:00:00.000',
      updatedAtIso: '2026-04-18T10:00:00.000',
      preAnestheticDate: '18/04/2026 10:00',
      anesthesiaDate: '',
      status: AnesthesiaCaseStatus.preAnesthetic,
      record: AnesthesiaRecord.empty().copyWith(
        patient: const Patient(
          name: 'Jose da Silva',
          age: 63,
          weightKg: 78,
          heightMeters: 1.72,
          asa: 'II',
          allergies: [],
          restrictions: [],
          medications: [],
        ),
      ),
    );

    final remoteNewer = localOlder.copyWith(
      updatedAtIso: '2026-04-21T08:30:00.000',
      anesthesiaDate: '21/04/2026 08:30',
      status: AnesthesiaCaseStatus.inProgress,
    );

    final remoteOnly = AnesthesiaCase(
      id: 'remote-only',
      createdAtIso: '2026-04-22T07:00:00.000',
      updatedAtIso: '2026-04-22T07:00:00.000',
      preAnestheticDate: '22/04/2026 07:00',
      anesthesiaDate: '',
      status: AnesthesiaCaseStatus.preAnesthetic,
      record: AnesthesiaRecord.empty().copyWith(
        patient: const Patient(
          name: 'Maria Souza',
          age: 42,
          weightKg: 64,
          heightMeters: 1.60,
          asa: 'I',
          allergies: [],
          restrictions: [],
          medications: [],
        ),
      ),
    );

    final merged = mergeStoredCases(
      localCases: [localOlder],
      remoteCases: [remoteNewer, remoteOnly],
    );

    expect(merged, hasLength(2));
    expect(merged.first.id, 'remote-only');
    expect(merged.last.id, 'same-case');
    expect(merged.last.status, AnesthesiaCaseStatus.inProgress);
    expect(merged.last.anesthesiaDate, '21/04/2026 08:30');
  });
}
