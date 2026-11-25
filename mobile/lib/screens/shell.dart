// App frame: header + role-based bottom tabs, and the navigation helpers
// every screen uses. Tabs depend on the role, but their order and icons never
// change (consistency).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/types.dart';
import '../state/app_state.dart';
import '../widgets/widgets.dart';
import 'history/history_screen.dart';
import 'home/home_screen.dart';
import 'record/record_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';

/// Opens a full-screen page with a back button.
Future<T?> push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

/// Closes every pushed page and shows a tab.
void goToTab(BuildContext context, AppTab tab) {
  AppScope.read(context).setTab(tab);
  Navigator.of(context).popUntil((r) => r.isFirst);
}

/// White header with a left-aligned title, like the design's native stack header.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, required this.title, this.showBack = false});
  final String title;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final scale = AppScope.of(context).settings.textScale;
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      automaticallyImplyLeading: false,
      leading: showBack ? const BackButton(color: C.primary) : null,
      titleSpacing: showBack ? 0 : Sp.lg,
      title: Semantics(
        header: true,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: appStyle(context, title, size: 20 * math.min(scale, 1.15) / scale, weight: W.semibold),
        ),
      ),
      shape: const Border(bottom: BorderSide(color: C.border)),
    );
  }
}

/// A pushed page: header with back button + body.
class StackPage extends StatelessWidget {
  const StackPage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppHeader(title: title, showBack: true),
      body: child,
    );
  }
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final i18n = st.i18n;
    final user = st.user!;
    final tabs = st.visibleTabs;
    final current = tabs.contains(st.tab) ? st.tab : AppTab.home;

    String title(AppTab t) => switch (t) {
          AppTab.home => user.role == Role.doctor ? i18n.t('dashboardTitle') : i18n.t('tab_home'),
          AppTab.record => i18n.t('recordTitle'),
          AppTab.history => i18n.t('historyTitle'),
          AppTab.reports => i18n.t('reportsTitle'),
          AppTab.settings => i18n.t('settingsTitle'),
        };
    String label(AppTab t) => switch (t) {
          AppTab.home => user.role == Role.patient ? i18n.t('tab_home') : i18n.t('tab_patients'),
          AppTab.record => i18n.t('tab_record'),
          AppTab.history => i18n.t('tab_history'),
          AppTab.reports => i18n.t('tab_reports'),
          AppTab.settings => i18n.t('tab_settings'),
        };
    Widget page(AppTab t) => switch (t) {
          AppTab.home => const HomeScreen(),
          AppTab.record => const RecordScreen(),
          AppTab.history => const HistoryScreen(),
          AppTab.reports => const ReportsScreen(),
          AppTab.settings => const SettingsScreen(),
        };

    return PopScope(
      // Android back on another tab returns to Home first.
      canPop: current == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) st.setTab(AppTab.home);
      },
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: AppHeader(title: title(current)),
        body: IndexedStack(
          index: tabs.indexOf(current),
          children: [
            for (final t in tabs)
              TickerMode(
                  enabled: t == current, child: KeyedSubtree(key: ValueKey('${user.id}-${t.name}'), child: page(t))),
          ],
        ),
        bottomNavigationBar: _TabBar(tabs: tabs, current: current, label: label, onTap: st.setTab),
      ),
    );
  }
}

const _tabIcons = {
  AppTab.home: (Mdi.home, Mdi.homeOutline),
  AppTab.record: (Mdi.plusCircle, Mdi.plusCircleOutline),
  AppTab.history: (Mdi.formatListBulleted, Mdi.formatListBulleted),
  AppTab.reports: (Mdi.chartLine, Mdi.chartLine),
  AppTab.settings: (Mdi.cog, Mdi.cogOutline),
};

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tabs, required this.current, required this.label, required this.onTap});
  final List<AppTab> tabs;
  final AppTab current;
  final String Function(AppTab) label;
  final ValueChanged<AppTab> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: C.surface,
        border: Border(top: BorderSide(color: C.border)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final t in tabs)
                  Expanded(
                    child: Builder(builder: (context) {
                      final on = t == current;
                      final color = on ? C.primary : C.textMuted;
                      final text = label(t);
                      return Semantics(
                        button: true,
                        selected: on,
                        label: text,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (!on) HapticFeedback.selectionClick();
                            onTap(t);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(on ? _tabIcons[t]!.$1 : _tabIcons[t]!.$2,
                                    size: t == AppTab.record ? 30 : 26, color: color),
                                Text(
                                  text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: appStyle(context, text, size: 12.5, weight: W.medium, color: color)
                                      .copyWith(fontSize: 12.5, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
