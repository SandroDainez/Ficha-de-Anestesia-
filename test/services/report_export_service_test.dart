import 'package:anestesia_app/models/anesthesia_record.dart';
import 'package:anestesia_app/models/hemodynamic_point.dart';
import 'package:anestesia_app/services/report_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ReportExportService();

  test('includes the hemodynamic chart in complete export when chart data exists', () {
    final record = AnesthesiaRecord.empty().copyWith(
      hemodynamicPoints: const [
        HemodynamicPoint(type: 'PAS', value: 120, time: 5),
        HemodynamicPoint(type: 'PAD', value: 70, time: 5),
      ],
    );

    expect(service.shouldIncludeHemodynamicChart(record), isTrue);
  });

  test('skips the hemodynamic chart in complete export when chart data is absent', () {
    const record = AnesthesiaRecord.empty();

    expect(service.shouldIncludeHemodynamicChart(record), isFalse);
  });

  test('includes the hemodynamic chart in complete export when only markers exist', () {
    final record = AnesthesiaRecord.empty().copyWith(
      hemodynamicMarkers: const [
        HemodynamicMarker(label: 'Incisão', time: 15),
      ],
    );

    expect(service.shouldIncludeHemodynamicChart(record), isTrue);
  });
}
