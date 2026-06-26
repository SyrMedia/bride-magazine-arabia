import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State: مجموعة معرّفات المقالات المحفوظة
class BookmarksNotifier extends StateNotifier<Set<int>> {
  BookmarksNotifier() : super(<int>{}) {
    _load();
  }

  static const _prefsKey = 'bookmarks_v1';
  bool _loaded = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? const <String>[];
    state = list.map(int.parse).toSet();
    _loaded = true;
  }

  bool get isLoaded => _loaded;

  bool isBookmarked(int id) => state.contains(id);

  Future<void> toggle(int id) async {
    final next = Set<int>.from(state);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = next;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      state.map((e) => e.toString()).toList(),
    );
  }
}

final bookmarksProvider =
StateNotifierProvider<BookmarksNotifier, Set<int>>((ref) {
  return BookmarksNotifier();
});
