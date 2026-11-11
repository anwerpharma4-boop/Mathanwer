import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../content/book_data.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../services/british_voice.dart';
import '../../widgets/common.dart';
import '../parent/parent_dashboard.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  VoiceCheck? _voice;
  bool _checking = false;

  Future<void> _checkVoice() async {
    setState(() => _checking = true);
    final r = await AppScope.read(context).voice.check(refresh: true);
    if (mounted) {
      setState(() {
        _voice = r;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).settings;
    return AppPage(
      title: context.tr('settings'),
      colour: const Color(0xFF6C7A93),
      body: ListenableBuilder(
        listenable: s,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    key: const ValueKey('languageSelector'),
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('English')),
                      ButtonSegment(value: 'ar', label: Text('العربية')),
                    ],
                    selected: {s.languageCode},
                    onSelectionChanged: (v) => s.setLanguage(v.first),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The textbook and all English learning content always stay in English.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('voice'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.verified_rounded, color: AppColors.success),
                    title: Text(context.tr('voiceBundled')),
                    subtitle: const Text(
                      'en-GB · Piper neural voice "Cori" (UK English) · generated offline and bundled in the app.',
                    ),
                  ),
                  Row(
                    children: [
                      const Text('Test: ', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SpeakButton(text: 'Hello. I\'m Robbie.', size: 44),
                      const SizedBox(width: 8),
                      SpeakButton(text: 'Z', letterName: 'z', size: 44, colour: AppColors.orange),
                      const SizedBox(width: 8),
                      const SpeakButton(text: 'tomato', size: 44, colour: AppColors.grass),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('checkDeviceVoice'),
                    onPressed: _checking ? null : _checkVoice,
                    icon: _checking
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.record_voice_over_rounded),
                    label: Text(context.tr('voiceCheck')),
                  ),
                  if (_voice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _voice!.detail,
                        style: TextStyle(color: _voice!.available ? AppColors.success : AppColors.inkSoft),
                      ),
                    ),
                  const Text(
                    'The device voice is only used for text without a bundled recording, and only if a British English (en-GB) voice is installed for offline use. Other accents are never used.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.tr('playbackSpeed')}: ${s.playbackRate.toStringAsFixed(2)}×',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Slider(
                    key: const ValueKey('speedSlider'),
                    value: s.playbackRate,
                    min: 0.5,
                    max: 1.25,
                    divisions: 6,
                    label: '${s.playbackRate.toStringAsFixed(2)}×',
                    onChanged: s.setPlaybackRate,
                  ),
                  SwitchListTile(
                    key: const ValueKey('sfxSwitch'),
                    contentPadding: EdgeInsets.zero,
                    value: s.soundEffects,
                    onChanged: s.setSoundEffects,
                    title: Text(context.tr('soundEffects')),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${context.tr('dailyGoal')}: ${s.dailyGoal}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => s.setDailyGoal(s.dailyGoal - 1),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      IconButton(
                        onPressed: () => s.setDailyGoal(s.dailyGoal + 1),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: BigTile(
                key: const ValueKey('openParents'),
                title: context.tr('parents'),
                subtitle: context.tr('parentGate'),
                icon: Icons.family_restroom_rounded,
                colour: const Color(0xFF6C7A93),
                onTap: () async {
                  if (await showParentGate(context) && context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ParentDashboard()));
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('about'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text(
                    'Original textbook: English for Iraq – 1st Primary – Pupil\'s Book, by Jenny Quintana and Helen O\'Neill '
                    '(Garnet Education; Republic of Iraq, Ministry of Education). All $bookPageCount pages are shown unchanged.\n\n'
                    'Page numbers: in this book the PDF page index equals the printed page number on every page.\n\n'
                    'Interactive activities are a separate learning layer based on the book\'s words, letters, dialogues, songs and stories '
                    '(from the book\'s transcripts, pages 80–93). Pictures in activities are cropped from the original book pages. '
                    'The robot mascot is original app artwork.\n\n'
                    'Audio: British English (en-GB) speech generated with the open-source Piper voice "Cori" (trained on public-domain '
                    'LibriVox recordings) and bundled for offline use. The book\'s original CD recordings and songs are not included.\n\n'
                    'Fonts: Andika and Noto Kufi Arabic (SIL Open Font License).\n\n'
                    'Privacy: no accounts, no ads, no tracking, no internet needed. Progress is stored only on this device.',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
