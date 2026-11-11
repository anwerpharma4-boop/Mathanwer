import 'dart:convert';
import 'dart:io';

import 'package:english_for_iraq/app.dart';
import 'package:english_for_iraq/app_scope.dart';
import 'package:english_for_iraq/data/progress_store.dart';
import 'package:english_for_iraq/data/settings.dart';
import 'package:english_for_iraq/services/audio_service.dart';
import 'package:english_for_iraq/services/book_source.dart';
import 'package:english_for_iraq/services/british_voice.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 1x1 white PNG.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
);

/// Book source that does not need the Android PDF renderer.
class FakeBookSource extends BookSource {
  final List<String> requests = [];

  @override
  int get pageCount => 96;

  @override
  Future<void> open() async {}

  @override
  Future<Uint8List?> render(int page, int widthPx, {bool Function()? isWanted}) async {
    requests.add('$page@$widthPx');
    return tinyPng;
  }

  @override
  Future<void> close() async {}
}

bool _ffiReady = false;
bool _fontsLoaded = false;

/// Loads the real app fonts (instead of the square test font) so layouts in
/// tests match the device.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final p in paths) {
      final f = File(p);
      if (f.existsSync()) loader.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
    await loader.load();
  }

  await load('Andika', ['assets/fonts/Andika-Regular.ttf', 'assets/fonts/Andika-Bold.ttf']);
  await load('NotoKufiArabic', ['assets/fonts/NotoKufiArabic-Regular.ttf', 'assets/fonts/NotoKufiArabic-Bold.ttf']);
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/sdk/flutter';
  await load('MaterialIcons', ['$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
}

/// Advances fake time past game delays and settles animations.
Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Future<ProgressStore> openTestStore({String? path}) async {
  if (!_ffiReady) {
    sqfliteFfiInit();
    _ffiReady = true;
  }
  return ProgressStore.open(factory: databaseFactoryFfi, path: path ?? inMemoryDatabasePath);
}

Future<AppServices> makeServices({Map<String, Object> prefs = const {}, ProgressStore? store}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final settings = await SettingsController.load();
  final progress = store ?? ProgressStore.memory();
  return AppServices(
    settings: settings,
    progress: progress,
    audio: SilentAudio(),
    voice: BritishVoice(),
    book: FakeBookSource(),
  );
}

/// Pumps the whole app (or [home]) with fake services on a given screen size.
Future<AppServices> pumpApp(
  WidgetTester tester, {
  Widget? home,
  Size size = const Size(400, 800),
  AppServices? services,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  // Like the system "remove animations" setting: idle animations stop, so
  // pumpAndSettle can settle.
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.runAsync(loadAppFonts);
  final s = services ?? await tester.runAsync(() => makeServices()) as AppServices;
  if (home == null) {
    await tester.pumpWidget(EnglishForIraqApp(services: s));
  } else {
    await tester.pumpWidget(
      AppScope(
        services: s,
        child: MaterialApp(home: home),
      ),
    );
  }
  await tester.pump();
  return s;
}

/// Repo root (tests run from the package directory).
String repoPath(String rel) => '${Directory.current.path}/$rel';

/// Lets pending async work (database writes) complete inside widget tests.
Future<void> settle(WidgetTester tester, [Duration d = const Duration(milliseconds: 100)]) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pump(d);
}
