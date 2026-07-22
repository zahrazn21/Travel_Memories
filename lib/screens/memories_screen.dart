import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_memories/screens/add_memory_screen.dart';
import 'package:travel_memories/services/memory_favorites_service.dart';
import 'package:travel_memories/themes/app_background_theme.dart';

class _Design {
  static const double radiusLg = 24;
  static const double radiusMd = 16;
  static const double radiusSm = 12;
  static const double gapXs = 4;
  static const double gapSm = 8;
  static const double gapMd = 16;
  static const double gapLg = 24;
  static const double imageHeight = 180;
  static const double detailImageHeight = 250;
}

class MemoriesListPage extends StatefulWidget {
  const MemoriesListPage({super.key});

  @override
  State<MemoriesListPage> createState() => _MemoriesListPageState();
}

class _MemoriesListPageState extends State<MemoriesListPage> {
  List<Map<String, dynamic>> _memories = [];

  @override
  void initState() {
    super.initState();
    MemoryFavoritesService.instance.load();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? memoriesString = prefs.getString('saved_memories');

    if (memoriesString != null && memoriesString.isNotEmpty) {
      try {
        final List<dynamic> decodedList = json.decode(memoriesString);
        setState(() {
          _memories = decodedList.map((item) {
            final map = Map<String, dynamic>.from(item);
            if (map['date'] is String) {
              map['date'] = DateTime.parse(map['date']);
            }
            return map;
          }).toList();
        });
      } catch (e) {
        print('خطا در خواندن خاطرات: $e');
      }
    }
  }

  Future<void> _saveMemories() async {
    final prefs = await SharedPreferences.getInstance();
    final memoriesToSave = _memories.map((m) {
      final copy = Map<String, dynamic>.from(m);
      if (copy['date'] is DateTime) {
        copy['date'] = (copy['date'] as DateTime).toIso8601String();
      }
      copy.remove('imageBytes'); 
      return copy;
    }).toList();

    final String encodedData = json.encode(memoriesToSave);
    await prefs.setString('saved_memories', encodedData);
  }

  Color _textColor(BuildContext context) {
    final bgTheme = Theme.of(context).extension<AppBackgroundTheme>();
    return bgTheme?.textColor ?? Colors.white;
  }

  Color _accentColor(BuildContext context) {
    final bgTheme = Theme.of(context).extension<AppBackgroundTheme>();
    return bgTheme!.memoryTextColor[1];
  }

  Color _cardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.7);
  }

  List<Color> _gradientColors(BuildContext context) {
    final bgTheme = Theme.of(context).extension<AppBackgroundTheme>();
    return bgTheme?.gradientColors ??
        const [
          Color(0xFFFFF0F5),
          Color(0xFFFFE4E1),
          Color(0xFFFFD1DC),
        ];
  }

  Future<void> _addMemory(Map<String, dynamic> data) async {
    setState(() {
      _memories.insert(0, {
        ...data,
        'id': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
    await _saveMemories(); 
  }

  void _toggleFavorite(Map<String, dynamic> memory) {
    MemoryFavoritesService.instance.toggle(memory);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(context);
    final text = _textColor(context);
    final card = _cardColor(context);
    final gradient = _gradientColors(context);

    return Scaffold(
      appBar: _buildAppBar(context, accent, text, gradient),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              _memories.isEmpty
                  ? _EmptyState(accentColor: accent, textColor: text)
                  : _buildMemoriesList(accent, text, card),
              Positioned(
                bottom: 150,
                right: 0,
                left: 0,
                child: Center(
                  child: _AddMemoryButton(
                    accentColor: accent,
                    onPressed: () => _navigateToAddMemory(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Color accent,
    Color text,
    List<Color> gradient,
  ) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📖', style: TextStyle(fontSize: 24)),
          const SizedBox(width: _Design.gapSm),
          Text(
            'خاطرات من',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: text,
              shadows: [
                Shadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 2)),
              ],
            ),
          ),
        ],
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
                color: accent.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4)),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: _RoundIconBadge(
              icon: Icons.search,
              color: accent,
              background: _cardColor(context)),
          onPressed: () {},
        ),
        const SizedBox(width: _Design.gapSm),
      ],
    );
  }

  Widget _buildMemoriesList(Color accent, Color text, Color card) {
    return AnimatedBuilder(
      animation: MemoryFavoritesService.instance,
      builder: (context, _) {
        return ListView.builder(
          padding: const EdgeInsets.only(
              top: _Design.gapMd, bottom: 120,
              left: _Design.gapMd, right: _Design.gapMd),
          itemCount: _memories.length,
          itemBuilder: (context, index) {
            final memory = _memories[index];
            final isFavorite =
                MemoryFavoritesService.instance.isFavorite(memory['id'] as int);
            return _MemoryCard(
              memory: memory,
              accentColor: accent,
              textColor: text,
              cardColor: card,
              isFavorite: isFavorite,
              onTap: () => _showMemoryDetail(context, memory),
              onToggleFavorite: () => _toggleFavorite(memory),
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToAddMemory(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddMemoryPage()),
    );

    if (result == null) return;

    final data = _memoryResultToMap(result);
    if (data != null) {
      await _addMemory(data);
    }
  }

  Future<void> _navigateToEditMemory(
      BuildContext context, Map<String, dynamic> memory) async {
    final existingMemory = Memory(
      title: (memory['title'] as String?) ?? '',
      date: (memory['date'] as DateTime?) ?? DateTime.now(),
      description: (memory['description'] as String?) ?? '',
      mood: (memory['mood'] as String?) ?? '😊 خوشحال',
      imagePath: memory['image'] as String?,
      imageBytes: memory['imageBytes'] as Uint8List?,
      city: (memory['city'] as String?) ?? '',
      attractionName: (memory['attractionName'] as String?) ?? '',
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMemoryPage(initialMemory: existingMemory),
      ),
    );

    if (result == null) return;

    final data = _memoryResultToMap(result);
    if (data == null) return;

    setState(() {
      final index =
          _memories.indexWhere((m) => m['id'] == memory['id']);
      if (index != -1) {
        _memories[index] = {
          ..._memories[index],
          ...data,
        };
        MemoryFavoritesService.instance.updateIfFavorite(_memories[index]);
      }
    });
    await _saveMemories();
  }

  Map<String, dynamic>? _memoryResultToMap(dynamic result) {
    if (result is Memory) {
      return {
        'title': result.title,
        'date': result.date,
        'description': result.description,
        'mood': result.mood,
        'image': result.imagePath,
        'imageBytes': result.imageBytes,
        'city': result.city,
        'attractionName': result.attractionName,
        'hasImage': result.imagePath != null || result.imageBytes != null,
      };
    } else if (result is Map<String, dynamic>) {
      return result;
    }
    return null;
  }

  void _showMemoryDetail(
      BuildContext context, Map<String, dynamic> memory) {
    final accent = _accentColor(context);
    final text = _textColor(context);
    final card = _cardColor(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1040)
          : Colors.white,
      builder: (context) => _MemoryDetailSheet(
        memory: memory,
        accentColor: accent,
        textColor: text,
        cardColor: card,
        onDelete: () => _confirmDeleteMemory(context, memory),
        onEdit: () {
          Navigator.pop(context);
          _navigateToEditMemory(context, memory);
        },
        onToggleFavorite: () => _toggleFavorite(memory),
      ),
    );
  }

  void _confirmDeleteMemory(
      BuildContext context, Map<String, dynamic> memory) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('حذف خاطره'),
          content: const Text('آیا از حذف این خاطره مطمئنی؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () async {
                final id = memory['id'] as int;
                setState(() {
                  _memories.removeWhere((m) => m['id'] == id);
                });
                MemoryFavoritesService.instance.remove(id);
                await _saveMemories();
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('خاطره حذف شد 🗑️'),
                    backgroundColor: Colors.red.shade400,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('حذف',
                  style: TextStyle(color: Colors.red.shade400)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _RoundIconBadge(
      {required this.icon,
      required this.color,
      required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)
        ],
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final Color color;
  final VoidCallback onTap;

  const _FavoriteButton({
    required this.isFavorite,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : color.withOpacity(0.55),
        size: 20,
      ),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: 18,
    );
  }
}

class _Chip extends StatelessWidget {
  final Widget child;
  final Color color;

  const _Chip({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_Design.radiusSm),
      ),
      child: child,
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final Color color;
  final bool onDarkBackground;

  const _DateChip(
      {required this.date,
      required this.color,
      this.onDarkBackground = false});

  @override
  Widget build(BuildContext context) {
    final textColor = onDarkBackground ? Colors.white : color;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today, color: textColor, size: 14),
        const SizedBox(width: _Design.gapXs + 2),
        Text(PersianDate.format(date),
            style: TextStyle(color: textColor, fontSize: 12)),
      ],
    );

    if (onDarkBackground) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius:
              BorderRadius.circular(_Design.radiusSm),
        ),
        child: content,
      );
    }
    return _Chip(color: color, child: content);
  }
}

class _EmptyState extends StatelessWidget {
  final Color accentColor;
  final Color textColor;

  const _EmptyState(
      {required this.accentColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.3),
                  accentColor.withOpacity(0.1)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                  color: accentColor.withOpacity(0.2), width: 2),
            ),
            child: Icon(Icons.auto_stories,
                size: 60,
                color: accentColor.withOpacity(0.6)),
          ),
          const SizedBox(height: _Design.gapLg),
          Text(
            'هنوز هیچ خاطره‌ای ثبت نکردی!',
            style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: _Design.gapXs + 4),
          Text(
            'اولین خاطره‌ات رو بنویس ✨',
            style: TextStyle(
                color: textColor.withOpacity(0.6), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _AddMemoryButton extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onPressed;

  const _AddMemoryButton(
      {required this.accentColor, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.8), accentColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: accentColor.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, color: Colors.white, size: 26),
        label: const Text(
          'خاطره جدید',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }
}

ImageProvider? _resolveImage(Map<String, dynamic> memory) {
  final bytes = memory['imageBytes'];
  if (bytes is Uint8List && bytes.isNotEmpty) {
    return MemoryImage(bytes);
  }

  final image = memory['image'];
  if (image == null) return null;
  final path = image.toString();
  if (path.isEmpty) return null;

  if (path.startsWith('http')) {
    return NetworkImage(path);
  }

  final file = File(path);
  if (!file.existsSync()) return null;
  return FileImage(file);
}

String _moodGlyph(Map<String, dynamic> memory) {
  final mood = memory['mood']?.toString();
  if (mood == null || mood.isEmpty) return '😊';
  return mood.substring(0, mood.length >= 2 ? 2 : 1);
}

class _MemoryCard extends StatelessWidget {
  final Map<String, dynamic> memory;
  final Color accentColor;
  final Color textColor;
  final Color cardColor;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _MemoryCard({
    required this.memory,
    required this.accentColor,
    required this.textColor,
    required this.cardColor,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final image = _resolveImage(memory);
    final date =
        (memory['date'] as DateTime?) ?? DateTime.now();
    final city = memory['city'] as String?;
    final attraction = memory['attractionName'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:
            const EdgeInsets.only(bottom: _Design.gapMd),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius:
              BorderRadius.circular(_Design.radiusLg),
          border: Border.all(
              color: accentColor.withOpacity(0.15),
              width: 1.5),
          boxShadow: [
            BoxShadow(
                color: accentColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5)),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(_Design.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image != null)
                _CardImage(
                    image: image,
                    date: date,
                    mood: _moodGlyph(memory)),
              Padding(
                padding: const EdgeInsets.all(_Design.gapMd),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        if (image == null)
                          _DateChip(
                              date: date,
                              color: accentColor),
                        Expanded(
                          child: Text(
                            memory['title'] ?? 'بدون عنوان',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (city != null && city.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          Text(
                            attraction != null &&
                                    attraction.isNotEmpty
                                ? attraction
                                : city,
                            style: TextStyle(
                              color: accentColor
                                  .withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.place_rounded,
                              color: accentColor
                                  .withOpacity(0.6),
                              size: 13),
                        ],
                      ),
                    ],
                    const SizedBox(height: _Design.gapSm),
                    Text(
                      memory['description'] ?? '',
                      style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14,
                          height: 1.5),
                      textAlign: TextAlign.right,
                      maxLines: image != null ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          _FavoriteButton(
                              isFavorite: isFavorite,
                              color: accentColor,
                              onTap: onToggleFavorite),
                          const SizedBox(
                              width: _Design.gapSm),
                          _MiniIconButton(
                              icon: Icons.share_outlined,
                              color: accentColor),
                        ]),
                        Row(children: [
                          Text(_moodGlyph(memory),
                              style: const TextStyle(
                                  fontSize: 20)),
                          const SizedBox(
                              width: _Design.gapXs),
                          Text('حالت',
                              style: TextStyle(
                                  color: textColor
                                      .withOpacity(0.4),
                                  fontSize: 12)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final ImageProvider image;
  final DateTime date;
  final String mood;

  const _CardImage(
      {required this.image,
      required this.date,
      required this.mood});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _Design.imageHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: image, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.35)
                ],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _DateChip(
                date: date,
                color: Colors.white,
                onDarkBackground: true),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle),
              child: Text(mood,
                  style: const TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MiniIconButton(
      {required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color.withOpacity(0.55), size: 20),
      onPressed: () {},
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: 18,
    );
  }
}

class _MemoryDetailSheet extends StatelessWidget {
  final Map<String, dynamic> memory;
  final Color accentColor;
  final Color textColor;
  final Color cardColor;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleFavorite;

  const _MemoryDetailSheet({
    required this.memory,
    required this.accentColor,
    required this.textColor,
    required this.cardColor,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final image = _resolveImage(memory);
    final date =
        (memory['date'] as DateTime?) ?? DateTime.now();
    final city = memory['city'] as String?;
    final attraction = memory['attractionName'] as String?;
    final id = memory['id'] as int;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close,
                          color: textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'جزئیات خاطره',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    AnimatedBuilder(
                      animation: MemoryFavoritesService.instance,
                      builder: (context, _) {
                        return _FavoriteButton(
                          isFavorite:
                              MemoryFavoritesService.instance.isFavorite(id),
                          color: accentColor,
                          onTap: onToggleFavorite,
                        );
                      },
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        if (image != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                                _Design.radiusMd + 4),
                            child: Image(
                              image: image,
                              height:
                                  _Design.detailImageHeight,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: _Design.gapMd),
                        Text(
                          memory['title'] ?? 'بدون عنوان',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        if (city != null && city.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.end,
                            children: [
                              Text(
                                attraction != null &&
                                        attraction.isNotEmpty
                                    ? '$attraction — $city'
                                    : city,
                                style: TextStyle(
                                  color: accentColor
                                      .withOpacity(0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.place_rounded,
                                  color: accentColor
                                      .withOpacity(0.6),
                                  size: 14),
                            ],
                          ),
                        ],
                        const SizedBox(height: _Design.gapSm),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            _DateChip(
                                date: date, color: accentColor),
                            _Chip(
                              color: accentColor,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_moodGlyph(memory),
                                      style: const TextStyle(
                                          fontSize: 18)),
                                  const SizedBox(
                                      width: _Design.gapXs),
                                  Text('حالت',
                                      style: TextStyle(
                                          color: accentColor,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: _Design.gapMd),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                              _Design.gapMd),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(
                                _Design.radiusMd),
                            border: Border.all(
                                color: accentColor
                                    .withOpacity(0.1)),
                          ),
                          child: Text(
                            memory['description'] ?? '',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                height: 1.8),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(height: _Design.gapLg),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            _ActionButton(
                                icon: Icons.edit,
                                label: 'ویرایش',
                                color: accentColor,
                                onTap: onEdit),
                            _ActionButton(
                                icon: Icons.share,
                                label: 'اشتراک',
                                color: Colors.blue,
                                onTap: () {}),
                            _ActionButton(
                                icon: Icons.delete,
                                label: 'حذف',
                                color: Colors.red,
                                onTap: onDelete),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: _Design.gapXs),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class PersianDate {
  static const List<String> _months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  static String format(DateTime date) {
    final j = _toJalali(date.year, date.month, date.day);
    return '${j[2]} ${_months[j[1] - 1]} ${j[0]}';
  }

  static List<int> _toJalali(int gy, int gm, int gd) {
    const gDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    int gy2 = (gm > 2) ? (gy + 1) : gy;
    int days = 355666 +
        (365 * gy) +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd +
        gDays.sublist(0, gm - 1).fold(0, (a, b) => a + b);

    int jy = -1595 + (33 * (days ~/ 12053));
    days %= 12053;
    jy += 4 * (days ~/ 1461);
    days %= 1461;
    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }

    int jm, jd;
    if (days < 186) {
      jm = 1 + (days ~/ 31);
      jd = 1 + (days % 31);
    } else {
      jm = 7 + ((days - 186) ~/ 30);
      jd = 1 + ((days - 186) % 30);
    }
    return [jy, jm, jd];
  }
}