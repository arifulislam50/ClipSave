import 'package:flutter/material.dart';

/// Copy Box brand colours.
///
/// Contrast (WCAG): text on primary uses #2D3436 (5.1:1) because white on
/// #FD79A8 is only 2.5:1. Link colour #B01F63 is 5.4:1 on the light tint.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFD79A8);
  static const Color onPrimary = Color(0xFF2D3436);
  static const Color tint = Color(0xFFFFE3EE);
  static const Color background = Color(0xFFFFFAFC);
  static const Color text = Color(0xFF2D3436);
  static const Color muted = Color(0xFF6B6470);
  static const Color border = Color(0xFFF3DCE6);
  static const Color link = Color(0xFFB01F63);
  static const Color star = Color(0xFFFDCB6E);
  static const Color white = Color(0xFFFFFFFF);
}

/// Palette values that are not part of [ColorScheme], for light and dark.
@immutable
class CopyBoxColors extends ThemeExtension<CopyBoxColors> {
  const CopyBoxColors({
    required this.tint,
    required this.background,
    required this.card,
    required this.text,
    required this.muted,
    required this.border,
    required this.link,
    required this.star,
  });

  /// Light pink fill for cards, chips, the search field and the nav indicator.
  final Color tint;
  final Color background;
  final Color card;
  final Color text;
  final Color muted;

  /// Hairline borders.
  final Color border;

  /// Text links and the copy icon.
  final Color link;

  /// Favourite star.
  final Color star;

  static const CopyBoxColors light = CopyBoxColors(
    tint: AppColors.tint,
    background: AppColors.background,
    card: AppColors.white,
    text: AppColors.text,
    muted: AppColors.muted,
    border: AppColors.border,
    link: AppColors.link,
    star: AppColors.star,
  );

  static const CopyBoxColors dark = CopyBoxColors(
    tint: Color(0xFF4A2536),
    background: Color(0xFF1A1418),
    card: Color(0xFF241C21),
    text: Color(0xFFECE6EA),
    muted: Color(0xFFB8ACB3),
    border: Color(0xFF3A2A32),
    link: Color(0xFFFF9EC4),
    star: AppColors.star,
  );

  static CopyBoxColors of(BuildContext context) =>
      Theme.of(context).extension<CopyBoxColors>() ?? light;

  @override
  CopyBoxColors copyWith({
    Color? tint,
    Color? background,
    Color? card,
    Color? text,
    Color? muted,
    Color? border,
    Color? link,
    Color? star,
  }) {
    return CopyBoxColors(
      tint: tint ?? this.tint,
      background: background ?? this.background,
      card: card ?? this.card,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      link: link ?? this.link,
      star: star ?? this.star,
    );
  }

  @override
  CopyBoxColors lerp(ThemeExtension<CopyBoxColors>? other, double t) {
    if (other is! CopyBoxColors) return this;
    return CopyBoxColors(
      tint: Color.lerp(tint, other.tint, t)!,
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      link: Color.lerp(link, other.link, t)!,
      star: Color.lerp(star, other.star, t)!,
    );
  }
}

/// Material 3 light and dark themes for Copy Box.
/// No custom font: google_fonts is not a dependency, so the platform default is used.
class AppTheme {
  AppTheme._();

  static const Color seed = AppColors.primary;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isLight = b == Brightness.light;
    final palette = isLight ? CopyBoxColors.light : CopyBoxColors.dark;

    final base = ColorScheme.fromSeed(seedColor: const Color(0xFFFD79A8), brightness: b)
        .copyWith(primary: const Color(0xFFFD79A8), onPrimary: const Color(0xFF2D3436));
    final scheme = base.copyWith(
      surface: palette.background,
      onSurface: palette.text,
      onSurfaceVariant: palette.muted,
      outlineVariant: palette.border,
      primaryContainer: palette.tint,
      onPrimaryContainer: palette.text,
      secondaryContainer: palette.tint,
      onSecondaryContainer: palette.text,
      surfaceContainerLowest: palette.card,
      surfaceContainerLow: palette.card,
    );

    final roundedButtons = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        shape: roundedButtons,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(64, 44),
          shape: roundedButtons,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.link,
          minimumSize: const Size(44, 44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.link,
          minimumSize: const Size(64, 44),
          shape: roundedButtons,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.tint,
        selectedColor: AppColors.primary,
        disabledColor: palette.tint,
        // State-dependent so selected (pink) chips always get #2D3436, also in dark mode.
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected) ? AppColors.onPrimary : palette.text),
        ),
        checkmarkColor: AppColors.onPrimary,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? AppColors.primary : null),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? AppColors.onPrimary : palette.text),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.onPrimary : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : null),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.tint,
        elevation: 0,
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: palette.text)),
        labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: palette.text, fontSize: 12, fontWeight: FontWeight.w500)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: palette.muted,
      ),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.tint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Palette used for folder colours. The first entry is the brand pink.
  static const List<Color> folderColors = [
    Color(0xFFFD79A8),
    Color(0xFF00897B),
    Color(0xFFF4511E),
    Color(0xFF8E24AA),
    Color(0xFFFFB300),
    Color(0xFF039BE5),
    Color(0xFFD81B60),
    Color(0xFF7CB342),
  ];
}
