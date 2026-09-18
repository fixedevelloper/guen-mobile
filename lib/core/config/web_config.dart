import 'package:flutter/foundation.dart' show kReleaseMode;

/// URL de base du frontend Next.js — utilisée uniquement pour renvoyer l'app
/// vers la page de paiement web (voir ExternalPaymentScreen) : carte/Google
/// Pay/Apple Pay/PayPal passent tous par la Checkout Session Stripe que
/// PaymentForm (Next.js) sait déjà monter correctement (voir
/// src/main/java/com/guentours/payment/gateway/stripe/StripePaymentGateway.java
/// côté backend - crée une Session en ui_mode embedded_page, incompatible
/// avec le PaymentSheet natif de flutter_stripe qui attend un PaymentIntent).
/// Même raisonnement de config que [ApiConfig] : override par --dart-define,
/// sinon prod en release, sinon l'hôte de dev Next.js en debug.
class WebConfig {
  WebConfig._();

  static const String _override = String.fromEnvironment('WEB_BASE_URL');

  /// Domaine de prod du frontend — voir APP_CORS_ALLOWED_ORIGINS dans
  /// application.yml côté Spring (source de vérité de ce qui est autorisé).
  static const String _productionUrl = 'https://www.guenstravel.com';

  /// URL de base (sans slash final).
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kReleaseMode) return _productionUrl;
    return 'http://localhost:3000';
  }
}
