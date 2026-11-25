import 'package:flutter/material.dart';

import '../data/ranges.dart';
import '../data/types.dart';
import '../state/app_state.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'app_text.dart';
import 'controls.dart';
import 'layout.dart';

Color _levelColor(Level? l) => switch (l) {
      Level.high => C.high,
      Level.low => C.low,
      Level.normal => C.text,
      null => C.textMuted,
    };

/// A single value; out-of-range values get colour AND an arrow icon.
class ValueText extends StatelessWidget {
  const ValueText(this.k, this.v, {super.key, this.variant = TextVariant.display});
  final MeasureKey k;
  final double? v;
  final TextVariant variant;

  @override
  Widget build(BuildContext context) {
    final i18n = AppScope.of(context).i18n;
    final lvl = levelOf(k, v);
    final color = _levelColor(lvl);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lvl == Level.high || lvl == Level.low) ...[
          Icon(lvl == Level.high ? Mdi.arrowUpBold : Mdi.arrowDownBold,
              size: variant == TextVariant.display ? 24 : 16, color: color),
          const SizedBox(width: 2),
        ],
        AppText(i18n.n(v), variant: variant, weight: W.semibold, color: color),
      ],
    );
  }
}

/// Large block used on Home and Reading detail: BP | Pulse, then Glucose.
class ReadingBlock extends StatelessWidget {
  const ReadingBlock(this.r, {super.key});
  final Reading r;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    Widget cap(String s) => AppText(s, variant: TextVariant.caption, color: C.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: gapped([
        if (r.hasBp || r.pulse != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.hasBp)
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    cap(i18n.t('bp')),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        ValueText(MeasureKey.systolic, r.systolic),
                        const AppText('/', variant: TextVariant.title, color: C.textMuted),
                        ValueText(MeasureKey.diastolic, r.diastolic),
                      ],
                    ),
                    cap('mmHg'),
                  ]),
                ),
              if (r.hasBp && r.pulse != null) const SizedBox(width: Sp.lg),
              if (r.pulse != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 80),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    cap(i18n.t('m_pulse')),
                    ValueText(MeasureKey.pulse, r.pulse),
                    cap('bpm'),
                  ]),
                ),
            ],
          ),
        if (r.glucose != null)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            cap(i18n.t('m_glucose')),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              ValueText(MeasureKey.glucose, r.glucose),
              const SizedBox(width: 6),
              Padding(padding: const EdgeInsets.only(bottom: 6), child: cap('mg/dL')),
            ]),
          ]),
        for (final f in st.data.fields)
          if (r.extra[f.id] != null)
            Wrap(spacing: Sp.sm, crossAxisAlignment: WrapCrossAlignment.end, children: [
              AppText('${i18n.name(f)}:', color: C.textMuted),
              AppText('${i18n.n(r.extra[f.id], f.decimals)} ${f.unit}', weight: W.semibold),
            ]),
      ], Sp.md),
    );
  }
}

/// Compact row for History lists. Same layout for every role.
class ReadingRow extends StatelessWidget {
  const ReadingRow(this.r, {super.key, this.onTap});
  final Reading r;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final level = readingLevel(r);
    final author = st.userById(r.enteredBy);
    final parts = [
      if (r.systolic != null) '${i18n.t('bp')} ${i18n.n(r.systolic)}/${i18n.n(r.diastolic)}',
      if (r.glucose != null) '${i18n.t('m_glucose')} ${i18n.n(r.glucose)}',
    ];
    Widget unit(String s) => AppText(' $s', variant: TextVariant.caption, color: C.textMuted);

    final content = Container(
      constraints: const BoxConstraints(minHeight: Touch.min),
      padding: const EdgeInsets.symmetric(vertical: Sp.md, horizontal: Sp.lg),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppText(i18n.dateRelative(r.takenAt), variant: TextVariant.label, weight: W.semibold),
              AppText(i18n.time(r.takenAt), variant: TextVariant.caption, color: C.textMuted),
            ]),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (r.systolic != null)
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
                  ValueText(MeasureKey.systolic, r.systolic, variant: TextVariant.body),
                  const AppText('/', color: C.textMuted),
                  ValueText(MeasureKey.diastolic, r.diastolic, variant: TextVariant.body),
                  unit('mmHg'),
                ]),
              if (r.glucose != null)
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
                  const Icon(Mdi.waterOutline, size: 16, color: C.textMuted),
                  ValueText(MeasureKey.glucose, r.glucose, variant: TextVariant.body),
                  unit('mg/dL'),
                ]),
              const SizedBox(height: 2),
              Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: Sp.sm, runSpacing: 2, children: [
                StatusBadge(badgeOf(level), small: true),
                Icon(r.method == EntryMethod.ocr ? Mdi.cameraOutline : Mdi.keyboardOutline, size: 16, color: C.textMuted),
                if (r.note != null) const Icon(Mdi.noteTextOutline, size: 16, color: C.textMuted),
                if (author != null && author.id != r.patientId)
                  AppText(i18n.name(author), variant: TextVariant.caption, color: C.textMuted, maxLines: 1),
              ]),
            ]),
          ),
          if (onTap != null) const Icon(Mdi.chevronRight, size: 24, color: C.textMuted),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      label:
          '${i18n.dateRelative(r.takenAt)} ${i18n.time(r.takenAt)}. ${parts.join(', ')}. ${i18n.t('lvl_${level.name}')}',
      excludeSemantics: true,
      child: Material(
        color: C.surface,
        child: InkWell(onTap: onTap, highlightColor: C.surfaceAlt, splashColor: Colors.transparent, child: content),
      ),
    );
  }
}
