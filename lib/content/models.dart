// Pure-Dart content models (no Flutter imports) so that they can also be used
// by command-line tools such as tool/export_speech.dart.

/// Kinds of entries in the textbook map.
enum LessonKind { lesson, project, story, revision }

/// Kinds of listening material taken from the textbook transcripts.
enum ScriptKind { conversation, song, chant, story, phrases }

class ScriptLine {
  const ScriptLine(this.speaker, this.text);

  /// Speaker label exactly as written in the textbook transcript
  /// (empty for narration or song lines).
  final String speaker;
  final String text;
}

/// A dialogue, song, chant, story or list of phrases from the book.
class Script {
  const Script({required this.title, required this.kind, required this.lines, this.track, this.instruction});

  final String title;
  final ScriptKind kind;
  final List<ScriptLine> lines;

  /// Audio track number printed in the Pupil's Book (headphones icon).
  final int? track;

  /// Instruction line as printed in the transcript (e.g. "Listen and point.").
  final String? instruction;
}

/// A vocabulary item taken from the textbook.
class VocabWord {
  const VocabWord({
    required this.id,
    required this.text,
    required this.topic,
    required this.page,
    this.image,
    this.say,
    this.colour,
    this.count,
    this.supplementary = false,
  });

  /// Stable identifier (also used for progress statistics).
  final String id;

  /// Spelling exactly as printed in the textbook.
  final String text;

  /// Topic group (e.g. "Alphabet", "Colours", "Classroom objects").
  final String topic;

  /// PDF page where the word is taught (PDF index == printed page number).
  final int page;

  /// Asset path of the original textbook picture, when one is available.
  final String? image;

  /// Text to pronounce when it differs from [text] (e.g. "one" for "1").
  final String? say;

  /// ARGB colour value for colour words (rendered as a paint swatch).
  final int? colour;

  /// Number of objects for number words.
  final int? count;

  /// True only for clearly-labelled enrichment content not in the textbook.
  final bool supplementary;

  String get spoken => say ?? text;
}

/// A letter of the alphabet with its textbook example words.
class LetterInfo {
  const LetterInfo({
    required this.lower,
    required this.words,
    required this.lessonPage,
    required this.nameIpa,
    required this.soundIpa,
    required this.soundHint,
  });

  final String lower;
  String get upper => lower.toUpperCase();

  /// Alphabet words from the textbook (ids into the vocabulary).
  final List<String> words;

  /// PDF page of the lesson that introduces the letter.
  final int lessonPage;

  /// British English letter name in IPA (e.g. "zɛd" for z).
  final String nameIpa;

  /// Phonics sound in IPA.
  final String soundIpa;

  /// Child-friendly description of the sound shown under the IPA.
  final String soundHint;

  /// Asset path of the original alphabet picture card (pages 6-7).
  String get cardImage => 'assets/images/letters/card_$lower.webp';

  /// Page of the alphabet card (a-l on page 6, m-z on page 7).
  int get cardPage => lower.compareTo('l') <= 0 ? 6 : 7;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.unitId,
    required this.number,
    required this.title,
    required this.pages,
    this.kind = LessonKind.lesson,
    this.letters = const [],
    this.words = const [],
    this.language = const [],
    this.scripts = const [],
    this.bookActivities = const [],
  });

  final String id;
  final int unitId;

  /// Lesson number as printed (0 for projects and stories).
  final int number;
  final String title;

  /// PDF pages covered by this lesson (first page is the main page).
  final List<int> pages;
  final LessonKind kind;

  /// Alphabet letters taught in this lesson.
  final List<String> letters;

  /// Vocabulary ids practised in this lesson.
  final List<String> words;

  /// Key language (sentences / phrases) exactly as printed.
  final List<String> language;

  /// Listening material (dialogues, songs, stories) from the transcripts.
  final List<Script> scripts;

  /// Activity instructions as given by the textbook icon key.
  final List<String> bookActivities;

  int get page => pages.first;
}

class Unit {
  const Unit({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.colour,
    required this.firstPage,
    required this.lastPage,
    required this.lessons,
    required this.vocabularyTopics,
  });

  final int id;
  final String title;
  final String titleAr;
  final int colour;
  final int firstPage;
  final int lastPage;
  final List<Lesson> lessons;

  /// Vocabulary topic names taught in this unit (from the Book map).
  final List<String> vocabularyTopics;

  bool get isRevision => title == 'Revision';
}

/// Non-unit sections of the book (cover, book map, transcripts, ...).
class BookSection {
  const BookSection(this.title, this.titleAr, this.firstPage, this.lastPage);

  final String title;
  final String titleAr;
  final int firstPage;
  final int lastPage;
}
