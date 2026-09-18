import 'package:dio/dio.dart';
import '../models/ancillary_option.dart';
import '../models/flight_search_request_dto.dart';
import '../models/harmonized_flight_offer.dart';
import '../models/multi_city_itinerary.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/payment_request.dart';
import '../../../../core/models/payment_result.dart';
import '../../../../core/models/booking_response.dart';

/// Client HTTP pour les endpoints publics `/api/search/**`, `/api/bookings/**`
/// et `/api/payments` du backend Spring Boot. L'URL de base (host + `/api`)
/// est portée par le [Dio] injecté (voir [DioClient] / [ApiConfig]) : ce
/// client n'utilise que des chemins relatifs.
class FlightApiClient {
  final Dio _dio;

  FlightApiClient(this._dio);

  Future<List<HarmonizedFlightOffer>> searchFlights(FlightSearchRequestDto request) async {
    try {
      // Envoi sous forme de queryParameters pour correspondre à @ModelAttribute
      final response = await _dio.get(
        '/search/flights',
        queryParameters: request.toJson(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => HarmonizedFlightOffer.fromJson(json)).toList();
      } else {
        throw Exception('Erreur serveur lors de la recherche');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Appelle l'API Spring Boot pour une recherche Multi-destinations harmonisée
  Future<List<MultiCityItinerary>> searchMultiCityFlights(
      MultiCityFlightSearchRequestDto requestDto,
      ) async {
    try {
      final response = await _dio.post(
        '/search/flights/multi-city',
        data: requestDto.toJson(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // Parsing direct et sécurisé vers le modèle MultiCityItinerary
        return data.map((json) => MultiCityItinerary.fromJson(json)).toList();
      } else {
        throw Exception("Erreur lors de la récupération des offres multi-destinations");
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Cote les extras tarifés (bagages/repas/sièges/assurance) disponibles pour une
  /// offre, avant la soumission finale du checkout : @PostMapping("/bookings/ancillary-options").
  /// `travelers` n'a besoin que de nom/type (voir AncillaryOptionsRequest côté Java) - les
  /// vrais noms ne sont pas encore connus à cette étape.
  Future<List<AncillaryOption>> getAncillaryOptions(
    String offerId,
    String offerType,
    List<Map<String, String>> travelers,
  ) async {
    try {
      final response = await _dio.post(
        '/bookings/ancillary-options',
        data: {
          'offerId': offerId,
          'offerType': offerType,
          'travelers': travelers,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => AncillaryOption.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors de la récupération des options additionnelles');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Relit une réservation par id : @GetMapping("/{id}"). `email` n'est requis
  /// que pour un accès invité (doit correspondre au contact de la réservation) -
  /// inutile pour le compte authentifié qui l'a créée. Utilisé pour sonder le
  /// statut de la réservation pendant le paiement externe (voir
  /// ExternalPaymentScreen) : le paiement carte/wallet se termine sur la page
  /// web Stripe, pas dans l'app, donc rien d'autre ne signale la confirmation
  /// côté client.
  Future<BookingResponse> getBooking(String bookingId, {String? email}) async {
    try {
      final response = await _dio.get(
        '/bookings/$bookingId',
        queryParameters: email != null ? {'email': email} : null,
      );
      return BookingResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Envoie la requête de réservation (vol simple) au contrôleur Spring Boot :
  /// @PostMapping("/checkout"), renvoie 201 + le BookingResponse créé.
  Future<BookingResponse> submitCheckout(Map<String, dynamic> checkoutData) async {
    try {
      final response = await _dio.post('/bookings/checkout', data: checkoutData);
      return BookingResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Enregistre un itinéraire MULTI_CITY (tous les segments, même fournisseur)
  /// en une seule réservation : @PostMapping("/checkout/multi-city").
  Future<BookingResponse> submitMultiCityCheckout(Map<String, dynamic> checkoutData) async {
    try {
      final response = await _dio.post('/bookings/checkout/multi-city', data: checkoutData);
      return BookingResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Traite le paiement via le contrôleur Spring Boot. Un paiement refusé
  /// n'est pas une erreur HTTP : PaymentController répond toujours 200 avec
  /// un PaymentResponse dont `status` vaut FAILED (voir PaymentResult.isSucceeded).
  Future<PaymentResult> submitPayment(PaymentRequest request) async {
    try {
      final response = await _dio.post('/payments', data: request.toJson());
      return PaymentResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Relit l'état courant d'un paiement (polling pour Mobile Money en
  /// attente de confirmation USSD). `email` doit correspondre au contact de
  /// la réservation (accès invité, voir PaymentController.getById côté Spring).
  Future<PaymentResult> getPaymentStatus(String paymentId, String email) async {
    try {
      final response = await _dio.get('/payments/$paymentId', queryParameters: {'email': email});
      return PaymentResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Soumet le code (PIN/AVS/OTP) demandé par la gateway pour débloquer un
  /// paiement carte resté en PENDING_AUTHORIZATION (voir
  /// PaymentController.completeCardAuthorization côté Spring : aucun webhook
  /// ne résout cette étape seule, elle exige ce round-trip explicite).
  Future<PaymentResult> submitCardAuthorization(String paymentId, String code) async {
    try {
      final response = await _dio.post('/payments/$paymentId/card-authorization', data: {'pin': code});
      return PaymentResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
