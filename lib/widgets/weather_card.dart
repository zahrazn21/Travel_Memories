import 'package:flutter/material.dart';
import 'package:travel_memories/services/weather_service.dart';
import 'package:travel_memories/services/weather_style.dart';
import 'package:travel_memories/themes/app_background_theme.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData? weather;

  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final style = WeatherInfo.fromCode(weather?.weatherCode);
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 65, 74, 237).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                style.icon,
                size: 45,
                color: style.color,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: style.shadowColor,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weather != null ? '${weather!.temp.round()}°' : '--',
                    style:  TextStyle(
                      fontSize: 18,
                      color: theme.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    style.label,
                    style:  TextStyle(color: theme.textColor, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'حداکثر ${weather != null ? weather!.maxTemp.round() : '--'}°',
                style:  TextStyle(color: theme.textColor, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'حداقل ${weather != null ? weather!.minTemp.round() : '--'}°',
                style:  TextStyle(color: theme.textColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}