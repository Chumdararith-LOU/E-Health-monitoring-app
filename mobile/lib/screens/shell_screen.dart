import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../widgets/widgets.dart';
import 'home/home_tab.dart';
import 'links/links_tab.dart';
import 'record/record_flow.dart';
import 'reports/reports_tab.dart';

/// Header + sync strip + current tab + bottom tab bar.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

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
        body: Column(
          children: [
            AppHeader(title: titles[_index]),
            const SyncStrip(),
            if (kShowDevStrip) const DevStrip(),
            Expanded(
              child: IndexedStack(
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
