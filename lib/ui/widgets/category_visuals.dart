import 'package:flutter/material.dart';

import '../../core/utils/content_classifier.dart';

/// Soft avatar colours for a category (icon contrast ≥ 4.6:1 on its tint).
class CategoryTint {
  const CategoryTint(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

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

  CategoryTint tint(Brightness brightness) {
    final light = brightness == Brightness.light;
    switch (this) {
      case ClipCategory.link:
        return light
            ? const CategoryTint(Color(0xFFE3EEFF), Color(0xFF1D5FB8))
            : const CategoryTint(Color(0xFF1F3550), Color(0xFFA9CCFF));
      case ClipCategory.email:
        return light
            ? const CategoryTint(Color(0xFFEEE6FF), Color(0xFF6B3FB8))
            : const CategoryTint(Color(0xFF352A50), Color(0xFFD2BEFF));
      case ClipCategory.phone:
        return light
            ? const CategoryTint(Color(0xFFDFF5E8), Color(0xFF1E7A4C))
            : const CategoryTint(Color(0xFF1E3A2C), Color(0xFFA6E3C3));
      case ClipCategory.number:
        return light
            ? const CategoryTint(Color(0xFFFFF0D4), Color(0xFF8A5A00))
            : const CategoryTint(Color(0xFF4A3A1A), Color(0xFFFFD98A));
      case ClipCategory.text:
        return light
            ? const CategoryTint(Color(0xFFFFE3EE), Color(0xFFB01F63))
            : const CategoryTint(Color(0xFF4A2536), Color(0xFFFF9EC4));
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
    final tint = category.tint(Theme.of(context).brightness);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: tint.background, shape: BoxShape.circle),
        child: Icon(category.icon, size: size * 0.5, color: tint.foreground),
      ),
    );
  }
}
