import 'package:material_ui/material_ui.dart';

import '../../content/book_data.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../listening/listen_repeat_screen.dart';
import 'choice_game.dart';
import 'choice_round.dart';
import 'extra_games.dart';

class GameSpec {
  const GameSpec(this.id, this.title, this.titleAr, this.icon, this.colour, this.open);
  final String id;
  final String title;
  final String titleAr;
  final IconData icon;
  final Color colour;
  final void Function(BuildContext) open;
}

void _push(BuildContext context, Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

/// The 12 educational games. All use vocabulary and concepts from the book.
final List<GameSpec> games = [
  GameSpec('match_picture', 'Match the word to the picture', 'طابق الكلمة بالصورة', Icons.image_search_rounded,
      AppColors.primary, (c) => openChoiceGame(c,
          title: 'Word and picture',
          instruction: 'Match the word to the picture.',
          makeRounds: () => RoundFactory().wordToPicture(vocabulary),
          kind: 'game_word_picture',
          ref: 'match_picture',
          colour: AppColors.primary)),
  GameSpec('match_case', 'Big and small letters', 'الحروف الكبيرة والصغيرة', Icons.text_fields_rounded, AppColors.coral,
      (c) => _push(c, const MatchCaseGame())),
  GameSpec('listen_choose', 'Listen and choose', 'استمع واختر', Icons.hearing_rounded, AppColors.teal,
      (c) => openChoiceGame(c,
          title: 'Listen and choose',
          instruction: 'Listen and choose the picture.',
          makeRounds: () => RoundFactory().listenAndChoose(vocabulary.where((w) => w.image != null).toList()),
          kind: 'game_listen',
          ref: 'listen_choose',
          colour: AppColors.teal)),
  GameSpec('missing_letter', 'Find the missing letter', 'جد الحرف الناقص', Icons.spellcheck_rounded, AppColors.grape,
      (c) => openChoiceGame(c,
          title: 'Missing letter',
          instruction: 'Find the missing letter.',
          makeRounds: () => RoundFactory().missingLetter(),
          kind: 'game_missing_letter',
          ref: 'missing_letter',
          colour: AppColors.grape)),
  GameSpec('arrange', 'Arrange letters into words', 'رتّب الحروف لتكوين كلمة', Icons.sort_by_alpha_rounded,
      AppColors.berry, (c) => _push(c, const ArrangeLettersGame())),
  GameSpec('colours', 'Colours', 'الألوان', Icons.palette_rounded, AppColors.orange,
      (c) => openChoiceGame(c,
          title: 'Colours',
          instruction: 'Which colour is it?',
          makeRounds: () => RoundFactory().colours(),
          kind: 'game_colours',
          ref: 'colours',
          colour: AppColors.orange)),
  GameSpec('count', 'Count the objects', 'عُدّ الأشياء', Icons.filter_9_plus_rounded, AppColors.grass,
      (c) => openChoiceGame(c,
          title: 'Count',
          instruction: 'How many can you see?',
          makeRounds: () => RoundFactory().counting(),
          kind: 'game_count',
          ref: 'count',
          colour: AppColors.grass)),
  GameSpec('animals', 'Animals', 'الحيوانات', Icons.pets_rounded, const Color(0xFFE5484D),
      (c) => openChoiceGame(c,
          title: 'Animals',
          instruction: 'Which animal is it?',
          makeRounds: () => RoundFactory().animals(),
          kind: 'game_animals',
          ref: 'animals',
          colour: const Color(0xFFE5484D))),
  GameSpec('classroom', 'Classroom objects', 'أدوات الصف', Icons.backpack_rounded, const Color(0xFFF29D0A),
      (c) => openChoiceGame(c,
          title: 'Classroom',
          instruction: 'Find the classroom object.',
          makeRounds: () => RoundFactory().classroom(),
          kind: 'game_classroom',
          ref: 'classroom',
          colour: const Color(0xFFF29D0A))),
  GameSpec('listen_repeat', 'Listen and repeat', 'استمع وكرّر', Icons.record_voice_over_rounded, AppColors.sky,
      (c) => _push(c, ListenRepeatScreen(title: 'Listen and repeat', items: listenRepeatDefault()))),
  GameSpec('memory', 'Memory cards', 'بطاقات الذاكرة', Icons.style_rounded, AppColors.teal,
      (c) => _push(c, const MemoryGame())),
  GameSpec('drag_drop', 'Drag and drop', 'اسحب وأفلت', Icons.pan_tool_alt_rounded, AppColors.orange,
      (c) => _push(c, const DragDropGame())),
];

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arabic = context.l10n.isArabic;
    return AppPage(
      title: context.tr('games'),
      colour: const Color(0xFFD6479B),
      body: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 560 ? 3 : 2);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.05),
          itemCount: games.length,
          itemBuilder: (context, i) {
            final g = games[i];
            return BigTile(
              key: ValueKey('game_${g.id}'),
              title: arabic ? g.titleAr : g.title,
              subtitle: '${i + 1}',
              icon: g.icon,
              colour: g.colour,
              onTap: () => g.open(context),
            );
          },
        );
      }),
    );
  }
}
