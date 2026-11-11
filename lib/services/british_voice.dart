import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Result of checking the device text-to-speech engine for a British voice.
class VoiceCheck {
  const VoiceCheck({required this.available, required this.voiceName, required this.detail});
  final bool available;
  final String? voiceName;
  final String detail;
}

/// Optional device TTS, used ONLY when an en-GB voice that is installed and
/// does not require the network is present. It never falls back to an
/// American or other English voice.
class BritishVoice {
  FlutterTts? _tts;
  VoiceCheck? _cached;
  Map<String, String>? _voice;

  FlutterTts get _engine => _tts ??= FlutterTts();

  static bool isBritishLocale(String locale) {
    final l = locale.replaceAll('_', '-').toLowerCase();
    return l == 'en-gb' || l.startsWith('en-gb-');
  }

  /// Pure selection logic (unit-tested): picks an installed, offline en-GB
  /// voice from the list reported by Android.
  static Map<String, String>? pickVoice(List<Map<String, String>> voices) {
    final candidates = voices.where((v) {
      final locale = v['locale'] ?? '';
      final network = v['network_required'] == '1';
      final notInstalled = (v['features'] ?? '').contains('notInstalled');
      return isBritishLocale(locale) && !network && !notInstalled;
    }).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => (b['quality'] ?? '').compareTo(a['quality'] ?? ''));
    return candidates.first;
  }

  Future<VoiceCheck> check({bool refresh = false}) async {
    if (_cached != null && !refresh) return _cached!;
    try {
      final raw = await _engine.getVoices;
      final voices = <Map<String, String>>[
        for (final v in (raw as List? ?? const []))
          (v as Map).map((k, val) => MapEntry('$k', '$val')),
      ];
      final chosen = pickVoice(voices);
      _voice = chosen == null ? null : {'name': chosen['name']!, 'locale': chosen['locale']!};
      _cached = VoiceCheck(
        available: chosen != null,
        voiceName: chosen?['name'],
        detail: chosen != null
            ? 'British English voice installed: ${chosen['name']}'
            : 'No offline British English (en-GB) voice is installed on this device.',
      );
    } catch (e) {
      debugPrint('TTS check failed: $e');
      _cached = const VoiceCheck(available: false, voiceName: null, detail: 'Text-to-speech is not available.');
    }
    return _cached!;
  }

  Future<bool> isBritishOfflineAvailable() async => (await check()).available;

  Future<bool> speak(String text, {double rate = 1.0}) async {
    final c = await check();
    if (!c.available || _voice == null) return false;
    try {
      await _engine.setLanguage('en-GB');
      await _engine.setVoice(_voice!);
      await _engine.setSpeechRate(0.42 * rate);
      await _engine.awaitSpeakCompletion(true);
      await _engine.speak(text);
      return true;
    } catch (e) {
      debugPrint('TTS speak failed: $e');
      return false;
    }
  }

  Future<void> stop() async {
    if (_tts != null) await _tts!.stop();
  }
}
