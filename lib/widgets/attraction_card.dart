import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:travel_memories/models/attraction.dart';
import 'package:travel_memories/screens/attraction_detail_screen.dart';
import 'package:travel_memories/services/attractions_service.dart';
import 'package:travel_memories/services/favorites_service.dart';
import 'package:travel_memories/widgets/retryable_network_image.dart';

class AttractionCard extends StatelessWidget {
  final Attraction attraction;
  final double? width;
  final double? height;
  final bool showFavoriteButton;
  final String? cityName;
  final String? cityImage;
  final String? cityKey;
  final void Function(String imageUrl)? onImageFound;

  const AttractionCard({
    super.key,
    required this.attraction,
    this.width,
    this.height,
    this.showFavoriteButton = true,
    this.cityName,
    this.cityImage,
    this.cityKey,
    this.onImageFound,
  });

  String get _fallbackAsset {
    if (cityImage != null && cityImage!.isNotEmpty && cityImage != 'null') {
      return 'images/cities/$cityImage';
    }
    return 'images/3.png';
  }

  Future<void> _openDetail(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttractionDetailScreen(
          attraction: attraction.toMap(),
          cityName: cityName,
          onImageFound: (imageUrl) async {
            if (imageUrl.trim().isEmpty) {
              return;
            }

            attraction.image = imageUrl;
            onImageFound?.call(imageUrl);

            if (cityKey != null && cityKey!.trim().isNotEmpty) {
              await AttractionsService.updateAttractionImage(
                cityKey: cityKey!,
                attractionName: attraction.name,
                imageUrl: imageUrl,
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayCity = (cityName != null && cityName!.isNotEmpty)
        ? cityName
        : attraction.province;

    final hasImage =
        attraction.image != null && attraction.image!.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: SizedBox(
        width: width ?? 120,
        height: height ?? 200,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Hero(
                    tag: hasImage ? attraction.image! : attraction.name,
                    child: hasImage
                        ? RetryableNetworkImage(
                            key: ValueKey(attraction.image),
                            url: attraction.image!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            headers: const {
                              'User-Agent':
                                  'TravelMemoriesApp/1.0 '
                                  '(https://github.com/zahrazn21/Travel_Memories)',
                            },
                            fallbackBuilder: (_) {
                              return Image.asset(
                                _fallbackAsset,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            _fallbackAsset,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),

                if (showFavoriteButton)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: AnimatedBuilder(
                      animation: FavoritesService.instance,
                      builder: (context, _) {
                        final isFav = FavoritesService.instance.isFavorite(
                          attraction,
                        );
                        return GestureDetector(
                          onTap: () {
                            FavoritesService.instance.toggle(attraction);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav
                                  ? const Color.fromARGB(255, 255, 60, 125)
                                  : Colors.white,
                              size: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
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
                              Colors.black.withOpacity(0.2),
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [0.0, 1.0],
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
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (displayCity != null &&
                                displayCity!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.white70,
                                    size: 11,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      displayCity!,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (attraction.inceptionYear != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'ساخت: ${attraction.inceptionYear}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}