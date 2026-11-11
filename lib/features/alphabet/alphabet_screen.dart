import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../games/choice_game.dart';
import '../games/choice_round.dart';
import '../games/extra_games.dart';
import 'letter_screen.dart';

class AlphabetScreen extends StatelessWidget {
  const AlphabetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    const colour = Color(0xFFE5484D);
    return AppPage(
      title: context.tr('alphabet'),
      colour: colour,
      body: LayoutBuilder(
        builder: (context, c) {
          final cols = (c.maxWidth / 110).floor().clamp(3, 9);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _ActivityChip(
                        icon: Icons.search_rounded,
                        label: context.tr('findLetter'),
                        onTap: () => openChoiceGame(
                          context,
                          title: context.tr('findLetter'),
                          instruction: 'Find the letter.',
                          makeRounds: () => RoundFactory().findLetter(),
                          kind: 'alphabet',
                          ref: 'find_letter',
                          colour: colour,
                        ),
                      ),
                      _ActivityChip(
                        icon: Icons.text_fields_rounded,
                        label: context.tr('matchCase'),
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MatchCaseGame())),
                      ),
                      _ActivityChip(
                        icon: Icons.hearing_rounded,
                        label: context.tr('initialSound'),
                        onTap: () => openChoiceGame(
                          context,
                          title: context.tr('initialSound'),
                          instruction: 'Which picture starts with this sound?',
                          makeRounds: () => RoundFactory().initialSound(),
                          kind: 'alphabet',
                          ref: 'initial_sound',
                          colour: colour,
                        ),
                      ),
                      _ActivityChip(
                        icon: Icons.image_rounded,
                        label: 'Letters & pictures',
                        onTap: () => openChoiceGame(
                          context,
                          title: 'Letters & pictures',
                          instruction: 'Which picture starts with this sound?',
                          makeRounds: () => RoundFactory().initialSound(rounds: 10),
                          kind: 'alphabet',
                          ref: 'letter_picture',
                          colour: colour,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final l = alphabet[i];
                    final stars = progress.bestStars('trace', l.lower);
                    return Material(
                      key: ValueKey('letter_${l.lower}'),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      elevation: 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => LetterScreen(letter: l))),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: EnglishContent(
                            child: Column(
                              children: [
                                Text('${l.upper}${l.lower}', style: learningText(26, color: colour)),
                                Expanded(
                                  child: Image.asset(l.cardImage, fit: BoxFit.contain, semanticLabel: l.words.first),
                                ),
                                if (stars > 0) StarRow(stars: stars, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: alphabet.length),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Text(
                    'Pictures: original alphabet cards from the Pupil\'s Book, pages 6–7.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
    child: ActionChip(
      avatar: Icon(icon, color: const Color(0xFFE5484D)),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      onPressed: onTap,
      backgroundColor: Colors.white,
    ),
  );
}
