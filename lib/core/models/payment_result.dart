import 'provider_quote.dart';

/// Reflète com.guentours.payment.domain.Payment tel que sérialisé par Jackson
/// (PaymentController renvoie l'entité JPA brute, pas le DTO PaymentResponse
/// — la clé JSON de l'identifiant est donc `id`, pas `paymentId`).
class PaymentResult {
  final String paymentId;
  final String bookingId;
  final Money amount;
  final String paymentMethod;
  final String status; // PaymentStatus: 'PENDING' | 'PENDING_AUTHORIZATION' | 'SUCCEEDED' | 'FAILED'
  final String? authorizationType; // PaymentAuthorizationType: 'PIN' | 'AVS' | 'REDIRECT' | 'OTP', seulement si PENDING_AUTHORIZATION
  final String? authorizationRedirectUrl; // seulement si authorizationType == 'REDIRECT'
  final String? failureReason;

  const PaymentResult({
    required this.paymentId,
    required this.bookingId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.authorizationType,
    this.authorizationRedirectUrl,
    this.failureReason,
  });

  bool get isSucceeded => status == 'SUCCEEDED';
  bool get isPending => status == 'PENDING';
  bool get isPendingAuthorization => status == 'PENDING_AUTHORIZATION';
  bool get isFailed => status == 'FAILED';

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      paymentId: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      amount: Money.fromJson(json['amount'] as Map<String, dynamic>? ?? const {}),
      paymentMethod: json['paymentMethod'] as String? ?? '',
      status: json['status'] as String? ?? 'FAILED',
      authorizationType: json['authorizationType'] as String?,
      authorizationRedirectUrl: json['authorizationRedirectUrl'] as String?,
      failureReason: json['failureReason'] as String?,
    );
  }
}
