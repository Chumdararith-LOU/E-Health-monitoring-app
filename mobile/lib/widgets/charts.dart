import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import 'app_text.dart';

class ChartPoint {
  const ChartPoint(this.t, this.v, this.id);
  final DateTime t;
  final double v;
  final String id;
}

class ChartSeries {
  const ChartSeries({required this.key, required this.label, required this.color, required this.points, this.band});
  final String key;
  final String label;
  final Color color;

  /// Ascending time.
  final List<ChartPoint> points;

  /// Normal range.
  final (double, double)? band;
}

class _Ticks {
  const _Ticks(this.lo, this.hi, this.values);
  final double lo, hi;
  final List<double> values;
}

_Ticks _niceTicks(double min, double max, [int count = 4]) {
  final span = (max - min) == 0 ? 1.0 : max - min;
  final step0 = span / count;
  final mag = math.pow(10, (math.log(step0) / math.ln10).floor()).toDouble();
  final step = [1, 2, 5, 10].map((m) => m * mag).firstWhere((s) => s >= step0, orElse: () => step0);
  final lo = (min / step).floor() * step;
  final hi = (max / step).ceil() * step;
  final values = <double>[];
  for (var v = lo; v <= hi + step / 2; v += step) {
    values.add((v * 100).round() / 100);
  }
  return _Ticks(lo, hi, values);
}

/// Line chart with normal-range band(s), a recessive grid, one y-axis, a legend
/// and tap-to-inspect (crosshair + tooltip).
class LineChart extends StatefulWidget {
  const LineChart({
    super.key,
    required this.series,
    required this.from,
    required this.to,
    this.height = 210,
    this.decimals = 0,
    this.onOpen,
  });

  final List<ChartSeries> series;
  final DateTime from;
  final DateTime to;
  final double height;
  final int decimals;
  final ValueChanged<String>? onOpen;

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  DateTime? _sel;
  static const _padL = 40.0, _padR = 12.0;

  List<DateTime> get _times {
    final set = <DateTime>{for (final s in widget.series) for (final p in s.points) p.t};
    return set.toList()..sort();
  }

  void _touch(double dx, double width) {
    final times = _times;
    if (times.isEmpty) return;
    final plotW = math.max(1.0, width - _padL - _padR);
    final span = math.max(1, widget.to.millisecondsSinceEpoch - widget.from.millisecondsSinceEpoch);
    double x(DateTime t) => _padL + (t.millisecondsSinceEpoch - widget.from.millisecondsSinceEpoch) / span * plotW;
    var best = times.first;
    var bestD = double.infinity;
    for (final t in times) {
      final d = (x(t) - dx).abs();
      if (d < bestD) {
        bestD = d;
        best = t;
      }
    }
    if (best != _sel) setState(() => _sel = best);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppScope.of(context).i18n;
    final sel = _sel;
    final selPoints = sel == null
        ? const <(ChartSeries, ChartPoint)>[]
        : [
            for (final s in widget.series)
              for (final p in s.points)
                if (p.t == sel) (s, p),
          ];

    Widget swatch(Color c, {bool band = false}) => Container(
          width: 16,
          height: band ? 12 : 4,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
            border: band ? Border.all(color: C.borderStrong) : null,
          ),
        );
    Widget legendItem(Widget sw, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          sw,
          const SizedBox(width: 6),
          AppText(label, variant: TextVariant.caption),
        ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Sp.sm),
          child: Wrap(spacing: Sp.md, runSpacing: Sp.xs, children: [
            if (widget.series.length > 1)
              for (final s in widget.series) legendItem(swatch(s.color), s.label),
            legendItem(swatch(C.band, band: true), i18n.t('normalRange')),
          ]),
        ),
        Semantics(
          image: true,
          label: widget.series.map((s) => '${s.label}: ${s.points.length}').join(', '),
          hint: i18n.t('chartHint'),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _touch(d.localPosition.dx, w),
              onHorizontalDragStart: (d) => _touch(d.localPosition.dx, w),
              onHorizontalDragUpdate: (d) => _touch(d.localPosition.dx, w),
              child: CustomPaint(
                size: Size(w, widget.height),
                painter: _ChartPainter(
                  series: widget.series,
                  from: widget.from,
                  to: widget.to,
                  sel: sel,
                  i18n: i18n,
                  latinStyle: appStyle(context, '0', size: 12, color: C.axis),
                  dateStyle: appStyle(context, i18n.dateShort(widget.from), size: 12, color: C.axis),
                  textScale: AppScope.of(context).settings.textScale,
                ),
              ),
            );
          }),
        ),
        if (sel != null && selPoints.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: Sp.sm),
            padding: const EdgeInsets.all(Sp.md),
            decoration: BoxDecoration(
              color: C.surfaceAlt,
              borderRadius: BorderRadius.circular(R.md),
              border: Border.all(color: C.border),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AppText('${i18n.date(sel)} · ${i18n.time(sel)}', variant: TextVariant.label, weight: W.semibold),
                  for (final (s, p) in selPoints)
                    Row(children: [
                      swatch(s.color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: '${s.label}: '),
                            TextSpan(
                              text: i18n.n(p.v, widget.decimals),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ]),
                          style: appStyle(context, s.label, variant: TextVariant.label),
                        ),
                      ),
                    ]),
                ]),
              ),
              if (widget.onOpen != null)
                Semantics(
                  link: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onOpen!(selPoints.first.$2.id),
                    child: Padding(
                      padding: const EdgeInsets.all(Sp.sm),
                      child: AppText('${i18n.t('readingDetail')} ›',
                          variant: TextVariant.label, weight: W.bold, color: C.primary),
                    ),
                  ),
                ),
            ]),
          )
        else
          AppText(i18n.t('chartHint'), variant: TextVariant.caption, color: C.textMuted, align: TextAlign.center),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.series,
    required this.from,
    required this.to,
    required this.sel,
    required this.i18n,
    required this.latinStyle,
    required this.dateStyle,
    required this.textScale,
  });

  final List<ChartSeries> series;
  final DateTime from, to;
  final DateTime? sel;
  final I18n i18n;
  final TextStyle latinStyle, dateStyle;
  final double textScale;

  static const padL = 40.0, padR = 12.0, padT = 12.0, padB = 28.0;

  void _text(Canvas canvas, String s, TextStyle style, Offset anchor, {TextAlign align = TextAlign.left, bool middleY = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style.copyWith(fontSize: 12, height: 1.0)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      TextAlign.right => anchor.dx - tp.width,
      TextAlign.center => anchor.dx - tp.width / 2,
      _ => anchor.dx,
    };
    final dy = middleY ? anchor.dy - tp.height / 2 : anchor.dy - tp.height;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plotW = math.max(1.0, size.width - padL - padR);
    final plotH = size.height - padT - padB;

    final vals = <double>[
      for (final s in series) ...[
        for (final p in s.points) p.v,
        if (s.band != null) ...[s.band!.$1, s.band!.$2],
      ],
    ];
    final ticks = vals.isEmpty ? _niceTicks(0, 100) : _niceTicks(vals.reduce(math.min), vals.reduce(math.max));
    final lo = ticks.lo, hi = ticks.hi;
    final span = math.max(1, to.millisecondsSinceEpoch - from.millisecondsSinceEpoch);
    double x(DateTime t) => padL + (t.millisecondsSinceEpoch - from.millisecondsSinceEpoch) / span * plotW;
    double y(double v) => padT + (1 - (v - lo) / math.max(1e-6, hi - lo)) * plotH;

    // normal-range bands
    final dash = Paint()
      ..color = C.borderStrong
      ..strokeWidth = 1;
    void dashed(double yy) {
      for (var xx = padL; xx < padL + plotW; xx += 8) {
        canvas.drawLine(Offset(xx, yy), Offset(math.min(xx + 4, padL + plotW), yy), dash);
      }
    }

    for (final s in series) {
      final b = s.band;
      if (b == null) continue;
      final top = y(math.min(hi, b.$2));
      final bottom = y(math.max(lo, b.$1));
      canvas.drawRect(Rect.fromLTWH(padL, top, plotW, math.max(0, bottom - top)), Paint()..color = C.band);
      dashed(y(b.$2));
      dashed(y(b.$1));
    }

    // grid + y labels
    final grid = Paint()
      ..color = C.grid
      ..strokeWidth = 1;
    for (final tv in ticks.values) {
      canvas.drawLine(Offset(padL, y(tv)), Offset(padL + plotW, y(tv)), grid);
      _text(canvas, i18n.n(tv), latinStyle, Offset(padL - 6, y(tv)), align: TextAlign.right, middleY: true);
    }

    // x labels: start, middle, end
    final mid = DateTime.fromMillisecondsSinceEpoch(from.millisecondsSinceEpoch + span ~/ 2);
    final xs = [(from, TextAlign.left), (mid, TextAlign.center), (to, TextAlign.right)];
    for (final (t, align) in xs) {
      _text(canvas, i18n.dateShort(t), dateStyle, Offset(x(t), size.height - 4), align: align);
    }

    // lines
    for (final s in series) {
      if (s.points.isEmpty) continue;
      final path = Path();
      for (var i = 0; i < s.points.length; i++) {
        final p = s.points[i];
        i == 0 ? path.moveTo(x(p.t), y(p.v)) : path.lineTo(x(p.t), y(p.v));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      if (s.points.length <= 31) {
        for (final p in s.points) {
          final o = Offset(x(p.t), y(p.v));
          canvas.drawCircle(o, 3.5, Paint()..color = s.color);
          canvas.drawCircle(o, 3.5, Paint()
            ..color = C.surface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
        }
      }
    }

    // selection
    final selT = sel;
    if (selT != null) {
      canvas.drawLine(Offset(x(selT), padT), Offset(x(selT), padT + plotH), Paint()
        ..color = C.text
        ..strokeWidth = 1);
      for (final s in series) {
        for (final p in s.points) {
          if (p.t != selT) continue;
          final o = Offset(x(p.t), y(p.v));
          canvas.drawCircle(o, 6, Paint()..color = s.color);
          canvas.drawCircle(o, 6, Paint()
            ..color = C.surface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.series != series || old.sel != sel || old.from != from || old.to != to || old.i18n != i18n;
}

/// Tiny trend line for cards (no axes; the card states the numbers in text).
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.color = C.series1, this.width = 120, this.height = 40});
  final List<double> values;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(size: Size(width, height), painter: _SparkPainter(values, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final span = max - min == 0 ? 1 : max - min;
    double px(int i) => 4 + i / (values.length - 1) * (size.width - 8);
    double py(double v) => 4 + (1 - (v - min) / span) * (size.height - 8);
    final path = Path()..moveTo(px(0), py(values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(px(i), py(values[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(Offset(px(values.length - 1), py(values.last)), 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values || old.color != color;
}
