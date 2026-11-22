// Record step 1–2: modern viewfinder with smoothly morphing device mask,
// rounded corner brackets, glowing flash toggle, and smooth OCR progress card.
// The viewfinder is simulated (no camera package yet) — Phak plugs in the
// real camera preview where DeviceLcd is drawn.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';
import 'record_flow.dart';
import 'review_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.mode, this.attach = false});

  final DeviceMode mode;

  /// true when opened from the review screen to add a second device
  /// (glucose) or retake: the result is returned with Navigator.pop.
  final bool attach;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  late DeviceMode _mode;
  bool _flash = false;
  bool _processing = false;
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _ctl.addStatusListener((s) {
      if (s == AnimationStatus.completed && _processing && mounted) {
        final st = AppScope.read(context);
        _finish(simulateOcr(_mode, st.ocrScenario, offline: false));
      }
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _take() {
    HapticFeedback.mediumImpact();
    final st = AppScope.read(context);
    if (st.offline) {
      // Server OCR can't run offline: skip the wait (ocr-camera-flow §4).
      _finish(simulateOcr(_mode, st.ocrScenario, offline: true));
      return;
    }
    setState(() => _processing = true);
    _ctl.forward(from: 0);
  }

  void _finish(OcrResult r) {
    _processing = false;
    if (widget.attach) {
      Navigator.of(context).pop(r);
    } else {
      Navigator.of(context).pushReplacement(fastRoute<void>(ReviewScreen(initial: r)));
    }
  }

  void _manual() {
    HapticFeedback.selectionClick();
    _ctl.stop();
    _processing = false;
    if (widget.attach) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(fastRoute<void>(const ReviewScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: C.cameraDeck,
      body: Column(
        children: [
          AppHeader(title: l.scanDevice, showBack: true),
          if (!widget.attach)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                color: C.panel,
                border: Border(bottom: BorderSide(color: C.divider)),
              ),
              child: SegmentedToggle<DeviceMode>(
                semanticLabel: l.deviceType,
                options: [
                  SegOption(DeviceMode.bp, l.modeBp, icon: Icons.favorite_outline_rounded),
                  SegOption(DeviceMode.glucose, l.modeGlu, icon: Icons.water_drop_outlined),
                ],
                selected: _mode,
                onChanged: _processing ? null : (m) => setState(() => _mode = m),
              ),
            ),
          Expanded(child: _viewfinder(l)),
          _deck(l),
        ],
      ),
    );
  }

  Widget _viewfinder(L l) {
    return LayoutBuilder(builder: (context, c) {
      final maxW = c.maxWidth;
      final maxH = c.maxHeight;
      double fw;
      double fh;
      if (_mode == DeviceMode.bp) {
        fw = math.min(238.0, maxW * 0.62);
        fh = fw * 4 / 3;
      } else {
        fw = math.min(294.0, maxW * 0.76);
        fh = fw * 3 / 4;
      }
      var limit = maxH - 122;
      if (limit < 96) limit = 96;
      if (fh > limit) {
        final k = limit / fh;
        fw *= k;
        fh *= k;
      }
      final top = math.max(12.0, (maxH - (fh + 94)) / 2);
      final targetFrame = Rect.fromLTWH((maxW - fw) / 2, top + 38, fw, fh);

      return TweenAnimationBuilder<Rect?>(
        tween: RectTween(begin: targetFrame, end: targetFrame),
        duration: D.animMed,
        curve: D.animCurve,
        builder: (context, animatedRect, _) {
          final frame = animatedRect ?? targetFrame;
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: frame,
                child: AnimatedOpacity(
                  duration: D.animFast,
                  opacity: _processing ? 0.45 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: FittedBox(
                      child: DeviceLcd(
                        mode: _mode,
                        showGuides: _mode == DeviceMode.bp,
                        glu: '112',
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _MaskPainter(frame)),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: frame.inflate(2),
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: _FramePainter()),
                  ),
                ),
              ),
              if (!_processing)
                Positioned(
                  top: math.max(8.0, frame.top - 36),
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xE615803D),
                        borderRadius: D.radiusPill,
                        border: Border.all(color: const Color(0x55FFFFFF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            l.ready,
                            style: T.tab.copyWith(
                              fontSize: 13.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!_processing)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xCC0F172A),
                          borderRadius: D.radius,
                          border: Border.all(color: const Color(0x2EFFFFFF)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFF7DD3FC)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l.cameraGuide,
                                style: T.cap.copyWith(color: Colors.white, height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l.simulatedCamera,
                          style: T.capSm.copyWith(color: C.onDark.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
              AnimatedSwitcher(
                duration: D.animMed,
                child: _processing
                    ? Container(
                        key: const ValueKey<String>('processing'),
                        color: const Color(0x880F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(child: _processingPanel(l)),
                      )
                    : const SizedBox.shrink(key: ValueKey<String>('idle')),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _processingPanel(L l) {
    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: C.panel,
            borderRadius: BorderRadius.circular(20),
            boxShadow: D.modalShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: C.infoBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.document_scanner_rounded, size: 20, color: C.infoBorder),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.readingPhoto, style: T.big)),
                ],
              ),
              const SizedBox(height: 12),
              Text(l.pleaseWait, style: T.body.copyWith(color: C.text2)),
              const SizedBox(height: 14),
              Container(
                height: 10,
                decoration: const BoxDecoration(
                  color: C.inputUnit,
                  borderRadius: D.radiusPill,
                ),
                child: ClipRRect(
                  borderRadius: D.radiusPill,
                  child: AnimatedBuilder(
                    animation: _ctl,
                    builder: (context, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _ctl.value.clamp(0.06, 1.0).toDouble(),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: D.navyGradient,
                          borderRadius: D.radiusPill,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(l.timeoutHint, style: T.cap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deck(L l) {
    return Container(
      decoration: const BoxDecoration(
        color: C.cameraDeck,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: _processing
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TactileButton(
                      label: l.typeNow,
                      icon: Icons.keyboard_outlined,
                      fontSize: 16,
                      onPressed: _manual,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.photoKept,
                      textAlign: TextAlign.center,
                      style: T.cap.copyWith(color: C.onDark),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _DarkDeckPill(
                            label: _flash ? l.flashOn : l.flashOff,
                            icon: _flash ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            active: _flash,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _flash = !_flash);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DarkDeckPill(
                            label: l.typeManual,
                            icon: Icons.keyboard_outlined,
                            active: false,
                            onTap: _manual,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TactileButton(
                      label: l.takePhoto,
                      icon: Icons.photo_camera_rounded,
                      variant: BtnVariant.green,
                      height: 60,
                      fontSize: 18,
                      onPressed: _take,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DarkDeckPill extends StatelessWidget {
  const _DarkDeckPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: active ? const Color(0x33F59E0B) : const Color(0xFF1F2937),
        borderRadius: D.radius,
        child: InkWell(
          borderRadius: D.radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: D.animFast,
            curve: D.animCurve,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: D.radius,
              border: Border.all(
                color: active ? const Color(0xFFF59E0B) : const Color(0x2EFFFFFF),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: active ? const Color(0xFFFCD34D) : Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.button.copyWith(
                      fontSize: 14.5,
                      color: active ? const Color(0xFFFEF3C7) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 68% translucent dark mask with smooth rounded cutout.
class _MaskPainter extends CustomPainter {
  _MaskPainter(this.hole);
  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(18)));
    canvas.drawPath(path, Paint()..color = const Color(0xB30F172A));
  }

  @override
  bool shouldRepaint(covariant _MaskPainter old) => old.hole != hole;
}

/// Sleek rounded alignment frame with crisp emerald corner arcs.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const r = 18.0;
    const arm = 26.0;
    final rect = Offset.zero & size;

    final subtleOutline = Paint()
      ..color = C.frameGreen.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(r)), subtleOutline);

    final corner = Paint()
      ..color = C.frameGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    void drawCorner(Path p) => canvas.drawPath(p, corner);

    // Top-left
    drawCorner(Path()
      ..moveTo(0, arm)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(arm, 0));

    // Top-right
    drawCorner(Path()
      ..moveTo(w - arm, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
      ..lineTo(w, arm));

    // Bottom-left
    drawCorner(Path()
      ..moveTo(0, h - arm)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: const Radius.circular(r), clockwise: false)
      ..lineTo(arm, h));

    // Bottom-right
    drawCorner(Path()
      ..moveTo(w - arm, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: const Radius.circular(r), clockwise: false)
      ..lineTo(w, h - arm));
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => false;
}
