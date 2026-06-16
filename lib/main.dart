import 'package:flutter/material.dart';
import 'package:travel_memories/screens/home_screen.dart';
import 'package:travel_memories/screens/search_screen.dart';
import 'package:travel_memories/screens/favorites_screen.dart';
import 'package:travel_memories/screens/memories_screen.dart';
import 'package:travel_memories/screens/profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'PlaypenSansArabic'),
          displayMedium: TextStyle(fontFamily: 'PlaypenSansArabic'),
          displaySmall: TextStyle(fontFamily: 'PlaypenSansArabic'),
          headlineMedium: TextStyle(fontFamily: 'PlaypenSansArabic'),
          headlineSmall: TextStyle(fontFamily: 'PlaypenSansArabic'),
          titleLarge: TextStyle(fontFamily: 'PlaypenSansArabic'),
          titleMedium: TextStyle(fontFamily: 'PlaypenSansArabic'),
          titleSmall: TextStyle(fontFamily: 'PlaypenSansArabic'),
          bodyLarge: TextStyle(fontFamily: 'PlaypenSansArabic'),
          bodyMedium: TextStyle(fontFamily: 'PlaypenSansArabic'),
          bodySmall: TextStyle(fontFamily: 'PlaypenSansArabic'),
          labelLarge: TextStyle(fontFamily: 'PlaypenSansArabic'),
          labelMedium: TextStyle(fontFamily: 'PlaypenSansArabic'),
          labelSmall: TextStyle(fontFamily: 'PlaypenSansArabic'),
        ),
        platform: TargetPlatform.android,
      ),
      home: const MainScreen(),
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
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

  // ترتیب: جستجو، خاطرات من، خانه، علاقه‌مندی‌ها، پروفایل
  final List<Widget> _pages = [
    const SearchScreen(),       // جستجو
    const MemoriesScreen(),     // خاطرات من
    const HomeScreen(title: 'Travel Memories'), // خانه (وسط)
    const FavoritesScreen(),    // علاقه‌مندی‌ها
    const ProfileScreen(),      // پروفایل
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontFamily: 'PlaypenSansArabic',
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'PlaypenSansArabic',
        ),
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              icon: Icons.search_outlined,
              isSelected: _selectedIndex == 0,
              index: 0,
            ),
            label: 'جستجو',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              icon: Icons.bookmark_border,
              isSelected: _selectedIndex == 1,
              index: 1,
            ),
            label: 'خاطرات',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              icon: Icons.home_outlined,
              isSelected: _selectedIndex == 2,
              index: 2,
              isHome: true,
            ),
            label: 'خانه',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              icon: Icons.favorite_border,
              isSelected: _selectedIndex == 3,
              index: 3,
            ),
            label: 'علاقه‌مندی',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(
              icon: Icons.person_outline,
              isSelected: _selectedIndex == 4,
              index: 4,
            ),
            label: 'پروفایل',
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon({
    required IconData icon,
    required bool isSelected,
    required int index,
    bool isHome = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isSelected ? 8 : (isHome ? 8 : 4)),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? Colors.pink.shade50 : Colors.transparent,
      ),
      child: Icon(
        icon,
        color: isSelected ? Colors.pink : Colors.grey.shade400,
        size: isSelected ? (isHome ? 28 : 26) : (isHome ? 26 : 22),
      ),
    );
  }
}