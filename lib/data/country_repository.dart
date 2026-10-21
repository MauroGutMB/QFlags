import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/country.dart';

/// Carrega a lista de países (nomes em PT e EN) de assets/data/countries.json.
class CountryRepository {
  CountryRepository._();
  static final instance = CountryRepository._();

  List<Country> _countries = const [];
  List<Country> get countries => _countries;

  Future<void> load() async {
    if (_countries.isNotEmpty) return;
    final raw = await rootBundle.loadString('assets/data/countries.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _countries = List.unmodifiable(
      list.map((e) => Country.fromJson(e as Map<String, dynamic>)),
    );
  }
}
