import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

enum FieldState { none, ok, low, error }

/// Label above, big numeric box, attached grey unit cap on the right.
/// Opens the phone's number pad (NFR-05). Always stores plain digits.
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
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color border = C.borderInput;
    double width = 1;
    Color fill = C.panel;
    List<BoxShadow>? halo;

    switch (widget.state) {
      case FieldState.ok:
        border = C.okBorder;
        width = 2;
        break;
      case FieldState.low:
        border = C.warnBorder;
        width = 2;
        fill = C.warnField;
        break;
      case FieldState.error:
        border = C.errBorder;
        width = 2;
        fill = C.errField;
        break;
      case FieldState.none:
        break;
    }
    if (_focus.hasFocus && widget.state != FieldState.error) {
      border = C.focus;
      width = 2;
      halo = const [BoxShadow(color: C.focusHalo, spreadRadius: 3)];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.label, style: T.label)),
            if (widget.badge != null) ...[const SizedBox(width: 8), widget.badge!],
          ],
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: D.radius,
            border: Border.all(color: border, width: width),
            boxShadow: halo,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          hintText: widget.hint,
                          hintStyle: T.body.copyWith(color: C.hint),
                        ),
                      ),
                    ),
                  ),
                  if (widget.unitWidget != null || widget.unit != null)
                    Container(
                      constraints: const BoxConstraints(minWidth: 84),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: C.inputUnit,
                        border: Border(left: BorderSide(color: C.borderInput)),
                      ),
                      child: widget.unitWidget ??
                          Text(widget.unit!, style: T.label.copyWith(fontSize: 15, color: C.text2)),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.message != null) ...[const SizedBox(height: 4), widget.message!],
      ],
    );
  }
}
