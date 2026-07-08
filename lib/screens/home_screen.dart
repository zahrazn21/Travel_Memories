import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:travel_memories/screens/attractions_screen.dart';
import 'dart:ui';

import 'package:travel_memories/themes/app_background_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _attractions = [];
  List<dynamic> cities = [];

  bool _isLoading = true;
  String _errorMessage = '';
  String getWeatherText(int code) {
    switch (code) {
      case 0:
        return 'آفتابی';
      case 1:
      case 2:
      case 3:
        return 'نیمه ابری';
      case 45:
      case 48:
        return 'مه';
      case 51:
      case 53:
      case 55:
        return 'نم نم باران';
      case 61:
      case 63:
      case 65:
        return 'بارانی';
      case 71:
      case 73:
      case 75:
        return 'برفی';
      case 95:
        return 'رعد و برق';
      default:
        return 'نامشخص';
    }
  }

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
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse('$baseUrl&apiKey=$apiKey');

      print(apiKey);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List? ?? [];

        setState(() {
          _attractions = features;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'خطا: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطا در ارتباط: $e';
      });
    }
  }

Future<void> loadCities() async {
  try {
    final String response = await rootBundle.loadString('data/cities.json');
    final data = json.decode(response);
    final loadedCities = data['cities'] as List;

    await Future.wait(loadedCities.map((city) async {
      final weather = await getWeather(city['lat'], city['lng']);
      city['weather'] = weather;
    }));

    setState(() {
      cities = loadedCities;
    });
  } catch (e) {
    print("ERROR => $e");
  }
}
  IconData getWeatherIcon(int code) {
    switch (code) {
      case 1:
        return Icons.wb_sunny_outlined; // آفتابی
      case 2:
        return Icons.wb_cloudy_outlined; // نیمه ابری
      case 3:
        return Icons.cloud_outlined; // ابری
      case 4:
        return Icons.grain; // بارانی
      case 5:
        return Icons.ac_unit; // برفی
      case 6:
        return Icons.foggy; // مه‌آلود
      default:
        return Icons.wb_sunny_outlined;
    }
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final current = data['current'];

        return {
          'temp': current['temperature_2m'],
          'humidity': current['relative_humidity_2m'],
          'wind': current['wind_speed_10m'],
          'weatherCode': current['weather_code'],
        };
      }

      return null;
    } catch (e) {
      print('Weather Error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
      final bgTheme = Theme.of(context).extension<AppBackgroundTheme>()!; // این خط باید باشه

    return Scaffold(
      body: Stack(
        children: [
          // Container(
          //   height: MediaQuery.of(context).size.height,
          //   width: MediaQuery.of(context).size.width,
          //   decoration: const BoxDecoration(
          //     image: DecorationImage(
          //       image: AssetImage("images/darkTheme.png"),
          //       fit: BoxFit.cover,
          //       alignment: Alignment.topCenter,
          //     ),
          //   ),
          // ),
      
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
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            width: double.infinity,
            height: 400,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              width: double.infinity, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 28),
                  ShaderMask(
                    shaderCallback: (bounds) =>  LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: bgTheme.travelTextColor,
                    ).createShader(bounds),
                    child: const Text(
                      ' سفر کن',
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
                    shaderCallback: (bounds) =>  LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: bgTheme.memoryTextColor,
                    ).createShader(bounds),
                    child: const Text(
                      ' خاطره بساز',
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

                  const SizedBox(height: 2),

                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white70],
                    ).createShader(bounds),
                    child:  Text(
                      '...هر سفر یک خاطره جدید',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: bgTheme.textColor,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black12,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 200,
                    left: 80, 
                    right: 80,
                    bottom: 16,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgTheme.textColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: bgTheme.textColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          textAlign:
                              TextAlign.right,
                          style:  TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: ' ...جستجوی شهر',
                            hintStyle: TextStyle(
                              color: bgTheme.textColor.withOpacity(0.6),
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                right: 8,
                              ), 
                              child: Icon(
                                Icons.search,
                                color: bgTheme.textColor.withOpacity(0.8),
                                size: 22,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                            ),
                            filled: true,
                            fillColor: const Color.fromARGB(0, 155, 151, 151),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, 
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Expanded(
                //   child: _isLoading
                //       ? const Center(child: CircularProgressIndicator())
                //       : _errorMessage.isNotEmpty
                //       ? Center(
                //           child: Text(
                //             _errorMessage,
                //             style: const TextStyle(color: Colors.white),
                //           ),
                //         )
                //       : ListView.builder(
                //           padding: const EdgeInsets.symmetric(horizontal: 16),
                //           itemCount: _attractions.length,
                //           itemBuilder: (context, index) {
                //             final item = _attractions[index];
                //             final props = item['properties'] ?? {};

                //             return Card(
                //               margin: const EdgeInsets.only(bottom: 12),

                //               shape: RoundedRectangleBorder(
                //                 borderRadius: BorderRadius.circular(16),
                //               ),

                //               child: ListTile(
                //                 leading: const CircleAvatar(
                //                   child: Icon(Icons.location_city),
                //                 ),

                //                 title: Text(props['name'] ?? 'بدون نام'),

                //                 subtitle: Text(
                //                   props['formatted'] ?? '',
                //                   maxLines: 2,
                //                   overflow: TextOverflow.ellipsis,
                //                 ),

                //                 trailing: const Icon(
                //                   Icons.arrow_forward_ios,
                //                   size: 16,
                //                 ),
                //               ),
                //             );
                //           },
                //         ),
                // ),
                const SizedBox(height: 120),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 12.0, // بلر بیشتر
                        sigmaY: 12.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          // gradient: LinearGradient(
                          //   begin: Alignment.topCenter,
                          //   end: Alignment.bottomCenter,
                          //   colors: bgTheme.gradientColors,
                          // ),
                          border: Border(
                            top: BorderSide(
                              color: bgTheme.borderColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 0.2,
                                    ),
                                    decoration: BoxDecoration(
                                      // color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: bgTheme.textColor.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: bgTheme.textColor,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text(
                                        'مشاهده همه',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                   Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'شهرهای ایران',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: bgTheme.textColor,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.place,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  // gradient: LinearGradient(
                                  //   begin: Alignment.topCenter,
                                  //   end: Alignment.bottomCenter,
                                  //   colors: [
                                  //     Color.fromARGB(255, 7, 4, 48),
                                  //     Color.fromARGB(255, 19, 10, 107),
                                  //   ],
                                  // ),
                                ),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                    reverse: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  itemCount: cities.length,
                                  itemBuilder: (context, index) {
                                    final city = cities[index];
                                    final weather = city['weather'];

                                    return SizedBox(
                                      width: 130,
                                      height: 60,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                          vertical: 3,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          splashColor: Colors.orange
                                              .withOpacity(0.1),
                                          highlightColor: Colors.orange
                                              .withOpacity(0.05),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AttractionsScreen(
                                                      city: city,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  child: Image.asset(
                                                    "images/cities/${city['image']}",
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Container(
                                                          color: Colors
                                                              .grey
                                                              .shade300,
                                                          child: const Icon(
                                                            Icons.broken_image,
                                                            size: 40,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                  ),
                                                ),

                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                          bottomLeft:
                                                              Radius.circular(
                                                                14,
                                                              ),
                                                          bottomRight:
                                                              Radius.circular(
                                                                14,
                                                              ),
                                                          topLeft:
                                                              Radius.circular(
                                                                20,
                                                              ),
                                                          topRight:
                                                              Radius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                    child: BackdropFilter(
                                                      filter: ImageFilter.blur(
                                                        sigmaX: 6.0,
                                                        sigmaY: 6.0,
                                                      ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            begin: Alignment
                                                                .topCenter,
                                                            end: Alignment
                                                                .bottomCenter,
                                                            colors: [
                                                              Colors.black
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                              Colors.black
                                                                  .withOpacity(
                                                                    0.7,
                                                                  ),
                                                            ],
                                                            stops: const [
                                                              0.0,
                                                              1.0,
                                                            ],
                                                          ),
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              city['name_fa'],
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white,
                                                                shadows: [
                                                                  Shadow(
                                                                    blurRadius:
                                                                        3,
                                                                    color: Colors
                                                                        .black26,
                                                                    offset:
                                                                        Offset(
                                                                          0,
                                                                          1,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                            ),

                                                            const SizedBox(
                                                              height: 3,
                                                            ),

                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: [
                                                                Text(
                                                                  '${weather?['temp'] ?? '--'}°',
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .white,
                                                                    shadows: [
                                                                      Shadow(
                                                                        blurRadius:
                                                                            3,
                                                                        color: Colors
                                                                            .black26,
                                                                        offset:
                                                                            Offset(
                                                                              0,
                                                                              1,
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 40,
                                                                ), 
                                                                Icon(
                                                                  weather !=
                                                                          null
                                                                      ? getWeatherIcon(
                                                                          weather['weatherCode'],
                                                                        )
                                                                      : Icons
                                                                            .wb_sunny_outlined,
                                                                  size: 16,
                                                                  color: Colors
                                                                      .white,
                                                                  shadows: const [
                                                                    Shadow(
                                                                      blurRadius:
                                                                          3,
                                                                      color: Colors
                                                                          .black26,
                                                                      offset:
                                                                          Offset(
                                                                            0,
                                                                            1,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),

                                                            const SizedBox(
                                                              height: 2,
                                                            ),

                                                            Text(
                                                              weather != null
                                                                  ? getWeatherText(
                                                                      weather['weatherCode'],
                                                                    )
                                                                  : 'در حال دریافت...',
                                                              textAlign:
                                                                  TextAlign
                                                                      .right,
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white70,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
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
}
