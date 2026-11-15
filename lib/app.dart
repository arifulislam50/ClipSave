import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'ads/ads_service.dart';
import 'core/constants.dart';
import 'core/theme/app_theme.dart';
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
      // Consent (UMP) and Mobile Ads initialisation run during the splash.
      // They never touch the clipboard or the clip database.
      home: SplashScreen(
        initialize: AdsService.instance.initialize,
        next: (_) => const RootShell(),
      ),
    );
  }
}
