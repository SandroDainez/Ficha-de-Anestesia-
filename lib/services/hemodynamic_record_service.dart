import '../models/anesthesia_record.dart';
import '../models/hemodynamic_point.dart';

class HemodynamicRecordService {
  const HemodynamicRecordService();
  static const double _pressurePairingToleranceMinutes = 1.0;

  HemodynamicPoint? latestPointOfType(
    List<HemodynamicPoint> points,
    String type,
  ) {
    final matches = points.where((item) => item.type == type).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return matches.isEmpty ? null : matches.last;
  }

  String latestBloodPressure(List<HemodynamicPoint> points) {
    final pas = latestPointOfType(points, 'PAS');
    final pad = latestPointOfType(points, 'PAD');
    if (pas == null || pad == null) return '--';
    return '${pas.value.round()} / ${pad.value.round()}';
  }

  String latestPam(List<HemodynamicPoint> points) {
    final pamPoints = buildPamPoints(points);
    if (pamPoints.isEmpty) return '--';
    final pam = pamPoints.last.value;
    return '${pam.toStringAsFixed(1)} mmHg';
  }

  List<HemodynamicPoint> buildPamPoints(List<HemodynamicPoint> points) {
    final pasPoints = points.where((item) => item.type == 'PAS').toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    final padPoints = points.where((item) => item.type == 'PAD').toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    final usedPadIndexes = <int>{};
    final pamPoints = <HemodynamicPoint>[];

    for (final pas in pasPoints) {
      var bestIndex = -1;
      var bestDelta = double.infinity;

      for (var index = 0; index < padPoints.length; index++) {
        if (usedPadIndexes.contains(index)) continue;
        final delta = (padPoints[index].time - pas.time).abs();
        if (delta <= _pressurePairingToleranceMinutes && delta < bestDelta) {
          bestDelta = delta;
          bestIndex = index;
        }
      }

      if (bestIndex == -1) continue;

      final matchingPad = padPoints[bestIndex];
      usedPadIndexes.add(bestIndex);
      final pam = (pas.value + (2 * matchingPad.value)) / 3;
      final averagedTime = (pas.time + matchingPad.time) / 2;
      pamPoints.add(
        HemodynamicPoint(type: 'PAM', value: pam, time: averagedTime),
      );
    }

    pamPoints.sort((a, b) => a.time.compareTo(b.time));
    return pamPoints;
  }

  DateTime? markerStartAt(List<HemodynamicMarker> markers, String label) {
    try {
      final marker = markers.firstWhere((item) => item.label == label);
      if (marker.recordedAtIso.trim().isEmpty) return null;
      return DateTime.tryParse(marker.recordedAtIso);
    } catch (_) {
      return null;
    }
  }

  double currentElapsedMinutes(DateTime? startedAt, DateTime now) {
    if (startedAt == null) return 0;
    final minutes = now.difference(startedAt).inSeconds / 60;
    return minutes < 0 ? 0 : minutes;
  }

  String formatClock(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String formatHemodynamicClock(double time) {
    final totalSeconds = (time * 60).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String formatElapsedFrom(DateTime? startedAt, DateTime now) {
    if (startedAt == null) return '--:--';
    final totalSeconds = now.difference(startedAt).inSeconds;
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<HemodynamicMarker> addMarker({
    required List<HemodynamicMarker> markers,
    required String label,
    required DateTime now,
  }) {
    final updatedMarkers = List<HemodynamicMarker>.from(markers);
    double markerTime = 0;

    if (label == 'Início da anestesia') {
      updatedMarkers.removeWhere((item) => item.label == label);
    } else {
      final anesthesiaStart = updatedMarkers
          .cast<HemodynamicMarker?>()
          .firstWhere(
            (item) => item?.label == 'Início da anestesia',
            orElse: () => null,
          );
      if (anesthesiaStart == null || anesthesiaStart.recordedAtIso.isEmpty) {
        return markers;
      }
      final startedAt = DateTime.tryParse(anesthesiaStart.recordedAtIso);
      if (startedAt != null) {
        markerTime = now.difference(startedAt).inSeconds / 60;
        if (markerTime < 0) markerTime = 0;
        if (markerTime == 0) {
          markerTime = 1 / 60;
        }
      }
      updatedMarkers.removeWhere((item) => item.label == label);
    }

    updatedMarkers.add(
      HemodynamicMarker(
        label: label,
        time: markerTime,
        clockTime: formatClock(now),
        recordedAtIso: now.toIso8601String(),
      ),
    );
    updatedMarkers.sort((a, b) => a.time.compareTo(b.time));
    return updatedMarkers;
  }

  List<HemodynamicPoint> addPoint({
    required List<HemodynamicPoint> points,
    required String type,
    required double value,
    required double time,
  }) {
    final updatedPoints = List<HemodynamicPoint>.from(points)
      ..add(HemodynamicPoint(type: type, value: value, time: time))
      ..sort((a, b) => a.time.compareTo(b.time));
    return updatedPoints;
  }

  List<HemodynamicPoint> removePoint({
    required List<HemodynamicPoint> points,
    required HemodynamicPoint point,
  }) {
    return List<HemodynamicPoint>.from(points)..remove(point);
  }

  /// Atualiza um ponto existente (mesmo tipo/tempo/valor) para novo tempo e valor.
  /// Usado ao arrastar marcações no gráfico.
  List<HemodynamicPoint> updatePoint({
    required List<HemodynamicPoint> points,
    required String type,
    required double matchTime,
    required double matchValue,
    required double newTime,
    required double newValue,
  }) {
    final list = List<HemodynamicPoint>.from(points);
    final idx = list.indexWhere(
      (p) =>
          p.type == type &&
          (p.time - matchTime).abs() < 1e-5 &&
          (p.value - matchValue).abs() < 1e-5,
    );
    if (idx == -1) return points;
    list[idx] = HemodynamicPoint(
      type: type,
      value: newValue,
      time: newTime < 0 ? 0 : newTime,
    );
    list.sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  AnesthesiaRecord migrateLegacyHemodynamics(AnesthesiaRecord record) {
    if (record.hemodynamicPoints.isNotEmpty ||
        record.hemodynamicEntries.isEmpty) {
      return record;
    }

    final points = <HemodynamicPoint>[];
    for (var index = 0; index < record.hemodynamicEntries.length; index++) {
      final entry = record.hemodynamicEntries[index];
      final timeValue =
          double.tryParse(entry.time.replaceAll(':', '.')) ?? index.toDouble();
      final fc = double.tryParse(entry.heartRate.replaceAll(',', '.'));
      final pas = double.tryParse(entry.systolic.replaceAll(',', '.'));
      final pad = double.tryParse(entry.diastolic.replaceAll(',', '.'));
      final spo2 = double.tryParse(entry.spo2.replaceAll(',', '.'));

      if (fc != null) {
        points.add(HemodynamicPoint(type: 'FC', value: fc, time: timeValue));
      }
      if (pas != null) {
        points.add(HemodynamicPoint(type: 'PAS', value: pas, time: timeValue));
      }
      if (pad != null) {
        points.add(HemodynamicPoint(type: 'PAD', value: pad, time: timeValue));
      }
      if (spo2 != null) {
        points.add(
          HemodynamicPoint(type: 'SpO2', value: spo2, time: timeValue),
        );
      }
    }

    return record.copyWith(hemodynamicPoints: points);
  }
}
