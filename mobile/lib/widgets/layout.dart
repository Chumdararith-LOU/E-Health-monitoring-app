import 'package:flutter/material.dart';

import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'app_text.dart';

/// Puts [gap] between children. A SectionTitle sits closer to what follows it.
List<Widget> gapped(List<Widget> items, [double gap = Sp.lg]) {
  final out = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    if (i > 0) out.add(SizedBox(height: items[i - 1] is SectionTitle ? gap - Sp.sm : gap));
    out.add(items[i]);
  }
  return out;
}

/// Screen: scrollable content + optional sticky footer.
/// Rule used everywhere: the main action of a screen sits in the footer, full
/// width, at the bottom (easy to reach with the thumb, always in the same place).
class AppScreen extends StatelessWidget {
  const AppScreen({super.key, required this.children, this.footer = const [], this.padded = true});

  final List<Widget> children;
  final List<Widget> footer;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: C.bg,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: padded
                  ? const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.xxl)
                  : const EdgeInsets.only(bottom: Sp.xxl),
              children: gapped(children),
            ),
          ),
          if (footer.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(Sp.lg, Sp.md, Sp.lg, inset > Sp.md ? inset : Sp.md),
              decoration: const BoxDecoration(
                color: C.surface,
                border: Border(top: BorderSide(color: C.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: gapped(footer, Sp.sm),
              ),
            ),
        ],
      ),
    );
  }
}

class CardTone {
  const CardTone(this.bg, this.border);
  final Color bg;
  final Color border;

  static const ok = CardTone(C.okSoft, C.okBorder);
  static const low = CardTone(C.lowSoft, C.lowBorder);
  static const high = CardTone(C.highSoft, C.highBorder);
}

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.children,
    this.onTap,
    this.semanticLabel,
    this.tone,
    this.padding = const EdgeInsets.all(Sp.lg),
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final CardTone? tone;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final pressed = _down && widget.onTap != null;
    final box = Container(
      width: double.infinity,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: pressed ? C.surfaceAlt : (widget.tone?.bg ?? C.surface),
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: pressed ? C.borderStrong : (widget.tone?.border ?? C.border)),
      ),
      child: Column(
        crossAxisAlignment: widget.crossAxisAlignment,
        children: gapped(widget.children, Sp.md),
      ),
    );
    if (widget.onTap == null) return box;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: box,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32),
      child: Row(
        children: [
          Expanded(
            child: AppText(text, variant: TextVariant.label, weight: W.semibold, color: C.textMuted, header: true),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// A row with [gap] between children, vertically centred.
class Gap extends StatelessWidget {
  const Gap({super.key, required this.children, this.gap = Sp.sm, this.crossAxisAlignment = CrossAxisAlignment.center});
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) out.add(SizedBox(width: gap));
      out.add(children[i]);
    }
    return Row(crossAxisAlignment: crossAxisAlignment, children: out);
  }
}

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: 1, width: double.infinity, child: ColoredBox(color: C.divider));
}

/// A tappable list row with icon, title, subtitle and chevron. At least 56 dp tall.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.right,
    this.onTap,
    this.danger = false,
    this.iconColor,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? right;
  final VoidCallback? onTap;
  final bool danger;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Touch.min),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.sm),
        child: Gap(
          gap: Sp.md,
          children: [
            if (icon != null) Icon(icon, size: 26, color: iconColor ?? (danger ? C.danger : C.primary)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(title, weight: W.medium, color: danger ? C.danger : C.text),
                  if (subtitle != null) AppText(subtitle!, variant: TextVariant.caption, color: C.textMuted),
                ],
              ),
            ),
            if (right != null) right!,
            if (onTap != null && right == null) const Icon(Mdi.chevronRight, size: 26, color: C.textMuted),
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title, $subtitle',
      excludeSemantics: true,
      child: InkWell(onTap: onTap, highlightColor: C.surfaceAlt, splashColor: Colors.transparent, child: content),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.action});
  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Sp.xxl, horizontal: Sp.lg),
      child: Column(
        children: gapped([
          Icon(icon, size: 48, color: C.textMuted),
          AppText(title, variant: TextVariant.heading, align: TextAlign.center),
          if (body != null) AppText(body!, color: C.textMuted, align: TextAlign.center),
          if (action != null) action!,
        ], Sp.sm),
      ),
    );
  }
}

enum BannerKind { info, warning, error, success }

/// Inline message (info / warning / error). Icon + text, never colour alone.
class AppBanner extends StatelessWidget {
  const AppBanner({super.key, this.kind = BannerKind.info, required this.text, this.icon});
  final BannerKind kind;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, defIcon) = switch (kind) {
      BannerKind.info => (C.primarySoft, C.primary, Mdi.informationOutline),
      BannerKind.warning => (C.lowSoft, C.low, Mdi.alertOutline),
      BannerKind.error => (C.dangerSoft, C.danger, Mdi.alertCircleOutline),
      BannerKind.success => (C.okSoft, C.ok, Mdi.checkCircleOutline),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Sp.md),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(R.md)),
        child: Gap(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon ?? defIcon, size: 22, color: fg)),
            Expanded(child: AppText(text, variant: TextVariant.label)),
          ],
        ),
      ),
    );
  }
}
