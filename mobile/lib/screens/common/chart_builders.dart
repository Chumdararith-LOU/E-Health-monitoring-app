import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

DateTime _d(DateTime t) => DateTime(t.year, t.month, t.day);

/// X-axis labels: every day for short ranges, otherwise 5 evenly spaced
/// dates. The month name is shown on the first label and when it changes.
List<ChartXLabel> xLabelsFor(L l, DateTime start, DateTime end, {DateTime? today}) {
  final s = _d(start);
  final total = (_d(end).difference(s).inHours / 24).round();
  final idx = <int>[];
  if (total <= 7) {
    for (var i = 0; i <= total; i++) {
      idx.add(i);
    }
  } else {
    for (var i = 0; i < 5; i++) {
      idx.add((i * total / 4).round());
    }
  }
  final out = <ChartXLabel>[];
  int? lastMonth;
  for (var k = 0; k < idx.length; k++) {
    final t = DateTime(s.year, s.month, s.day + idx[k]);
    final short = total <= 7;
    final showMonth = !short && (lastMonth == null || t.month != lastMonth);
    lastMonth = t.month;
    final isToday = today != null && _d(today) == t;
    out.add(ChartXLabel(t, showMonth ? l.day(t) : l.n(t.day), bold: isToday));
  }
  return out;
}

double _ceilTo(double v, double step) => (v / step).ceil() * step;

List<double> _ticks(double from, double to, double step) {
  final out = <double>[];
  for (var v = from; v <= to + 0.01; v += step) {
    out.add(v);
  }
  return out;
}

/// Blood pressure: systolic (solid navy, circles) + diastolic (dashed grey,
/// squares), both normal bands.
Widget bpChart(L l, List<Reading> newestFirst, DateTime start, DateTime end, {double height = 190, DateTime? today}) {
  final rs = newestFirst.where((r) => r.hasBp).toList().reversed.toList();
  double maxV = 180;
  for (final r in rs) {
    if (r.systolic! + 10 > maxV) maxV = r.systolic! + 10.0;
  }
  final yMax = _ceilTo(maxV, 30);
  final ticks = _ticks(60, yMax, 30);
  final sys = rs
      .map((r) => ChartPoint(r.time, r.systolic!.toDouble(),
          flagged: r.sysStatus != RangeStatus.normal, line1: l.dayTime(r.time), line2: l.n('${r.bpText} mmHg')))
      .toList();
  final dia = rs
      .map((r) => ChartPoint(r.time, r.diastolic!.toDouble(),
          flagged: r.diaStatus != RangeStatus.normal, line1: l.dayTime(r.time), line2: l.n('${r.bpText} mmHg')))
      .toList();
  final sysMin = rs.isEmpty ? 0 : rs.map((r) => r.systolic!).reduce((a, b) => a < b ? a : b);
  final sysMaxV = rs.isEmpty ? 0 : rs.map((r) => r.systolic!).reduce((a, b) => a > b ? a : b);
  return TrendChart(
    height: height,
    series: [
      ChartSeries(points: dia, color: C.text2, dashed: true, marker: MarkerShape.square, strokeWidth: 1.8),
      ChartSeries(points: sys, color: C.navyBase, strokeWidth: 2.4),
    ],
    bands: [ChartBand(Fields.sys.normalMin, Fields.sys.normalMax), ChartBand(Fields.dia.normalMin, Fields.dia.normalMax)],
    yMin: 50,
    yMax: yMax,
    yTicks: ticks,
    yTickLabels: ticks.map((t) => l.n(t.round())).toList(),
    start: start,
    end: end,
    xLabels: xLabelsFor(l, start, end, today: today),
    semanticLabel: '${l.bp}: ${l.n(rs.length)} · ${l.systolic} ${l.n(sysMin)}–${l.n(sysMaxV)} mmHg',
  );
}

/// "Nice" tick step for about 4–6 ticks.
double _niceStep(double range) {
  final raw = range <= 0 ? 1.0 : range / 4;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final n = raw / mag;
  final nice = n <= 1 ? 1.0 : (n <= 2 ? 2.0 : (n <= 5 ? 5.0 : 10.0));
  return nice * mag;
}

/// Any single-value field (glucose, pulse, Admin custom fields).
/// The axis fits the data and the normal band automatically.
Widget fieldChart(L l, VitalField f, List<Reading> newestFirst, double? Function(Reading) pick, DateTime start, DateTime end,
    {double height = 190, DateTime? today}) {
  final rs = newestFirst.where((r) => pick(r) != null).toList().reversed.toList();
  var lo = f.normalMin;
  var hi = f.normalMax;
  for (final r in rs) {
    final v = pick(r)!;
    if (v < lo) lo = v;
    if (v > hi) hi = v;
  }
  final step = _niceStep(hi - lo);
  final yMin = math.max(0.0, ((lo - step * 0.5) / step).floor() * step);
  final yMax = ((hi + step * 0.5) / step).ceil() * step;
  final ticks = _ticks(yMin, yMax, step);
  final pts = rs.map((r) {
    final v = pick(r)!;
    return ChartPoint(r.time, v, flagged: f.status(v) != RangeStatus.normal, line1: l.dayTime(r.time), line2: l.n('${f.fmt(v)} ${f.unit}'));
  }).toList();
  return TrendChart(
    height: height,
    series: [ChartSeries(points: pts, color: C.navyBase, strokeWidth: 2.2)],
    bands: [ChartBand(f.normalMin, f.normalMax)],
    yMin: yMin,
    yMax: yMax,
    yTicks: ticks,
    yTickLabels: ticks.map((t) => l.n(step < 1 ? t.toStringAsFixed(1) : t.round().toString())).toList(),
    start: start,
    end: end,
    xLabels: xLabelsFor(l, start, end, today: today),
    semanticLabel: '${f.short(l.km)}: ${l.n(rs.length)}',
  );
}

/// Legend under the BP chart.
Widget bpLegend(L l, {bool withDiamond = true, String? extra}) {
  return Wrap(
    spacing: 14,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      LegendLine(label: l.systolic, color: C.navyBase),
      LegendLine(label: l.diastolic, color: C.text2, dashed: true, square: true),
      if (withDiamond) LegendDiamond(label: l.outOfRange),
      LegendBand(label: l.normalRange),
      if (extra != null) Text(extra, style: T.cap),
    ],
  );
}
