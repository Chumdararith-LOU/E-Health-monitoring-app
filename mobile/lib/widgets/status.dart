import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum Severity { ok, warn, error, info }

class SeverityStyle {
  const SeverityStyle(this.bg, this.border, this.fg, this.icon);
  final Color bg;
  final Color border;
  final Color fg;
  final IconData icon;

  static SeverityStyle of(Severity s) {
    switch (s) {
      case Severity.ok:
        return const SeverityStyle(C.okBg, C.okBorder, C.okText, Icons.check_circle_rounded);
      case Severity.warn:
        return const SeverityStyle(C.warnBg, C.warnBorder, C.warnText, Icons.warning_rounded);
      case Severity.error:
        return const SeverityStyle(C.errBg, C.errBorder, C.errText, Icons.error_rounded);
      case Severity.info:
        return const SeverityStyle(C.infoBg, C.infoBorder, C.infoText, Icons.info_rounded);
    }
  }
}

/// Soft-tinted rounded clinical banner with circular icon medallion.
/// Dual-coded (icon + tonal fill + text) and never auto-dismisses.
class StatusAlertBanner extends StatelessWidget {
  const StatusAlertBanner({
    super.key,
    required this.severity,
    required this.message,
    this.title,
    this.action,
    this.icon,
  });

  final Severity severity;
  final String message;
  final String? title;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final s = SeverityStyle.of(severity);
    return Semantics(
      liveRegion: severity == Severity.error,
      container: true,
      child: AnimatedContainer(
        duration: D.animMed,
        curve: D.animCurve,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: s.bg,
          borderRadius: D.radius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: s.border.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon ?? s.icon, size: 19, color: s.fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(title!, style: T.h.copyWith(color: s.fg)),
                    const SizedBox(height: 2),
                  ],
                  Text(message, style: T.bodySm.copyWith(color: s.fg)),
                  if (action != null) ...[
                    const SizedBox(height: 10),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum BadgeTone { crit, warn, ok, info, gray }

/// Soft-tinted rounded pill badge: icon + crisp bold text. Never a colour dot.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.tone = BadgeTone.gray, this.icon});

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    Color bg = C.inputUnit;
    Color fg = C.text2;
    switch (tone) {
      case BadgeTone.crit:
        bg = C.errBg;
        fg = C.errText;
        break;
      case BadgeTone.warn:
        bg = C.warnBg;
        fg = C.warnText;
        break;
      case BadgeTone.ok:
        bg = C.okBg;
        fg = C.okText;
        break;
      case BadgeTone.info:
        bg = C.infoBg;
        fg = C.infoText;
        break;
      case BadgeTone.gray:
        bg = C.inputUnit;
        fg = C.text2;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: D.radiusPill,
      ),
      // Text.rich (not Row + Flexible) so the badge works both in rows
      // (sizes to its text) and in narrow columns (wraps).
      child: Text.rich(
        TextSpan(children: [
          if (icon != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(icon, size: 15, color: fg),
              ),
            ),
          TextSpan(text: label),
        ]),
        style: T.badge.copyWith(color: fg, fontFeatures: T.tabular),
      ),
    );
  }
}

/// Small coloured hint line under a field (soft flag, error, low confidence).
class FieldHint extends StatelessWidget {
  const FieldHint({super.key, required this.severity, required this.text, this.icon});

  final Severity severity;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final s = SeverityStyle.of(severity);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(icon ?? s.icon, size: 17, color: s.fg),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: T.cap.copyWith(
              color: s.fg,
              fontWeight: severity == Severity.error ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
