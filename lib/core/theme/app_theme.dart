import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copy Box brand colours that are the same in light and dark.
///
/// Contrast (WCAG): text on primary uses #2D3436 (5.1:1) because white on
/// #FD79A8 is only 2.5:1.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFD79A8);
  static const Color onPrimary = Color(0xFF2D3436);
  static const Color star = Color(0xFFFDCB6E);
}

/// The few roles that [ColorScheme] has no slot for. Everything else comes
/// from `Theme.of(context).colorScheme` (surface, onSurface, onSurfaceVariant,
/// outlineVariant, ...).
@immutable
class CopyBoxColors extends ThemeExtension<CopyBoxColors> {
  const CopyBoxColors({
    required this.card,
    required this.fill,
    required this.link,
    required this.star,
    required this.tipBackground,
    required this.tipForeground,
    required this.tipBorder,
  });

  /// Cards and tiles (with a 1px `colorScheme.outlineVariant` border).
  final Color card;

  /// Search field, unselected chips, nav indicator, copy-button background.
  final Color fill;

  /// Text links, text buttons, copy icon, selected nav item.
  /// #FD79A8 on black (8.5:1). On white, pink text is only 2.5:1, so the light
  /// theme uses the deeper #B01F63 (6.5:1).
  final Color link;

  /// Favourite star.
  final Color star;

  /// Amber advisory ("tip") card.
  final Color tipBackground;
  final Color tipForeground;
  final Color tipBorder;

  static const CopyBoxColors dark = CopyBoxColors(
    card: Color(0xFF121214),
    fill: Color(0xFF1E1E22),
    link: AppColors.primary,
    star: AppColors.star,
    tipBackground: Color(0xFF2A2110),
    tipForeground: AppColors.star,
    tipBorder: Color(0xFF2A2110),
  );

  static const CopyBoxColors light = CopyBoxColors(
    card: Color(0xFFFFFFFF),
    fill: Color(0xFFEFEFF1),
    link: Color(0xFFB01F63),
    star: AppColors.star,
    tipBackground: Color(0xFFF6F6F7),
    tipForeground: Color(0xFF6B4A00),
    tipBorder: AppColors.star,
  );

  static CopyBoxColors of(BuildContext context) =>
      Theme.of(context).extension<CopyBoxColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  CopyBoxColors copyWith({
    Color? card,
    Color? fill,
    Color? link,
    Color? star,
    Color? tipBackground,
    Color? tipForeground,
    Color? tipBorder,
  }) {
    return CopyBoxColors(
      card: card ?? this.card,
      fill: fill ?? this.fill,
      link: link ?? this.link,
      star: star ?? this.star,
      tipBackground: tipBackground ?? this.tipBackground,
      tipForeground: tipForeground ?? this.tipForeground,
      tipBorder: tipBorder ?? this.tipBorder,
    );
  }

  @override
  CopyBoxColors lerp(ThemeExtension<CopyBoxColors>? other, double t) {
    if (other is! CopyBoxColors) return this;
    return CopyBoxColors(
      card: Color.lerp(card, other.card, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      link: Color.lerp(link, other.link, t)!,
      star: Color.lerp(star, other.star, t)!,
      tipBackground: Color.lerp(tipBackground, other.tipBackground, t)!,
      tipForeground: Color.lerp(tipForeground, other.tipForeground, t)!,
      tipBorder: Color.lerp(tipBorder, other.tipBorder, t)!,
    );
  }
}

/// Material 3 themes. Pink is used ONLY as the accent (primary): every
/// surface is neutral. Dark is pure black; light is white with neutral greys.
/// No custom font: google_fonts is not a dependency.
class AppTheme {
  AppTheme._();

  static const Color seed = AppColors.primary;

  // Built once and reused (MaterialApp rebuilds must not rebuild themes).
  static final ThemeData _light = _build(_lightScheme(), CopyBoxColors.light);
  static final ThemeData _dark = _build(_darkScheme(), CopyBoxColors.dark);

  static ThemeData light() => _light;
  static ThemeData dark() => _dark;

  /// fromSeed adds a pink tint to every surface role; each one is overridden
  /// here with a neutral value. (`ColorScheme.background` is deprecated in
  /// Flutter; `surface` is the background role, and the scaffold uses it.)
  static ColorScheme _darkScheme() {
    return ColorScheme.fromSeed(seedColor: const Color(0xFFFD79A8), brightness: Brightness.dark)
        .copyWith(
      primary: const Color(0xFFFD79A8),
      onPrimary: const Color(0xFF2D3436),
      surface: const Color(0xFF000000),
      surfaceDim: const Color(0xFF000000),
      surfaceBright: const Color(0xFF1A1A1D),
      surfaceContainerLowest: const Color(0xFF000000),
      surfaceContainerLow: const Color(0xFF0B0B0D),
      surfaceContainer: const Color(0xFF121214),
      surfaceContainerHigh: const Color(0xFF1A1A1D),
      surfaceContainerHighest: const Color(0xFF222226),
      surfaceTint: Colors.transparent,
      onSurface: const Color(0xFFF5F5F7),
      onSurfaceVariant: const Color(0xFFA1A1AA),
      outline: const Color(0xFF3A3A40),
      outlineVariant: const Color(0xFF26262A),
      primaryContainer: const Color(0xFF1E1E22),
      onPrimaryContainer: const Color(0xFFF5F5F7),
      secondaryContainer: const Color(0xFF1E1E22),
      onSecondaryContainer: const Color(0xFFF5F5F7),
      inverseSurface: const Color(0xFFE4E4E7),
      onInverseSurface: const Color(0xFF1B1B1F),
      inversePrimary: const Color(0xFFB01F63),
    );
  }

  static ColorScheme _lightScheme() {
    return ColorScheme.fromSeed(seedColor: const Color(0xFFFD79A8), brightness: Brightness.light)
        .copyWith(
      primary: const Color(0xFFFD79A8),
      onPrimary: const Color(0xFF2D3436),
      surface: const Color(0xFFFFFFFF),
      surfaceDim: const Color(0xFFEFEFF1),
      surfaceBright: const Color(0xFFFFFFFF),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF6F6F7),
      surfaceContainer: const Color(0xFFF6F6F7),
      surfaceContainerHigh: const Color(0xFFEFEFF1),
      surfaceContainerHighest: const Color(0xFFEFEFF1),
      surfaceTint: Colors.transparent,
      onSurface: const Color(0xFF1B1B1F),
      onSurfaceVariant: const Color(0xFF5F5F67),
      outline: const Color(0xFFA1A1AA),
      outlineVariant: const Color(0xFFE4E4E7),
      primaryContainer: const Color(0xFFEFEFF1),
      onPrimaryContainer: const Color(0xFF1B1B1F),
      secondaryContainer: const Color(0xFFEFEFF1),
      onSecondaryContainer: const Color(0xFF1B1B1F),
      inverseSurface: const Color(0xFF2A2A2E),
      onInverseSurface: const Color(0xFFF5F5F7),
      inversePrimary: const Color(0xFFFD79A8),
    );
  }

  /// Transparent system bars; light icons on dark, dark icons on light.
  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return base.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static ThemeData _build(ColorScheme scheme, CopyBoxColors palette) {
    final roundedButtons = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayStyle(scheme.brightness),
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
        backgroundColor: palette.fill,
        selectedColor: AppColors.primary,
        disabledColor: palette.fill,
        // State-dependent: selected (pink) chips always get #2D3436.
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: WidgetStateColor.resolveWith((states) =>
              states.contains(WidgetState.selected) ? AppColors.onPrimary : scheme.onSurface),
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
              states.contains(WidgetState.selected) ? AppColors.onPrimary : scheme.onSurface),
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
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.fill,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? palette.link : scheme.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? palette.link : scheme.onSurfaceVariant,
            )),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: scheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.fill,
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
