import 'package:anestesia_app/models/anesthesia_record.dart';
import 'package:anestesia_app/models/hemodynamic_entry.dart';
import 'package:anestesia_app/models/hemodynamic_point.dart';
import 'package:anestesia_app/services/hemodynamic_record_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = HemodynamicRecordService();

  test('returns latest points and derived blood pressure metrics', () {
    const points = [
      HemodynamicPoint(type: 'PAS', value: 100, time: 1),
      HemodynamicPoint(type: 'PAD', value: 60, time: 1),
      HemodynamicPoint(type: 'PAS', value: 120, time: 5),
      HemodynamicPoint(type: 'PAD', value: 70, time: 5),
      HemodynamicPoint(type: 'FC', value: 80, time: 5),
    ];

    expect(service.latestPointOfType(points, 'PAS')!.value, 120);
    expect(service.latestBloodPressure(points), '120 / 70');
    expect(service.latestPam(points), '86.7 mmHg');
  });

  test('builds PAM automatically from nearby PAS and PAD timestamps', () {
    const points = [
      HemodynamicPoint(type: 'PAS', value: 120, time: 5.0),
      HemodynamicPoint(type: 'PAD', value: 70, time: 5.4),
    ];

    final pamPoints = service.buildPamPoints(points);

    expect(pamPoints, hasLength(1));
    expect(pamPoints.single.value, closeTo(86.7, 0.1));
    expect(service.latestPam(points), '86.7 mmHg');
  });

  test('adds markers based on anesthesia start time', () {
    final now = DateTime.parse('2026-03-31T10:30:00');
    final markers = service.addMarker(
      markers: const [],
      label: 'Início da anestesia',
      now: DateTime.parse('2026-03-31T10:00:00'),
    );

    final surgeryMarkers = service.addMarker(
      markers: markers,
      label: 'Início da cirurgia',
      now: now,
    );

    expect(markers.single.time, 0);
    expect(surgeryMarkers.last.label, 'Início da cirurgia');
    expect(surgeryMarkers.last.time, 30);
  });

  test('adds and removes hemodynamic points in sorted order', () {
    const existing = [
      HemodynamicPoint(type: 'FC', value: 75, time: 4),
    ];
    final updated = service.addPoint(
      points: existing,
      type: 'PAS',
      value: 110,
      time: 2,
    );

    expect(updated.first.time, 2);
    expect(updated.last.time, 4);

    final removed = service.removePoint(points: updated, point: updated.first);
    expect(removed, hasLength(1));
    expect(removed.single.type, 'FC');
  });

  test('migrates legacy hemodynamic entries to points', () {
    final record = AnesthesiaRecord.empty().copyWith(
      hemodynamicEntries: const [
        HemodynamicEntry(
          time: '5',
          heartRate: '80',
          systolic: '120',
          diastolic: '70',
          spo2: '99',
        ),
      ],
    );

    final migrated = service.migrateLegacyHemodynamics(record);

    expect(migrated.hemodynamicPoints, hasLength(4));
    expect(
      migrated.hemodynamicPoints.map((item) => item.type),
      containsAll(['FC', 'PAS', 'PAD', 'SpO2']),
    );
  });
}
