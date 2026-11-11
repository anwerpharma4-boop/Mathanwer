// Textbook content of "English for Iraq - 1st Primary - Pupil's Book"
// (Jenny Quintana and Helen O'Neill, Garnet Education).
//
// Everything in this file was transcribed from the supplied 96-page PDF:
// the Book map (pages 4-5), the unit pages (8-79), the Transcripts
// (pages 80-93) and the Picture dictionary (pages 94-96).
// PDF page index == printed page number for every page of this edition.
//
// Nothing here replaces the original pages: the textbook PDF is shown
// unchanged by the reader. This data only drives the interactive layer.

import 'models.dart';

const int bookPageCount = 96;
const String bookAsset =
    'assets/book/english_for_iraq_1st_primary_pupils_book.pdf';

/// SHA-256 of the original PDF supplied by the publisher/school.
/// Verified by test/book_integrity_test.dart.
const String bookSha256 =
    '7f054d382af285a5c9b778bfbb149417d6192fbdd496efbab7d2d0520b2108af';

String _img(String stem) => 'assets/images/words/$stem.webp';

// ---------------------------------------------------------------------------
// Vocabulary
// ---------------------------------------------------------------------------

const String topicAlphabet = 'Alphabet words';
const String topicColours = 'Colours';
const String topicClassroom = 'Classroom objects';
const String topicToys = 'Toys';
const String topicNumbers = 'Numbers';
const String topicAnimals = 'Animals';
const String topicAdjectives = 'Adjectives';
const String topicBody = 'Parts of the body';
const String topicFamily = 'Family';
const String topicHouse = 'In the house';

/// Alphabet words: letter -> (word, picture-dictionary page).
const Map<String, List<String>> _alphabetWords = {
  'a': ['apple', 'ant'],
  'b': ['ball', 'bus'],
  'c': ['car', 'cat'],
  'd': ['dog', 'duck'],
  'e': ['egg', 'elephant'],
  'f': ['flower', 'fish'],
  'g': ['girl', 'goat'],
  'h': ['horse', 'house'],
  'i': ['ink', 'in'],
  'j': ['juice', 'jumper'],
  'k': ['key', 'kite'],
  'l': ['lemon', 'lion'],
  'm': ['monkey', 'moon'],
  'n': ['net', 'nose'],
  'o': ['orange', 'olive'],
  'p': ['plane', 'pizza'],
  'q': ['question', 'queen'],
  'r': ['robot', 'rabbit'],
  's': ['snake', 'sun'],
  't': ['taxi', 'tomato'],
  'u': ['umbrella', 'up'],
  'v': ['van', 'violin'],
  'w': ['window', 'watch'],
  'x': ['x-ray'],
  'y': ['yo-yo'],
  'z': ['zebra'],
};

const Map<String, int> _letterLessonPage = {
  'a': 8, 'b': 9, 'c': 10, 'd': 11, 'e': 12, 'f': 13, //
  'g': 18, 'h': 19, 'i': 20, 'j': 21, 'k': 22, 'l': 23, //
  'm': 28, 'n': 29, 'o': 30, 'p': 31, 'q': 32, 'r': 33, 's': 34, 't': 35, //
  'u': 38, 'v': 39, 'w': 40, 'x': 41, 'y': 41, 'z': 41,
};

String wordId(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

int _dictionaryPage(String letter) {
  if (letter.compareTo('h') <= 0) return 94;
  if (letter.compareTo('p') <= 0) return 95;
  return 96;
}

List<VocabWord> _buildVocabulary() {
  final list = <VocabWord>[];
  _alphabetWords.forEach((letter, words) {
    for (final w in words) {
      list.add(VocabWord(
        id: wordId(w),
        text: w,
        topic: topicAlphabet,
        page: _letterLessonPage[letter]!,
        image: _img(wordId(w)),
        // "in" is taught with a picture of a robot in a box.
      ));
    }
  });

  void add(String text, String topic, int page,
      {String? image, int? colour, String? say, int? count}) {
    list.add(VocabWord(
      id: '${wordId(topic)}__${wordId(text)}',
      text: text,
      topic: topic,
      page: page,
      image: image,
      colour: colour,
      say: say,
      count: count,
    ));
  }

  // Colours (Unit 1 lessons 7-8, Unit 5 lesson 2).
  add('blue', topicColours, 14, colour: 0xFF2F6FD6);
  add('red', topicColours, 14, colour: 0xFFE53935);
  add('yellow', topicColours, 14, colour: 0xFFFFD60A);
  add('orange', topicColours, 15, colour: 0xFFFF8C1A);
  add('green', topicColours, 15, colour: 0xFF2EAD5B);
  add('pink', topicColours, 15, colour: 0xFFF06AB0);
  add('black', topicColours, 45, colour: 0xFF1D1D1F);
  add('white', topicColours, 45, colour: 0xFFFFFFFF);
  add('brown', topicColours, 45, colour: 0xFF8B5A2B);
  add('grey', topicColours, 45, colour: 0xFF9AA0A6);

  // Classroom objects (Unit 2).
  add('book', topicClassroom, 19, image: _img('book'));
  add('ruler', topicClassroom, 19, image: _img('ruler'));
  add('bag', topicClassroom, 19, image: _img('bag'));
  add('pencil case', topicClassroom, 19, image: _img('pencil_case'));
  add('rubber', topicClassroom, 19, image: _img('rubber'));
  add('pen', topicClassroom, 19, image: _img('pen'));
  add('pencil', topicClassroom, 19, image: _img('pencil'));
  add('bin', topicClassroom, 21, image: _img('bin'));
  add('desk', topicClassroom, 21, image: _img('desk'));
  add('chair', topicClassroom, 21, image: _img('chair'));
  add('CD', topicClassroom, 21, image: _img('cd'), say: 'a CD');

  // Toys (Unit 3).
  add('bear', topicToys, 28);
  add('bike', topicToys, 28, image: _img('bike'));
  add('doll', topicToys, 28, image: _img('doll'));
  add('net', topicToys, 29, image: _img('net'));
  add('skates', topicToys, 28, image: _img('skates'));
  add('toy', topicToys, 28, image: _img('toy'));
  add('yo-yo', topicToys, 28, image: _img('yo_yo'));
  add('balloon', topicToys, 30, image: _img('balloon'));
  add('present', topicToys, 33);

  // Numbers 1-10 (Unit 3 lessons 3-4).
  const names = [
    'one', 'two', 'three', 'four', 'five', //
    'six', 'seven', 'eight', 'nine', 'ten'
  ];
  for (var i = 1; i <= 10; i++) {
    add('$i', topicNumbers, i <= 5 ? 30 : 31, say: names[i - 1], count: i);
  }

  // Animals (Unit 5).
  add('camel', topicAnimals, 44, image: _img('camel'));
  add('tiger', topicAnimals, 44, image: _img('tiger'));
  add('penguin', topicAnimals, 44, image: _img('penguin'));
  add('lion', topicAnimals, 44, image: _img('lion'));
  add('elephant', topicAnimals, 44, image: _img('elephant'));
  add('duck', topicAnimals, 44, image: _img('duck'));
  add('monkey', topicAnimals, 44, image: _img('monkey'));
  add('rabbit', topicAnimals, 44, image: _img('rabbit'));
  add('goat', topicAnimals, 44, image: _img('goat'));

  // Adjectives (Unit 5 lesson 3).
  add('big', topicAdjectives, 46, image: _img('big'));
  add('funny', topicAdjectives, 46, image: _img('funny'));
  add('little', topicAdjectives, 46, image: _img('little'));
  add('long', topicAdjectives, 46, image: _img('long'));

  // Parts of the body (Unit 6).
  add('head', topicBody, 56, image: _img('head'));
  add('toes', topicBody, 56, image: _img('toes'));
  add('ears', topicBody, 56, image: _img('ears'));
  add('nose', topicBody, 56, image: _img('nose'));
  add('hands', topicBody, 56, image: _img('hands'));
  add('eyes', topicBody, 56, image: _img('eyes'));
  add('body', topicBody, 57);
  add('arm', topicBody, 57);
  add('leg', topicBody, 57);
  add('feet', topicBody, 57);

  // Family (Unit 7).
  add('dad', topicFamily, 64, image: _img('dad'));
  add('mum', topicFamily, 64, image: _img('mum'));
  add('sister', topicFamily, 64, image: _img('sister'));
  add('brother', topicFamily, 64, image: _img('brother'));
  add('grandma', topicFamily, 64, image: _img('grandma'));
  add('grandpa', topicFamily, 64, image: _img('grandpa'));

  // In the house (Unit 7).
  add('bed', topicHouse, 68, image: _img('bed'));
  add('bin', topicHouse, 68, image: _img('bin'));
  add('chair', topicHouse, 68, image: _img('chair'));
  add('desk', topicHouse, 68, image: _img('desk'));
  add('table', topicHouse, 68, image: _img('table'));
  add('door', topicHouse, 69, image: _img('door'));
  add('roof', topicHouse, 69, image: _img('roof'));
  add('wall', topicHouse, 69, image: _img('house_painting'));
  add('window', topicHouse, 69, image: _img('window'));

  return list;
}

final List<VocabWord> vocabulary = _buildVocabulary();

final Map<String, VocabWord> vocabularyById = {
  for (final w in vocabulary) w.id: w,
};

/// Ordered topic names (Book map order).
const List<String> vocabularyTopics = [
  topicAlphabet,
  topicColours,
  topicClassroom,
  topicToys,
  topicNumbers,
  topicAnimals,
  topicAdjectives,
  topicBody,
  topicFamily,
  topicHouse,
];

List<VocabWord> wordsInTopic(String topic) =>
    vocabulary.where((w) => w.topic == topic).toList();

String _c(String text) => '${wordId(topicColours)}__${wordId(text)}';
String _cl(String text) => '${wordId(topicClassroom)}__${wordId(text)}';
String _t(String text) => '${wordId(topicToys)}__${wordId(text)}';
String _n(int n) => '${wordId(topicNumbers)}__$n';
String _an(String text) => '${wordId(topicAnimals)}__${wordId(text)}';
String _ad(String text) => '${wordId(topicAdjectives)}__${wordId(text)}';
String _b(String text) => '${wordId(topicBody)}__${wordId(text)}';
String _f(String text) => '${wordId(topicFamily)}__${wordId(text)}';
String _h(String text) => '${wordId(topicHouse)}__${wordId(text)}';

// ---------------------------------------------------------------------------
// Alphabet
// ---------------------------------------------------------------------------

const _letterNames = {
  'a': 'eɪ', 'b': 'biː', 'c': 'siː', 'd': 'diː', 'e': 'iː', 'f': 'ɛf', //
  'g': 'dʒiː', 'h': 'eɪtʃ', 'i': 'aɪ', 'j': 'dʒeɪ', 'k': 'keɪ', 'l': 'ɛl',
  'm': 'ɛm', 'n': 'ɛn', 'o': 'əʊ', 'p': 'piː', 'q': 'kjuː', 'r': 'ɑː',
  's': 'ɛs', 't': 'tiː', 'u': 'juː', 'v': 'viː', 'w': 'dʌbəljuː', 'x': 'ɛks',
  'y': 'waɪ', 'z': 'zɛd',
};

const _letterSounds = {
  'a': 'æ', 'b': 'b', 'c': 'k', 'd': 'd', 'e': 'ɛ', 'f': 'f', 'g': 'g',
  'h': 'h', 'i': 'ɪ', 'j': 'dʒ', 'k': 'k', 'l': 'l', 'm': 'm', 'n': 'n',
  'o': 'ɒ', 'p': 'p', 'q': 'kw', 'r': 'r', 's': 's', 't': 't', 'u': 'ʌ',
  'v': 'v', 'w': 'w', 'x': 'ks', 'y': 'j', 'z': 'z',
};

final List<LetterInfo> alphabet = [
  for (final entry in _alphabetWords.entries)
    LetterInfo(
      lower: entry.key,
      words: entry.value.map(wordId).toList(),
      lessonPage: _letterLessonPage[entry.key]!,
      nameIpa: _letterNames[entry.key]!,
      soundIpa: _letterSounds[entry.key]!,
      soundHint: '${entry.key} as in ${entry.value.first}',
    ),
];

LetterInfo letterInfo(String letter) =>
    alphabet.firstWhere((l) => l.lower == letter.toLowerCase());

// ---------------------------------------------------------------------------
// Listening material from the Transcripts (pages 80-93)
// ---------------------------------------------------------------------------

Script _say(int track, String letter, List<String> words) => Script(
      title: 'Letter $letter',
      kind: ScriptKind.phrases,
      track: track,
      instruction: 'Listen and look at the board. Now listen and say them after me.',
      lines: [
        ScriptLine('', '$letter ${words.join(' ')}'),
        for (final w in words) ScriptLine('', w),
      ],
    );

const Script alphabetSong = Script(
  title: 'The Alphabet Song',
  kind: ScriptKind.song,
  track: 10,
  lines: [
    ScriptLine('', 'a, b, c, d'),
    ScriptLine('', 'e, f, g'),
    ScriptLine('', 'h, i, j, k'),
    ScriptLine('', 'l, m, n, o, p'),
    ScriptLine('', 'q, r, s'),
    ScriptLine('', 't, u, v'),
    ScriptLine('', 'w, x, y and z'),
  ],
);

// ---------------------------------------------------------------------------
// Units and lessons
// ---------------------------------------------------------------------------

Lesson _letterLesson(int unit, int number, String letter, int track,
    {List<String> extraWords = const [],
    List<String> language = const [],
    List<Script> scripts = const [],
    List<String> bookActivities = const []}) {
  final words = _alphabetWords[letter]!;
  return Lesson(
    id: 'u${unit}l$number',
    unitId: unit,
    number: number,
    title: 'Letter $letter',
    pages: [_letterLessonPage[letter]!],
    letters: [letter],
    words: [...words.map(wordId), ...extraWords],
    language: language,
    scripts: [_say(track, letter, words), ...scripts],
    bookActivities: ['Listen, look and say', ...bookActivities, 'Trace'],
  );
}

final List<Unit> units = [
  // ----------------------------------------------------------------- Unit 1
  Unit(
    id: 1,
    title: 'Hello',
    titleAr: 'مرحباً',
    colour: 0xFF2EAD5B,
    firstPage: 8,
    lastPage: 17,
    vocabularyTopics: [topicAlphabet, topicColours],
    lessons: [
      _letterLesson(1, 1, 'a', 2, language: ['Hello.'], scripts: [
        const Script(title: 'Hello', kind: ScriptKind.conversation, track: 3,
            instruction: 'Listen and look at the picture.', lines: [
          ScriptLine('Robbie', 'Hello.'),
          ScriptLine('Ahmed', 'Hello.'),
        ]),
      ]),
      _letterLesson(1, 2, 'b', 4, language: ['Goodbye.'], scripts: [
        const Script(title: 'Goodbye', kind: ScriptKind.conversation, track: 5,
            instruction: 'Listen and look at the picture.', lines: [
          ScriptLine('Robbie', 'Goodbye.'),
          ScriptLine('Ahmed', 'Goodbye.'),
        ]),
      ]),
      _letterLesson(1, 3, 'c', 6,
          language: ['Thank you.', 'Goodbye.'],
          bookActivities: ['Look and say', 'Listen and sing'],
          scripts: [
            const Script(title: 'Hello, Goodbye', kind: ScriptKind.song, track: 7,
                instruction: 'Listen and sing.', lines: [
              ScriptLine('', 'Hello, hello, hello'),
              ScriptLine('', 'How are you today?'),
              ScriptLine('', 'Hello, hello, hello'),
              ScriptLine('', 'Can you come and play?'),
              ScriptLine('', 'Goodbye, goodbye, goodbye'),
              ScriptLine('', 'Can you come back again?'),
              ScriptLine('', 'Goodbye, goodbye, goodbye'),
              ScriptLine('', 'And play another day.'),
            ]),
          ]),
      _letterLesson(1, 4, 'd', 8,
          language: ["What's your name?", "I'm Nada.", "I'm Ahmed."],
          bookActivities: ['Look and say', 'Listen and sing'],
          scripts: [
            const Script(title: "What's Your Name?", kind: ScriptKind.song, track: 9,
                instruction: 'Listen and sing.', lines: [
              ScriptLine('Robbie', "What's your name?"),
              ScriptLine('Nada', "I'm Nada. Yes, Nada."),
              ScriptLine('Robbie', "What's your name?"),
              ScriptLine('Nada', "I'm Nada."),
              ScriptLine('Nada', 'My name is Nada.'),
              ScriptLine('Robbie', "What's your name?"),
              ScriptLine('Ahmed', "I'm Ahmed. Yes, Ahmed."),
              ScriptLine('Robbie', "What's your name?"),
              ScriptLine('Ahmed', "I'm Ahmed."),
              ScriptLine('Ahmed', 'My name is Ahmed.'),
              ScriptLine('Nada & Ahmed', "What's your name?"),
              ScriptLine('Robbie', "I'm Robbie. Yes, Robbie."),
              ScriptLine('Nada & Ahmed', "What's your name?"),
              ScriptLine('Robbie', "I'm Robbie."),
              ScriptLine('Robbie', 'My name is Robbie.'),
            ]),
            alphabetSong,
          ]),
      _letterLesson(1, 5, 'e', 11,
          language: ["Hello. I'm Robbie.", "I'm Rosie.", "I'm Nada.", "I'm Ahmed."],
          scripts: [
            const Script(title: "Hello. I'm Robbie.", kind: ScriptKind.conversation,
                track: 12, instruction: 'Listen and look at the picture.', lines: [
              ScriptLine('Robbie', "Hello. I'm Robbie."),
              ScriptLine('Rosie', "I'm Rosie."),
              ScriptLine('Ahmed', "I'm Ahmed."),
              ScriptLine('Nada', "I'm Nada."),
            ]),
          ]),
      _letterLesson(1, 6, 'f', 13,
          language: ["Who's this?", 'Hani.', 'Iman.'],
          scripts: [
            const Script(title: "Who's this?", kind: ScriptKind.conversation,
                track: 14, instruction: 'Listen and look at the picture.', lines: [
              ScriptLine('Robbie', "Who's this?"),
              ScriptLine('Ahmed', 'Hani.'),
              ScriptLine('Robbie', "Who's this?"),
              ScriptLine('Nada', 'Iman.'),
              ScriptLine('Robbie', 'Hello, Hani.'),
              ScriptLine('Hani', 'Hello.'),
              ScriptLine('Robbie', 'Hello, Iman.'),
              ScriptLine('Iman', 'Hello.'),
            ]),
          ]),
      Lesson(
        id: 'u1l7', unitId: 1, number: 7, title: 'Colours', pages: [14],
        words: [_c('blue'), _c('red'), _c('yellow')],
        bookActivities: ['Listen, look and say', 'Find and point'],
        scripts: [
          const Script(title: 'Colours', kind: ScriptKind.phrases, track: 15,
              instruction: 'Listen and look at the colours.', lines: [
            ScriptLine('', 'red'), ScriptLine('', 'blue'), ScriptLine('', 'yellow'),
          ]),
        ],
      ),
      Lesson(
        id: 'u1l8', unitId: 1, number: 8, title: 'Colours', pages: [15],
        words: [_c('orange'), _c('green'), _c('pink')],
        language: ['Here you are.', 'Thank you.'],
        bookActivities: ['Listen, look and say', 'Look', 'Listen and sing', 'Match'],
        scripts: [
          const Script(title: 'Colours', kind: ScriptKind.phrases, track: 16,
              instruction: 'Listen and look at the colours.', lines: [
            ScriptLine('', 'orange'), ScriptLine('', 'green'), ScriptLine('', 'pink'),
          ]),
          const Script(title: 'Here you are', kind: ScriptKind.conversation, lines: [
            ScriptLine('Robbie', 'Here you are.'),
            ScriptLine('Nada', 'Thank you.'),
          ]),
          const Script(title: 'The Colour Song', kind: ScriptKind.song, track: 17,
              instruction: 'Listen and sing.', lines: [
            ScriptLine('', 'Red, green, orange.'),
            ScriptLine('', 'Pink, yellow, blue.'),
            ScriptLine('', '6 lovely pencils.'),
            ScriptLine('', 'All for you.'),
            ScriptLine('', 'Blue, red, yellow.'),
            ScriptLine('', 'Pink, orange, green.'),
            ScriptLine('', '6 pretty flowers.'),
            ScriptLine('', 'All for me.'),
          ]),
        ],
      ),
      const Lesson(
        id: 'u1p', unitId: 1, number: 0, title: 'P for Project: Draw and colour a ball',
        pages: [16, 17], kind: LessonKind.project,
        language: ['Draw and colour a ball.', 'Draw', 'Colour', 'Cut', 'Stick'],
      ),
    ],
  ),
  // ----------------------------------------------------------------- Unit 2
  Unit(
    id: 2,
    title: 'My school',
    titleAr: 'مدرستي',
    colour: 0xFFF29D0A,
    firstPage: 18,
    lastPage: 27,
    vocabularyTopics: [topicAlphabet, topicClassroom],
    lessons: [
      _letterLesson(2, 1, 'g', 18,
          language: ['Hands up!', 'Hands down!', 'Stand up!', 'Sit down!', 'Turn round!'],
          bookActivities: ['Listen, look and say', 'Listen and sing'],
          scripts: [
            const Script(title: 'Hands up!', kind: ScriptKind.phrases, track: 19,
                instruction: 'Listen and look at the picture.', lines: [
              ScriptLine('', 'Hands up!'),
              ScriptLine('', 'Hands down!'),
              ScriptLine('', 'Stand up!'),
              ScriptLine('', 'Sit down!'),
              ScriptLine('', 'Turn round!'),
            ]),
            alphabetSong,
          ]),
      _letterLesson(2, 2, 'h', 20,
          extraWords: [_cl('book'), _cl('ruler'), _cl('pencil case'), _cl('rubber'),
            _cl('pen'), _cl('pencil'), _cl('bag')],
          language: ['A ruler.'],
          bookActivities: ['Look', 'Listen and point'],
          scripts: [
            const Script(title: 'In the classroom', kind: ScriptKind.phrases, track: 21,
                instruction: 'Listen and point to the picture.', lines: [
              ScriptLine('', 'a ruler'),
              ScriptLine('', 'a pencil case'),
              ScriptLine('', 'a rubber'),
              ScriptLine('', 'a pencil'),
              ScriptLine('', 'a bag'),
              ScriptLine('', 'a book'),
              ScriptLine('', 'a pen'),
            ]),
          ]),
      _letterLesson(2, 3, 'i', 22,
          bookActivities: ['Listen, say and find'],
          scripts: [
            const Script(title: 'Listen, look and point', kind: ScriptKind.phrases,
                track: 23, instruction: 'Listen, look and point.', lines: [
              ScriptLine('', 'a red pen'),
              ScriptLine('', 'a blue pencil'),
              ScriptLine('', 'a pink bag'),
              ScriptLine('', 'a green pencil case'),
              ScriptLine('', 'a yellow bag'),
              ScriptLine('', 'a green pencil'),
              ScriptLine('', 'a yellow rubber'),
              ScriptLine('', 'a pink pencil case'),
              ScriptLine('', 'a yellow ruler'),
              ScriptLine('', 'a blue ruler'),
              ScriptLine('', 'an orange pencil case'),
              ScriptLine('', 'a green pen'),
              ScriptLine('', 'an orange pencil'),
              ScriptLine('', 'a blue pen'),
              ScriptLine('', 'a red book'),
            ]),
          ]),
      _letterLesson(2, 4, 'j', 24,
          extraWords: [_cl('book'), _cl('bin'), _cl('desk'), _cl('chair'), _cl('CD')],
          language: ['Good morning, Teacher.', 'Sit down here, Robbie.', 'Thank you.'],
          bookActivities: ['Listen, look and say'],
          scripts: [
            const Script(title: 'In the classroom', kind: ScriptKind.phrases, track: 25,
                instruction: 'Listen and look at the pictures.', lines: [
              ScriptLine('', 'a book'),
              ScriptLine('', 'a bin'),
              ScriptLine('', 'a desk'),
              ScriptLine('', 'a chair'),
              ScriptLine('', 'a CD'),
            ]),
            const Script(title: 'Good morning', kind: ScriptKind.conversation, track: 26,
                instruction: 'Listen and look at the picture.', lines: [
              ScriptLine('Robbie', 'Good morning, Teacher.'),
              ScriptLine('Teacher', 'Good morning, Robbie.'),
              ScriptLine('Robbie', 'Hello.'),
              ScriptLine('Children', 'Hello, Robbie.'),
              ScriptLine('Hani', 'Sit down here, Robbie.'),
              ScriptLine('Robbie', 'Thank you.'),
            ]),
          ]),
      _letterLesson(2, 5, 'k', 27,
          language: ["What's this?", 'Is it a pen?', 'No.', 'Is it a pencil?', 'Yes.'],
          scripts: [
            const Script(title: "What's this?", kind: ScriptKind.conversation, track: 28,
                instruction: 'Look and listen.', lines: [
              ScriptLine('Teacher', "What's this?"),
              ScriptLine('Boy', 'Is it a pen?'),
              ScriptLine('Teacher', 'No.'),
              ScriptLine('Girl', 'Is it a pencil?'),
              ScriptLine('Teacher', 'Yes.'),
              ScriptLine('Girl', 'Is it a blue pencil?'),
              ScriptLine('Teacher', 'No.'),
              ScriptLine('Boy', 'Is it a red pencil?'),
              ScriptLine('Teacher', 'Yes!'),
            ]),
          ]),
      _letterLesson(2, 6, 'l', 29,
          language: ['Open.', 'Draw.', 'Close.'],
          bookActivities: ['Look', 'Listen and look', 'Do', 'Listen and sing'],
          scripts: [
            const Script(title: 'Open, draw, close', kind: ScriptKind.phrases, track: 30,
                instruction: 'Listen and look at the pictures.', lines: [
              ScriptLine('Teacher', 'Open your books, please.'),
              ScriptLine('Teacher', 'Draw a red pencil, please.'),
              ScriptLine('Teacher', 'Close your books, please.'),
              ScriptLine('Teacher', 'Draw a blue pen.'),
            ]),
            alphabetSong,
          ]),
      const Lesson(
        id: 'u2l7', unitId: 2, number: 7, title: 'Look and find', pages: [24],
        bookActivities: ['Look', 'Find and point', 'Listen and look'],
        scripts: [
          Script(title: 'Listen and tick', kind: ScriptKind.phrases, track: 31,
              instruction: 'Listen and tick.', lines: [
            ScriptLine('', 'a key'),
            ScriptLine('', 'a horse'),
            ScriptLine('', 'a ball'),
            ScriptLine('', 'a duck'),
          ]),
        ],
      ),
      const Lesson(
        id: 'u2l8', unitId: 2, number: 8, title: "Who's in the bus?", pages: [25],
        language: ["Who's in the bus?"],
        bookActivities: ['Look and say', 'Find and point'],
      ),
      const Lesson(
        id: 'u2s', unitId: 2, number: 0, title: 'Story: What is it?', pages: [26, 27],
        kind: LessonKind.story,
        language: ['Hello, children.'],
        scripts: [
          Script(title: 'What is it?', kind: ScriptKind.story, track: 32,
              instruction: 'Listen to a story and look at the pictures.', lines: [
            ScriptLine('', 'One day, Robbie and Rosie go to school with their friends, Ahmed and Nada.'),
            ScriptLine('', "The teacher says, 'Hello, children. Hello, Robbie and Rosie. Sit down, please.'"),
            ScriptLine('', "'Take out your coloured pencils, children. I want you to draw pictures,' says the teacher."),
            ScriptLine('', 'The children and Robbie and Rosie take out their coloured pencils.'),
            ScriptLine('', 'Robbie and Rosie, and the children, start to draw. What are they drawing?'),
            ScriptLine('', "'What's this, Nada?' says the teacher."),
            ScriptLine('', "'It's a cat,' says Nada."),
            ScriptLine('', "'It's a nice picture, Nada,' says the teacher. 'And what's this, Ahmed?'"),
            ScriptLine('', "'Teacher! It's a fish!' says Ahmed."),
            ScriptLine('', "'It's a lovely fish,' says the teacher. 'Very good.'"),
            ScriptLine('', "Look at Robbie's picture!"),
            ScriptLine('', "'It's a flower, teacher,' says Robbie."),
            ScriptLine('', "'It's a lovely flower, Robbie,' says the teacher."),
            ScriptLine('', "'Look at my picture, teacher!' says Rosie."),
            ScriptLine('', "'Is it a robot?' says the teacher."),
            ScriptLine('', "'Yes!' says Rosie. 'It's Robbie!'"),
            ScriptLine('', 'Rosie gives the picture to Robbie.'),
            ScriptLine('', "'Here you are, Robbie,' says Rosie. 'It's for you!'"),
            ScriptLine('', "'Thank you, Rosie,' says Robbie."),
          ]),
          Script(title: "Say 'Thank you'", kind: ScriptKind.conversation, track: 33,
              instruction: 'Listen and learn.', lines: [
            ScriptLine('Girl', 'Here you are. Flowers!'),
            ScriptLine('Mum', 'Thank you.'),
            ScriptLine('Boy 1', 'Here you are. A yellow car.'),
            ScriptLine('Boy 2', 'Thank you!'),
          ]),
        ],
      ),
    ],
  ),
  // ----------------------------------------------------------------- Unit 3
  Unit(
    id: 3,
    title: 'My toys',
    titleAr: 'ألعابي',
    colour: 0xFFE8B10E,
    firstPage: 28,
    lastPage: 37,
    vocabularyTopics: [topicAlphabet, topicToys, topicNumbers],
    lessons: [
      _letterLesson(3, 1, 'm', 34,
          extraWords: [_t('bike'), _t('doll'), _t('skates'), _t('yo-yo'), _t('balloon'), _t('toy')],
          bookActivities: ['Look', 'Find and point']),
      _letterLesson(3, 2, 'n', 35,
          extraWords: [_t('net')],
          bookActivities: ['Listen, say and find'],
          scripts: [
            const Script(title: 'Listen, look and point', kind: ScriptKind.phrases,
                track: 36, instruction: 'Listen, look and point.', lines: [
              ScriptLine('', 'a red ball'),
              ScriptLine('', 'a blue ball'),
              ScriptLine('', 'a red car'),
              ScriptLine('', 'a blue car'),
              ScriptLine('', 'a yellow kite'),
              ScriptLine('', 'an orange kite'),
              ScriptLine('', 'a pink yo-yo'),
              ScriptLine('', 'a red yo-yo'),
              ScriptLine('', 'a green and yellow bus'),
              ScriptLine('', 'red skates'),
              ScriptLine('', 'a yellow and red puzzle'),
            ]),
          ]),
      _letterLesson(3, 3, 'o', 37,
          extraWords: [_n(1), _n(2), _n(3), _n(4), _n(5), _t('balloon')],
          bookActivities: ['Listen and point', 'Count', 'Listen and sing'],
          scripts: [
            const Script(title: 'Numbers 1 to 5', kind: ScriptKind.phrases, track: 38,
                instruction: 'Listen and point.', lines: [
              ScriptLine('', '1 balloon'),
              ScriptLine('', '2 balloons'),
              ScriptLine('', '3 balloons'),
              ScriptLine('', '4 balloons'),
              ScriptLine('', '5 balloons'),
            ]),
            const Script(title: '5 Balloons', kind: ScriptKind.song, track: 39,
                instruction: 'Listen and sing.', lines: [
              ScriptLine('', '5 balloons in my hand.'),
              ScriptLine('', "1 balloon went 'Bang!'"),
              ScriptLine('', '4 balloons in my hand.'),
              ScriptLine('', "1 balloon went 'Bang!'"),
              ScriptLine('', '3 balloons in my hand.'),
              ScriptLine('', "1 balloon went 'Bang!'"),
              ScriptLine('', '2 balloons in my hand.'),
              ScriptLine('', "1 balloon went 'Bang!'"),
              ScriptLine('', '1 balloon in my hand.'),
              ScriptLine('', "1 balloon went 'Bang!'"),
            ]),
          ]),
      _letterLesson(3, 4, 'p', 40,
          extraWords: [_n(6), _n(7), _n(8), _n(9), _n(10)],
          language: ['How many toys?'],
          bookActivities: ['Listen and point', 'Count'],
          scripts: [
            const Script(title: 'Numbers 6 to 10', kind: ScriptKind.phrases, track: 41,
                instruction: 'Listen and point.', lines: [
              ScriptLine('', '6'), ScriptLine('', '7'), ScriptLine('', '8'),
              ScriptLine('', '9'), ScriptLine('', '10'),
            ]),
            const Script(title: 'How many toys?', kind: ScriptKind.conversation, lines: [
              ScriptLine('Teacher', 'How many toys?'),
            ]),
          ]),
      _letterLesson(3, 5, 'q', 42,
          language: ['What is it?', "It's a kite."],
          scripts: [
            const Script(title: 'What is it?', kind: ScriptKind.conversation, track: 43,
                instruction: 'Listen and look at the picture.', lines: [
              ScriptLine('Robbie', 'What is it?'),
              ScriptLine('Ahmed', "It's a kite."),
              ScriptLine('Robbie', 'What is it?'),
              ScriptLine('Boy', "It's a bike."),
            ]),
          ]),
      _letterLesson(3, 6, 'r', 44,
          language: ['How old are you?', "I'm 6.", "I'm 4."],
          extraWords: [_t('present')],
          bookActivities: ['Listen and look', 'Listen and sing'],
          scripts: [
            const Script(title: 'Happy birthday, Hasan!', kind: ScriptKind.conversation,
                track: 45, instruction: 'Listen and look at the picture.', lines: [
              ScriptLine('Robbie', 'Hello.'),
              ScriptLine('Hasan', 'Hello, Robbie.'),
              ScriptLine('Robbie', 'Happy birthday, Hasan! How old are you?'),
              ScriptLine('Hasan', "I'm 4."),
            ]),
            const Script(title: 'Happy Birthday', kind: ScriptKind.song, track: 46,
                instruction: 'Listen and sing.', lines: [
              ScriptLine('', 'Happy birthday to you!'),
              ScriptLine('', 'Happy birthday to you!'),
              ScriptLine('', 'Happy birthday, dear Hasan,'),
              ScriptLine('', 'Happy birthday to you!'),
            ]),
          ]),
      _letterLesson(3, 7, 's', 47,
          language: ["I'm 6."],
          bookActivities: ['Listen and point'],
          scripts: [
            const Script(title: 'How old?', kind: ScriptKind.conversation, track: 48,
                instruction: 'Listen and point.', lines: [
              ScriptLine('Ahmed', "I'm 6."),
              ScriptLine('Iman', "I'm 5."),
              ScriptLine('Hani', "I'm 8."),
              ScriptLine('Fatima', "I'm 4."),
              ScriptLine('Faisal', "I'm 3."),
              ScriptLine('Layla', "I'm 7."),
            ]),
          ]),
      _letterLesson(3, 8, 't', 49,
          bookActivities: ['Listen and look', 'Look and say'],
          scripts: [
            const Script(title: 'I know!', kind: ScriptKind.conversation, track: 50,
                instruction: 'Listen and say.', lines: [
              ScriptLine('Child 1', '2b?'),
              ScriptLine('Child 2', "I know! It's a taxi."),
              ScriptLine('Child 1', '4a?'),
              ScriptLine('Child 2', "I know! It's a tomato."),
              ScriptLine('Child 1', '3d?'),
              ScriptLine('Child 2', "I know! It's a duck."),
              ScriptLine('Child 1', 'Your turn.'),
            ]),
          ]),
      const Lesson(
        id: 'u3p', unitId: 3, number: 0, title: 'P for Project: Make a numbers poster',
        pages: [36, 37], kind: LessonKind.project,
        language: ['Make a numbers poster.', 'Draw', 'Colour', 'Stick', 'Point and say'],
      ),
    ],
  ),
  // ----------------------------------------------------------------- Unit 4
  Unit(
    id: 4,
    title: 'Revision',
    titleAr: 'مراجعة',
    colour: 0xFFFF7A3D,
    firstPage: 38,
    lastPage: 43,
    vocabularyTopics: [topicAlphabet],
    lessons: [
      _letterLesson(4, 1, 'u', 52,
          language: ['Is it a bus?', 'Yes.'],
          bookActivities: ['Look and say']),
      _letterLesson(4, 2, 'v', 53,
          language: ['How many vans can you see?'],
          bookActivities: ['Count']),
      _letterLesson(4, 3, 'w', 54,
          language: ['What can you see?'],
          bookActivities: ['Look and say']),
      Lesson(
        id: 'u4l4', unitId: 4, number: 4, title: 'Letters x, y, z', pages: [41],
        letters: ['x', 'y', 'z'],
        words: [wordId('x-ray'), wordId('yo-yo'), wordId('zebra')],
        bookActivities: ['Listen, look and say', 'Listen and look', 'Trace'],
        scripts: [
          _say(55, 'x', ['x-ray']),
          _say(55, 'y', ['yo-yo']),
          _say(55, 'z', ['zebra']),
          const Script(title: 'Listen and tick', kind: ScriptKind.phrases, track: 56,
              instruction: 'Listen and tick the right picture.', lines: [
            ScriptLine('', 'a lemon'),
            ScriptLine('', 'a plane'),
            ScriptLine('', 'a bag'),
            ScriptLine('', 'a dog'),
          ]),
        ],
      ),
      const Lesson(
        id: 'u4s', unitId: 4, number: 0, title: 'Story: Happy birthday!', pages: [42, 43],
        kind: LessonKind.story,
        language: ['Happy birthday, Nada!', 'How old are you?', "I'm 6.",
          'Is it a robot?', "It's a doll!", 'What can you see?', 'Thank you!'],
        scripts: [
          Script(title: 'Happy birthday!', kind: ScriptKind.story, track: 57,
              instruction: 'Listen to a story and look at the pictures.', lines: [
            ScriptLine('', "It is Nada's birthday. She is in bed. She has just woken up."),
            ScriptLine('', 'There is a knock on the door. It is Ahmed.'),
            ScriptLine('', "He says, 'Happy birthday, Nada.'"),
            ScriptLine('', "Mum and Dad say, 'Happy birthday, Nada!'"),
            ScriptLine('', "Nada is very happy. It's her birthday."),
            ScriptLine('', 'Mum, Dad, Ahmed and Nada go to the toy shop to buy birthday presents for Nada.'),
            ScriptLine('', "The shop keeper says, 'How old are you?'"),
            ScriptLine('', "Nada says, 'I'm 6.'"),
            ScriptLine('', 'The shop keeper gives Nada a present.'),
            ScriptLine('', "'Is it a robot?' says Ahmed."),
            ScriptLine('', "Nada opens the present. 'It's a doll!' she says."),
            ScriptLine('', 'Nada is very happy.'),
            ScriptLine('', 'Mum and Dad, Ahmed and Nada go home. Nada has her new doll.'),
            ScriptLine('', 'Mum has a present for Nada, too, in her bag. Nada doesn\'t know what it is.'),
            ScriptLine('', 'Mum and Dad have a surprise for Nada. They are having a birthday party for her.'),
            ScriptLine('', 'At home, Mum and Dad get ready for the party. They blow up lots of balloons.'),
            ScriptLine('', 'Mum has made a cake with pink icing and six candles.'),
            ScriptLine('', "Later, Mum says, 'Nada, come here, please.' Mum opens the living room door."),
            ScriptLine('', "Mum says, 'What can you see?' But Nada can't see anything. It is dark."),
            ScriptLine('', 'Then Mum turns on the light. Nada sees the balloons and the cake, and she sees her friends!'),
            ScriptLine('', "'Surprise!' say Mum and Dad."),
            ScriptLine('', "Nada blows out the candles on her cake. Her friends sing 'Happy birthday'."),
            ScriptLine('', 'Nada opens her presents. She has a yo-yo and a bear, and a book.'),
            ScriptLine('', 'Nada opens her present from Mum and Dad. It is a tablet!'),
            ScriptLine('', "Nada says, 'Thank you!'"),
            ScriptLine('', 'Nada is very happy with her presents.'),
          ]),
          Script(title: 'Share your things', kind: ScriptKind.conversation, track: 58,
              instruction: 'Listen and learn.', lines: [
            ScriptLine('Boy', 'What is it?'),
            ScriptLine('Girl', "It's a robot. It's my robot."),
            ScriptLine('Boy', 'Oh.'),
            ScriptLine('Girl', "Let's play with the robot!"),
            ScriptLine('Girl 1', 'Look! Balloons!'),
            ScriptLine('Girl 2', 'Wow! 4 balloons.'),
            ScriptLine('Girl 1', 'Here you are. 2 balloons for you and 2 balloons for me.'),
          ]),
        ],
      ),
    ],
  ),
  // ----------------------------------------------------------------- Unit 5
  Unit(
    id: 5,
    title: 'At the zoo',
    titleAr: 'في حديقة الحيوانات',
    colour: 0xFFE5484D,
    firstPage: 44,
    lastPage: 53,
    vocabularyTopics: [topicAnimals, topicColours, topicAdjectives],
    lessons: [
      Lesson(
        id: 'u5l1', unitId: 5, number: 1, title: 'Animals', pages: [44],
        words: [_an('camel'), _an('tiger'), _an('penguin'), _an('lion'), _an('elephant'),
          _an('duck'), _an('monkey'), _an('rabbit'), _an('goat')],
        bookActivities: ['Listen, look and say', 'Look and say', 'Listen and sing'],
        scripts: [
          const Script(title: 'Animals', kind: ScriptKind.phrases, track: 59,
              instruction: 'Listen and look at the picture.', lines: [
            ScriptLine('', 'camel'), ScriptLine('', 'tiger'), ScriptLine('', 'penguin'),
            ScriptLine('', 'lion'), ScriptLine('', 'elephant'), ScriptLine('', 'duck'),
            ScriptLine('', 'monkey'), ScriptLine('', 'rabbit'), ScriptLine('', 'goat'),
          ]),
          comeToTheZoo,
        ],
      ),
      Lesson(
        id: 'u5l2', unitId: 5, number: 2, title: 'Colours', pages: [45],
        words: [_c('black'), _c('white'), _c('brown'), _c('grey')],
        bookActivities: ['Listen, look and say', 'Look and say', 'Listen and sing'],
        scripts: [
          const Script(title: 'Colours', kind: ScriptKind.phrases, track: 61,
              instruction: 'Listen and point to the colours.', lines: [
            ScriptLine('', 'black'), ScriptLine('', 'white'),
            ScriptLine('', 'brown'), ScriptLine('', 'grey'),
          ]),
          comeToTheZoo,
        ],
      ),
      Lesson(
        id: 'u5l3', unitId: 5, number: 3, title: 'Big and little', pages: [46],
        words: [_ad('funny'), _ad('little'), _ad('big'), _ad('long')],
        bookActivities: ['Listen, look and say', 'Look and say'],
        scripts: [
          const Script(title: 'Big, little, long, funny', kind: ScriptKind.phrases,
              track: 62, instruction: 'Listen and look at the pictures.', lines: [
            ScriptLine('', 'big'), ScriptLine('', 'little'),
            ScriptLine('', 'long'), ScriptLine('', 'funny'),
          ]),
          const Script(title: 'At the zoo', kind: ScriptKind.phrases, track: 63,
              instruction: 'Listen and look at the picture.', lines: [
            ScriptLine('', '2 funny monkeys.'),
            ScriptLine('', '6 little ants.'),
            ScriptLine('', '1 big camel.'),
            ScriptLine('', '1 long snake.'),
          ]),
        ],
      ),
      const Lesson(
        id: 'u5l4', unitId: 5, number: 4, title: 'How many?', pages: [47],
        language: ['How many red fish?'],
        bookActivities: ['Listen and point', 'Count'],
        scripts: [
          Script(title: 'How many?', kind: ScriptKind.phrases, track: 64,
              instruction: 'Listen and point.', lines: [
            ScriptLine('', '1 rabbit.'),
            ScriptLine('', '1 green and yellow snake.'),
            ScriptLine('', '5 grey rabbits.'),
            ScriptLine('', '2 monkeys.'),
            ScriptLine('', '2 red fish.'),
            ScriptLine('', '4 blue fish.'),
            ScriptLine('', '2 penguins.'),
            ScriptLine('', '3 monkeys.'),
            ScriptLine('', 'Robbie the robot.'),
            ScriptLine('', '1 camel.'),
            ScriptLine('', '3 lions.'),
            ScriptLine('', '1 tiger.'),
            ScriptLine('', '1 grey cat.'),
            ScriptLine('', '4 green and yellow snakes.'),
            ScriptLine('', '6 orange fish.'),
            ScriptLine('', '1 goat.'),
            ScriptLine('', '1 horse.'),
            ScriptLine('', '3 goats.'),
            ScriptLine('', '4 pink and green fish.'),
            ScriptLine('', '2 tigers.'),
            ScriptLine('', '3 camels.'),
            ScriptLine('', '2 elephants.'),
            ScriptLine('', '2 brown cats.'),
            ScriptLine('', '1 lion.'),
          ]),
        ],
      ),
      Lesson(
        id: 'u5l5', unitId: 5, number: 5, title: 'Look and find', pages: [48],
        words: [wordId('bus'), wordId('cat'), wordId('ant'), wordId('dog')],
        bookActivities: ['Look', 'Find and point'],
      ),
      Lesson(
        id: 'u5l6', unitId: 5, number: 6, title: "Where's the tiger?", pages: [49],
        words: [wordId('horse'), wordId('goat'), wordId('egg'), wordId('fish')],
        language: ["Where's the blue tiger?", 'In the bag.'],
        bookActivities: ['Look and say', 'Listen and look'],
        scripts: [
          const Script(title: "Where's the tiger?", kind: ScriptKind.conversation,
              track: 65, instruction: 'Listen and look at the pictures.', lines: [
            ScriptLine('Male', "Where's the red and black tiger?"),
            ScriptLine('Female', 'In the net.'),
            ScriptLine('Male', "Where's the blue and black tiger?"),
            ScriptLine('Female', 'In the bag.'),
            ScriptLine('Male', "Where's the pink and black tiger?"),
            ScriptLine('Female', 'In the bin.'),
            ScriptLine('Male', "Where's the yellow and black tiger?"),
            ScriptLine('Female', 'In the pencil case.'),
            ScriptLine('Male', "Where's the brown and black tiger?"),
            ScriptLine('Female', 'In the taxi.'),
            ScriptLine('Male', "Where's the grey and black tiger?"),
            ScriptLine('Female', 'In the house.'),
          ]),
        ],
      ),
      Lesson(
        id: 'u5l7', unitId: 5, number: 7, title: 'Words and pictures', pages: [50],
        words: [wordId('ant'), wordId('bus'), wordId('cat'), wordId('dog'),
          wordId('egg'), wordId('fish'), wordId('goat'), wordId('horse')],
        bookActivities: ['Trace', 'Match'],
      ),
      const Lesson(
        id: 'u5l8', unitId: 5, number: 8, title: 'There is ...', pages: [51],
        language: ['There is a dog in a bus.', 'There is a green fish.', 'There are 3 cats.',
          'There is a goat in a bus.', 'There is an ant on a bag.',
          'There is a dog and a cat on a horse.'],
        bookActivities: ['Read', 'Match'],
      ),
      const Lesson(
        id: 'u5p', unitId: 5, number: 0, title: 'P for Project: Make an animal mask',
        pages: [52, 53], kind: LessonKind.project,
        language: ['Make an animal mask.', 'Draw', 'Colour', 'Make', 'Play'],
      ),
    ],
  ),
  // ----------------------------------------------------------------- Unit 6
  Unit(
    id: 6,
    title: 'My body',
    titleAr: 'جسمي',
    colour: 0xFFD6479B,
    firstPage: 54,
    lastPage: 63,
    vocabularyTopics: [topicBody],
    lessons: [
      const Lesson(
        id: 'u6l1', unitId: 6, number: 1, title: 'My ears!', pages: [54],
        language: ['My ears!'],
        bookActivities: ['Look', 'Do'],
        scripts: [
          Script(title: 'Touch your eyes', kind: ScriptKind.phrases, track: 66,
              instruction: 'Listen and do these things.', lines: [
            ScriptLine('', 'Touch your eyes.'),
            ScriptLine('', 'Touch your hair.'),
            ScriptLine('', 'Touch your nose.'),
            ScriptLine('', 'Touch your mouth.'),
            ScriptLine('', 'Touch your ears.'),
            ScriptLine('', 'Stop!'),
          ]),
        ],
      ),
      const Lesson(
        id: 'u6l2', unitId: 6, number: 2, title: 'My nose. My eyes.', pages: [55],
        language: ['My nose.', 'My eyes.'],
        bookActivities: ['Look and say', 'Listen and point'],
        scripts: [
          Script(title: 'My eyes', kind: ScriptKind.conversation, track: 67,
              instruction: 'Listen and point.', lines: [
            ScriptLine('Nada', 'My eyes are brown. My hair is black.'),
            ScriptLine('Hani', 'My eyes are blue. My hair is brown.'),
          ]),
          Script(title: 'The clowns', kind: ScriptKind.phrases, track: 68,
              instruction: 'Listen and point.', lines: [
            ScriptLine('', 'I have black eyes.'),
            ScriptLine('', 'I have orange hair, and a green nose!'),
          ]),
        ],
      ),
      Lesson(
        id: 'u6l3', unitId: 6, number: 3, title: 'Touch your head', pages: [56],
        words: [_b('head'), _b('toes'), _b('ears'), _b('nose'), _b('hands'), _b('eyes')],
        bookActivities: ['Listen and sing', 'Do'],
        scripts: [
          const Script(title: 'Touch Your Head', kind: ScriptKind.song, track: 69,
              instruction: 'Listen and sing.', lines: [
            ScriptLine('', 'Touch your head.'),
            ScriptLine('', 'Touch your toes.'),
            ScriptLine('', 'Touch your ears.'),
            ScriptLine('', 'Touch your nose.'),
            ScriptLine('', 'Hands up.'),
            ScriptLine('', 'Hands down.'),
            ScriptLine('', 'Stand up.'),
            ScriptLine('', 'Sit down.'),
            ScriptLine('', 'Touch your head.'),
            ScriptLine('', 'Touch your toes.'),
            ScriptLine('', 'Touch your ears.'),
            ScriptLine('', 'Touch your nose.'),
            ScriptLine('', 'Hands up.'),
            ScriptLine('', 'Hands down.'),
            ScriptLine('', 'Close your eyes.'),
            ScriptLine('', 'And turn round.'),
          ]),
          alphabetSong,
        ],
      ),
      Lesson(
        id: 'u6l4', unitId: 6, number: 4, title: 'My monster', pages: [57],
        words: [_b('head'), _b('body'), _b('arm'), _b('hands'), _b('leg'), _b('feet'),
          _b('toes'), wordId('ink'), wordId('juice'), wordId('kite'), wordId('lemon')],
        bookActivities: ['Listen, look and say', 'Look', 'Match'],
        scripts: [
          const Script(title: 'My body', kind: ScriptKind.phrases, track: 70,
              instruction: 'Listen and look at the pictures.', lines: [
            ScriptLine('', 'head'), ScriptLine('', 'body'), ScriptLine('', 'arm'),
            ScriptLine('', 'hand'), ScriptLine('', 'leg'), ScriptLine('', 'feet'),
            ScriptLine('', 'toes'),
          ]),
        ],
      ),
      const Lesson(
        id: 'u6l5', unitId: 6, number: 5, title: 'Monsters', pages: [58],
        language: ['I have three red ears.'],
        bookActivities: ['Look', 'Listen and match'],
        scripts: [
          Script(title: 'My monster', kind: ScriptKind.conversation, track: 71,
              instruction: 'Listen and match.', lines: [
            ScriptLine('Nada', "Hello. I'm Nada. My monster has 2 green hands and she has 4 yellow eyes."),
            ScriptLine('Ahmed', "Hello. I'm Ahmed. My monster has a yellow body. He has 3 black legs."),
            ScriptLine('Iman', "Hello. My name's Iman. I have a monster. My monster has 3 blue legs. He has a pink nose."),
            ScriptLine('Hani', "My name's Hani. I have a monster. She has 2 orange ears and she has white hair."),
          ]),
          Script(title: 'Our monsters', kind: ScriptKind.conversation, track: 72,
              instruction: 'Listen and match.', lines: [
            ScriptLine('Nada', 'My monster has 3 blue legs. She has a pink nose. She has 3 red ears. She has a blue body. She has 4 yellow eyes. She has 2 green arms. She has white hair.'),
            ScriptLine('Ahmed', 'My monster has 3 black legs. He has 2 pink noses. He has 2 orange ears. He has 3 green arms and hands. He has a yellow body and 4 white eyes. He has no hair.'),
            ScriptLine('Iman', "I'm Iman. My monster has a blue body. He has 3 green arms and 3 green hands. He has 5 yellow eyes. He has 3 red ears and he has pink hair."),
            ScriptLine('Hani', "My name's Hani. My monster has a blue body. She has 2 green arms and 2 green hands. She has white hair. She has 3 black legs. And she has 2 orange ears."),
          ]),
        ],
      ),
      Lesson(
        id: 'u6l6', unitId: 6, number: 6, title: 'I am a monster', pages: [59],
        words: [wordId('moon'), wordId('net'), wordId('orange'), wordId('pizza')],
        language: ['I am a monster.', 'I have a blue body.', 'I have 2 green heads.',
          'I have 3 red arms.', 'I have a yellow leg.'],
        bookActivities: ['Look and say', 'Read', 'Do'],
        scripts: [
          const Script(title: 'I am a monster', kind: ScriptKind.conversation, track: 73,
              instruction: 'Listen and look at the picture.', lines: [
            ScriptLine('Robbie', 'I am a monster. I have a blue body and 2 green heads. I have 3 red arms and a yellow leg.'),
          ]),
        ],
      ),
      const Lesson(
        id: 'u6l7', unitId: 6, number: 7, title: 'I wash my ...', pages: [60],
        language: ['I wash my face.', 'I wash my hands.', 'I wash my feet.', 'I wash my hair.'],
        bookActivities: ['Read'],
      ),
      const Lesson(
        id: 'u6l8', unitId: 6, number: 8, title: 'What is it?', pages: [61],
        language: ['What is it?', 'A blue body and pink feet.', "It's a monkey!",
          'Now me. What is it?'],
        bookActivities: ['Look and say', 'Do'],
      ),
      const Lesson(
        id: 'u6s', unitId: 6, number: 0, title: 'Story: At the Zoo', pages: [62, 63],
        kind: LessonKind.story,
        language: ['The lion is big!', 'The rabbits are little.', 'There are 3 goats.',
          'Where is the penguin?', 'An ear!', "It's an elephant!", 'The monkeys are funny!',
          'Goodbye.'],
        scripts: [
          Script(title: 'At the Zoo', kind: ScriptKind.story, track: 74,
              instruction: 'Listen to a story and look at the pictures.', lines: [
            ScriptLine('', 'Ahmed, Nada and Robbie are at the zoo. They are happy. They love animals.'),
            ScriptLine('', 'They buy tickets from the zoo keeper. The children and Robbie go into the zoo.'),
            ScriptLine('', "They see the lion. Nada is a bit afraid. 'The lion is big!' she says."),
            ScriptLine('', 'Ahmed and Robbie are a bit afraid, too.'),
            ScriptLine('', "'Let's go and see a little animal,' says Ahmed."),
            ScriptLine('', 'The children and Robbie find the rabbits in the zoo.'),
            ScriptLine('', "Ahmed says, 'The rabbits are little.'"),
            ScriptLine('', "'I like little animals!' says Nada."),
            ScriptLine('', 'The children are happy now. They look for more animals in the zoo.'),
            ScriptLine('', "They see the goats. Nada points to the goats. 'There are 3 goats,' she says."),
            ScriptLine('', "The goats don't look at the children. They are eating grass."),
            ScriptLine('', 'The children look for the penguin. They find the pool.'),
            ScriptLine('', "'Where is the penguin?' says Ahmed."),
            ScriptLine('', "They don't see the penguin. The penguin is under the water! It is hiding!"),
            ScriptLine('', 'The children and Robbie go to the elephant house.'),
            ScriptLine('', "Nada sees something. 'An ear!' she says."),
            ScriptLine('', "'It's an elephant!' says Ahmed. The elephant is hiding!"),
            ScriptLine('', 'The children look at the monkeys.'),
            ScriptLine('', "'The monkeys are funny!' says Nada. The children like the monkeys."),
            ScriptLine('', 'It is time for the children to go home. They are waving goodbye to the monkeys.'),
            ScriptLine('', "'Goodbye,' says Nada. 'Goodbye,' says Ahmed."),
            ScriptLine('', 'The children have a lovely day at the zoo.'),
          ]),
          Script(title: 'Help in the classroom', kind: ScriptKind.conversation, track: 75,
              instruction: 'Listen and learn.', lines: [
            ScriptLine('Teacher', "Where's the ruler?"),
            ScriptLine('Girl', "It's on the table. Here you are."),
            ScriptLine('Teacher', "I can't find my book."),
            ScriptLine('Boy', 'I can help you!'),
            ScriptLine('Teacher', 'Thank you.'),
          ]),
        ],
      ),
    ],
  ),
  // ----------------------------------------------------------------- Unit 7
  Unit(
    id: 7,
    title: 'My family',
    titleAr: 'عائلتي',
    colour: 0xFF8E5CC9,
    firstPage: 64,
    lastPage: 73,
    vocabularyTopics: [topicFamily, topicHouse],
    lessons: [
      Lesson(
        id: 'u7l1', unitId: 7, number: 1, title: 'My family', pages: [64],
        words: [_f('dad'), _f('mum'), _f('sister'), _f('brother'), _f('grandma'),
          _f('grandpa'), wordId('queen'), wordId('rabbit'), wordId('sun')],
        language: ['This is my dad.', 'This is my mum.', "Who's this?",
          'This is my friend, Robbie.'],
        bookActivities: ['Match', 'Listen, look and say', 'Listen and point'],
        scripts: [
          const Script(title: 'My family', kind: ScriptKind.phrases, track: 76,
              instruction: 'Listen and point.', lines: [
            ScriptLine('', 'dad'), ScriptLine('', 'mum'), ScriptLine('', 'sister'),
            ScriptLine('', 'brother'), ScriptLine('', 'grandma'), ScriptLine('', 'grandpa'),
          ]),
          const Script(title: "Hani's family", kind: ScriptKind.conversation, track: 77,
              instruction: 'Listen and point.', lines: [
            ScriptLine('Hani', 'This is my dad.'),
            ScriptLine('Hani', 'This is my mum.'),
            ScriptLine('Hani', 'This is my brother, Hasan.'),
            ScriptLine('Hani', 'This is my sister, Amna.'),
            ScriptLine('Hani', 'This is my grandpa.'),
            ScriptLine('Hani', 'This is my grandma.'),
            ScriptLine('Mum', "Who's this?"),
            ScriptLine('Hani', 'This is my friend, Robbie.'),
            ScriptLine('All', 'Hello, Robbie.'),
            ScriptLine('Robbie', 'Hello.'),
            ScriptLine('Hani', 'And this is my sister.'),
            ScriptLine('Robbie', 'I know! Hello, Iman!'),
            ScriptLine('Iman', 'Hello, Robbie.'),
          ]),
        ],
      ),
      Lesson(
        id: 'u7l2', unitId: 7, number: 2, title: 'How old are you?', pages: [65],
        words: [wordId('taxi'), wordId('umbrella'), wordId('violin')],
        language: ['How old are you?', "I'm 6.", "I'm 3."],
        bookActivities: ['Match', 'Listen and look', 'Listen and point'],
        scripts: [
          const Script(title: 'How old are you?', kind: ScriptKind.conversation, track: 78,
              instruction: 'Listen and look at the picture.', lines: [
            ScriptLine('Robbie', 'How old are you, Iman?'),
            ScriptLine('Iman', "I'm 6."),
            ScriptLine('Robbie', 'How old are you, Amna?'),
            ScriptLine('Amna', "I'm 3."),
          ]),
          const Script(title: 'How old is ...?', kind: ScriptKind.conversation, track: 79,
              instruction: 'Listen and look at the picture.', lines: [
            ScriptLine('Voice 1', 'How old is Iman?'),
            ScriptLine('Voice 2', "She's 6."),
            ScriptLine('Voice 1', 'How old is Hani?'),
            ScriptLine('Voice 2', "He's 5."),
            ScriptLine('Voice 1', 'How old is Amna?'),
            ScriptLine('Voice 2', "She's 3."),
            ScriptLine('Voice 1', 'How old is Hasan?'),
            ScriptLine('Voice 2', "He's 4."),
          ]),
        ],
      ),
      Lesson(
        id: 'u7l3', unitId: 7, number: 3, title: "It's my friend", pages: [66],
        words: [wordId('window'), wordId('x-ray'), wordId('yo-yo'), wordId('zebra')],
        language: ["It's my friend.", 'Rosie, my friend.'],
        bookActivities: ['Match', 'Listen and sing'],
        scripts: [
          const Script(title: 'My Friend', kind: ScriptKind.song, track: 80,
              instruction: 'Listen and sing.', lines: [
            ScriptLine('Hani', 'Look, Dad, look,'),
            ScriptLine('Hani', 'Robbie, my friend.'),
            ScriptLine('Hani', "It's my friend."),
            ScriptLine('Hani', 'My very good friend.'),
            ScriptLine('Hani', 'Robbie the funny robot!'),
            ScriptLine('Iman', 'Look, Mum, look.'),
            ScriptLine('Iman', 'Rosie, my friend.'),
            ScriptLine('Iman', "It's my friend."),
            ScriptLine('Iman', 'My very good friend.'),
            ScriptLine('Iman', 'Rosie the little robot!'),
          ]),
        ],
      ),
      Lesson(
        id: 'u7l4', unitId: 7, number: 4, title: 'I have a ...', pages: [67],
        words: [wordId('ant'), wordId('robot'), wordId('cat')],
        language: ['I have a green taxi.', 'I have a yellow car.', 'I have a green car.'],
        bookActivities: ['Match', 'Listen and point', 'Read'],
        scripts: [
          const Script(title: 'Listen and point', kind: ScriptKind.phrases, track: 81,
              instruction: 'Listen and point to the right picture.', lines: [
            ScriptLine('', 'This boy has a green van.'),
            ScriptLine('', 'This girl has a yellow taxi.'),
            ScriptLine('', 'This girl has a blue car.'),
          ]),
        ],
      ),
      Lesson(
        id: 'u7l5', unitId: 7, number: 5, title: 'What can you see?', pages: [68],
        words: [_h('bed'), _h('desk'), _h('chair'), _h('bin'), _h('table')],
        language: ['What can you see?'],
        bookActivities: ['Find and point'],
      ),
      Lesson(
        id: 'u7l6', unitId: 7, number: 6, title: 'This is my house', pages: [69],
        words: [_h('roof'), _h('window'), _h('door'), _h('wall'), _c('yellow'), _c('red'),
          _c('green'), _c('blue')],
        bookActivities: ['Look and say', 'Listen and point'],
        scripts: [
          const Script(title: 'This Is My House', kind: ScriptKind.song, track: 82,
              instruction: 'Listen and point.', lines: [
            ScriptLine('', 'This is my house.'),
            ScriptLine('', "It's a lovely house."),
            ScriptLine('', "It's red and yellow and green and blue."),
            ScriptLine('', 'The door is red.'),
            ScriptLine('', 'The windows are blue.'),
            ScriptLine('', 'The roof is blue, too.'),
            ScriptLine('', 'The walls are yellow and green.'),
          ]),
        ],
      ),
      const Lesson(
        id: 'u7l7', unitId: 7, number: 7, title: 'I have a key', pages: [70],
        language: ['I have a green key.', 'I have a red key.', 'I have a blue jumper.',
          'I have a yellow jumper.'],
        bookActivities: ['Read', 'Match'],
      ),
      const Lesson(
        id: 'u7l8', unitId: 7, number: 8, title: '10 Little Elephants', pages: [71],
        language: ['10 little elephants in a line.'],
        bookActivities: ['Listen and sing', 'Count'],
        scripts: [
          Script(title: '10 Little Elephants', kind: ScriptKind.song, track: 83,
              instruction: 'Listen and sing.', lines: [
            ScriptLine('', '1 little, 2 little, 3 little elephants'),
            ScriptLine('', '4 little, 5 little, 6 little elephants'),
            ScriptLine('', '7 little, 8 little, 9 little elephants'),
            ScriptLine('', '10 little elephants in a line.'),
          ]),
        ],
      ),
      const Lesson(
        id: 'u7p', unitId: 7, number: 0, title: 'P for Project: Draw your family',
        pages: [72, 73], kind: LessonKind.project,
        language: ['Draw your family.', 'Draw', 'Colour', 'Write', 'Stick',
          'mum dad brother sister grandma grandpa'],
      ),
    ],
  ),
  // ----------------------------------------------------------------- Unit 8
  Unit(
    id: 8,
    title: 'Revision',
    titleAr: 'مراجعة',
    colour: 0xFF15A6B8,
    firstPage: 74,
    lastPage: 79,
    vocabularyTopics: [],
    lessons: [
      const Lesson(
        id: 'u8l1', unitId: 8, number: 1, title: "Nada's little dog", pages: [74],
        language: ["Who's this?", 'How old are you, Iman?', "I'm 5.", 'What is it?',
          "It's my little dog.", 'How many can you see?', 'Oh!', "It's a balloon.",
          "It's a toy."],
        bookActivities: ['Listen and look', 'Look and say'],
        scripts: [
          Script(title: "Nada's little dog", kind: ScriptKind.conversation, track: 84,
              instruction: 'Listen and look at the pictures.', lines: [
            ScriptLine('Ahmed', 'How old are you, Iman?'),
            ScriptLine('Iman', "I'm 5."),
            ScriptLine('Ahmed', 'What is it?'),
            ScriptLine('Iman', "It's my little dog."),
            ScriptLine('Ahmed', 'Oh!'),
            ScriptLine('Iman', "It's a toy."),
          ]),
        ],
      ),
      const Lesson(
        id: 'u8l2', unitId: 8, number: 2, title: 'Find the right picture', pages: [75],
        bookActivities: ['Listen and point'],
        scripts: [
          Script(title: 'Listen and find', kind: ScriptKind.phrases, track: 85,
              instruction: 'Listen and find the right pictures.', lines: [
            ScriptLine('', 'This girl has a red pencil case and a yellow rubber.'),
            ScriptLine('', 'This boy is in school. He has two red pencils and a long ruler.'),
            ScriptLine('', 'This girl is in her house. She has a little doll.'),
            ScriptLine('', 'This man is in a big, black car.'),
            ScriptLine('', 'This lady is in a shop. She has a green bag.'),
            ScriptLine('', 'This girl is in the park. She has a red bike.'),
          ]),
        ],
      ),
      const Lesson(
        id: 'u8l3', unitId: 8, number: 3, title: 'I have a pen', pages: [76],
        language: ['I have a pen.', 'I have a pen and a pencil.'],
        bookActivities: ['Listen and look', 'Do'],
        scripts: [
          Script(title: 'The game', kind: ScriptKind.phrases, track: 86,
              instruction: 'Look at the pictures and listen to the game.', lines: [
            ScriptLine('', 'I have a pen.'),
            ScriptLine('', 'I have a pen and a pencil.'),
            ScriptLine('', 'I have a pen, a pencil and a rubber.'),
            ScriptLine('', 'I have a pen, a pencil, a rubber and a ruler.'),
            ScriptLine('', 'I have a pen, a pencil, a rubber, a ruler and a book.'),
            ScriptLine('', 'I have a pen, a pencil, a rubber, a ruler, a book and a bag.'),
          ]),
        ],
      ),
      const Lesson(
        id: 'u8l4', unitId: 8, number: 4, title: 'Goodbye', pages: [77],
        language: ['Goodbye.'],
        bookActivities: ['Look and say'],
      ),
      const Lesson(
        id: 'u8s', unitId: 8, number: 0, title: "Story: Ahmed's dream", pages: [78, 79],
        kind: LessonKind.story,
        language: ["It's my rocket.", 'No toys!', 'Goodbye!'],
        scripts: [
          Script(title: "Ahmed's dream", kind: ScriptKind.story, track: 87,
              instruction: 'Listen to a story and look at the pictures.', lines: [
            ScriptLine('', "In Ahmed's house, it is time for bed."),
            ScriptLine('', 'Ahmed\'s mum helps him put on his pyjamas. His pyjamas are purple.'),
            ScriptLine('', "Ahmed looks at the sky and says, 'It's the moon.'"),
            ScriptLine('', 'Ahmed gets into bed with his teddy. Ahmed falls asleep.'),
            ScriptLine('', "He dreams he has a rocket. Ahmed says, 'It's my rocket.'"),
            ScriptLine('', 'Ahmed is a spaceman with a big space helmet.'),
            ScriptLine('', 'He is in his rocket now with Nada and Robbie, and teddy, too.'),
            ScriptLine('', 'The rocket is flying in the sky. The children like flying in a rocket.'),
            ScriptLine('', 'They see a plane and they wave.'),
            ScriptLine('', 'The rocket lands on the moon.'),
            ScriptLine('', 'Ahmed is sad. Nada is sad. Robbie is sad. Teddy is sad.'),
            ScriptLine('', "Ahmed says, 'No toys!'"),
            ScriptLine('', 'Ahmed, Nada, Robbie and teddy fly home.'),
            ScriptLine('', 'The rocket flies through the window and into the bedroom.'),
            ScriptLine('', 'Ahmed makes a noise and he wakes up from his dream.'),
            ScriptLine('', 'His mum comes into his bedroom. Ahmed is not in bed. He is asleep on the toy box!'),
            ScriptLine('', "'Ahmed!' says Mum. Ahmed gets back into bed."),
            ScriptLine('', "He waves goodbye to the moon and says, 'Goodbye!'"),
          ]),
          Script(title: 'Love your family', kind: ScriptKind.conversation, track: 88,
              instruction: 'Listen and learn.', lines: [
            ScriptLine('Boy', 'I love you, Mum.'),
            ScriptLine('Mum', 'I love you, too.'),
            ScriptLine('Girl', 'This is a present for you, Grandpa. Because I love you.'),
            ScriptLine('Grandpa', 'Thank you!'),
            ScriptLine('Boy', 'I love my sister!'),
            ScriptLine('Girl', 'I love my brother!'),
          ]),
        ],
      ),
    ],
  ),
];

const Script comeToTheZoo = Script(
  title: 'Come To The Zoo!',
  kind: ScriptKind.song,
  track: 60,
  instruction: 'Listen and sing.',
  lines: [
    ScriptLine('', 'Boys and girls and Robbie too,'),
    ScriptLine('', 'Come to the zoo! Come to the zoo!'),
    ScriptLine('', 'Boys and girls and Robbie too,'),
    ScriptLine('', 'Come to the zoo today.'),
    ScriptLine('', "There's a lion, a tiger and monkeys too,"),
    ScriptLine('', 'In the zoo! In the zoo!'),
    ScriptLine('', "There's a lion, a tiger and monkeys too,"),
    ScriptLine('', 'In the zoo today.'),
    ScriptLine('', 'There are penguins, ducks and elephants too,'),
    ScriptLine('', 'In the zoo! In the zoo!'),
    ScriptLine('', 'There are penguins, ducks and elephants too,'),
    ScriptLine('', 'In the zoo today.'),
    ScriptLine('', "There's a camel, goats and rabbits too,"),
    ScriptLine('', 'In the zoo! In the zoo!'),
    ScriptLine('', "There's a camel, goats and rabbits too,"),
    ScriptLine('', 'In the zoo today.'),
  ],
);

const List<BookSection> bookSections = [
  BookSection('Cover', 'الغلاف', 1, 1),
  BookSection('Publication details', 'معلومات النشر', 2, 2),
  BookSection('Icon key', 'دليل الرموز', 3, 3),
  BookSection('Book map', 'خريطة الكتاب', 4, 5),
  BookSection('Alphabet', 'الحروف الأبجدية', 6, 7),
  BookSection('Transcripts', 'نصوص الاستماع', 80, 93),
  BookSection('Picture dictionary', 'القاموس المصوّر', 94, 96),
];

final List<Lesson> allLessons = [for (final u in units) ...u.lessons];

Lesson lessonById(String id) => allLessons.firstWhere((l) => l.id == id);

Unit unitById(int id) => units.firstWhere((u) => u.id == id);

/// Every listening script in the book (deduplicated by identity).
List<Script> get allScripts {
  final seen = <Script>{};
  final out = <Script>[];
  for (final l in allLessons) {
    for (final s in l.scripts) {
      if (seen.add(s)) out.add(s);
    }
  }
  return out;
}

/// A human readable description of what is on a PDF page, used by the
/// reader's page search and thumbnails.
String describePage(int page) {
  for (final s in bookSections) {
    if (page >= s.firstPage && page <= s.lastPage) return s.title;
  }
  for (final u in units) {
    for (final l in u.lessons) {
      if (l.pages.contains(page)) {
        final prefix = l.kind == LessonKind.lesson
            ? 'Unit ${u.id} · Lesson ${l.number}'
            : 'Unit ${u.id}';
        return '$prefix · ${l.title}';
      }
    }
  }
  return 'Page $page';
}

/// Searchable keywords for a PDF page (titles, letters, words, language).
String pageSearchText(int page) {
  final b = StringBuffer(describePage(page));
  for (final u in units) {
    if (page >= u.firstPage && page <= u.lastPage) b.write(' ${u.title}');
    for (final l in u.lessons) {
      if (!l.pages.contains(page)) continue;
      for (final letter in l.letters) {
        b.write(' letter $letter');
      }
      for (final w in l.words) {
        final v = vocabularyById[w];
        if (v != null) b.write(' ${v.text}');
      }
      for (final s in l.language) {
        b.write(' $s');
      }
      for (final sc in l.scripts) {
        b.write(' ${sc.title}');
      }
    }
  }
  if (page == 6 || page == 7) {
    for (final l in alphabet) {
      if (l.cardPage == page) b.write(' ${l.lower} ${l.words.join(' ')}');
    }
  }
  if (page >= 94) {
    for (final l in alphabet) {
      final dictPage = _dictionaryPage(l.lower);
      if (dictPage == page) b.write(' ${l.words.join(' ')}');
    }
  }
  return b.toString().toLowerCase();
}
