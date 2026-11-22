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
        return const SeverityStyle(C.okBg, C.okBorder, C.okText, Icons.check_circle_outline);
      case Severity.warn:
        return const SeverityStyle(C.warnBg, C.warnBorder, C.warnText, Icons.warning_amber_rounded);
      case Severity.error:
        return const SeverityStyle(C.errBg, C.errBorder, C.errText, Icons.cancel_outlined);
      case Severity.info:
        return const SeverityStyle(C.infoBg, C.infoBorder, C.infoText, Icons.info_outline);
    }
  }
}

/// Tinted box + 4px left bar + icon + plain text. Never auto-dismisses.
class StatusAlertBanner extends StatelessWidget {
  const StatusAlertBanner({super.key, required this.severity, required this.message, this.title, this.action, this.icon});

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
      child: Container(
        decoration: BoxDecoration(color: s.bg, borderRadius: D.radius, border: Border.all(color: s.border)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: s.border),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(icon ?? s.icon, size: 20, color: s.fg),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null) Text(title!, style: T.h.copyWith(color: s.fg)),
                              Text(message, style: T.bodySm.copyWith(color: s.fg)),
                              if (action != null) ...[const SizedBox(height: 8), action!],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum BadgeTone { crit, warn, ok, info, gray }

/// Small rectangular badge: border + icon + bold text. Never a colour dot.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.tone = BadgeTone.gray, this.icon});

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    Color bg = C.panelHeader;
    Color border = C.borderStrong;
    Color fg = C.text;
    switch (tone) {
      case BadgeTone.crit:
        bg = C.errBg;
        border = C.errBorder;
        fg = C.errText;
        break;
      case BadgeTone.warn:
        bg = C.warnBg;
        border = C.warnBorder;
        fg = C.warnText;
        break;
      case BadgeTone.ok:
        bg = C.okBg;
        border = C.okBorder;
        fg = C.okText;
        break;
      case BadgeTone.info:
        bg = C.infoBg;
        border = C.infoBorder;
        fg = C.infoText;
        break;
      case BadgeTone.gray:
        bg = C.panelHeader;
        border = C.borderStrong;
        fg = C.text;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(3)),
      // Text.rich (not Row + Flexible) so the badge works both in rows
      // (sizes to its text) and in narrow columns (wraps).
      child: Text.rich(
        TextSpan(children: [
          if (icon != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(padding: const EdgeInsets.only(right: 4), child: Icon(icon, size: 15, color: fg)),
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
        Padding(padding: const EdgeInsets.only(top: 4), child: Icon(icon ?? s.icon, size: 16, color: s.fg)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: T.cap.copyWith(color: s.fg, fontWeight: severity == Severity.error ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
