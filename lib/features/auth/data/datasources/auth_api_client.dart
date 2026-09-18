import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../models/profile_user.dart';

/// Client HTTP pour `/api/auth/**`. La session vit dans le cookie HttpOnly
/// `gt_auth` posé par login/register/me (voir AuthCookieService côté Spring)
/// et rejoué automatiquement par le [CookieManager] enregistré sur ce [Dio]
/// (voir [DioClient]) — aucun token à gérer à la main côté client.
class AuthApiClient {
  final Dio _dio;

  AuthApiClient(this._dio);

  Future<ProfileUser> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return ProfileUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ProfileUser> register({
    required String email,
    required String fullName,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'password': password,
      });
      return ProfileUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Vérifie l'ID token Google (obtenu nativement par google_sign_in) côté
  /// serveur et pose le même cookie `gt_auth` que [login] — voir
  /// AuthController#loginWithGoogle / SocialTokenVerifier.
  Future<ProfileUser> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post('/auth/oauth/google', data: {'idToken': idToken});
      return ProfileUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Équivalent Facebook de [loginWithGoogle] (token obtenu par
  /// flutter_facebook_auth) — voir AuthController#loginWithFacebook.
  Future<ProfileUser> loginWithFacebook(String accessToken) async {
    try {
      final response = await _dio.post('/auth/oauth/facebook', data: {'accessToken': accessToken});
      return ProfileUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Résout la session courante depuis le cookie `gt_auth`. Lève une
  /// [ApiException] avec `status == 401` si personne n'est connecté — ce
  /// n'est pas une erreur réseau, juste l'état "non authentifié".
  Future<ProfileUser> me() async {
    try {
      final response = await _dio.get('/auth/me');
      return ProfileUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Toujours 200 côté serveur, que l'email existe ou non (évite de révéler
  /// quels comptes existent) — voir PasswordResetController.forgotPassword.
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `token` est celui reçu par email (lien de réinitialisation) — pas de
  /// deep-link configuré côté app, l'utilisateur le saisit manuellement.
  Future<void> resetPassword({required String token, required String newPassword}) async {
    try {
      await _dio.post('/auth/reset-password', data: {'token': token, 'newPassword': newPassword});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
