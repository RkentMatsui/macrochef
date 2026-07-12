// lib/services/generation_prefs_store.dart
import 'dart:convert';

import '../data/repositories/settings_repository.dart';
import '../models/recipe_preset.dart';

/// Typed access to recipe-generation preferences stored as JSON in the
/// key/value [SettingsRepository]: saved prompt presets, the ingredient
/// blacklist, and recently-generated (unsaved) recipe titles for dedupe.
class GenerationPrefsStore {
  final SettingsRepository settings;
  GenerationPrefsStore(this.settings);

  static const _kPresets = 'recipe_presets';
  static const _kBlacklist = 'ingredient_blacklist';
  static const _kRecent = 'recent_generated_titles';
  static const recentCap = 15;

  // ---- presets ----
  Future<List<RecipePreset>> presets() async {
    final raw = await settings.get(_kPresets);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(RecipePreset.fromJson).toList();
  }

  Future<void> savePreset(RecipePreset p) async {
    final all = await presets();
    final idx = all.indexWhere((e) => e.label == p.label);
    if (idx >= 0) {
      all[idx] = p;
    } else {
      all.add(p);
    }
    await settings.set(_kPresets, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> deletePreset(String label) async {
    final all = await presets();
    all.removeWhere((e) => e.label == label);
    await settings.set(_kPresets, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  // ---- blacklist ----
  Future<List<String>> blacklist() async {
    final raw = await settings.get(_kBlacklist);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> setBlacklist(List<String> items) async {
    await settings.set(_kBlacklist, jsonEncode(items));
  }

  // ---- recently generated titles (dedupe) ----
  Future<List<String>> recentGeneratedTitles() async {
    final raw = await settings.get(_kRecent);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<String>();
  }

  Future<void> addRecentGeneratedTitle(String title) async {
    final t = title.trim();
    if (t.isEmpty) return;
    final all = await recentGeneratedTitles();
    all.removeWhere((e) => e.toLowerCase() == t.toLowerCase());
    all.insert(0, t); // newest-first
    final capped = all.take(recentCap).toList();
    await settings.set(_kRecent, jsonEncode(capped));
  }
}
