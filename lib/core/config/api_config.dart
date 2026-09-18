import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, kReleaseMode;
import 'dart:io' show Platform;

/// Configuration centralisée de l'URL du backend Spring Boot (com.guentours).
///
/// Le backend n'utilise aucun préfixe de version : toutes les routes sont
/// sous `/api/...` (ex: `/api/search/flights`, `/api/bookings/checkout`).
///
/// Pour pointer l'app vers un backend distant différent de la prod (staging,
/// test sur un appareil physique en debug...), compiler avec :
///   flutter run --dart-define=API_BASE_URL=https://api-guentours.guens.org/api
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// URL du backend en production — voir APP_CORS_ALLOWED_ORIGINS dans
  /// application.yml côté Spring pour le domaine du frontend correspondant.
  static const String _productionUrl = 'https://api-guentours.guens.org/api';

  /// URL de base incluant le segment `/api`, sans slash final.
  ///
  /// Un build release (`flutter build apk/appbundle --release`) sans
  /// `--dart-define` pointe automatiquement sur la prod plutôt que sur l'hôte
  /// de dev — oublier le flag ne peut plus faire fuiter un APK distribué qui
  /// pointe silencieusement sur l'émulateur/localhost.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kReleaseMode) return _productionUrl;
    return 'http://$_devHost:8080/api';
  }

  /// Hôte de dev par défaut selon la plateforme d'exécution :
  /// - Android (émulateur) : 10.0.2.2 redirige vers le localhost de la machine hôte.
  /// - iOS simulator / desktop / web : localhost fonctionne directement.
  /// Un appareil physique doit toujours passer par --dart-define=API_BASE_URL=...
  static String get _devHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static bool get enableHttpLogging => kDebugMode;
}
