// Record step 1–2: camera with device-shaped mask, then "reading photo".
// The viewfinder is simulated (no camera package yet) — Phak plugs in the
// real camera preview where DeviceLcd is drawn.

import 'dart:math' as math;

import 'package:flutter/material.dart';

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(color: C.panelHeader, border: Border(bottom: BorderSide(color: C.borderStrong))),
              child: SegmentedToggle<DeviceMode>(
                semanticLabel: l.deviceType,
                options: [
                  SegOption(DeviceMode.bp, l.modeBp, icon: Icons.favorite_border),
                  SegOption(DeviceMode.glucose, l.modeGlu, icon: Icons.water_drop_outlined),
                ],
                selected: _mode,
                onChanged: _processing ? null : (m) => setState(() => _mode = m),
              ),
            ),
          Expanded(child: _viewfinder(l)),
          if (!_processing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: C.infoBg,
                border: Border(top: BorderSide(color: C.infoBorder), bottom: BorderSide(color: C.infoBorder)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.info_outline, size: 20, color: C.infoText)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l.cameraGuide, style: T.bodySm.copyWith(color: C.infoText, height: 1.7))),
                ],
              ),
            ),
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
        fw = math.min(234.0, maxW * 0.62);
        fh = fw * 4 / 3;
      } else {
        fw = math.min(290.0, maxW * 0.74);
        fh = fw * 3 / 4;
      }
      var limit = maxH - 70;
      if (limit < 80) limit = 80;
      if (fh > limit) {
        final k = limit / fh;
        fw *= k;
        fh *= k;
      }
      final top = math.max(8.0, (maxH - (fh + 42)) / 2);
      final frame = Rect.fromLTWH((maxW - fw) / 2, top + 42, fw, fh);

      return Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B7178), Color(0xFF4A5057), Color(0xFF2F343A)],
                ),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: frame,
            child: Opacity(
              opacity: _processing ? 0.55 : 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: FittedBox(
                  child: DeviceLcd(mode: _mode, showGuides: _mode == DeviceMode.bp, glu: '112'),
                ),
              ),
            ),
          ),
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _MaskPainter(frame)))),
          Positioned.fromRect(rect: frame.inflate(1.5), child: IgnorePointer(child: CustomPaint(painter: _FramePainter()))),
          if (!_processing)
            Positioned(
              top: top,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(color: C.okBorder, border: Border.all(color: C.okText), borderRadius: BorderRadius.circular(3)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(l.ready, style: T.tab.copyWith(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 10,
            bottom: 6,
            child: Text(l.simulatedCamera, style: T.capSm.copyWith(color: C.onDark)),
          ),
          if (_processing) ...[
            Positioned.fill(child: Container(color: const Color(0x66000000))),
            Positioned(
              left: 20,
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(child: _processingPanel(l)),
            ),
          ],
        ],
      );
    });
  }

  Widget _processingPanel(L l) {
    return Semantics(
      liveRegion: true,
      child: Container(
        decoration: BoxDecoration(color: C.panel, borderRadius: D.radius, border: Border.all(color: C.borderStrong), boxShadow: D.modalShadow),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(color: C.panelHeader, border: Border(bottom: BorderSide(color: C.border))),
                child: Row(
                  children: [
                    const Icon(Icons.sync, size: 20, color: C.infoBorder),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l.readingPhoto, style: T.h)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.pleaseWait, style: T.body),
                    const SizedBox(height: 10),
                    Container(
                      height: 22,
                      decoration: BoxDecoration(color: const Color(0xFFF1F3F5), border: Border.all(color: C.borderStrong), borderRadius: BorderRadius.circular(3)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: AnimatedBuilder(
                          animation: _ctl,
                          builder: (context, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _ctl.value.clamp(0.04, 1.0).toDouble(),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: D.navyGradient,
                                border: Border(right: BorderSide(color: C.navyDark)),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _deck(L l) {
    return Container(
      decoration: const BoxDecoration(color: C.cameraDeck, border: Border(top: BorderSide(color: Colors.black))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: _processing
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TactileButton(label: l.typeNow, icon: Icons.keyboard_outlined, fontSize: 16, onPressed: _manual),
                    const SizedBox(height: 8),
                    Text(l.photoKept, textAlign: TextAlign.center, style: T.cap.copyWith(color: C.onDark)),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TactileButton(
                            label: _flash ? l.flashOn : l.flashOff,
                            icon: _flash ? Icons.flash_on : Icons.flash_off,
                            height: 48,
                            fontSize: 15,
                            onPressed: () => setState(() => _flash = !_flash),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TactileButton(label: l.typeManual, icon: Icons.keyboard_outlined, height: 48, fontSize: 15, onPressed: _manual),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TactileButton(label: l.takePhoto, icon: Icons.photo_camera_outlined, variant: BtnVariant.green, height: 64, fontSize: 19, onPressed: _take),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 75% black mask around the device-shaped cutout.
class _MaskPainter extends CustomPainter {
  _MaskPainter(this.hole);
  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(4)));
    canvas.drawPath(path, Paint()..color = const Color(0xBF000000));
  }

  @override
  bool shouldRepaint(covariant _MaskPainter old) => old.hole != hole;
}

/// 3px green frame with thick corner ticks.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = C.frameGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)), line);
    final corner = Paint()
      ..color = C.frameGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.square;
    const k = 24.0;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(const Offset(-4, -4), const Offset(k, -4), corner);
    canvas.drawLine(const Offset(-4, -4), const Offset(-4, k), corner);
    canvas.drawLine(Offset(w + 4, -4), Offset(w - k, -4), corner);
    canvas.drawLine(Offset(w + 4, -4), Offset(w + 4, k), corner);
    canvas.drawLine(Offset(-4, h + 4), Offset(k, h + 4), corner);
    canvas.drawLine(Offset(-4, h + 4), Offset(-4, h - k), corner);
    canvas.drawLine(Offset(w + 4, h + 4), Offset(w - k, h + 4), corner);
    canvas.drawLine(Offset(w + 4, h + 4), Offset(w + 4, h - k), corner);
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => false;
}
