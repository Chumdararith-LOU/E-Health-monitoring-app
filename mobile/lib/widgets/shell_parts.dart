// Shared shell pieces (AppShellMobile): light header, gliding language pill,
// calm animated sync strip, and Material 3 bottom navigation bar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';

/// Clean light top header with dark status-bar icons, crisp title, and
/// gliding ខ្មែរ | EN pill switcher.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, this.showBack = false, this.onBack});

  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        decoration: const BoxDecoration(
          color: C.panel,
          border: Border(bottom: BorderSide(color: C.divider)),
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: [
                if (showBack)
                  _BackButton(
                    label: l.back,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      (onBack ?? () => Navigator.of(context).maybePop())();
                    },
                  )
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
                      style: T.big.copyWith(color: C.text),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const LangToggle(),
              ],
            ),
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: C.navyTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.favorite_rounded, color: C.navyBase, size: 20),
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
      child: _TapScale(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
          decoration: BoxDecoration(
            color: C.inputUnit,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left_rounded, color: C.text, size: 22),
              Text(label, style: T.label.copyWith(fontSize: 14, color: C.text)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sliding-thumb ខ្មែរ | EN pill toggle (US-15).
class LangToggle extends StatelessWidget {
  const LangToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final isKm = st.lang == AppLang.km;

    Widget seg(String text, AppLang value) {
      final on = st.lang == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: value == AppLang.km ? 'ភាសាខ្មែរ' : 'English',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!on) {
                HapticFeedback.selectionClick();
                st.setLang(value);
              }
            },
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: D.animFast,
                curve: D.animCurve,
                style: T.button.copyWith(
                  fontSize: 13.5,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                  color: on ? C.navyBase : C.text2,
                ),
                child: Text(text, maxLines: 1),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 108,
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: C.inputUnit,
        borderRadius: D.radiusPill,
        border: Border.all(color: C.border),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: D.animMed,
            curve: D.animCurve,
            alignment: isKm ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: C.panel,
                  borderRadius: D.radiusPill,
                  boxShadow: const [
                    BoxShadow(color: Color(0x140F172A), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              seg('ខ្មែរ', AppLang.km),
              seg('EN', AppLang.en),
            ],
          ),
        ],
      ),
    );
  }
}

/// Calm animated status strip: subtle when synced, clear amber when offline (NFR-09).
class SyncStrip extends StatelessWidget {
  const SyncStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final st = AppScope.of(context);
    final l = L.of(context);

    Color bg;
    Color border;
    Color fg;
    Color dot;
    IconData icon;
    String text;

    if (st.offline) {
      bg = C.warnBg;
      border = C.warnDivider;
      fg = C.warnText;
      dot = C.warnBorder;
      icon = Icons.cloud_off_rounded;
      final c = st.pendingCount;
      text = c > 0 ? l.offlinePending(c) : l.offlineNone;
    } else if (st.syncing) {
      bg = C.infoBg;
      border = const Color(0xFFBAE6FD);
      fg = C.infoText;
      dot = C.infoBorder;
      icon = Icons.sync_rounded;
      text = l.syncing;
    } else {
      bg = C.panelHeader;
      border = C.divider;
      fg = C.text2;
      dot = C.okBorder;
      icon = Icons.cloud_done_rounded;
      final t = st.lastSync;
      final sameDay = t.year == st.today.year && t.month == st.today.month && t.day == st.today.day;
      text = l.syncedAt(sameDay ? l.time(t) : l.dayTime(t));
    }

    return Semantics(
      liveRegion: true,
      child: AnimatedContainer(
        duration: D.animMed,
        curve: D.animCurve,
        constraints: const BoxConstraints(minHeight: 30),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: dot),
            const SizedBox(width: 8),
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

/// Modern Material 3-inspired bottom tab bar with soft active pills and
/// an inviting tactile emerald Record button (hidden for Family per US-13).
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

    Widget tab(int i, IconData activeIcon, IconData idleIcon, String label) {
      final on = i == index;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: _TapScale(
            onTap: () {
              if (!on) HapticFeedback.selectionClick();
              onTab(i);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: D.animMed,
                    curve: D.animCurve,
                    width: on ? 52 : 34,
                    height: 30,
                    decoration: BoxDecoration(
                      color: on ? C.navyTint : Colors.transparent,
                      borderRadius: D.radiusPill,
                    ),
                    child: Icon(
                      on ? activeIcon : idleIcon,
                      size: 22,
                      color: on ? C.navyBase : C.hint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: D.animFast,
                    curve: D.animCurve,
                    style: T.tab.copyWith(
                      color: on ? C.navyBase : C.text2,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                    ),
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
        child: _TapScale(
          onTap: () {
            HapticFeedback.lightImpact();
            onRecord();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            decoration: BoxDecoration(
              gradient: D.greenGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x3815803D), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 22, color: Colors.white),
                Text(
                  l.tabRecord,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.tab.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: C.panel,
        border: Border(top: BorderSide(color: C.divider)),
        boxShadow: D.navShadow,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tab(0, Icons.home_rounded, Icons.home_outlined, l.tabHome),
              if (st.canRecord) record,
              tab(1, Icons.bar_chart_rounded, Icons.bar_chart_outlined, l.tabReports),
              tab(2, Icons.link_rounded, Icons.link_outlined, l.tabLinks),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle tactile press-scale micro-interaction used on nav items and back button.
class _TapScale extends StatefulWidget {
  const _TapScale({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
