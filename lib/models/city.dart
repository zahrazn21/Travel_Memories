class City {
  final int id;
  final String nameFa;
  final String nameEn;
  final String provinceFa;
  final double lat;
  final double lng;
  final int population;
  final String wikiEn;

  City({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.provinceFa,
    required this.lat,
    required this.lng,
    required this.population,
    required this.wikiEn,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'],
    nameFa: json['name_fa'],
    nameEn: json['name_en'],
    provinceFa: json['province_fa'],
    lat: json['lat'],
    lng: json['lng'],
    population: json['population'],
    wikiEn: json['wikipedia_en'] ?? json['name_en'],
  );
}