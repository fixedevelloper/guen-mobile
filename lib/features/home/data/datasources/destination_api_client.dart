import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../models/featured_destination.dart';

/// Client HTTP pour `/api/destinations/**` (voir DestinationController côté
/// Spring) — endpoint public en lecture seule, pas besoin de session.
class DestinationApiClient {
  final Dio _dio;

  DestinationApiClient(this._dio);

  Future<List<FeaturedDestination>> featured() async {
    try {
      final response = await _dio.get('/destinations/featured');
      final data = response.data as List<dynamic>;
      return data.map((json) => FeaturedDestination.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
