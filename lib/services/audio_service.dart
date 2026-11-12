import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'british_voice.dart';
import 'web_audio/element_player.dart';

enum Sfx { correct, wrong, complete, tap, star, flip }

/// Audio output used by the whole app.
abstract class AudioOut {
  /// Speaks [text] in British English. Returns false if no British English
  /// audio is available for it (the app never falls back to another accent).
  Future<bool> say(String text);
  Future<void> letterName(String letter);
  Future<void> letterSound(String letter);
  Future<void> sfx(Sfx s);
  Future<void> stop();
  bool hasClip(String text);

  /// Web only: unlocks audio on the first tap (iPad/iPhone Safari).
  void unlock() {}
  double get rate;
  set rate(double v);
  bool sfxEnabled = true;
}

/// Plays bundled, pre-generated en-GB clips (offline). Falls back to the
/// device text-to-speech engine only if a British English (en-GB) voice is
/// verified to be installed for offline use.
class BundledAudio extends AudioOut {
  BundledAudio._(this._clips, this._voice);

  final Map<String, String> _clips;
  final BritishVoice _voice;
  final AudioPlayer _speech = AudioPlayer(playerId: 'speech');
  final AudioPlayer _fx = AudioPlayer(playerId: 'sfx');

  /// On the web: persistent <audio> elements (see element_player.dart).
  final ElementPlayer? _webSpeech = createElementPlayer();
  final ElementPlayer? _webFx = createElementPlayer();
  Completer<void>? _done;
  double _rate = 1.0;
  int _token = 0;

  static Future<BundledAudio> load(BritishVoice voice) async {
    Map<String, String> clips = {};
    try {
      final raw = await rootBundle.loadString('assets/audio/speech_manifest.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      clips = (json['clips'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String));
    } catch (e) {
      debugPrint('Audio manifest missing: $e');
    }
    final a = BundledAudio._(clips, voice);
    await a._init();
    return a;
  }

  Future<void> _init() async {
    if (_webSpeech != null) return;
    try {
      await _speech.setReleaseMode(ReleaseMode.stop);
      await _fx.setReleaseMode(ReleaseMode.stop);
      await _fx.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Audio init failed: $e');
    }
    _speech.onPlayerComplete.listen((_) => _finish());
  }

  void _finish() {
    final d = _done;
    _done = null;
    if (d != null && !d.isCompleted) d.complete();
  }

  @override
  double get rate => _rate;
  @override
  set rate(double v) => _rate = v;

  @override
  bool hasClip(String text) => _clips.containsKey(text);

  /// URL of a bundled asset in the web build.
  static String _webUrl(String path) => 'assets/assets/$path';

  @override
  void unlock() {
    _webSpeech?.unlock(_webUrl('audio/sfx/silence.mp3'));
    _webFx?.unlock(_webUrl('audio/sfx/silence.mp3'));
  }

  Future<bool> _playAsset(String path) async {
    final token = ++_token;
    _finish();
    final web = _webSpeech;
    if (web != null) {
      web.stop();
      return web.play(_webUrl(path), rate: _rate);
    }
    try {
      await _speech.stop();
      if (token != _token) return true;
      final done = Completer<void>();
      _done = done;
      await _speech.play(AssetSource(path));
      // Always apply: the Android player keeps its previous rate otherwise
      // (e.g. after switching from Slow back to Normal).
      await _speech.setPlaybackRate(_rate);
      // Safety timeout so the UI never waits forever on a lost event.
      await done.future.timeout(const Duration(seconds: 60), onTimeout: () {});
      return true;
    } catch (e) {
      debugPrint('Audio play failed for $path: $e');
      _finish();
      return false;
    }
  }

  @override
  Future<bool> say(String text) async {
    final clip = _clips[text] ?? _clips[text.trim()];
    if (clip != null) return _playAsset('audio/speech/$clip');
    // Not bundled: use the device voice only if it is verified British.
    if (await _voice.isBritishOfflineAvailable()) {
      return _voice.speak(text, rate: _rate);
    }
    return false;
  }

  @override
  Future<void> letterName(String letter) => _playAsset('audio/letters/name_${letter.toLowerCase()}.mp3');

  @override
  Future<void> letterSound(String letter) => _playAsset('audio/letters/sound_${letter.toLowerCase()}.mp3');

  @override
  Future<void> sfx(Sfx s) async {
    if (!sfxEnabled) return;
    final web = _webFx;
    if (web != null) {
      web.play(_webUrl('audio/sfx/${s.name}.mp3'), volume: 0.8);
      return;
    }
    try {
      await _fx.stop();
      await _fx.play(AssetSource('audio/sfx/${s.name}.mp3'), volume: 0.8);
    } catch (e) {
      debugPrint('sfx failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    _token++;
    _finish();
    _webSpeech?.stop();
    try {
      if (_webSpeech == null) await _speech.stop();
      await _voice.stop();
    } catch (_) {}
  }
}

/// Silent implementation for tests and for when audio initialisation fails.
class SilentAudio extends AudioOut {
  SilentAudio({Set<String>? clips}) : _clips = clips ?? {};
  final Set<String> _clips;
  final List<String> spoken = [];
  @override
  double rate = 1.0;

  @override
  bool hasClip(String text) => _clips.contains(text);
  @override
  Future<bool> say(String text) async {
    spoken.add(text);
    return true;
  }

  @override
  Future<void> letterName(String letter) async => spoken.add('name:$letter');
  @override
  Future<void> letterSound(String letter) async => spoken.add('sound:$letter');
  @override
  Future<void> sfx(Sfx s) async {}
  @override
  Future<void> stop() async {}
}
