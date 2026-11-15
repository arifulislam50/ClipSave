import 'package:clipsave/core/ad_config.dart';
import 'package:clipsave/core/constants.dart';
import 'package:clipsave/core/theme/app_theme.dart';
import 'package:clipsave/data/repositories/settings_repository.dart';
import 'package:clipsave/ui/screens/clip_editor_screen.dart';
import 'package:clipsave/ui/screens/splash_screen.dart';
import 'package:clipsave/ui/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child,
        ),
      ),
    );

void main() {
  group('theme', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      test('${theme.brightness.name}: primary #FD79A8, text on primary #2D3436', () {
        expect(theme.colorScheme.primary, const Color(0xFFFD79A8));
        expect(theme.colorScheme.onPrimary, const Color(0xFF2D3436));
        expect(theme.extension<CopyBoxColors>(), isNotNull);
      });
    }

    test('dark scheme: pure black, neutral surfaces, no pink tint', () {
      final c = AppTheme.dark().colorScheme;
      expect(c.surface, const Color(0xFF000000));
      expect(c.surfaceContainerLowest, const Color(0xFF000000));
      expect(c.surfaceContainerLow, const Color(0xFF0B0B0D));
      expect(c.surfaceContainer, const Color(0xFF121214));
      expect(c.surfaceContainerHigh, const Color(0xFF1A1A1D));
      expect(c.surfaceContainerHighest, const Color(0xFF222226));
      expect(c.surfaceTint, const Color(0x00000000));
      expect(c.onSurface, const Color(0xFFF5F5F7));
      expect(c.onSurfaceVariant, const Color(0xFFA1A1AA));
      expect(c.outline, const Color(0xFF3A3A40));
      expect(c.outlineVariant, const Color(0xFF26262A));
      expect(AppTheme.dark().scaffoldBackgroundColor, const Color(0xFF000000));
      final x = AppTheme.dark().extension<CopyBoxColors>()!;
      expect(x.card, const Color(0xFF121214));
      expect(x.fill, const Color(0xFF1E1E22));
      expect(x.link, const Color(0xFFFD79A8));
      expect(x.tipBackground, const Color(0xFF2A2110));
      expect(x.tipForeground, const Color(0xFFFDCB6E));
    });

    test('light scheme: white with neutral greys', () {
      final c = AppTheme.light().colorScheme;
      expect(c.surface, const Color(0xFFFFFFFF));
      expect(c.surfaceContainer, const Color(0xFFF6F6F7));
      expect(c.surfaceContainerHigh, const Color(0xFFEFEFF1));
      expect(c.outlineVariant, const Color(0xFFE4E4E7));
      expect(c.onSurface, const Color(0xFF1B1B1F));
      expect(AppTheme.folderColors.first, const Color(0xFFFD79A8));
    });

    test('no pale pink anywhere in either scheme', () {
      const pale = [Color(0xFFFFE3EE), Color(0xFFFFFAFC), Color(0xFFFFF1D6)];
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final c = theme.colorScheme;
        for (final role in [
          c.surface, c.surfaceContainerLowest, c.surfaceContainerLow, c.surfaceContainer,
          c.surfaceContainerHigh, c.surfaceContainerHighest, c.primaryContainer,
          c.secondaryContainer, c.outlineVariant,
        ]) {
          expect(pale.contains(role), isFalse);
        }
      }
    });

    test('status/navigation bars: transparent, icons follow brightness', () {
      final dark = AppTheme.overlayStyle(Brightness.dark);
      expect(dark.statusBarIconBrightness, Brightness.light);
      expect(dark.statusBarColor, const Color(0x00000000));
      expect(dark.systemNavigationBarColor, const Color(0x00000000));
      expect(AppTheme.overlayStyle(Brightness.light).statusBarIconBrightness, Brightness.dark);
    });
  });

  group('theme mode default', () {
    test('dark when nothing saved; saved choices restored', () async {
      SharedPreferences.setMockInitialValues({});
      expect((await SettingsRepository.create()).themeMode, ThemeMode.dark);
      for (final mode in ThemeMode.values) {
        SharedPreferences.setMockInitialValues({'theme_mode': mode.name});
        expect((await SettingsRepository.create()).themeMode, mode);
      }
    });
  });

  group('splash timing (min 1.5 s, max 3 s)', () {
    test('constants', () {
      expect(AppInfo.splashDuration, const Duration(seconds: 2));
      expect(AppInfo.splashMinDuration, const Duration(milliseconds: 1500));
      expect(AppInfo.splashMaxDuration, const Duration(seconds: 3));
      expect(AppInfo.reducedMotionSplashDuration, const Duration(seconds: 1));
    });

    testWidgets('fast initialisation: leaves as soon as 1.5 s have passed', (tester) async {
      await tester.pumpWidget(_host(SplashScreen(
        initialize: () async {},
        next: (_) => const Text('HOME'),
      )));
      expect(find.text('Copy Box'), findsOneWidget);
      expect(find.text('Save everything you copy'), findsOneWidget);
      expect(find.text('Your clips stay on your device'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1400));
      expect(find.text('HOME'), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('slow initialisation: leaves at 3 s, work continues in background', (tester) async {
      var initDone = false;
      await tester.pumpWidget(_host(SplashScreen(
        initialize: () async {
          await Future<void>.delayed(const Duration(seconds: 7));
          initDone = true;
        },
        next: (_) => const Text('HOME'),
      )));
      await tester.pump(const Duration(milliseconds: 2900));
      expect(find.text('HOME'), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(initDone, isFalse);
      await tester.pump(const Duration(seconds: 5)); // let the slow work finish
      expect(initDone, isTrue);
    });

    testWidgets('background work is started but never awaited', (tester) async {
      var started = false;
      await tester.pumpWidget(_host(SplashScreen(
        initialize: () async {},
        background: [
          () async {
            started = true;
            await Future<void>.delayed(const Duration(seconds: 30));
          },
        ],
        next: (_) => const Text('HOME'),
      )));
      await tester.pump(); // first frame -> work starts
      expect(started, isTrue);
      await tester.pump(AppInfo.splashMinDuration);
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('a failing initialisation never traps the user', (tester) async {
      await tester.pumpWidget(_host(SplashScreen(
        initialize: () async => throw StateError('consent failed'),
        next: (_) => const Text('HOME'),
      )));
      await tester.pump(AppInfo.splashMinDuration);
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('reduced motion: 1 second, static progress bar', (tester) async {
      await tester.pumpWidget(_host(
        SplashScreen(initialize: () async {}, next: (_) => const Text('HOME')),
        reduceMotion: true,
      ));
      final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bar.value, 1.0);
      await tester.pump(AppInfo.reducedMotionSplashDuration);
      await tester.pump();
      await tester.pump();
      expect(find.text('HOME'), findsOneWidget);
    });
  });

  testWidgets('splash content is centred horizontally and vertically', (tester) async {
    await tester.pumpWidget(_host(SplashScreen(next: (_) => const Text('HOME'))));
    final screen = tester.getRect(find.byType(Scaffold));
    final logo = tester.getRect(find.byType(AppLogo));
    final footer = tester.getRect(find.text('Your clips stay on your device'));
    expect(logo.width, 156);
    for (final finder in [
      find.byType(AppLogo),
      find.text('Copy Box'),
      find.text('Save everything you copy'),
      find.byType(LinearProgressIndicator),
      find.text('Your clips stay on your device'),
    ]) {
      expect(tester.getCenter(finder).dx, closeTo(screen.center.dx, 0.5));
    }
    // The whole group (logo top .. footer bottom) is vertically centred.
    expect((logo.top + footer.bottom) / 2, closeTo(screen.center.dy, 0.5));
    // Gaps: logo->title 28, title->tagline 8, tagline->bar 32, bar->footer 14.
    final title = tester.getRect(find.text('Copy Box'));
    final tagline = tester.getRect(find.text('Save everything you copy'));
    final bar = tester.getRect(find.byType(LinearProgressIndicator));
    expect(title.top - logo.bottom, closeTo(28, 0.5));
    expect(tagline.top - title.bottom, closeTo(8, 0.5));
    expect(bar.top - tagline.bottom, closeTo(32, 0.5));
    expect(footer.top - bar.bottom, closeTo(14, 0.5));
    await tester.pump(AppInfo.splashMaxDuration);
    await tester.pumpAndSettle();
  });

  testWidgets('AppLogo paints at the requested size', (tester) async {
    await tester.pumpWidget(_host(const Center(child: AppLogo(size: 112))));
    expect(tester.getSize(find.byType(AppLogo)), const Size(112, 112));
    expect(find.bySemanticsLabel('Copy Box logo'), findsOneWidget);
  });

  test('editor counter formatting', () {
    expect(formatThousands(0), '0');
    expect(formatThousands(999), '999');
    expect(formatThousands(1000), '1,000');
    expect(formatThousands(100000), '100,000');
  });

  test('AdMob: Google test IDs are flagged until replaced', () {
    expect(AdConfig.androidAppId, 'ca-app-pub-3940256099942544~3347511713');
    expect(AdConfig.bannerAdUnitId, 'ca-app-pub-3940256099942544/9214589741');
    expect(AdConfig.usingTestIds, isTrue,
        reason: 'Update this test when you switch to your real AdMob IDs.');
  });
}
