import 'package:flutter/material.dart';

import '../data/dates.dart';
import '../data/types.dart';
import '../state/app_state.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'app_text.dart';
import 'button.dart';
import 'layout.dart';

/// Bottom sheet: the same look for every picker.
Future<T?> showSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,

  /// False when the builder scrolls its own content (and adds its own footer).
  bool scroll = true,
}) {
  final closeLabel = AppScope.read(context).i18n.t('close');
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.surface,
    barrierColor: C.sheetScrim,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg))),
    builder: (ctx) {
      final inset = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, inset > Sp.lg ? inset : Sp.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.sm),
              child: Row(
                children: [
                  Expanded(child: AppText(title, variant: TextVariant.heading, header: true)),
                  Semantics(
                    button: true,
                    label: closeLabel,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const SizedBox(
                        width: Touch.compact,
                        height: Touch.compact,
                        child: Icon(Mdi.close, size: 28, color: C.text),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (scroll) _SheetScroll(child: builder(ctx)) else builder(ctx),
          ],
        ),
      );
    },
  );
}

class _SheetScroll extends StatelessWidget {
  const _SheetScroll({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: Sp.sm), child: child),
      );
}

/// Shows which patient the screen is about, for roles that see several
/// patients. Always at the top of History / Reports / Record, so users never
/// wonder "whose data is this?".
class PatientSwitcher extends StatelessWidget {
  const PatientSwitcher({super.key, this.labelKey = 'viewingFor'});

  /// 'viewingFor' or 'recordingFor'.
  final String labelKey;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final patient = st.patient;
    final user = st.user;
    if (patient == null || user == null || user.role == Role.patient) return const SizedBox.shrink();
    final i18n = st.i18n;
    final many = st.patients.length > 1;
    return Semantics(
      button: many,
      label: '${i18n.t(labelKey)}: ${i18n.name(patient)}. ${many ? i18n.t('switchPatient') : ''}',
      excludeSemantics: true,
      child: Material(
        color: C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.lg),
          side: const BorderSide(color: C.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: many ? () => _choose(context) : null,
          highlightColor: C.primarySoft,
          splashColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(minHeight: Touch.min),
            padding: const EdgeInsets.all(Sp.md),
            child: Gap(
              gap: Sp.md,
              children: [
                const Icon(Mdi.accountCircle, size: 36, color: C.primary),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(i18n.t(labelKey), variant: TextVariant.caption, color: C.textMuted),
                      AppText(i18n.name(patient), weight: W.semibold),
                    ],
                  ),
                ),
                if (many)
                  Container(
                    constraints: const BoxConstraints(minHeight: Touch.compact),
                    padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(i18n.t('change'), variant: TextVariant.label, weight: W.semibold, color: C.primary),
                        const Icon(Mdi.chevronDown, size: 22, color: C.primary),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _choose(BuildContext context) {
    final st = AppScope.read(context);
    showSheet<void>(
      context,
      title: st.i18n.t('choosePatient'),
      builder: (ctx) {
        final st = AppScope.of(ctx);
        final i18n = st.i18n;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: gapped([
            for (final p in st.patients)
              Builder(builder: (_) {
                final selected = p.id == st.patient?.id;
                final today = st.todayReadingOf(p.id);
                return Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: selected,
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      st.selectPatient(p.id);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: Touch.min),
                      padding: const EdgeInsets.all(Sp.md),
                      decoration: BoxDecoration(
                        color: selected ? C.primarySoft : null,
                        borderRadius: BorderRadius.circular(R.md),
                        border: Border.all(color: selected ? C.primary : C.border, width: 1.5),
                      ),
                      child: Gap(
                        gap: Sp.md,
                        children: [
                          Icon(selected ? Mdi.radioboxMarked : Mdi.radioboxBlank, size: 26,
                              color: selected ? C.primary : C.textMuted),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(i18n.name(p), weight: W.semibold),
                                AppText(
                                  today != null
                                      ? '✓ ${i18n.t('recordedToday', {'time': i18n.time(today.takenAt)})}'
                                      : i18n.t('notRecordedToday'),
                                  variant: TextVariant.caption,
                                  color: today != null ? C.ok : C.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ], Sp.sm),
        );
      },
    );
  }
}

/// Simple calendar: tap the first day, then the last day.
/// Returns (from, to) or null when closed.
Future<(DateTime, DateTime)?> showDateRangeSheet(BuildContext context, {(DateTime, DateTime)? initial}) {
  return showSheet<(DateTime, DateTime)>(
    context,
    title: AppScope.read(context).i18n.t('pickRange'),
    scroll: false,
    builder: (_) => _RangeCalendar(initial: initial),
  );
}

class _RangeCalendar extends StatefulWidget {
  const _RangeCalendar({this.initial});
  final (DateTime, DateTime)? initial;

  @override
  State<_RangeCalendar> createState() => _RangeCalendarState();
}

class _RangeCalendarState extends State<_RangeCalendar> {
  final _today = startOfDay(DateTime.now());
  late DateTime _month = DateTime(_today.year, _today.month);
  late DateTime? _a = widget.initial?.$1;
  late DateTime? _b = widget.initial == null ? null : startOfDay(widget.initial!.$2);

  DateTime? get _lo => _a != null && _b != null ? (_a!.isBefore(_b!) ? _a : _b) : _a;
  DateTime? get _hi => _a != null && _b != null ? (_a!.isBefore(_b!) ? _b : _a) : _a;

  (DateTime, DateTime)? get _result => _a == null ? null : (_lo!, _hi ?? _a!);

  void _tap(DateTime d) {
    setState(() {
      if (_a == null || _b != null) {
        _a = d;
        _b = null;
      } else {
        _b = d;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppScope.of(context).i18n;
    final lead = DateTime(_month.year, _month.month).weekday % 7;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= daysInMonth; d++) DateTime(_month.year, _month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final canNext = _month.year < _today.year || _month.month < _today.month;
    final lo = _lo, hi = _hi;

    Widget navBtn(IconData icon, bool enabled, VoidCallback onTap, String label) => Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onTap : null,
            child: SizedBox(
              width: Touch.compact,
              height: Touch.compact,
              child: Icon(icon, size: 30, color: enabled ? C.primary : C.border),
            ),
          ),
        );

    final calendar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: gapped([
        Container(
          padding: const EdgeInsets.all(Sp.md),
          decoration: BoxDecoration(color: C.surfaceAlt, borderRadius: BorderRadius.circular(R.md)),
          child: Gap(gap: Sp.md, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppText(i18n.t('from'), variant: TextVariant.caption, color: C.textMuted),
                AppText(lo != null ? i18n.date(lo) : '—', weight: W.semibold),
              ]),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppText(i18n.t('to'), variant: TextVariant.caption, color: C.textMuted),
                AppText(hi != null && _b != null ? i18n.date(hi) : '—', weight: W.semibold),
              ]),
            ),
          ]),
        ),
        AppText(
          _a == null || _b != null ? i18n.t('pickStart') : i18n.t('pickEnd'),
          variant: TextVariant.caption,
          color: C.primary,
          weight: W.semibold,
        ),
        Row(children: [
          navBtn(Mdi.chevronLeft, true, () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
              'previous month'),
          Expanded(child: AppText(i18n.monthYear(_month), weight: W.semibold, align: TextAlign.center)),
          navBtn(Mdi.chevronRight, canNext, () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
              'next month'),
        ]),
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth / 7;
          Widget cell(Widget child, {Color? bg}) => Container(width: w, height: 46, color: bg, alignment: Alignment.center, child: child);
          return Wrap(children: [
            for (final initial in i18n.weekdayInitials)
              cell(AppText(initial, variant: TextVariant.caption, color: C.textMuted)),
            for (final d in cells)
              if (d == null)
                cell(const SizedBox.shrink())
              else
                Builder(builder: (_) {
                  final future = d.isAfter(_today);
                  final edge = (lo != null && isSameDay(d, lo)) || (hi != null && isSameDay(d, hi));
                  final inside = lo != null && hi != null && d.isAfter(lo) && d.isBefore(hi);
                  final isToday = isSameDay(d, _today);
                  return Semantics(
                    button: true,
                    enabled: !future,
                    selected: edge,
                    label: i18n.date(d),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: future ? null : () => _tap(d),
                      child: cell(
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: edge ? C.primary : null,
                            border: isToday && !edge ? Border.all(color: C.primary, width: 1.5) : null,
                          ),
                          child: AppText(
                            i18n.digits('${d.day}'),
                            variant: TextVariant.label,
                            weight: edge ? W.bold : W.regular,
                            color: future ? C.textDisabled : (edge ? C.onPrimary : C.text),
                          ),
                        ),
                        bg: inside ? C.primarySoft : null,
                      ),
                    ),
                  );
                }),
          ]);
        }),
      ], Sp.sm),
    );

    final range = _result;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetScroll(child: calendar),
        const SizedBox(height: Sp.sm),
        AppButton(
          label: i18n.t('apply'),
          disabled: range == null,
          onPressed: () => Navigator.of(context).pop(range),
        ),
      ],
    );
  }
}
