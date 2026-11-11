import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../content/models.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/progress_store.dart';
import '../../widgets/common.dart';
import 'lesson_screen.dart';

class UnitsScreen extends StatelessWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    final arabic = context.l10n.isArabic;
    return AppPage(
      title: context.tr('lessons'),
      colour: AppColors.grass,
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) => LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 900 ? 3 : (c.maxWidth > 560 ? 2 : 1);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              mainAxisExtent: 150,
            ),
            itemCount: units.length,
            itemBuilder: (context, i) {
              final u = units[i];
              final done = progress.unitCompletion(u.id);
              return Material(
                key: ValueKey('unit_${u.id}'),
                color: Color(u.colour),
                borderRadius: BorderRadius.circular(28),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => UnitScreen(unit: u))),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Text('${u.id}', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Color(u.colour))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('${context.tr('unit')} ${u.id}',
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                          EnglishContent(
                            child: Text(u.title, style: learningText(28, color: Colors.white)),
                          ),
                          if (arabic) Text(u.titleAr, style: const TextStyle(color: Colors.white, fontSize: 15)),
                          Text('${context.tr('pages')} ${u.firstPage}–${u.lastPage}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: done,
                              minHeight: 8,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ]),
                      ),
                      if (done >= 1) const Icon(Icons.verified_rounded, color: Colors.white, size: 34),
                    ]),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class UnitScreen extends StatelessWidget {
  const UnitScreen({super.key, required this.unit});
  final Unit unit;

  String _kindLabel(BuildContext context, Lesson l) => switch (l.kind) {
        LessonKind.project => context.tr('project'),
        LessonKind.story => context.tr('story'),
        _ => '${context.tr('lesson')} ${l.number}',
      };

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).progress;
    final colour = Color(unit.colour);
    return AppPage(
      title: '${context.tr('unit')} ${unit.id} · ${context.l10n.isArabic ? unit.titleAr : unit.title}',
      colour: colour,
      body: ListenableBuilder(
        listenable: progress,
        builder: (context, _) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: unit.lessons.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final l = unit.lessons[i];
            final p = progress.lesson(l.id);
            final icon = switch (l.kind) {
              LessonKind.project => Icons.content_cut_rounded,
              LessonKind.story => Icons.auto_stories_rounded,
              _ => l.letters.isNotEmpty ? Icons.abc_rounded : Icons.school_rounded,
            };
            return Material(
              key: ValueKey('lesson_${l.id}'),
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              elevation: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: l))),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colour.withValues(alpha: 0.15),
                      child: l.letters.isNotEmpty
                          ? EnglishContent(child: Text(l.letters.join(), style: learningText(26, color: colour)))
                          : Icon(icon, color: colour, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_kindLabel(context, l), style: TextStyle(color: colour, fontWeight: FontWeight.w800)),
                        EnglishContent(child: Text(l.title, style: learningText(20))),
                        Text('${context.tr('page')} ${l.pages.join(', ')}',
                            style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                      ]),
                    ),
                    if (p.status == LessonStatus.completed)
                      StarRow(stars: p.stars, size: 22)
                    else if (p.status == LessonStatus.inProgress)
                      Pill(text: context.tr('inProgress'), colour: AppColors.orange)
                    else
                      const Icon(Icons.chevron_right_rounded, size: 30, color: AppColors.inkSoft),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
