import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum PanelAccent { normal, warn, ok, memo }

/// Modern elevated surface card with hairline border, soft icon badge,
/// and smooth accent transitions. Preserves the exact BoxedPanel API.
class BoxedPanel extends StatelessWidget {
  const BoxedPanel({
    super.key,
    this.title,
    this.leadingIcon,
    this.trailing,
    required this.child,
    this.accent = PanelAccent.normal,
    this.padding = const EdgeInsets.all(16),
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
    Color headerBg = Colors.transparent;
    Color headerDivider = C.divider;
    Color iconBg = C.navyTint;
    Color iconColor = C.navyBase;
    Color titleColor = C.text;

    switch (accent) {
      case PanelAccent.warn:
        bg = C.panel;
        border = C.warnDivider;
        borderWidth = 1.5;
        headerBg = C.warnBg;
        headerDivider = C.warnDivider;
        iconBg = const Color(0xFFFEF3C7);
        iconColor = C.warnText;
        titleColor = C.warnText;
        break;
      case PanelAccent.ok:
        bg = C.panel;
        border = C.okDivider;
        borderWidth = 1.5;
        headerBg = C.okBg;
        headerDivider = C.okDivider;
        iconBg = const Color(0xFFDCFCE7);
        iconColor = C.okText;
        titleColor = C.okText;
        break;
      case PanelAccent.memo:
        bg = C.memoBg;
        border = C.memoBorder;
        borderWidth = 1;
        headerBg = Colors.transparent;
        headerDivider = C.warnDivider;
        iconBg = C.memoHeader;
        iconColor = C.memoIcon;
        titleColor = C.memoIcon;
        break;
      case PanelAccent.normal:
        break;
    }

    return AnimatedContainer(
      duration: D.animMed,
      curve: D.animCurve,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: D.radiusLg,
        border: Border.all(color: border, width: borderWidth),
        boxShadow: D.panelShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              AnimatedContainer(
                duration: D.animMed,
                curve: D.animCurve,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                decoration: BoxDecoration(
                  color: headerBg,
                  border: Border(bottom: BorderSide(color: headerDivider)),
                ),
                child: Row(
                  children: [
                    if (leadingIcon != null) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: D.radiusSm,
                        ),
                        child: Icon(leadingIcon, size: 18, color: iconColor),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          title!,
                          style: T.h.copyWith(color: titleColor),
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),
              ),
            Padding(padding: padding, child: child),
            if (footer != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
