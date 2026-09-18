import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../models/vehicle_search_request_dto.dart';
import '../models/harmonized_vehicle_offer.dart';

/// Client HTTP pour `/api/search/vehicles`. Chemins relatifs : l'URL de base
/// est portée par le [Dio] injecté (voir [DioClient] / [ApiConfig]).
class VehicleApiClient {
  final Dio _dio;

  VehicleApiClient(this._dio);

  Future<List<HarmonizedVehicleOffer>> searchVehicles(VehicleSearchRequestDto request) async {
    try {
      final response = await _dio.get('/search/vehicles', queryParameters: request.toJson());
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => HarmonizedVehicleOffer.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
