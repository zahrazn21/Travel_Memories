import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:travel_memories/screens/all_cities_screen.dart';
import 'package:travel_memories/screens/attractions_screen.dart';
import 'package:travel_memories/screens/search_screen.dart';
import 'package:travel_memories/services/attractions_service.dart'; 
import 'package:travel_memories/themes/app_background_theme.dart';
import 'package:travel_memories/widgets/city_weather_card.dart';
import 'package:travel_memories/widgets/seasonal_pick_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _attractions = [];
  List<Map<String, dynamic>> _cities = [];

  final Map<String, Map<String, dynamic>?> _weatherByCity = {};
  final Set<String> _pendingWeather = {};

  bool _isLoadingAttractions = true;
  bool _isLoadingCities = true;
  String _errorMessage = '';
  String _citiesError = '';

  static String get apiKey => dotenv.env['API_KEY'] ?? '';
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  @override
  void initState() {
    super.initState();
    fetchAttractions();
    loadCities();
  }

  Future<void> fetchAttractions() async {
    setState(() {
      _isLoadingAttractions = true;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse('$baseUrl&apiKey=$apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List? ?? [];
        if (!mounted) return;
        setState(() {
          _attractions = features;
          _isLoadingAttractions = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingAttractions = false;
          _errorMessage = 'خطا: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAttractions = false;
        _errorMessage = 'خطا در ارتباط';
      });
    }
  }

  Future<void> loadCities() async {
    setState(() {
      _isLoadingCities = true;
      _citiesError = '';
    });

    try {
      final String response = await rootBundle.loadString('data/cities.json');
      final data = json.decode(response);
      final loadedCities = List<Map<String, dynamic>>.from(data['cities']);

      if (!mounted) return;
      setState(() {
        _cities = loadedCities;
        _isLoadingCities = false;
      });

      for (final city in loadedCities) {
        _loadWeatherFor(city);
      }

      _prefetchImportantCities(loadedCities);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCities = false;
        _citiesError = 'مشکلی در بارگذاری شهرها پیش اومد';
      });
    }
  }

  void _prefetchImportantCities(List<Map<String, dynamic>> cities) {
    final currentSeason = _currentSeasonKey();
    
    final priorityCities = cities.where((c) {
      final isPopular = c['is_popular'] == true;
      final isSeasonal = (c['best_seasons'] as List?)?.contains(currentSeason) ?? false;
      return isPopular || isSeasonal;
    }).take(8); 

    for (var city in priorityCities) {
      AttractionsService.prefetchCity(
        lat: (city['lat'] as num).toDouble(),
        lng: (city['lng'] as num).toDouble(),
        cityKey: city['name_fa'] as String,
      );
    }
  }

  Future<void> _loadWeatherFor(Map<String, dynamic> city) async {
    final name = city['name_fa'] as String;
    setState(() => _pendingWeather.add(name));

    final weather = await getWeather(city['lat'], city['lng']);

    if (!mounted) return;
    setState(() {
      _weatherByCity[name] = weather;
      _pendingWeather.remove(name);
    });
  }

  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat'
        '&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final current = data['current'];

      return {
        'temp': current['temperature_2m'],
        'humidity': current['relative_humidity_2m'],
        'wind': current['wind_speed_10m'],
        'weatherCode': current['weather_code'],
      };
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgTheme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgTheme.gradientColors,
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.infinity,
              height: 380,
              child: Image.asset(
                bgTheme.backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1A1A3E),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 60,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Header(bgTheme: bgTheme),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 140,
                    left: 100,
                    right: 100,
                    bottom: 10,
                  ),
                  child: _SearchBar(bgTheme: bgTheme),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '✨هر سفر یک خاطره جدید',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.08),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: bgTheme.borderColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: _buildPanelBody(bgTheme),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _seasonalTaglines = [
    'هوای عالی برای این روزها',
    'مقصد داغ این فصل',
    'کمتر دیده شده، بیشتر لذت‌بخش',
    'بهترین وقت سفر بهش الان‌ه',
  ];

  String _currentSeasonKey() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'spring';
    if (month >= 6 && month <= 8) return 'summer';
    if (month >= 9 && month <= 11) return 'fall';
    return 'winter';
  }

  Widget _buildPanelBody(AppBackgroundTheme bgTheme) {
    if (_isLoadingCities) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    if (_citiesError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: bgTheme.textColor.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(_citiesError, style: TextStyle(color: bgTheme.textColor)),
            const SizedBox(height: 8),
            TextButton(onPressed: loadCities, child: const Text('تلاش دوباره')),
          ],
        ),
      );
    }

    if (_cities.isEmpty) {
      return Center(
        child: Text(
          'شهری برای نمایش وجود نداره',
          style: TextStyle(color: bgTheme.textColor),
        ),
      );
    }

    final currentSeason = _currentSeasonKey();
    var seasonal = _cities
        .where(
          (c) => (c['best_seasons'] as List?)?.contains(currentSeason) ?? false,
        )
        .toList();
    if (seasonal.isEmpty) seasonal = _cities.take(4).toList();

    final popular = _cities.where((c) => c['is_popular'] == true).toList();

    final bottomSafePadding = MediaQuery.of(context).padding.bottom + 90;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomSafePadding),
      children: [
        _CitiesHeader(
          bgTheme: bgTheme,
          title: 'شهرهای ایران',
          icon: Icons.place,
          iconColor: Colors.red,
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllCitiesScreen(cities: _cities),
            ),
          ),
        ),
        SizedBox(height: 230, child: _buildCitiesRow(_cities)),

        const SizedBox(height: 12),
        _CitiesHeader(
          bgTheme: bgTheme,
          title: 'پیشنهاد این فصل',
          icon: Icons.wb_sunny_rounded,
          iconColor: Colors.orangeAccent,
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllCitiesScreen(cities: seasonal),
            ),
          ),
        ),
        SizedBox(height: 200, child: _buildSeasonalRow(seasonal)),

        const SizedBox(height: 12),
        _CitiesHeader(
          bgTheme: bgTheme,
          title: 'شهرهای محبوب',
          icon: Icons.favorite_rounded,
          iconColor: Colors.pinkAccent,
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllCitiesScreen(cities: popular),
            ),
          ),
        ),
        SizedBox(height: 230, child: _buildCitiesRow(popular)),
      ],
    );
  }

  Widget _buildCitiesRow(List<Map<String, dynamic>> cities) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        final name = city['name_fa'] as String;

        return Listener(
          onPointerDown: (_) {
            AttractionsService.prefetchCity(
              lat: (city['lat'] as num).toDouble(),
              lng: (city['lng'] as num).toDouble(),
              cityKey: name,
            );
          },
          child: CityWeatherCard(
            city: city,
            weather: _weatherByCity[name],
            isLoadingWeather: _pendingWeather.contains(name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttractionsScreen(city: city),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSeasonalRow(List<Map<String, dynamic>> cities) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        final name = city['name_fa'] as String;

        return Listener(
          // 🔹 به محض شروع فشردن کارت، دانلود سریعاً شروع می‌شود
          onPointerDown: (_) {
            AttractionsService.prefetchCity(
              lat: (city['lat'] as num).toDouble(),
              lng: (city['lng'] as num).toDouble(),
              cityKey: name,
            );
          },
          child: SeasonalPickCard(
            city: city,
            weather: _weatherByCity[name],
            isLoadingWeather: _pendingWeather.contains(name),
            tagline:
                (city['seasonal_tagline'] as String?) ??
                _seasonalTaglines[index % _seasonalTaglines.length],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttractionsScreen(city: city),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final AppBackgroundTheme bgTheme;
  const _Header({required this.bgTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 28),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: bgTheme.travelTextColor,
            ).createShader(bounds),
            child: const Text(
              'سفر کن',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: bgTheme.memoryTextColor,
            ).createShader(bounds),
            child: const Text(
              'خاطره بساز',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final AppBackgroundTheme bgTheme;
  const _SearchBar({required this.bgTheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bgTheme.textColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: bgTheme.textColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: bgTheme.textColor.withOpacity(0.8),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '...جستجوی شهر',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: bgTheme.textColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CitiesHeader extends StatelessWidget {
  final AppBackgroundTheme bgTheme;
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onSeeAll;

  const _CitiesHeader({
    required this.bgTheme,
    required this.title,
    required this.icon,
    required this.iconColor,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: bgTheme.textColor,
                ),
              ),
            ],
          ),

          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: bgTheme.textColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: bgTheme.textColor.withOpacity(0.2)),
                ),
              ),
              child: const Text(
                'مشاهده همه',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}