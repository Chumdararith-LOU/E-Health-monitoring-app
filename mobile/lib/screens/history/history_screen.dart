// FR-09 / US-06: newest first, filter by date range, out-of-range marked.

import 'package:flutter/material.dart';

import '../../data/ranges.dart';
import '../../data/stats.dart';
import '../../data/types.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../shell.dart';
import 'reading_detail_screen.dart';

/// 7, 30, 90 days; 0 = all; -1 = custom.
const _all = 0, _custom = -1;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _period = 30;
  DayRange? _customRange;
  bool _onlyFlagged = false;

  Future<void> _pickRange() async {
    final c = _customRange;
    final r = await showDateRangeSheet(context, initial: c == null ? null : (c.from, c.to));
    if (r != null) {
      setState(() {
        _customRange = customRange(r.$1, r.$2);
        _period = _custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final patient = st.patient;
    var list = patient == null ? const <Reading>[] : st.readingsOf(patient.id);
    final c = _customRange;
    if (_period == _custom && c != null) {
      list = inRange(list, c);
    } else if (_period > 0) {
      list = inRange(list, lastNDays(_period));
    }
    if (_onlyFlagged) list = list.where(isOutOfRange).toList();

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: gapped([
          if (st.user?.role != Role.patient) const PatientSwitcher(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Gap(children: [
              for (final p in [7, 30, 90, _all])
                AppChip(
                  label: p == _all ? t('filterAll') : t('nDays', {'n': p}),
                  selected: _period == p,
                  onTap: () => setState(() => _period = p),
                ),
              AppChip(
                icon: Mdi.calendarRange,
                label: _period == _custom && c != null ? '${i18n.dateShort(c.from)} – ${i18n.dateShort(c.to)}' : t('filterCustom'),
                selected: _period == _custom,
                onTap: _pickRange,
              ),
            ]),
          ),
          Gap(children: [
            AppChip(
              icon: Mdi.alertOutline,
              label: t('onlyFlagged'),
              selected: _onlyFlagged,
              onTap: () => setState(() => _onlyFlagged = !_onlyFlagged),
            ),
            Expanded(
              child: AppText(t('readingsCount', {'n': list.length}),
                  variant: TextVariant.caption, color: C.textMuted, align: TextAlign.right),
            ),
          ]),
        ], Sp.md),
      ),
    );

    return ColoredBox(
      color: C.bg,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: Sp.xxl),
        itemCount: 1 + (list.isEmpty ? 1 : list.length),
        itemBuilder: (context, i) {
          if (i == 0) return header;
          if (list.isEmpty) return EmptyState(icon: Mdi.calendarSearch, title: t('noResults'));
          final idx = i - 1;
          final first = idx == 0, last = idx == list.length - 1;
          const r = Radius.circular(R.lg);
          final r0 = list[idx];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: Sp.lg),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.vertical(top: first ? r : Radius.zero, bottom: last ? r : Radius.zero),
              border: Border(
                left: const BorderSide(color: C.border),
                right: const BorderSide(color: C.border),
                top: first ? const BorderSide(color: C.border) : BorderSide.none,
                bottom: last ? const BorderSide(color: C.border) : BorderSide.none,
              ),
            ),
            child: Column(children: [
              if (!first) const AppDivider(),
              ReadingRow(r0, onTap: () => push(context, ReadingDetailScreen(id: r0.id))),
            ]),
          );
        },
      ),
    );
  }
}
