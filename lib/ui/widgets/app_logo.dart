import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Logo geometry on a 108 x 108 grid. Kept in sync with tool/generate_logo.py,
/// which generates the launcher icon, tile glyph and splash icon.
class LogoGeometry {
  LogoGeometry._();

  static const double grid = 108;
  static const double cardRadius = 5;
  static const double stroke = 2.6;

  /// Zoom applied inside [AppLogo] so the stack fills the tile nicely.
  static const double zoom = 1.25;

  /// Tile corner radius as a fraction of the logo size.
  static const double tileRadius = 0.24;

  /// Back, middle, front.
  static const List<Rect> cards = [
    Rect.fromLTRB(40, 29, 84, 57),
    Rect.fromLTRB(32, 40, 76, 68),
    Rect.fromLTRB(24, 51, 68, 79),
  ];
  static const List<double> opacities = [0.4, 0.7, 1.0];

  /// Text lines on the front card.
  static const List<(Offset, Offset)> lines = [
    (Offset(31, 60), Offset(61, 60)),
    (Offset(31, 67), Offset(61, 67)),
    (Offset(31, 73), Offset(47, 73)),
  ];
}

/// The Copy Box logo: three stacked rounded cards.
///
/// With a [background] it draws a rounded tile (corner radius 24% of [size]).
/// With `background: null` it draws only the cards, for use on a coloured
/// surface (the splash screen); the card lines then use [lineColor].
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.background = AppColors.primary,
    this.foreground = Colors.white,
    this.lineColor,
    this.semanticLabel = 'Copy Box logo',
  });

  final double size;
  final Color? background;
  final Color foreground;

  /// Defaults to [background], or brand pink when there is no background.
  final Color? lineColor;

  /// Null hides the logo from screen readers (when a title is next to it).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final logo = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: LogoPainter(
          background: background,
          foreground: foreground,
          lineColor: lineColor ?? background ?? AppColors.primary,
        ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: logo);
    return Semantics(label: semanticLabel, image: true, child: logo);
  }
}

class LogoPainter extends CustomPainter {
  const LogoPainter({
    required this.background,
    required this.foreground,
    required this.lineColor,
  });

  final Color? background;
  final Color foreground;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (background != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(side * LogoGeometry.tileRadius),
        ),
        Paint()..color = background!,
      );
    }

    final scale = side / LogoGeometry.grid * LogoGeometry.zoom;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-LogoGeometry.grid / 2, -LogoGeometry.grid / 2);

    for (var i = 0; i < LogoGeometry.cards.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          LogoGeometry.cards[i],
          const Radius.circular(LogoGeometry.cardRadius),
        ),
        Paint()
          ..color = foreground.withValues(
              alpha: foreground.a * LogoGeometry.opacities[i]),
      );
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = LogoGeometry.stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final (from, to) in LogoGeometry.lines) {
      canvas.drawLine(from, to, linePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LogoPainter oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.foreground != foreground ||
      oldDelegate.lineColor != lineColor;
}
