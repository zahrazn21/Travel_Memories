import 'package:flutter/material.dart';
import 'package:travel_memories/themes/app_menu_theme.dart';
import 'app_background_theme.dart';

class AppThemes {
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.purple,
    scaffoldBackgroundColor: const Color.fromRGBO(10, 14, 39, 1),
    cardColor: const Color(0xFF16213E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0A0E27),
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    extensions: [
      const AppBackgroundTheme(
        gradientColors: [
          Color(0xFF0A0E27),
          Color.fromARGB(255, 16, 10, 42),
          Color(0xFF1A1040),
        ],
        borderColor: Color.fromARGB(183, 50, 17, 122),
        backgroundImage: "images/bgdark.png",
        travelTextColor: [
          Colors.white,
          Color.fromARGB(255, 112, 78, 205),
        ],
        memoryTextColor: [
          Colors.white,
          Color.fromARGB(255, 207, 105, 255),
        ],
        textColor: Colors.white,
        imageShadowColors: [
          Colors.transparent,
          Color.fromARGB(43, 0, 0, 0),
        ],
        panelBackgroundColors: [
          Color(0xFF0A0E27),
          Color(0xFF1A1040),
        ],
      ),
      AppMenuTheme(
        shadowColor: Color.fromARGB(152, 12, 16, 49),
        gradientColors: [
          Color.fromARGB(255, 148, 23, 157).withOpacity(0.4),
          Color.fromARGB(255, 200, 50, 200).withOpacity(0.2),
          Colors.white.withOpacity(0.1),
        ],
        borderColor: Colors.white.withOpacity(0.2),
        textColor: Colors.white,
        boxShadowColor: Color.fromARGB(255, 124, 19, 245),
      ),
    ],
  );

  static final ThemeData blue = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: const Color.fromARGB(255, 192, 222, 255),
    cardColor: const Color.fromARGB(255, 74, 97, 138),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 26, 73, 132),
      foregroundColor: Color.fromARGB(255, 15, 53, 73),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    extensions: [
      AppBackgroundTheme(
        gradientColors: [
          Color(0xFFE8F4FD),
          Color(0xFFC9E6F7),
          Color(0xFFA8D8EF),
        ],
        borderColor: Colors.white,
        backgroundImage: "images/bgblue.png",
        travelTextColor: [
          Color.fromARGB(255, 27, 99, 214),
          Color.fromARGB(255, 27, 99, 214),
        ],
        memoryTextColor: [
          Color.fromARGB(255, 27, 99, 214),
          Color.fromARGB(255, 27, 99, 214),
        ],
        textColor: Color.fromARGB(255, 22, 75, 79),
        imageShadowColors: [
          Color.fromARGB(0, 255, 255, 255),
          Color.fromARGB(255, 143, 225, 255).withOpacity(0.1),
        ],
        panelBackgroundColors: [
          Color(0xFFE8F4FD),
          Color(0xFFC9E6F7),
          Color(0xFFA8D8EF),
        ],
      ),
      AppMenuTheme(
        shadowColor: Color.fromARGB(255, 227, 241, 255),
        gradientColors: [
          Color.fromARGB(255, 255, 255, 255).withOpacity(0.4),
          Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
          Colors.white.withOpacity(0.1),
        ],
        borderColor: Colors.black12,
        textColor: Color.fromARGB(255, 31, 67, 103),
        boxShadowColor: Color.fromRGBO(37, 190, 240, 1),
      ),
    ],
  );
}