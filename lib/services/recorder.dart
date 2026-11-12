import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records the child's own voice so they can compare it with the model.
/// This is NOT speech recognition: nothing is analysed or uploaded, and the
/// recording is overwritten each time.
class VoiceRecorder {
  AudioRecorder? _rec;
  final AudioPlayer _player = AudioPlayer(playerId: 'myvoice');
  String? _lastPath;

  bool get hasRecording {
    final path = _lastPath;
    if (path == null) return false;
    // On the web the result is a blob URL held by the browser.
    if (kIsWeb) return true;
    return File(path).existsSync();
  }

  Future<bool> start() async {
    try {
      final rec = _rec ??= AudioRecorder();
      if (!await rec.hasPermission()) return false;
      if (kIsWeb) {
        // Safari records AAC (mp4); Chrome/Firefox record Opus (webm).
        final encoder = await rec.isEncoderSupported(AudioEncoder.aacLc) ? AudioEncoder.aacLc : AudioEncoder.opus;
        await rec.start(RecordConfig(encoder: encoder, numChannels: 1), path: '');
      } else {
        final dir = await getTemporaryDirectory();
        final path = p.join(dir.path, 'my_voice.m4a');
        await rec.start(const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1), path: path);
      }
      return true;
    } catch (e) {
      debugPrint('Recording unavailable: $e');
      return false;
    }
  }

  Future<void> stop() async {
    try {
      _lastPath = await _rec?.stop();
    } catch (e) {
      debugPrint('Stop recording failed: $e');
    }
  }

  Future<void> playBack() async {
    final path = _lastPath;
    if (path == null) return;
    try {
      await _player.stop();
      await _player.play(kIsWeb ? UrlSource(path) : DeviceFileSource(path));
    } catch (e) {
      debugPrint('Playback failed: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _rec?.dispose();
      await _player.dispose();
    } catch (_) {}
  }
}
