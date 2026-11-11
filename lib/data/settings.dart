import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences stored locally.
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsController> load() async => SettingsController(await SharedPreferences.getInstance());

  String get languageCode => _prefs.getString('language') ?? 'en';
  Future<void> setLanguage(String code) async {
    await _prefs.setString('language', code);
    notifyListeners();
  }

  /// Audio playback rate (0.5 = slow, 1.0 = normal).
  double get playbackRate => _prefs.getDouble('playback_rate') ?? 1.0;
  Future<void> setPlaybackRate(double v) async {
    await _prefs.setDouble('playback_rate', v.clamp(0.5, 1.5));
    notifyListeners();
  }

  bool get soundEffects => _prefs.getBool('sfx') ?? true;
  Future<void> setSoundEffects(bool v) async {
    await _prefs.setBool('sfx', v);
    notifyListeners();
  }

  int get dailyGoal => _prefs.getInt('daily_goal') ?? 5;
  Future<void> setDailyGoal(int v) async {
    await _prefs.setInt('daily_goal', v.clamp(1, 30));
    notifyListeners();
  }

  bool get readerContinuous => _prefs.getBool('reader_continuous') ?? false;
  Future<void> setReaderContinuous(bool v) async {
    await _prefs.setBool('reader_continuous', v);
    notifyListeners();
  }
}
