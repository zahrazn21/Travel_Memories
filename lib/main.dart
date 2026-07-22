import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:travel_memories/providers/theme_provider.dart';
import 'package:travel_memories/screens/home_screen.dart';
import 'package:travel_memories/screens/search_screen.dart';
import 'package:travel_memories/screens/favorites_screen.dart';
import 'package:travel_memories/screens/memories_screen.dart';
import 'package:travel_memories/screens/profile_screen.dart';
import 'package:travel_memories/screens/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:travel_memories/services/favorites_service.dart';
import 'package:travel_memories/services/auth_service.dart';
import 'package:travel_memories/widgets/custom_bottom_nav.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoritesService.instance.load();
  await dotenv.load(fileName: ".env");

  final isLoggedIn = await AuthService.instance.isLoggedIn();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: themeProvider.currentTheme.copyWith(
        textTheme: const TextTheme(
          displayLarge:   TextStyle(fontFamily: 'PlaypenSansArabic'),
          displayMedium:  TextStyle(fontFamily: 'PlaypenSansArabic'),
          displaySmall:   TextStyle(fontFamily: 'PlaypenSansArabic'),
          headlineMedium: TextStyle(fontFamily: 'PlaypenSansArabic'),
          headlineSmall:  TextStyle(fontFamily: 'PlaypenSansArabic'),
          titleLarge:     TextStyle(fontFamily: 'PlaypenSansArabic'),
          titleMedium:    TextStyle(fontFamily: 'PlaypenSansArabic'),
          titleSmall:     TextStyle(fontFamily: 'PlaypenSansArabic'),
          bodyLarge:      TextStyle(fontFamily: 'PlaypenSansArabic'),
          bodyMedium:     TextStyle(fontFamily: 'PlaypenSansArabic'),
          bodySmall:      TextStyle(fontFamily: 'PlaypenSansArabic'),
          labelLarge:     TextStyle(fontFamily: 'PlaypenSansArabic'),
          labelMedium:    TextStyle(fontFamily: 'PlaypenSansArabic'),
          labelSmall:     TextStyle(fontFamily: 'PlaypenSansArabic'),
        ),
        platform: TargetPlatform.android,
      ),
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [
        Locale('fa', 'IR'),
        Locale('en', 'US'),
      ],
         localizationsDelegates: const [
        PersianMaterialLocalizations.delegate,
        PersianCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: isLoggedIn ? const MainScreen() : const LoginScreen(),
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: child!,
          ),
        );
      },
    );
  }
}


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    const SearchScreen(),
    const MemoriesListPage(),
    const HomeScreen(title: 'Travel Memories'),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _pages),
          Positioned(
            bottom: 10,
            left: 16,
            right: 16,
            child: CustomBottomNav(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}