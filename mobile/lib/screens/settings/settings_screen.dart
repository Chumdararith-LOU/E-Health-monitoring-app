// Settings: language and numerals (US-15), text size, reminder time (US-17),
// care team / linked patients, normal ranges, demo reset, sign out.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/ranges.dart';
import '../../data/types.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../links/link_screens.dart';
import '../shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final t = i18n.t;
    final user = st.user;
    if (user == null) return const SizedBox.shrink();
    final s = st.settings;
    void set(Settings v) => st.setSettings(v);
    void shiftReminder(int d) =>
        set(s.copyWith(reminderMinutes: math.min(11 * 60, math.max(4 * 60, s.reminderMinutes + d))));

    return AppScreen(children: [
      AppCard(children: [
        Gap(gap: Sp.md, children: [
          const Icon(Mdi.accountCircle, size: 56, color: C.primary),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppText(t('signedInAs'), variant: TextVariant.caption, color: C.textMuted),
              AppText(i18n.name(user), variant: TextVariant.heading),
              AppText('${i18n.role(user.role)} · ${i18n.digits(user.phone)}', variant: TextVariant.label, color: C.textMuted),
            ]),
          ),
        ]),
      ]),
      SectionTitle(t('language')),
      AppCard(children: [
        Segmented<Lang>(
          label: t('language'),
          value: s.lang,
          onChanged: (v) => set(s.copyWith(lang: v)),
          options: const [SegOption(Lang.km, 'ខ្មែរ'), SegOption(Lang.en, 'English')],
        ),
        AppText(t('numerals'), variant: TextVariant.label, weight: W.semibold),
        Segmented<Numerals>(
          label: t('numerals'),
          value: s.numerals,
          onChanged: (v) => set(s.copyWith(numerals: v)),
          options: [SegOption(Numerals.western, t('numeralsWestern')), SegOption(Numerals.khmer, t('numeralsKhmer'))],
        ),
        AppText(t('textSize'), variant: TextVariant.label, weight: W.semibold),
        Segmented<double>(
          label: t('textSize'),
          value: s.textScale,
          onChanged: (v) => set(s.copyWith(textScale: v)),
          options: [SegOption(1, t('textNormal')), SegOption(1.15, t('textLarge')), SegOption(1.3, t('textXL'))],
        ),
      ]),
      if (user.role == Role.patient) ...[
        SectionTitle(t('reminder')),
        AppCard(children: [
          Gap(children: [
            const Icon(Mdi.bellRingOutline, size: 26, color: C.primary),
            Expanded(child: AppText(t('reminder'), weight: W.medium)),
            AppToggle(value: s.reminderOn, onChanged: (v) => set(s.copyWith(reminderOn: v)), label: t('reminder')),
          ]),
          if (s.reminderOn) ...[
            const AppDivider(),
            AppText(t('reminderTime'), variant: TextVariant.label, color: C.textMuted),
            Semantics(
              liveRegion: true,
              child: AppText(i18n.timeOfMinutes(s.reminderMinutes), variant: TextVariant.title, align: TextAlign.center),
            ),
            Gap(gap: Sp.md, children: [
              Expanded(
                child: AppButton(
                  compact: true,
                  variant: BtnVariant.secondary,
                  icon: Mdi.minus,
                  label: t('earlier'),
                  onPressed: () => shiftReminder(-15),
                ),
              ),
              Expanded(
                child: AppButton(
                  compact: true,
                  variant: BtnVariant.secondary,
                  icon: Mdi.plus,
                  label: t('later'),
                  onPressed: () => shiftReminder(15),
                ),
              ),
            ]),
            AppText(t('reminderHint'), variant: TextVariant.caption, color: C.textMuted),
          ],
        ]),
      ],
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xs),
        children: [
          if (user.role == Role.patient)
            ListRow(icon: Mdi.accountGroupOutline, title: t('careTeam'), onTap: () => push(context, const CareTeamScreen()))
          else
            ListRow(
              icon: Mdi.accountMultipleOutline,
              title: t('linkedPatients'),
              subtitle: st.patients.map(i18n.name).join(', '),
              onTap: () => push(context, const CareTeamScreen()),
            ),
        ],
      ),
      SectionTitle(t('ranges')),
      AppCard(children: [
        for (final k in measureOrder)
          Gap(children: [
            Expanded(child: AppText(t('m_${k.name}'))),
            AppText('${i18n.n(measures[k]!.normalMin)}–${i18n.n(measures[k]!.normalMax)}', weight: W.semibold),
            SizedBox(width: 52, child: AppText(measures[k]!.unit, variant: TextVariant.caption, color: C.textMuted)),
          ]),
        AppText(t('rangesHint'), variant: TextVariant.caption, color: C.textMuted),
      ]),
      SectionTitle(t('aboutDemo')),
      AppCard(children: [
        AppText(t('aboutDemoBody'), variant: TextVariant.label),
        AppText('${t('version')} ${i18n.digits('1.0.0')} (demo)', variant: TextVariant.caption, color: C.textMuted),
        AppButton(
          variant: BtnVariant.secondary,
          icon: Mdi.restore,
          label: t('resetDemo'),
          onPressed: () async {
            final c = await ask(
              context,
              title: t('resetConfirmTitle'),
              body: t('resetConfirmBody'),
              icon: Mdi.restoreAlert,
              iconColor: C.danger,
              buttons: [DialogBtn('reset', t('reset'), BtnVariant.danger), DialogBtn('cancel', t('cancel'))],
            );
            if (c == 'reset' && context.mounted) {
              st.resetData();
              showToast(context, t('resetDone'));
            }
          },
        ),
      ]),
      AppButton(
        variant: BtnVariant.dangerGhost,
        icon: Mdi.logout,
        label: t('signOut'),
        onPressed: () async {
          final c = await ask(
            context,
            title: t('signOutConfirm'),
            buttons: [DialogBtn('out', t('signOut'), BtnVariant.danger), DialogBtn('cancel', t('cancel'))],
          );
          if (c == 'out') st.signOut();
        },
      ),
    ]);
  }
}
