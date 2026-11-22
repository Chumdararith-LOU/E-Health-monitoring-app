import 'package:flutter/material.dart';

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
    this.strokeWidth = 2,
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

/// One metric per chart (BP counts as one), green normal band with dashed
/// edges, diamond markers for out-of-range points, tap a point for a
/// white bordered tooltip. Breaks the line on missed days.
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
    this.height = 190,
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
    if (oldWidget.start != widget.start || oldWidget.end != widget.end || oldWidget.series.length != widget.series.length) {
      _s = null;
      _p = null;
    }
  }

  void _onTap(Offset pos, Size size) {
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
        if (dx.abs() < 26 && d < best) {
          best = d;
          bs = s;
          bp = p;
        }
      }
    }
    setState(() {
      if (bs == _s && bp == _p) {
        _s = null;
        _p = null;
      } else {
        _s = bs;
        _p = bp;
      }
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
          onTapDown: widget.interactive ? (d) => _onTap(d.localPosition, size) : null,
          child: CustomPaint(
            size: size,
            painter: _ChartPainter(widget, _s, _p),
          ),
        );
      }),
    );
  }
}

class _Geo {
  _Geo(Size size, this.w) : plot = Rect.fromLTRB(38, 12, size.width - 12, size.height - 28);

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

  TextPainter _tp(String s, {double size = 12, Color color = C.text2, FontWeight weight = FontWeight.w400}) {
    return TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontFamily: T.f, fontSize: size, color: color, fontWeight: weight, height: 1.25, fontFeatures: T.tabular),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
  }

  void _dashLine(Canvas c, Offset a, Offset b, Paint paint, {double on = 4, double off = 3}) {
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

  @override
  void paint(Canvas canvas, Size size) {
    final g = _Geo(size, w);
    final plot = g.plot;

    // Normal bands
    final bandFill = Paint()..color = C.okBg;
    final bandEdge = Paint()
      ..color = C.okBorder
      ..strokeWidth = 1;
    for (final b in w.bands) {
      final top = g.y(b.hi);
      final bot = g.y(b.lo);
      canvas.drawRect(Rect.fromLTRB(plot.left, top, plot.right, bot), bandFill);
      _dashLine(canvas, Offset(plot.left, top), Offset(plot.right, top), bandEdge);
      _dashLine(canvas, Offset(plot.left, bot), Offset(plot.right, bot), bandEdge);
    }

    // Grid + Y labels
    final grid = Paint()
      ..color = C.grid
      ..strokeWidth = 1;
    for (var i = 0; i < w.yTicks.length; i++) {
      final y = g.y(w.yTicks[i]);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      if (i < w.yTickLabels.length) {
        final tp = _tp(w.yTickLabels[i]);
        tp.paint(canvas, Offset(plot.left - 6 - tp.width, y - tp.height / 2));
      }
    }

    // X labels
    for (var i = 0; i < w.xLabels.length; i++) {
      final xl = w.xLabels[i];
      final tp = _tp(xl.text, color: xl.bold ? C.text : C.text2, weight: xl.bold ? FontWeight.w700 : FontWeight.w400);
      final x = g.x(xl.t);
      double dx = x - tp.width / 2;
      if (dx < plot.left - 10) dx = plot.left - 10;
      if (dx + tp.width > size.width) dx = size.width - tp.width;
      tp.paint(canvas, Offset(dx, plot.bottom + 8));
    }

    // Series lines (break on missed days)
    for (final s in w.series) {
      final path = Path();
      DateTime? prev;
      for (final p in s.points) {
        final o = Offset(g.x(p.t), g.y(p.v));
        final gap = prev == null ? 99 : (DateTime(p.t.year, p.t.month, p.t.day).difference(DateTime(prev.year, prev.month, prev.day)).inHours / 24).abs();
        if (prev == null || gap > 1.5) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
        prev = p.t;
      }
      final stroke = Paint()
        ..color = s.color
        ..strokeWidth = s.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(s.dashed ? _dashPath(path, 6, 4) : path, stroke);
    }

    // Markers
    final dense = w.series.isNotEmpty && w.series.first.points.length > 40;
    final r = dense ? 2.6 : 3.6;
    for (final s in w.series) {
      for (final p in s.points) {
        final o = Offset(g.x(p.t), g.y(p.v));
        if (p.flagged) {
          final d = dense ? 4.0 : 5.5;
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
              ..strokeWidth = 1,
          );
        } else if (s.marker == MarkerShape.square) {
          final rect = Rect.fromCenter(center: o, width: r * 1.8, height: r * 1.8);
          canvas.drawRect(rect, Paint()..color = Colors.white);
          canvas.drawRect(
            rect,
            Paint()
              ..color = s.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6,
          );
        } else {
          canvas.drawCircle(o, r, Paint()..color = s.color);
        }
      }
    }

    // Tooltip
    if (sel != null && selP != null && sel! < w.series.length && selP! < w.series[sel!].points.length) {
      final p = w.series[sel!].points[selP!];
      final o = Offset(g.x(p.t), g.y(p.v));
      final guide = Paint()
        ..color = C.text2
        ..strokeWidth = 1;
      _dashLine(canvas, Offset(o.dx, plot.top), Offset(o.dx, plot.bottom), guide, on: 3, off: 3);
      canvas.drawCircle(
        o,
        7,
        Paint()
          ..color = C.text
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final t1 = _tp(p.line1, size: 12);
      final t2 = _tp(p.line2, size: 14, color: C.text, weight: FontWeight.w700);
      final bw = (t1.width > t2.width ? t1.width : t2.width) + 18;
      final bh = t1.height + t2.height + 12;
      double bx = o.dx > plot.center.dx ? o.dx - bw - 12 : o.dx + 12;
      if (bx < 2) bx = 2;
      if (bx + bw > size.width - 2) bx = size.width - 2 - bw;
      double by = o.dy - bh - 6;
      if (by < 2) by = o.dy + 10;
      if (by + bh > size.height - 2) by = size.height - 2 - bh;
      final box = RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(3));
      canvas.drawRRect(box.shift(const Offset(0, 2)), Paint()..color = const Color(0x22000000));
      canvas.drawRRect(box, Paint()..color = Colors.white);
      canvas.drawRRect(
        box,
        Paint()
          ..color = C.text2
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      t1.paint(canvas, Offset(bx + 9, by + 6));
      t2.paint(canvas, Offset(bx + 9, by + 6 + t1.height));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}

/// Small legend swatches used under charts.
class LegendLine extends StatelessWidget {
  const LegendLine({super.key, required this.label, required this.color, this.dashed = false, this.square = false});
  final String label;
  final Color color;
  final bool dashed;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: const Size(22, 10), painter: _LegendPainter(color, dashed, square)),
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
      ..strokeWidth = 2;
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
      final r = Rect.fromCenter(center: c, width: 7, height: 7);
      canvas.drawRect(r, Paint()..color = Colors.white);
      canvas.drawRect(
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    } else {
      canvas.drawCircle(c, 3.6, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _LegendPainter old) => old.color != color || old.dashed != dashed || old.square != square;
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
          child: Container(width: 9, height: 9, color: C.errBorder),
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
          height: 10,
          decoration: BoxDecoration(color: C.okBg, border: Border.all(color: C.okBorder)),
        ),
        const SizedBox(width: 6),
        Text(label, style: T.cap),
      ],
    );
  }
}
