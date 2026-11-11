import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'data/progress_store.dart';
import 'data/settings.dart';
import 'services/audio_service.dart';
import 'services/book_source.dart';
import 'services/british_voice.dart';

/// Application services shared through the widget tree.
class AppServices {
  AppServices({
    required this.settings,
    required this.progress,
    required this.audio,
    required this.voice,
    required this.book,
  }) {
    _applySettings();
    settings.addListener(_applySettings);
  }

  final SettingsController settings;
  final ProgressStore progress;
  final AudioOut audio;
  final BritishVoice voice;
  final BookSource book;

  void _applySettings() {
    audio.rate = settings.playbackRate;
    audio.sfxEnabled = settings.soundEffects;
    progress.dailyGoal = settings.dailyGoal;
  }
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing');
    return scope!.services;
  }

  /// Read without registering a dependency (for callbacks).
  static AppServices read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}

/// Counts learning time while the app is in the foreground.
class LearningTimer with WidgetsBindingObserver {
  LearningTimer(this.progress);

  final ProgressStore progress;
  Timer? _timer;
  DateTime? _since;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _resume();
  }

  void _resume() {
    _since = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _flush());
  }

  void _flush() {
    final s = _since;
    if (s == null) return;
    final now = DateTime.now();
    final secs = now.difference(s).inSeconds;
    _since = now;
    progress.addLearningTime(secs);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resume();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _flush();
      _since = null;
      _timer?.cancel();
    }
  }

  void dispose() {
    _flush();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
