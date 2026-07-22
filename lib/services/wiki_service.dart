import 'dart:convert';
import 'package:http/http.dart' as http;

class WikiService {
  static final Map<String, String?> _cache = {};

  static Future<String?> searchCommons(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final encoded = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://commons.wikimedia.org/w/api.php'
        '?action=query'
        '&list=search'
        '&srnamespace=6' 
        '&srsearch=$encoded'
        '&format=json'
        '&origin=*'
        '&srlimit=1',
      );

      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      final results = data['query']?['search'] as List?;
      if (results == null || results.isEmpty) return null;

      final title = results[0]['title'] as String;
      return await _getCommonsImageUrl(title);
    } catch (_) {}
    return null;
  }

  static Future<String?> _getCommonsImageUrl(String title) async {
    try {
      final encoded = Uri.encodeComponent(title);
      final url = Uri.parse(
        'https://commons.wikimedia.org/w/api.php'
        '?action=query'
        '&titles=$encoded'
        '&prop=imageinfo'
        '&iiprop=url'
        '&iiurlwidth=600'
        '&format=json'
        '&origin=*',
      );

      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      final pages = data['query']?['pages'] as Map?;
      if (pages == null) return null;

      final page = pages.values.first;
      final imageinfo = page['imageinfo'] as List?;
      if (imageinfo == null || imageinfo.isEmpty) return null;

      return imageinfo[0]['thumburl'] ?? imageinfo[0]['url'];
    } catch (_) {}
    return null;
  }

  static Future<String?> searchWikipedia(String query, {String lang = 'en'}) async {
    if (query.trim().isEmpty) return null;
    try {
      final encoded = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://$lang.wikipedia.org/w/api.php'
        '?action=query'
        '&titles=$encoded'
        '&prop=pageimages'
        '&format=json'
        '&pithumbsize=600'
        '&origin=*',
      );

      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      final pages = data['query']?['pages'] as Map?;
      if (pages == null) return null;

      final page = pages.values.first;
      return page['thumbnail']?['source'];
    } catch (_) {}
    return null;
  }

 static Future<String?> getImage(String nameEn, String nameFa) async {
    final cacheKey = '$nameEn|$nameFa';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    String? img;
    final isArabicOrFarsi = RegExp(r'[\u0600-\u06FF]').hasMatch(nameEn);

    if (nameFa.isNotEmpty) {
      img = await searchWikipedia(nameFa, lang: 'fa');
    }

    if (img == null && nameFa.isNotEmpty) {
      img = await searchCommons(nameFa);
    }

    if (img == null && !isArabicOrFarsi && nameEn.isNotEmpty) {
      img = await searchWikipedia('$nameEn Iran', lang: 'en');
    }

    if (img == null && !isArabicOrFarsi && nameEn.isNotEmpty) {
      img = await searchCommons('$nameEn Iran');
    }

    if (img == null && isArabicOrFarsi && nameEn.isNotEmpty) {
      img = await searchCommons(nameEn);
    }

    _cache[cacheKey] = img;
    return img;
  }
  static Future<String?>? getImageUrl(String nameEn) async {}
}