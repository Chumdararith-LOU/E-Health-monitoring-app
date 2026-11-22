import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import 'history_view.dart';
import 'report_view.dart';

/// Reports & History tab: sleek sliding toggle on top, smooth state-preserving
/// sub-view transitions below.
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
    const views = <Widget>[ReportView(), HistoryView()];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: C.panel,
            border: Border(bottom: BorderSide(color: C.divider)),
          ),
          child: SegmentedToggle<int>(
            semanticLabel: l.reportOrHistory,
            options: [
              SegOption(0, l.reportsTitle, icon: Icons.bar_chart_rounded),
              SegOption(1, l.history, icon: Icons.format_list_bulleted_rounded),
            ],
            selected: _sub,
            onChanged: (v) {
              if (_sub != v) setState(() => _sub = v);
            },
          ),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < views.length; i++)
                IgnorePointer(
                  ignoring: i != _sub,
                  child: ExcludeSemantics(
                    excluding: i != _sub,
                    child: TickerMode(
                      enabled: i == _sub,
                      child: AnimatedOpacity(
                        opacity: i == _sub ? 1.0 : 0.0,
                        duration: D.animFast,
                        curve: D.animCurve,
                        child: AnimatedSlide(
                          offset: i == _sub ? Offset.zero : const Offset(0, 0.012),
                          duration: D.animFast,
                          curve: D.animCurve,
                          child: views[i],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
