import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Central Dio client.
///
/// Two factories are exposed:
///   • [DioClient.plain]           — no Authorization header (public routes)
///   • [DioClient.authenticated]   — injects Bearer token per-request
class DioClient {
  DioClient._();

  // ── shared base options ────────────────────────────────────────────────────

  static BaseOptions get _baseOptions => BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

  // ── plain (no auth) ────────────────────────────────────────────────────────

  static Dio get plain {
    final dio = Dio(_baseOptions);
    _addLogging(dio);
    return dio;
  }

  // ── authenticated ──────────────────────────────────────────────────────────

  /// Returns a Dio instance that injects [token] as a Bearer header.
  /// Call this inside a repository method that receives the token from
  /// the widget/bloc layer.
  static Dio authenticated(String token) {
    final dio = Dio(_baseOptions);
    dio.options.headers['Authorization'] = 'Bearer $token';
    _addLogging(dio);
    return dio;
  }

  // ── logging interceptor (debug only) ──────────────────────────────────────

  static void _addLogging(Dio dio) {
    assert(() {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (o) => print('[Dio] $o'),
        ),
      );
      return true;
    }());
  }
}