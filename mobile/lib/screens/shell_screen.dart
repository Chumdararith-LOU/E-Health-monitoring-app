import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/widgets.dart';
import 'home/home_tab.dart';
import 'links/links_tab.dart';
import 'record/record_flow.dart';
import 'reports/reports_tab.dart';

/// Header + sync strip + state-preserving smooth tabs + bottom tab bar.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  void _go(int i) {
    if (_index != i) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final st = AppScope.of(context);
    final titles = <String>[l.appName, l.reportsTitle, l.linksTitle];

    return PopScope(
      // Android back on Reports/Links returns to Home first.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _go(0);
      },
      child: Scaffold(
        backgroundColor: C.canvas,
        body: Column(
          children: [
            AppHeader(title: titles[_index]),
            const SyncStrip(),
            if (kShowDevStrip) const DevStrip(),
            Expanded(
              child: _SmoothIndexedStack(
                index: _index,
                children: [
                  HomeTab(onOpenReports: () => _go(1), onOpenLinks: () => _go(2)),
                  const ReportsTab(),
                  LinksTab(onSignedOut: () => _go(0)),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomTabBar(
          index: _index,
          onTab: _go,
          onRecord: () {
            if (st.canRecord) openRecord(context);
          },
        ),
      ),
    );
  }
}

/// Keeps all tabs mounted (preserving scroll offsets & loaded charts) while
/// adding a crisp fade + subtle vertical settle on tab switch.
class _SmoothIndexedStack extends StatelessWidget {
  const _SmoothIndexedStack({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: ExcludeSemantics(
              excluding: i != index,
              // TickerMode sits inside the fade so the outgoing tab can
              // still fade out; only the tab's own animations pause.
              child: AnimatedOpacity(
                opacity: i == index ? 1.0 : 0.0,
                duration: D.animFast,
                curve: D.animCurve,
                child: AnimatedSlide(
                  offset: i == index ? Offset.zero : const Offset(0, 0.012),
                  duration: D.animFast,
                  curve: D.animCurve,
                  child: TickerMode(enabled: i == index, child: children[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
