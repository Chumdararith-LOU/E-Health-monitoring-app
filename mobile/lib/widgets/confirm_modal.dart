import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'status.dart';
import 'tactile_button.dart';

class ModalAction<V> {
  const ModalAction(
    this.label,
    this.value, {
    this.variant = BtnVariant.gray,
    this.icon,
    this.height = 56,
  });

  final String label;
  final V value;
  final BtnVariant variant;
  final IconData? icon;
  final double height;
}

/// Thumb-reachable rounded bottom sheet with circular tonal severity badge.
/// Preserves strict non-dismissible behavior for destructive confirms,
/// duplicate-morning guards, and discard prompts.
/// Returns the chosen action's value, or null if dismissed programmatically.
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
  HapticFeedback.lightImpact();

  return showModalBottomSheet<V>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    barrierColor: C.scrim,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final buttons = actions
          .map(
            (a) => TactileButton(
              label: a.label,
              variant: a.variant,
              icon: a.icon,
              height: a.height,
              onPressed: () => Navigator.of(ctx).pop(a.value),
            ),
          )
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
          if (i > 0) col.add(const SizedBox(height: 10));
          col.add(buttons[i]);
        }
        actionArea = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: col);
      }

      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: const BoxDecoration(
              color: C.panel,
              borderRadius: BorderRadius.all(Radius.circular(24)),
              boxShadow: D.modalShadow,
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  20 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: C.borderStrong,
                          borderRadius: D.radiusPill,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: s.bg,
                            shape: BoxShape.circle,
                            border: Border.all(color: s.border.withValues(alpha: 0.35)),
                          ),
                          child: Icon(icon ?? s.icon, size: 22, color: s.fg),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(title, style: T.big.copyWith(color: C.text)),
                          ),
                        ),
                      ],
                    ),
                    if (body != null) ...[
                      const SizedBox(height: 16),
                      body,
                    ],
                    if (message != null) ...[
                      const SizedBox(height: 12),
                      Text(message, style: T.body.copyWith(color: C.text2)),
                    ],
                    const SizedBox(height: 20),
                    actionArea,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
