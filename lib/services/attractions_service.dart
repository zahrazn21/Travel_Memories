import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_memories/models/attraction.dart';

class AttractionsService {
  static const _sparqlEndpoint = 'https://query.wikidata.org/sparql';

  static final Map<String, List<Attraction>> _cache = {};

  static void prefetchCity({
    required double lat,
    required double lng,
    required String cityKey,
  }) {
    if (_cache.containsKey(cityKey)) return;
    AttractionsService().fetchNear(lat: lat, lng: lng, cityKey: cityKey);
  }


  Future<List<Attraction>> fetchNear({
    required double lat,
    required double lng,
    String? cityKey, 
  }) async {

    if (cityKey != null && _cache.containsKey(cityKey)) {
      print('⚡ Data returned instantly from CACHE for: $cityKey');
      return _cache[cityKey]!;
    }

    final sw = Stopwatch()..start();

    final bindings = await _queryWikidata(lat: lat, lng: lng);

    final uniqueBindings = <String, dynamic>{};
    for (var binding in bindings) {
      final nameFa = binding['placeLabel']?['value'] as String?;
      if (nameFa != null && !uniqueBindings.containsKey(nameFa)) {
        uniqueBindings[nameFa] = binding;
      }
    }

    print('⏱ SPARQL query: ${sw.elapsedMilliseconds}ms, ${uniqueBindings.length} unique results');
    sw.reset();

    final futures = uniqueBindings.values.map((binding) async {
      final nameFa = binding['placeLabel']?['value'] as String?;
      final nameEn = binding['placeAltLabel']?['value'] as String?;
      if (nameFa == null) return null;

      final itemSw = Stopwatch()..start();
      final image = await _getImage(nameFa: nameFa, nameEn: nameEn ?? '');
      print('⏱ image for "$nameFa": ${itemSw.elapsedMilliseconds}ms → ${image != null ? "found" : "none"}');

      if (image == null) return null;

      return Attraction(
        name: nameFa,
        description: binding['placeDescription']?['value'] as String?,
        website: binding['website']?['value'] as String?,
        inceptionYear: _extractYear(binding['inception']?['value']),
        image: image,
        lat: double.tryParse(binding['lat']?['value'] ?? ''),
        lng: double.tryParse(binding['lon']?['value'] ?? ''),
        province: binding['provinceLabel']?['value'] as String?,
      );
    }).toList();

    final results = await Future.wait(futures);
    final attractions = results.whereType<Attraction>().toList();
    print('⏱ TOTAL: ${sw.elapsedMilliseconds}ms');

    if (cityKey != null && attractions.isNotEmpty) {
      _cache[cityKey] = attractions;
    }

    return attractions;
  }

  String? _extractYear(String? isoDate) {
    if (isoDate == null || isoDate.length < 4) return null;
    return isoDate.substring(0, 4);
  }

  Future<List<dynamic>> _queryWikidata({
    required double lat,
    required double lng,
  }) async {
    final query = '''
SELECT ?place ?placeLabel ?placeDescription ?lat ?lon ?sitelinks (SAMPLE(?provLabel) AS ?provinceLabel) WHERE {
  SERVICE wikibase:around {
    ?place wdt:P625 ?coord .
    bd:serviceParam wikibase:center "Point($lng $lat)"^^geo:wktLiteral .
    bd:serviceParam wikibase:radius "40" .
  }
  BIND(geof:longitude(?coord) AS ?lon)
  BIND(geof:latitude(?coord) AS ?lat)

  ?place wdt:P31 ?type .
  VALUES ?type {
    # ── جاذبه‌های تاریخی/فرهنگی ──
    wd:Q2065736   # tourist attraction
    wd:Q839954    # archaeological site
    wd:Q4989906   # monument
    wd:Q16560     # palace
    wd:Q23413     # castle / fortress
    wd:Q12518     # tower
    wd:Q44613     # caravanserai
    wd:Q1329623   # bazaar
    wd:Q33506     # museum
    wd:Q32815     # mosque
    wd:Q16970     # church building
    wd:Q1370598   # hammam / bathhouse
    wd:Q2319498   # landmark

    # ── جاذبه‌های طبیعی ──
    wd:Q23397     # lake
    wd:Q34038     # waterfall
    wd:Q8502      # mountain
    wd:Q35509     # spring
    wd:Q1349417   # cave
    wd:Q473972    # protected area
    wd:Q1252910   # canyon / gorge
    wd:Q23442     # island
    wd:Q7930989   # wetland
    wd:Q22698     # park / garden
  }

  # ── جلوگیری از قاطی شدن روستا/شهر/شهرک ──
  MINUS { ?place wdt:P31 wd:Q532 }      # village
  MINUS { ?place wdt:P31 wd:Q515 }      # city
  MINUS { ?place wdt:P31 wd:Q3957 }     # town
  MINUS { ?place wdt:P31 wd:Q486972 }   # human settlement

  ?place wikibase:sitelinks ?sitelinks .
  FILTER(?sitelinks >= 2)
  
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
GROUP BY ?place ?placeLabel ?placeDescription ?lat ?lon ?sitelinks
ORDER BY DESC(?sitelinks)
LIMIT 80
''';

    final response = await http.post(
      Uri.parse(_sparqlEndpoint),
      headers: {
        'Content-Type': 'application/sparql-query',
        'Accept': 'application/json',
      },
      body: query,
    );

    if (response.statusCode != 200) {
      throw Exception('خطا: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return data['results']?['bindings'] as List? ?? [];
  }


  Future<String?> _getImage({
    required String nameFa,
    required String nameEn,
  }) async {
    if (nameEn.isNotEmpty) {
      final img = await _fromWikipedia(nameEn, lang: 'en');
      if (img != null && !img.contains('Iran_location')) return img;
    }

    final imgFa = await _fromWikipedia(nameFa, lang: 'fa');
    if (imgFa != null && !imgFa.contains('Iran_location')) return imgFa;

    if (nameEn.isNotEmpty) {
      final commonsEn = await _fromCommons(nameEn);
      if (commonsEn != null) return commonsEn;
    }

    return _fromCommons(nameFa);
  }

  Future<String?> _fromWikipedia(String title, {required String lang}) async {
    try {
      final encoded = Uri.encodeComponent(title);
      final res = await http.get(
        Uri.parse(
          'https://$lang.wikipedia.org/w/api.php'
          '?action=query&titles=$encoded&prop=pageimages'
          '&format=json&pithumbsize=600&origin=*',
        ),
      );
      if (res.statusCode != 200) return null;

      final pages = jsonDecode(res.body)['query']?['pages'] as Map?;
      if (pages == null || pages.isEmpty) return null;

      final page = pages.values.first;
      return page['thumbnail']?['source'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fromCommons(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final searchRes = await http.get(
        Uri.parse(
          'https://commons.wikimedia.org/w/api.php'
          '?action=query&list=search&srnamespace=6'
          '&srsearch=$encoded&format=json&origin=*&srlimit=1',
        ),
      );
      if (searchRes.statusCode != 200) return null;

      final results = jsonDecode(searchRes.body)['query']?['search'] as List?;
      if (results == null || results.isEmpty) return null;

      final title = Uri.encodeComponent(results[0]['title']);
      final imgRes = await http.get(
        Uri.parse(
          'https://commons.wikimedia.org/w/api.php'
          '?action=query&titles=$title&prop=imageinfo'
          '&iiprop=url&iiurlwidth=600&format=json&origin=*',
        ),
      );
      if (imgRes.statusCode != 200) return null;

      final pages = jsonDecode(imgRes.body)['query']?['pages'] as Map?;
      if (pages == null || pages.isEmpty) return null;

      final imageinfo = pages.values.first['imageinfo'] as List?;
      if (imageinfo == null || imageinfo.isEmpty) return null;

      return imageinfo[0]['thumburl'] ?? imageinfo[0]['url'];
    } catch (_) {
      return null;
    }
  }
}