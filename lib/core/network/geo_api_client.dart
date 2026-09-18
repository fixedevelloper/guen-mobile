import 'package:dio/dio.dart';

/// Option de ville renvoyée par `/api/geo/cities`, réutilisée pour tous les
/// champs "ville" (hôtels, véhicules, meublés) — même pattern que
/// `searchCitySuggestions` côté frontend Next.js. `code` est en réalité le
/// nom de ville brut (`cityName`), pas un code ISO/IATA : c'est cette valeur
/// qu'il faut renvoyer telle quelle dans les requêtes de recherche.
class CityOption {
  final String code;
  final String title;
  final String subtitle;

  const CityOption({required this.code, required this.title, required this.subtitle});
}

class GeoApiClient {
  final Dio _dio;

  GeoApiClient(this._dio);

  Future<List<CityOption>> searchCities(String query, {int limit = 8}) async {
    if (query.trim().length < 2) return const [];
    try {
      final response = await _dio.get(
        '/geo/cities',
        queryParameters: {'q': query.trim(), 'limit': limit},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) {
        final cityName = json['cityName'] as String? ?? '';
        return CityOption(
          code: cityName,
          title: cityName,
          subtitle: json['countryName'] as String? ?? '',
        );
      }).toList();
    } on DioException {
      return const [];
    }
  }
  Future<List<CityOption>> searchAirports(String query, {int limit = 8}) async {
    if (query.trim().length < 2) return const [];
    try {
      final response = await _dio.get(
        '/geo/airports',
        queryParameters: {'q': query.trim(), 'limit': limit},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) {
        final airportCode = json['airportCode'] as String? ?? '';
        return CityOption(
          code: airportCode,
          title: json['airportName'] as String? ?? '',
          subtitle: json['city'] as String? ?? '',
        );
      }).toList();
    } on DioException {
      return const [];
    }
  }
}
