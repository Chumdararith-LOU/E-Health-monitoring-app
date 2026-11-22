import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'status.dart';
import 'tactile_button.dart';

class ModalAction<V> {
  const ModalAction(this.label, this.value, {this.variant = BtnVariant.gray, this.icon, this.height = 56});
  final String label;
  final V value;
  final BtnVariant variant;
  final IconData? icon;
  final double height;
}

/// Centred bordered dialog with a tinted title bar. Used for destructive
/// confirms, the duplicate-morning guard and the discard prompt.
/// Returns the chosen action's value, or null if dismissed.
Future<V?> showConfirmModal<V>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? body,
  required List<ModalAction<V>> actions,
  Severity tone = Severity.warn,
  IconData? icon,
  bool sideBySide = false,
}) {
  final s = SeverityStyle.of(tone);
  return showGeneralDialog<V>(
    context: context,
    barrierDismissible: false,
    barrierLabel: title,
    barrierColor: C.scrim,
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      final buttons = actions
          .map((a) => TactileButton(
                label: a.label,
                variant: a.variant,
                icon: a.icon,
                height: a.height,
                borderOverride: a.variant == BtnVariant.gray ? C.text2 : null,
                onPressed: () => Navigator.of(ctx).pop(a.value),
              ))
          .toList();

      Widget actionArea;
      if (sideBySide) {
        final row = <Widget>[];
        for (var i = 0; i < buttons.length; i++) {
          if (i > 0) row.add(const SizedBox(width: 12));
          row.add(Expanded(child: buttons[i]));
        }
        actionArea = Row(crossAxisAlignment: CrossAxisAlignment.start, children: row);
      } else {
        final col = <Widget>[];
        for (var i = 0; i < buttons.length; i++) {
          if (i > 0) col.add(const SizedBox(height: 12));
          col.add(buttons[i]);
        }
        actionArea = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: col);
      }

      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  decoration: BoxDecoration(
                    color: C.panel,
                    borderRadius: D.radius,
                    border: Border.all(color: C.borderStrong),
                    boxShadow: D.modalShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: s.bg,
                              border: Border(bottom: BorderSide(color: s.border)),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(width: 4, color: s.border),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                                      child: Row(
                                        children: [
                                          Icon(icon ?? s.icon, size: 22, color: s.fg),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Semantics(
                                              header: true,
                                              child: Text(title, style: T.big.copyWith(color: s.fg)),
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
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (body != null) ...[body, const SizedBox(height: 14)],
                                if (message != null) ...[Text(message, style: T.body), const SizedBox(height: 16)],
                                actionArea,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
  );
}
