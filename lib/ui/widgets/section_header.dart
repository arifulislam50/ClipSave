import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Small upper-case section label ("CAPTURE", "AUTOMATIC CATEGORIES").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: CopyBoxColors.of(context).muted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
        ),
      ),
    );
  }
}
