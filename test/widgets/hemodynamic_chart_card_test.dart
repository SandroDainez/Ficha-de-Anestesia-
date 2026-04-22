import 'package:anestesia_app/models/hemodynamic_point.dart';
import 'package:anestesia_app/widgets/hemodynamic_chart_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps a 180-minute baseline for shorter procedures', () {
    final maxTime = HemodynamicChartCard.computeDisplayMaxTime(
      points: const [
        HemodynamicPoint(type: 'PAS', value: 120, time: 45),
      ],
      markers: const [],
      currentInlineTime: 60,
    );

    expect(maxTime, 180);
  });

  test('expands the chart for prolonged procedures beyond 180 minutes', () {
    final maxTime = HemodynamicChartCard.computeDisplayMaxTime(
      points: const [
        HemodynamicPoint(type: 'PAS', value: 120, time: 480),
        HemodynamicPoint(type: 'FC', value: 82, time: 482),
      ],
      markers: const [
        HemodynamicMarker(label: 'Fim da cirurgia', time: 475),
      ],
      currentInlineTime: 485,
    );

    expect(maxTime, 495);
    expect(HemodynamicChartCard.minimumChartWidthFor(maxTime), greaterThan(1400));
  });
}
