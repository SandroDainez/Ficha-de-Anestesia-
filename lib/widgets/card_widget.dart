import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'app_card_style.dart';
import '../models/hemodynamic_point.dart';

class PanelCard extends StatefulWidget {
  const PanelCard({
    super.key,
    required this.title,
    required this.titleColor,
    required this.icon,
    required this.child,
    this.trailing,
    this.fillChild = false,
    this.minHeight,
    this.isAttention = false,
    this.isCompleted = false,
    this.collapsible = true,
    this.initiallyExpanded = false,
    this.collapsedChild,
    this.onTap,
  });

  final String title;
  final Color titleColor;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final bool fillChild;
  final double? minHeight;
  final bool isAttention;
  final bool isCompleted;
  final bool collapsible;
  final bool initiallyExpanded;
  final Widget? collapsedChild;
  final VoidCallback? onTap;

  @override
  State<PanelCard> createState() => _PanelCardState();
}

class _PanelCardState extends State<PanelCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    void handleCardTap() {
      if (widget.onTap != null) {
        widget.onTap!();
        return;
      }
      if (widget.collapsible) {
        setState(() => _isExpanded = !_isExpanded);
      }
    }

    void handleCollapsedTap() {
      if (widget.onTap != null) {
        widget.onTap!();
        return;
      }
      if (widget.collapsible) {
        setState(() => _isExpanded = true);
      }
    }

    final isSuccess = widget.isCompleted && !widget.isAttention;
    final headerBackground = widget.isAttention
        ? const Color(0xFFFFF1F1)
        : isSuccess
        ? const Color(0xFFE7F6EC)
        : const Color(0xFFF5F7FC);
    final headerDivider = widget.isAttention
        ? const Color(0xFFE29B9B)
        : isSuccess
        ? const Color(0xFF8DD0A3)
        : const Color(0xFFBCD0E4);
    final cardBackground = isSuccess
        ? const Color(0xFFF4FBF6)
        : widget.isAttention
        ? const Color(0xFFFFF7F7)
        : Colors.white;
    final cardBorder = widget.isAttention
        ? const Color(0xFFE29B9B)
        : isSuccess
        ? const Color(0xFF8DD0A3)
        : const Color(0xFFBCD0E4);
    final effectiveTitleColor = widget.isAttention
        ? const Color(0xFFB04141)
        : isSuccess
        ? const Color(0xFF177245)
        : const Color(0xFF6A7E94);

    return Container(
      width: double.infinity,
      constraints: _isExpanded && widget.minHeight != null
          ? BoxConstraints(minHeight: widget.minHeight!)
          : null,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: AppCardStyle.radius,
        border: Border.all(color: cardBorder),
        boxShadow: const [AppCardStyle.shadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(13),
              bottom: Radius.circular(_isExpanded ? 0 : 13),
            ),
            onTap: (widget.collapsible || widget.onTap != null)
                ? handleCardTap
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: headerBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(13),
                  topRight: const Radius.circular(13),
                  bottomLeft: Radius.circular(_isExpanded ? 0 : 13),
                  bottomRight: Radius.circular(_isExpanded ? 0 : 13),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: _isExpanded ? headerDivider : Colors.transparent,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 18, color: effectiveTitleColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: effectiveTitleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        height: 1.1,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.trailing != null) widget.trailing!,
                  if (widget.collapsible)
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF7D93AA),
                    ),
                ],
              ),
            ),
          ),
          if (!widget.collapsible || _isExpanded)
            if (widget.fillChild)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: widget.child,
                ),
              )
            else
              Padding(padding: const EdgeInsets.all(12), child: widget.child)
          else if (widget.collapsedChild != null)
            InkWell(
              onTap: (widget.collapsible || widget.onTap != null)
                  ? handleCollapsedTap
                  : null,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(13),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: widget.collapsedChild!,
              ),
            ),
        ],
      ),
    );
  }
}

class SoftTag extends StatelessWidget {
  const SoftTag({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class DetailLine extends StatelessWidget {
  const DetailLine({
    super.key,
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Widget? accent;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder =
        value.trim().isEmpty ||
        value.trim() == '--' ||
        value.toLowerCase().contains('toque para preencher');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF72859A),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            accent ?? const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isPlaceholder
                ? const Color(0xFF7E92A8)
                : const Color(0xFF17324D),
            fontWeight: isPlaceholder ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class BulletLine extends StatelessWidget {
  const BulletLine({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 9, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class CheckLine extends StatelessWidget {
  const CheckLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Icon(Icons.check, size: 14, color: Color(0xFF2B76D2)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class AddButton extends StatelessWidget {
  const AddButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFD9E5F5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 14, color: Color(0xFF2B76D2)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF2B76D2),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusHint extends StatelessWidget {
  const StatusHint({
    super.key,
    required this.text,
    this.icon = Icons.edit_outlined,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0EAF3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF8AA0B5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF7B8EA2),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandBadge extends StatelessWidget {
  const ExpandBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.open_in_full, size: 14, color: Color(0xFF7D93AA)),
        SizedBox(width: 4),
        Text(
          'Expandir',
          style: TextStyle(
            color: Color(0xFF7D93AA),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class LegendRow extends StatelessWidget {
  const LegendRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          LegendDot(label: 'PAS (∨)', color: Color(0xFF365FD5)),
          SizedBox(width: 14),
          LegendDot(label: 'PAD (∧)', color: Color(0xFF6B8DF2)),
          SizedBox(width: 14),
          LegendDot(label: 'PAM (m)', color: Color(0xFF2747B8)),
          SizedBox(width: 14),
          LegendDot(label: 'FC (•)', color: Color(0xFFEA5455)),
          SizedBox(width: 14),
          LegendDot(label: 'SpO₂ (S)', color: Color(0xFF16A96B)),
          SizedBox(width: 14),
          LegendDot(label: 'PAI', color: Color(0xFF5B6B7A)),
        ],
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6F8298),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

typedef HemodynamicPointDragCallback =
    void Function(
      String type,
      double matchTime,
      double matchValue,
      double newValue,
      double newTime,
    );

class HemodynamicChart extends StatefulWidget {
  const HemodynamicChart({
    super.key,
    required this.points,
    required this.markers,
    required this.selectedType,
    this.displayMaxTime,
    this.onPointTap,
    this.onChartTap,
    this.onPointMoved,
    this.onPointDragEnd,
  });

  final List<HemodynamicPoint> points;
  final List<HemodynamicMarker> markers;
  final String selectedType;
  final double? displayMaxTime;
  final ValueChanged<HemodynamicPoint>? onPointTap;
  final ValueChanged<double>? onChartTap;
  final HemodynamicPointDragCallback? onPointMoved;
  final VoidCallback? onPointDragEnd;

  @override
  State<HemodynamicChart> createState() => _HemodynamicChartState();
}

class _HemodynamicChartState extends State<HemodynamicChart> {
  static const double _tapSlop = 20;
  static const double _dragHitRadius = 18;
  static const double _tapHitRadius = 28;

  Offset? _downLocal;
  bool _movedPastSlop = false;
  bool _dragUpdated = false;
  HemodynamicPoint? _draggingHit;
  double? _matchTime;
  double? _matchValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
        final layout = HemodynamicChartLayout(
          points: widget.points,
          markers: widget.markers,
          size: chartSize,
          displayMaxTime: widget.displayMaxTime,
        );

        // Listener garante toque no gráfico (onTapUp com Pan competia e falhava).
        Widget chart = Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            _downLocal = event.localPosition;
            _movedPastSlop = false;
            _dragUpdated = false;
            final hit = layout.hitTest(
              event.localPosition,
              radius: _dragHitRadius,
            );
            if (hit != null &&
                widget.onPointMoved != null &&
                widget.onPointTap == null) {
              _draggingHit = hit;
              _matchTime = hit.time;
              _matchValue = hit.value;
            } else {
              _draggingHit = null;
              _matchTime = null;
              _matchValue = null;
            }
          },
          onPointerMove: (event) {
            if (_downLocal == null) return;
            if ((event.localPosition - _downLocal!).distance > _tapSlop) {
              _movedPastSlop = true;
            }
            final drag = _draggingHit;
            final mt = _matchTime;
            final mv = _matchValue;
            if (drag != null &&
                mt != null &&
                mv != null &&
                widget.onPointMoved != null) {
              _dragUpdated = true;
              final type = drag.type;
              final newValue = layout.valueForY(event.localPosition.dy, type);
              final newTime = layout.timeForX(event.localPosition.dx);
              widget.onPointMoved!(type, mt, mv, newValue, newTime);
              _matchTime = newTime;
              _matchValue = newValue;
            }
          },
          onPointerUp: (event) => _handlePointerUp(layout, event.localPosition),
          onPointerCancel: (_) => _handlePointerCancel(),
          child: CustomPaint(painter: _ChartPainter(layout), size: chartSize),
        );

        if (kIsWeb) {
          chart = PointerInterceptor(child: chart);
        }
        return chart;
      },
    );
  }

  void _handlePointerCancel() {
    if (_draggingHit != null && _dragUpdated) {
      widget.onPointDragEnd?.call();
    }
    _clearPointerState();
  }

  void _handlePointerUp(HemodynamicChartLayout layout, Offset local) {
    if (_draggingHit != null) {
      if (_dragUpdated) {
        widget.onPointDragEnd?.call();
      }
      _clearPointerState();
      return;
    }

    final down = _downLocal;
    if (down == null) {
      _clearPointerState();
      return;
    }

    if (_movedPastSlop) {
      _clearPointerState();
      return;
    }

    final hit = layout.hitTest(local, radius: _tapHitRadius);
    if (hit != null && widget.onPointTap != null) {
      widget.onPointTap!(hit);
    } else if (hit == null && widget.onChartTap != null) {
      widget.onChartTap!(layout.valueForY(local.dy, widget.selectedType));
    }

    _clearPointerState();
  }

  void _clearPointerState() {
    _downLocal = null;
    _movedPastSlop = false;
    _dragUpdated = false;
    _draggingHit = null;
    _matchTime = null;
    _matchValue = null;
  }
}

class HemodynamicChartLayout {
  HemodynamicChartLayout({
    required this.points,
    required this.markers,
    required this.size,
    this.displayMaxTime,
  });

  final List<HemodynamicPoint> points;
  final List<HemodynamicMarker> markers;
  final Size size;
  final double? displayMaxTime;

  static const double leftPadding = 44;
  static const double rightPadding = 12;
  static const double topPadding = 34;
  static const double bottomPadding = 38;
  static const double bandGap = 14;

  double get minTime => 0;
  double get maxTime {
    final double pointMax = points.isEmpty
        ? 0
        : points.map((item) => item.time).reduce((a, b) => a > b ? a : b);
    final double markerMax = markers.isEmpty
        ? 0
        : markers.map((item) => item.time).reduce((a, b) => a > b ? a : b);
    final baseMax = pointMax > markerMax ? pointMax : markerMax;
    final maxValue = displayMaxTime != null && displayMaxTime! > baseMax
        ? displayMaxTime!
        : baseMax;
    if (maxValue <= 180) return 180.0;
    final blocksOf15 = (maxValue / 15).ceil();
    return blocksOf15 * 15.0;
  }

  double get chartWidth => size.width - leftPadding - rightPadding;
  double get spo2Top => topPadding;
  double get stepHeight =>
      (size.height - topPadding - bottomPadding - bandGap) / 23;
  double get spo2Height => stepHeight * 6;
  double get spo2Bottom => spo2Top + spo2Height;
  double get hemoTop => spo2Bottom + bandGap;
  double get hemoHeight => stepHeight * 17;

  double xForTime(double time) {
    if (maxTime <= minTime) return leftPadding;
    return leftPadding + ((time - minTime) / (maxTime - minTime)) * chartWidth;
  }

  double timeForX(double x) {
    if (chartWidth <= 0) return minTime;
    final clamped = x.clamp(leftPadding, leftPadding + chartWidth);
    if (maxTime <= minTime) return minTime;
    return minTime +
        ((clamped - leftPadding) / chartWidth) * (maxTime - minTime);
  }

  double yForValue(double value, [String type = 'FC']) {
    if (type == 'SpO2') {
      final clamped = value.clamp(70, 100);
      return spo2Top + spo2Height - ((clamped - 70) / 30) * spo2Height;
    }

    final clamped = value.clamp(0, 200);
    return hemoTop + hemoHeight - (clamped / 200) * hemoHeight;
  }

  double valueForY(double y, String type) {
    if (type == 'SpO2') {
      final usableY = (y - spo2Top).clamp(0, spo2Height);
      final raw = 100 - (usableY / spo2Height) * 30;
      return raw.clamp(70, 100).roundToDouble();
    }

    final usableY = (y - hemoTop).clamp(0, hemoHeight);
    final raw = 200 - (usableY / hemoHeight) * 200;
    final snapped = (raw / 10).round() * 10;
    return snapped.clamp(0, 200).toDouble();
  }

  Offset offsetForPoint(HemodynamicPoint point) {
    return Offset(xForTime(point.time), yForValue(point.value, point.type));
  }

  HemodynamicPoint? hitTest(Offset position, {double radius = 48.0}) {
    for (final point in points.reversed) {
      final offset = offsetForPoint(point);
      if ((offset - position).distance <= radius) {
        return point;
      }
    }
    return null;
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.layout);

  final HemodynamicChartLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE7EEF6)
      ..strokeWidth = 1;
    final timeGridMinor = Paint()
      ..color = const Color(0xFFE6EEF7)
      ..strokeWidth = 1;
    final timeGridMajor = Paint()
      ..color = const Color(0xFFC9D8E8)
      ..strokeWidth = 1.4;
    final axis = Paint()
      ..color = const Color(0xFF8EA5BF)
      ..strokeWidth = 1.5;
    final separatorPaint = Paint()
      ..color = const Color(0xFFC8D6E5)
      ..strokeWidth = 1.2;
    final axisText = TextPainter(textDirection: TextDirection.ltr);
    const spo2AxisStyle = TextStyle(
      color: Color(0xFF0F9F63),
      fontSize: 13,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.1,
    );
    const hemoAxisStyle = TextStyle(
      color: Color(0xFF5F7896),
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.1,
    );
    const timeAxisStyle = TextStyle(
      color: Color(0xFF5F7896),
      fontSize: 11,
      fontWeight: FontWeight.w800,
    );

    for (var value = 70; value <= 100; value += 10) {
      final y = layout.yForValue(value.toDouble(), 'SpO2');
      canvas.drawLine(
        Offset(HemodynamicChartLayout.leftPadding, y),
        Offset(size.width - HemodynamicChartLayout.rightPadding, y),
        grid,
      );
      axisText.text = TextSpan(text: value.toString(), style: spo2AxisStyle);
      axisText.layout();
      axisText.paint(canvas, Offset(2, y - (axisText.height / 2)));
    }

    for (var value = 0; value <= 200; value += 10) {
      final y = layout.yForValue(value.toDouble(), 'FC');
      canvas.drawLine(
        Offset(HemodynamicChartLayout.leftPadding, y),
        Offset(size.width - HemodynamicChartLayout.rightPadding, y),
        grid,
      );
      axisText.text = TextSpan(text: value.toString(), style: hemoAxisStyle);
      axisText.layout();
      axisText.paint(canvas, Offset(2, y - (axisText.height / 2)));
    }

    canvas.drawLine(
      Offset(HemodynamicChartLayout.leftPadding, layout.spo2Bottom + 7),
      Offset(
        size.width - HemodynamicChartLayout.rightPadding,
        layout.spo2Bottom + 7,
      ),
      separatorPaint,
    );

    axisText.text = const TextSpan(
      text: 'SpO₂',
      style: TextStyle(
        color: Color(0xFF0F9F63),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
    axisText.layout();
    axisText.paint(canvas, const Offset(46, 14));

    for (double minute = 0; minute <= layout.maxTime; minute += 5) {
      final x = layout.xForTime(minute);
      final isMajor = minute % 15 == 0;
      canvas.drawLine(
        Offset(x, HemodynamicChartLayout.topPadding),
        Offset(x, size.height - HemodynamicChartLayout.bottomPadding),
        isMajor ? timeGridMajor : timeGridMinor,
      );
    }

    canvas.drawLine(
      Offset(
        HemodynamicChartLayout.leftPadding,
        HemodynamicChartLayout.topPadding,
      ),
      Offset(
        HemodynamicChartLayout.leftPadding,
        size.height - HemodynamicChartLayout.bottomPadding,
      ),
      axis,
    );

    if (layout.points.isEmpty && layout.markers.isEmpty) {
      return;
    }

    final sortedMarkers = List<HemodynamicMarker>.from(layout.markers)
      ..sort((a, b) => a.time.compareTo(b.time));
    for (var index = 0; index < sortedMarkers.length; index++) {
      final marker = sortedMarkers[index];
      final x = layout.xForTime(marker.time);
      final markerColor = marker.label == 'Início da anestesia'
          ? const Color(0xFF2B76D2)
          : const Color(0xFF169653);
      final markerPaint = Paint()
        ..color = markerColor
        ..strokeWidth = 1.4;
      canvas.drawLine(
        Offset(x, HemodynamicChartLayout.topPadding),
        Offset(x, size.height - HemodynamicChartLayout.bottomPadding),
        markerPaint,
      );
      axisText.text = TextSpan(
        text: marker.clockTime.trim().isEmpty
            ? marker.label
            : '${marker.label} ${marker.clockTime}',
        style: TextStyle(
          color: markerColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      );
      axisText.layout();
      final labelX = x < 130 ? x + 34 : x + 4;
      final labelY = 2.0 + (index * 12.0);
      axisText.paint(canvas, Offset(labelX, labelY));
    }

    _drawSeries(canvas, 'PAS', const Color(0xFF365FD5));
    _drawSeries(canvas, 'PAD', const Color(0xFF6B8DF2));
    _drawSeries(canvas, 'PAM', const Color(0xFF2747B8));
    _drawSeries(canvas, 'FC', const Color(0xFFEA5455));
    _drawSeries(canvas, 'SpO2', const Color(0xFF16A96B));
    _drawSeries(canvas, 'PAI', const Color(0xFF5B6B7A));

    for (double time = 0; time <= layout.maxTime; time += 15) {
      final x = layout.xForTime(time);
      axisText.text = TextSpan(
        text: _formatAxisTime(time),
        style: timeAxisStyle,
      );
      axisText.layout();
      axisText.paint(canvas, Offset(x - 8, size.height - 16));
    }
  }

  String _formatAxisTime(double time) {
    final totalSeconds = (time * 60).round();
    final minutes = totalSeconds ~/ 60;
    return minutes.toString().padLeft(2, '0');
  }

  void _drawSeries(Canvas canvas, String type, Color color) {
    final data = type == 'PAM'
        ? _buildPamPoints()
        : (layout.points.where((item) => item.type == type).toList()
            ..sort((a, b) => a.time.compareTo(b.time)));
    if (data.isEmpty) return;

    const lineStroke = 3.0;
    const symbolStroke = 3.5;
    final line = Paint()
      ..color = color
      ..strokeWidth = lineStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final symbolPaint = Paint()
      ..color = color
      ..strokeWidth = symbolStroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path();

    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      final offset = layout.offsetForPoint(point);
      final x = offset.dx;
      final y = offset.dy;
      if (type != 'PAI') {
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      switch (type) {
        case 'PAS':
          const tw = 9.0;
          const th = 8.0;
          final symbol = Path()
            ..moveTo(x - tw, y - th)
            ..lineTo(x, y + th + 2)
            ..lineTo(x + tw, y - th)
            ..close();
          canvas.drawPath(symbol, symbolPaint);
          break;
        case 'PAD':
          const tw = 9.0;
          const th = 8.0;
          final symbol = Path()
            ..moveTo(x - tw, y + th)
            ..lineTo(x, y - th - 2)
            ..lineTo(x + tw, y + th)
            ..close();
          canvas.drawPath(symbol, symbolPaint);
          break;
        case 'FC':
          final fill = Paint()..color = color;
          final ring = Paint()
            ..color = color
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke;
          canvas.drawCircle(offset, 7, fill);
          canvas.drawCircle(offset, 7, ring);
          break;
        case 'PAM':
          final text = TextPainter(
            text: TextSpan(
              text: 'M',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          text.paint(canvas, Offset(x - text.width / 2, y - text.height / 2));
          break;
        case 'SpO2':
          final text = TextPainter(
            text: TextSpan(
              text: 'Sat',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          text.paint(canvas, Offset(x - text.width / 2, y - text.height / 2));
          break;
        case 'PAI':
          canvas.drawCircle(
            offset,
            14,
            Paint()
              ..color = color.withAlpha(24)
              ..style = PaintingStyle.fill,
          );
          canvas.drawCircle(
            offset,
            14,
            Paint()
              ..color = color
              ..strokeWidth = 2.5
              ..style = PaintingStyle.stroke,
          );
          final text = TextPainter(
            text: TextSpan(
              text: 'PAI',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          text.paint(canvas, Offset(x - text.width / 2, y - text.height / 2));
          break;
      }
    }
    if (type != 'PAI') {
      canvas.drawPath(path, line);
    }
  }

  List<HemodynamicPoint> _buildPamPoints() {
    const toleranceMinutes = 1.0;
    final pasPoints = layout.points
        .where((item) => item.type == 'PAS')
        .toList();
    final padPoints = layout.points
        .where((item) => item.type == 'PAD')
        .toList();
    final usedPadIndexes = <int>{};
    final pamPoints = <HemodynamicPoint>[];

    for (final pas in pasPoints) {
      var bestIndex = -1;
      var bestDelta = double.infinity;
      for (var index = 0; index < padPoints.length; index++) {
        if (usedPadIndexes.contains(index)) continue;
        final delta = (padPoints[index].time - pas.time).abs();
        if (delta <= toleranceMinutes && delta < bestDelta) {
          bestDelta = delta;
          bestIndex = index;
        }
      }
      if (bestIndex == -1) continue;

      final matchingPad = padPoints[bestIndex];
      usedPadIndexes.add(bestIndex);
      final pam = (pas.value + (2 * matchingPad.value)) / 3;
      pamPoints.add(
        HemodynamicPoint(
          type: 'PAM',
          value: pam,
          time: (pas.time + matchingPad.time) / 2,
        ),
      );
    }

    pamPoints.sort((a, b) => a.time.compareTo(b.time));
    return pamPoints;
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.layout.points != layout.points ||
      oldDelegate.layout.markers != layout.markers;
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.background,
    required this.valueColor,
    required this.icon,
  });

  final String label;
  final String value;
  final Color background;
  final Color valueColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1EAF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: valueColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6D8097),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class LabeledSurface extends StatelessWidget {
  const LabeledSurface({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE7F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6F8298),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class DoseRow extends StatelessWidget {
  const DoseRow({
    super.key,
    required this.drug,
    required this.dose,
    required this.time,
  });

  final String drug;
  final String dose;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            drug,
            style: const TextStyle(
              color: Color(0xFF17324D),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            dose,
            style: const TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            time,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF5D7288),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class KeyValueLine extends StatelessWidget {
  const KeyValueLine({
    super.key,
    required this.label,
    required this.value,
    this.labelColor = const Color(0xFF5D7288),
    this.valueColor = const Color(0xFF17324D),
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value.trim().isEmpty || value.trim() == '--';
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: labelColor, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isPlaceholder ? const Color(0xFF8AA0B5) : valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
