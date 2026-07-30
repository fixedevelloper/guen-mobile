import 'package:dio/dio.dart';
import '../models/flight_search_request_dto.dart';
import '../models/harmonized_flight_offer.dart';
import '../models/multi_city_itinerary.dart';
import '../models/seat_map_response.dart';
import '../models/payment_request.dart'; // N'oubliez pas cet import

class FlightApiClient {
  final Dio _dio;
  final String _baseUrl = 'http://127.0.0.1:8080/api/'; // Assurez-vous que c'est accessible depuis votre émulateur (ex: 10.0.2.2 pour Android)

  FlightApiClient(this._dio);

  Future<List<HarmonizedFlightOffer>> searchFlights(FlightSearchRequestDto request) async {
    try {
      // Envoi sous forme de queryParameters pour correspondre à @ModelAttribute
      final response = await _dio.get(
        '${_baseUrl}search/flights',
        queryParameters: request.toJson(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => HarmonizedFlightOffer.fromJson(json)).toList();
      } else {
        throw Exception('Erreur serveur lors de la recherche');
      }
    } on DioException catch (e) {
      throw Exception('Erreur réseau : ${e.message}');
    }
  }

  /// Appelle l'API Spring Boot pour une recherche Multi-destinations harmonisée
  Future<List<MultiCityItinerary>> searchMultiCityFlights(
      MultiCityFlightSearchRequestDto requestDto,
      ) async {
    try {
      final response = await _dio.post(
        '${_baseUrl}search/flights/multi-city',
        data: requestDto.toJson(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // Parsing direct et sécurisé vers le modèle MultiCityItinerary
        return data.map((json) => MultiCityItinerary.fromJson(json)).toList();
      } else {
        throw Exception("Erreur lors de la récupération des offres multi-destinations");
      }
    } catch (e) {
      rethrow;
    }
  }

  // Exemple d'implémentation dans ton FlightApiClient
  Future<SeatMapResponse> getFlightSeatMap(String offerId) async {
    try {
      final response = await _dio.get(
        '${_baseUrl}search/flights/seats',
        queryParameters: {'offerId': offerId},
      );

      if (response.statusCode == 200 && response.data != null) {
        return SeatMapResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load seat map');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Envoie la requête de réservation (incluant les passagers et les sièges sélectionnés)
  /// au contrôleur Spring Boot : @PostMapping("/checkout")
  Future<Map<String, dynamic>> submitCheckout(Map<String, dynamic> checkoutData) async {
    try {
      final response = await _dio.post(
        '${_baseUrl}bookings/checkout',
        data: checkoutData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        // Retourne le BookingResponse converti en Map
        // Tu pourras facilement le parser en objet BookingResponse plus tard
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Erreur lors de la finalisation de la réservation : ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Gestion des erreurs Spring Boot (Validation, etc.)
      if (e.response?.data != null) {
        throw Exception('Erreur serveur : ${e.response?.data['message'] ?? e.message}');
      }
      throw Exception('Erreur réseau : ${e.message}');
    }
  }

  /// Traite le paiement via le contrôleur Spring Boot
  /// Attend un statut 200 (HttpStatus.OK) en cas de succès, ou 402 (PAYMENT_REQUIRED) en cas d'échec
  Future<Map<String, dynamic>> submitPayment(PaymentRequest request) async {
    try {
      final response = await _dio.post(
        '${_baseUrl}payments', // <-- Ajuste le chemin selon le @RequestMapping de ton contrôleur Java
        data: request.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>; // PaymentResponse
      } else {
        throw Exception('Erreur inattendue : ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Ton backend Java renvoie HttpStatus.PAYMENT_REQUIRED (402) si le paiement échoue (PaymentStatus != SUCCEEDED)
      if (e.response?.statusCode == 402) {
        throw Exception('Le paiement a été refusé.');
      }

      if (e.response?.data != null) {
        throw Exception('Erreur serveur : ${e.response?.data['message'] ?? e.message}');
      }
      throw Exception('Erreur réseau : ${e.message}');
    }
  }
}