import 'package:flutter/material.dart';

import '../../core/utils/content_classifier.dart';

/// UI-only icon mapping, kept out of the core layer.
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
}
