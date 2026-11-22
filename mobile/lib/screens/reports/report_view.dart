// Reports (FR-10, FR-11, US-10, US-11, US-18): period toggle, Min/Avg/Max
// table (schema-driven, includes Admin custom fields), one chart per metric.
// Rith: swap the local maths for GET /patients/{id}/summary later.

import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import '../common/chart_builders.dart';

enum _Period { d7, d30, d90, custom }

class _Stat {
  _Stat(this.min, this.avg, this.max, this.flagged);
  final double min;
  final double avg;
  final double max;
  final int flagged;
}

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  _Period _period = _Period.d30;
  DateTimeRange? _custom;

  int _daysOf(_Period p) {
    switch (p) {
      case _Period.d7:
        return 7;
      case _Period.d30:
        return 30;
      case _Period.d90:
        return 90;
      case _Period.custom:
        return 30;
    }
  }

  Future<void> _pickCustom(DateTime today) async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: today,
      initialDateRange: _custom ?? DateTimeRange(start: DateTime(today.year, today.month, today.day - 13), end: today),
    );
    if (!mounted || r == null) return;
    setState(() {
      _custom = r;
      _period = _Period.custom;
    });
  }

  _Stat? _stat(List<Reading> rs, VitalField f, double? Function(Reading) pick) {
    final vals = <double>[];
    var flagged = 0;
    for (final r in rs) {
      final v = pick(r);
      if (v == null) continue;
      vals.add(v);
      if (f.status(v) != RangeStatus.normal) flagged++;
    }
    if (vals.isEmpty) return null;
    var mn = vals.first;
    var mx = vals.first;
    var sum = 0.0;
    for (final v in vals) {
      if (v < mn) mn = v;
      if (v > mx) mx = v;
      sum += v;
    }
    return _Stat(mn, sum / vals.length, mx, flagged);
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final l = L.of(context);
    final today = st.today;

    DateTime start;
    DateTime end;
    if (_period == _Period.custom && _custom != null) {
      start = MockData.dateOnly(_custom!.start);
      end = MockData.dateOnly(_custom!.end);
    } else {
      final n = _daysOf(_period);
      end = today;
      start = DateTime(today.year, today.month, today.day - (n - 1));
    }

    final inRange = st.readings.where((r) {
      final d = MockData.dateOnly(r.time);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();

    final totalDays = (end.difference(start).inHours / 24).round() + 1;
    final daysWith = inRange.map((r) => MockData.dateOnly(r.time)).toSet();
    var missed = 0;
    for (var i = 0; i < totalDays; i++) {
      final d = DateTime(start.year, start.month, start.day + i);
      if (d == today) continue; // today is not "missed" yet
      if (!daysWith.contains(d)) missed++;
    }
    final flaggedDays = inRange.where((r) => r.flagged).map((r) => MockData.dateOnly(r.time)).toSet().length;
    final periodLabel = _period == _Period.custom ? l.dayRange(start, end) : l.days(_daysOf(_period));

    final children = <Widget>[
      Text('${st.activePatient.name.of(l.km)} · ${l.dayY(start)} – ${l.dayY(end)}', style: T.bodySm.copyWith(fontWeight: FontWeight.w600)),
      SegmentedToggle<_Period>(
        semanticLabel: l.period,
        fontSize: 14,
        options: [
          SegOption(_Period.d7, l.days(7)),
          SegOption(_Period.d30, l.days(30)),
          SegOption(_Period.d90, l.days(90)),
          SegOption(_Period.custom, l.custom),
        ],
        selected: _period,
        onChanged: (p) {
          if (p == _Period.custom) {
            _pickCustom(today);
          } else {
            setState(() => _period = p);
          }
        },
      ),
    ];

    if (inRange.isEmpty) {
      children.add(StatusAlertBanner(severity: Severity.info, message: l.noReadingsPeriod));
    } else {
      children.add(_summary(l, inRange, periodLabel, missed, flaggedDays));
      children.add(BoxedPanel(
        title: l.bp,
        trailing: Text('mmHg', style: T.cap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            bpChart(l, inRange, start, end, today: today),
            const SizedBox(height: 8),
            bpLegend(l),
            const SizedBox(height: 4),
            Text(l.tapPoint, style: T.cap),
          ],
        ),
      ));
      children.add(_fieldPanel(l, Fields.glu, l.bloodGlucose, inRange, (r) => r.glucose, start, end, today));
      children.add(_fieldPanel(l, Fields.pul, l.pulse, inRange, (r) => r.pulse?.toDouble(), start, end, today));
      for (final f in Fields.custom) {
        children.add(_fieldPanel(l, f, f.short(l.km), inRange, (r) => r.extra[f.id], start, end, today, custom: true));
      }
    }

    children.add(Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TactileButton(
          label: l.exportPdf,
          icon: Icons.download_outlined,
          onPressed: inRange.isEmpty
              ? null
              : () => showConfirmModal<bool>(
                    context,
                    title: l.pdfLaterTitle,
                    message: l.pdfLaterBody,
                    tone: Severity.info,
                    actions: [ModalAction<bool>(l.ok, true, variant: BtnVariant.navy)],
                  ),
        ),
        const SizedBox(height: 6),
        Text(inRange.isEmpty ? l.exportDisabled : l.exportHint, textAlign: TextAlign.center, style: T.cap),
      ],
    ));

    return ListView(padding: const EdgeInsets.all(16), children: gapped(children, 16));
  }

  Widget _summary(L l, List<Reading> rs, String periodLabel, int missed, int flaggedDays) {
    final rows = <Widget>[];
    void add(VitalField f, String name, double? Function(Reading) pick, {bool custom = false}) {
      final s = _stat(rs, f, pick);
      if (s == null) return;
      rows.add(_SummaryRow(
        name: name,
        sub: '${f.unit} · ${l.normalShort(f.fmt(f.normalMin), f.fmt(f.normalMax))}',
        min: l.n(f.fmt(s.min)),
        avg: l.n(f.fmt(s.avg)),
        max: l.n(f.fmt(s.max)),
        maxHigh: s.max > f.normalMax,
        minLow: s.min < f.normalMin,
        flaggedText: s.flagged > 0 ? l.flaggedTimes(s.flagged) : null,
        extraLabel: custom ? l.extraField : null,
      ));
    }

    add(Fields.sys, Fields.sys.short(l.km), (r) => r.systolic?.toDouble());
    add(Fields.dia, Fields.dia.short(l.km), (r) => r.diastolic?.toDouble());
    add(Fields.pul, Fields.pul.short(l.km), (r) => r.pulse?.toDouble());
    add(Fields.glu, Fields.glu.short(l.km), (r) => r.glucose);
    for (final f in Fields.custom) {
      add(f, f.short(l.km), (r) => r.extra[f.id], custom: true);
    }

    return BoxedPanel(
      title: l.summaryOf(periodLabel),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                StatusBadge(label: l.readingsCount(rs.length)),
                StatusBadge(label: l.missedDays(missed), tone: BadgeTone.warn, icon: Icons.schedule),
                StatusBadge(label: l.flaggedDays(flaggedDays), tone: BadgeTone.crit, icon: Icons.error_outline),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: C.panelHeader,
              border: Border(top: BorderSide(color: C.border), bottom: BorderSide(color: C.border)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(flex: 7, child: Padding(padding: const EdgeInsets.only(left: 14), child: Text(l.colMeasure, style: _th))),
                Expanded(flex: 4, child: Text(l.colMin, textAlign: TextAlign.right, style: _th)),
                Expanded(flex: 4, child: Text(l.colAvg, textAlign: TextAlign.right, style: _th)),
                Expanded(flex: 5, child: Padding(padding: const EdgeInsets.only(right: 14), child: Text(l.colMax, textAlign: TextAlign.right, style: _th))),
              ],
            ),
          ),
          ...gappedDividers(rows),
        ],
      ),
    );
  }

  static const _th = TextStyle(fontFamily: T.f, fontSize: 14, fontWeight: FontWeight.w700, height: 1.55, color: C.text);

  Widget _fieldPanel(L l, VitalField f, String title, List<Reading> rs, double? Function(Reading) pick, DateTime start, DateTime end, DateTime today,
      {bool custom = false}) {
    final has = rs.any((r) => pick(r) != null);
    if (!has) return const SizedBox.shrink();
    return BoxedPanel(
      title: title,
      trailing: custom ? StatusBadge(label: l.extraField) : Text(f.unit, style: T.cap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          fieldChart(l, f, rs, pick, start, end, today: today),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LegendLine(label: f.short(l.km), color: C.navyBase),
              LegendDiamond(label: l.outOfRange),
              LegendBand(label: l.normalShort(f.fmt(f.normalMin), f.fmt(f.normalMax))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rows separated by 1px dividers.
List<Widget> gappedDividers(List<Widget> rows) {
  final out = <Widget>[];
  for (var i = 0; i < rows.length; i++) {
    if (i > 0) out.add(const Divider(height: 1, thickness: 1, color: C.divider));
    out.add(rows[i]);
  }
  return out;
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.name,
    required this.sub,
    required this.min,
    required this.avg,
    required this.max,
    required this.maxHigh,
    required this.minLow,
    this.flaggedText,
    this.extraLabel,
  });

  final String name;
  final String sub;
  final String min;
  final String avg;
  final String max;
  final bool maxHigh;
  final bool minLow;
  final String? flaggedText;
  final String? extraLabel;

  @override
  Widget build(BuildContext context) {
    const numStyle = TextStyle(fontFamily: T.f, fontSize: 17, fontWeight: FontWeight.w600, height: 1.5, color: C.text, fontFeatures: T.tabular);
    final flagStyle = numStyle.copyWith(color: C.errText, fontWeight: FontWeight.w700);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: T.h.copyWith(fontSize: 15)),
                  Text(sub, style: T.capSm.copyWith(fontFeatures: T.tabular)),
                  if (flaggedText != null) ...[
                    const SizedBox(height: 2),
                    StatusBadge(label: flaggedText!, tone: BadgeTone.crit, icon: Icons.error_outline),
                  ],
                  if (extraLabel != null) ...[
                    const SizedBox(height: 2),
                    StatusBadge(label: extraLabel!),
                  ],
                ],
              ),
            ),
          ),
          Expanded(flex: 4, child: Text(minLow ? '$min ▼' : min, textAlign: TextAlign.right, style: minLow ? flagStyle : numStyle)),
          Expanded(flex: 4, child: Text(avg, textAlign: TextAlign.right, style: numStyle)),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(maxHigh ? '$max ▲' : max, textAlign: TextAlign.right, style: maxHigh ? flagStyle : numStyle),
            ),
          ),
        ],
      ),
    );
  }
}
