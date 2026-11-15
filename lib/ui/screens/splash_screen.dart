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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _progress;
  bool _started = false;
  bool _reduceMotion = false;

  static const Color _ink = AppColors.onPrimary;

  /// Width the three-card stack should occupy on screen.
  static const double _stackWidth = 156;

  /// AppLogo size whose card stack is [_stackWidth] wide (cards span 60 of 108 grid units, zoomed 1.25x).
  static const double _logoSize =
      _stackWidth * LogoGeometry.grid / (60 * LogoGeometry.zoom);

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.primary,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              const AppLogo(
                size: _logoSize,
                background: null,
                foreground: Colors.white,
                lineColor: AppColors.primary,
                semanticLabel: null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Copy Box',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: _ink),
              ),
              const SizedBox(height: 6),
              const Text(
                'Save everything you copy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _ink),
              ),
              const Spacer(flex: 4),
              _progressBar(),
              const SizedBox(height: 16),
              const Text(
                'Your clips stay on your device',
                style: TextStyle(fontSize: 13, color: _ink),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
