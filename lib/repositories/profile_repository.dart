

// ── response models (replace with your actual models / freezed) ──────────────

import 'package:eigen_flutter/models/profile.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/base_repository.dart';
import 'package:eigen_flutter/repositories/dio_client.dart';


// ── repository ────────────────────────────────────────────────────────────────

/// All methods require [token] — passed from the widget/bloc layer.
/// The token is intentionally NOT stored here; the caller owns it.
class ProfileRepository with BaseRepository {
  

  Future<ApiResult<Profile>> getProfile({
    required String token,
  }) {
    return safeCall(
      () => DioClient.authenticated(token).get('/auth/profile'),
      fromJson: (data) => Profile.fromJson(data as Map<String, dynamic>),
    );
  }



  Future<ApiResult<int>> getStreak({required String token}) {
    return safeCall(
      () => DioClient.authenticated(token).get('/profile/streak'),
      fromJson: (data) => (data as num).toInt(),
    );
  }

  
    Future<ApiResult<void>> updateSchool({
    required String token,
    required String school,
  }) {
    return safeCall(
      () => DioClient.authenticated(token).patch(
        '/profile/school',
        data: {'school': school},
      ),
      fromJson: (_) {},
    );
  }

  
}