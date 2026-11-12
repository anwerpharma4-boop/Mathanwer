import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web audio output (Android/desktop browsers and iPad/iPhone Safari).
abstract class ElementPlayer {
  Future<bool> play(String url, {double rate = 1.0, double volume = 1.0});
  void unlock(String silentUrl);
  void stop();
}

ElementPlayer? createElementPlayer() => _WebAudioPlayer();

/// Plays clips through the Web Audio API.
///
/// Why not one <audio> element per clip: iPad/iPhone Safari only lets an
/// element start after a tap, and starting one element can pause another
/// (a "correct" chime could cut off the spoken word). A single AudioContext,
/// resumed during a tap, can then play any number of sounds at any time.
class _WebAudioPlayer implements ElementPlayer {
  static web.AudioContext? _ctx;
  static final _buffers = <String, web.AudioBuffer>{}; // insertion ordered (LRU)
  static final _loading = <String, Future<web.AudioBuffer?>>{};
  static bool _sessionSet = false;

  web.AudioBufferSourceNode? _source;
  Completer<bool>? _done;
  int _token = 0;

  /// Pitch-preserving element, used only for slow (or fast) speed.
  web.HTMLAudioElement? _el;
  bool _elPrimed = false;

  static web.AudioContext get _context {
    final c = _ctx ??= web.AudioContext();
    if (!_sessionSet) {
      _sessionSet = true;
      // Safari 17+: play even when the device is in silent mode.
      try {
        final session = web.window.navigator.getProperty<JSObject?>('audioSession'.toJS);
        session?.setProperty('type'.toJS, 'playback'.toJS);
      } catch (_) {}
    }
    return c;
  }

  void _finish(bool ok) {
    final d = _done;
    _done = null;
    if (d != null && !d.isCompleted) d.complete(ok);
  }

  @override
  void unlock(String silentUrl) {
    // Runs inside the tap handler (synchronously): iOS allows audio to start.
    final c = _context;
    if (c.state != 'running') {
      c.resume().toDart.then((_) {}, onError: (Object e) => debugPrint('AudioContext resume failed: $e'));
      // Playing a 1-sample buffer completes the unlock on older iOS.
      try {
        final b = c.createBuffer(1, 1, 22050);
        final s = c.createBufferSource()..buffer = b;
        s.connect(c.destination);
        s.start();
      } catch (_) {}
    }
    if (!_elPrimed) {
      _elPrimed = true;
      final el = _el ??= web.HTMLAudioElement()..preload = 'auto';
      el.src = silentUrl;
      el.play().toDart.then(
        (_) {},
        onError: (Object e) {
          _elPrimed = false;
        },
      );
    }
  }

  static Future<web.AudioBuffer?> _load(String url) {
    final hit = _buffers.remove(url);
    if (hit != null) {
      _buffers[url] = hit; // most recently used
      return Future.value(hit);
    }
    return _loading[url] ??= () async {
      try {
        final res = await web.window.fetch(url.toJS).toDart;
        if (!res.ok) throw StateError('HTTP ${res.status}');
        final bytes = await res.arrayBuffer().toDart;
        final buffer = await _context.decodeAudioData(bytes).toDart;
        _buffers[url] = buffer;
        while (_buffers.length > 120) {
          _buffers.remove(_buffers.keys.first);
        }
        return buffer;
      } catch (e) {
        debugPrint('Could not load audio $url: $e');
        return null;
      } finally {
        _loading.remove(url);
      }
    }();
  }

  @override
  Future<bool> play(String url, {double rate = 1.0, double volume = 1.0}) async {
    stop();
    final token = ++_token;
    final done = Completer<bool>();
    _done = done;

    if ((rate - 1.0).abs() > 0.01) return _playElement(url, rate, volume, token, done);

    final c = _context;
    if (c.state != 'running') {
      try {
        await c.resume().toDart.timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    final buffer = await _load(url);
    if (token != _token) return false; // a newer sound was requested meanwhile
    if (buffer == null) {
      _finish(false);
      return false;
    }
    try {
      final gain = c.createGain();
      gain.gain.value = volume;
      gain.connect(c.destination);
      final source = c.createBufferSource()..buffer = buffer;
      source.connect(gain);
      source.onended = ((web.Event _) {
        if (token == _token) _finish(true);
      }).toJS;
      _source = source;
      source.start();
    } catch (e) {
      debugPrint('Audio start failed: $e');
      _finish(false);
      return false;
    }
    // Safety net in case "ended" never arrives.
    final seconds = buffer.duration + 5;
    return done.future.timeout(Duration(milliseconds: (seconds * 1000).round()), onTimeout: () => true);
  }

  Future<bool> _playElement(String url, double rate, double volume, int token, Completer<bool> done) async {
    final el = _el ??= web.HTMLAudioElement()..preload = 'auto';
    late StreamSubscription<web.Event> ended;
    late StreamSubscription<web.Event> error;
    ended = el.onEnded.listen((_) {
      if (token == _token) _finish(true);
    });
    error = el.onError.listen((_) {
      if (token == _token) _finish(false);
    });
    el.src = url;
    el.preservesPitch = true;
    el.playbackRate = rate;
    el.volume = volume;
    try {
      await el.play().toDart;
    } catch (e) {
      debugPrint('Slow playback blocked or failed: $e');
      _finish(false);
    }
    final ok = await done.future.timeout(const Duration(seconds: 60), onTimeout: () => false);
    await ended.cancel();
    await error.cancel();
    return ok;
  }

  @override
  void stop() {
    _token++;
    final s = _source;
    _source = null;
    if (s != null) {
      try {
        s.onended = null;
        s.stop();
      } catch (_) {}
    }
    _el?.pause();
    _finish(true);
  }
}
