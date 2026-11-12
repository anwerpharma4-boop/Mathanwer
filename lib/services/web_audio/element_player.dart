// A media player built on one persistent HTML <audio> element (web only).
//
// iPad/iPhone Safari only lets an audio element play after a user gesture.
// Re-using a single element that was "unlocked" by the child's first tap
// keeps later, automatic playback (instructions, prompts) working.
export 'element_player_stub.dart' if (dart.library.js_interop) 'element_player_web.dart';
