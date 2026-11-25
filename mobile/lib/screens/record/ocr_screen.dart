// OCR flow (US-07, US-08, US-09), simulated. No text recognition runs yet:
//  - demo "clear" photos return the numbers printed on them (132/84, 72; 118 mg/dL)
//  - the demo "blurry" photo fails → typing, with the photo still visible
//  - real camera photos return plausible numbers near the patient's last reading
// The hand-over to the reading form is the contract in the plan:
//   ReadingFormScreen(prefill: Prefill(systolic, diastolic, pulse, glucose, photoUri))
// Plug real OCR (ML Kit / Tesseract) into _simulate(); the rest stays the same.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/types.dart';
import '../../state/app_state.dart';
import '../../widgets/widgets.dart';
import '../shell.dart';
import 'reading_form_screen.dart';

enum OcrDevice { bp, glucose }

enum _Phase { intro, reading, failed }

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key, required this.device});
  final OcrDevice device;

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  _Phase _phase = _Phase.intro;
  String? _photo;
  bool _denied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _simulate(String uri) {
    setState(() {
      _photo = uri;
      _phase = _Phase.reading;
    });
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (uri == 'demo:bp-blurry') {
        setState(() => _phase = _Phase.failed);
        return;
      }
      final st = AppScope.read(context);
      final patient = st.patient;
      Prefill prefill;
      if (uri == 'demo:bp') {
        prefill = const Prefill(systolic: 132, diastolic: 84, pulse: 72);
      } else if (uri == 'demo:glucose') {
        prefill = const Prefill(glucose: 118);
      } else {
        final rs = patient == null ? const <Reading>[] : st.readingsOf(patient.id);
        final last = rs.isEmpty ? null : rs.first;
        final rnd = math.Random();
        double j(double? v, double d, double spread) => ((v ?? d) + (rnd.nextDouble() - 0.5) * spread).roundToDouble();
        prefill = widget.device == OcrDevice.bp
            ? Prefill(
                systolic: j(last?.systolic, 128, 10),
                diastolic: j(last?.diastolic, 80, 6),
                pulse: j(last?.pulse, 74, 8),
                lowConfidence: rnd.nextDouble() < 0.4 ? const {'pulse'} : const {},
              )
            : Prefill(glucose: j(last?.glucose, 110, 20));
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ReadingFormScreen(
          method: EntryMethod.ocr,
          prefill: prefill.withPhoto(uri),
          patientId: patient?.id,
        ),
      ));
    });
  }

  Future<void> _openCamera() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 60);
      if (file != null) _simulate(file.path);
    } catch (_) {
      setState(() => _denied = true);
    }
  }

  void _typeInstead() {
    final patient = AppScope.read(context).patient;
    final photo = _photo;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ReadingFormScreen(
        prefill: photo == null ? null : const Prefill().withPhoto(photo),
        patientId: patient?.id,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).i18n.t;
    final title = widget.device == OcrDevice.bp ? t('ocrTitleBp') : t('ocrTitleGlu');
    final photo = _photo;

    if (_phase == _Phase.reading && photo != null) {
      return StackPage(
        title: title,
        child: AppScreen(children: [
          AppPhoto(uri: photo, height: 300, radius: R.lg, label: t('photo')),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: C.primary)),
            const SizedBox(width: Sp.md),
            Semantics(liveRegion: true, child: AppText(t('reading'), variant: TextVariant.heading)),
          ]),
        ]),
      );
    }

    if (_phase == _Phase.failed && photo != null) {
      return StackPage(
        title: title,
        child: AppScreen(
          footer: [
            AppButton(icon: Mdi.keyboardOutline, label: t('typeInstead'), onPressed: _typeInstead),
            AppButton(
              variant: BtnVariant.secondary,
              icon: Mdi.cameraRetakeOutline,
              label: t('retakePhoto'),
              onPressed: () => setState(() => _phase = _Phase.intro),
            ),
          ],
          children: [
            AppPhoto(uri: photo, height: 300, radius: R.lg, label: t('photo')),
            AppCard(tone: CardTone.low, children: [
              Gap(children: [
                const Icon(Mdi.imageOffOutline, size: 32, color: C.low),
                Expanded(
                  child: Semantics(liveRegion: true, child: AppText(t('ocrFailTitle'), variant: TextVariant.heading)),
                ),
              ]),
              AppText(t('ocrFailBody')),
            ]),
          ],
        ),
      );
    }

    final demoUri = widget.device == OcrDevice.bp ? 'demo:bp' : 'demo:glucose';
    return StackPage(
      title: title,
      child: AppScreen(
        footer: [
          AppButton(icon: Mdi.camera, label: t('openCamera'), onPressed: _openCamera),
          AppButton(variant: BtnVariant.secondary, icon: Mdi.keyboardOutline, label: t('typeInstead'), onPressed: _typeInstead),
        ],
        children: [
          if (_denied) AppBanner(kind: BannerKind.warning, text: t('cameraDenied')),
          AppCard(children: [
            AppText(t('ocrHowTo'), variant: TextVariant.heading),
            for (final (icon, text) in [
              (Mdi.phoneRotatePortrait, t('ocrTip1')),
              (Mdi.cropFree, t('ocrTip2')),
              (Mdi.whiteBalanceSunny, t('ocrTip3')),
            ])
              Gap(gap: Sp.md, children: [Icon(icon, size: 28, color: C.primary), Expanded(child: AppText(text))]),
          ]),
          AppCard(children: [
            Gap(children: [
              const Icon(Mdi.flaskOutline, size: 22, color: C.textMuted),
              AppText(t('demo'), variant: TextVariant.label, weight: W.semibold, color: C.textMuted),
            ]),
            AppText(t('demoOcrNote'), variant: TextVariant.caption, color: C.textMuted),
            AppButton(
              variant: BtnVariant.secondary,
              compact: true,
              icon: Mdi.imageOutline,
              label: t('demoPhotoClear'),
              onPressed: () => _simulate(demoUri),
            ),
            if (widget.device == OcrDevice.bp)
              AppButton(
                variant: BtnVariant.secondary,
                compact: true,
                icon: Mdi.imageBrokenVariant,
                label: t('demoPhotoBlurry'),
                onPressed: () => _simulate('demo:bp-blurry'),
              ),
          ]),
        ],
      ),
    );
  }
}
