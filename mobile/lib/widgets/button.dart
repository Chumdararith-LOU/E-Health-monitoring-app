import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'app_text.dart';

enum BtnVariant { primary, secondary, danger, ghost, dangerGhost }

class _Spec {
  const _Spec(this.bg, this.bgPressed, this.fg, this.border);
  final Color bg, bgPressed, fg, border;
}

const _specs = {
  BtnVariant.primary: _Spec(C.primary, C.primaryPressed, C.onPrimary, C.primary),
  BtnVariant.secondary: _Spec(C.surface, C.primarySoft, C.primary, C.primary),
  BtnVariant.danger: _Spec(C.danger, C.dangerPressed, C.onPrimary, C.danger),
  BtnVariant.ghost: _Spec(Color(0x00000000), C.primarySoft, C.primary, Color(0x00000000)),
  BtnVariant.dangerGhost: _Spec(Color(0x00000000), C.dangerSoft, C.danger, Color(0x00000000)),
};

/// One button for the whole app: same height, radius and pressed feedback everywhere.
/// It fills the width it is given (a stretched column or an Expanded) and
/// shrinks to its label otherwise.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BtnVariant.primary,
    this.icon,
    this.disabled = false,
    this.loading = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final BtnVariant variant;
  final IconData? icon;
  final bool disabled;
  final bool loading;
  final bool compact;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final s = _specs[widget.variant]!;
    final off = widget.disabled || widget.loading || widget.onPressed == null;
    final fg = off ? C.textDisabled : s.fg;
    final bg = off && widget.variant == BtnVariant.primary
        ? C.border
        : (_down && !off ? s.bgPressed : s.bg);
    final compact = widget.compact;

    Widget? lead;
    if (widget.loading) {
      lead = SizedBox(
        width: 22,
        height: 22,
        child: _Spinner(color: s.fg),
      );
    } else if (widget.icon != null) {
      lead = Icon(widget.icon, size: compact ? 20 : 24, color: fg);
    }

    final label = AppText(
      widget.label,
      variant: compact ? TextVariant.label : TextVariant.body,
      weight: W.semibold,
      color: fg,
      align: TextAlign.center,
    );

    return Semantics(
      button: true,
      enabled: !off,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: off ? null : (_) => _set(true),
        onTapUp: off ? null : (_) => _set(false),
        onTapCancel: off ? null : () => _set(false),
        onTap: off ? null : widget.onPressed,
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? Touch.compact : Touch.min),
          padding: EdgeInsets.symmetric(horizontal: compact ? Sp.md : Sp.lg, vertical: Sp.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: off ? C.border : s.border, width: 1.5),
          ),
          child: LayoutBuilder(
            builder: (context, c) => Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (lead != null) ...[lead, const SizedBox(width: Sp.sm)],
                c.hasBoundedWidth ? Flexible(child: label) : label,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small indeterminate spinner without pulling in Material.
class _Spinner extends StatefulWidget {
  const _Spinner({required this.color});
  final Color color;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: CustomPaint(painter: _ArcPainter(widget.color)),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Offset.zero & size, 0, 4.4, false, p);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
