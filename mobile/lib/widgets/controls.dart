import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/ranges.dart';
import '../state/app_state.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'app_text.dart';
import 'layout.dart';

enum BadgeLevel { normal, high, low, missed }

BadgeLevel badgeOf(Level l) => switch (l) {
      Level.normal => BadgeLevel.normal,
      Level.high => BadgeLevel.high,
      Level.low => BadgeLevel.low,
    };

/// Status = icon + word + colour. Same look in every list, card and tooltip.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.level, {super.key, this.small = false});
  final BadgeLevel level;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final i18n = AppScope.of(context).i18n;
    final (fg, bg, icon, label) = switch (level) {
      BadgeLevel.normal => (C.ok, C.okSoft, Mdi.checkCircle, i18n.t('lvl_normal')),
      BadgeLevel.high => (C.high, C.highSoft, Mdi.arrowUpBoldCircle, i18n.t('lvl_high')),
      BadgeLevel.low => (C.low, C.lowSoft, Mdi.arrowDownBoldCircle, i18n.t('lvl_low')),
      BadgeLevel.missed => (C.missed, C.missedSoft, Mdi.calendarRemove, i18n.t('missed')),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: small ? 16 : 18, color: fg),
            const SizedBox(width: 4),
            AppText(label, variant: small ? TextVariant.caption : TextVariant.label, weight: W.semibold, color: fg),
          ],
        ),
      ),
    );
  }
}

/// A small coloured pill with an icon and text (dashboard flags).
class FlagPill extends StatelessWidget {
  const FlagPill({super.key, required this.icon, required this.text, required this.fg, required this.bg});
  final IconData icon;
  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          AppText(text, variant: TextVariant.caption, weight: W.semibold, color: fg),
        ],
      ),
    );
  }
}

class SegOption<T> {
  const SegOption(this.value, this.label);
  final T value;
  final String label;
}

/// Segmented control for 2–4 mutually exclusive options (period, language, text size).
class Segmented<T> extends StatelessWidget {
  const Segmented({super.key, required this.options, required this.value, required this.onChanged, this.label});
  final List<SegOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: C.surface,
          border: Border.all(color: C.primary, width: 1.5),
          borderRadius: BorderRadius.circular(R.md),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < options.length; i++)
                Expanded(child: _item(context, options[i], i == options.length - 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, SegOption<T> o, bool last) {
    final on = o.value == value;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: on,
      button: true,
      label: o.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!on) {
            HapticFeedback.selectionClick();
            onChanged(o.value);
          }
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: Touch.compact),
          padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
          decoration: BoxDecoration(
            color: on ? C.primary : null,
            border: last ? null : const Border(right: BorderSide(color: C.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (on && options.length <= 3) ...[
                const Icon(Mdi.check, size: 18, color: C.onPrimary),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: AppText(
                  o.label,
                  variant: TextVariant.label,
                  weight: on ? W.semibold : W.medium,
                  color: on ? C.onPrimary : C.text,
                  align: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter chip.
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, required this.onTap, this.selected = false, this.icon});
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final lead = selected ? Mdi.check : icon;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: Touch.compact - 4),
          padding: const EdgeInsets.symmetric(horizontal: Sp.md),
          decoration: BoxDecoration(
            color: selected ? C.primarySoft : C.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? C.primary : C.borderStrong, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lead != null) ...[
                Icon(lead, size: 18, color: selected ? C.primary : C.textMuted),
                const SizedBox(width: 4),
              ],
              AppText(label, variant: TextVariant.label, weight: W.medium, color: selected ? C.primary : C.text),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text input with the label above and help / warning / error text below.
/// An error replaces the help text; an icon marks it.
class AppField extends StatefulWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.hint,
    this.error,
    this.warning,
    this.right,
    this.large = false,
    this.placeholder,
    this.keyboardType,
    this.obscure = false,
    this.maxLength,
    this.multiline = false,
    this.minHeight,
    this.autofocus = false,
    this.centered = false,
    this.letterSpacing,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? error;
  final String? warning;
  final Widget? right;
  final bool large;
  final String? placeholder;
  final TextInputType? keyboardType;
  final bool obscure;
  final int? maxLength;
  final bool multiline;
  final double? minHeight;
  final bool autofocus;
  final bool centered;
  final double? letterSpacing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(AppField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _own)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final error = widget.error;
    final borderColor = error != null
        ? C.danger
        : focused
            ? C.focus
            : widget.warning != null
                ? C.low
                : C.borderStrong;
    final sample = widget.controller.text.isEmpty ? (widget.placeholder ?? '') : widget.controller.text;
    final style = appStyle(
      context,
      sample,
      size: widget.large ? 32 : TextVariant.body.size,
      weight: widget.large ? W.semibold : W.regular,
    ).copyWith(letterSpacing: widget.letterSpacing, height: widget.multiline ? null : 1.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(widget.label, variant: TextVariant.label, weight: W.semibold),
        const SizedBox(height: Sp.xs),
        Container(
          constraints: BoxConstraints(minHeight: widget.minHeight ?? (widget.large ? 64 : Touch.min)),
          padding: const EdgeInsets.only(right: Sp.sm),
          decoration: BoxDecoration(
            color: C.surface,
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: borderColor, width: focused || error != null ? 2 : 1.5),
          ),
          child: Row(
            crossAxisAlignment: widget.multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  label: widget.label,
                  hint: error ?? widget.hint,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    autofocus: widget.autofocus,
                    obscureText: widget.obscure,
                    keyboardType: widget.keyboardType ?? (widget.multiline ? TextInputType.multiline : null),
                    textInputAction: widget.textInputAction,
                    maxLines: widget.multiline ? null : 1,
                    minLines: widget.multiline && widget.minHeight != null ? 5 : 1,
                    inputFormatters: [
                      if (widget.maxLength != null) LengthLimitingTextInputFormatter(widget.maxLength),
                    ],
                    textAlign: widget.centered ? TextAlign.center : TextAlign.start,
                    style: style,
                    cursorColor: C.focus,
                    onChanged: (v) {
                      setState(() {});
                      widget.onChanged?.call(v);
                    },
                    onSubmitted: widget.onSubmitted,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.placeholder,
                      hintStyle: style.copyWith(color: C.textDisabled),
                      contentPadding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.md),
                    ),
                  ),
                ),
              ),
              if (widget.right != null) widget.right!,
            ],
          ),
        ),
        if (error != null)
          _Msg(icon: Mdi.alertCircle, color: C.danger, text: error)
        else if (widget.warning != null)
          _Msg(icon: Mdi.alert, color: C.low, text: widget.warning!)
        else if (widget.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: Sp.xs),
            child: AppText(widget.hint!, variant: TextVariant.caption, color: C.textMuted),
          ),
      ],
    );
  }
}

class _Msg extends StatelessWidget {
  const _Msg({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Sp.xs),
      child: Semantics(
        liveRegion: true,
        child: Gap(
          gap: 4,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 3), child: Icon(icon, size: 18, color: color)),
            Expanded(child: AppText(text, variant: TextVariant.caption, color: color, weight: W.medium)),
          ],
        ),
      ),
    );
  }
}

class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.value, required this.onChanged, required this.label});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: Padding(
          padding: const EdgeInsets.all(Sp.sm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 60,
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: value ? C.primary : C.border, borderRadius: BorderRadius.circular(17)),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(value ? Mdi.check : Mdi.close, size: 16, color: value ? C.primary : C.textMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
