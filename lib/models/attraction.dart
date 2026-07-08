class Attraction {
  final String name;
  final String? description;
  final String? website;
  final String? inceptionYear;
  final String image;
  final double? lat;
  final double? lng;

  const Attraction({
    required this.name,
    required this.image,
    this.description,
    this.website,
    this.inceptionYear,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'website': website,
      'inception': inceptionYear,
      'image': image,
      'lat': lat,
      'lng': lng,
    };
  }
}