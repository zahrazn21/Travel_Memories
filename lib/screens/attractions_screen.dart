import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:travel_memories/models/attraction.dart';
import 'package:travel_memories/screens/all_attractions_screen.dart';
import 'package:travel_memories/screens/city_map_screen.dart';
import 'package:travel_memories/services/attractions_service.dart';
import 'package:travel_memories/services/city_data_service.dart';
import 'package:travel_memories/services/weather_service.dart';
import 'package:travel_memories/themes/app_background_theme.dart';
import 'package:travel_memories/widgets/attraction_card.dart';
import 'package:travel_memories/widgets/city_stat_item.dart';
import 'package:travel_memories/widgets/wave_clipper.dart';
import 'package:travel_memories/widgets/weather_card.dart';

class AttractionsScreen extends StatefulWidget {
  final Map<String, dynamic> city;

  const AttractionsScreen({super.key, required this.city});

  @override
  State<AttractionsScreen> createState() => _AttractionsScreenState();
}

class _AttractionsScreenState extends State<AttractionsScreen> {
  final _attractionsService = AttractionsService();

  List<Attraction> _attractions = [];
  bool _isLoadingAttractions = true;
  String _attractionsError = '';

  WeatherData? _weather;
  Map<String, dynamic>? _cityInfo;

  @override
  void initState() {
    super.initState();
    _loadAttractions();
    _loadWeather();
    _loadCityInfo();
  }

  // @override
  // void dispose() {
  //   _attractionsService.dispose();
  //   super.dispose();
  // }

  double get _lat => widget.city['lat'];
  double get _lng => widget.city['lng'];
  String get _cityNameFa => widget.city['name_fa'];

  Future<void> _loadCityInfo() async {
    final city = await CityDataService.getCityByName(_cityNameFa);
    if (!mounted) return;
    setState(() => _cityInfo = city);
  }

  Future<void> _loadWeather() async {
    final data = await WeatherService.fetch(lat: _lat, lng: _lng);
    if (!mounted) return;
    setState(() => _weather = data);
  }

  Future<void> _loadAttractions() async {
    try {
      final results = await _attractionsService.fetchNear(lat: _lat, lng: _lng);
      if (!mounted) return;
      setState(() {
        _attractions = results;
        _isLoadingAttractions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attractionsError = e.toString();
        _isLoadingAttractions = false;
      });
    }
  }

  String get _slogan => _cityInfo?['slogan'] ?? 'لقب موجود نیست';

  String _formatPopulation(num? population) {
    if (population == null) return '--';
    if (population >= 1000000) {
      return '${(population / 1000000).toStringAsFixed(1)} میلیون';
    }
    return population.toStringAsFixed(0);
  }

  String _formatArea(num? area) {
    if (area == null) return '--';
    return '$area km²';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          _buildTopImage(),
          _buildTopImageOverlay(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 190),
                Expanded(child: _buildContentPanel()),
              ],
            ),
          ),
          _buildBackButton(),

        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
      final theme = Theme.of(context).extension<AppBackgroundTheme>()!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.gradientColors,
        ),
      ),
    );
  }

  Widget _buildTopImage() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        width: double.infinity,
        height: 280,
        child: Image.asset(
          "images/cities/${widget.city['image']}",
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTopImageOverlay() {
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 280,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:theme.imageShadowColors,
          ),
        ),
      ),
    );
  }

  Widget _buildContentPanel() {
  final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

  return CustomPaint(
    painter: const WaveBorderPainter(),
    child: ClipPath(
      clipper: const WaveClipper(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: theme.panelBackgroundColors,
            ),
          ),
               child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // بخش ثابت (بدون اسکرول)
              const SizedBox(height: 16),
              _buildCityTitle(),
              const SizedBox(height: 4),
              _buildSlogan(),
              const SizedBox(height: 10),

              // بخش اسکرول‌شونده
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCityStatsRow(),
                      const SizedBox(height: 10),
                      if (_cityInfo?['about'] != null) ...[
                        _buildAboutSection(),
                        const SizedBox(height: 10),
                      ],
                      WeatherCard(weather: _weather),
                      const SizedBox(height: 14),
                      _sectionTitle('جاذبه‌های دیدنی'),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AllAttractionsScreen(
                              attractions: _attractions,
                              cityName: _cityNameFa,
                            ),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child:  Text(
                          'مشاهده همه',
                          style: TextStyle(
                            color: theme.travelTextColor[1],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAttractionsList(),
                      const SizedBox(height: 14),
                      _sectionTitle('موقعیت $_cityNameFa روی نقشه'),
                      const SizedBox(height: 8),
                      CityMapWidget(city: widget.city, height: 180),
                      const SizedBox(height: 16),
                      _buildAddMemoryButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
  
        )
       ),
    ),
  );
}
 
  Widget _buildCityTitle() {
              final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _cityNameFa,
            style:  TextStyle(
              color: theme.travelTextColor[1],
              fontSize: 28,
              fontWeight: FontWeight.bold,
              // shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.place,
            color: Color.fromARGB(255, 255, 60, 125),
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildSlogan() {
              final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Text(
      _slogan,
      textAlign: TextAlign.center,
      style:  TextStyle(
        color: theme.textColor,
        fontSize: 13,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget _buildCityStatsRow() {
          final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 65, 74, 237).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CityStatItem(
            label: 'استان',
            value: _cityInfo?['province_fa'] ?? '--',
            icon: Icons.location_city,
          ),
          _verticalDivider(),
          CityStatItem(
            label: 'جمعیت',
            value: _formatPopulation(_cityInfo?['population']),
            icon: Icons.people,
          ),
          _verticalDivider(),
          CityStatItem(
            label: 'مساحت',
            value: _formatArea(_cityInfo?['area']),
            icon: Icons.square_foot,
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
              final theme = Theme.of(context).extension<AppBackgroundTheme>()!;
    return Container(
      width: 1,
      height: 30,
      color: theme.textColor.withOpacity(0.15),
    );
  }

  Widget _buildAboutSection() {
          final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 65, 74, 237).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textColor.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'درباره $_cityNameFa',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: theme.travelTextColor[1],
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _cityInfo?['about'] ?? '',
            textAlign: TextAlign.right,
            style: TextStyle(
              
              color: theme.textColor.withOpacity(0.8),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
              final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style:  TextStyle(
          color: theme.textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAttractionsList() {
          final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return SizedBox(
      height: 200,
      child: Builder(
        builder: (_) {
          if (_isLoadingAttractions) {
            return  Center(
              child: CircularProgressIndicator(color: theme.textColor),
            );
          }
          if (_attractionsError.isNotEmpty) {
            return Center(
              child: Text(
                _attractionsError,
                style: TextStyle(color: theme.textColor),
              ),
            );
          }
          if (_attractions.isEmpty) {
            return  Center(
              child: Text(
                'جاذبه‌ای پیدا نشد',
                style: TextStyle(color: theme.textColor),
              ),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _attractions.length,
            itemBuilder: (context, index) =>
                AttractionCard(attraction: _attractions[index]),
          );
        },
      ),
    );
  }

  Widget _buildAddMemoryButton() {
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
          onPressed: () {},
          icon: const Icon(Icons.edit, color: Colors.white, size: 18),
          label: const Text(
            'ثبت خاطره برای این شهر',
            style: TextStyle(
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

  
Widget _buildBackButton() {
            final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.only(top: 12, left: 12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: theme.textColor.withOpacity(0.35),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child:  Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.arrow_back,
                color: theme.textColor,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
