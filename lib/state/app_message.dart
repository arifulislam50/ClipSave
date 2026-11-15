import 'package:flutter/foundation.dart';

/// A one-off message for the UI to show as a snackbar, optionally with one action.
@immutable
class AppMessage {
  const AppMessage(this.text, {this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  bool get hasAction => actionLabel != null && onAction != null;
}
