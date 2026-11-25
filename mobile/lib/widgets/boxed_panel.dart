import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum PanelAccent { normal, warn, ok, memo }

/// A page section: a plain heading on the canvas, then its content.
///
/// By default the content sits on a borderless white surface (for forms and
/// lists). `open: true` drops the surface so the content sits straight on the
/// page. `PanelAccent.memo` draws a quote with a left accent rule; `ok` and
/// `warn` tint the surface. No header bands, icon tiles or nested borders.
class BoxedPanel extends StatelessWidget {
  const BoxedPanel({
    super.key,
    this.title,
    this.leadingIcon,
    this.trailing,
    required this.child,
    this.accent = PanelAccent.normal,
    this.padding,
    this.footer,
    this.open = false,
  });

  final String? title;
  final IconData? leadingIcon;
  final Widget? trailing;
  final Widget child;
  final PanelAccent accent;

  /// Content padding. Defaults to 16 on a surface and none when open.
  final EdgeInsetsGeometry? padding;
  final Widget? footer;
  final bool open;

  @override
  Widget build(BuildContext context) {
    if (accent == PanelAccent.memo) return _memo();

    final heading = title == null ? null : _heading(C.text, C.text2);

    if (open) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (heading != null) ...[heading, const SizedBox(height: Sp.s2)],
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
          if (footer != null) ...[const SizedBox(height: Sp.s3), footer!],
        ],
      );
    }

    final bg = switch (accent) {
      PanelAccent.ok => C.okBg,
      PanelAccent.warn => C.warnBg,
      _ => C.panel,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading != null) ...[heading, const SizedBox(height: Sp.s2)],
        AnimatedContainer(
          duration: D.animMed,
          curve: D.animCurve,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: bg, borderRadius: D.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(padding: padding ?? const EdgeInsets.all(Sp.s4), child: child),
              if (footer != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.s4, vertical: Sp.s3),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: C.divider)),
                  ),
                  child: footer,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heading(Color fg, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.s1),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 18, color: iconColor),
            const SizedBox(width: Sp.s2),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title!, style: T.h.copyWith(color: fg)),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Sp.s2),
            trailing!,
          ],
        ],
      ),
    );
  }

  Widget _memo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(Sp.s3, Sp.s1, 0, Sp.s1),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: C.memoBorder, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[_heading(C.memoIcon, C.memoIcon), const SizedBox(height: Sp.s1)],
          Padding(padding: padding ?? const EdgeInsets.symmetric(horizontal: Sp.s1), child: child),
          if (footer != null) ...[const SizedBox(height: Sp.s2), footer!],
        ],
      ),
    );
  }
}
