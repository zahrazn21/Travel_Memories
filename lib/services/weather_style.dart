import 'package:flutter/material.dart';

class WeatherInfo {
  final IconData icon;
  final String label;
  final Color color;
  final Color shadowColor;

  const WeatherInfo({
    required this.icon,
    required this.label,
    required this.color,
    required this.shadowColor,
  });

  factory WeatherInfo.fromCode(int? code) {
    switch (code) {
      case 0:
        return const WeatherInfo(
          icon: Icons.wb_sunny_rounded,
          label: 'آفتابی',
          color: Colors.orangeAccent,
          shadowColor: Color(0xFFFFB300),
        );
      case 1:
      case 2:
      case 3:
        return const WeatherInfo(
          icon: Icons.wb_cloudy_rounded,
          label: 'نیمه ابری',
          color: Colors.blueGrey,
          shadowColor: Color(0xFF90CAF9),
        );
      case 45:
      case 48:
        return const WeatherInfo(
          icon: Icons.foggy,
          label: 'مه',
          color: Colors.grey,
          shadowColor: Color(0xFFB0BEC5),
        );
      case 51:
      case 53:
      case 55:
        return const WeatherInfo(
          icon: Icons.grain,
          label: 'نم‌نم باران',
          color: Colors.lightBlueAccent,
          shadowColor: Color(0xFF42A5F5),
        );
      case 61:
      case 63:
      case 65:
        return const WeatherInfo(
          icon: Icons.grain,
          label: 'بارانی',
          color: Colors.lightBlueAccent,
          shadowColor: Color(0xFF42A5F5),
        );
      case 71:
      case 73:
      case 75:
        return const WeatherInfo(
          icon: Icons.ac_unit,
          label: 'برفی',
          color: Colors.cyanAccent,
          shadowColor: Color(0xFF80DEEA),
        );
      case 95:
        return const WeatherInfo(
          icon: Icons.flash_on,
          label: 'رعد و برق',
          color: Colors.amber,
          shadowColor: Color(0xFFFFD54F),
        );
      default:
        return const WeatherInfo(
          icon: Icons.wb_sunny_rounded,
          label: 'نامشخص',
          color: Colors.orangeAccent,
          shadowColor: Color(0xFFFFB300),
        );
    }
  }
}