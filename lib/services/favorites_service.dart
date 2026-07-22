import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_memories/models/attraction.dart';

class FavoritesService extends ChangeNotifier {
  FavoritesService._internal();
  static final FavoritesService instance = FavoritesService._internal();

  static const _storageKey = 'favorite_attractions';

  final Map<String, Attraction> _favorites = {};
  bool _isLoaded = false;

  List<Attraction> get favorites => _favorites.values.toList();

  bool isFavorite(Attraction attraction) =>
      _favorites.containsKey(attraction.name);


  Future<void> load() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _favorites.clear();
    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        final attraction = Attraction.fromMap(map);
        _favorites[attraction.name] = attraction;
      } catch (_) {
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggle(Attraction attraction) async {
    if (_favorites.containsKey(attraction.name)) {
      _favorites.remove(attraction.name);
    } else {
      _favorites[attraction.name] = attraction;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _favorites.values.map((a) => jsonEncode(a.toMap())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  Future<void> remove(Attraction attraction) async {
    if (_favorites.remove(attraction.name) != null) {
      notifyListeners();
      await _persist();
    }
  }
}
