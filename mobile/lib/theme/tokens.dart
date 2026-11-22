// Design tokens — "2010s Clinical Utility".
// Values come from claude/design-tokens-copy.md and the mobile design canvas.
// Every screen uses these; never type a raw colour inside a screen file.

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// Colours.
class C {
  C._();

  // Surfaces
  static const canvas = Color(0xFFECEFF1);
  static const panel = Color(0xFFFFFFFF);
  static const panelHeader = Color(0xFFF4F6F8);
  static const zebra = Color(0xFFF9FAFB);
  static const footer = Color(0xFFFAFBFC);
  static const inputUnit = Color(0xFFE8ECEF);

  // Borders
  static const border = Color(0xFFC5CCD3);
  static const borderStrong = Color(0xFF8F9AA6);
  static const borderInput = Color(0xFFB0B8C1);
  static const divider = Color(0xFFE1E5EA);
  static const grid = Color(0xFFD5DCE3);

  // Text
  static const text = Color(0xFF1A202C);
  static const text2 = Color(0xFF4A5568);
  static const hint = Color(0xFF6B7684);
  static const muted = Color(0xFF9AA5B1);

  // Brand + actions
  static const navyTop = Color(0xFF265C8F);
  static const navyBase = Color(0xFF1B4369);
  static const navyDark = Color(0xFF12304D);
  static const navyTint = Color(0xFFDCE7F2);
  static const saveTop = Color(0xFF348C39);
  static const saveBase = Color(0xFF256B29);
  static const saveBorder = Color(0xFF1E5622);
  static const link = Color(0xFF0B5ED7);
  static const focus = Color(0xFF1976D2);
  static const focusHalo = Color(0x381976D2);

  // Clinical semantics (always paired with an icon + text)
  static const okBg = Color(0xFFE8F5E9);
  static const okBorder = Color(0xFF2E7D32);
  static const okText = Color(0xFF1B5E20);
  static const okDivider = Color(0xFFA5D6A7);

  static const warnBg = Color(0xFFFFF8E1);
  static const warnBorder = Color(0xFFD97706);
  static const warnText = Color(0xFF8A4B00);
  static const warnDivider = Color(0xFFE8C27A);
  static const warnField = Color(0xFFFFFDF5);

  static const errBg = Color(0xFFFFEBEE);
  static const errBorder = Color(0xFFC62828);
  static const errText = Color(0xFF8E1B1B);
  static const errField = Color(0xFFFFF5F6);

  static const infoBg = Color(0xFFE3F2FD);
  static const infoBorder = Color(0xFF1565C0);
  static const infoText = Color(0xFF0D47A1);

  // Doctor memo (US-19)
  static const memoBg = Color(0xFFFFFDE7);
  static const memoHeader = Color(0xFFFFF6C7);
  static const memoBorder = Color(0xFFD8C36A);
  static const memoIcon = Color(0xFF6B5A10);

  // Camera
  static const cameraDeck = Color(0xFF1F2429);
  static const cameraBg = Color(0xFF2F343A);
  static const lcd = Color(0xFFAEBB9E);
  static const lcdGlucose = Color(0xFFB8C7C9);
  static const lcdText = Color(0xFF1E2A1E);
  static const frameGreen = Color(0xFF7CD67F);
  static const deviceTop = Color(0xFFE4E7EA);
  static const deviceBottom = Color(0xFFC9CED3);
  static const deviceBorder = Color(0xFF9AA3AD);
  static const onDark = Color(0xFFD5DCE3);

  // Overlays
  static const scrim = Color(0x991A202C);
  static const scrimLight = Color(0x591A202C);
  static const shadow = Color(0x14000000);
  static const shadowModal = Color(0x47000000);

  // Dev strip (non-production only)
  static const devBg = Color(0xFFFFE082);
  static const devBorder = Color(0xFFB8860B);
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

/// Typography. Khmer-first line heights (1.6–1.8) so stacked
/// subscripts and upper vowels never clip.
class T {
  T._();

  static const f = 'NotoSansKhmer';
  static const lcdFamily = 'ShareTechMono';
  static const tabular = <FontFeature>[FontFeature.tabularFigures()];

  static const title = TextStyle(fontFamily: f, fontSize: 22, fontWeight: FontWeight.w700, height: 1.6, color: C.text);
  static const h = TextStyle(fontFamily: f, fontSize: 16, fontWeight: FontWeight.w700, height: 1.65, color: C.text);
  static const big = TextStyle(fontFamily: f, fontSize: 18, fontWeight: FontWeight.w700, height: 1.65, color: C.text);
  static const hero = TextStyle(fontFamily: f, fontSize: 28, fontWeight: FontWeight.w700, height: 1.3, color: C.text, fontFeatures: tabular);
  static const value = TextStyle(fontFamily: f, fontSize: 26, fontWeight: FontWeight.w700, height: 1.3, color: C.text, fontFeatures: tabular);
  static const valueSm = TextStyle(fontFamily: f, fontSize: 20, fontWeight: FontWeight.w700, height: 1.35, color: C.text, fontFeatures: tabular);
  static const input = TextStyle(fontFamily: f, fontSize: 20, fontWeight: FontWeight.w600, height: 1.5, color: C.text, fontFeatures: tabular);
  static const body = TextStyle(fontFamily: f, fontSize: 16, fontWeight: FontWeight.w400, height: 1.75, color: C.text);
  static const bodyB = TextStyle(fontFamily: f, fontSize: 16, fontWeight: FontWeight.w700, height: 1.65, color: C.text);
  static const bodySm = TextStyle(fontFamily: f, fontSize: 15, fontWeight: FontWeight.w400, height: 1.75, color: C.text);
  static const label = TextStyle(fontFamily: f, fontSize: 16, fontWeight: FontWeight.w600, height: 1.65, color: C.text);
  static const button = TextStyle(fontFamily: f, fontSize: 17, fontWeight: FontWeight.w700, height: 1.5);
  static const cap = TextStyle(fontFamily: f, fontSize: 14, fontWeight: FontWeight.w400, height: 1.7, color: C.text2);
  static const capSm = TextStyle(fontFamily: f, fontSize: 13, fontWeight: FontWeight.w400, height: 1.7, color: C.text2);
  static const badge = TextStyle(fontFamily: f, fontSize: 13, fontWeight: FontWeight.w700, height: 1.65);
  static const tab = TextStyle(fontFamily: f, fontSize: 13, height: 1.65);
}

/// Shared box decorations.
class D {
  D._();

  static const radius = BorderRadius.all(Radius.circular(4));
  static const panelShadow = [BoxShadow(color: C.shadow, blurRadius: 2, offset: Offset(0, 1))];
  static const modalShadow = [BoxShadow(color: C.shadowModal, blurRadius: 20, offset: Offset(0, 6))];

  static const grayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFE6EAEE)],
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

  /// Dark-to-clear overlay that makes a control look "pushed in".
  static const insetShade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.35],
    colors: [Color(0x59000000), Color(0x00000000)],
  );
}
