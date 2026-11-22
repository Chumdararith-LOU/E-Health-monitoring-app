import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum BtnVariant { green, navy, gray, red, dangerOutline }

class _BtnSpec {
  const _BtnSpec({this.gradient, this.flat, required this.border, required this.fg, this.textShadow = false});
  final Gradient? gradient;
  final Color? flat;
  final Color border;
  final Color fg;
  final bool textShadow;
}

/// The only button style in the app: 1px darker border, subtle vertical
/// gradient, top highlight, and a visible 1px press-down.
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
    this.fontSize = 17,
    this.loading = false,
    this.expand = true,
    this.horizontalPadding = 14,
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
        return const _BtnSpec(flat: Color(0xFFA5D6A7), border: Color(0xFF81C784), fg: Colors.white);
      }
      return const _BtnSpec(flat: Color(0xFFF1F3F5), border: Color(0xFFD8DEE4), fg: C.muted);
    }
    switch (widget.variant) {
      case BtnVariant.green:
        return _BtnSpec(
          gradient: _down
              ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1E5A22), Color(0xFF2E7D32)])
              : D.greenGradient,
          border: C.saveBorder,
          fg: Colors.white,
          textShadow: true,
        );
      case BtnVariant.navy:
        return _BtnSpec(
          gradient: _down
              ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF143554), Color(0xFF1F4E79)])
              : D.navyGradient,
          border: C.navyDark,
          fg: Colors.white,
        );
      case BtnVariant.red:
        return _BtnSpec(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _down ? const [Color(0xFF9A1515), Color(0xFFC62828)] : const [Color(0xFFD32F2F), Color(0xFFB71C1C)],
          ),
          border: const Color(0xFF8E1414),
          fg: Colors.white,
          textShadow: true,
        );
      case BtnVariant.dangerOutline:
        return _BtnSpec(
          gradient: _down ? null : D.grayGradient,
          flat: _down ? const Color(0xFFF5D5D8) : null,
          border: C.errBorder,
          fg: C.errText,
        );
      case BtnVariant.gray:
        return _BtnSpec(
          gradient: _down ? null : D.grayGradient,
          flat: _down ? const Color(0xFFD5DCE3) : null,
          border: widget.borderOverride ?? C.borderInput,
          fg: C.text,
        );
    }
  }

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final spec = _spec(enabled);
    final style = T.button.copyWith(
      fontSize: widget.fontSize,
      color: spec.fg,
      shadows: spec.textShadow ? const [Shadow(color: Color(0x59000000), offset: Offset(0, 1))] : null,
    );

    final children = <Widget>[];
    if (widget.loading) {
      children.add(SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: spec.fg)));
      children.add(const SizedBox(width: 10));
    } else if (widget.icon != null) {
      children.add(Icon(widget.icon, size: 22, color: spec.fg));
      children.add(const SizedBox(width: 8));
    }
    final text = Text(widget.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: style);
    // Flexible only when the button has a bounded width to share.
    children.add(widget.expand ? Flexible(child: text) : text);
    if (widget.trailingIcon != null) {
      children.add(const SizedBox(width: 6));
      children.add(Icon(widget.trailingIcon, size: 22, color: spec.fg));
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: Container(
          constraints: BoxConstraints(minHeight: widget.height),
          decoration: BoxDecoration(
            gradient: spec.gradient,
            color: spec.gradient == null ? spec.flat : null,
            borderRadius: D.radius,
            border: Border.all(color: spec.border),
          ),
          foregroundDecoration: _down && enabled ? const BoxDecoration(borderRadius: D.radius, gradient: D.insetShade) : null,
          child: Stack(
            children: [
              if (enabled && !_down)
                const Positioned(left: 1, right: 1, top: 0, child: SizedBox(height: 1, child: ColoredBox(color: Color(0x40FFFFFF)))),
              Padding(
                padding: EdgeInsets.fromLTRB(widget.horizontalPadding, _down ? 7 : 6, widget.horizontalPadding, _down ? 5 : 6),
                child: SizedBox(
                  width: widget.expand ? double.infinity : null,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: widget.height - 14),
                    child: Row(
                      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: children,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
