import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Logo geometry on a 108 x 108 grid. Kept in sync with tool/generate_logo.py,
/// which generates the launcher icon, tile glyph and splash icon.
class LogoGeometry {
  LogoGeometry._();

  static const double grid = 108;

  /// The artwork is the original design scaled to 78% around (54,54): every
  /// corner is within 31 of the centre, so round launcher masks never clip it.
  static const double cardRadius = 3.9;
  static const double stroke = 2.0;

  /// Zoom applied inside [AppLogo] so the stack fills the tile nicely.
  static const double zoom = 1.25;

  /// Tile corner radius as a fraction of the logo size.
  static const double tileRadius = 0.24;

  /// Back, middle, front.
  static const List<Rect> cards = [
    Rect.fromLTWH(43.08, 34.5, 34.32, 21.84),
    Rect.fromLTWH(36.84, 43.08, 34.32, 21.84),
    Rect.fromLTWH(30.6, 51.66, 34.32, 21.84),
  ];

  /// Bounding box of the three cards (centred on 54,54).
  static const Rect bounds = Rect.fromLTRB(30.6, 34.5, 77.4, 73.5);
  static const List<double> opacities = [0.4, 0.7, 1.0];

  /// Text lines on the front card.
  static const List<(Offset, Offset)> lines = [
    (Offset(36.06, 58.68), Offset(59.46, 58.68)),
    (Offset(36.06, 64.14), Offset(59.46, 64.14)),
    (Offset(36.06, 68.82), Offset(48.54, 68.82)),
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
