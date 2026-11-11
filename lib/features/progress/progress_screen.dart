import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/progress_store.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../quizzes/quizzes_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    final arabic = context.l10n.isArabic;
    return AppPage(
      title: context.tr('progress'),
      colour: AppColors.sky,
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) {
          final level = progress.level;
          final today = progress.activitiesOn(DateTime.now());
          final goal = progress.dailyGoal;
          final weak = progress.weakWords.map((id) => vocabularyById[id]).whereType<Object>().take(8).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Panel(
                child: Row(
                  children: [
                    const Mascot(size: 90, mood: MascotMood.cheer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${context.tr('level')} $level · ${context.tr('level$level')}',
                            key: const ValueKey('levelLabel'),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(value: progress.levelProgress, minHeight: 14),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.sunshine, size: 30),
                              Text(
                                ' ${progress.totalStars} ${context.tr('stars')}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Panel(
                child: Row(
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: (today / goal).clamp(0, 1).toDouble(),
                            strokeWidth: 10,
                            backgroundColor: AppColors.grass.withValues(alpha: 0.15),
                            color: AppColors.grass,
                          ),
                          Center(
                            child: Text(
                              '${today.clamp(0, 99)}/$goal',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('dailyGoal'),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '$today ${context.tr('activitiesToday')} · ${(progress.secondsOn(DateTime.now()) / 60).round()} ${context.tr('minutesToday')}',
                          ),
                          if (progress.dailyGoalMet)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Pill(text: '✓', colour: AppColors.success, icon: Icons.flag_rounded),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(context.tr('lessons'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final u in units)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(
                          '${u.id}. ${arabic ? u.titleAr : u.title}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress.unitCompletion(u.id),
                            minHeight: 14,
                            color: Color(u.colour),
                            backgroundColor: Color(u.colour).withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${u.lessons.where((l) => progress.lesson(l.id).status == LessonStatus.completed).length}/${u.lessons.length}',
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Text(context.tr('badges'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final b in badgeDefs)
                    Tooltip(
                      message: arabic ? b.titleAr : b.title,
                      child: Container(
                        width: 96,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: progress.badges.containsKey(b.id)
                              ? AppColors.sunshine.withValues(alpha: 0.35)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              iconByName(b.icon),
                              size: 36,
                              color: progress.badges.containsKey(b.id) ? AppColors.orange : Colors.black26,
                            ),
                            Text(
                              arabic ? b.titleAr : b.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: progress.badges.containsKey(b.id) ? AppColors.ink : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(context.tr('reviewThese'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (weak.isEmpty)
                Text(context.tr('nothingToReview'))
              else ...[
                EnglishContent(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in progress.weakWords.take(8))
                        Chip(label: Text(vocabularyById[id]?.text ?? id, style: learningText(18))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => openRevision(context),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('practise')),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
