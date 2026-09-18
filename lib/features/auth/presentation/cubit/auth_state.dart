import 'package:equatable/equatable.dart';

import '../../data/models/profile_user.dart';

enum AuthStatus {
  /// Vérification de la session en cours au lancement de l'app.
  checking,
  authenticated,
  unauthenticated,

  /// Une action (login/register/logout) est en cours.
  submitting,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final ProfileUser? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.checking,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    ProfileUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}
