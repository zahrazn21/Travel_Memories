import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:travel_memories/utils/weather_utils.dart';


class CityWeatherCard extends StatelessWidget {
  final Map<String, dynamic> city;
  final Map<String, dynamic>? weather;
  final bool isLoadingWeather;
  final VoidCallback onTap;

  const CityWeatherCard({
    super.key,
    required this.city,
    required this.weather,
    required this.isLoadingWeather,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 170,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.orange.withOpacity(0.15),
            highlightColor: Colors.orange.withOpacity(0.06),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      "images/cities/${city['image']}",
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.broken_image,
                          size: 36,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.75),
                          ],
                          stops: const [0.0, 0.35, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _WeatherBadge(
                      weather: weather,
                      isLoading: isLoadingWeather,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          color: Colors.black.withOpacity(0.25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.place,
                                    color: Colors.redAccent,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      city['name_fa'] ?? '',
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 3,
                                            color: Colors.black45,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              _WeatherLine(
                                weather: weather,
                                isLoading: isLoadingWeather,
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
      ),
    );
  }
}

class _WeatherBadge extends StatelessWidget {
  final Map<String, dynamic>? weather;
  final bool isLoading;

  const _WeatherBadge({required this.weather, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _ShimmerChip(width: 44, height: 22);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            weather != null ? '${weather!['temp']}°' : '--°',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            WeatherUtils.iconFor(weather?['weatherCode'] as int?),
            size: 13,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _WeatherLine extends StatelessWidget {
  final Map<String, dynamic>? weather;
  final bool isLoading;

  const _WeatherLine({required this.weather, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Align(
        alignment: Alignment.centerRight,
        child: _ShimmerChip(width: 70, height: 10),
      );
    }
    return Text(
      weather != null
          ? WeatherUtils.textFor(weather!['weatherCode'] as int?)
          : 'در دسترس نیست',
      textAlign: TextAlign.right,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}


class _ShimmerChip extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerChip({required this.width, required this.height});

  @override
  State<_ShimmerChip> createState() => _ShimmerChipState();
}

class _ShimmerChipState extends State<_ShimmerChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15 + _controller.value * 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }
}
