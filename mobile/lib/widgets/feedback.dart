// Two feedback channels used the same way everywhere:
//  - ask(): a blocking dialog for decisions (delete, replace, discard). Buttons
//    name the action ("Delete reading", not "OK"); the destructive one is red;
//    Cancel is always present.
//  - showToast(): a short message after an action, with an optional Undo
//    (forgiveness, Nielsen #3).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'app_text.dart';
import 'button.dart';
import 'layout.dart';

class DialogBtn {
  const DialogBtn(this.id, this.label, [this.variant = BtnVariant.secondary]);
  final String id;
  final String label;
  final BtnVariant variant;
}

/// Shows a decision dialog. Returns the id of the tapped button, or null if dismissed.
Future<String?> ask(
  BuildContext context, {
  required String title,
  String? body,
  IconData? icon,
  Color iconColor = C.primary,
  required List<DialogBtn> buttons,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: C.scrim,
    transitionDuration: const Duration(milliseconds: 180),
    transitionBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    pageBuilder: (ctx, _, __) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Sp.lg),
          child: Material(
            color: C.surface,
            borderRadius: BorderRadius.circular(R.lg),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Sp.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...gapped([
                    if (icon != null) Align(alignment: Alignment.centerLeft, child: Icon(icon, size: 36, color: iconColor)),
                    AppText(title, variant: TextVariant.title, header: true),
                    if (body != null) AppText(body, color: C.textMuted),
                  ], Sp.sm),
                  const SizedBox(height: Sp.lg),
                  ...gapped([
                    for (final b in buttons)
                      AppButton(label: b.label, variant: b.variant, onPressed: () => Navigator.of(ctx).pop(b.id)),
                  ], Sp.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Toast {
  _Toast(this.message, this.actionLabel, this.onAction, this.info);
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool info;
}

/// Shows a toast above the tab bar.
void showToast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction, bool info = false}) {
  final host = context.findAncestorStateOfType<ToastHostState>();
  host?._show(_Toast(message, actionLabel, onAction, info));
  SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context));
}

/// Sits above the Navigator (MaterialApp.builder) so toasts survive page changes.
class ToastHost extends StatefulWidget {
  const ToastHost({super.key, required this.child});
  final Widget child;

  @override
  State<ToastHost> createState() => ToastHostState();
}

class ToastHostState extends State<ToastHost> {
  _Toast? _toast;
  Timer? _timer;

  void _show(_Toast t) {
    _timer?.cancel();
    setState(() => _toast = t);
    _timer = Timer(Duration(seconds: t.actionLabel != null ? 6 : 3), _hide);
  }

  void _hide() {
    _timer?.cancel();
    if (mounted) setState(() => _toast = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _toast;
    final bottom = MediaQuery.paddingOf(context).bottom + 88;
    return Stack(
      children: [
        widget.child,
        if (t != null)
          Positioned(
            left: Sp.lg,
            right: Sp.lg,
            bottom: bottom,
            child: Material(
              color: C.toastBg,
              borderRadius: BorderRadius.circular(R.md),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
                child: Semantics(
                  liveRegion: true,
                  child: Gap(
                    gap: Sp.md,
                    children: [
                      Icon(t.info ? Mdi.information : Mdi.checkCircle, size: 24, color: C.toastIcon),
                      Expanded(child: AppText(t.message, color: Colors.white, weight: W.medium)),
                      if (t.actionLabel != null)
                        Semantics(
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              t.onAction?.call();
                              _hide();
                            },
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 44),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                              child: AppText(t.actionLabel!, weight: W.bold, color: C.toastAction),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
