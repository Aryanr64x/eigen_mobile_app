
import 'package:eigen_flutter/models/profile.dart';

class AuthState {
  final String? accessToken;
  final Profile? profile;

  const AuthState({
    this.accessToken,
    this.profile,
  });

  /// Initial unauthenticated state
  const AuthState.initial()
      : accessToken = null,
        profile = null;

  bool get isAuthenticated => accessToken != null && profile != null;

  AuthState copyWith({
    String? accessToken,
    Profile? profile,
  }) =>
      AuthState(
        accessToken: accessToken ?? this.accessToken,
        profile: profile ?? this.profile,
      );

  /// Explicit clear — does NOT fall through to copyWith
  /// so both fields are set to null intentionally
  AuthState clear() => const AuthState.initial();

  @override
  String toString() =>
      'AuthState(isAuthenticated: $isAuthenticated, profile: $profile)';
}