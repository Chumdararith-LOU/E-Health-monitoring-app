import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum PanelAccent { normal, warn, ok, memo }

/// White box, 1px border, optional shaded title bar. No floating text.
class BoxedPanel extends StatelessWidget {
  const BoxedPanel({
    super.key,
    this.title,
    this.leadingIcon,
    this.trailing,
    required this.child,
    this.accent = PanelAccent.normal,
    this.padding = const EdgeInsets.all(14),
    this.footer,
  });

  final String? title;
  final IconData? leadingIcon;
  final Widget? trailing;
  final Widget child;
  final PanelAccent accent;
  final EdgeInsetsGeometry padding;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    Color bg = C.panel;
    Color border = C.border;
    double borderWidth = 1;
    Color headerBg = C.panelHeader;
    Color headerDivider = C.border;
    Color iconColor = C.text;

    switch (accent) {
      case PanelAccent.warn:
        border = C.warnBorder;
        borderWidth = 2;
        headerBg = C.warnBg;
        headerDivider = C.warnDivider;
        break;
      case PanelAccent.ok:
        border = C.okBorder;
        borderWidth = 2;
        headerBg = C.okBg;
        headerDivider = C.okDivider;
        break;
      case PanelAccent.memo:
        bg = C.memoBg;
        border = C.memoBorder;
        headerBg = C.memoHeader;
        headerDivider = C.memoBorder;
        iconColor = C.memoIcon;
        break;
      case PanelAccent.normal:
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: D.radius,
        border: Border.all(color: border, width: borderWidth),
        boxShadow: D.panelShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: headerBg,
                  border: Border(bottom: BorderSide(color: headerDivider)),
                ),
                child: Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 20, color: iconColor),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Semantics(header: true, child: Text(title!, style: T.h)),
                    ),
                    if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                  ],
                ),
              ),
            Padding(padding: padding, child: child),
            if (footer != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: const BoxDecoration(
                  color: C.footer,
                  border: Border(top: BorderSide(color: C.divider)),
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}
