import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
        },
      );

      if (response.user == null) {
        throw Exception("Signup failed");
      }

      return response;
    } catch (e) {
      throw Exception("Signup error: $e");
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(    
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw Exception("Login failed");
      }

      return response;
    } catch (e) {
      throw Exception("Signin error: $e");
    }
  }

  /// 📦 Get Access Token (use for FastAPI)
  String? getAccessToken() {
    final session = _client.auth.currentSession;
    return session?.accessToken;
  }

  /// 🚪 Logout (optional but useful)
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}