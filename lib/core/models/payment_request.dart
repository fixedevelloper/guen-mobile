/// Reflète com.guentours.payment.web.PaymentRequest côté backend.
///
/// `countryCode` (ISO2) et `countryCurrency` (ISO 4217) sont `@NotBlank` côté
/// serveur : les omettre fait échouer la requête avec un 400. `paymentMethod`
/// doit être l'une des valeurs de l'enum backend (`CARD`, `MOBILE_MONEY`,
/// `GOOGLE_PAY`, `APPLE_PAY`, `PAYPAL`) — l'opérateur (Orange/MTN/...) est
/// déduit côté serveur à partir du préfixe de `mobileNumber` et n'est pas
/// transmis par le client.
///
/// N'exposer QUE `CARD` et `MOBILE_MONEY` côté UI : `GOOGLE_PAY`/`APPLE_PAY`
/// sont des stubs backend non fonctionnels (token de paiement toujours nul
/// — `FlutterwaveGooglePayGateway`/`FlutterwaveApplePayGateway`) et `PAYPAL`
/// n'est pas confirmé prêt en production. `PaymentService` valide en plus,
/// selon `paymentMethod`, un format strict côté backend :
/// - CARD : `cardNumber` = 12-19 chiffres, `expiry` = MM/YY, `cvv` = 3-4 chiffres.
/// - MOBILE_MONEY : `mobileNumber` doit matcher `^\+?\d{8,15}$`, et
///   `countryCode` doit être l'un des pays mobile money supportés
///   (CM, SN, CI, ML, GH, UG, RW, ZM, KE) sous peine d'échec du paiement.
class PaymentRequest {
  final String bookingId;
  final String paymentMethod; // 'CARD' ou 'MOBILE_MONEY'
  final String countryCode; // ISO2, ex: 'CM'
  final String countryCurrency; // ISO 4217, ex: 'XAF'
  final String? cardNumber;
  final String? cardHolderName;
  final String? expiry;
  final String? cvv;
  final String? mobileNumber;

  PaymentRequest({
    required this.bookingId,
    required this.paymentMethod,
    required this.countryCode,
    required this.countryCurrency,
    this.cardNumber,
    this.cardHolderName,
    this.expiry,
    this.cvv,
    this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'paymentMethod': paymentMethod,
      'countryCode': countryCode,
      'countryCurrency': countryCurrency,
      if (cardNumber != null) 'cardNumber': cardNumber,
      if (cardHolderName != null) 'cardHolderName': cardHolderName,
      if (expiry != null) 'expiry': expiry,
      if (cvv != null) 'cvv': cvv,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
    };
  }
}
