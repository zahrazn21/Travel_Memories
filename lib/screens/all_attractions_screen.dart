import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:travel_memories/models/attraction.dart';
import 'package:travel_memories/screens/attraction_detail_screen.dart';
import 'package:travel_memories/themes/app_background_theme.dart';

class AllAttractionsScreen extends StatefulWidget {
  final List<Attraction> attractions;
  final String cityName;

  const AllAttractionsScreen({
    super.key,
    required this.attractions,
    required this.cityName,
  });

  @override
  State<AllAttractionsScreen> createState() => _AllAttractionsScreenState();
}

class _AllAttractionsScreenState extends State<AllAttractionsScreen> {
  String _query = '';

  List<Attraction> get _filtered {
    if (_query.isEmpty) return widget.attractions;
    return widget.attractions
        .where((a) => a.name.contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
        final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Scaffold(
      backgroundColor: theme.gradientColors[1],
      appBar: AppBar(
        backgroundColor:theme.gradientColors[2],
        elevation: 0,
        title: Text(
          'جاذبه‌های ${widget.cityName}',
          style:  TextStyle(color: theme.textColor, fontSize: 17),
        ),
        iconTheme:  IconThemeData(color: theme.textColor),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child: _filtered.isEmpty
                ?  Center(
                    child: Text(
                      'جاذبه‌ای پیدا نشد',
                      style: TextStyle(color: theme.textColor),
                    ),
                  )
                : _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
            final theme = Theme.of(context).extension<AppBackgroundTheme>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        textAlign: TextAlign.right,
        style:  TextStyle(color: theme.textColor),
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: ' ...جستحوی جاذبه ',
          hintStyle:  TextStyle(color: theme.textColor),
          prefixIcon:  Icon(Icons.search, color: theme.textColor),
          filled: true,
          fillColor: theme.textColor.withOpacity(0.06),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: _filtered.length,
      itemBuilder: (context, index) =>
          AttractionGridCard(attraction: _filtered[index]),
    );
  }
}


class AttractionGridCard extends StatelessWidget {
  final Attraction attraction;

  const AttractionGridCard({super.key, required this.attraction});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AttractionDetailScreen(attraction: attraction.toMap()),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                attraction.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade800,
                  child: const Icon(
                    Icons.broken_image,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
              ),
       Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.85),
        ],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          attraction.name,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.black,
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        if (attraction.inceptionYear != null) ...[
          const SizedBox(height: 3),
          Text(
            'ساخت: ${attraction.inceptionYear}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ],
    ),
  ),
),     ],
          ),
        ),
      ),
    );
  }
}

