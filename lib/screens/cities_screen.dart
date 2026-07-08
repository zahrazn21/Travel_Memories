import 'package:flutter/material.dart';
import '../models/city.dart';
import '../services/wiki_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class CityCard extends StatelessWidget {
  final City city;
  const CityCard({required this.city});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FutureBuilder<String?>(
            future: WikiService.getImageUrl(city.nameEn),
            builder: (context, snap) {
              if (snap.hasData && snap.data != null) {
                return Image.network(
                  snap.data!,
                  height: 130,
                  fit: BoxFit.cover,
                );
              }
              return Container(
                height: 130,
                color: Colors.grey[200],
                child: const Icon(Icons.location_city, size: 40, color: Colors.grey),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city.nameFa, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(city.provinceFa, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CitiesScreen extends StatefulWidget {
  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}


Future<List<City>> loadCities() async {
  final raw = await rootBundle.loadString('assets/iran_cities.json');
  final json = jsonDecode(raw);
  return (json['cities'] as List)
      .map((e) => City.fromJson(e))
      .toList();
}

class _CitiesScreenState extends State<CitiesScreen> {
  List<City> _cities = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    loadCities().then((list) => setState(() => _cities = list));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _cities
        : _cities.where((c) =>
            c.nameFa.contains(_query) ||
            c.nameEn.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('شهرهای ایران')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'جستجو...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) => CityCard(city: filtered[i]),
            ),
          ),
        ],
      ),
    );
  }
}