import 'package:eigen_flutter/models/auth_state.dart';
import 'package:eigen_flutter/models/profile.dart';
import 'package:eigen_flutter/storage/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Runs once on app start — restores session from SharedPreferences
    final storage = ref.read(storageServiceProvider);

    final token = storage.getAccessToken();
    final profileJson = storage.getProfile();

    if (token != null && profileJson != null) {
      return AuthState(
        accessToken: token,
        profile: Profile.fromJson(profileJson),
      );
    }

    return const AuthState.initial();
  }

  // ── called after a successful login ───────────────────────────────────────

  Future<void> setAuth({
    required String accessToken,
    required Profile profile,
  }) async {
    final storage = ref.read(storageServiceProvider);

    await Future.wait([
      storage.saveAccessToken(accessToken),
      storage.saveProfile(_profileToJson(profile)),
    ]);

    state = AsyncData(
      AuthState(accessToken: accessToken, profile: profile),
    );
  }

  // ── update profile without touching the token ─────────────────────────────

  Future<void> updateProfile(Profile profile) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveProfile(_profileToJson(profile));

  final current = state.asData?.value ?? const AuthState.initial();
    state = AsyncData(current.copyWith(profile: profile));
  }

  // ── update token without touching the profile ─────────────────────────────

  Future<void> updateAccessToken(String accessToken) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveAccessToken(accessToken);

   final current = state.asData?.value ?? const AuthState.initial();
    state = AsyncData(current.copyWith(accessToken: accessToken));
  }

  // ── logout — clears everything ────────────────────────────────────────────

  Future<void> logout() async {
    final storage = ref.read(storageServiceProvider);
    await storage.clearAll();
    state = const AsyncData(AuthState.initial());
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _profileToJson(Profile profile) => {
        'id': profile.id,
        'username': profile.username,
        'email': profile.email,
        'avatar_url': profile.avatarUrl,
        'created_at': profile.createdAt,
      };
}

// ── provider ──────────────────────────────────────────────────────────────────

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ── convenience select providers ─────────────────────────────────────────────

final accessTokenProvider = Provider<String?>(
  (ref) => ref.watch(authProvider).asData?.value.accessToken,
);

final userProfileProvider = Provider<Profile?>(
  (ref) => ref.watch(authProvider).asData?.value.profile,
);

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).asData?.value.isAuthenticated ?? false,
);