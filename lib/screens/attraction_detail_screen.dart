import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:travel_memories/themes/app_background_theme.dart';
import 'package:travel_memories/screens/add_memory_screen.dart';

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
  bool _hasError = false;
  bool _isFavorite = false;
  final TextEditingController _memoryController = TextEditingController();

  static const List<String> _validExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg', '.bmp'
  ];

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

  bool _isValidImageUrl(String url) {
    if (url.isEmpty || url == 'null' || url == 'undefined') return false;
    
    final lowerUrl = url.toLowerCase();
    
    final hasValidExtension = _validExtensions.any((ext) => lowerUrl.contains(ext));
    if (hasValidExtension) return true;
    
    final validDomains = ['wikimedia', 'wikipedia', 'commons', 'static', 'images'];
    final hasValidDomain = validDomains.any((domain) => lowerUrl.contains(domain));
    
    return hasValidDomain;
  }

  void _addGalleryImage(String url, {bool asFirst = false}) {
    if (!_isValidImageUrl(url)) {
      print('⚠️ Invalid image skipped: $url');
      return;
    }
    
    final key = _imageKey(url);
    if (_addedImageKeys.contains(key)) {
      print('⚠️ Duplicate image skipped: $url');
      return;
    }
    
    _addedImageKeys.add(key);
    
    setState(() {
      if (asFirst) {
        galleryImages.insert(0, url);
      } else {
        galleryImages.add(url);
      }
      _headerImage ??= url;
    });
    
    print('✅ Image added: $url');
  }

  Future<void> fetchWikipediaData(String name) async {
    try {
      final encoded = Uri.encodeComponent(name);
      final res = await http.get(
        Uri.parse('https://fa.wikipedia.org/api/rest_v1/page/summary/$encoded'),
        headers: {
          'User-Agent': 'TravelMemoriesApp/1.0 (contact: your@email.com)',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          wikiData = data;
        });

        final img = data['originalimage']?['source'] ?? data['thumbnail']?['source'];
        if (img != null && img.isNotEmpty) {
          _addGalleryImage(img, asFirst: true);
        }

        final wikidataId = data['wikibase_item'];
        if (wikidataId != null) {
          await fetchWikidataExtra(wikidataId);
        }
      }
    } catch (e) {
      print('❌ Error fetching Wikipedia: $e');
    }
  }

  Future<void> fetchWikidataExtra(String qid) async {
    try {
      final query = '''
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
          'User-Agent': 'TravelMemoriesApp/1.0',
        },
        body: query,
      ).timeout(const Duration(seconds: 5));

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

          int addedCount = 0;
          for (final b in bindings) {
            if (addedCount >= 3) break;
            final img = b['image']?['value'] as String?;
            if (img != null && img.isNotEmpty) {
              _addGalleryImage(img);
              addedCount++;
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching Wikidata: $e');
    }
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
        headers: {
          'User-Agent': 'TravelMemoriesApp/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode != 200) return;

      final results = jsonDecode(res.body)['query']?['search'] as List? ?? [];
      
      int addedCount = 0;
      const maxImages = 3;

      for (final r in results) {
        if (addedCount >= maxImages) break;
        
        final title = Uri.encodeComponent(r['title']);
        final imgRes = await http.get(
          Uri.parse(
            'https://commons.wikimedia.org/w/api.php'
            '?action=query&titles=$title&prop=imageinfo'
            '&iiprop=url&iiurlwidth=600&format=json&origin=*',
          ),
          headers: {
            'User-Agent': 'TravelMemoriesApp/1.0',
          },
        ).timeout(const Duration(seconds: 3));

        if (imgRes.statusCode == 200) {
          final pages = jsonDecode(imgRes.body)['query']?['pages'] as Map?;
          if (pages != null) {
            final imageinfo = pages.values.first['imageinfo'] as List?;
            final url = imageinfo?[0]['thumburl'] ?? imageinfo?[0]['url'];
            if (url != null && url.isNotEmpty) {
              final key = _imageKey(url);
              if (!_addedImageKeys.contains(key)) {
                _addGalleryImage(url);
                addedCount++;
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error fetching more images: $e');
    }
  }

  Future<void> fetchDetails() async {
    setState(() {
      isLoading = true;
      _hasError = false;
    });

    final name = widget.attraction['name'] as String? ?? '';
    final nameEn = widget.attraction['name_en'] as String? ?? '';

    final mainImage = widget.attraction['image'] as String?;
    if (mainImage != null && mainImage.isNotEmpty) {
      _addGalleryImage(mainImage, asFirst: true);
    }

    try {
      await Future.wait([
        fetchWikipediaData(name),
        if (nameEn.isNotEmpty) fetchMoreImages(nameEn),
      ]);
    } catch (e) {
      print('⚠️ Some requests failed: $e');
    }

    if (!mounted) return;
    
    setState(() {
      isLoading = false;
      _hasError = galleryImages.isEmpty;
    });
    
    if (galleryImages.isEmpty && mounted) {
      setState(() {
        _hasError = true;
      });
    }
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        content: Text(
          _isFavorite ? 'به علاقه‌مندی‌ها اضافه شد' : 'از علاقه‌مندی‌ها حذف شد',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.attraction['name'] as String? ?? '';
    final description =
        wikiData?['description'] ?? widget.attraction['description'] ?? '';
    final extract = wikiData?['extract'] ?? '';
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    final uniqueImages = galleryImages.toSet().toList();
    final headerImage =
        _headerImage ?? (uniqueImages.isNotEmpty ? uniqueImages[0] : null);

    return Scaffold(
      body: Stack(
        children: [
          // Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topCenter,
          //       end: Alignment.bottomCenter,
          //       colors: theme.imageShadowColors,
          //     ),
          //   ),
          // ),
          CustomScrollView(
            slivers: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: theme.imageShadowColors[1],
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _GlassIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _GlassIconButton(
                        icon: _isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        iconColor: _isFavorite
                            ? Colors.pinkAccent
                            : Colors.white,
                        onTap: _toggleFavorite,
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: headerImage != null
                        ? GestureDetector(
                            onTap: () => _showFullImage(headerImage),
                            child: _buildImage(headerImage, fit: BoxFit.cover),
                          )
                        : Container(
                            color: const Color(0xFF1A1A3E),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.white54,
                                size: 60,
                              ),
                            ),
                          ),
                  ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textColor,
                                  ),
                                ),
                              ),
                            ],
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
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_hasError && uniqueImages.isEmpty)
                            _buildErrorState(theme)
                          else ...[
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
                            if (uniqueImages.length > 1) ...[
                              _sectionTitle('گالری تصاویر'),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 140,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: uniqueImages.length,
                                  itemBuilder: (context, index) {
                                    final img = uniqueImages[index];
                                    final isActive = img == headerImage;
                                    return GestureDetector(
                                      onTap: () => _showFullImage(img),
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 10),
                                        width: 160,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: _buildImage(img, fit: BoxFit.cover),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],
                          _sectionTitle('ثبت خاطره'),
                          const SizedBox(height: 8),
                          _buildAddMemoryButton(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url, {BoxFit fit = BoxFit.cover}) {
    if (!_isValidImageUrl(url)) {
      return Container(
        color: Colors.white12,
        child: const Icon(Icons.broken_image, color: Colors.white30, size: 40),
      );
    }
    
    return Image.network(
      url,
      fit: fit,
      headers: {
        'User-Agent': 'TravelMemoriesApp/1.0',
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Image load error: $url');
        return Container(
          color: Colors.white12,
          child: const Icon(Icons.broken_image, color: Colors.white30, size: 40),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.white12,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white30,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(AppBackgroundTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported,
            color: theme.textColor.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'تصویری برای این مکان یافت نشد',
            style: TextStyle(color: theme.textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                // پاک کردن کش تصاویر و تلاش مجدد
                _addedImageKeys.clear();
                galleryImages.clear();
                _headerImage = null;
              });
              fetchDetails();
            },
            child: const Text('تلاش دوباره'),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: theme.travelTextColor[1],
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'اطلاعات تکمیلی',
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
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
          Row(
            children: [
              Icon(icon, color: theme.travelTextColor[1], size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(value, style: TextStyle(color: theme.textColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: theme.travelTextColor[1],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
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
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withOpacity(0.9),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: url,
                    child: _buildImage(url, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'تصویر ${galleryImages.indexOf(url) + 1} از ${galleryImages.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMemoryButton() {
    final attractionName = widget.attraction['name'] as String? ?? '';
    final cityName = widget.attraction['city'] as String? ?? '';

    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(219, 47, 15, 173),
              Color.fromARGB(255, 107, 45, 207),
              Color.fromARGB(255, 177, 45, 207),
              Color.fromARGB(255, 207, 45, 107),
              Color.fromARGB(255, 207, 121, 45),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddMemoryPage(
                  initialCity: cityName,
                  initialAttraction: attractionName,
                  onMemorySaved: (memory) {
                    print('خاطره جدید برای جاذبه ${memory.attractionName} در شهر ${memory.city}');
                  },
                ),
              ),
            );
          },
          icon: const Icon(Icons.edit, color: Colors.white, size: 18),
          label: Text(
            'ثبت خاطره برای $attractionName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ),
    );
  }
}

/// Small frosted-glass circular icon button
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Material(
          color: Colors.black.withOpacity(0.3),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}