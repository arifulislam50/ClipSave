import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_logo.dart';

/// Full-screen brand splash shown on every app start.
///
/// It never reads the clipboard. [initialize] (settings + opening the
/// database) and [background] (ads consent / SDK start) begin after the
/// first frame. Navigation to [next] happens once [initialize] has finished
/// (or failed) AND [AppInfo.splashMinDuration] has passed, or at
/// [AppInfo.splashMaxDuration] at the latest, while anything slow continues
/// in the background. [background] work is never awaited.
///
/// Layout: one Column, centred horizontally and vertically: logo (156 wide),
/// 28, "Copy Box", 8, tagline, 32, progress bar, 14, footer.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.next,
    this.initialize,
    this.background = const [],
  });

  final WidgetBuilder next;
  final Future<void> Function()? initialize;
  final List<Future<void> Function()> background;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  AnimationController? _progress;
  AnimationController? _logoFade;
  Animation<double>? _logoOpacity;
  bool _started = false;
  bool _reduceMotion = false;
  bool _minElapsed = false;
  bool _initDone = false;
  bool _navigated = false;
  Timer? _minTimer;
  Timer? _maxTimer;

  static const Color _ink = AppColors.onPrimary;
  static const double logoWidth = 156;
  static const Duration _logoFadeDuration = Duration(milliseconds: 600);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    final minimum = _reduceMotion ? AppInfo.reducedMotionSplashDuration : AppInfo.splashMinDuration;
    if (!_reduceMotion) {
      _progress = AnimationController(vsync: this, duration: AppInfo.splashDuration)..forward();
      _logoFade = AnimationController(vsync: this, duration: _logoFadeDuration)..forward();
      _logoOpacity = CurvedAnimation(parent: _logoFade!, curve: Curves.easeOut);
    }
    _minTimer = Timer(minimum, () {
      _minElapsed = true;
      _maybeContinue();
    });
    _maxTimer = Timer(AppInfo.splashMaxDuration, _continue);
    // Start work after the first frame so it never delays it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWork());
  }

  void _startWork() {
    for (final task in widget.background) {
      unawaited(Future<void>.sync(task).catchError((Object _) {}));
    }
    Future<void>.sync(() => widget.initialize?.call()).catchError((Object _) {
      // Initialisation problems must never trap the user on the splash.
    }).whenComplete(() {
      _initDone = true;
      _maybeContinue();
    });
  }

  void _maybeContinue() {
    if (_minElapsed && _initDone) _continue();
  }

  void _continue() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _minTimer?.cancel();
    _maxTimer?.cancel();
    unawaited(Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, _, __) => widget.next(context),
        transitionDuration:
            _reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ));
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _maxTimer?.cancel();
    _progress?.dispose();
    _logoFade?.dispose();
    super.dispose();
  }

  Widget _progressBar() {
    Widget bar(double value) => ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            backgroundColor: const Color.fromRGBO(45, 52, 54, 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(_ink),
          ),
        );
    final controller = _progress;
    return Semantics(
      label: 'Loading',
      child: SizedBox(
        width: 120,
        height: 4,
        child: controller == null
            ? bar(1) // Reduced motion: static bar, no animation.
            : AnimatedBuilder(
                animation: controller,
                builder: (_, __) => bar(controller.value),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const logo = AppLogo.artwork(
      width: logoWidth,
      foreground: Colors.white,
      lineColor: AppColors.primary,
      semanticLabel: null,
    );
    final opacity = _logoOpacity;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (opacity == null)
                logo
              else
                FadeTransition(opacity: opacity, child: logo),
              const SizedBox(height: 28),
              const Text(
                'Copy Box',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: _ink),
              ),
              const SizedBox(height: 8),
              const Text(
                'Save everything you copy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _ink),
              ),
              const SizedBox(height: 32),
              _progressBar(),
              const SizedBox(height: 14),
              const Text(
                'Your clips stay on your device',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
