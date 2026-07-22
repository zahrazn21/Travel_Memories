class Attraction {
  final String name;
  final String? description;
  final String? website;
  final String? inceptionYear;
  final String image;
  final double? lat;
  final double? lng;
  final String? province; // 👈 جدید

  const Attraction({
    required this.name,
    required this.image,
    this.description,
    this.website,
    this.inceptionYear,
    this.lat,
    this.lng,
    this.province, // 👈 جدید
  });

  factory Attraction.fromMap(Map<String, dynamic> map) {
    return Attraction(
      name: map['name'] as String,
      image: map['image'] as String,
      description: map['description'] as String?,
      website: map['website'] as String?,
      inceptionYear: map['inception'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      province: map['province'] as String?, // 👈 جدید
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'website': website,
      'inception': inceptionYear,
      'image': image,
      'lat': lat,
      'lng': lng,
      'province': province, // 👈 جدید
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Attraction && other.name == name);

  @override
  int get hashCode => name.hashCode;
}