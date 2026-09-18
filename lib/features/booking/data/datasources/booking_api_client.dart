import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/payment_request.dart';
import '../../../../core/models/payment_result.dart';
import '../models/checkout_request_dto.dart';
import '../../../../core/models/booking_response.dart';

/// Client HTTP pour `/api/bookings/checkout` et `/api/payments`. Chemins
/// relatifs : l'URL de base est portée par le [Dio] injecté (voir
/// [DioClient] / [ApiConfig]). Réutilisé par les checkouts hôtel, véhicule
/// et meublé (les vols ont leur propre client dédié, `FlightApiClient`,
/// pour la sélection de sièges).
class BookingApiClient {
  final Dio _dio;

  BookingApiClient(this._dio);

  /// Réservations de l'utilisateur connecté, la plus récente en premier
  /// (voir BookingController.myBookings côté Spring). Nécessite une session
  /// authentifiée — le cookie est porté automatiquement par [DioClient].
  Future<List<BookingResponse>> getMyBookings() async {
    try {
      final response = await _dio.get('/bookings/me');
      final data = response.data as List<dynamic>;
      return data.map((json) => BookingResponse.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<BookingResponse> checkout(CheckoutRequestDto request) async {
    try {
      final response = await _dio.post('/bookings/checkout', data: request.toJson());
      return BookingResponse.fromJson(response.data as Map<String, dynamic>);
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

  /// Un paiement refusé n'est pas une erreur HTTP : PaymentController répond
  /// toujours 200 avec un PaymentResponse dont `status` vaut FAILED (voir
  /// PaymentResult.isSucceeded).
  Future<PaymentResult> pay(PaymentRequest request) async {
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
