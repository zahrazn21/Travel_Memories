import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';


class MemoryFavoritesService extends ChangeNotifier {
  MemoryFavoritesService._internal();
  static final MemoryFavoritesService instance =
      MemoryFavoritesService._internal();

  static const _storageKey = 'favorite_memories';

  final Map<int, Map<String, dynamic>> _favorites = {};
  bool _isLoaded = false;

  List<Map<String, dynamic>> get favorites => _favorites.values.toList();

  bool isFavorite(int id) => _favorites.containsKey(id);

  
  Future<void> load() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _favorites.clear();
    for (final item in raw) {
      try {
        final map = _decode(item);
        final id = map['id'] as int;
        _favorites[id] = map;
      } catch (_) {
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> add(Map<String, dynamic> memory) async {
    final id = memory['id'] as int;
    _favorites[id] = memory;
    notifyListeners();
    await _persist();
  }

  Future<void> remove(int id) async {
    if (_favorites.remove(id) != null) {
      notifyListeners();
      await _persist();
    }
  }

  Future<void> toggle(Map<String, dynamic> memory) async {
    final id = memory['id'] as int;
    if (_favorites.containsKey(id)) {
      await remove(id);
    } else {
      await add(memory);
    }
  }

  Future<void> updateIfFavorite(Map<String, dynamic> memory) async {
    final id = memory['id'] as int;
    if (_favorites.containsKey(id)) {
      _favorites[id] = memory;
      notifyListeners();
      await _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _favorites.values.map(_encode).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  String _encode(Map<String, dynamic> memory) {
    final copy = Map<String, dynamic>.from(memory);

    final date = copy['date'];
    if (date is DateTime) copy['date'] = date.toIso8601String();

    final createdAt = copy['createdAt'];
    if (createdAt is DateTime) {
      copy['createdAt'] = createdAt.toIso8601String();
    }

    final bytes = copy['imageBytes'];
    if (bytes is Uint8List) {
      copy['imageBytes'] = base64Encode(bytes);
    } else {
      copy.remove('imageBytes');
    }

    return jsonEncode(copy);
  }

  Map<String, dynamic> _decode(String raw) {
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);

    final date = map['date'];
    if (date is String) map['date'] = DateTime.parse(date);

    final createdAt = map['createdAt'];
    if (createdAt is String) map['createdAt'] = DateTime.parse(createdAt);

    final bytes = map['imageBytes'];
    if (bytes is String) map['imageBytes'] = base64Decode(bytes);

    return map;
  }
}
