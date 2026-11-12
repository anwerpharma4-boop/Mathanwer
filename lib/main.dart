import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'app_scope.dart';
import 'data/progress_store.dart';
import 'data/settings.dart';
import 'services/audio_service.dart';
import 'services/book_source.dart';
import 'services/british_voice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);

  final settings = await SettingsController.load();
  ProgressStore progress;
  try {
    if (kIsWeb) {
      // No SQLite in the browser: keep a JSON snapshot in local storage.
      const key = 'progress_v1';
      progress = ProgressStore.snapshot(
        json: settings.prefs.getString(key),
        save: (json) => settings.prefs.setString(key, json),
      );
    } else {
      progress = await ProgressStore.open();
    }
  } catch (e) {
    debugPrint('Progress database unavailable, using memory only: $e');
    progress = ProgressStore.memory();
  }
  final voice = BritishVoice();
  AudioOut audio;
  try {
    audio = await BundledAudio.load(voice);
  } catch (e) {
    debugPrint('Audio unavailable: $e');
    audio = SilentAudio();
  }
  final services = AppServices(
    settings: settings,
    progress: progress,
    audio: audio,
    voice: voice,
    book: PdfxBookSource(),
  );
  LearningTimer(progress).start();

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true; // keep the app running for the child
  };
  runApp(EnglishForIraqApp(services: services));
}
