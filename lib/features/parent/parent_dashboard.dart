import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../data/progress_store.dart';
import '../../widgets/common.dart';
import '../vocabulary/vocabulary_screen.dart';

/// A simple grown-up check (multiplication question) before the parent area.
Future<bool> showParentGate(BuildContext context, {math.Random? random}) async {
  final rnd = random ?? math.Random();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => _ParentGateDialog(a: 3 + rnd.nextInt(7), b: 3 + rnd.nextInt(7)),
  );
  return ok ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog({required this.a, required this.b});
  final int a;
  final int b;

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final _controller = TextEditingController();
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (int.tryParse(_controller.text.trim()) == widget.a * widget.b) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('parentGate')),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(context.tr('parentGateHint')),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${widget.a} × ${widget.b} = ?',
                key: const ValueKey('gateQuestion'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          ),
          TextField(
            key: const ValueKey('gateAnswer'),
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: context.tr('answer'), errorText: _error ? context.tr('wrongAnswer') : null),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(context.tr('cancel'))),
        FilledButton(key: const ValueKey('gateOpen'), onPressed: _submit, child: Text(context.tr('open'))),
      ],
    );
  }
}

const Map<String, String> activityNames = {
  'lesson': 'Lesson practice',
  'quiz': 'Quizzes',
  'alphabet': 'Alphabet',
  'trace': 'Tracing',
  'vocab': 'Vocabulary',
  'revision': 'Revision',
  'listen': 'Listening',
  'speak': 'Listen and repeat',
  'drawing': 'Drawing',
  'game_word_picture': 'Game: word and picture',
  'game_case': 'Game: big and small letters',
  'game_listen': 'Game: listen and choose',
  'game_missing_letter': 'Game: missing letter',
  'game_spell': 'Game: arrange letters',
  'game_colours': 'Game: colours',
  'game_count': 'Game: counting',
  'game_animals': 'Game: animals',
  'game_classroom': 'Game: classroom objects',
  'game_memory': 'Game: memory cards',
  'game_drag': 'Game: drag and drop',
};

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  String _duration(int seconds) {
    final m = seconds ~/ 60;
    if (m < 60) return '$m min';
    return '${m ~/ 60} h ${m % 60} min';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppScope.of(context).progress;
    final arabic = context.l10n.isArabic;
    final now = DateTime.now();
    final week = [for (var i = 6; i >= 0; i--) now.subtract(Duration(days: i))];
    final maxSecs = week.map(p.secondsOn).fold<int>(60, math.max);
    final quizzes = p.results.where((r) => r.kind == 'quiz').toList().reversed.take(10).toList();
    final weakKinds = p.averageByKind().entries.where((e) => e.value < 0.6).toList()..sort((a, b) => a.value.compareTo(b.value));
    final weakTopics = p.accuracyByTopic().entries.where((e) => e.value < 0.7).toList()..sort((a, b) => a.value.compareTo(b.value));
    final unitsDone = units.where((u) => p.isUnitComplete(u.id)).length;

    Widget stat(String label, String value, IconData icon, Color c) => SizedBox(
          width: 170,
          child: Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: c, size: 30),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
            ]),
          ),
        );

    return AppPage(
      title: context.tr('parents'),
      colour: const Color(0xFF6C7A93),
      body: ListenableBuilder(
        listenable: p,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            stat(context.tr('overall'), '${(p.overallCompletion * 100).round()}%', Icons.donut_large_rounded, AppColors.primary),
            stat(context.tr('unitsDone'), '$unitsDone / ${units.length}', Icons.layers_rounded, AppColors.grape),
            stat(context.tr('lessonsDone'), '${p.completedLessonCount} / ${allLessons.length}', Icons.school_rounded, AppColors.grass),
            stat(context.tr('timeSpent'), _duration(p.totalSeconds), Icons.timer_rounded, AppColors.orange),
            stat(context.tr('wordsMastered'), '${p.masteredWordCount} / ${vocabularyById.length}', Icons.abc_rounded, AppColors.berry),
            stat(context.tr('stars'), '${p.totalStars}', Icons.star_rounded, AppColors.sunshine),
          ]),
          const SizedBox(height: 18),
          Text(context.tr('timeSpent'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Panel(
            child: SizedBox(
              height: 140,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final d in week)
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text('${p.secondsOn(d) ~/ 60}', style: const TextStyle(fontSize: 11)),
                      Container(
                        height: 90 * p.secondsOn(d) / maxSecs + 2,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(height: 4),
                      Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                    ]),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          Text(context.tr('lessonsDone'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          for (final u in units)
            ListTile(
              dense: true,
              leading: Icon(p.isUnitComplete(u.id) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: p.isUnitComplete(u.id) ? AppColors.success : AppColors.inkSoft),
              title: Text('${context.tr('unit')} ${u.id}: ${arabic ? u.titleAr : u.title}'),
              trailing: Text(
                  '${u.lessons.where((l) => p.lesson(l.id).status == LessonStatus.completed).length}/${u.lessons.length}'),
            ),
          const SizedBox(height: 12),
          Text(context.tr('quizResults'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (quizzes.isEmpty) Text(context.tr('noData')),
          for (final q in quizzes)
            ListTile(
              dense: true,
              leading: const Icon(Icons.quiz_rounded),
              title: Text(q.ref == 'challenge' ? context.tr('challenge') : '${context.tr('unitQuiz')} ${q.unitId ?? ''}'),
              subtitle: Text('${q.createdAt.day}/${q.createdAt.month}/${q.createdAt.year}'),
              trailing: Text('${q.score}/${q.total} (${(q.ratio * 100).round()}%)',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          const SizedBox(height: 12),
          Text(context.tr('weakAreas'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (weakKinds.isEmpty && weakTopics.isEmpty) Text(context.tr('noData')),
          for (final e in weakTopics)
            ListTile(
              dense: true,
              leading: const Icon(Icons.trending_down_rounded, color: AppColors.coral),
              title: Text(arabic ? (topicArabic[e.key] ?? e.key) : e.key),
              trailing: Text('${(e.value * 100).round()}%'),
            ),
          for (final e in weakKinds)
            ListTile(
              dense: true,
              leading: const Icon(Icons.trending_down_rounded, color: AppColors.orange),
              title: Text(activityNames[e.key] ?? e.key),
              trailing: Text('${(e.value * 100).round()}%'),
            ),
          if (p.weakWords.isNotEmpty)
            EnglishContent(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final id in p.weakWords.take(15)) Chip(label: Text(vocabularyById[id]?.text ?? id)),
                ]),
              ),
            ),
          const SizedBox(height: 24),
          Text(context.tr('offlineNote'), style: const TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('resetProgress'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.coral),
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  content: Text(context.tr('resetConfirm')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('delete'))),
                  ],
                ),
              );
              if (yes == true) await p.resetAll();
            },
            icon: const Icon(Icons.delete_forever_rounded),
            label: Text(context.tr('resetProgress')),
          ),
        ]),
      ),
    );
  }
}
