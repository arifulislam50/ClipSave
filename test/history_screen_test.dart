import 'package:clipsave/ui/screens/history_screen.dart';
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
}
