import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/content_classifier.dart';
import '../../data/models/clip_filter.dart';
import '../../state/clips_controller.dart';
import 'category_visuals.dart';

/// Horizontal chips: All, Favourites, auto categories, then user folders.
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
          avatar: icon == null ? null : Icon(icon, size: 18, color: color),
          showCheckmark: false,
          selected: selected,
          onSelected: (_) =>
              controller.setFilter(selected ? ClipFilter.all : filter),
        ),
      );
    }

    return SizedBox(
      height: 48,
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
                  icon: Icons.folder, color: Color(f.color)),
        ],
      ),
    );
  }
}
