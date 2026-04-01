import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/anesthesia_record.dart';

class RecordStorageService {
  RecordStorageService();

  static const String _boxName = 'anesthesia_record_box';
  static const String _recordKey = 'current_record';

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

  Future<AnesthesiaRecord?> loadRecord() async {
    await _ensureInitialized();
    final box = await Hive.openBox<dynamic>(_boxName);
    final raw = box.get(_recordKey);

    if (raw is! Map) return null;

    return AnesthesiaRecord.fromJson(Map<dynamic, dynamic>.from(raw));
  }

  Future<void> saveRecord(AnesthesiaRecord record) async {
    await _ensureInitialized();
    final box = await Hive.openBox<dynamic>(_boxName);
    await box.put(_recordKey, record.toJson());
  }
}
