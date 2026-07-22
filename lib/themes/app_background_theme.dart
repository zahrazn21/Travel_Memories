import 'package:flutter/material.dart';

@immutable
class AppBackgroundTheme extends ThemeExtension<AppBackgroundTheme> {
  final List<Color> gradientColors;
  final String backgroundImage;
  final Color borderColor;
  final List<Color> travelTextColor;
  final List<Color> memoryTextColor;
  final Color textColor;
  final List<Color> imageShadowColors; 
  final List<Color> panelBackgroundColors; 
 const AppBackgroundTheme({
    required this.gradientColors,
    required this.backgroundImage,
    required this.borderColor,
    required this.travelTextColor,
    required this.memoryTextColor,
    required this.textColor,
    required this.imageShadowColors,
    required this.panelBackgroundColors,
  });

  @override
  AppBackgroundTheme copyWith({
    List<Color>? gradientColors,
    String? backgroundImage,
    Color? borderColor,
    List<Color>? travelTextColor,
    List<Color>? memoryTextColor,
    Color? textColor,
    List<Color>? imageShadowColors, 
    List<Color>? panelBackgroundColors,
  }) {
    return AppBackgroundTheme(
      gradientColors: gradientColors ?? this.gradientColors,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      borderColor: borderColor ?? this.borderColor,
      travelTextColor: travelTextColor ?? this.travelTextColor,
      memoryTextColor: memoryTextColor ?? this.memoryTextColor,
      textColor: textColor ?? this.textColor,
      imageShadowColors: imageShadowColors ?? this.imageShadowColors,
      panelBackgroundColors: panelBackgroundColors ?? this.panelBackgroundColors,
      
    );
  }

  @override
  AppBackgroundTheme lerp(ThemeExtension<AppBackgroundTheme>? other, double t) {
    if (other is! AppBackgroundTheme) return this;
    return AppBackgroundTheme(
      gradientColors: t < 0.5 ? gradientColors : other.gradientColors,
      backgroundImage: t < 0.5 ? backgroundImage : other.backgroundImage,
      borderColor: t < 0.5 ? borderColor : other.borderColor,
      travelTextColor: t < 0.5 ? travelTextColor : other.travelTextColor,
      memoryTextColor: t < 0.5 ? memoryTextColor : other.memoryTextColor,
      textColor: t < 0.5 ? textColor : other.textColor,
      imageShadowColors: t < 0.5 ? imageShadowColors : other.imageShadowColors, 
      panelBackgroundColors: t < 0.5 ? panelBackgroundColors : other.panelBackgroundColors, 
    );
      }
}