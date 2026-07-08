import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:travel_memories/themes/app_background_theme.dart';

class AttractionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> attraction;

  const AttractionDetailScreen({super.key, required this.attraction});

  @override
  State<AttractionDetailScreen> createState() => _AttractionDetailScreenState();
}

class _AttractionDetailScreenState extends State<AttractionDetailScreen> {
  Map<String, dynamic>? wikiData;
  Map<String, dynamic>? wikidataExtra;
  List<String> galleryImages = [];
  final Set<String> _addedImageKeys = {}; 
  String? _headerImage; 
  bool isLoading = true;
  final TextEditingController _memoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  @override
  void dispose() {
    _memoryController.dispose();
    super.dispose();
  }

  String _imageKey(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.isEmpty) return url;
    var filename = uri.pathSegments.last;
    filename = filename.replaceFirst(RegExp(r'^\d+px-'), '');
    return filename.toLowerCase();
  }

  void _addGalleryImage(String url, {bool asFirst = false}) {
    final key = _imageKey(url);
    if (_addedImageKeys.contains(key)) return;
    _addedImageKeys.add(key);
    setState(() {
      if (asFirst) {
        galleryImages.insert(0, url);
      } else {
        galleryImages.add(url);
      }
      _headerImage ??= url;
    });
  }

  Future<void> fetchWikipediaData(String name) async {
    try {
      final encoded = Uri.encodeComponent(name);
      final res = await http.get(
        Uri.parse('https://fa.wikipedia.org/api/rest_v1/page/summary/$encoded'),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          wikiData = data;
        });

        final img =
            data['originalimage']?['source'] ?? data['thumbnail']?['source'];
        if (img != null) {
          _addGalleryImage(img, asFirst: true);
        }

        final wikidataId = data['wikibase_item'];
        if (wikidataId != null) {
          await fetchWikidataExtra(wikidataId);
        }
      }
    } catch (_) {}
  }

  Future<void> fetchWikidataExtra(String qid) async {
    try {
      final query =
          '''
SELECT ?inception ?architectLabel ?styleLabel ?image WHERE {
  OPTIONAL { wd:$qid wdt:P571 ?inception }
  OPTIONAL { wd:$qid wdt:P84 ?architect . 
    ?architect rdfs:label ?architectLabel 
    FILTER(LANG(?architectLabel) = "fa" || LANG(?architectLabel) = "en") }
  OPTIONAL { wd:$qid wdt:P149 ?style . 
    ?style rdfs:label ?styleLabel 
    FILTER(LANG(?styleLabel) = "fa" || LANG(?styleLabel) = "en") }
  OPTIONAL { wd:$qid wdt:P18 ?image }
} LIMIT 5
''';

      final res = await http.post(
        Uri.parse('https://query.wikidata.org/sparql'),
        headers: {
          'Content-Type': 'application/sparql-query',
          'Accept': 'application/json',
        },
        body: query,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bindings = data['results']?['bindings'] as List? ?? [];

        if (bindings.isNotEmpty) {
          final b = bindings[0];
          final inceptionRaw = b['inception']?['value'] as String?;

          setState(() {
            wikidataExtra = {
              'inception': inceptionRaw != null && inceptionRaw.length >= 4
                  ? inceptionRaw.substring(0, 4)
                  : null,
              'architect': b['architectLabel']?['value'],
              'style': b['styleLabel']?['value'],
            };
          });

          for (final b in bindings) {
            final img = b['image']?['value'] as String?;
            if (img != null) _addGalleryImage(img);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> fetchMoreImages(String name) async {
    try {
      final encoded = Uri.encodeComponent('$name Iran');
      final res = await http.get(
        Uri.parse(
          'https://commons.wikimedia.org/w/api.php'
          '?action=query&list=search&srnamespace=6'
          '&srsearch=$encoded&format=json&origin=*&srlimit=5',
        ),
      );

      if (res.statusCode != 200) return;

      final results = jsonDecode(res.body)['query']?['search'] as List? ?? [];

      for (final r in results) {
        final title = Uri.encodeComponent(r['title']);
        final imgRes = await http.get(
          Uri.parse(
            'https://commons.wikimedia.org/w/api.php'
            '?action=query&titles=$title&prop=imageinfo'
            '&iiprop=url&iiurlwidth=600&format=json&origin=*',
          ),
        );

        if (imgRes.statusCode == 200) {
          final pages = jsonDecode(imgRes.body)['query']?['pages'] as Map?;
          if (pages != null) {
            final imageinfo = pages.values.first['imageinfo'] as List?;
            final url = imageinfo?[0]['thumburl'] ?? imageinfo?[0]['url'];
            if (url != null) _addGalleryImage(url);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> fetchDetails() async {
    final name = widget.attraction['name'] as String? ?? '';
    final nameEn = widget.attraction['name_en'] as String? ?? '';

    final mainImage = widget.attraction['image'] as String?;
    if (mainImage != null) {
      _addGalleryImage(mainImage, asFirst: true);
    }

    await fetchWikipediaData(name);
    if (nameEn.isNotEmpty) {
      await fetchMoreImages(nameEn);
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.attraction['name'] as String? ?? '';
    final description =
        wikiData?['description'] ?? widget.attraction['description'] ?? '';
    final extract = wikiData?['extract'] ?? '';
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    final headerImage =
        _headerImage ?? (galleryImages.isNotEmpty ? galleryImages[0] : null);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: theme.imageShadowColors,
              ),
            ),
          ),

          CustomScrollView(
            slivers: [

              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: theme.panelBackgroundColors.last,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: headerImage != null
                      ? Image.network(
                          headerImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1A1A3E),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.white54,
                              size: 60,
                            ),
                          ),
                        )
                      : Container(color: const Color(0xFF1A1A3E)),
                ),
              ),

              SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.panelBackgroundColors[1],
                      border: const Border(
                        top: BorderSide(color: Colors.white24, width: 1.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 16),

                          Text(
                            name,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.textColor,
                            ),
                          ),

                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              description,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textColor.withOpacity(0.7),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          if (wikidataExtra != null) _buildWikidataSection(),

                          const SizedBox(height: 16),

                          if (extract.isNotEmpty) ...[
                            _sectionTitle('درباره'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.textColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: theme.textColor.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                extract,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textColor.withOpacity(0.85),
                                  height: 1.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (galleryImages.length > 2) ...[
                            _sectionTitle('گالری تصاویر'),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 140,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: galleryImages.length,
                                itemBuilder: (context, index) {
                                  final img = galleryImages[index];
                                  final isActive = img == headerImage;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _headerImage = img);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 10),
                                      width: 160,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isActive
                                              ? Colors.purple
                                              : theme.textColor.withOpacity(
                                                  0.15,
                                                ),
                                          width: isActive ? 2 : 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          img,
                                          fit: BoxFit.cover,
                                          headers: const {
                                            'User-Agent':
                                                'TravelMemoriesApp/1.0 (contact: youremail@example.com)',
                                          },
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                color: Colors.white12,
                                                child: const Icon(
                                                  Icons.image,
                                                  color: Colors.white30,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          _sectionTitle('ثبت خاطره'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.textColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.purple.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _memoryController,
                                  maxLines: 4,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: theme.textColor),
                                  decoration: InputDecoration(
                                    hintText: 'خاطره‌ات رو اینجا بنویس...',
                                    hintStyle: TextStyle(
                                      color: theme.textColor.withOpacity(0.4),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color.fromARGB(219, 47, 15, 173),
                                            Color.fromARGB(255, 107, 45, 207),
                                            Color.fromARGB(255, 177, 45, 207),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: theme.textColor.withOpacity(
                                            0.2,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: TextButton.icon(
                                        onPressed: () {
                                          if (_memoryController
                                              .text
                                              .isNotEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'خاطره ذخیره شد ✓',
                                                ),
                                                backgroundColor: Colors.purple,
                                              ),
                                            );
                                            _memoryController.clear();
                                          }
                                        },
                                        icon: Icon(
                                          Icons.save_outlined,
                                          color: theme.textColor,
                                          size: 16,
                                        ),
                                        label: Text(
                                          'ذخیره خاطره',
                                          style: TextStyle(
                                            color: theme.textColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (isLoading)
            const Positioned(
              top: 320,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(color: Colors.purple),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWikidataSection() {
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.textColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.textColor.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'اطلاعات تکمیلی',
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.info_outline, color: theme.travelTextColor[0], size: 18),
            ],
          ),
          const SizedBox(height: 12),
          if (wikidataExtra?['inception'] != null)
            _infoRow(
              Icons.calendar_today_outlined,
              'سال ساخت',
              wikidataExtra!['inception'],
            ),
          if (wikidataExtra?['architect'] != null)
            _infoRow(Icons.architecture, 'معمار', wikidataExtra!['architect']),
          if (wikidataExtra?['style'] != null)
            _infoRow(
              Icons.style_outlined,
              'سبک معماری',
              wikidataExtra!['style'],
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: TextStyle(color: theme.textColor, fontSize: 14)),
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: theme.travelTextColor[0], size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.travelTextColor[0],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
