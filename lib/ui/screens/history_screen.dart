import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/clip_filter.dart';
import '../../state/clips_controller.dart';
import '../../state/settings_controller.dart';
import '../actions/clip_actions.dart';
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
        title: const Text('ClipSave'),
        actions: [
          IconButton(
            tooltip: 'New clip',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => ClipActions.openEditor(context),
          ),
          PopupMenuButton<_HistoryMenu>(
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
            padding: EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: _SearchField(),
          ),
          const FilterBar(),
          if (!guideDismissed) const CaptureInfoCard(),
          const Expanded(child: _ClipList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ClipActions.saveClipboard(context),
        icon: const Icon(Icons.content_paste_go_rounded),
        label: const Text('Save clipboard'),
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
    return SearchBar(
      controller: _controller,
      hintText: 'Search clips',
      elevation: const WidgetStatePropertyAll<double>(0),
      leading: const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Icon(Icons.search),
      ),
      trailing: [
        if (_controller.text.isNotEmpty)
          IconButton(
            tooltip: 'Clear search',
            icon: const Icon(Icons.close),
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
          action: TextButton(
            onPressed: () => controller.setFilter(ClipFilter.all),
            child: const Text('Show all clips'),
          ),
        );
      }
      return EmptyState(
        icon: Icons.content_paste_rounded,
        title: 'Your clipboard history',
        message: 'Copy something, then come back here or tap "Save clipboard". '
            'Saved text stays on this device only.',
        action: FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const CaptureGuideScreen())),
          icon: const Icon(Icons.help_outline),
          label: const Text('How capture works'),
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.onErrorContainer),
          ),
          onDismissed: (_) => ClipActions.delete(context, item),
          child: ClipTile(item: item),
        );
      },
    );
  }
}
