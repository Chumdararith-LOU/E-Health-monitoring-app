import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/tokens.dart';

/// Drawn stand-in for the camera picture of a BP monitor or glucose meter.
/// Phak swaps this for the real captured photo (Image.file) later.
class DeviceLcd extends StatelessWidget {
  const DeviceLcd({
    super.key,
    required this.mode,
    this.sys = '128',
    this.dia = '82',
    this.pul = '74',
    this.glu = '112',
    this.unit = 'mg/dL',
    this.width = 196,
    this.dimPulse = false,
    this.showGuides = false,
  });

  final DeviceMode mode;
  final String sys;
  final String dia;
  final String pul;
  final String glu;
  final String unit;
  final double width;
  final bool dimPulse;
  final bool showGuides;

  @override
  Widget build(BuildContext context) {
    final k = width / 196; // scale factor
    final lcdStyle = TextStyle(fontFamily: T.lcdFamily, color: C.lcdText, height: 1.0, fontFeatures: T.tabular);

    Widget tag(String t) => Container(
          padding: EdgeInsets.symmetric(horizontal: 3 * k),
          decoration: showGuides ? BoxDecoration(border: Border.all(color: const Color(0x801E2A1E))) : null,
          child: Text(t, style: lcdStyle.copyWith(fontSize: 13 * k)),
        );

    Widget row(String label, String value, double size, {bool dim = false}) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(padding: EdgeInsets.only(bottom: 6 * k), child: tag(label)),
            Opacity(opacity: dim ? 0.5 : 1, child: Text(value, style: lcdStyle.copyWith(fontSize: size * k))),
          ],
        );

    final screen = Container(
      padding: EdgeInsets.fromLTRB(12 * k, 8 * k, 12 * k, 8 * k),
      decoration: BoxDecoration(
        color: mode == DeviceMode.bp ? C.lcd : C.lcdGlucose,
        borderRadius: BorderRadius.circular(6 * k),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, spreadRadius: -1, offset: Offset(0, 2))],
      ),
      child: mode == DeviceMode.bp
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                row('SYS', sys, 54),
                row('DIA', dia, 54),
                row('PUL', pul, 38, dim: dimPulse),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(glu, style: lcdStyle.copyWith(fontSize: 60 * k)),
                SizedBox(height: 4 * k),
                Text(unit, style: lcdStyle.copyWith(fontSize: 16 * k)),
              ],
            ),
    );

    return Container(
      width: width,
      padding: EdgeInsets.fromLTRB(14 * k, 14 * k, 14 * k, 18 * k),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.deviceTop, C.deviceBottom]),
        borderRadius: BorderRadius.circular((mode == DeviceMode.bp ? 14 : 22) * k),
        border: Border.all(color: C.deviceBorder),
        boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          screen,
          SizedBox(height: 12 * k),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 34 * k, height: 14 * k, decoration: BoxDecoration(color: C.borderStrong, borderRadius: BorderRadius.circular(7 * k))),
              SizedBox(width: 10 * k),
              Container(
                width: 34 * k,
                height: 14 * k,
                decoration: BoxDecoration(
                  color: mode == DeviceMode.bp ? const Color(0xFF3A6FB0) : const Color(0xFF8C3A3A),
                  borderRadius: BorderRadius.circular(7 * k),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
