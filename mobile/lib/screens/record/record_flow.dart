// Entry point of the Record flow + the simulated OCR.
// Phak: replace simulateOcr() with the real OCR call; keep the OcrResult
// contract so Seyla's review screen doesn't change.

import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import 'camera_screen.dart';

/// Opens the camera in BP mode (per claude/ocr-camera-flow.md).
void openRecord(BuildContext context) {
  Navigator.of(context).push(fastRoute<void>(const CameraScreen(mode: DeviceMode.bp)));
}

OcrResult simulateOcr(DeviceMode mode, OcrScenario scenario, {required bool offline}) {
  if (offline) {
    return OcrResult(mode: mode, failed: true, offline: true);
  }
  if (scenario == OcrScenario.failed) {
    return OcrResult(mode: mode, failed: true);
  }
  if (mode == DeviceMode.glucose) {
    return const OcrResult(
      mode: DeviceMode.glucose,
      glucose: '112',
      unit: GlucoseUnit.mgdl,
      conf: <String, Conf>{'glu': Conf.high},
    );
  }
  switch (scenario) {
    case OcrScenario.clear:
      return const OcrResult(
        mode: DeviceMode.bp,
        systolic: '128',
        diastolic: '82',
        pulse: '74',
        conf: <String, Conf>{'sys': Conf.high, 'dia': Conf.high, 'pul': Conf.high},
      );
    case OcrScenario.partial:
      return const OcrResult(
        mode: DeviceMode.bp,
        systolic: '128',
        diastolic: '82',
        pulse: '74',
        conf: <String, Conf>{'sys': Conf.high, 'dia': Conf.high, 'pul': Conf.low},
      );
    case OcrScenario.misread:
      // A 1 read as a 7: "128" → "728". The hard limit catches it.
      return const OcrResult(
        mode: DeviceMode.bp,
        systolic: '728',
        diastolic: '82',
        pulse: '74',
        conf: <String, Conf>{'sys': Conf.high, 'dia': Conf.high, 'pul': Conf.high},
      );
    case OcrScenario.failed:
      return OcrResult(mode: mode, failed: true);
  }
}
