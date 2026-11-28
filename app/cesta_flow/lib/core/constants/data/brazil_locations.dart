import 'dart:convert';

import 'package:flutter/services.dart';

class BrazilState {
  const BrazilState({required this.uf, required this.name});

  final String uf;
  final String name;
}

class BrazilLocations {
  BrazilLocations._({required this.states, required this.citiesByUf});

  final List<BrazilState> states;
  final Map<String, List<String>> citiesByUf;

  static BrazilLocations? _cache;

  static Future<BrazilLocations> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString('assets/data/brazil_locations.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final statesJson = decoded['states'] as List<dynamic>;
    final citiesJson = decoded['citiesByUf'] as Map<String, dynamic>;

    final states = statesJson
        .map(
          (item) => BrazilState(
            uf: (item as Map<String, dynamic>)['uf'] as String,
            name: item['name'] as String,
          ),
        )
        .toList();

    final citiesByUf = <String, List<String>>{};
    for (final entry in citiesJson.entries) {
      citiesByUf[entry.key] = List<String>.from(entry.value as List<dynamic>);
    }

    final loaded = BrazilLocations._(states: states, citiesByUf: citiesByUf);
    _cache = loaded;
    return loaded;
  }

  /// Interpreta valor salvo (UF ou nome completo) como sigla.
  String? resolveStateUf(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    for (final state in states) {
      if (state.uf.toUpperCase() == trimmed.toUpperCase()) return state.uf;
      if (state.name.toLowerCase() == trimmed.toLowerCase()) return state.uf;
    }
    return null;
  }

  String? stateNameFor(String? uf) {
    if (uf == null) return null;
    for (final state in states) {
      if (state.uf == uf) return state.name;
    }
    return null;
  }

  List<String> citiesFor(String uf) => citiesByUf[uf] ?? const [];

  String? resolveCityName(String uf, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    for (final city in citiesFor(uf)) {
      if (city == trimmed) return city;
      if (city.toLowerCase() == trimmed.toLowerCase()) return city;
    }
    return null;
  }
}