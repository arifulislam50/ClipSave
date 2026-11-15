import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/clip_filter.dart';
import '../../state/clips_controller.dart';
import '../../state/settings_controller.dart';
import '../actions/clip_actions.dart';
import '../widgets/app_logo.dart';
import '../widgets/capture_info_card.dart';
import '../widgets/clip_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import 'capture_guide_screen.dart';

enum _HistoryMenu { clear, guide }

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guideDismissed =
        context.select<SettingsController, bool>((s) => s.guideDismissed);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 32, semanticLabel: null),
            SizedBox(width: 10),
            Text('Copy Box', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New clip',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => ClipActions.openEditor(context),
          ),
          PopupMenuButton<_HistoryMenu>(
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case _HistoryMenu.clear:
                  ClipActions.clearHistory(context);
                case _HistoryMenu.guide:
                  Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const CaptureGuideScreen()));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _HistoryMenu.clear,
                child: Text('Clear history (keep favourites)'),
              ),
              PopupMenuItem(
                value: _HistoryMenu.guide,
                child: Text('How capture works'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: _SearchField(),
          ),
          const FilterBar(),
          if (!guideDismissed) const CaptureInfoCard(),
          const Expanded(child: _ClipList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ClipActions.saveClipboard(context),
        icon: const Icon(Icons.content_paste_rounded),
        label: const Text('Save clipboard', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<ClipsController>().query,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    context.read<ClipsController>().setQuery(value);
    setState(() {}); // Toggle the clear button.
  }

  @override
  Widget build(BuildContext context) {
    final colors = CopyBoxColors.of(context);
    return SearchBar(
      controller: _controller,
      hintText: 'Search clips',
      constraints: const BoxConstraints(minHeight: 52, maxHeight: 52),
      elevation: const WidgetStatePropertyAll<double>(0),
      backgroundColor: WidgetStatePropertyAll<Color>(colors.fill),
      shape: const WidgetStatePropertyAll<OutlinedBorder>(StadiumBorder()),
      hintStyle: WidgetStatePropertyAll<TextStyle>(TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      padding: const WidgetStatePropertyAll<EdgeInsets>(
          EdgeInsets.symmetric(horizontal: 12)),
      leading: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
      trailing: [
        if (_controller.text.isNotEmpty)
          IconButton(
            tooltip: 'Clear search',
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              _controller.clear();
              _changed('');
            },
          ),
      ],
      onChanged: _changed,
    );
  }
}

class _ClipList extends StatelessWidget {
  const _ClipList();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClipsController>();
    final items = controller.items;

    if (controller.loading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      if (controller.query.trim().isNotEmpty) {
        return const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No matches',
          message: 'Try a different word, or clear the filter.',
        );
      }
      if (controller.filter != ClipFilter.all) {
        return EmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'Nothing here yet',
          message: 'No clips match this filter.',
          actions: [
            TextButton(
              onPressed: () => controller.setFilter(ClipFilter.all),
              child: const Text('Show all clips'),
            ),
          ],
        );
      }
      return EmptyState(
        illustration: const AppLogo(size: 112, semanticLabel: null),
        title: 'Nothing saved yet',
        message: 'Copy text in any app, then come back here or tap '
            '"Save clipboard". Your clips are stored on this device.',
        actions: [
          FilledButton.icon(
            onPressed: () => ClipActions.saveClipboard(context),
            icon: const Icon(Icons.content_paste_rounded),
            label: const Text('Save clipboard'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const CaptureGuideScreen())),
            child: const Text('How capture works'),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey<int?>(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Icon(Icons.delete_outline,
                semanticLabel: 'Delete',
                color: Theme.of(context).colorScheme.onErrorContainer),
          ),
          onDismissed: (_) => ClipActions.delete(context, item),
          child: ClipTile(item: item),
        );
      },
    );
  }
}
