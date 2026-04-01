import 'package:anestesia_app/models/anesthesia_case.dart';
import 'package:anestesia_app/models/anesthesia_record.dart';
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
}
