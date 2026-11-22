// History (FR-09, US-05, US-06): newest first, date-range filter, missed-day
// rows, OCR/Manual/Edited badges, Edit + Delete on your own entries.

import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import '../common/labels.dart';
import '../record/review_screen.dart';

class _Item {
  const _Item.reading(this.reading) : day = null;
  const _Item.missed(this.day) : reading = null;
  final Reading? reading;
  final DateTime? day;
}

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  static const _pageSize = 10;
  DateTime? _from;
  DateTime? _to;
  int _page = 0;

  Future<void> _pick(bool isFrom, DateTime current, DateTime first, DateTime last) async {
    final d = await showDatePicker(context: context, initialDate: current, firstDate: first, lastDate: last);
    if (!mounted || d == null) return;
    setState(() {
      if (isFrom) {
        _from = d;
      } else {
        _to = d;
      }
      if (_from != null && _to != null && _from!.isAfter(_to!)) {
        final t = _from;
        _from = _to;
        _to = t;
      }
      _page = 0;
    });
  }

  Future<void> _delete(L l, AppState st, Reading r) async {
    final ok = await showConfirmModal<bool>(
      context,
      title: l.delTitle,
      tone: Severity.error,
      icon: Icons.delete_outline,
      sideBySide: true,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: C.panelHeader, border: Border.all(color: C.border), borderRadius: D.radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.dayTime(r.time), style: T.bodyB),
            Text(
              l.n([
                if (r.hasBp) '${r.bpText} mmHg',
                if (r.pulse != null) '${r.pulse} bpm',
                if (r.glucose != null) '${Fields.glu.fmt(r.glucose!)} mg/dL',
              ].join(' · ')),
              style: T.bodySm.copyWith(fontFeatures: T.tabular),
            ),
          ],
        ),
      ),
      message: l.delBody,
      actions: [
        ModalAction<bool>(l.cancel, false),
        ModalAction<bool>(l.delete, true, variant: BtnVariant.red, icon: Icons.delete_outline),
      ],
    );
    if (ok == true) st.deleteReading(r);
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final l = L.of(context);
    final today = st.today;
    final all = st.readings;
    final earliest = all.isEmpty ? today : MockData.dateOnly(all.last.time);

    final to = _to ?? today;
    final from = _from ?? DateTime(today.year, today.month, today.day - 6);

    // Build day-by-day items, newest first.
    final items = <_Item>[];
    var count = 0;
    final days = (to.difference(from).inHours / 24).round();
    for (var i = 0; i <= days; i++) {
      final d = DateTime(to.year, to.month, to.day - i);
      final dayReadings = all.where((r) => MockData.dateOnly(r.time) == d).toList();
      if (dayReadings.isEmpty) {
        if (d != today && !d.isBefore(earliest)) items.add(_Item.missed(d));
      } else {
        for (final r in dayReadings) {
          items.add(_Item.reading(r));
          count++;
        }
      }
    }

    final pages = (items.length / _pageSize).ceil();
    final page = pages == 0 ? 0 : _page.clamp(0, pages - 1).toInt();
    final shown = items.skip(page * _pageSize).take(_pageSize).toList();

    final children = <Widget>[
      _filter(l, from, to, earliest, today),
      Text(l.newestFirst(count), style: T.cap),
    ];

    if (count == 0) {
      children.add(BoxedPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.noReadingsBetween(l.day(from), l.day(to)), style: T.body),
            const SizedBox(height: 12),
            TactileButton(
              label: l.showAll,
              icon: Icons.calendar_month_outlined,
              height: 48,
              fontSize: 16,
              onPressed: () => setState(() {
                _from = earliest;
                _to = today;
                _page = 0;
              }),
            ),
          ],
        ),
      ));
    }

    for (final it in shown) {
      children.add(it.reading != null ? _card(l, st, it.reading!) : _missed(l, it.day!));
    }

    if (pages > 1) {
      final a = page * _pageSize + 1;
      final b = (page * _pageSize + shown.length);
      children.add(Row(
        children: [
          Expanded(child: Text(l.pageOf(a, b, items.length), style: T.cap)),
          TactileButton(label: l.prev, height: 44, fontSize: 15, expand: false, onPressed: page > 0 ? () => setState(() => _page = page - 1) : null),
          const SizedBox(width: 8),
          TactileButton(label: l.next, height: 44, fontSize: 15, expand: false, onPressed: page < pages - 1 ? () => setState(() => _page = page + 1) : null),
        ],
      ));
    }

    return ListView(padding: const EdgeInsets.all(16), children: gapped(children, 14));
  }

  Widget _filter(L l, DateTime from, DateTime to, DateTime earliest, DateTime today) {
    final first = DateTime(today.year - 1, today.month, today.day);
    Widget dateBox(String label, DateTime value, bool isFrom) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: T.cap.copyWith(fontWeight: FontWeight.w600, color: C.text)),
          Semantics(
            button: true,
            label: '$label ${l.numericDate(value)}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => _pick(isFrom, value, first, today),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: C.panel,
                  border: Border.all(color: C.borderInput),
                  borderRadius: D.radius,
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 1, offset: Offset(0, 1))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 17, color: C.text2),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(l.numericDate(value), style: T.label.copyWith(fontSize: 15, fontFeatures: T.tabular)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: C.panelHeader, border: Border.all(color: C.border), borderRadius: D.radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dateBox(l.from, from, true)),
              const SizedBox(width: 10),
              Expanded(child: dateBox(l.to, to, false)),
            ],
          ),
          const SizedBox(height: 10),
          TactileButton(
            label: l.showAll,
            icon: Icons.calendar_month_outlined,
            height: 44,
            fontSize: 15,
            onPressed: () => setState(() {
              _from = earliest;
              _to = today;
              _page = 0;
            }),
          ),
        ],
      ),
    );
  }

  Widget _missed(L l, DateTime d) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: C.warnBg, border: Border.all(color: C.warnBorder), borderRadius: D.radius),
      child: Row(
        children: [
          Expanded(child: Text(l.day(d), style: T.bodyB)),
          StatusBadge(label: l.missedRow, tone: BadgeTone.warn, icon: Icons.schedule),
        ],
      ),
    );
  }

  Widget _card(L l, AppState st, Reading r) {
    final p = st.activePatient;
    final canEdit = st.canEdit(r);
    final valueStyle = T.valueSm;

    Widget cell(String label, String value, bool flagged, String unit) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: T.capSm),
            Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(l.n(value), style: valueStyle),
                  ),
                ),
                if (flagged) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.error_outline, size: 18, color: C.errBorder, semanticLabel: l.high),
                ],
              ],
            ),
            Text(unit, style: T.capSm),
          ],
        );

    final actions = <Widget>[];
    if (canEdit) {
      actions.add(TactileButton(
        label: l.edit,
        icon: Icons.edit_outlined,
        height: 48,
        fontSize: 15,
        expand: false,
        onPressed: () => Navigator.of(context).push(fastRoute<void>(ReviewScreen(editing: r))),
      ));
      actions.add(const SizedBox(width: 8));
      actions.add(TactileButton(
        label: l.delete,
        icon: Icons.delete_outline,
        height: 48,
        fontSize: 15,
        expand: false,
        variant: BtnVariant.dangerOutline,
        onPressed: () => _delete(l, st, r),
      ));
    } else if (r.hasPhoto) {
      actions.add(TactileButton(
        label: l.viewPhoto,
        icon: Icons.photo_outlined,
        height: 48,
        fontSize: 15,
        expand: false,
        onPressed: () => showPhotoDialog(context, reading: r),
      ));
    }

    return Container(
      decoration: BoxDecoration(color: C.panel, border: Border.all(color: C.border), borderRadius: D.radius, boxShadow: D.panelShadow),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: const BoxDecoration(color: C.panelHeader, border: Border(bottom: BorderSide(color: C.border))),
              child: Row(
                children: [
                  Expanded(child: Text(l.dayTime(r.time), style: T.h)),
                  if (r.pendingSync) ...[
                    StatusBadge(label: l.pendingSync, tone: BadgeTone.warn, icon: Icons.schedule),
                    const SizedBox(width: 6),
                  ],
                  MethodBadge(method: r.method),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: cell(l.bp, r.hasBp ? r.bpText : '—', r.bpFlagged, 'mmHg')),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: cell(l.pulse, r.pulse?.toString() ?? '—', r.pulseFlagged, 'bpm')),
                  const SizedBox(width: 8),
                  Expanded(flex: 5, child: cell(l.glucose, r.glucose == null ? '—' : Fields.glu.fmt(r.glucose!), r.gluFlagged, 'mg/dL')),
                ],
              ),
            ),
            if (r.flagged)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(label: flagText(l, r), tone: BadgeTone.crit, icon: Icons.error_outline),
                ),
              ),
            if (r.note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Text('“${r.note}”', style: T.cap.copyWith(fontStyle: FontStyle.italic)),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              decoration: const BoxDecoration(color: C.footer, border: Border(top: BorderSide(color: C.divider))),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 6,
                spacing: 8,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.recordedBy(authorLabel(l, r, p)), style: T.cap),
                      if (!canEdit && st.role != Role.family)
                        Text(l.onlyAuthorEdits(authorName(l, r, p)), style: T.capSm),
                    ],
                  ),
                  if (actions.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: actions),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
