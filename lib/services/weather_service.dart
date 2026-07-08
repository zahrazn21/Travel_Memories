import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temp;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;

  const WeatherData({
    required this.temp,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });
}

class WeatherService {
  static Future<WeatherData?> fetch({
    required double lat,
    required double lng,
  }) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lng'
      '&current=temperature_2m,weather_code'
      '&daily=temperature_2m_max,temperature_2m_min'
      '&timezone=auto',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    return WeatherData(
      temp: (data['current']['temperature_2m'] as num).toDouble(),
      maxTemp: (data['daily']['temperature_2m_max'][0] as num).toDouble(),
      minTemp: (data['daily']['temperature_2m_min'][0] as num).toDouble(),
      weatherCode: data['current']['weather_code'] as int,
    );
  }
}