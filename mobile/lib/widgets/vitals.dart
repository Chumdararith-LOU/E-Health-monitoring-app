import 'package:flutter/material.dart';

import '../data/models.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'status.dart';

/// Label / big number / unit, with a High or Low badge when out of range.
class VitalTile extends StatelessWidget {
  const VitalTile({super.key, required this.label, required this.value, required this.unit, this.status, this.big = false});

  final String label;
  final String value;
  final String unit;
  final RangeStatus? status;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: T.cap, maxLines: 1, overflow: TextOverflow.ellipsis),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(l.n(value), style: big ? T.hero : T.value),
        ),
        Text(unit, style: T.cap),
        if (status == RangeStatus.high || status == RangeStatus.low) ...[
          const SizedBox(height: 6),
          StatusBadge(
            label: status == RangeStatus.high ? l.high : l.low,
            tone: BadgeTone.crit,
            icon: status == RangeStatus.high ? Icons.arrow_upward : Icons.arrow_downward,
          ),
        ],
      ],
    );
  }
}

/// The three core vitals of a reading in a row.
class VitalRow extends StatelessWidget {
  const VitalRow({super.key, required this.reading, this.big = false});

  final Reading reading;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: VitalTile(
            label: l.bp,
            value: reading.hasBp ? reading.bpText : '—',
            unit: 'mmHg',
            status: reading.bpStatus,
            big: big,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: VitalTile(label: l.pulse, value: reading.pulse?.toString() ?? '—', unit: 'bpm', status: reading.pulseStatus, big: big),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: VitalTile(
            label: l.glucose,
            value: reading.glucose == null ? '—' : Fields.glu.fmt(reading.glucose!),
            unit: 'mg/dL',
            status: reading.gluStatus,
            big: big,
          ),
        ),
      ],
    );
  }
}

/// Method badge: OCR / Manual / OCR + edited.
class MethodBadge extends StatelessWidget {
  const MethodBadge({super.key, required this.method});
  final EntryMethod method;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    switch (method) {
      case EntryMethod.ocr:
        return const StatusBadge(label: 'OCR', icon: Icons.photo_camera_outlined);
      case EntryMethod.manual:
        return StatusBadge(label: l.badgeManual, tone: BadgeTone.info, icon: Icons.keyboard_outlined);
      case EntryMethod.ocrEdited:
        return StatusBadge(label: l.badgeEdited, tone: BadgeTone.warn, icon: Icons.edit_outlined);
    }
  }
}

/// Gap helper for vertical lists.
List<Widget> gapped(List<Widget> items, double gap) {
  final out = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    if (i > 0) out.add(SizedBox(height: gap));
    out.add(items[i]);
  }
  return out;
}
