import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:travel_memories/models/attraction.dart';

class AttractionsService {
  static const _sparqlEndpoint = 'https://query.wikidata.org/sparql';
  static const _hiveBoxName = 'attractions_cache_box';
  static const _cacheTtl = Duration(days: 7);
  static const _wikidataLimit = 200;
  static const _imageBatchSize = 2;
  static const _maxImageRounds = 5;

  static final Map<String, List<Attraction>> _cache = {};
  static Box<String>? _box;

  static Future<void> updateAttractionImage({
    required String cityKey,
    required String attractionName,
    required String imageUrl,
  }) async {
    if (imageUrl.trim().isEmpty) return;

    try {
      final normalizedUrl = normalizeImageUrl(imageUrl);

      final memoryList = _cache[cityKey];
      if (memoryList != null) {
        for (final attraction in memoryList) {
          if (attraction.name == attractionName) {
            attraction.image = normalizedUrl;
            print('🧠 Image updated in MEMORY cache: $attractionName');
            break;
          }
        }
      }

      final box = await _openBox();
      final cachedRaw = box.get(cityKey);
      if (cachedRaw == null) {
        print('⚠️ No Hive cache found for city: $cityKey');
        return;
      }

      final wrapper = jsonDecode(cachedRaw) as Map<String, dynamic>;
      final items = (wrapper['items'] as List?) ?? [];

      bool found = false;
      for (final item in items) {
        if (item is! Map) continue;
        final name = item['name']?.toString() ?? '';
        if (name == attractionName) {
          item['image'] = normalizedUrl;
          found = true;
          print('💾 Image updated in Hive: $attractionName');
          break;
        }
      }

      if (!found) {
        print('⚠️ Attraction not found in Hive: $attractionName');
        return;
      }

      wrapper['items'] = items;
      await box.put(cityKey, jsonEncode(wrapper));
      print('✅ Image successfully persisted in Hive: $attractionName');
    } catch (e) {
      print('❌ Failed to update attraction image in Hive: $e');
    }
  }

  static Future<Box<String>> _openBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<String>(_hiveBoxName);
    return _box!;
  }

  static void prefetchCity({
    required double lat,
    required double lng,
    required String cityKey,
  }) {
    if (_cache.containsKey(cityKey)) {
      return;
    }
    AttractionsService().fetchNear(lat: lat, lng: lng, cityKey: cityKey);
  }

  static Future<void> clearCache(String cityKey) async {
    _cache.remove(cityKey);
    final box = await _openBox();
    await box.delete(cityKey);
  }

  static String normalizeImageUrl(String url) {
    var fixed = url.trim();
    if (fixed.startsWith('http://')) {
      fixed = fixed.replaceFirst('http://', 'https://');
    }
    if (fixed.contains('Special:FilePath') && !fixed.contains('width=')) {
      final separator = fixed.contains('?') ? '&' : '?';
      fixed = '$fixed${separator}width=600';
    }
    return fixed;
  }

  Future<List<Attraction>> fetchNear({
    required double lat,
    required double lng,
    String? cityKey,
    bool forceRefresh = false,
    void Function(List<Attraction> current)? onBatchUpdate,
  }) async {
    if (!forceRefresh && cityKey != null && _cache.containsKey(cityKey)) {
      print('⚡ Data returned instantly from MEMORY cache for: $cityKey');
      return List.of(_cache[cityKey]!);
    }

    if (!forceRefresh && cityKey != null) {
      try {
        final box = await _openBox();
        final cachedRaw = box.get(cityKey);
        if (cachedRaw != null) {
          final wrapper = jsonDecode(cachedRaw) as Map<String, dynamic>;
          final savedAt = DateTime.tryParse(
            wrapper['savedAt'] as String? ?? '',
          );
          final isFresh =
              savedAt != null && DateTime.now().difference(savedAt) < _cacheTtl;
          if (isFresh) {
            final decoded = wrapper['items'] as List;
            final cachedList = decoded
                .map((e) => Attraction.fromMap(e as Map<String, dynamic>))
                .toList();
            if (cachedList.isNotEmpty) {
              _cache[cityKey] = cachedList;
              print('💾 Data returned from HIVE cache for: $cityKey');
              return List.of(cachedList);
            }
          } else {
            print('⏳ کش Hive برای $cityKey منقضی شده.');
          }
        }
      } catch (e) {
        print('⚠️ خطا در خواندن کش Hive: $e');
      }
    }

    final sw = Stopwatch()..start();
    final rawBindings = await _queryWikidata(lat: lat, lng: lng);
    final uniqueBindings = await compute(_processUniqueBindings, rawBindings);
    print(
      '⏱ Wikidata: '
      '${sw.elapsedMilliseconds}ms | '
      '${uniqueBindings.length} unique results',
    );

    final attractions = <Attraction>[];
    final needsImageFetch = <_PendingImageFetch>[];

    for (final binding in uniqueBindings) {
      final nameFa = binding['placeLabel']?['value'] as String? ?? '';
      if (nameFa.isEmpty) {
        continue;
      }

      final nameEn = binding['placeAltLabel']?['value'] as String? ?? '';
      final commonsCategory = binding['commonsCat']?['value'] as String?;
      String? initialImage;
      final rawP18 = binding['image']?['value'] as String?;
      if (rawP18 != null && rawP18.isNotEmpty) {
        initialImage = normalizeImageUrl(rawP18);
      }

      final attraction = Attraction(
        name: nameFa,
        nameEn: nameEn.isNotEmpty ? nameEn : null,
        description: binding['placeDescription']?['value'] as String?,
        website: binding['website']?['value'] as String?,
        inceptionYear: _extractYear(binding['inception']?['value']),
        image: initialImage,
        lat: double.tryParse(binding['lat']?['value']?.toString() ?? ''),
        lng: double.tryParse(binding['lon']?['value']?.toString() ?? ''),
        province: binding['provinceLabel']?['value'] as String?,
      );

      attractions.add(attraction);
      if (initialImage == null || initialImage.isEmpty) {
        needsImageFetch.add(_PendingImageFetch(attraction, commonsCategory));
      }
    }

    print(
      '🖼️ '
      '${attractions.length - needsImageFetch.length}/'
      '${attractions.length} دارای P18 هستند.',
    );
    print(
      '🔎 '
      '${needsImageFetch.length} جاذبه نیاز به جستجوی عکس دارند.',
    );

    onBatchUpdate?.call(List.of(attractions));

    if (needsImageFetch.isNotEmpty) {
      await _loadAllMissingImages(
        attractions: attractions,
        pending: needsImageFetch,
        onBatchUpdate: onBatchUpdate,
      );
    }

    final before = attractions.length;
    attractions.removeWhere((attraction) {
      final noImage =
          attraction.image == null || attraction.image!.trim().isEmpty;
      final noDescription =
          attraction.description == null ||
          attraction.description!.trim().isEmpty;
      return noImage && noDescription;
    });

    if (before != attractions.length) {
      print(
        '🗑️ '
        '${before - attractions.length} '
        'جاذبه بدون عکس و توضیح حذف شد.',
      );
    }

    final imageCount = attractions.where((a) {
      return a.image != null && a.image!.trim().isNotEmpty;
    }).length;
    print(
      '🏁 TOTAL: '
      '$imageCount/${attractions.length} '
      'جاذبه عکس دارند.',
    );

    if (cityKey != null && attractions.isNotEmpty) {
      _cache[cityKey] = List.of(attractions);
      try {
        final box = await _openBox();
        final wrapper = {
          'savedAt': DateTime.now().toIso8601String(),
          'items': attractions.map((a) => a.toMap()).toList(),
        };
        await box.put(cityKey, jsonEncode(wrapper));
        print('💾 نتایج کامل در Hive ذخیره شد: $cityKey');
      } catch (e) {
        print('⚠️ ذخیره Hive fail شد: $e');
      }
    }

    return attractions;
  }

  Future<void> _loadAllMissingImages({
    required List<Attraction> attractions,
    required List<_PendingImageFetch> pending,
    void Function(List<Attraction> current)? onBatchUpdate,
  }) async {
    for (var round = 1; round <= _maxImageRounds; round++) {
      final missing = pending.where((item) {
        final image = item.attraction.image;
        return image == null || image.trim().isEmpty;
      }).toList();

      if (missing.isEmpty) {
        print('✅ تمام جاذبه‌ها عکس دارند.');
        return;
      }

      print(
        '🔄 IMAGE ROUND $round/$_maxImageRounds '
        '| باقی‌مانده: ${missing.length}',
      );

      for (var i = 0; i < missing.length; i += _imageBatchSize) {
        final end = (i + _imageBatchSize < missing.length)
            ? i + _imageBatchSize
            : missing.length;
        final batch = missing.sublist(i, end);

        await Future.wait(
          batch.map((pendingItem) async {
            try {
              final img = await _getImage(
                nameFa: pendingItem.attraction.name,
                nameEn: pendingItem.attraction.nameEn ?? '',
                commonsCategory: pendingItem.commonsCategory,
              );
              if (img != null && img.isNotEmpty) {
                pendingItem.attraction.image = img;
                print('✅ عکس پیدا شد: ${pendingItem.attraction.name}');
              } else {
                print('❌ عکس پیدا نشد: ${pendingItem.attraction.name}');
              }
            } catch (e) {
              print('⚠️ Image error ${pendingItem.attraction.name}: $e');
            }
          }),
        );

        onBatchUpdate?.call(List.of(attractions));
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final remaining = pending.where((item) {
        final image = item.attraction.image;
        return image == null || image.trim().isEmpty;
      }).length;

      if (remaining == 0) {
        print('🎉 همه عکس‌ها پیدا شدند.');
        return;
      }

      if (round < _maxImageRounds) {
        print(
          '⏳ $remaining جاذبه هنوز عکس ندارند. '
          'Round بعدی شروع می‌شود...',
        );
        await Future.delayed(Duration(seconds: round));
      }
    }

    final remaining = pending.where((item) {
      final image = item.attraction.image;
      return image == null || image.trim().isEmpty;
    }).length;
    print(
      '🏁 پایان تلاش عکس‌ها. '
      '$remaining جاذبه هنوز بدون عکس هستند.',
    );
  }

  Future<String?> _getImage({
    required String nameFa,
    required String nameEn,
    String? commonsCategory,
  }) async {
    if (commonsCategory != null && commonsCategory.isNotEmpty) {
      final image = await _fromCommonsCategory(commonsCategory, maxFiles: 20);
      if (_isValidImage(image)) {
        return image;
      }
    }

    if (nameEn.isNotEmpty) {
      final image = await _fromWikipedia(nameEn, lang: 'en');
      if (_isValidImage(image)) {
        return image;
      }
    }

    if (nameFa.isNotEmpty) {
      final image = await _fromWikipedia(nameFa, lang: 'fa');
      if (_isValidImage(image)) {
        return image;
      }
    }

    if (nameEn.isNotEmpty) {
      final image = await _fromCommons(nameEn, maxResults: 10);
      if (_isValidImage(image)) {
        return image;
      }
    }

    if (nameFa.isNotEmpty) {
      final image = await _fromCommons(nameFa, maxResults: 10);
      if (_isValidImage(image)) {
        return image;
      }
    }

    final queries = <String>{};
    if (nameEn.isNotEmpty) {
      queries.add('$nameEn landmark');
      queries.add('$nameEn monument');
      queries.add('$nameEn tourist attraction');
      queries.add('$nameEn Iran');
    }
    if (nameFa.isNotEmpty) {
      queries.add('$nameFa جاذبه');
      queries.add('$nameFa اثر تاریخی');
    }

    for (final query in queries) {
      final image = await _fromCommons(query, maxResults: 10);
      if (_isValidImage(image)) {
        return image;
      }
    }

    return null;
  }

  bool _isValidImage(String? url) {
    if (url == null || url.trim().isEmpty) {
      return false;
    }

    final lower = url.toLowerCase();
    const badExtensions = [
      '.svg',
      '.pdf',
      '.djvu',
      '.tif',
      '.tiff',
      '.ogv',
      '.webm',
    ];
    if (badExtensions.any((ext) => lower.endsWith(ext))) {
      return false;
    }

    final badNames = [
      'iran_location',
      'location_map',
      'blank_map',
      'flag_of_iran',
      'wikimedia-logo',
    ];
    if (badNames.any(lower.contains)) {
      return false;
    }

    return true;
  }

  Future<List<dynamic>> _queryWikidata({
    required double lat,
    required double lng,
  }) async {
    final query =
        '''
SELECT ?place ?placeLabel ?placeDescription ?lat ?lon ?sitelinks ?image ?commonsCat
       (SAMPLE(?provLabel) AS ?provinceLabel)
WHERE {
  SERVICE wikibase:around {
    ?place wdt:P625 ?coord .
    bd:serviceParam
      wikibase:center
      "Point($lng $lat)"^^geo:wktLiteral .
    bd:serviceParam
      wikibase:radius
      "40" .
  }

  BIND(geof:longitude(?coord) AS ?lon)
  BIND(geof:latitude(?coord) AS ?lat)

  ?place wdt:P31 ?type .
  VALUES ?type {
    wd:Q2065736
    wd:Q839954
    wd:Q4989906
    wd:Q16560
    wd:Q23413
    wd:Q12518
    wd:Q44613
    wd:Q1329623
    wd:Q33506
    wd:Q32815
    wd:Q16970
    wd:Q1370598
    wd:Q2319498
    wd:Q23397
    wd:Q34038
    wd:Q8502
    wd:Q35509
    wd:Q1349417
    wd:Q473972
    wd:Q1252910
    wd:Q23442
    wd:Q7930989
    wd:Q22698
  }

  MINUS { ?place wdt:P31 wd:Q532 }
  MINUS { ?place wdt:P31 wd:Q515 }
  MINUS { ?place wdt:P31 wd:Q3957 }
  MINUS { ?place wdt:P31 wd:Q486972 }

  ?place wikibase:sitelinks ?sitelinks .
  FILTER(?sitelinks >= 2)

  OPTIONAL { ?place wdt:P18 ?image }
  OPTIONAL { ?place wdt:P373 ?commonsCat }
  OPTIONAL {
    ?place wdt:P131* ?province .
    ?province wdt:P31/wdt:P279* wd:Q1344695 .
    ?province rdfs:label ?provLabel .
    FILTER(LANG(?provLabel) = "fa")
  }

  SERVICE wikibase:label {
    bd:serviceParam wikibase:language "fa,en" .
  }
}

GROUP BY
  ?place
  ?placeLabel
  ?placeDescription
  ?lat
  ?lon
  ?sitelinks
  ?image
  ?commonsCat

ORDER BY DESC(?sitelinks)
LIMIT $_wikidataLimit
''';

    final response = await http
        .post(
          Uri.parse(_sparqlEndpoint),
          headers: {
            'Content-Type': 'application/sparql-query',
            'Accept': 'application/json',
            'User-Agent':
                'TravelMemoriesApp/1.0 '
                '(https://github.com/zahrazn21/Travel_Memories)',
          },
          body: query,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('خطا در Wikidata: ${response.statusCode}');
    }

    return compute(_decodeJson, response.body);
  }

  static List<dynamic> _processUniqueBindings(List<dynamic> bindings) {
    final Map<String, dynamic> uniqueMap = {};
    for (final binding in bindings) {
      final nameFa = binding['placeLabel']?['value'] as String?;
      if (nameFa != null &&
          nameFa.isNotEmpty &&
          !uniqueMap.containsKey(nameFa)) {
        uniqueMap[nameFa] = binding;
      }
    }
    return uniqueMap.values.toList();
  }

  static List<dynamic> _decodeJson(String body) {
    final data = jsonDecode(body);
    return data['results']?['bindings'] as List? ?? [];
  }

  String? _extractYear(String? isoDate) {
    if (isoDate == null || isoDate.length < 4) {
      return null;
    }
    return isoDate.substring(0, 4);
  }

  static const Map<String, String> _wikiHeaders = {
    'User-Agent':
        'TravelMemoriesApp/1.0 '
        '(https://github.com/zahrazn21/Travel_Memories)',
  };

  Future<http.Response?> _getWithRetry(Uri url, {int retries = 3}) async {
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final response = await http
            .get(url, headers: _wikiHeaders)
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 429) {
          final wait = Duration(milliseconds: 1000 * (attempt + 1));
          print('⏳ 429 Rate Limit | انتظار ${wait.inMilliseconds}ms');
          await Future.delayed(wait);
          continue;
        }

        if (response.statusCode >= 500 && response.statusCode <= 599) {
          if (attempt < retries) {
            final wait = Duration(milliseconds: 700 * (attempt + 1));
            await Future.delayed(wait);
            continue;
          }
        }

        return response;
      } catch (e) {
        print('⚠️ GET failed (attempt ${attempt + 1}/${retries + 1}): $e');
        if (attempt == retries) {
          return null;
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    return null;
  }

  Future<String?> _fromCommonsCategory(
    String categoryTitle, {
    int maxFiles = 20,
  }) async {
    try {
      final encodedCat = Uri.encodeComponent('Category:$categoryTitle');
      final res = await _getWithRetry(
        Uri.parse(
          'https://commons.wikimedia.org/w/api.php'
          '?action=query'
          '&list=categorymembers'
          '&cmtitle=$encodedCat'
          '&cmtype=file'
          '&cmlimit=$maxFiles'
          '&format=json'
          '&origin=*',
        ),
      );

      if (res == null || res.statusCode != 200) {
        return null;
      }

      final members =
          jsonDecode(res.body)['query']?['categorymembers'] as List?;
      if (members == null || members.isEmpty) {
        return null;
      }

      for (final member in members) {
        final title = member['title'] as String? ?? '';
        if (title.isEmpty) {
          continue;
        }

        final encodedTitle = Uri.encodeComponent(title);
        final imgRes = await _getWithRetry(
          Uri.parse(
            'https://commons.wikimedia.org/w/api.php'
            '?action=query'
            '&titles=$encodedTitle'
            '&prop=imageinfo'
            '&iiprop=url'
            '&iiurlwidth=600'
            '&format=json'
            '&origin=*',
          ),
        );

        if (imgRes == null || imgRes.statusCode != 200) {
          continue;
        }

        final pages = jsonDecode(imgRes.body)['query']?['pages'] as Map?;
        if (pages == null || pages.isEmpty) {
          continue;
        }

        final imageinfo = pages.values.first['imageinfo'] as List?;
        if (imageinfo == null || imageinfo.isEmpty) {
          continue;
        }

        final url = (imageinfo[0]['thumburl'] ?? imageinfo[0]['url']) as String?;
        if (_isValidImage(url)) {
          return normalizeImageUrl(url!);
        }
      }

      return null;
    } catch (e) {
      print('⚠️ Commons Category error: $e');
      return null;
    }
  }

  Future<String?> _fromWikipedia(String title, {required String lang}) async {
    try {
      final encoded = Uri.encodeComponent(title);
      final res = await _getWithRetry(
        Uri.parse(
          'https://$lang.wikipedia.org/w/api.php'
          '?action=query'
          '&titles=$encoded'
          '&prop=pageimages'
          '&format=json'
          '&pithumbsize=600'
          '&origin=*',
        ),
      );

      if (res == null || res.statusCode != 200) {
        return null;
      }

      final pages = jsonDecode(res.body)['query']?['pages'] as Map?;
      if (pages == null || pages.isEmpty) {
        return null;
      }

      final page = pages.values.first;
      final source = page['thumbnail']?['source'] as String?;
      if (_isValidImage(source)) {
        return normalizeImageUrl(source!);
      }

      return null;
    } catch (e) {
      print('⚠️ Wikipedia error: $e');
      return null;
    }
  }

  Future<String?> _fromCommons(String query, {int maxResults = 10}) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final searchRes = await _getWithRetry(
        Uri.parse(
          'https://commons.wikimedia.org/w/api.php'
          '?action=query'
          '&list=search'
          '&srnamespace=6'
          '&srsearch=$encoded'
          '&format=json'
          '&origin=*'
          '&srlimit=$maxResults',
        ),
      );

      if (searchRes == null || searchRes.statusCode != 200) {
        return null;
      }

      final results = jsonDecode(searchRes.body)['query']?['search'] as List?;
      if (results == null || results.isEmpty) {
        return null;
      }

      final queryWords = query
          .toLowerCase()
          .split(RegExp(r'[\s_\-]+'))
          .where((word) => word.length > 2)
          .toList();

      for (final result in results) {
        final resultTitle = result['title'] as String? ?? '';
        if (resultTitle.isEmpty) {
          continue;
        }

        final lowerTitle = resultTitle.toLowerCase();
        const unsupported = [
          '.svg',
          '.pdf',
          '.djvu',
          '.tif',
          '.tiff',
          '.ogv',
          '.webm',
        ];
        if (unsupported.any((ext) => lowerTitle.endsWith(ext))) {
          continue;
        }

        final hasRelevantWord =
            queryWords.isEmpty ||
            queryWords.any((word) => lowerTitle.contains(word));
        if (!hasRelevantWord) {
          continue;
        }

        final title = Uri.encodeComponent(resultTitle);
        final imgRes = await _getWithRetry(
          Uri.parse(
            'https://commons.wikimedia.org/w/api.php'
            '?action=query'
            '&titles=$title'
            '&prop=imageinfo'
            '&iiprop=url'
            '&iiurlwidth=600'
            '&format=json'
            '&origin=*',
          ),
        );

        if (imgRes == null || imgRes.statusCode != 200) {
          continue;
        }

        final pages = jsonDecode(imgRes.body)['query']?['pages'] as Map?;
        if (pages == null || pages.isEmpty) {
          continue;
        }

        final imageinfo = pages.values.first['imageinfo'] as List?;
        if (imageinfo == null || imageinfo.isEmpty) {
          continue;
        }

        final url = (imageinfo[0]['thumburl'] ?? imageinfo[0]['url']) as String?;
        if (_isValidImage(url)) {
          return normalizeImageUrl(url!);
        }
      }

      return null;
    } catch (e) {
      print('⚠️ Commons Search error for "$query": $e');
      return null;
    }
  }
}

class _PendingImageFetch {
  final Attraction attraction;
  final String? commonsCategory;

  _PendingImageFetch(this.attraction, this.commonsCategory);
}