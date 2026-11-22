// Shared shell pieces (AppShellMobile): header, sync strip, tab bar.
// They match the "Shared shell parts" row on the design canvas.

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';

/// 52px navy header: back button or emblem, title, ខ្មែរ | EN toggle.
/// Extends under the status bar.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.showBack = false, this.onBack});

  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: D.navyGradient,
        border: Border(bottom: BorderSide(color: C.navyDark)),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
          child: Row(
            children: [
              if (showBack)
                _BackButton(label: l.back, onTap: onBack ?? () => Navigator.of(context).maybePop())
              else
                const _Emblem(),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.big.copyWith(color: Colors.white, height: 1.6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const LangToggle(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: D.grayGradient,
        border: Border.all(color: C.navyDark),
        borderRadius: D.radius,
      ),
      child: const Icon(Icons.add, color: C.errBorder, size: 26),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E6BA3), Color(0xFF1F4E79)],
            ),
            border: Border.all(color: C.navyDark),
            borderRadius: D.radius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left, color: Colors.white, size: 24),
              Text(label, style: T.button.copyWith(fontSize: 14, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// ខ្មែរ | EN segmented toggle (US-15). Lives in the header of every screen.
class LangToggle extends StatelessWidget {
  const LangToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    Widget seg(String text, AppLang value, {bool first = false}) {
      final on = st.lang == value;
      return Semantics(
        button: true,
        selected: on,
        label: value == AppLang.km ? 'ភាសាខ្មែរ' : 'English',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => st.setLang(value),
          child: Container(
            constraints: const BoxConstraints(minHeight: 38, minWidth: 46),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? C.navyDark : null,
              gradient: on ? null : D.grayGradient,
              border: first ? null : const Border(left: BorderSide(color: C.navyDark)),
            ),
            foregroundDecoration: on ? const BoxDecoration(gradient: D.insetShade) : null,
            child: Text(text, style: T.button.copyWith(fontSize: 14, color: on ? Colors.white : C.text)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: C.navyDark), borderRadius: D.radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              seg('ខ្មែរ', AppLang.km, first: true),
              seg('EN', AppLang.en),
            ],
          ),
        ),
      ),
    );
  }
}

/// 28px status strip: synced / syncing / offline (NFR-09).
class SyncStrip extends StatelessWidget {
  const SyncStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final l = L.of(context);

    Color bg;
    Color border;
    Color fg;
    IconData icon;
    String text;

    if (st.offline) {
      bg = C.warnBg;
      border = C.warnBorder;
      fg = C.warnText;
      icon = Icons.wifi_off;
      final c = st.pendingCount;
      text = c > 0 ? l.offlinePending(c) : l.offlineNone;
    } else if (st.syncing) {
      bg = C.infoBg;
      border = C.infoBorder;
      fg = C.infoText;
      icon = Icons.sync;
      text = l.syncing;
    } else {
      bg = C.okBg;
      border = C.okBorder;
      fg = C.okText;
      icon = Icons.check;
      final t = st.lastSync;
      final sameDay = t.year == st.today.year && t.month == st.today.month && t.day == st.today.day;
      text = l.syncedAt(sameDay ? l.time(t) : l.dayTime(t));
    }

    return Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: border))),
        child: Row(
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: T.tab.copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed bottom tab bar. Record is the green button (opens the record flow);
/// Family members don't get it (US-13).
class BottomTabBar extends StatelessWidget {
  const BottomTabBar({super.key, required this.index, required this.onTab, required this.onRecord});

  /// 0 = Home, 1 = Reports, 2 = Links.
  final int index;
  final ValueChanged<int> onTab;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final l = L.of(context);

    Widget tab(int i, IconData icon, String label) {
      final on = i == index;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTab(i),
            child: Container(
              decoration: BoxDecoration(
                color: on ? C.navyTint : null,
                border: Border(top: BorderSide(color: on ? C.navyBase : Colors.transparent, width: 3)),
              ),
              padding: const EdgeInsets.only(bottom: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: on ? C.navyBase : C.text2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.tab.copyWith(color: on ? C.navyBase : C.text2, fontWeight: on ? FontWeight.w700 : FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final record = Expanded(
      child: Semantics(
        button: true,
        label: l.tabRecord,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onRecord,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            decoration: BoxDecoration(
              gradient: D.greenGradient,
              border: Border.all(color: C.saveBorder),
              borderRadius: D.radius,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, size: 21, color: Colors.white),
                Text(l.tabRecord, maxLines: 1, style: T.tab.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: D.grayGradient,
        border: Border(top: BorderSide(color: C.borderStrong)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tab(0, Icons.home_outlined, l.tabHome),
              if (st.canRecord) record,
              tab(1, Icons.bar_chart, l.tabReports),
              tab(2, Icons.link, l.tabLinks),
            ],
          ),
        ),
      ),
    );
  }
}
