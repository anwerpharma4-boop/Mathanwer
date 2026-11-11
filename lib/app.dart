import 'package:material_ui/material_ui.dart';

import 'app_scope.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';

class EnglishForIraqApp extends StatelessWidget {
  const EnglishForIraqApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      services: services,
      child: ListenableBuilder(
        listenable: services.settings,
        builder: (context, _) {
          final arabic = services.settings.languageCode == 'ar';
          return MaterialApp(
            title: 'English for Iraq',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.build(arabic: arabic),
            builder: (context, child) => Directionality(
              textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
