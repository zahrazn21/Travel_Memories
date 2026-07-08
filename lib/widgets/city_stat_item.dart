import 'package:flutter/material.dart';
import 'package:travel_memories/themes/app_background_theme.dart';

/// A small "icon + value + label" column, e.g. population, area, province.
class CityStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const CityStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Column(
      children: [
        Icon(icon, color: theme.textColor.withOpacity(0.7), size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style:  TextStyle(
            color: theme.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: theme.textColor.withOpacity(0.5), fontSize: 10),
        ),
      ],
    );
  }
}