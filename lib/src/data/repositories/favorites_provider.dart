import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier() : super(<int>{});

  bool isFav(int id) => state.contains(id);

  void toggle(int id) {
    final s = Set<int>.from(state);
    if (!s.add(id)) s.remove(id);
    state = s;
  }

  void clear() => state = <int>{};
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>(
      (ref) => FavoritesNotifier(),
);
