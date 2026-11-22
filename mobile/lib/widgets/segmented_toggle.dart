import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class SegOption<V> {
  const SegOption(this.value, this.label, {this.icon});
  final V value;
  final String label;
  final IconData? icon;
}

/// Joined button group; the selected segment looks pushed in (navy).
/// Used for ខ្មែរ | EN, report periods, device type, glucose unit.
class SegmentedToggle<V> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.height = 46,
    this.fontSize = 15,
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
    final children = <Widget>[];
    for (var i = 0; i < options.length; i++) {
      final o = options[i];
      final on = o.value == selected;
      children.add(Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: o.label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChanged == null ? null : () => onChanged!(o.value),
            child: Container(
              constraints: BoxConstraints(minHeight: height - 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: on ? null : D.grayGradient,
                color: on ? C.navyBase : null,
                border: i == 0 ? null : const Border(left: BorderSide(color: C.borderInput)),
              ),
              foregroundDecoration: on ? const BoxDecoration(gradient: D.insetShade) : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (o.icon != null) ...[
                    Icon(o.icon, size: 19, color: on ? Colors.white : C.text),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      o.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: T.button.copyWith(fontSize: fontSize, color: on ? Colors.white : C.text, fontFeatures: T.tabular),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        decoration: BoxDecoration(borderRadius: D.radius, border: Border.all(color: C.borderInput)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ),
    );
  }
}
