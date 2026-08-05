import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme mode. Defaults to dark; persisted via SharedPreferences.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'taifa_theme_mode';

  @override
  ThemeMode build() {
    Future.microtask(_hydrate);
    return ThemeMode.dark;
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (!ref.mounted || raw == null) return;
    state = raw == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> _persist(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.light ? 'light' : 'dark');
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    unawaited(_persist(next));
  }

  void set(ThemeMode mode) {
    state = mode;
    unawaited(_persist(mode));
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
