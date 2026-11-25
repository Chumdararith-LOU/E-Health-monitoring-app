// Home tab (FR-13 / US-14, US-13, US-12). One screen per role:
// patient = own overview, caretaker & family = one card per patient,
// doctor = dashboard sorted by who needs attention.

import 'package:flutter/material.dart';

import '../../data/ranges.dart';
import '../../data/stats.dart';
import '../../data/types.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../links/link_screens.dart';
import '../shell.dart';
import 'patient_detail_screen.dart';
import 'patient_overview.dart';

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final h = DateTime.now().hour;
    final g = h < 12 ? 'goodMorning' : h < 17 ? 'goodAfternoon' : 'goodEvening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText('${i18n.t(g)}, ${i18n.name(st.user)}', variant: TextVariant.title),
        if (st.user?.role == Role.patient && st.settings.reminderOn)
          Gap(gap: 4, children: [
            const Icon(Mdi.bellRingOutline, size: 18, color: C.textMuted),
            Flexible(
              child: AppText(
                i18n.t('reminderAt', {'time': i18n.timeOfMinutes(st.settings.reminderMinutes)}),
                variant: TextVariant.caption,
                color: C.textMuted,
              ),
            ),
          ]),
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).user;
    if (user == null) return const SizedBox.shrink();
    return switch (user.role) {
      Role.patient => AppScreen(children: [const _Greeting(), PatientOverview(patientId: user.id)]),
      Role.doctor => const _DoctorDashboard(),
      _ => const _LinkedPatientsHome(),
    };
  }
}

String _ageLine(BuildContext context, AppUser p) {
  final i18n = AppScope.of(context).i18n;
  return '${i18n.t('age', {'n': p.age ?? 0})} · ${(i18n.isKm ? p.conditionsKm : p.conditionsEn) ?? ''}';
}

/// Caretaker and family: one card per linked patient, today's status first.
class _LinkedPatientsHome extends StatelessWidget {
  const _LinkedPatientsHome();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final isFamily = st.user?.role == Role.family;
    return AppScreen(children: [
      const _Greeting(),
      if (isFamily) AppBanner(icon: Mdi.eyeOutline, text: t('readOnly')),
      SectionTitle(isFamily ? t('myRelatives') : t('myPatients')),
      if (st.patients.isEmpty)
        AppCard(children: [
          EmptyState(
            icon: Mdi.accountMultiplePlusOutline,
            title: t('noLinkedPatients'),
            body: t('noLinkedPatientsHint'),
            action: AppButton(
              label: t('linkPatient'),
              icon: Mdi.linkVariantPlus,
              onPressed: () => push(context, const LinkPatientScreen()),
            ),
          ),
        ]),
      for (final p in st.patients)
        Builder(builder: (context) {
          final today = st.todayReadingOf(p.id);
          final rs = st.readingsOf(p.id);
          final latest = rs.isEmpty ? null : rs.first;
          return AppCard(
            semanticLabel: '${i18n.name(p)}. ${t('tapToOpen')}',
            onTap: () => push(context, PatientDetailScreen(patientId: p.id)),
            children: [
              Gap(children: [
                const Icon(Mdi.accountCircle, size: 40, color: C.primary),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AppText(i18n.name(p), variant: TextVariant.heading),
                    AppText(_ageLine(context, p), variant: TextVariant.caption, color: C.textMuted),
                  ]),
                ),
                const Icon(Mdi.chevronRight, size: 26, color: C.textMuted),
              ]),
              Gap(children: [
                Icon(today != null ? Mdi.checkCircle : Mdi.clockAlertOutline, size: 22, color: today != null ? C.ok : C.low),
                Expanded(
                  child: AppText(
                    today != null ? t('recordedToday', {'time': i18n.time(today.takenAt)}) : t('notRecordedToday'),
                    weight: W.semibold,
                    color: today != null ? C.ok : C.low,
                  ),
                ),
              ]),
              if (latest != null)
                Gap(children: [
                  Expanded(
                    child: AppText(
                      '${t('latest')}: ${[
                        if (latest.systolic != null) '${i18n.n(latest.systolic)}/${i18n.n(latest.diastolic)} mmHg',
                        if (latest.glucose != null) '${i18n.n(latest.glucose)} mg/dL',
                      ].join(' · ')}',
                      variant: TextVariant.label,
                      color: C.textMuted,
                    ),
                  ),
                  StatusBadge(badgeOf(readingLevel(latest)), small: true),
                ]),
              if (st.canRecord(p.id) && today == null)
                AppButton(
                  icon: Mdi.plusCircle,
                  label: t('recordNow'),
                  onPressed: () {
                    st.selectPatient(p.id);
                    goToTab(context, AppTab.record);
                  },
                ),
            ],
          );
        }),
    ]);
  }
}

/// FR-12 / US-12: one card per patient with the latest reading, 7-day average
/// and flags; sorted so patients who need attention come first.
class _DoctorDashboard extends StatelessWidget {
  const _DoctorDashboard();

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final rows = [for (final p in st.patients) (p, summarize(st.readingsOf(p.id)))]
      ..sort((a, b) => b.$2.attentionScore.compareTo(a.$2.attentionScore));
    final attention = rows.where((r) => r.$2.attentionScore > 0).length;

    Widget stat(String label, int value, {CardTone? tone, Color color = C.text}) => Expanded(
          child: AppCard(tone: tone, children: [
            AppText(label, variant: TextVariant.caption, color: C.textMuted),
            AppText(i18n.n(value), variant: TextVariant.display, color: color),
          ]),
        );

    String pair(double? s, double? d, double? g) => s != null ? '${i18n.n(s)}/${i18n.n(d)} · ${i18n.n(g)}' : '–';

    return AppScreen(children: [
      const _Greeting(),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          stat(t('needsAttention'), attention,
              tone: attention > 0 ? CardTone.high : null, color: attention > 0 ? C.high : C.text),
          const SizedBox(width: Sp.md),
          stat(t('allGood'), rows.length - attention),
        ]),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionTitle(t('dashboardTitle')),
        AppText(t('sortedByFlags'), variant: TextVariant.caption, color: C.textMuted),
      ]),
      for (final (p, s) in rows)
        AppCard(
          semanticLabel: '${i18n.name(p)}. ${t('tapToOpen')}',
          onTap: () => push(context, PatientDetailScreen(patientId: p.id)),
          children: [
            Gap(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AppText(i18n.name(p), variant: TextVariant.heading),
                  AppText(_ageLine(context, p), variant: TextVariant.caption, color: C.textMuted),
                ]),
              ),
              const Icon(Mdi.chevronRight, size: 26, color: C.textMuted),
            ]),
            Wrap(spacing: Sp.sm, runSpacing: Sp.sm, children: [
              if (s.latestLevel != null && s.latestLevel != Level.normal) StatusBadge(badgeOf(s.latestLevel!), small: true),
              if (s.outOfRange7 > 0)
                FlagPill(icon: Mdi.alert, text: t('outOfRangeDays', {'n': s.outOfRange7}), fg: C.high, bg: C.highSoft),
              if (s.missed7 > 0)
                FlagPill(icon: Mdi.calendarRemove, text: t('missedDays', {'n': s.missed7}), fg: C.missed, bg: C.missedSoft),
              if (s.attentionScore == 0) const StatusBadge(BadgeLevel.normal, small: true),
            ]),
            Container(
              padding: const EdgeInsets.only(top: Sp.md),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.divider))),
              child: Gap(gap: Sp.md, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AppText(
                      '${t('latest')}${s.latest != null ? ' · ${i18n.dateRelative(s.latest!.takenAt)}' : ''}',
                      variant: TextVariant.caption,
                      color: C.textMuted,
                    ),
                    AppText(pair(s.latest?.systolic, s.latest?.diastolic, s.latest?.glucose), weight: W.semibold),
                  ]),
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AppText(t('avg7', {'n': 7}), variant: TextVariant.caption, color: C.textMuted),
                    AppText(pair(s.avgSystolic, s.avgDiastolic, s.avgGlucose), weight: W.semibold),
                  ]),
                ),
              ]),
            ),
            const AppText('mmHg · mg/dL', variant: TextVariant.caption, color: C.textMuted),
          ],
        ),
      if (rows.isEmpty) EmptyState(icon: Mdi.accountMultipleOutline, title: t('noLinkedPatients')),
    ]);
  }
}
