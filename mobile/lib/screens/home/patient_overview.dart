// One patient's status: today card, latest reading, last 7 days, doctor's
// notes. Used on the patient's Home and on the patient page for other roles.

import 'package:flutter/material.dart';

import '../../data/dates.dart';
import '../../data/ranges.dart';
import '../../data/stats.dart';
import '../../data/types.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../history/reading_detail_screen.dart';
import '../shell.dart';

/// Today's status: the single most important thing on Home (FR-13 / US-14).
class TodayCard extends StatelessWidget {
  const TodayCard({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final today = st.todayReadingOf(patientId);
    final recordable = st.canRecord(patientId);
    void goRecord() {
      if (st.user?.role != Role.patient) st.selectPatient(patientId);
      goToTab(context, AppTab.record);
    }

    Widget head(IconData icon, Color color, String text) => Gap(gap: Sp.md, children: [
          Icon(icon, size: 40, color: color),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppText('${t('todayStatus')} · ${i18n.date(DateTime.now())}', variant: TextVariant.caption, color: C.textMuted),
              AppText(text, variant: TextVariant.heading, color: color),
            ]),
          ),
        ]);

    if (today != null) {
      return AppCard(tone: CardTone.ok, children: [
        head(Mdi.checkCircle, C.ok, t('recordedToday', {'time': i18n.time(today.takenAt)})),
        if (recordable)
          AppButton(variant: BtnVariant.secondary, icon: Mdi.plus, label: t('addAnother'), onPressed: goRecord),
      ]);
    }
    return AppCard(tone: CardTone.low, children: [
      head(Mdi.clockAlertOutline, C.low, t('notRecordedToday')),
      if (recordable) ...[
        AppText(t('notRecordedHint'), variant: TextVariant.label),
        AppButton(icon: Mdi.plusCircle, label: t('recordNow'), onPressed: goRecord),
      ],
    ]);
  }
}

class PatientOverview extends StatelessWidget {
  const PatientOverview({super.key, required this.patientId, this.showToday = true});
  final String patientId;
  final bool showToday;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final all = st.readingsOf(patientId);
    final latest = all.isEmpty ? null : all.first;
    final week = inRange(all, lastNDays(7)).reversed.toList();
    final sys = statOf(week, (r) => r.systolic);
    final dia = statOf(week, (r) => r.diastolic);
    final glu = statOf(week, (r) => r.glucose);
    final now = DateTime.now();
    final days = [for (var i = 0; i < 7; i++) addDays(now, i - 6)];
    final recorded = {for (final r in week) dayKey(r.takenAt)};
    final hasToday = st.todayReadingOf(patientId) != null;
    final notes = st.data.notes.where((n) => n.patientId == patientId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    void openReports() {
      if (st.user?.role != Role.patient) st.selectPatient(patientId);
      goToTab(context, AppTab.reports);
    }

    Widget trendRow(String label, String value, String? unit, List<double> values) => Container(
          padding: const EdgeInsets.only(top: Sp.md),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.divider))),
          child: Gap(gap: Sp.md, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppText(label, variant: TextVariant.caption, color: C.textMuted),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: value),
                    if (unit != null)
                      TextSpan(text: ' $unit', style: appStyle(context, unit, variant: TextVariant.caption, color: C.textMuted)),
                  ]),
                  style: appStyle(context, value, variant: TextVariant.title, weight: W.semibold),
                ),
              ]),
            ),
            Sparkline(values: values, width: 110),
          ]),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: gapped([
        if (showToday) TodayCard(patientId: patientId),
        SectionTitle(t('latestReading')),
        if (latest != null)
          AppCard(
            semanticLabel: t('latestReading'),
            onTap: () => push(context, ReadingDetailScreen(id: latest.id)),
            children: [
              Row(children: [
                Expanded(
                  child: AppText('${i18n.dateRelative(latest.takenAt)} · ${i18n.time(latest.takenAt)}',
                      variant: TextVariant.label, color: C.textMuted),
                ),
                StatusBadge(badgeOf(readingLevel(latest))),
              ]),
              ReadingBlock(latest),
            ],
          )
        else
          AppCard(children: [
            EmptyState(icon: Mdi.clipboardTextOutline, title: t('noReadings'), body: t('noReadingsHint')),
          ]),
        SectionTitle(t('last7Days', {'n': 7})),
        AppCard(
          semanticLabel: t('seeReport'),
          onTap: openReports,
          children: [
            // 7 day dots: filled = recorded, dashed = missed, amber ring = today not yet
            Semantics(
              label: days.map((d) => '${i18n.dayName(d)} ${recorded.contains(dayKey(d)) ? '✓' : t('missed')}').join(', '),
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    _DayDot(
                      label: i18n.weekdayInitial(days[i]),
                      done: recorded.contains(dayKey(days[i])),
                      isToday: i == 6,
                      todayPending: i == 6 && !hasToday,
                    ),
                ],
              ),
            ),
            trendRow(
              '${t('bp')} · ${t('avg')}',
              sys.count > 0 ? '${i18n.n(sys.avg)}/${i18n.n(dia.avg)}' : '–',
              null,
              [for (final r in week) if (r.systolic != null) r.systolic!],
            ),
            trendRow(
              '${t('m_glucose')} · ${t('avg')}',
              glu.count > 0 ? i18n.n(glu.avg) : '–',
              'mg/dL',
              [for (final r in week) if (r.glucose != null) r.glucose!],
            ),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              AppText(t('seeReport'), variant: TextVariant.label, weight: W.semibold, color: C.primary),
              const Icon(Mdi.chevronRight, size: 22, color: C.primary),
            ]),
          ],
        ),
        if (notes.isNotEmpty) ...[
          SectionTitle(t('doctorNotes')),
          for (final n in notes.take(2))
            AppCard(children: [
              Gap(children: [
                const Icon(Mdi.stethoscope, size: 22, color: C.primary),
                Expanded(
                  child: AppText(i18n.name(st.userById(n.authorId)), variant: TextVariant.label, weight: W.semibold),
                ),
                AppText(i18n.dateShort(n.createdAt), variant: TextVariant.caption, color: C.textMuted),
              ]),
              AppText(n.text),
            ]),
        ],
      ]),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.label, required this.done, required this.isToday, required this.todayPending});
  final String label;
  final bool done;
  final bool isToday;
  final bool todayPending;

  @override
  Widget build(BuildContext context) {
    Widget dot;
    if (done) {
      dot = Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(color: C.primary, shape: BoxShape.circle),
        child: const Icon(Mdi.check, size: 16, color: C.onPrimary),
      );
    } else if (todayPending) {
      dot = Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.low, width: 2)),
      );
    } else {
      dot = const CustomPaint(size: Size(30, 30), painter: _DashedCircle());
    }
    return Column(children: [
      dot,
      const SizedBox(height: 4),
      AppText(label, variant: TextVariant.caption, color: isToday ? C.text : C.textMuted, weight: isToday ? W.bold : W.regular),
    ]);
  }
}

class _DashedCircle extends CustomPainter {
  const _DashedCircle();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = C.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    const n = 12;
    const sweep = 2 * 3.141592653589793 / n;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.55, false, p);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle old) => false;
}
