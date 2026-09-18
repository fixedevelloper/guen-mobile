import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/failures.dart';
import '../../data/datasources/auth_api_client.dart';
import 'auth_state.dart';

/// Source de vérité unique pour la session utilisateur. Enregistré comme
/// singleton (voir injection.dart) : une seule instance pour toute l'app,
/// afin que login/logout se reflètent immédiatement partout (écran Profil,
/// éventuel gate futur sur d'autres écrans) sans re-synchronisation manuelle.
class AuthCubit extends Cubit<AuthState> {
  final AuthApiClient _apiClient;

  AuthCubit(this._apiClient) : super(const AuthState());

  /// Résout la session depuis le cookie persistant, à appeler une fois au
  /// démarrage de l'app (voir splash_screen.dart). Un 401 signifie
  /// simplement "personne n'est connecté", pas une erreur à afficher.
  Future<void> checkSession() async {
    emit(state.copyWith(status: AuthStatus.checking));
    try {
      final user = await _apiClient.me();
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (e) {
      if (e.status == 401) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      } else {
        emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message));
      }
    } catch (_) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.submitting, errorMessage: null));
    try {
      final user = await _apiClient.login(email, password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message));
    } catch (e) {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Connexion impossible. Vérifiez vos identifiants.',
      ));
    }
  }

  Future<void> register({
    required String email,
    required String fullName,
    required String password,
    String? phone,
  }) async {
    emit(state.copyWith(status: AuthStatus.submitting, errorMessage: null));
    try {
      final user = await _apiClient.register(
        email: email,
        fullName: fullName,
        password: password,
        phone: phone,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message));
    } catch (e) {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Inscription impossible. Réessayez.',
      ));
    }
  }

  /// Déclenche le sélecteur de compte Google natif, puis vérifie l'ID token
  /// côté backend (voir AuthApiClient#loginWithGoogle). Une annulation
  /// utilisateur (retour sans choisir de compte) ne doit pas afficher
  /// d'erreur — [GoogleSignIn.signIn] renvoie simplement `null` dans ce cas.
  Future<void> loginWithGoogle() async {
    emit(state.copyWith(status: AuthStatus.submitting, errorMessage: null));
    try {
      final account = await GoogleSignIn(scopes: const ['email']).signIn();
      if (account == null) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
        return;
      }
      final idToken = (await account.authentication).idToken;
      if (idToken == null) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Connexion Google impossible. Réessayez.',
        ));
        return;
      }
      final user = await _apiClient.loginWithGoogle(idToken);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message));
    } catch (e) {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Connexion Google impossible. Réessayez.',
      ));
    }
  }

  /// Équivalent Facebook de [loginWithGoogle] (SDK flutter_facebook_auth).
  Future<void> loginWithFacebook() async {
    emit(state.copyWith(status: AuthStatus.submitting, errorMessage: null));
    try {
      final result = await FacebookAuth.instance.login(permissions: const ['email', 'public_profile']);
      if (result.status == LoginStatus.cancelled) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
        return;
      }
      final accessToken = result.accessToken?.tokenString;
      if (result.status != LoginStatus.success || accessToken == null) {
        emit(AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: result.message ?? 'Connexion Facebook impossible. Réessayez.',
        ));
        return;
      }
      final user = await _apiClient.loginWithFacebook(accessToken);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on ApiException catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message));
    } catch (e) {
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Connexion Facebook impossible. Réessayez.',
      ));
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.logout();
    } catch (_) {
      // Le cookie côté serveur est de toute façon best-effort à effacer ;
      // on déconnecte localement dans tous les cas.
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
