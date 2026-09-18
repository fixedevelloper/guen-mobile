import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../models/hotel_search_request_dto.dart';
import '../models/harmonized_hotel_offer.dart';
import '../models/hotel_detail.dart';
import '../models/room_offer.dart';

/// Client HTTP pour `/api/search/hotels*`. Chemins relatifs : l'URL de base
/// est portée par le [Dio] injecté (voir [DioClient] / [ApiConfig]).
class HotelApiClient {
  final Dio _dio;

  HotelApiClient(this._dio);

  /// `searchId` est `null` si aucun fournisseur actif n'a capturé de jeton de
  /// pagination pour cette recherche (voir HotelSearchResult côté Spring) —
  /// dans ce cas il n'y a rien à charger de plus, l'appelant doit masquer
  /// toute action "charger plus".
  Future<({String? searchId, List<HarmonizedHotelOffer> offers})> searchHotels(
      HotelSearchRequestDto request) async {
    try {
      final response = await _dio.get(
        '/search/hotels',
        queryParameters: request.toJson(),
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception('Format de réponse invalide.');
      }

      final offersRaw = data['offers'];
      if (offersRaw is! List) {
        throw Exception('Champ "offers" manquant ou invalide.');
      }

      return (
        searchId: data['searchId'] as String?,
        offers: offersRaw.map((json) => HarmonizedHotelOffer.fromJson(json as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Page supplémentaire d'une recherche déjà lancée par [searchHotels] (voir
  /// `searchId`) ; renvoie une liste vide une fois qu'il n'y a plus rien.
  Future<List<HarmonizedHotelOffer>> loadMoreHotels(String searchId, int pageNumber) async {
    try {
      final response = await _dio.get(
        '/search/hotels/load-more',
        queryParameters: {'searchId': searchId, 'pageNumber': pageNumber},
      );
      final data = response.data as List<dynamic>;
      return data.map((json) => HarmonizedHotelOffer.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<HotelDetail> getHotelDetail(String offerId) async {
    try {
      final response = await _dio.get('/search/hotels/details', queryParameters: {'offerId': offerId});
      return HotelDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<RoomOffer>> getHotelRooms(String offerId) async {
    try {
      final response = await _dio.get('/search/hotels/get-rooms', queryParameters: {'offerId': offerId});
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => RoomOffer.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
