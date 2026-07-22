import 'package:flutter/material.dart';
import 'package:travel_memories/themes/app_menu_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final menuTheme = Theme.of(context).extension<AppMenuTheme>()!;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: menuTheme.boxShadowColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: menuTheme.shadowColor.withOpacity(1),
            blurRadius: 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.search_outlined,
            label: 'جستجو',
            isSelected: selectedIndex == 0,
            onTap: () => onItemTapped(0),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.bookmark_border,
            label: 'خاطرات',
            isSelected: selectedIndex == 1,
            onTap: () => onItemTapped(1),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.home_outlined,
            label: 'خانه',
            isSelected: selectedIndex == 2,
            onTap: () => onItemTapped(2),
            isHome: true,
          ),
          _buildNavItem(
            context: context,
            icon: Icons.favorite_border,
            label: 'علاقه‌مندی',
            isSelected: selectedIndex == 3,
            onTap: () => onItemTapped(3),
          ),
          _buildNavItem(
            context: context,
            icon: Icons.person_outline,
            label: 'پروفایل',
            isSelected: selectedIndex == 4,
            onTap: () => onItemTapped(4),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isHome = false,
  }) {
    final menuTheme = Theme.of(context).extension<AppMenuTheme>()!;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 70,
        
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 10 : 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: menuTheme.gradientColors,
                      )
                    : null,
                border: Border.all(
                  color: isSelected
                      ? menuTheme.boxShadowColor.withOpacity(0.6)
                      : Colors.transparent,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: menuTheme.boxShadowColor.withOpacity(0.5),
                          blurRadius: 25,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: menuTheme.boxShadowColor,
                          blurRadius: 15,
                          spreadRadius: -2,
                          offset: const Offset(0, 0),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? menuTheme.textColor
                    : menuTheme.textColor.withOpacity(0.5),
                size: isSelected ? (isHome ? 26 : 22) : (isHome ? 22 : 18),
                shadows: isSelected
                    ? [const Shadow(blurRadius: 10, color: Colors.white)]
                    : [],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? menuTheme.textColor
                    : menuTheme.textColor.withOpacity(0.5),
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'PlaypenSansArabic',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}