// test/services/generation_prefs_store_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/settings_repository.dart';
import 'package:macrochef/models/recipe_preset.dart';
import 'package:macrochef/services/generation_prefs_store.dart';

void main() {
  late AppDatabase db;
  late GenerationPrefsStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = GenerationPrefsStore(SettingsRepository(db));
  });
  tearDown(() => db.close());

  test('presets round-trip and replace by label', () async {
    expect(await store.presets(), isEmpty);
    await store.savePreset(
      const RecipePreset(label: 'Wrap', prompt: 'wrap', pinnedIngredient: 'tortilla'),
    );
    await store.savePreset(const RecipePreset(label: 'Wrap', prompt: 'better wrap'));
    final all = await store.presets();
    expect(all.length, 1); // same label replaces
    expect(all.first.prompt, 'better wrap');
    expect(all.first.pinnedIngredient, isNull);
  });

  test('deletePreset removes by label', () async {
    await store.savePreset(const RecipePreset(label: 'A', prompt: 'a'));
    await store.savePreset(const RecipePreset(label: 'B', prompt: 'b'));
    await store.deletePreset('A');
    final labels = (await store.presets()).map((e) => e.label).toList();
    expect(labels, ['B']);
  });

  test('blacklist round-trips', () async {
    expect(await store.blacklist(), isEmpty);
    await store.setBlacklist(['cilantro', 'olives']);
    expect(await store.blacklist(), ['cilantro', 'olives']);
  });

  test('recent titles are newest-first, de-duplicated, capped at 15', () async {
    for (var i = 0; i < 20; i++) {
      await store.addRecentGeneratedTitle('Recipe $i');
    }
    final recent = await store.recentGeneratedTitles();
    expect(recent.length, 15);
    expect(recent.first, 'Recipe 19'); // newest first
    expect(recent.contains('Recipe 4'), isFalse); // oldest dropped

    // Re-adding an existing title moves it to front without duplicating.
    await store.addRecentGeneratedTitle('Recipe 10');
    final after = await store.recentGeneratedTitles();
    expect(after.first, 'Recipe 10');
    expect(after.where((t) => t == 'Recipe 10').length, 1);
  });
}
