import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

enum BtnVariant { green, navy, gray, red, dangerOutline }

class _BtnSpec {
  const _BtnSpec({
    required this.bg,
    required this.border,
    required this.fg,
    this.shadow,
    this.splash,
  });

  final Color bg;
  final Color border;
  final Color fg;
  final List<BoxShadow>? shadow;
  final Color? splash;
}

/// Modern tactile Material 3 button: clean high-contrast fills, subtle colored
/// elevation, smooth press-scale feedback, ink ripple, and haptic confirmation.
/// `loading` locks the button at once so a reading can't be saved twice.
class TactileButton extends StatefulWidget {
  const TactileButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BtnVariant.gray,
    this.icon,
    this.trailingIcon,
    this.height = 56,
    this.fontSize = 16.5,
    this.loading = false,
    this.expand = true,
    this.horizontalPadding = 16,
    this.borderOverride,
  });

  final String label;
  final VoidCallback? onPressed;
  final BtnVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;
  final double fontSize;
  final bool loading;
  final bool expand;
  final double horizontalPadding;
  final Color? borderOverride;

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _down = false;

  _BtnSpec _spec(bool enabled) {
    if (!enabled) {
      if (widget.variant == BtnVariant.green) {
        return const _BtnSpec(
          bg: Color(0xFFBBF7D0),
          border: Color(0xFF86EFAC),
          fg: Color(0xFF166534),
        );
      }
      return const _BtnSpec(
        bg: Color(0xFFF1F5F9),
        border: Color(0xFFE2E8F0),
        fg: C.muted,
      );
    }

    switch (widget.variant) {
      case BtnVariant.green:
        return const _BtnSpec(
          bg: C.saveBase,
          border: C.saveBase,
          fg: Colors.white,
          splash: Color(0x2EFFFFFF),
          shadow: [
            BoxShadow(color: Color(0x3315803D), blurRadius: 10, offset: Offset(0, 4)),
          ],
        );
      case BtnVariant.navy:
        return const _BtnSpec(
          bg: C.navyBase,
          border: C.navyBase,
          fg: Colors.white,
          splash: Color(0x2EFFFFFF),
          shadow: [
            BoxShadow(color: Color(0x2E0F5C7A), blurRadius: 10, offset: Offset(0, 4)),
          ],
        );
      case BtnVariant.red:
        return const _BtnSpec(
          bg: C.errBorder,
          border: C.errBorder,
          fg: Colors.white,
          splash: Color(0x2EFFFFFF),
          shadow: [
            BoxShadow(color: Color(0x33DC2626), blurRadius: 10, offset: Offset(0, 4)),
          ],
        );
      case BtnVariant.dangerOutline:
        return _BtnSpec(
          bg: C.errBg,
          border: widget.borderOverride ?? const Color(0xFFFECACA),
          fg: C.errText,
          splash: const Color(0x1ADC2626),
        );
      case BtnVariant.gray:
        return _BtnSpec(
          bg: C.panel,
          border: widget.borderOverride ?? C.borderStrong,
          fg: C.text,
          splash: const Color(0x140F172A),
          shadow: const [
            BoxShadow(color: Color(0x0A0F172A), blurRadius: 6, offset: Offset(0, 2)),
          ],
        );
    }
  }

  void _setDown(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  void _handleTap() {
    if (widget.variant == BtnVariant.green || widget.variant == BtnVariant.red) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final spec = _spec(enabled);
    final style = T.button.copyWith(fontSize: widget.fontSize, color: spec.fg);

    final children = <Widget>[];
    if (widget.loading) {
      children.add(
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: spec.fg),
        ),
      );
      children.add(const SizedBox(width: 10));
    } else if (widget.icon != null) {
      children.add(Icon(widget.icon, size: 21, color: spec.fg));
      children.add(const SizedBox(width: 8));
    }

    final text = Text(
      widget.label,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
    children.add(widget.expand ? Flexible(child: text) : text);

    if (widget.trailingIcon != null) {
      children.add(const SizedBox(width: 6));
      children.add(Icon(widget.trailingIcon, size: 21, color: spec.fg));
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: (_down && enabled) ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: D.animFast,
          curve: D.animCurve,
          constraints: BoxConstraints(minHeight: widget.height),
          decoration: BoxDecoration(
            color: spec.bg,
            borderRadius: D.radius,
            border: Border.all(color: spec.border, width: 1.25),
            boxShadow: (_down || !enabled) ? null : spec.shadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: D.radius,
              splashColor: spec.splash,
              highlightColor: spec.splash,
              onTapDown: enabled ? (_) => _setDown(true) : null,
              onTapUp: enabled ? (_) => _setDown(false) : null,
              onTapCancel: enabled ? () => _setDown(false) : null,
              onTap: enabled ? _handleTap : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.horizontalPadding,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: widget.expand ? double.infinity : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: widget.height - 18),
                    child: Row(
                      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
