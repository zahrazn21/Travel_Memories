import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:travel_memories/screens/attractions_screen.dart';
import 'package:travel_memories/themes/app_background_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _allCities = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadCities();
    _controller.addListener(_onQueryChanged);
    _focusNode.addListener(() => setState(() {}));
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final String response = await rootBundle.loadString('data/cities.json');
      final data = json.decode(response);
      final loadedCities = List<Map<String, dynamic>>.from(
        data['cities'] as List,
      );

      await Future.wait(
        loadedCities.map((city) async {
          final lat = city['lat'];
          final lng = city['lng'];
          if (lat != null && lng != null) {
            city['weather'] = await _getWeather(
              (lat as num).toDouble(),
              (lng as num).toDouble(),
            );
          }
        }),
      );

      if (mounted) {
        setState(() {
          _allCities = loadedCities;
          _results = loadedCities;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load cities error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _getWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat'
        '&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final current = jsonDecode(response.body)['current'];
        return {
          'temp': current['temperature_2m'],
          'humidity': current['relative_humidity_2m'],
          'wind': current['wind_speed_10m'],
          'weatherCode': current['weather_code'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Weather error: $e');
      return null;
    }
  }

  void _onQueryChanged() {
    final query = _controller.text.trim();
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _results = _allCities;
      } else {
        _results = _allCities.where((city) {
          final nameFa = (city['name_fa'] ?? '').toString();
          final nameEn = (city['name_en'] ?? '').toString();
          final province = (city['province_fa'] ?? '').toString();
          return nameFa.contains(query) ||
              nameEn.toLowerCase().contains(query.toLowerCase()) ||
              province.contains(query);
        }).toList();
      }
    });
  }

  String _formatPopulation(num? population) {
    if (population == null) return '';
    if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)} میلیون نفر';
    }
    return '${population.toStringAsFixed(0)} نفر';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(theme),
              const SizedBox(height: 8),
              _buildSearchBar(theme),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppBackgroundTheme theme) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Material(
              color: theme.textColor.withOpacity(0.08),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back,
                    color: theme.textColor,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Text(
              'جستجوی شهرها',
              style: TextStyle(
                color: theme.travelTextColor[1],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppBackgroundTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: theme.textColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _focusNode.hasFocus
                ? theme.travelTextColor[0].withOpacity(0.6)
                : theme.textColor.withOpacity(0.12),
            width: 1.4,
          ),
          boxShadow: _focusNode.hasFocus
              ? [
                  BoxShadow(
                    color: theme.travelTextColor[0].withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            Icon(Icons.search_rounded, color: theme.textColor.withOpacity(0.7)),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: theme.textColor, fontSize: 15),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'نام شهر یا استان رو بنویس...',
                  hintStyle: TextStyle(
                    color: theme.textColor.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  _focusNode.requestFocus();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: theme.textColor.withOpacity(0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppBackgroundTheme theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.travelTextColor[0]),
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 260 + (index * 35).clamp(0, 400)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - value)),
              child: child,
            ),
          ),
          child: _buildCityTile(context, theme, _results[index]),
        );
      },
    );
  }

  Widget _buildCityTile(
    BuildContext context,
    AppBackgroundTheme theme,
    Map<String, dynamic> city,
  ) {
    final population = _formatPopulation(city['population'] as num?);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AttractionsScreen(city: city)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.textColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.textColor.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: SizedBox(
                width: 84,
                height: 84,
                child: city['image'] != null
                    ? Image.asset(
                        'images/cities/${city['image']}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(theme),
                      )
                    : _imagePlaceholder(theme),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city['name_fa'] as String? ?? '',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: theme.travelTextColor[1],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (city['province_fa'] != null)
                      Text(
                        'استان ${city['province_fa']}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: theme.textColor.withOpacity(0.65),
                          fontSize: 12.5,
                        ),
                      ),
                    if (population.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        population,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: theme.textColor.withOpacity(0.45),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    if (city['weather'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '${(city['weather']['temp'] as num).toStringAsFixed(0)}°',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.thermostat,
                            size: 14,
                            color: theme.textColor.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Icon(
                Icons.chevron_right,
                color: theme.textColor.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(AppBackgroundTheme theme) {
    return Container(
      color: theme.textColor.withOpacity(0.1),
      child: Icon(Icons.location_city, color: theme.textColor.withOpacity(0.4)),
    );
  }

  Widget _buildEmptyState(AppBackgroundTheme theme) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.textColor.withOpacity(0.06),
                border: Border.all(color: theme.textColor.withOpacity(0.12)),
              ),
              child: Icon(
                Icons.location_off_outlined,
                size: 50,
                color: theme.textColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _query.isEmpty ? 'هیچ شهری یافت نشد' : 'شهری با این نام پیدا نشد',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'یه اسم دیگه رو امتحان کن',
              style: TextStyle(
                color: theme.textColor.withOpacity(0.55),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
