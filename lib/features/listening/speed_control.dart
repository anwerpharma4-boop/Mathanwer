import 'package:material_ui/material_ui.dart';

import '../../app_scope.dart';
import '../../core/l10n.dart';

/// Toggle between slow (0.75x) and normal playback.
class SpeedControl extends StatelessWidget {
  const SpeedControl({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final slow = settings.playbackRate < 0.95;
        return SegmentedButton<bool>(
          key: const ValueKey('speedControl'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: true,
              icon: const Icon(Icons.slow_motion_video_rounded),
              label: Text(context.tr('slow')),
            ),
            ButtonSegment(value: false, icon: const Icon(Icons.speed_rounded), label: Text(context.tr('normal'))),
          ],
          selected: {slow},
          onSelectionChanged: (s) => settings.setPlaybackRate(s.first ? 0.75 : 1.0),
        );
      },
    );
  }
}
