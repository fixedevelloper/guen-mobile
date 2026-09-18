import 'package:dio/dio.dart';

/// Reflète com.guentours.shared.web.ApiError, la forme JSON renvoyée par
/// GlobalExceptionHandler pour toute erreur applicative (validation, 404,
/// conflit métier, fournisseur indisponible...). Équivalent Dart de
/// `normalizeApiError()` côté frontend Next.js (lib/api/client.ts).
class ApiException implements Exception {
  final int status;
  final String error;
  final String message;
  final List<String> details;

  const ApiException({
    required this.status,
    required this.error,
    required this.message,
    this.details = const [],
  });

  /// True pour une erreur de validation (400) qui porte un détail par champ.
  bool get isValidation => status == 400 && details.isNotEmpty;

  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(
        status: (data['status'] as num?)?.toInt() ?? e.response?.statusCode ?? 0,
        error: data['error'] as String? ?? 'Request Failed',
        message: data['message'].toString(),
        details: (data['details'] as List?)?.map((d) => d.toString()).toList() ?? const [],
      );
    }
    if (e.response != null) {
      return ApiException(
        status: e.response!.statusCode ?? 0,
        error: 'Request Failed',
        message: 'Le serveur a répondu de façon inattendue. Veuillez réessayer.',
      );
    }
    return const ApiException(
      status: 0,
      error: 'Network Error',
      message: 'Impossible de contacter le serveur. Vérifiez votre connexion et réessayez.',
    );
  }

  @override
  String toString() => message;
}

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}
