/// Identifiants OAuth mobile pour la connexion Google/Facebook (google_sign_in,
/// flutter_facebook_auth) — connexion native (Android/iOS/Web uniquement, pas
/// de support Linux desktop). Le token obtenu localement est vérifié côté
/// backend par SocialTokenVerifier (voir AuthController#loginWithGoogle et
/// #loginWithFacebook), qui mint le même cookie gt_auth que login()/register().
///
/// Même principe de config que [ApiConfig]/[WebConfig] : override par
/// --dart-define, aucune valeur en dur dans le code. Tant que ces identifiants
/// ne sont pas fournis, [googleClientId]/[facebookAppId] sont vides et
/// AuthCubit#loginWithGoogle/loginWithFacebook échouent proprement avec un
/// message "non configuré" plutôt que de planter.
///
///   flutter run --dart-define=GOOGLE_MOBILE_CLIENT_ID=... --dart-define=FACEBOOK_APP_ID=...
class OAuthConfig {
  OAuthConfig._();

  /// Client id OAuth Google pour la plateforme mobile (Android/iOS), distinct
  /// du client web déjà utilisé par oauth2Login() — voir
  /// GOOGLE_MOBILE_CLIENT_ID dans .env.example côté backend.
  static const String googleClientId = String.fromEnvironment('GOOGLE_MOBILE_CLIENT_ID');

  /// App id Facebook — même app que FACEBOOK_CLIENT_ID côté backend (Facebook
  /// n'a qu'un seul id d'app par produit, pas un id distinct par plateforme).
  static const String facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID');

  static bool get isGoogleConfigured => googleClientId.isNotEmpty;

  static bool get isFacebookConfigured => facebookAppId.isNotEmpty;
}
