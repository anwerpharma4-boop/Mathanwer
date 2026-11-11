import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../content/models.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../games/choice_game.dart';
import '../games/choice_round.dart';
import '../listening/listen_repeat_screen.dart';
import '../reader/reader_screen.dart';

const Map<String, String> topicArabic = {
  topicAlphabet: 'كلمات الحروف',
  topicColours: 'الألوان',
  topicClassroom: 'أدوات الصف',
  topicToys: 'الألعاب',
  topicNumbers: 'الأرقام',
  topicAnimals: 'الحيوانات',
  topicAdjectives: 'الصفات',
  topicBody: 'أجزاء الجسم',
  topicFamily: 'العائلة',
  topicHouse: 'في البيت',
};

const Map<String, IconData> topicIcons = {
  topicAlphabet: Icons.abc_rounded,
  topicColours: Icons.palette_rounded,
  topicClassroom: Icons.backpack_rounded,
  topicToys: Icons.toys_rounded,
  topicNumbers: Icons.pin_rounded,
  topicAnimals: Icons.pets_rounded,
  topicAdjectives: Icons.straighten_rounded,
  topicBody: Icons.accessibility_new_rounded,
  topicFamily: Icons.family_restroom_rounded,
  topicHouse: Icons.house_rounded,
};

/// Units that teach a topic (from the Book map).
List<int> unitsForTopic(String topic) => [for (final u in units) if (u.vocabularyTopics.contains(topic)) u.id];

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arabic = context.l10n.isArabic;
    final progress = AppScope.of(context).progress;
    return AppPage(
      title: context.tr('vocabulary'),
      colour: AppColors.grape,
      body: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 560 ? 3 : 2);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.0),
          itemCount: vocabularyTopics.length,
          itemBuilder: (context, i) {
            final t = vocabularyTopics[i];
            final words = wordsInTopic(t);
            final mastered = words.where((w) => progress.wordStat(w.id).mastered).length;
            final unitIds = unitsForTopic(t);
            return BigTile(
              key: ValueKey('topic_$i'),
              title: arabic ? topicArabic[t]! : t,
              subtitle: '${context.tr('unit')} ${unitIds.join(', ')} · $mastered/${words.length}',
              icon: topicIcons[t]!,
              colour: AppColors.tiles[(i + 2) % AppColors.tiles.length],
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TopicScreen(topic: t))),
            );
          },
        );
      }),
    );
  }
}

class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, required this.topic});
  final String topic;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final _pc = PageController(viewportFraction: 0.82);
  int _index = 0;

  List<VocabWord> get words => wordsInTopic(widget.topic);

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arabic = context.l10n.isArabic;
    final ws = words;
    const colour = AppColors.grape;
    final visual = ws.where((w) => w.image != null || w.colour != null || w.count != null).toList();
    return AppPage(
      title: arabic ? topicArabic[widget.topic]! : widget.topic,
      colour: colour,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Pill(text: '${context.tr('fromBook')} · ${context.tr('unit')} ${unitsForTopic(widget.topic).join(', ')}',
              colour: AppColors.grass, icon: Icons.menu_book_rounded),
        ),
        Expanded(
          child: EnglishContent(
            child: PageView.builder(
              key: const ValueKey('flashcards'),
              controller: _pc,
              itemCount: ws.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                AppScope.read(context).audio.say(ws[i].spoken);
              },
              itemBuilder: (context, i) {
                final w = ws[i];
                return AnimatedScale(
                  scale: i == _index ? 1 : 0.9,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    child: Panel(
                      child: LayoutBuilder(builder: (context, c) {
                        final pic = (c.maxHeight - 150).clamp(80.0, 320.0);
                        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          WordPicture(word: w, size: pic),
                          const SizedBox(height: 8),
                          Text(w.text, style: learningText(40, color: colour)),
                          const SizedBox(height: 6),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            SpeakButton(key: ValueKey('say_${w.id}'), text: w.spoken, size: 56, colour: colour),
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => ReaderScreen(initialPage: w.page))),
                              icon: const Icon(Icons.menu_book_rounded, size: 18),
                              label: Text('${context.tr('page')} ${w.page}'),
                            ),
                          ]),
                        ]);
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Text('${_index + 1} / ${ws.length}', style: const TextStyle(color: AppColors.inkSoft)),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
            FilledButton.icon(
              key: const ValueKey('topicRepeat'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ListenRepeatScreen(
                      title: context.tr('listenAndSay'),
                      colour: colour,
                      items: [for (final w in ws) RepeatItem(w.spoken, word: w)]))),
              icon: const Icon(Icons.record_voice_over_rounded),
              label: Text(context.tr('listenAndSay')),
            ),
            if (visual.length >= 3)
              FilledButton.icon(
                key: const ValueKey('topicListenChoose'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                onPressed: () => openChoiceGame(context,
                    title: widget.topic,
                    instruction: 'Listen and choose the picture.',
                    makeRounds: () => RoundFactory().listenAndChoose(visual, rounds: 8, options: visual.length >= 4 ? 4 : 3),
                    kind: 'vocab',
                    ref: widget.topic,
                    colour: AppColors.teal),
                icon: const Icon(Icons.hearing_rounded),
                label: const Text('Listen and choose'),
              ),
            if (ws.where((w) => w.image != null).length >= 3)
              FilledButton.icon(
                key: const ValueKey('topicMatch'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => openChoiceGame(context,
                    title: widget.topic,
                    instruction: 'Match the word to the picture.',
                    makeRounds: () => RoundFactory().wordToPicture(ws, rounds: 8),
                    kind: 'vocab',
                    ref: '${widget.topic}_match',
                    colour: AppColors.primary),
                icon: const Icon(Icons.image_search_rounded),
                label: const Text('Word and picture'),
              ),
          ]),
        ),
      ]),
    );
  }
}
