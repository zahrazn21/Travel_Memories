import 'dart:convert';
import 'package:flutter/services.dart';

class CityDataService {
  static Map<String, dynamic>? _cache;

  static Future<Map<String, dynamic>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('data/cities.json');
    _cache = json.decode(raw) as Map<String, dynamic>;
    return _cache!;
  }

  static Future<Map<String, dynamic>?> getCityByName(String nameFa) async {
    final data = await _loadAll();
    final cities = data['cities'] as List<dynamic>;
    for (final city in cities) {
      if (city['name_fa'] == nameFa) return city as Map<String, dynamic>;
    }
    return null;
  }
}