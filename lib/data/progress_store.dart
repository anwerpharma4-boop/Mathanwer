import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../content/book_data.dart';

/// Status of a lesson for the learner.
enum LessonStatus { notStarted, inProgress, completed }

class LessonProgress {
  const LessonProgress(this.status, this.stars);
  final LessonStatus status;
  final int stars;
}

class ActivityResult {
  const ActivityResult({
    required this.kind,
    required this.ref,
    required this.unitId,
    required this.score,
    required this.total,
    required this.stars,
    required this.createdAt,
  });

  final String kind;
  final String ref;
  final int? unitId;
  final int score;
  final int total;
  final int stars;
  final DateTime createdAt;

  double get ratio => total == 0 ? 0 : score / total;
}

class WordStat {
  WordStat(this.correct, this.wrong);
  int correct;
  int wrong;

  int get attempts => correct + wrong;
  double get accuracy => attempts == 0 ? 0 : correct / attempts;
  bool get mastered => correct >= 3 && correct >= wrong * 2;
}

class BadgeDef {
  const BadgeDef(this.id, this.title, this.titleAr, this.icon);
  final String id;
  final String title;
  final String titleAr;

  /// Material icon code point name used by the UI.
  final String icon;
}

const List<BadgeDef> badgeDefs = [
  BadgeDef('first_lesson', 'First lesson', 'الدرس الأول', 'school'),
  BadgeDef('five_lessons', '5 lessons', '5 دروس', 'menu_book'),
  BadgeDef('twenty_lessons', '20 lessons', '20 درساً', 'auto_stories'),
  BadgeDef('first_game', 'First game', 'اللعبة الأولى', 'sports_esports'),
  BadgeDef('ten_games', '10 games', '10 ألعاب', 'emoji_events'),
  BadgeDef('perfect', 'Perfect score', 'نتيجة كاملة', 'star'),
  BadgeDef('quiz_star', 'Quiz star', 'نجم الاختبارات', 'military_tech'),
  BadgeDef('word_wizard', '20 words mastered', 'أتقنت 20 كلمة', 'abc'),
  BadgeDef('letter_tracer', 'Letter tracer', 'متتبّع الحروف', 'gesture'),
  BadgeDef('listener', 'Good listener', 'مستمع جيد', 'headphones'),
  BadgeDef('artist', 'Little artist', 'فنان صغير', 'palette'),
  BadgeDef('daily_goal', 'Daily goal', 'الهدف اليومي', 'flag'),
  BadgeDef('unit_1', 'Unit 1 done', 'أكملت الوحدة 1', 'looks_one'),
  BadgeDef('unit_2', 'Unit 2 done', 'أكملت الوحدة 2', 'looks_two'),
  BadgeDef('unit_3', 'Unit 3 done', 'أكملت الوحدة 3', 'looks_3'),
  BadgeDef('unit_4', 'Unit 4 done', 'أكملت الوحدة 4', 'looks_4'),
  BadgeDef('unit_5', 'Unit 5 done', 'أكملت الوحدة 5', 'looks_5'),
  BadgeDef('unit_6', 'Unit 6 done', 'أكملت الوحدة 6', 'looks_6'),
  BadgeDef('unit_7', 'Unit 7 done', 'أكملت الوحدة 7', 'filter_7'),
  BadgeDef('unit_8', 'Unit 8 done', 'أكملت الوحدة 8', 'filter_8'),
];

/// Stars are encouraging: finishing an activity always earns at least 1.
int starsFor(int score, int total) {
  if (total <= 0) return 1;
  final r = score / total;
  if (r >= 0.9) return 3;
  if (r >= 0.6) return 2;
  return 1;
}

/// Level thresholds by total stars (index = level - 1).
const List<int> levelThresholds = [0, 15, 40, 80, 150];

int levelForStars(int stars) {
  var level = 1;
  for (var i = 0; i < levelThresholds.length; i++) {
    if (stars >= levelThresholds[i]) level = i + 1;
  }
  return level;
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Local progress database (SQLite). Everything stays on the device.
class ProgressStore extends ChangeNotifier {
  ProgressStore._(this._db);

  /// Memory-only store (nothing persisted). Used by widget tests and as a
  /// fallback if the database cannot be opened.
  factory ProgressStore.memory() => ProgressStore._(null);

  final Database? _db;

  final Map<String, LessonProgress> _lessons = {};
  final List<ActivityResult> _results = [];
  final Map<String, WordStat> _words = {};
  final Map<String, int> _dailySeconds = {};
  final Map<String, int> _dailyActivities = {};
  final Set<int> _bookmarks = {};
  final Map<String, DateTime> _badges = {};
  final Map<String, String> _kv = {};

  /// Badges earned since the UI last asked (for celebration pop-ups).
  final List<BadgeDef> newlyEarned = [];

  static const _schemaVersion = 1;

  static Future<ProgressStore> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'progress.db');
    final database = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onCreate: (db, v) async {
          final b = db.batch();
          b.execute(
            'CREATE TABLE lessons(lesson_id TEXT PRIMARY KEY, status INTEGER NOT NULL, stars INTEGER NOT NULL, updated_at INTEGER NOT NULL)',
          );
          b.execute(
            'CREATE TABLE results(id INTEGER PRIMARY KEY AUTOINCREMENT, kind TEXT NOT NULL, ref TEXT NOT NULL, unit_id INTEGER, score INTEGER NOT NULL, total INTEGER NOT NULL, stars INTEGER NOT NULL, created_at INTEGER NOT NULL)',
          );
          b.execute(
            'CREATE TABLE words(word_id TEXT PRIMARY KEY, correct INTEGER NOT NULL, wrong INTEGER NOT NULL, last_seen INTEGER NOT NULL)',
          );
          b.execute('CREATE TABLE daily(day TEXT PRIMARY KEY, seconds INTEGER NOT NULL, activities INTEGER NOT NULL)');
          b.execute('CREATE TABLE bookmarks(page INTEGER PRIMARY KEY, created_at INTEGER NOT NULL)');
          b.execute('CREATE TABLE badges(id TEXT PRIMARY KEY, earned_at INTEGER NOT NULL)');
          b.execute('CREATE TABLE kv(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
          await b.commit(noResult: true);
        },
      ),
    );
    final store = ProgressStore._(database);
    await store._load();
    return store;
  }

  Future<void> _load() async {
    final db = _db;
    if (db == null) return;
    for (final r in await db.query('lessons')) {
      _lessons[r['lesson_id'] as String] = LessonProgress(LessonStatus.values[r['status'] as int], r['stars'] as int);
    }
    for (final r in await db.query('results', orderBy: 'id')) {
      _results.add(
        ActivityResult(
          kind: r['kind'] as String,
          ref: r['ref'] as String,
          unitId: r['unit_id'] as int?,
          score: r['score'] as int,
          total: r['total'] as int,
          stars: r['stars'] as int,
          createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        ),
      );
    }
    for (final r in await db.query('words')) {
      _words[r['word_id'] as String] = WordStat(r['correct'] as int, r['wrong'] as int);
    }
    for (final r in await db.query('daily')) {
      _dailySeconds[r['day'] as String] = r['seconds'] as int;
      _dailyActivities[r['day'] as String] = r['activities'] as int;
    }
    for (final r in await db.query('bookmarks')) {
      _bookmarks.add(r['page'] as int);
    }
    for (final r in await db.query('badges')) {
      _badges[r['id'] as String] = DateTime.fromMillisecondsSinceEpoch(r['earned_at'] as int);
    }
    for (final r in await db.query('kv')) {
      _kv[r['key'] as String] = r['value'] as String;
    }
  }

  Future<void> close() async => _db?.close();

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ------------------------------------------------------------- lessons
  LessonProgress lesson(String id) => _lessons[id] ?? const LessonProgress(LessonStatus.notStarted, 0);

  Future<void> markLessonStarted(String id) async {
    if (lesson(id).status != LessonStatus.notStarted) return;
    _lessons[id] = const LessonProgress(LessonStatus.inProgress, 0);
    await _db?.insert('lessons', {
      'lesson_id': id,
      'status': 1,
      'stars': 0,
      'updated_at': _now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await setValue('last_lesson', id);
    notifyListeners();
  }

  Future<void> completeLesson(String id, {int stars = 3}) async {
    final prev = lesson(id);
    final best = stars > prev.stars ? stars : prev.stars;
    _lessons[id] = LessonProgress(LessonStatus.completed, best);
    await _db?.insert('lessons', {
      'lesson_id': id,
      'status': 2,
      'stars': best,
      'updated_at': _now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await setValue('last_lesson', id);
    await _bumpActivity();
    await _checkBadges();
    notifyListeners();
  }

  int get completedLessonCount => _lessons.values.where((l) => l.status == LessonStatus.completed).length;

  bool isUnitComplete(int unitId) =>
      unitById(unitId).lessons.every((l) => lesson(l.id).status == LessonStatus.completed);

  double unitCompletion(int unitId) {
    final ls = unitById(unitId).lessons;
    final done = ls.where((l) => lesson(l.id).status == LessonStatus.completed).length;
    return ls.isEmpty ? 0 : done / ls.length;
  }

  // ------------------------------------------------------------- results
  List<ActivityResult> get results => List.unmodifiable(_results);

  Future<ActivityResult> recordResult({
    required String kind,
    required String ref,
    int? unitId,
    required int score,
    required int total,
  }) async {
    final stars = starsFor(score, total);
    final r = ActivityResult(
      kind: kind,
      ref: ref,
      unitId: unitId,
      score: score,
      total: total,
      stars: stars,
      createdAt: DateTime.now(),
    );
    _results.add(r);
    await _db?.insert('results', {
      'kind': kind,
      'ref': ref,
      'unit_id': unitId,
      'score': score,
      'total': total,
      'stars': stars,
      'created_at': r.createdAt.millisecondsSinceEpoch,
    });
    await _bumpActivity();
    await _checkBadges();
    notifyListeners();
    return r;
  }

  int get totalStars =>
      _results.fold<int>(0, (s, r) => s + r.stars) + _lessons.values.fold<int>(0, (s, l) => s + l.stars);

  int get level => levelForStars(totalStars);

  /// Progress (0..1) towards the next level.
  double get levelProgress {
    final l = level;
    if (l >= levelThresholds.length) return 1;
    final lo = levelThresholds[l - 1];
    final hi = levelThresholds[l];
    return ((totalStars - lo) / (hi - lo)).clamp(0, 1).toDouble();
  }

  int bestStars(String kind, String ref) =>
      _results.where((r) => r.kind == kind && r.ref == ref).fold<int>(0, (m, r) => r.stars > m ? r.stars : m);

  // ------------------------------------------------------------- words
  WordStat wordStat(String id) => _words[id] ?? WordStat(0, 0);

  Future<void> recordWord(String id, bool correct) async {
    final s = _words.putIfAbsent(id, () => WordStat(0, 0));
    if (correct) {
      s.correct++;
    } else {
      s.wrong++;
    }
    await _db?.insert('words', {
      'word_id': id,
      'correct': s.correct,
      'wrong': s.wrong,
      'last_seen': _now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  int get masteredWordCount => _words.values.where((w) => w.mastered).length;

  /// Words that need revision: answered wrongly and not yet mastered.
  List<String> get weakWords {
    final list = _words.entries.where((e) => e.value.wrong > 0 && !e.value.mastered && e.value.accuracy < 0.75).toList()
      ..sort((a, b) => b.value.wrong.compareTo(a.value.wrong));
    return list.map((e) => e.key).toList();
  }

  // ------------------------------------------------------------- daily
  int secondsOn(DateTime day) => _dailySeconds[dayKey(day)] ?? 0;
  int activitiesOn(DateTime day) => _dailyActivities[dayKey(day)] ?? 0;
  int get totalSeconds => _dailySeconds.values.fold(0, (a, b) => a + b);

  Future<void> addLearningTime(int seconds) async {
    if (seconds <= 0) return;
    final k = dayKey(DateTime.now());
    _dailySeconds[k] = (_dailySeconds[k] ?? 0) + seconds;
    await _saveDay(k);
    notifyListeners();
  }

  Future<void> _bumpActivity() async {
    final k = dayKey(DateTime.now());
    _dailyActivities[k] = (_dailyActivities[k] ?? 0) + 1;
    await _saveDay(k);
  }

  Future<void> _saveDay(String k) async => _db?.insert('daily', {
    'day': k,
    'seconds': _dailySeconds[k] ?? 0,
    'activities': _dailyActivities[k] ?? 0,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  int dailyGoal = 5;

  bool get dailyGoalMet => activitiesOn(DateTime.now()) >= dailyGoal;

  // ------------------------------------------------------------- bookmarks
  Set<int> get bookmarks => Set.unmodifiable(_bookmarks);
  bool isBookmarked(int page) => _bookmarks.contains(page);

  Future<void> toggleBookmark(int page) async {
    if (_bookmarks.remove(page)) {
      await _db?.delete('bookmarks', where: 'page = ?', whereArgs: [page]);
    } else {
      _bookmarks.add(page);
      await _db?.insert('bookmarks', {'page': page, 'created_at': _now}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    notifyListeners();
  }

  // ------------------------------------------------------------- kv
  String? value(String key) => _kv[key];

  Future<void> setValue(String key, String value) async {
    _kv[key] = value;
    await _db?.insert('kv', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  int get lastReaderPage => int.tryParse(_kv['reader_page'] ?? '') ?? 1;
  Future<void> setLastReaderPage(int page) => setValue('reader_page', '$page');

  // ------------------------------------------------------------- badges
  Map<String, DateTime> get badges => Map.unmodifiable(_badges);

  Future<void> awardBadge(String id) async {
    if (_badges.containsKey(id)) return;
    final now = DateTime.now();
    _badges[id] = now;
    newlyEarned.add(badgeDefs.firstWhere((b) => b.id == id));
    await _db?.insert('badges', {
      'id': id,
      'earned_at': now.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _checkBadges() async {
    final lessonsDone = completedLessonCount;
    if (lessonsDone >= 1) await awardBadge('first_lesson');
    if (lessonsDone >= 5) await awardBadge('five_lessons');
    if (lessonsDone >= 20) await awardBadge('twenty_lessons');
    final games = _results.where((r) => r.kind.startsWith('game')).length;
    if (games >= 1) await awardBadge('first_game');
    if (games >= 10) await awardBadge('ten_games');
    if (_results.any((r) => r.total >= 5 && r.score == r.total)) await awardBadge('perfect');
    if (_results.any((r) => r.kind == 'quiz' && r.stars == 3)) await awardBadge('quiz_star');
    if (masteredWordCount >= 20) await awardBadge('word_wizard');
    if (_results.where((r) => r.kind == 'trace').length >= 5) await awardBadge('letter_tracer');
    if (_results.where((r) => r.kind == 'listen').length >= 5) await awardBadge('listener');
    if (_results.any((r) => r.kind == 'drawing')) await awardBadge('artist');
    if (dailyGoalMet) await awardBadge('daily_goal');
    for (final u in units) {
      if (isUnitComplete(u.id)) await awardBadge('unit_${u.id}');
    }
  }

  List<BadgeDef> takeNewBadges() {
    final out = List<BadgeDef>.from(newlyEarned);
    newlyEarned.clear();
    return out;
  }

  // ------------------------------------------------------------- parents
  /// Average score ratio per activity kind (for the parent dashboard).
  Map<String, double> averageByKind() {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final r in _results) {
      if (r.total == 0) continue;
      sums[r.kind] = (sums[r.kind] ?? 0) + r.ratio;
      counts[r.kind] = (counts[r.kind] ?? 0) + 1;
    }
    return {for (final k in sums.keys) k: sums[k]! / counts[k]!};
  }

  /// Average ratio per vocabulary topic from word statistics.
  Map<String, double> accuracyByTopic() {
    final c = <String, int>{};
    final t = <String, int>{};
    for (final e in _words.entries) {
      final w = vocabularyById[e.key];
      if (w == null) continue;
      c[w.topic] = (c[w.topic] ?? 0) + e.value.correct;
      t[w.topic] = (t[w.topic] ?? 0) + e.value.attempts;
    }
    return {
      for (final k in t.keys)
        if (t[k]! > 0) k: c[k]! / t[k]!,
    };
  }

  double get overallCompletion => allLessons.isEmpty ? 0 : completedLessonCount / allLessons.length;

  Future<void> resetAll() async {
    for (final t in ['lessons', 'results', 'words', 'daily', 'bookmarks', 'badges', 'kv']) {
      await _db?.delete(t);
    }
    _lessons.clear();
    _results.clear();
    _words.clear();
    _dailySeconds.clear();
    _dailyActivities.clear();
    _bookmarks.clear();
    _badges.clear();
    _kv.clear();
    newlyEarned.clear();
    notifyListeners();
  }
}
