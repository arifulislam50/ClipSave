import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/content_classifier.dart';
import '../../data/models/clip_filter.dart';
import '../../state/clips_controller.dart';
import 'category_visuals.dart';

/// Horizontal chips: All, Favourites, auto categories, then user folders.
/// Chips are 36px high (radius 10); the padded tap target keeps them ≥ 48px tall to touch.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClipsController>();
    final current = controller.filter;

    Widget chip(String label, ClipFilter filter, {IconData? icon, Color? color}) {
      final selected = current == filter;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          avatar: icon == null
              ? null
              : Icon(icon, size: 18, color: selected ? AppColors.onPrimary : color),
          selected: selected,
          showCheckmark: false,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          // M3 chips are 32px; +1 vertical density step = 36px.
          visualDensity: const VisualDensity(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          onSelected: (_) => controller.setFilter(selected ? ClipFilter.all : filter),
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          chip('All', ClipFilter.all),
          chip('Favourites', ClipFilter.favorites, icon: Icons.star_rounded),
          for (final c in ClipCategory.values)
            chip(c.label, ClipFilter.category(c), icon: c.icon),
          for (final f in controller.folders)
            if (f.id != null)
              chip(f.name, ClipFilter.folder(f.id!),
                  icon: Icons.folder_rounded, color: Color(f.color)),
        ],
      ),
    );
  }
}
