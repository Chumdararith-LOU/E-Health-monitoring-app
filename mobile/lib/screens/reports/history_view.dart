// History (FR-09, US-05, US-06): newest first, clean date-range filter card,
// soft missed-day rows, timeline vital cards, Edit + Delete on own entries.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    HapticFeedback.selectionClick();
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
      icon: Icons.delete_outline_rounded,
      sideBySide: true,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: C.panelHeader,
          border: Border.all(color: C.border),
          borderRadius: D.radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.dayTime(r.time), style: T.bodyB),
            const SizedBox(height: 2),
            Text(
              l.n([
                if (r.hasBp) '${r.bpText} mmHg',
                if (r.pulse != null) '${r.pulse} bpm',
                if (r.glucose != null) '${Fields.glu.fmt(r.glucose!)} mg/dL',
              ].join(' · ')),
              style: T.bodySm.copyWith(color: C.text2, fontFeatures: T.tabular),
            ),
          ],
        ),
      ),
      message: l.delBody,
      actions: [
        ModalAction<bool>(l.cancel, false),
        ModalAction<bool>(l.delete, true, variant: BtnVariant.red, icon: Icons.delete_outline_rounded),
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
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(l.newestFirst(count), style: T.cap.copyWith(fontWeight: FontWeight.w600)),
      ),
    ];

    if (count == 0) {
      children.add(
        BoxedPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.noReadingsBetween(l.day(from), l.day(to)), style: T.body),
              const SizedBox(height: 14),
              TactileButton(
                label: l.showAll,
                icon: Icons.calendar_month_outlined,
                variant: BtnVariant.navy,
                height: 48,
                fontSize: 15.5,
                onPressed: () => setState(() {
                  _from = earliest;
                  _to = today;
                  _page = 0;
                }),
              ),
            ],
          ),
        ),
      );
    }

    for (final it in shown) {
      children.add(it.reading != null ? _card(l, st, it.reading!) : _missed(l, it.day!));
    }

    if (pages > 1) {
      final a = page * _pageSize + 1;
      final b = page * _pageSize + shown.length;
      children.add(
        BoxedPanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(child: Text(l.pageOf(a, b, items.length), style: T.cap.copyWith(fontWeight: FontWeight.w600))),
              TactileButton(
                label: l.prev,
                height: 44,
                fontSize: 14.5,
                expand: false,
                onPressed: page > 0 ? () => setState(() => _page = page - 1) : null,
              ),
              const SizedBox(width: 8),
              TactileButton(
                label: l.next,
                height: 44,
                fontSize: 14.5,
                expand: false,
                onPressed: page < pages - 1 ? () => setState(() => _page = page + 1) : null,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: gapped(children, 14),
    );
  }

  Widget _filter(L l, DateTime from, DateTime to, DateTime earliest, DateTime today) {
    final first = DateTime(today.year - 1, today.month, today.day);
    Widget dateBox(String label, DateTime value, bool isFrom) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: T.capSm.copyWith(fontWeight: FontWeight.w700, color: C.text2)),
          const SizedBox(height: 4),
          Semantics(
            button: true,
            label: '$label ${l.numericDate(value)}',
            excludeSemantics: true,
            child: Material(
              color: C.inputUnit,
              borderRadius: D.radius,
              child: InkWell(
                borderRadius: D.radius,
                onTap: () => _pick(isFrom, value, first, today),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: C.border),
                    borderRadius: D.radius,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: C.navyBase),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.numericDate(value),
                          style: T.label.copyWith(fontSize: 14.5, fontFeatures: T.tabular),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return BoxedPanel(
      padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 12),
          TactileButton(
            label: l.showAll,
            icon: Icons.calendar_month_outlined,
            height: 44,
            fontSize: 14.5,
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
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: C.warnBg,
        border: Border.all(color: C.warnDivider, width: 1.25),
        borderRadius: D.radiusLg,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy_rounded, size: 18, color: C.warnText),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(l.day(d), style: T.bodyB.copyWith(color: C.warnText))),
          const SizedBox(width: 8),
          StatusBadge(label: l.missedRow, tone: BadgeTone.warn, icon: Icons.schedule_rounded),
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
            Text(label, style: T.capSm.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Row(
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.n(value),
                      style: flagged ? valueStyle.copyWith(color: C.errText) : valueStyle,
                    ),
                  ),
                ),
                if (flagged) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.error_rounded, size: 17, color: C.errBorder, semanticLabel: l.high),
                ],
              ],
            ),
            Text(unit, style: T.capSm.copyWith(color: C.hint)),
          ],
        );

    final actions = <Widget>[];
    if (canEdit) {
      actions.add(TactileButton(
        label: l.edit,
        icon: Icons.edit_outlined,
        height: 44,
        fontSize: 14.5,
        expand: false,
        horizontalPadding: 12,
        onPressed: () => Navigator.of(context).push(fastRoute<void>(ReviewScreen(editing: r))),
      ));
      actions.add(const SizedBox(width: 8));
      actions.add(TactileButton(
        label: l.delete,
        icon: Icons.delete_outline_rounded,
        height: 44,
        fontSize: 14.5,
        expand: false,
        horizontalPadding: 12,
        variant: BtnVariant.dangerOutline,
        onPressed: () => _delete(l, st, r),
      ));
    } else if (r.hasPhoto) {
      actions.add(TactileButton(
        label: l.viewPhoto,
        icon: Icons.photo_outlined,
        height: 44,
        fontSize: 14.5,
        expand: false,
        horizontalPadding: 12,
        onPressed: () => showPhotoDialog(context, reading: r),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: C.panel,
        border: Border.all(color: r.flagged ? C.errBorder.withValues(alpha: 0.35) : C.border),
        borderRadius: D.radiusLg,
        boxShadow: D.panelShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 10),
              child: Row(
                children: [
                  Expanded(child: Text(l.dayTime(r.time), style: T.h)),
                  if (r.pendingSync) ...[
                    StatusBadge(label: l.pendingSync, tone: BadgeTone.warn, icon: Icons.schedule_rounded),
                    const SizedBox(width: 6),
                  ],
                  MethodBadge(method: r.method),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: C.panelHeader,
                  borderRadius: D.radius,
                  border: Border.all(color: C.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: cell(l.bp, r.hasBp ? r.bpText : '—', r.bpFlagged, 'mmHg')),
                    const SizedBox(width: 8),
                    Expanded(flex: 4, child: cell(l.pulse, r.pulse?.toString() ?? '—', r.pulseFlagged, 'bpm')),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: cell(
                        l.glucose,
                        r.glucose == null ? '—' : Fields.glu.fmt(r.glucose!),
                        r.gluFlagged,
                        'mg/dL',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (r.flagged)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(label: flagText(l, r), tone: BadgeTone.crit, icon: Icons.error_rounded),
                ),
              ),
            if (r.note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: C.panelHeader,
                    borderRadius: D.radiusSm,
                    border: const Border(left: BorderSide(color: C.borderStrong, width: 3)),
                  ),
                  child: Text('“${r.note}”', style: T.cap.copyWith(fontStyle: FontStyle.italic)),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: C.footer,
                border: Border(top: BorderSide(color: C.divider)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
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
