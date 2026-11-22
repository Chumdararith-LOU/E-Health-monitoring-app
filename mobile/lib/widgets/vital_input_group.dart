import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

enum FieldState { none, ok, low, error }

/// Label above, soft-filled rounded numeric input with sleek inline unit pill
/// or custom unit selector. Opens the phone's number pad (NFR-05) and smoothly
/// animates validation or OCR guidance messages.
class VitalInputGroup extends StatefulWidget {
  const VitalInputGroup({
    super.key,
    required this.label,
    required this.controller,
    this.unit,
    this.unitWidget,
    this.badge,
    this.state = FieldState.none,
    this.message,
    this.decimal = false,
    this.hint,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? unit;
  final Widget? unitWidget;
  final Widget? badge;
  final FieldState state;
  final Widget? message;
  final bool decimal;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  State<VitalInputGroup> createState() => _VitalInputGroupState();
}

class _VitalInputGroupState extends State<VitalInputGroup> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;

    Color border = C.border;
    double width = 1.25;
    Color fill = focused ? C.panel : C.inputUnit;
    List<BoxShadow>? halo;

    switch (widget.state) {
      case FieldState.ok:
        border = C.okDivider;
        width = 1.5;
        fill = C.panel;
        break;
      case FieldState.low:
        border = C.warnBorder;
        width = 1.75;
        fill = C.warnField;
        break;
      case FieldState.error:
        border = C.errBorder;
        width = 1.75;
        fill = C.errField;
        break;
      case FieldState.none:
        break;
    }

    if (focused && widget.state != FieldState.error) {
      border = C.focus;
      width = 2;
      fill = C.panel;
      halo = const [
        BoxShadow(color: C.focusHalo, blurRadius: 0, spreadRadius: 3),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.label, style: T.label)),
            if (widget.badge != null) ...[
              const SizedBox(width: 8),
              widget.badge!,
            ],
          ],
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: D.animFast,
          curve: D.animCurve,
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: D.radius,
            border: Border.all(color: border, width: width),
            boxShadow: halo,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focus,
                        onChanged: widget.onChanged,
                        keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
                        textInputAction: TextInputAction.done,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(widget.decimal ? r'[0-9.]' : r'[0-9]')),
                          LengthLimitingTextInputFormatter(5),
                        ],
                        style: T.input,
                        cursorColor: C.focus,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          hintText: widget.hint,
                          hintStyle: T.body.copyWith(color: C.muted),
                        ),
                      ),
                    ),
                  ),
                  if (widget.unitWidget != null)
                    Container(
                      constraints: const BoxConstraints(minWidth: 88),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: C.panelHeader,
                        border: Border(left: BorderSide(color: C.divider)),
                      ),
                      child: widget.unitWidget!,
                    )
                  else if (widget.unit != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: focused ? C.inputUnit : C.panel,
                            borderRadius: D.radiusSm,
                            border: Border.all(color: C.border),
                          ),
                          child: Text(
                            widget.unit!,
                            style: T.cap.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: C.text2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: D.animMed,
          curve: D.animCurve,
          alignment: Alignment.topCenter,
          child: widget.message != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: widget.message!,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
