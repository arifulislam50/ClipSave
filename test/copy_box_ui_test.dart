import 'package:clipsave/core/ad_config.dart';
import 'package:clipsave/core/constants.dart';
import 'package:clipsave/core/theme/app_theme.dart';
import 'package:clipsave/ui/screens/clip_editor_screen.dart';
import 'package:clipsave/ui/screens/splash_screen.dart';
import 'package:clipsave/ui/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

    test('light palette', () {
      final c = AppTheme.light().extension<CopyBoxColors>()!;
      expect(c.tint, const Color(0xFFFFE3EE));
      expect(c.background, const Color(0xFFFFFAFC));
      expect(c.border, const Color(0xFFF3DCE6));
      expect(c.link, const Color(0xFFB01F63));
      expect(c.star, const Color(0xFFFDCB6E));
      expect(AppTheme.folderColors.first, const Color(0xFFFD79A8));
    });
  });

  group('splash', () {
    testWidgets('shows brand, waits for timer AND initialisation, then navigates',
        (tester) async {
      var initDone = false;
      await tester.pumpWidget(_host(SplashScreen(
        initialize: () async {
          await Future<void>.delayed(const Duration(seconds: 7));
          initDone = true;
        },
        next: (_) => const Text('HOME'),
      )));
      expect(find.text('Copy Box'), findsOneWidget);
      expect(find.text('Save everything you copy'), findsOneWidget);
      expect(find.text('Your clips stay on your device'), findsOneWidget);

      await tester.pump(AppInfo.splashDuration); // timer done, init not yet
      await tester.pump();
      expect(find.text('HOME'), findsNothing);

      await tester.pump(const Duration(seconds: 2)); // init finishes
      await tester.pumpAndSettle();
      expect(initDone, isTrue);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('a failing initialisation never traps the user', (tester) async {
      await tester.pumpWidget(_host(SplashScreen(
        initialize: () async => throw StateError('consent failed'),
        next: (_) => const Text('HOME'),
      )));
      await tester.pump(AppInfo.splashDuration);
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('reduced motion: 1 second, static progress bar', (tester) async {
      await tester.pumpWidget(_host(
        SplashScreen(next: (_) => const Text('HOME')),
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
    await tester.pump(AppInfo.splashDuration);
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
