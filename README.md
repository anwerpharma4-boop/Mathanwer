# English for Iraq — 1st Primary (interactive app)

An offline app (Flutter) for **Android** and **iPad/iPhone (web version in Safari)** for children aged 6–7 that combines:

1. **The original textbook**: *English for Iraq – 1st Primary – Pupil's Book* (Jenny Quintana and Helen O'Neill,
   Garnet Education), all **96 pages**, shown **unchanged** in a full PDF reader.
2. **A separate interactive learning layer** built only from that book's letters, words, dialogues, songs and
   stories: lessons, alphabet, vocabulary, listening & speaking, 12 games, quizzes, drawing, rewards and a
   parent dashboard. English is the learning language; Arabic is available for the interface.

No internet, no accounts, no ads, no tracking. Progress is stored only on the device.

---

## Status at a glance

| Area | Status |
|---|---|
| All 96 original pages bundled unchanged (SHA-256 verified) | ✅ automated test |
| PDF reader: single page + continuous, pinch zoom 1×–12×, one-finger pan with edge limits, double-tap, fit width / fit page / reset, thumbnails, search, bookmarks, last position, full screen | ✅ widget tests with real multi-touch gestures |
| Sharp zoom (re-render up to 2480 px = the PDF's 300 dpi text layer) | ✅ implemented; quality on device not visually verified |
| Interactive lessons linked to their PDF pages (8 units, 64 lessons/projects/stories) | ✅ tests |
| British English audio (en-GB) bundled offline: 615 phrases, 26 letter names, 26 phonics sounds | ✅ generated + checked automatically (see *Audio*) |
| Alphabet (upper/lower, name, sound, textbook card, words, tracing, recognition, mini quiz) | ✅ tests |
| Vocabulary by topic (from the book only), listen & repeat, picture–word, recognition | ✅ tests |
| Listening & speaking (dialogues, songs as spoken lyrics, stories, listen-and-say pauses, speed) | ✅ tests |
| Record-and-compare own voice (no speech recognition) | ✅ implemented; needs a device microphone to verify |
| 12 games, unit quizzes, big challenge, revision of weak words | ✅ tests |
| Stars, badges, levels, daily goal, progress persistence after restart | ✅ tests (SQLite) |
| Parent dashboard behind a grown-up question | ✅ tests |
| Drawing, colouring, tracing, eraser, colours, brush sizes, save PNG | ✅ tests (saving needs a device) |
| English / Arabic (RTL) interface | ✅ tests |
| Phone / tablet / landscape layouts | ✅ rendered and reviewed (screenshots) |
| Debug and release APK build | ✅ built in CI-like environment |
| Web version for iPad (Safari, add to Home Screen, works offline) | ✅ built; tested in Chromium with iPad emulation: textbook (pdf.js), pinch zoom, audio, offline reload, saved progress. Not yet tested on a real iPad. |
| Install and run on a real device / emulator, airplane-mode test | ⚠️ **not done here** – no Android device or emulator (no KVM) was available. Use [docs/MANUAL_TEST_CHECKLIST.md](docs/MANUAL_TEST_CHECKLIST.md). |

---

## Textbook fidelity

* `assets/book/english_for_iraq_1st_primary_pupils_book.pdf` is the supplied file, byte-for-byte
  (SHA-256 `7f054d38…08af`, checked by `test/book_integrity_test.dart`).
* The reader rasterises pages for display only; nothing is redrawn, translated or replaced.
* **Page numbers:** in this edition the PDF page index equals the printed page number on every page
  (checked visually for the whole book), so "page 44" means the same thing everywhere in the app.
* Pictures in the interactive activities are **cropped from the original pages** (alphabet cards pp. 6–7,
  picture dictionary pp. 94–96, topic pictures pp. 19, 21, 28, 45–46, 56, 64, 68–69) by
  `tool/extract_images.py`. No AI-generated illustrations are used. The robot mascot and the colouring-page
  outlines are original app artwork drawn in code and are not presented as textbook content.
* All dialogue, song, story and sentence text was transcribed from the book (unit pages and the Transcripts,
  pp. 80–93). The book's original CD recordings and song melodies are **not** included; songs are read aloud
  and labelled as such.

### Book structure (PDF pages)

| Pages | Content |
|---|---|
| 1–7 | Cover, publication details, icon key, book map, alphabet cards |
| 8–17 | Unit 1 *Hello* (a–f, colours) + Project: draw and colour a ball |
| 18–27 | Unit 2 *My school* (g–l, classroom objects) + Story: *What is it?* |
| 28–37 | Unit 3 *My toys* (m–t, numbers 1–10) + Project: numbers poster |
| 38–43 | Unit 4 *Revision* (u–z) + Story: *Happy birthday!* |
| 44–53 | Unit 5 *At the zoo* (animals, colours, adjectives) + Project: animal mask |
| 54–63 | Unit 6 *My body* + Story: *At the Zoo* |
| 64–73 | Unit 7 *My family* (family, in the house) + Project: draw your family |
| 74–79 | Unit 8 *Revision* + Story: *Ahmed's dream* |
| 80–93 | Transcripts |
| 94–96 | Picture dictionary |

---

## Audio (British English)

* Locale **en-GB only**. All words, sentences, dialogue lines, song lyrics, story sentences and app instructions
  are pre-generated and bundled (`assets/audio/`, ~7 MB, MP3 — plays on Android and in Safari), so the app speaks fully offline.
* Voice: open-source **Piper** neural TTS, voice **`en_GB-cori-high`** (UK English female; trained on
  public-domain LibriVox recordings). Phonemes come from espeak-ng British English — e.g. *tomato*
  /təmˈɑːtəʊ/, *car* /kˈɑː/ (non-rhotic), *z* /zˈɛd/, *orange* /ˈɒɹɪndʒ/.
* These are high-quality synthetic voices, **not human recordings**. Generation is checked automatically
  (phonemes, duration per phoneme, garbled-tail detection), but a native-speaker listening check is still
  recommended before classroom use; isolated phonics sounds are the hardest for TTS.
* The device's text-to-speech is used **only** for text without a bundled clip and **only** if an installed,
  offline `en-GB` voice is found (`lib/services/british_voice.dart`). Other accents are never substituted.
  Settings → *Check device voice* shows the result.
* Playback speed: Slow (0.75×) / Normal, or 0.5×–1.25× in Settings.

Regenerate (needs Python 3, `pip install piper-tts`, ffmpeg with libvorbis, and the voice model from
huggingface.co/rhasspy/piper-voices):

```bash
dart run tool/export_speech.dart > build/speech.json
python tool/generate_audio.py --model /path/to/en_GB-cori-high.onnx --force
```

---

## Features

**Home**: Start Learning (continues with the next unfinished lesson), Original Textbook, Interactive Lessons,
Alphabet, Vocabulary, Listening & Speaking, Games, Quizzes & Challenges, My Progress, Settings, Drawing & Colouring.

**Reader** (`lib/features/reader/`): single-page (swipe to turn) and continuous scrolling; two-finger pinch
zoom from fit-page (1×) up to 12×; one-finger panning in all directions, clamped at the page edges; zoom is
kept while panning; double-tap zoom (2.5×) / double-tap to reset; zoom −/+, fit width, fit page, reset;
page slider and previous/next; thumbnails; search by page number, unit, lesson, letter or word; bookmarks;
remembers the last page; full-screen mode. Pages are rendered lazily through a single serial queue
(Android's PdfRenderer allows one open page) with an LRU cache; only the centre page gets the sharpest render.

**Lessons**: every lesson/project/story opens on tabs *Book page* (the original page, zoomable, with
"Open in textbook"), *Learn* (letter, words, key language), *Listen* (dialogues/songs/stories from the
transcripts), *Words* and *Practise* (games built from the lesson's own words).

**Alphabet**: A–Z grid of the book's alphabet cards; per letter: upper/lower case, British letter name,
phonics sound (IPA + "a as in apple"), textbook words with pictures, finger tracing (graded against the letter
shape), "find the letter" grid, mini quiz; plus find-the-letter, match big/small, first-sound games.

**Games (12)**: match word–picture · big & small letters · listen and choose · missing letter · arrange letters
· colours · counting 1–10 · animals · classroom objects · listen and repeat · memory cards · drag and drop.
Wrong answers only trigger a gentle "try again" — only first-try answers count, and every finished activity
earns at least one star.

**Assessment**: unit quizzes 1–8, big challenge, revision of words answered wrongly; stars, 20 badges,
5 levels, daily goal, lesson completion; parent dashboard (overall %, units/lessons done, time per day,
words mastered, quiz history, weak topics/activities, reset) behind a multiplication question.

---

## Project layout

```
lib/
  content/        book data (pure Dart): units, lessons, vocabulary, scripts, page map
  core/           theme, English/Arabic strings
  data/           SQLite progress store, settings
  services/       PDF rendering queue, audio, en-GB voice check, voice recorder
  features/       home, reader, lessons, alphabet, vocabulary, listening, games,
                  quizzes, progress, parent, settings, drawing
  widgets/        shared widgets, mascot, celebrations
assets/           book PDF, cropped textbook pictures, audio, fonts
tool/             image extraction, speech export, audio generation, icons
test/             unit + widget tests, screenshot renderer
docs/             manual device test checklist
```

---

## iPad / iPhone (web version)

iOS cannot install Android APKs, so the app is also published as an offline web app.

1. One-time: on GitHub open **Settings → Pages → Source: GitHub Actions**. The workflow
   `.github/workflows/web.yml` then builds and publishes the site on every push to
   **https://anwerpharma4-boop.github.io/Mathanwer/**.
2. On the iPad open that address in **Safari** (with internet, once) and wait about a minute while
   the book, audio and pictures (~40 MB) are saved for offline use.
3. Tap **Share → Add to Home Screen**. Open the app from the new icon (it runs full screen).
   Open it once from the icon while still online, so that copy also saves everything; after
   that it works without internet.

Notes: the home-screen app keeps its own storage, separate from Safari. Progress and drawings are
stored on the iPad (browser storage); clearing Safari website data deletes them. Tap anywhere once
after opening so iOS allows sound.

**بالعربية:** افتح الرابط أعلاه في متصفح Safari على الآيباد مع اتصال بالإنترنت لأول مرة وانتظر دقيقة،
ثم اضغط زر المشاركة ← «إضافة إلى الشاشة الرئيسية». افتح التطبيق من الأيقونة الجديدة مرة واحدة والإنترنت متصل،
وبعدها يعمل دون إنترنت.

Build it yourself: `tool/build_web.sh /Mathanwer/` → static files in `build/web` (any HTTPS static host works).

## Build

Requirements: Flutter **3.50.0** (Dart 3.14), Android SDK (platform 36, build-tools 35), JDK 17+.

```bash
flutter pub get
flutter test                      # 71 automated tests
flutter build apk --debug         # build/app/outputs/flutter-apk/app-debug.apk
flutter build apk --release       # build/app/outputs/flutter-apk/app-release.apk
flutter build apk --release --split-per-abi   # smaller per-CPU APKs
```

**Release signing:** create `android/key.properties` (never commit it):

```
storeFile=/absolute/path/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Without it, release builds are signed with the debug key (installable for testing, not for Google Play).

Screenshots for visual review:

```bash
pdftoppm -r 60 -png assets/book/*.pdf /tmp/pages/p
SCREENSHOTS=1 BOOK_PAGES=/tmp/pages flutter test test/screenshots_test.dart   # -> build/screenshots/
```

Note: tests use `sqflite_common_ffi`; `pubspec.yaml` tells `package:sqlite3` to use the system SQLite
(`hooks: user_defines: sqlite3: source: system`) so no binaries are downloaded.

---

## Known limitations

* Not yet run on a physical device or emulator (none available in the build environment). Gestures, rendering
  and logic are covered by widget tests, but device-only behaviour (PdfRenderer output, audio output,
  microphone, file saving, performance on low-end phones) must be checked with the manual checklist.
* No original CD audio or song melodies; audio is synthetic British English.
* No speech recognition: speaking practice is listen → say → optionally record yourself and compare.
* Continuous mode starts at fit-page and zooms in; it does not zoom out below one page.
* Textbook illustrations are cropped from the scanned pages, so some include neighbouring scene details.

## Credits and licences

* Textbook © Garnet Publishing Ltd / Republic of Iraq Ministry of Education; distributed free by law
  (as printed on the cover). Bundled for use with the school course.
* Piper TTS (MIT), voice *Cori* (dataset: public-domain LibriVox recordings).
* Fonts: Andika and Noto Kufi Arabic — SIL Open Font License 1.1.
* App code, mascot, icon and colouring outlines: original work for this project.
