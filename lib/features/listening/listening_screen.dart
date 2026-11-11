import 'package:material_ui/material_ui.dart';

import '../../content/book_data.dart';
import '../../content/models.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'listen_repeat_screen.dart';
import 'script_player.dart';

/// All listening material from the textbook, grouped by unit.
class ListeningScreen extends StatelessWidget {
  const ListeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arabic = context.l10n.isArabic;
    final seen = <Script>{};
    return AppPage(
      title: context.tr('listening'),
      colour: AppColors.teal,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Panel(
            child: Row(children: [
              const Icon(Icons.record_voice_over_rounded, color: AppColors.teal, size: 36),
              const SizedBox(width: 12),
              Expanded(child: Text(context.tr('speakingNote'), style: const TextStyle(fontSize: 15))),
              FilledButton(
                key: const ValueKey('openListenRepeat'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ListenRepeatScreen(title: context.tr('listenAndSay'), items: listenRepeatDefault()))),
                child: Text(context.tr('play')),
              ),
            ]),
          ),
          for (final u in units) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
              child: Text('${context.tr('unit')} ${u.id} · ${arabic ? u.titleAr : u.title}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(u.colour))),
            ),
            for (final l in u.lessons)
              for (final s in l.scripts)
                if (seen.add(s))
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: Color(u.colour).withValues(alpha: 0.15),
                        child: Icon(scriptKindIcon(s.kind), color: Color(u.colour)),
                      ),
                      title: EnglishContent(child: Text(s.title, style: learningText(19))),
                      subtitle: Text(
                          '${scriptKindLabel(s.kind)}${s.track != null ? ' · Track ${s.track}' : ''} · ${context.tr('page')} ${l.page}'),
                      trailing: const Icon(Icons.play_circle_fill_rounded, color: AppColors.teal, size: 36),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ScriptPlayerScreen(script: s, bookPage: l.page, colour: Color(u.colour)))),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
