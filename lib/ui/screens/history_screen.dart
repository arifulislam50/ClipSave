import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/clip_filter.dart';
import '../../data/models/clip_item.dart';
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

const String emptyMessageAutoSaveOn =
    'Copy something, then open Copy Box and it is saved automatically. '
    'Or tap New clip to type your own text. Saved text stays on this device.';
const String emptyMessageAutoSaveOff =
    'Auto-save is off. Turn it on in Settings, use the Quick Settings tile, '
    'Share or the text menu, or tap New clip to type your own text.';

/// Extended "New clip" FAB: 56px high, radius 16, #FD79A8 with #2D3436
/// (colours and shape come from the theme's floatingActionButtonTheme).
class NewClipFab extends StatelessWidget {
  const NewClipFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      tooltip: 'New clip',
      onPressed: () => ClipActions.openEditor(context),
      icon: const Icon(Icons.add_rounded),
      label: const Text('New clip', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

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
      // "New clip" opens the editor. It lives in this tab's Scaffold, which ends
      // above the ad banner (RootShell), so the banner can never cover it.
      floatingActionButton: const NewClipFab(),
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

class _ClipList extends StatefulWidget {
  const _ClipList();

  @override
  State<_ClipList> createState() => _ClipListState();
}

class _ClipListState extends State<_ClipList> with WidgetsBindingObserver {
  /// Rebuilds at local midnight (and on resume) so "Today"/"Yesterday" labels
  /// stay correct across midnight and device clock changes.
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    _midnight = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      _scheduleMidnight();
    }
  }

  /// Expanded/collapsed per clip id. Several may be open at once; toggling one
  /// only rebuilds that tile (each tile listens to its own notifier).
  final Map<int, ValueNotifier<bool>> _expanded = {};

  ValueNotifier<bool> _expandedFor(ClipItem item) =>
      _expanded.putIfAbsent(item.id ?? -item.content.hashCode, () => ValueNotifier<bool>(false));

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    for (final n in _expanded.values) {
      n.dispose();
    }
    super.dispose();
  }

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
      final autoSave = context.select<SettingsController, bool>((s) => s.autoCapture);
      return EmptyState(
        illustration: const AppLogo(size: 112, semanticLabel: null),
        title: 'Nothing saved yet',
        message: autoSave ? emptyMessageAutoSaveOn : emptyMessageAutoSaveOff,
        actions: [
          FilledButton.icon(
            onPressed: () => ClipActions.openEditor(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New clip'),
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
      itemCount: items.length + (controller.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Pagination: fetch the next 50 when the user nears the end.
        if (controller.hasMore && index >= items.length - 10) {
          WidgetsBinding.instance.addPostFrameCallback((_) => controller.loadMore());
        }
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
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
          child: ClipTile(item: item, expanded: _expandedFor(item)),
        );
      },
    );
  }
}
