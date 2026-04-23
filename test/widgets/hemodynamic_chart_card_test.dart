import 'package:anestesia_app/models/hemodynamic_point.dart';
import 'package:anestesia_app/widgets/hemodynamic_chart_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps a 180-minute baseline for shorter procedures', () {
    final maxTime = HemodynamicChartCard.computeDisplayMaxTime(
      points: const [HemodynamicPoint(type: 'PAS', value: 120, time: 45)],
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
      markers: const [HemodynamicMarker(label: 'Fim da cirurgia', time: 475)],
      currentInlineTime: 485,
    );

    expect(maxTime, 495);
    expect(
      HemodynamicChartCard.minimumChartWidthFor(maxTime),
      greaterThan(1400),
    );
  });

  testWidgets('keeps correction toggle enabled to return to register mode', (
    WidgetTester tester,
  ) async {
    var toggled = false;
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HemodynamicChartCard(
            dominant: false,
            inlineHemodynamicRemoveMode: true,
            hasAnesthesiaStartMarker: true,
            hasSurgeryStartMarker: false,
            inlineHemodynamicType: 'PAS',
            currentInlineTime: 10,
            anesthesiaElapsed: '00:10',
            surgeryElapsed: '--:--',
            points: const [],
            markers: const [],
            latestFc: '--',
            latestBloodPressure: '--',
            latestPam: '--',
            paiSummary: '--',
            latestSpo2: '--',
            onAddAnesthesiaStart: () {},
            onAddSurgeryStart: () {},
            onAddAnesthesiaEnd: () {},
            onAddSurgeryEnd: () {},
            hasAnesthesiaEndMarker: false,
            hasSurgeryEndMarker: false,
            onToggleRemoveMode: () {
              toggled = true;
            },
            onSelectType: (_) {},
            onQuickSpo2: (_) {},
            onPointTap: (_) {},
            onChartTap: null,
          ),
        ),
      ),
    );

    await tester.tap(find.text('GRÁFICO HEMODINÂMICO'));
    await tester.pumpAndSettle();

    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('hemo-toggle-mode-button')),
    );
    expect(button.onPressed, isNotNull);

    await tester.ensureVisible(
      find.byKey(const Key('hemo-toggle-mode-button')),
    );
    await tester.tap(find.byKey(const Key('hemo-toggle-mode-button')));
    await tester.pumpAndSettle();

    expect(toggled, isTrue);
  });

  testWidgets('uses manual saturation card instead of quick chips', (
    WidgetTester tester,
  ) async {
    double? savedValue;
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HemodynamicChartCard(
            dominant: false,
            inlineHemodynamicRemoveMode: false,
            hasAnesthesiaStartMarker: true,
            hasSurgeryStartMarker: false,
            inlineHemodynamicType: 'SpO2',
            currentInlineTime: 10,
            anesthesiaElapsed: '00:10',
            surgeryElapsed: '--:--',
            points: const [],
            markers: const [],
            latestFc: '--',
            latestBloodPressure: '--',
            latestPam: '--',
            paiSummary: '--',
            latestSpo2: '--',
            onAddAnesthesiaStart: () {},
            onAddSurgeryStart: () {},
            onAddAnesthesiaEnd: () {},
            onAddSurgeryEnd: () {},
            hasAnesthesiaEndMarker: false,
            hasSurgeryEndMarker: false,
            onToggleRemoveMode: () {},
            onSelectType: (_) {},
            onQuickSpo2: (value) {
              savedValue = value;
            },
            onPointTap: null,
            onChartTap: null,
          ),
        ),
      ),
    );

    await tester.tap(find.text('GRÁFICO HEMODINÂMICO'));
    await tester.pumpAndSettle();

    expect(find.text('Sat manual'), findsOneWidget);
    expect(find.text('85%'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('hemo-spo2-manual-field')),
      '97',
    );
    await tester.tap(find.byKey(const Key('hemo-spo2-manual-save-button')));
    await tester.pumpAndSettle();

    expect(savedValue, 97);
  });
}
