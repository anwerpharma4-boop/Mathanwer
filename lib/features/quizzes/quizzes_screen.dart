import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../games/choice_game.dart';
import '../games/choice_round.dart';

void openRevision(BuildContext context) {
  final weak = AppScope.read(context).progress.weakWords;
  openChoiceGame(context,
      title: context.tr('reviewThese'),
      instruction: 'Listen and choose the picture.',
      makeRounds: () => RoundFactory().revision(weak),
      kind: 'revision',
      ref: 'revision',
      colour: AppColors.orange);
}

class QuizzesScreen extends StatelessWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    final arabic = context.l10n.isArabic;
    return AppPage(
      title: context.tr('quizzes'),
      colour: const Color(0xFFE8B10E),
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 150,
                  child: BigTile(
                    key: const ValueKey('bigChallenge'),
                    title: context.tr('challenge'),
                    subtitle: '15 ${context.tr('questions')}',
                    icon: Icons.emoji_events_rounded,
                    colour: AppColors.berry,
                    badge: progress.bestStars('quiz', 'challenge') > 0
                        ? StarRow(stars: progress.bestStars('quiz', 'challenge'), size: 18)
                        : null,
                    onTap: () => openChoiceGame(context,
                        title: context.tr('challenge'),
                        instruction: 'Listen and choose the picture.',
                        makeRounds: () {
                          final f = RoundFactory();
                          return [
                            ...f.listenAndChoose(vocabulary, rounds: 5, options: 4),
                            ...f.pictureToWord(vocabulary, rounds: 4),
                            ...f.missingLetter(rounds: 3),
                            ...f.counting(rounds: 3),
                          ];
                        },
                        kind: 'quiz',
                        ref: 'challenge',
                        colour: AppColors.berry),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 150,
                  child: BigTile(
                    key: const ValueKey('revisionQuiz'),
                    title: context.tr('reviewThese'),
                    subtitle: '${progress.weakWords.length} ${context.tr('words')}',
                    icon: Icons.refresh_rounded,
                    colour: AppColors.orange,
                    onTap: () => openRevision(context),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Text(context.tr('unitQuiz'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final u in units)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  key: ValueKey('unitQuiz_${u.id}'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: Color(u.colour),
                    child: Text('${u.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                  ),
                  title: EnglishContent(child: Text(u.title, style: learningText(20))),
                  subtitle: arabic ? Text(u.titleAr) : null,
                  trailing: progress.bestStars('quiz', 'unit_${u.id}') > 0
                      ? StarRow(stars: progress.bestStars('quiz', 'unit_${u.id}'), size: 22)
                      : Icon(Icons.play_circle_fill_rounded, color: Color(u.colour), size: 36),
                  onTap: () => openChoiceGame(context,
                      title: '${context.tr('unitQuiz')} ${u.id}',
                      instruction: 'Listen and choose the picture.',
                      makeRounds: () => RoundFactory().unitQuiz(u),
                      kind: 'quiz',
                      ref: 'unit_${u.id}',
                      unitId: u.id,
                      colour: Color(u.colour)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
