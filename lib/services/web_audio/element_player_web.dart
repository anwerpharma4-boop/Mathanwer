import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

abstract class ElementPlayer {
  Future<bool> play(String url, {double rate = 1.0, double volume = 1.0});
  void unlock(String silentUrl);
  void stop();
}

ElementPlayer? createElementPlayer() => _WebElementPlayer();

class _WebElementPlayer implements ElementPlayer {
  final web.HTMLAudioElement _el = web.HTMLAudioElement()..preload = 'auto';
  Completer<bool>? _done;
  bool _unlocked = false;

  _WebElementPlayer() {
    _el.onEnded.listen((_) => _finish(true));
    _el.onError.listen((_) => _finish(false));
  }

  void _finish(bool ok) {
    final d = _done;
    _done = null;
    if (d != null && !d.isCompleted) d.complete(ok);
  }

  @override
  void unlock(String silentUrl) {
    if (_unlocked) return;
    _unlocked = true;
    // Must run synchronously inside the tap handler.
    _el.src = silentUrl;
    _el.play().toDart.then(
      (_) {},
      onError: (Object e) {
        _unlocked = false;
        debugPrint('Audio unlock failed: $e');
      },
    );
  }

  @override
  Future<bool> play(String url, {double rate = 1.0, double volume = 1.0}) async {
    _finish(false);
    final done = Completer<bool>();
    _done = done;
    _el.src = url;
    _el.playbackRate = rate;
    _el.volume = volume;
    try {
      await _el.play().toDart;
    } catch (e) {
      debugPrint('Audio play blocked or failed: $e');
      _finish(false);
      return false;
    }
    return done.future.timeout(const Duration(seconds: 60), onTimeout: () => false);
  }

  @override
  void stop() {
    _el.pause();
    _finish(true);
  }
}
