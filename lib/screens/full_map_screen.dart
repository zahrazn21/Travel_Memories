import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_memories/themes/app_background_theme.dart';

class FullMapScreen extends StatefulWidget {
  final Map<String, dynamic> city;

  const FullMapScreen({super.key, required this.city});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final MapController _mapController = MapController();
  double _zoom = 13;

  String _tileUrlFor(Color primary) {
    if (primary == Colors.blue) {
      return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    }
    if (primary == Colors.pink) {
      return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
    }
    return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  }

  void _zoomBy(double delta) {
    final newZoom = (_zoom + delta).clamp(3.0, 18.0);
    setState(() => _zoom = newZoom);
    _mapController.move(_mapController.camera.center, newZoom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppBackgroundTheme>()!;
    final primary = Theme.of(context).primaryColor;
    final accent = theme.travelTextColor[0];
    final accentSoft = theme.travelTextColor[1];
    final tileUrl = _tileUrlFor(primary);

    final lat = widget.city['lat'] ?? 35.6892;
    final lng = widget.city['lng'] ?? 51.3890;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Hero(
            tag: 'city_map_${widget.city['name_fa']}',
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: _zoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lng),
                      width: 55,
                      height: 55,
                      child: Icon(
                        Icons.location_on_rounded,
                        size: 55,
                        color: accent,
                        shadows: [
                          Shadow(color: accent.withOpacity(.6), blurRadius: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            top: 12,
            right: 12,
            child: SafeArea(
              child: Material(
                color: Colors.black.withOpacity(.6),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_back,
                      color: accent,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, left: 14),
              child: Align(
                alignment: Alignment.topLeft,
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
                    widget.city['name_fa'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      shadows: [
                        Shadow(color: accent.withOpacity(.7), blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 14,
            child: Column(
              children: [
                _zoomButton(
                  icon: Icons.add,
                  color: accent,
                  onTap: () => _zoomBy(1),
                ),
                const SizedBox(height: 10),
                _zoomButton(
                  icon: Icons.remove,
                  color: accentSoft,
                  onTap: () => _zoomBy(-1),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 30,
            right: 14,
            child: _zoomButton(
              icon: Icons.my_location,
              color: accentSoft,
              onTap: () {
                setState(() => _zoom = 13);
                _mapController.move(LatLng(lat, lng), 13);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withOpacity(.65),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(.6)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
