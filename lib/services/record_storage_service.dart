import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';
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
    if (kIsWeb) {
      _initialized = true;
      return;
    }

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
    Box<dynamic>? box;
    final cases = <AnesthesiaCase>[];

    if (!kIsWeb) {
      try {
        box = await _openBox();
        final rawCases = box.get(_casesKey);

        if (rawCases is List) {
          for (final item in rawCases) {
            if (item is Map) {
              cases.add(
                AnesthesiaCase.fromJson(Map<dynamic, dynamic>.from(item)),
              );
            }
          }
        }
      } catch (_) {
        // ignore local storage failure and fall back to remote when available
      }
    }

    if (cases.isNotEmpty) {
      cases.sort((a, b) => b.updatedAtIso.compareTo(a.updatedAtIso));
      return cases;
    }

    if (await _ensureRemote()) {
      final remoteCases = await _loadCasesRemote();
      if (remoteCases.isNotEmpty) return remoteCases;
    }

    if (kIsWeb || box == null) return const [];

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
    if (kIsWeb) return;
    final box = await _openBox();
    final raw = cases.map((item) => item.toJson()).toList();
    await box.put(_casesKey, raw);
  }

  Future<AnesthesiaCase?> loadCase(String caseId) async {
    if (await _ensureRemote()) {
      try {
        final response = await _client!
            .from('anesthesia_cases')
            .select()
            .eq('id', caseId)
            .maybeSingle();
        if (response != null) {
          return _mapCase(response as Map<String, dynamic>);
        }
      } catch (_) {
        // fallback to local storage
      }
    }
    if (kIsWeb) return null;

    final cases = await loadCases();
    return cases.firstWhereOrNull((item) => item.id == caseId);
  }

  Future<void> upsertCase(AnesthesiaCase caseFile) async {
    if (await _ensureRemote()) {
      await _upsertRemoteCase(caseFile);
    }
    if (kIsWeb) return;
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
    if (await _ensureRemote()) {
      await _deleteRemoteCase(caseId);
    }
    if (kIsWeb) return;
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
        record.anesthesiaTechniqueDetails.trim().isNotEmpty ||
        record.drugs.isNotEmpty ||
        record.sedationMedications.isNotEmpty ||
        record.neuraxialNeedles.isNotEmpty ||
        record.anesthesiaMaterials.isNotEmpty ||
        record.postAnesthesiaRecovery.hasContent ||
        record.hemodynamicMarkers.isNotEmpty ||
        record.hemodynamicPoints.isNotEmpty;

    if (hasIntraoperativeContent) return AnesthesiaCaseStatus.inProgress;
    if (hasPreAnesthetic) return AnesthesiaCaseStatus.preAnesthetic;
    return AnesthesiaCaseStatus.inProgress;
  }

  SupabaseClient? get _client => SupabaseService.instance.client;

  Future<bool> _ensureRemote() async {
    await SupabaseService.instance.initialize();
    return SupabaseService.instance.isReady;
  }

  Future<List<AnesthesiaCase>> _loadCasesRemote() async {
    final client = _client;
    if (client == null) return [];
    try {
      final response =
      await client.from('anesthesia_cases').select().order('updated_at', ascending: false);
      if (response is List) {
        return response
            .map((item) => _mapCase(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // ignore remote failure
    }
    return [];
  }

  Future<void> _upsertRemoteCase(AnesthesiaCase caseFile) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('anesthesia_cases').upsert({
        'id': caseFile.id,
        'created_at': caseFile.createdAtIso,
        'updated_at': caseFile.updatedAtIso,
        'pre_anesthetic_date': caseFile.preAnestheticDate,
        'anesthesia_date': caseFile.anesthesiaDate,
        'status': caseFile.status.code,
        'record': caseFile.record.toJson(),
      }, onConflict: 'id');
    } catch (_) {
      // remote save failure is non-fatal
    }
  }

  Future<void> _deleteRemoteCase(String caseId) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('anesthesia_cases').delete().eq('id', caseId);
    } catch (_) {
      // ignore
    }
  }

  AnesthesiaCase _mapCase(Map<String, dynamic> data) {
    return AnesthesiaCase(
      id: data['id'] as String? ?? createCaseId(),
      createdAtIso: data['created_at'] as String? ?? data['createdAtIso'] as String? ?? '',
      updatedAtIso: data['updated_at'] as String? ?? data['updatedAtIso'] as String? ?? '',
      preAnestheticDate: data['pre_anesthetic_date'] as String? ?? data['preAnestheticDate'] as String? ?? '',
      anesthesiaDate: data['anesthesia_date'] as String? ?? data['anesthesiaDate'] as String? ?? '',
      status: AnesthesiaCaseStatusX.fromCode(data['status'] as String?),
      record: AnesthesiaRecord.fromJson(
        data['record'] as Map<dynamic, dynamic>? ?? const {},
      ),
    );
  }
}

extension _IterableExtensions<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
