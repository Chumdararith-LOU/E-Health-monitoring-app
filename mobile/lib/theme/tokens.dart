// Design tokens. One source of truth so every screen looks and behaves the same.
// Reliability and consistency over decoration:
//  - one primary colour for actions, semantic colours only for health status
//  - all text colours pass WCAG AA (4.5:1) on the surfaces they sit on
//  - touch targets are at least 56 dp (Material minimum is 48 dp; elderly users get more)

import 'package:flutter/widgets.dart';

/// Colours.
class C {
  C._();

  static const bg = Color(0xFFF3F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFB);
  static const border = Color(0xFFD3DAE0);
  static const borderStrong = Color(0xFF9AA6B2);
  static const divider = Color(0xFFE6EAEE);

  static const text = Color(0xFF141A21);
  static const textMuted = Color(0xFF4B5763);
  static const textDisabled = Color(0xFF8A96A3);

  static const primary = Color(0xFF0B5CAB);
  static const primaryPressed = Color(0xFF084A8A);
  static const primarySoft = Color(0xFFE5EFF9);
  static const onPrimary = Color(0xFFFFFFFF);

  // Health status (always shown with an icon + a word, never colour alone)
  static const ok = Color(0xFF1A7A3A);
  static const okSoft = Color(0xFFE3F3E8);
  static const okBorder = Color(0xFFB5DEC0);
  static const high = Color(0xFFB3261E);
  static const highSoft = Color(0xFFFCE9E7);
  static const highBorder = Color(0xFFF2C3BE);
  static const low = Color(0xFF8A4B00);
  static const lowSoft = Color(0xFFFFF1DB);
  static const lowBorder = Color(0xFFF0D29F);
  static const missed = Color(0xFF5B6470);
  static const missedSoft = Color(0xFFECEFF2);

  static const danger = Color(0xFFB3261E);
  static const dangerPressed = Color(0xFF8E1D17);
  static const dangerSoft = Color(0xFFFCE9E7);
  static const focus = Color(0xFF0B5CAB);

  // Chart series (dataviz reference palette, slots 1 and 2)
  static const series1 = Color(0xFF257DE0);
  static const series2 = Color(0xFFF47230);
  static const band = Color(0xFFE7ECF0);
  static const grid = Color(0xFFE3E7EB);
  static const axis = Color(0xFF5B6470);

  // Overlays
  static const scrim = Color(0x8C0A0F14);
  static const sheetScrim = Color(0x800A0F14);
  static const toastBg = Color(0xFF1F2933);
  static const toastIcon = Color(0xFF9FE0B0);
  static const toastAction = Color(0xFF9CC9FF);
  static const optionBorder = Color(0xFFA9C6E6);
}

/// Spacing (dp).
class Sp {
  Sp._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii (dp).
class R {
  R._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

/// Minimum touch target heights (dp).
class Touch {
  Touch._();
  static const double min = 56;
  static const double compact = 48;
}

/// Type scale in dp before the user's text-size setting is applied.
enum TextVariant {
  display(40), // big reading values
  title(24),
  heading(20),
  body(18),
  label(16),
  caption(14);

  const TextVariant(this.size);
  final double size;
}

/// Font families declared in pubspec.yaml. Google Sans has no Khmer glyphs,
/// so Khmer text is set in Noto Sans Khmer.
class Fonts {
  Fonts._();
  static const latin = 'GoogleSans';
  static const khmer = 'NotoSansKhmer';
}
