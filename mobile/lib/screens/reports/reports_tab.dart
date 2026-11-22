import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import 'history_view.dart';
import 'report_view.dart';

/// Reports & History tab: a two-way toggle on top, each view keeps its state.
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  int _sub = 0;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(color: C.panelHeader, border: Border(bottom: BorderSide(color: C.border))),
          child: SegmentedToggle<int>(
            semanticLabel: l.reportOrHistory,
            options: [
              SegOption(0, l.reportsTitle, icon: Icons.bar_chart),
              SegOption(1, l.history, icon: Icons.format_list_bulleted),
            ],
            selected: _sub,
            onChanged: (v) => setState(() => _sub = v),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _sub,
            children: const [ReportView(), HistoryView()],
          ),
        ),
      ],
    );
  }
}
