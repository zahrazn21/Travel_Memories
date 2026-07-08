import 'package:flutter/material.dart';

@immutable
class AppMenuTheme extends ThemeExtension<AppMenuTheme> {
  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;
  final Color textColor;
  final Color boxShadowColor; 

  const AppMenuTheme({
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
    required this.textColor,
    required this.boxShadowColor, 
  });

  @override
  AppMenuTheme copyWith({
    List<Color>? gradientColors,
    Color? borderColor,
    Color? shadowColor,
    Color? textColor,
    Color? boxShadowColor, 
  }) {
    return AppMenuTheme(
      gradientColors: gradientColors ?? this.gradientColors,
      borderColor: borderColor ?? this.borderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      textColor: textColor ?? this.textColor,
      boxShadowColor: boxShadowColor ?? this.boxShadowColor, // 👈 اضافه شد
    );
  }

  @override
  AppMenuTheme lerp(ThemeExtension<AppMenuTheme>? other, double t) {
    if (other is! AppMenuTheme) return this;
    return AppMenuTheme(
      gradientColors: t < 0.5 ? gradientColors : other.gradientColors,
      borderColor: t < 0.5 ? borderColor : other.borderColor,
      shadowColor: t < 0.5 ? shadowColor : other.shadowColor,
      textColor: t < 0.5 ? textColor : other.textColor,
      boxShadowColor: t < 0.5 ? boxShadowColor : other.boxShadowColor, // 👈 اضافه شد
    );
  }
}