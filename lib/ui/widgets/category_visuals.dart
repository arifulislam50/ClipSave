import 'package:flutter/material.dart';

import '../../core/utils/content_classifier.dart';

/// UI-only visuals for categories, kept out of the core layer.
extension ClipCategoryVisuals on ClipCategory {
  IconData get icon {
    switch (this) {
      case ClipCategory.text:
        return Icons.notes_rounded;
      case ClipCategory.link:
        return Icons.link_rounded;
      case ClipCategory.email:
        return Icons.alternate_email_rounded;
      case ClipCategory.phone:
        return Icons.call_outlined;
      case ClipCategory.number:
        return Icons.tag_rounded;
    }
  }

  /// Singular name for the meta line ("Link · 5 min ago · Shared").
  String get singular {
    switch (this) {
      case ClipCategory.text:
        return 'Text';
      case ClipCategory.link:
        return 'Link';
      case ClipCategory.email:
        return 'Email';
      case ClipCategory.phone:
        return 'Phone';
      case ClipCategory.number:
        return 'Number';
    }
  }

  /// Category colour: the type word in each clip's meta line, and the
  /// folders-screen category avatars (at 18% alpha behind the icon).
  /// Dark values are the design colours (≥ 6.8:1 on the #121214 card);
  /// light mode uses deeper shades of the same hues (≥ 5.3:1 on white).
  Color color(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (this) {
      case ClipCategory.link:
        return dark ? const Color(0xFF6AA9FF) : const Color(0xFF1D5FB8);
      case ClipCategory.email:
        return dark ? const Color(0xFFFFC857) : const Color(0xFF8A5A00);
      case ClipCategory.phone:
        return dark ? const Color(0xFF4ADE9A) : const Color(0xFF1E7A4C);
      case ClipCategory.number:
        return dark ? const Color(0xFFA78BFA) : const Color(0xFF6B3FB8);
      case ClipCategory.text:
        return dark ? const Color(0xFFFD79A8) : const Color(0xFFB01F63);
    }
  }
}

/// Round category avatar used by clip tiles and category cards.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.size = 44});

  final ClipCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = category.color(Theme.of(context).brightness);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(category.icon, size: size * 0.5, color: color),
      ),
    );
  }
}
