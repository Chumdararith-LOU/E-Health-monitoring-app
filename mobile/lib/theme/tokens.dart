// Design tokens — "Modern Clinical Utility" (Material 3 refined).
// Drop-in replacement preserving all token names for full compatibility
// across all screens and widgets, with Khmer-first line heights intact.

import 'package:flutter/material.dart';

/// Colours.
class C {
  C._();

  // Surfaces
  static const canvas = Color(0xFFF5F7FA);
  static const panel = Color(0xFFFFFFFF);
  static const panelHeader = Color(0xFFF8FAFC);
  static const zebra = Color(0xFFF8FAFC);
  static const footer = Color(0xFFF8FAFC);
  static const inputUnit = Color(0xFFF1F5F9);

  // Borders
  static const border = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);
  static const borderInput = Color(0xFFCBD5E1);
  static const divider = Color(0xFFEDF2F7);
  static const grid = Color(0xFFE2E8F0);

  // Text
  static const text = Color(0xFF0F172A);
  static const text2 = Color(0xFF475569);
  static const hint = Color(0xFF64748B);
  static const muted = Color(0xFF94A3B8);

  // Brand + actions (modern medical teal-navy & crisp emerald)
  static const navyTop = Color(0xFF156D8F);
  static const navyBase = Color(0xFF0F5C7A);
  static const navyDark = Color(0xFF0B445C);
  static const navyTint = Color(0xFFE0F2FE);
  static const saveTop = Color(0xFF16A34A);
  static const saveBase = Color(0xFF15803D);
  static const saveBorder = Color(0xFF166534);
  static const link = Color(0xFF0284C7);
  static const focus = Color(0xFF0284C7);
  static const focusHalo = Color(0x2E0284C7);

  // Clinical semantics (always paired with an icon + text)
  static const okBg = Color(0xFFECFDF5);
  static const okBorder = Color(0xFF16A34A);
  static const okText = Color(0xFF14532D);
  static const okDivider = Color(0xFFBBF7D0);

  static const warnBg = Color(0xFFFFFBEB);
  static const warnBorder = Color(0xFFD97706);
  static const warnText = Color(0xFF92400E);
  static const warnDivider = Color(0xFFFDE68A);
  static const warnField = Color(0xFFFFFDF7);

  static const errBg = Color(0xFFFEF2F2);
  static const errBorder = Color(0xFFDC2626);
  static const errText = Color(0xFF991B1B);
  static const errField = Color(0xFFFFF8F8);

  static const infoBg = Color(0xFFF0F9FF);
  static const infoBorder = Color(0xFF0284C7);
  static const infoText = Color(0xFF075985);

  // Doctor memo (US-19)
  static const memoBg = Color(0xFFFFFBEB);
  static const memoHeader = Color(0xFFFEF3C7);
  static const memoBorder = Color(0xFFFCD34D);
  static const memoIcon = Color(0xFF92400E);

  // Camera
  static const cameraDeck = Color(0xFF111827);
  static const cameraBg = Color(0xFF1F2937);
  static const lcd = Color(0xFFAEBB9E);
  static const lcdGlucose = Color(0xFFB8C7C9);
  static const lcdText = Color(0xFF1E2A1E);
  static const frameGreen = Color(0xFF4ADE80);
  static const deviceTop = Color(0xFFE2E8F0);
  static const deviceBottom = Color(0xFFCBD5E1);
  static const deviceBorder = Color(0xFF94A3B8);
  static const onDark = Color(0xFFE2E8F0);

  // Overlays & soft elevation
  static const scrim = Color(0x8A0F172A);
  static const scrimLight = Color(0x470F172A);
  static const shadow = Color(0x0D0F172A);
  static const shadowModal = Color(0x330F172A);

  // Dev strip (non-production only)
  static const devBg = Color(0xFFFEF3C7);
  static const devBorder = Color(0xFFD97706);
}

/// Spacing scale (4 px grid).
class Sp {
  Sp._();
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
}

/// Typography. Khmer-first line heights (1.5–1.75) so stacked
/// subscripts and upper vowels never clip.
class T {
  T._();

  static const f = 'NotoSansKhmer';
  static const lcdFamily = 'ShareTechMono';
  static const tabular = <FontFeature>[FontFeature.tabularFigures()];

  static const title = TextStyle(fontFamily: f, fontSize: 22, fontWeight: FontWeight.w700, height: 1.55, color: C.text);
  static const h = TextStyle(fontFamily: f, fontSize: 16, fontWeight: FontWeight.w700, height: 1.6, color: C.text);
  static const big = TextStyle(fontFamily: f, fontSize: 18, fontWeight: FontWeight.w700, height: 1.6, color: C.text);
  static const hero = TextStyle(fontFamily: f, fontSize: 30, fontWeight: FontWeight.w700, height: 1.25, color: C.text, fontFeatures: tabular);
  static const value = TextStyle(fontFamily: f, fontSize: 26, fontWeight: FontWeight.w700, height: 1.3, color: C.text, fontFeatures: tabular);
  static const valueSm = TextStyle(fontFamily: f, fontSize: 20, fontWeight: FontWeight.w700, height: 1.35, color: C.text, fontFeatures: tabular);
  static const input = TextStyle(fontFamily: f, fontSize: 20, fontWeight: FontWeight.w600, height: 1.5, color: C.text, fontFeatures: tabular);
  static const body = TextStyle(fontFamily: f, fontSize: 16, fontWeight: FontWeight.w400, height: 1.75, color: C.text);
  static const bodyB = TextStyle(fontFamily: f, fontSize: 16, fontWeight: FontWeight.w700, height: 1.65, color: C.text);
  static const bodySm = TextStyle(fontFamily: f, fontSize: 15, fontWeight: FontWeight.w400, height: 1.7, color: C.text);
  static const label = TextStyle(fontFamily: f, fontSize: 15, fontWeight: FontWeight.w600, height: 1.65, color: C.text);
  static const button = TextStyle(fontFamily: f, fontSize: 16, fontWeight: FontWeight.w700, height: 1.5);
  static const cap = TextStyle(fontFamily: f, fontSize: 14, fontWeight: FontWeight.w400, height: 1.65, color: C.text2);
  static const capSm = TextStyle(fontFamily: f, fontSize: 13, fontWeight: FontWeight.w400, height: 1.65, color: C.text2);
  static const badge = TextStyle(fontFamily: f, fontSize: 13, fontWeight: FontWeight.w600, height: 1.6);
  static const tab = TextStyle(fontFamily: f, fontSize: 12.5, height: 1.6);
}

/// Shared box decorations, radii, and motion defaults.
class D {
  D._();

  // Radii — `radius` upgrades all existing controls to crisp 12px corners.
  static const radius = BorderRadius.all(Radius.circular(12));
  static const radiusSm = BorderRadius.all(Radius.circular(8));
  static const radiusLg = BorderRadius.all(Radius.circular(16));
  static const radiusPill = BorderRadius.all(Radius.circular(999));

  // Motion defaults
  static const animFast = Duration(milliseconds: 160);
  static const animMed = Duration(milliseconds: 240);
  static const animCurve = Curves.easeOutCubic;

  // Soft diffused shadows
  static const panelShadow = [
    BoxShadow(color: C.shadow, blurRadius: 12, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x060F172A), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const navShadow = [
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 16, offset: Offset(0, -3)),
  ];
  static const modalShadow = [
    BoxShadow(color: C.shadowModal, blurRadius: 28, offset: Offset(0, 10)),
  ];

  // Subtle modern gradients (keeps compatibility with existing buttons)
  static const grayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F6F9)],
  );
  static const navyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [C.navyTop, C.navyBase],
  );
  static const greenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [C.saveTop, C.saveBase],
  );

  /// Soft pressed overlay (replaces harsh dark 2010 inset bevel).
  static const insetShade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.5],
    colors: [Color(0x140F172A), Color(0x00000000)],
  );
}
