import 'package:flutter/material.dart';

/// The app's single visual language.
///
/// The app previously shipped several experimental styles; we've committed to
/// [broadcast] — a sports "match centre" look: high-contrast scoreboard hero,
/// tabular numbers, accent rules, uppercase labels, fixtures-style lists.
enum UiStyle {
  broadcast,
}

/// Broadcast is now the only style. This service is retained so the rest of the
/// app keeps a single, stable hook for the active visual language (and so a new
/// style could be reintroduced later without touching call sites).
class UiStyleService extends ChangeNotifier {
  UiStyle get style => UiStyle.broadcast;

  /// Kept for API compatibility; there is nothing to load now.
  Future<void> init() async {}

  String get label => 'Broadcast';
}
