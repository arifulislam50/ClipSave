import 'package:clipsave/ui/screens/history_screen.dart';
import 'package:clipsave/ui/widgets/category_visuals.dart';
import 'package:clipsave/ui/widgets/clip_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/history_harness.dart';

void main() {
  group('Step 1: New clip replaces Save clipboard', () {
    testWidgets('exactly one FAB, labelled "New clip"; no app-bar edit icon', (tester) async {
      final h = await HistoryHarness.pump(tester, clips: ['hello']);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.widgetWithText(FloatingActionButton, 'New clip'), findsOneWidget);
      expect(find.byTooltip('New clip'), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_rounded), findsNothing);
      expect(find.text('Save clipboard'), findsNothing);
      final fab = tester.getSize(find.byType(FloatingActionButton));
      expect(fab.height, greaterThanOrEqualTo(48));
      await h.close(tester);
    });

    testWidgets('empty state: New clip button and auto-save-on message', (tester) async {
      final h = await HistoryHarness.pump(tester);
      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(find.text(emptyMessageAutoSaveOn), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'New clip'), findsOneWidget);
      expect(find.text('How capture works'), findsOneWidget);
      await h.close(tester);
    });

    testWidgets('empty state with auto-save off explains the alternatives', (tester) async {
      final h = await HistoryHarness.pump(tester, autoCapture: false);
      expect(find.text(emptyMessageAutoSaveOff), findsOneWidget);
      await h.close(tester);
    });

    testWidgets('New clip opens the editor', (tester) async {
      final h = await HistoryHarness.pump(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Type or paste text to keep'), findsOneWidget);
      await h.close(tester);
    });
  });

  group('Step 2: clip tile', () {
    const longText = 'Line one of a long clip that keeps going and going so that it '
        'needs more than two lines when collapsed in the history list. '
        'Second sentence with more words. Third sentence with even more words '
        'to be sure the preview is truncated. END-MARKER';

    testWidgets('no category avatar on tiles', (tester) async {
      final h = await HistoryHarness.pump(tester, clips: ['hello', 'https://flutter.dev']);
      expect(find.byType(ClipTile), findsNWidgets(2));
      expect(find.descendant(of: find.byType(ClipTile), matching: find.byType(CategoryAvatar)),
          findsNothing);
      expect(tester.getSize(find.byType(ClipTile).first).height, greaterThanOrEqualTo(72));
      await h.close(tester);
    });

    testWidgets('one tap expands, a second tap collapses', (tester) async {
      final h = await HistoryHarness.pump(tester, clips: [longText]);
      expect(find.text(ClipTile.collapseHint), findsNothing);
      await tester.tap(find.byType(ClipTile));
      await tester.pumpAndSettle();
      expect(find.text(ClipTile.collapseHint), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
      await tester.tap(find.text(ClipTile.collapseHint));
      await tester.pumpAndSettle();
      expect(find.text(ClipTile.collapseHint), findsNothing);
      expect(find.byType(SelectableText), findsNothing);
      await h.close(tester);
    });

    testWidgets('tapping the tile does not copy; the copy button does', (tester) async {
      final h = await HistoryHarness.pump(tester, clips: ['P@ssw0rd!', 'plain note']);
      await tester.tap(find.text('plain note'));
      await tester.pumpAndSettle();
      expect(h.bridge.copies, isEmpty);
      await tester.tap(find.byTooltip('Copy').at(1)); // second tile = 'plain note'
      await tester.pump();
      await tester.tap(find.byTooltip('Copy').first); // 'P@ssw0rd!' is newest
      await tester.pump();
      expect(h.bridge.copies, [('plain note', false), ('P@ssw0rd!', true)]);
      await h.close(tester);
    });

    testWidgets('expanded text is capped at 10,000 characters', (tester) async {
      final h = await HistoryHarness.pump(tester, clips: ['x' * 12000]);
      await tester.tap(find.byType(ClipTile));
      await tester.pumpAndSettle();
      expect(find.text(ClipTile.truncatedNote), findsOneWidget);
      final shown = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(shown.data!.length, ClipTile.maxExpandedChars);
      await h.close(tester);
    });

    testWidgets('all seven filter chips are still present', (tester) async {
      final h = await HistoryHarness.pump(tester, clips: ['hello']);
      for (final label in ['All', 'Favourites', 'Text', 'Links', 'Emails', 'Phones', 'Numbers']) {
        await tester.dragUntilVisible(find.widgetWithText(FilterChip, label),
            find.byType(ListView).first, const Offset(-120, 0));
        expect(find.widgetWithText(FilterChip, label), findsOneWidget, reason: label);
      }
      await h.close(tester);
    });
  });

  group('Step 3: date and time line', () {
    final dateLine = RegExp(r'^(Today|Yesterday|\d{1,2} [A-Z][a-z]{2} \d{4}) · \d{1,2}:\d{2} (AM|PM)$');

    testWidgets('the date line is the last text line; no relative time', (tester) async {
      final h = await HistoryHarness.pump(tester, clips: ['hello world']);
      final tile = find.byType(ClipTile);
      final texts = find.descendant(of: tile, matching: find.byType(RichText));
      final lines = texts.evaluate().map((e) {
        final w = e.widget as RichText;
        return (y: tester.getTopLeft(find.byWidget(w)).dy, text: w.text.toPlainText());
      // Icons also render as RichText (one private-use glyph); skip them.
      }).where((l) => l.text.trim().length > 1).toList()
        ..sort((a, b) => a.y.compareTo(b.y));
      expect(dateLine.hasMatch(lines.last.text), isTrue, reason: 'last line was "${lines.last.text}"');
      expect(lines.last.text, startsWith('Today · '));
      expect(find.textContaining(' ago'), findsNothing);
      expect(find.textContaining('Just now'), findsNothing);
      // Meta line is "Type · Source".
      expect(lines.any((l) => l.text == 'Text · Typed'), isTrue);
      await h.close(tester);
    });

    testWidgets('date line stays last when expanded (hint below it)', (tester) async {
      final h = await HistoryHarness.pump(tester, clips: ['hello world']);
      await tester.tap(find.byType(ClipTile));
      await tester.pumpAndSettle();
      final date = tester.getTopLeft(find.byKey(const ValueKey<String>('clip-date'))).dy;
      final hint = tester.getTopLeft(find.text(ClipTile.collapseHint)).dy;
      expect(hint, greaterThan(date));
      await h.close(tester);
    });
  });
}
