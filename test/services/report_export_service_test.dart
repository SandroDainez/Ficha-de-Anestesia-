import 'package:anestesia_app/models/anesthesia_case.dart';
import 'package:anestesia_app/models/anesthesia_record.dart';
import 'package:anestesia_app/models/hemodynamic_point.dart';
import 'package:anestesia_app/services/report_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = ReportExportService();

  test(
    'includes the hemodynamic chart in complete export when chart data exists',
    () {
      final record = AnesthesiaRecord.empty().copyWith(
        hemodynamicPoints: const [
          HemodynamicPoint(type: 'PAS', value: 120, time: 5),
          HemodynamicPoint(type: 'PAD', value: 70, time: 5),
        ],
      );

      expect(service.shouldIncludeHemodynamicChart(record), isTrue);
    },
  );

  test(
    'skips the hemodynamic chart in complete export when chart data is absent',
    () {
      const record = AnesthesiaRecord.empty();

      expect(service.shouldIncludeHemodynamicChart(record), isFalse);
    },
  );

  test(
    'includes the hemodynamic chart in complete export when only markers exist',
    () {
      final record = AnesthesiaRecord.empty().copyWith(
        hemodynamicMarkers: const [
          HemodynamicMarker(label: 'Incisão', time: 15),
        ],
      );

      expect(service.shouldIncludeHemodynamicChart(record), isTrue);
    },
  );

  test('builds a PDF when hemodynamic chart data exists', () async {
    final record = AnesthesiaRecord.empty().copyWith(
      hemodynamicPoints: const [
        HemodynamicPoint(type: 'PAS', value: 130, time: 0),
        HemodynamicPoint(type: 'PAD', value: 70, time: 0),
        HemodynamicPoint(type: 'FC', value: 80, time: 0),
        HemodynamicPoint(type: 'SpO2', value: 97, time: 0),
      ],
      hemodynamicMarkers: const [
        HemodynamicMarker(label: 'Início da anestesia', time: 0),
      ],
    );

    final bytes = await service.buildCasePdf(
      record: record,
      status: AnesthesiaCaseStatus.inProgress,
    );

    expect(bytes, isNotEmpty);
  });
}
