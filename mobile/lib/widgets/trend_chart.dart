import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

enum MarkerShape { circle, square }

class ChartPoint {
  const ChartPoint(this.t, this.v, {this.flagged = false, this.line1 = '', this.line2 = ''});
  final DateTime t;
  final double v;
  final bool flagged;

  /// Tooltip lines (date/time, value).
  final String line1;
  final String line2;
}

class ChartSeries {
  const ChartSeries({
    required this.points,
    required this.color,
    this.dashed = false,
    this.marker = MarkerShape.circle,
    this.strokeWidth = 2.4,
  });
  final List<ChartPoint> points;
  final Color color;
  final bool dashed;
  final MarkerShape marker;
  final double strokeWidth;
}

class ChartBand {
  const ChartBand(this.lo, this.hi);
  final double lo;
  final double hi;
}

class ChartXLabel {
  const ChartXLabel(this.t, this.text, {this.bold = false});
  final DateTime t;
  final String text;
  final bool bold;
}

/// Smooth monotone-curve clinical chart with translucent normal band,
/// zero-overshoot splines, missed-day gaps, diamond out-of-range markers,
/// and tap + finger-scrub tooltip inspection.
class TrendChart extends StatefulWidget {
  const TrendChart({
    super.key,
    required this.series,
    required this.bands,
    required this.yMin,
    required this.yMax,
    required this.yTicks,
    required this.yTickLabels,
    required this.start,
    required this.end,
    required this.xLabels,
    required this.semanticLabel,
    this.height = 196,
    this.interactive = true,
  });

  final List<ChartSeries> series;
  final List<ChartBand> bands;
  final double yMin;
  final double yMax;
  final List<double> yTicks;
  final List<String> yTickLabels;
  final DateTime start;
  final DateTime end;
  final List<ChartXLabel> xLabels;
  final String semanticLabel;
  final double height;
  final bool interactive;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _s;
  int? _p;

  @override
  void didUpdateWidget(covariant TrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start ||
        oldWidget.end != widget.end ||
        oldWidget.series.length != widget.series.length) {
      _s = null;
      _p = null;
    }
  }

  void _selectAt(Offset pos, Size size, {required bool toggleSame}) {
    final g = _Geo(size, widget);
    double best = double.infinity;
    int? bs;
    int? bp;
    for (var s = 0; s < widget.series.length; s++) {
      final pts = widget.series[s].points;
      for (var p = 0; p < pts.length; p++) {
        final dx = g.x(pts[p].t) - pos.dx;
        final dy = g.y(pts[p].v) - pos.dy;
        final d = dx * dx + dy * dy * 0.25;
        if (dx.abs() < 28 && d < best) {
          best = d;
          bs = s;
          bp = p;
        }
      }
    }

    if (bs == null || bp == null) {
      if (toggleSame && (_s != null || _p != null)) {
        setState(() {
          _s = null;
          _p = null;
        });
      }
      return;
    }

    if (bs == _s && bp == _p) {
      if (toggleSame) {
        HapticFeedback.selectionClick();
        setState(() {
          _s = null;
          _p = null;
        });
      }
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _s = bs;
      _p = bp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, widget.height);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.interactive
              ? (d) => _selectAt(d.localPosition, size, toggleSame: true)
              : null,
          onHorizontalDragStart: widget.interactive
              ? (d) => _selectAt(d.localPosition, size, toggleSame: false)
              : null,
          onHorizontalDragUpdate: widget.interactive
              ? (d) => _selectAt(d.localPosition, size, toggleSame: false)
              : null,
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _ChartPainter(widget, _s, _p),
            ),
          ),
        );
      }),
    );
  }
}

class _Geo {
  _Geo(Size size, this.w)
      : plot = Rect.fromLTRB(40, 14, size.width - 12, size.height - 28);

  final TrendChart w;
  final Rect plot;

  static DateTime _d(DateTime t) => DateTime(t.year, t.month, t.day);

  double x(DateTime t) {
    final total = (_d(w.end).difference(_d(w.start)).inHours / 24).round();
    if (total <= 0) return plot.center.dx;
    final idx = _d(t).difference(_d(w.start)).inHours / 24;
    final f = (idx / total).clamp(0.0, 1.0).toDouble();
    return plot.left + f * plot.width;
  }

  double y(double v) {
    final f = ((v - w.yMin) / (w.yMax - w.yMin)).clamp(0.0, 1.0).toDouble();
    return plot.bottom - f * plot.height;
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.w, this.sel, this.selP);

  final TrendChart w;
  final int? sel;
  final int? selP;

  TextPainter _tp(
    String s, {
    double size = 11.5,
    Color color = C.hint,
    FontWeight weight = FontWeight.w500,
  }) {
    return TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: T.f,
          fontSize: size,
          color: color,
          fontWeight: weight,
          height: 1.3,
          fontFeatures: T.tabular,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
  }

  void _dashLine(Canvas c, Offset a, Offset b, Paint paint, {double on = 5, double off = 4}) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    double d = 0;
    while (d < total) {
      final e = (d + on) > total ? total : d + on;
      c.drawLine(a + dir * d, a + dir * e, paint);
      d = e + off;
    }
  }

  Path _dashPath(Path src, double on, double off) {
    final out = Path();
    for (final m in src.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        final e = (d + on) > m.length ? m.length : d + on;
        out.addPath(m.extractPath(d, e), Offset.zero);
        d = e + off;
      }
    }
    return out;
  }

  /// Splits points into contiguous day runs (breaking on missed days > 1.5d).
  List<List<Offset>> _segments(List<ChartPoint> pts, _Geo g) {
    final runs = <List<Offset>>[];
    List<Offset> cur = <Offset>[];
    DateTime? prev;
    for (final p in pts) {
      final o = Offset(g.x(p.t), g.y(p.v));
      final gap = prev == null
          ? 0.0
          : (DateTime(p.t.year, p.t.month, p.t.day)
                      .difference(DateTime(prev.year, prev.month, prev.day))
                      .inHours /
                  24)
              .abs();
      if (prev != null && gap > 1.5) {
        if (cur.isNotEmpty) runs.add(cur);
        cur = <Offset>[o];
      } else {
        cur.add(o);
      }
      prev = p.t;
    }
    if (cur.isNotEmpty) runs.add(cur);
    return runs;
  }

  /// Fritsch-Carlson monotone cubic spline: smooth curve with zero overshoot
  /// past real clinical readings.
  Path _monotonePath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) return path;
    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
      return path;
    }

    final n = pts.length;
    final dx = List<double>.filled(n - 1, 0);
    final m = List<double>.filled(n - 1, 0);
    for (var i = 0; i < n - 1; i++) {
      dx[i] = pts[i + 1].dx - pts[i].dx;
      final dy = pts[i + 1].dy - pts[i].dy;
      m[i] = dx[i].abs() > 0.001 ? dy / dx[i] : 0;
    }

    final t = List<double>.filled(n, 0);
    t[0] = m[0];
    t[n - 1] = m[n - 2];
    for (var i = 1; i < n - 1; i++) {
      if (m[i - 1] * m[i] <= 0) {
        t[i] = 0;
      } else {
        t[i] = (m[i - 1] + m[i]) * 0.5;
      }
    }

    for (var i = 0; i < n - 1; i++) {
      if (m[i] == 0) {
        t[i] = 0;
        t[i + 1] = 0;
      } else {
        final a = t[i] / m[i];
        final b = t[i + 1] / m[i];
        final sq = a * a + b * b;
        if (sq > 9) {
          final tau = 3 / math.sqrt(sq);
          t[i] = tau * a * m[i];
          t[i + 1] = tau * b * m[i];
        }
      }
    }

    for (var i = 0; i < n - 1; i++) {
      if (dx[i].abs() <= 0.001) {
        path.lineTo(pts[i + 1].dx, pts[i + 1].dy);
      } else {
        final h = dx[i] / 3;
        path.cubicTo(
          pts[i].dx + h,
          pts[i].dy + t[i] * h,
          pts[i + 1].dx - h,
          pts[i + 1].dy - t[i + 1] * h,
          pts[i + 1].dx,
          pts[i + 1].dy,
        );
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = _Geo(size, w);
    final plot = g.plot;

    // Translucent normal-range bands
    final bandFill = Paint()..color = C.okBg.withValues(alpha: 0.75);
    final bandEdge = Paint()
      ..color = C.okBorder.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (final b in w.bands) {
      final top = g.y(b.hi);
      final bot = g.y(b.lo);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(plot.left, top, plot.right, bot), const Radius.circular(4)),
        bandFill,
      );
      _dashLine(canvas, Offset(plot.left, top), Offset(plot.right, top), bandEdge);
      _dashLine(canvas, Offset(plot.left, bot), Offset(plot.right, bot), bandEdge);
    }

    // Soft horizontal grid + Y labels
    final grid = Paint()
      ..color = C.divider
      ..strokeWidth = 1;
    for (var i = 0; i < w.yTicks.length; i++) {
      final y = g.y(w.yTicks[i]);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      if (i < w.yTickLabels.length) {
        final tp = _tp(w.yTickLabels[i]);
        tp.paint(canvas, Offset(plot.left - 8 - tp.width, y - tp.height / 2));
      }
    }

    // X labels
    for (var i = 0; i < w.xLabels.length; i++) {
      final xl = w.xLabels[i];
      final tp = _tp(
        xl.text,
        color: xl.bold ? C.text : C.hint,
        weight: xl.bold ? FontWeight.w700 : FontWeight.w500,
      );
      final x = g.x(xl.t);
      double dx = x - tp.width / 2;
      if (dx < plot.left - 10) dx = plot.left - 10;
      if (dx + tp.width > size.width) dx = size.width - tp.width;
      tp.paint(canvas, Offset(dx, plot.bottom + 8));
    }

    // Series curves + soft gradient wash under solid curves
    for (final s in w.series) {
      final runs = _segments(s.points, g);
      final stroke = Paint()
        ..color = s.color
        ..strokeWidth = s.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (final run in runs) {
        if (run.length < 2) continue;
        final curve = _monotonePath(run);

        if (!s.dashed) {
          final area = Path.from(curve)
            ..lineTo(run.last.dx, plot.bottom)
            ..lineTo(run.first.dx, plot.bottom)
            ..close();
          final fillPaint = Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                s.color.withValues(alpha: 0.14),
                s.color.withValues(alpha: 0.0),
              ],
            ).createShader(plot);
          canvas.drawPath(area, fillPaint);
        }

        canvas.drawPath(s.dashed ? _dashPath(curve, 6, 4) : curve, stroke);
      }
    }

    // Data point markers (crisp white halo so points pop over bands/grid)
    final dense = w.series.isNotEmpty && w.series.first.points.length > 40;
    final r = dense ? 2.8 : 4.0;
    for (final s in w.series) {
      for (final p in s.points) {
        final o = Offset(g.x(p.t), g.y(p.v));
        if (p.flagged) {
          final d = dense ? 4.4 : 5.8;
          final path = Path()
            ..moveTo(o.dx, o.dy - d)
            ..lineTo(o.dx + d, o.dy)
            ..lineTo(o.dx, o.dy + d)
            ..lineTo(o.dx - d, o.dy)
            ..close();
          canvas.drawPath(path, Paint()..color = C.errBorder);
          canvas.drawPath(
            path,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        } else if (s.marker == MarkerShape.square) {
          final rect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: o, width: r * 1.9, height: r * 1.9),
            const Radius.circular(2),
          );
          canvas.drawRRect(rect, Paint()..color = Colors.white);
          canvas.drawRRect(
            rect,
            Paint()
              ..color = s.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8,
          );
        } else {
          canvas.drawCircle(o, r + 1.4, Paint()..color = Colors.white);
          canvas.drawCircle(o, r, Paint()..color = s.color);
        }
      }
    }

    // Floating tooltip on tap or finger scrub
    if (sel != null &&
        selP != null &&
        sel! < w.series.length &&
        selP! < w.series[sel!].points.length) {
      final s = w.series[sel!];
      final p = s.points[selP!];
      final o = Offset(g.x(p.t), g.y(p.v));
      final accent = p.flagged ? C.errBorder : s.color;

      final guide = Paint()
        ..color = C.borderStrong
        ..strokeWidth = 1.25;
      _dashLine(canvas, Offset(o.dx, plot.top), Offset(o.dx, plot.bottom), guide, on: 4, off: 3);

      canvas.drawCircle(o, 10, Paint()..color = accent.withValues(alpha: 0.18));
      canvas.drawCircle(o, 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        o,
        5.5,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );

      final t1 = _tp(p.line1, size: 11.5, color: C.text2, weight: FontWeight.w500);
      final t2 = _tp(p.line2, size: 14, color: C.text, weight: FontWeight.w700);
      final bw = (t1.width > t2.width ? t1.width : t2.width) + 22;
      final bh = t1.height + t2.height + 16;
      double bx = o.dx > plot.center.dx ? o.dx - bw - 12 : o.dx + 12;
      if (bx < 4) bx = 4;
      if (bx + bw > size.width - 4) bx = size.width - 4 - bw;
      double by = o.dy - bh - 10;
      if (by < 4) by = o.dy + 12;
      if (by + bh > size.height - 4) by = size.height - 4 - bh;

      final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bw, bh),
        const Radius.circular(10),
      );
      canvas.drawRRect(
        box.shift(const Offset(0, 4)),
        Paint()
          ..color = const Color(0x1F0F172A)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawRRect(box, Paint()..color = C.panel);
      canvas.drawRRect(
        box,
        Paint()
          ..color = C.borderStrong
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      t1.paint(canvas, Offset(bx + 11, by + 8));
      t2.paint(canvas, Offset(bx + 11, by + 8 + t1.height));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.sel != sel ||
      old.selP != selP ||
      old.w.series != w.series ||
      old.w.bands != w.bands ||
      old.w.start != w.start ||
      old.w.end != w.end ||
      old.w.yMin != w.yMin ||
      old.w.yMax != w.yMax;
}

/// Small legend swatches used under charts.
class LegendLine extends StatelessWidget {
  const LegendLine({
    super.key,
    required this.label,
    required this.color,
    this.dashed = false,
    this.square = false,
  });

  final String label;
  final Color color;
  final bool dashed;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: const Size(22, 12), painter: _LegendPainter(color, dashed, square)),
        const SizedBox(width: 6),
        Text(label, style: T.cap),
      ],
    );
  }
}

class _LegendPainter extends CustomPainter {
  _LegendPainter(this.color, this.dashed, this.square);
  final Color color;
  final bool dashed;
  final bool square;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (dashed) {
      for (double x = 0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset((x + 5) > size.width ? size.width : x + 5, y), p);
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final c = Offset(size.width / 2, y);
    if (square) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 7.5, height: 7.5),
        const Radius.circular(2),
      );
      canvas.drawRRect(r, Paint()..color = Colors.white);
      canvas.drawRRect(
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    } else {
      canvas.drawCircle(c, 4.4, Paint()..color = Colors.white);
      canvas.drawCircle(c, 3.4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _LegendPainter old) =>
      old.color != color || old.dashed != dashed || old.square != square;
}

class LegendDiamond extends StatelessWidget {
  const LegendDiamond({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: C.errBorder,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(label, style: T.cap),
      ],
    );
  }
}

class LegendBand extends StatelessWidget {
  const LegendBand({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 11,
          decoration: BoxDecoration(
            color: C.okBg,
            border: Border.all(color: C.okBorder.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: T.cap),
      ],
    );
  }
}
