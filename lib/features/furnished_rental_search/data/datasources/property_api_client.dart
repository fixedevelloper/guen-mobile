import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../models/property_search_request_dto.dart';
import '../models/harmonized_property_offer.dart';

/// Client HTTP pour `/api/search/properties`. Chemins relatifs : l'URL de
/// base est portée par le [Dio] injecté (voir [DioClient] / [ApiConfig]).
class PropertyApiClient {
  final Dio _dio;

  PropertyApiClient(this._dio);

  Future<List<HarmonizedPropertyOffer>> searchProperties(PropertySearchRequestDto request) async {
    try {
      final response = await _dio.get('/search/properties', queryParameters: request.toJson());
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => HarmonizedPropertyOffer.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
