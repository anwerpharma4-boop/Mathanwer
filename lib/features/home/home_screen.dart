import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../content/models.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/progress_store.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../alphabet/alphabet_screen.dart';
import '../drawing/drawing_screen.dart';
import '../games/games_screen.dart';
import '../lessons/lesson_screen.dart';
import '../lessons/units_screen.dart';
import '../listening/listening_screen.dart';
import '../progress/progress_screen.dart';
import '../quizzes/quizzes_screen.dart';
import '../reader/reader_screen.dart';
import '../settings/settings_screen.dart';
import '../vocabulary/vocabulary_screen.dart';

/// The lesson to continue with: the last opened unfinished lesson, otherwise
/// the first lesson that is not completed.
Lesson nextLesson(ProgressStore progress) {
  final last = progress.value('last_lesson');
  if (last != null) {
    final l = allLessons.where((x) => x.id == last);
    if (l.isNotEmpty && progress.lesson(last).status != LessonStatus.completed) return l.first;
  }
  return allLessons.firstWhere(
    (l) => progress.lesson(l.id).status != LessonStatus.completed,
    orElse: () => allLessons.first,
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final progress = services.progress;
    final tiles = <_TileSpec>[
      _TileSpec(
        'startLearning',
        'startLearningSub',
        Icons.play_circle_fill_rounded,
        () => _push(context, LessonScreen(lesson: nextLesson(progress))),
      ),
      _TileSpec(
        'textbook',
        'textbookSub',
        Icons.menu_book_rounded,
        () => _push(context, ReaderScreen(initialPage: progress.lastReaderPage)),
      ),
      _TileSpec('lessons', 'lessonsSub', Icons.school_rounded, () => _push(context, const UnitsScreen())),
      _TileSpec('alphabet', 'alphabetSub', Icons.abc_rounded, () => _push(context, const AlphabetScreen())),
      _TileSpec(
        'vocabulary',
        'vocabularySub',
        Icons.collections_bookmark_rounded,
        () => _push(context, const VocabularyScreen()),
      ),
      _TileSpec('listening', 'listeningSub', Icons.headphones_rounded, () => _push(context, const ListeningScreen())),
      _TileSpec('games', 'gamesSub', Icons.sports_esports_rounded, () => _push(context, const GamesScreen())),
      _TileSpec('quizzes', 'quizzesSub', Icons.emoji_events_rounded, () => _push(context, const QuizzesScreen())),
      _TileSpec('progress', 'progressSub', Icons.insights_rounded, () => _push(context, const ProgressScreen())),
      _TileSpec('settings', 'settingsSub', Icons.settings_rounded, () => _push(context, const SettingsScreen())),
      _TileSpec('drawing', 'drawingSub', Icons.palette_rounded, () => _push(context, const DrawingHomeScreen())),
    ];
    const tileColours = [...AppColors.tiles, Color(0xFFFF6B5E)];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 700;
            final cols = c.maxWidth > 700 ? 4 : (c.maxWidth > 460 ? 3 : 2);
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(wide: wide)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: c.maxWidth > 1000 ? 1.5 : (wide ? 1.15 : 1.0),
                    ),
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final t = tiles[i];
                      return BigTile(
                        key: ValueKey('home_${t.key}'),
                        title: context.tr(t.key),
                        subtitle: context.tr(t.sub),
                        icon: t.icon,
                        colour: tileColours[i],
                        onTap: t.onTap,
                      );
                    }, childCount: tiles.length),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TileSpec {
  _TileSpec(this.key, this.sub, this.icon, this.onTap);
  final String key;
  final String sub;
  final IconData icon;
  final VoidCallback onTap;
}

class _Header extends StatelessWidget {
  const _Header({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) {
        final today = progress.activitiesOn(DateTime.now());
        final goal = progress.dailyGoal;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4F8DF9), Color(0xFF7A5CF0)]),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: [
              Mascot(size: wide ? 120 : 92),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('hello'),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      context.tr('letsLearn'),
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr('appTitle')} · ${context.tr('appSubtitle')}',
                      maxLines: 2,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _HeaderChip(icon: Icons.star_rounded, text: '${progress.totalStars}'),
                        _HeaderChip(
                          icon: Icons.military_tech_rounded,
                          text: '${context.tr('level')} ${progress.level}',
                        ),
                        _HeaderChip(
                          icon: Icons.flag_rounded,
                          text: '${today.clamp(0, goal)}/$goal ${context.tr('activitiesToday')}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.sunshine, size: 18),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
