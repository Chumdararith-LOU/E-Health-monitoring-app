import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

class SegOption<V> {
  const SegOption(this.value, this.label, {this.icon});
  final V value;
  final String label;
  final IconData? icon;
}

/// Modern sliding-thumb segmented control on a soft slate track.
/// Used for report periods, device type, glucose unit, and settings toggles.
class SegmentedToggle<V> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.height = 46,
    this.fontSize = 14.5,
    this.semanticLabel,
  });

  final List<SegOption<V>> options;
  final V selected;
  final ValueChanged<V>? onChanged;
  final double height;
  final double fontSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    final count = options.length;
    final selectedIdx = options.indexWhere((o) => o.value == selected);
    final alignX = count <= 1 || selectedIdx < 0
        ? 0.0
        : -1.0 + (2.0 * selectedIdx / (count - 1));

    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: C.inputUnit,
          borderRadius: D.radius,
          border: Border.all(color: C.border),
        ),
        child: Stack(
          children: [
            if (selectedIdx >= 0)
              Positioned.fill(
                child: AnimatedAlign(
                  duration: D.animMed,
                  curve: D.animCurve,
                  alignment: Alignment(alignX, 0),
                  child: FractionallySizedBox(
                    widthFactor: 1 / count,
                    heightFactor: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: C.panel,
                        borderRadius: D.radiusSm,
                        border: Border.all(color: C.border.withValues(alpha: 0.7)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x140F172A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final o in options)
                    Expanded(
                      child: _SegmentItem(
                        option: o,
                        selected: o.value == selected,
                        minHeight: (height - 8).clamp(36, 80).toDouble(),
                        fontSize: fontSize,
                        onTap: onChanged == null
                            ? null
                            : () {
                                if (o.value != selected) {
                                  HapticFeedback.selectionClick();
                                }
                                onChanged!(o.value);
                              },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentItem<V> extends StatelessWidget {
  const _SegmentItem({
    required this.option,
    required this.selected,
    required this.minHeight,
    required this.fontSize,
    required this.onTap,
  });

  final SegOption<V> option;
  final bool selected;
  final double minHeight;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? C.navyBase : C.text2;
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (option.icon != null) ...[
                Icon(option.icon, size: 18, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: D.animFast,
                  curve: D.animCurve,
                  style: T.button.copyWith(
                    fontSize: fontSize,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                    fontFeatures: T.tabular,
                  ),
                  child: Text(
                    option.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
