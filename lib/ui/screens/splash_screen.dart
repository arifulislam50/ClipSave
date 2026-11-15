import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_logo.dart';

/// Full-screen brand splash shown on every app start.
///
/// It never reads the clipboard or touches the database: [initialize] must
/// only do work that is safe before the history screen exists. Navigation to
/// [next] happens once BOTH the splash duration has elapsed AND [initialize]
/// has finished (or failed).
///
/// Layout: one Column, centred horizontally and vertically: logo (156 wide),
/// 28, "Copy Box", 8, tagline, 32, progress bar, 14, footer.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.next,
    this.initialize,
  });

  final WidgetBuilder next;
  final Future<void> Function()? initialize;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  AnimationController? _progress;
  AnimationController? _logoFade;
  Animation<double>? _logoOpacity;
  bool _started = false;
  bool _reduceMotion = false;

  static const Color _ink = AppColors.onPrimary;
  static const double logoWidth = 156;
  static const Duration _logoFadeDuration = Duration(milliseconds: 600);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = _reduceMotion
        ? AppInfo.reducedMotionSplashDuration
        : AppInfo.splashDuration;
    if (!_reduceMotion) {
      _progress = AnimationController(vsync: this, duration: duration)..forward();
      _logoFade = AnimationController(vsync: this, duration: _logoFadeDuration)..forward();
      _logoOpacity = CurvedAnimation(parent: _logoFade!, curve: Curves.easeOut);
    }
    unawaited(_run(duration));
  }

  Future<void> _run(Duration duration) async {
    Future<void> init() async {
      try {
        await widget.initialize?.call();
      } catch (_) {
        // Initialisation problems must never trap the user on the splash.
      }
    }

    await Future.wait<void>([Future<void>.delayed(duration), init()]);
    if (!mounted) return;
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
