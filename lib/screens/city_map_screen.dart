import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_memories/themes/app_background_theme.dart';
import 'package:travel_memories/screens/full_map_screen.dart';

class CityMapWidget extends StatelessWidget {
  final Map<String, dynamic> city;
  final double height;

  const CityMapWidget({super.key, required this.city, this.height = 180});

  Future<void> _openInMapsApp(double lat, double lng) async {
    final Uri googleMapsUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    final Uri appleMapsUri = Uri.parse('https://maps.apple.com/?q=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUri)) {
        await launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
      } else {
        final Uri webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('❌ Could not launch maps app: $e');
    }
  }

  String _tileUrlFor(Color primary) {
    if (primary == const Color.fromARGB(255, 188, 225, 255)) {
      return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    }
    if (primary == const Color.fromARGB(255, 255, 207, 223)) {
      return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    }
    return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;
    final primary = Theme.of(context).primaryColor;

    final accent = theme.travelTextColor[0]; 
    final accentSoft = theme.travelTextColor[1];
    final tileUrl = _tileUrlFor(primary);

    final lat = (city['lat'] is num) 
        ? (city['lat'] as num).toDouble() 
        : (double.tryParse(city['lat']?.toString() ?? '') ?? 35.6892);
    final lng = (city['lng'] is num) 
        ? (city['lng'] as num).toDouble() 
        : (double.tryParse(city['lng']?.toString() ?? '') ?? 51.3890);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: FullMapScreen(city: city),
          ),
        ),
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: accent.withOpacity(.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.2),
              blurRadius: 25,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Hero(
                tag: 'city_map_${city['name_fa']}',
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 13,
                    initialRotation: 0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: tileUrl,
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'ir.travel_memories.app.custom_id',
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(.35),
                      ],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 55,
                    color: accent,
                    shadows: [
                      Shadow(color: accent.withOpacity(.6), blurRadius: 18),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.65),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withOpacity(.55)),
                  ),
                  child: Text(
                    city['name_fa'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: accent.withOpacity(.7), blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 18,
                child: GestureDetector(
                  onTap: () => _openInMapsApp(lat, lng),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(.65),
                      border: Border.all(color: accentSoft.withOpacity(.6)),
                      boxShadow: [
                        BoxShadow(color: accentSoft.withOpacity(.35), blurRadius: 10),
                      ],
                    ),
                    child: Icon(Icons.my_location, color: accentSoft),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}