import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';

/// "Mey (Caretaker)" / "Sokha (self)".
String authorLabel(L l, Reading r, PatientInfo p) {
  if (r.authorId == 'mey') return '${MockData.caretakerName.of(l.km)} (${l.roleCaretaker})';
  return '${p.firstName.of(l.km)} (${l.roleSelf})';
}

/// Short author name for "Only X can edit this".
String authorName(L l, Reading r, PatientInfo p) {
  if (r.authorId == 'mey') return MockData.caretakerName.of(l.km);
  return p.firstName.of(l.km);
}

/// e.g. "High blood pressure and glucose" for a history row.
String flagText(L l, Reading r) {
  final parts = <String>[];
  if (r.bpFlagged) parts.add(r.bpStatus == RangeStatus.high ? l.bpHigh : l.bpLow);
  if (r.gluFlagged) parts.add(r.gluStatus == RangeStatus.high ? l.gluHigh : l.gluLow);
  if (r.pulseFlagged) parts.add(l.pulseOut);
  return parts.join(' · ');
}
