import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'ads/ads_service.dart';
import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'state/clips_controller.dart';
import 'state/settings_controller.dart';
import 'ui/root_shell.dart';
import 'ui/screens/splash_screen.dart';

/// Global messenger so controller messages can show snackbars anywhere.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class CopyBoxApp extends StatelessWidget {
  const CopyBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsController, ThemeMode>((s) => s.themeMode);
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // Transparent status/navigation bars: light icons in dark mode, dark
      // icons in light mode. (App bars and the pink splash set their own.)
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.overlayStyle(Theme.of(context).brightness),
        child: child ?? const SizedBox.shrink(),
      ),
      // The splash waits (min 1.5 s, max 3 s) for settings + database open,
      // run in parallel. Ads consent + Mobile Ads start in the background after
      // the first frame and are never awaited; banners load only on History.
      home: SplashScreen(
        initialize: () => Future.wait<void>([
          context.read<SettingsController>().load(),
          context.read<ClipsController>().warmUp(),
        ]),
        background: [AdsService.instance.initialize],
        next: (_) => const RootShell(),
      ),
    );
  }
}
