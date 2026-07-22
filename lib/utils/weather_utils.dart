import 'package:flutter/material.dart';

class WeatherUtils {
  WeatherUtils._();

  static const Map<int, _WeatherInfo> _codeMap = {
    0: _WeatherInfo('آفتابی', Icons.wb_sunny_outlined),
    1: _WeatherInfo('نیمه آفتابی', Icons.wb_sunny_outlined),
    2: _WeatherInfo('نیمه ابری', Icons.wb_cloudy_outlined),
    3: _WeatherInfo('ابری', Icons.cloud_outlined),
    45: _WeatherInfo('مه‌آلود', Icons.foggy),
    48: _WeatherInfo('مه‌آلود', Icons.foggy),
    51: _WeatherInfo('نم‌نم باران', Icons.grain),
    53: _WeatherInfo('نم‌نم باران', Icons.grain),
    55: _WeatherInfo('نم‌نم باران', Icons.grain),
    61: _WeatherInfo('بارانی', Icons.water_drop_outlined),
    63: _WeatherInfo('بارانی', Icons.water_drop_outlined),
    65: _WeatherInfo('بارانی شدید', Icons.water_drop),
    71: _WeatherInfo('برفی', Icons.ac_unit),
    73: _WeatherInfo('برفی', Icons.ac_unit),
    75: _WeatherInfo('برف شدید', Icons.ac_unit),
    95: _WeatherInfo('رعد و برق', Icons.thunderstorm_outlined),
  };

  static const _WeatherInfo _fallback = _WeatherInfo(
    'نامشخص',
    Icons.wb_sunny_outlined,
  );

  static String textFor(int? code) =>
      (code == null ? null : _codeMap[code])?.label ?? _fallback.label;

  static IconData iconFor(int? code) =>
      (code == null ? null : _codeMap[code])?.icon ?? _fallback.icon;
}

class _WeatherInfo {
  final String label;
  final IconData icon;
  const _WeatherInfo(this.label, this.icon);
}
