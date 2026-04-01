import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/anesthesia_case.dart';
import '../models/anesthesia_record.dart';

class RecordStorageService {
  RecordStorageService();

  static const String _boxName = 'anesthesia_record_box';
  static const String _legacyRecordKey = 'current_record';
  static const String _casesKey = 'saved_cases';

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      Hive.init(directory.path);
    } catch (_) {
      Hive.init(Directory.systemTemp.path);
    }

    _initialized = true;
  }

  Future<Box<dynamic>> _openBox() async {
    await _ensureInitialized();
    return Hive.openBox<dynamic>(_boxName);
  }

  String createCaseId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<List<AnesthesiaCase>> loadCases() async {
    final box = await _openBox();
    final rawCases = box.get(_casesKey);
    final cases = <AnesthesiaCase>[];

    if (rawCases is List) {
      for (final item in rawCases) {
        if (item is Map) {
          cases.add(AnesthesiaCase.fromJson(Map<dynamic, dynamic>.from(item)));
        }
      }
    }

    if (cases.isNotEmpty) {
      cases.sort((a, b) => b.updatedAtIso.compareTo(a.updatedAtIso));
      return cases;
    }

    final legacy = box.get(_legacyRecordKey);
    if (legacy is! Map) return const [];

    final migratedRecord = AnesthesiaRecord.fromJson(
      Map<dynamic, dynamic>.from(legacy),
    );
    final now = DateTime.now().toIso8601String();
    final migratedCase = AnesthesiaCase(
      id: createCaseId(),
      createdAtIso: now,
      updatedAtIso: now,
      preAnestheticDate: '',
      anesthesiaDate: '',
      status: _inferStatus(migratedRecord),
      record: migratedRecord,
    );
    await saveCases([migratedCase]);
    await box.delete(_legacyRecordKey);
    return [migratedCase];
  }

  Future<void> saveCases(List<AnesthesiaCase> cases) async {
    final box = await _openBox();
    final raw = cases.map((item) => item.toJson()).toList();
    await box.put(_casesKey, raw);
  }

  Future<AnesthesiaCase?> loadCase(String caseId) async {
    final cases = await loadCases();
    for (final item in cases) {
      if (item.id == caseId) return item;
    }
    return null;
  }

  Future<void> upsertCase(AnesthesiaCase caseFile) async {
    final cases = await loadCases();
    final updated = List<AnesthesiaCase>.from(cases);
    final index = updated.indexWhere((item) => item.id == caseFile.id);
    if (index >= 0) {
      updated[index] = caseFile;
    } else {
      updated.add(caseFile);
    }
    updated.sort((a, b) => b.updatedAtIso.compareTo(a.updatedAtIso));
    await saveCases(updated);
  }

  Future<void> deleteCase(String caseId) async {
    final cases = await loadCases();
    final updated = cases.where((item) => item.id != caseId).toList();
    await saveCases(updated);
  }

  Future<AnesthesiaRecord?> loadRecord() async {
    final cases = await loadCases();
    if (cases.isEmpty) return null;

    final active = cases.firstWhere(
      (item) => item.status != AnesthesiaCaseStatus.finalized,
      orElse: () => cases.first,
    );
    return active.record;
  }

  Future<void> saveRecord(AnesthesiaRecord record) async {
    final now = DateTime.now().toIso8601String();
    final caseFile = AnesthesiaCase(
      id: createCaseId(),
      createdAtIso: now,
      updatedAtIso: now,
      preAnestheticDate: '',
      anesthesiaDate: '',
      status: _inferStatus(record),
      record: record,
    );
    await upsertCase(caseFile);
  }

  AnesthesiaCaseStatus _inferStatus(AnesthesiaRecord record) {
    final hasPreAnesthetic =
        record.preAnestheticAssessment.asaClassification.trim().isNotEmpty ||
        record.preAnestheticAssessment.anestheticPlan.trim().isNotEmpty ||
        record.preAnestheticAssessment.comorbidities.isNotEmpty ||
        record.preAnestheticAssessment.currentMedications.isNotEmpty ||
        record.preAnestheticAssessment.allergyDescription.trim().isNotEmpty;

    final hasIntraoperativeContent =
        record.surgeryDescription.trim().isNotEmpty ||
        record.surgeonName.trim().isNotEmpty ||
        record.airway.device.trim().isNotEmpty ||
        record.anesthesiaTechnique.trim().isNotEmpty ||
        record.drugs.isNotEmpty ||
        record.events.isNotEmpty ||
        record.hemodynamicMarkers.isNotEmpty ||
        record.hemodynamicPoints.isNotEmpty;

    if (hasIntraoperativeContent) return AnesthesiaCaseStatus.inProgress;
    if (hasPreAnesthetic) return AnesthesiaCaseStatus.preAnesthetic;
    return AnesthesiaCaseStatus.inProgress;
  }
}
