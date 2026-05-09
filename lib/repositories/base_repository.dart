import 'package:dio/dio.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import '../errors/app_exception.dart';

/// Mix this into every resource repository to get [safeCall].
///
/// [safeCall] wraps a Dio request, catches [DioException] and maps it
/// to a typed [ApiResult] so callers never deal with raw exceptions.
mixin BaseRepository {
  Future<ApiResult<T>> safeCall<T>(
    Future<Response<dynamic>> Function() request, {
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await request();
      return ApiSuccess(fromJson(response.data));
    } on DioException catch (e) {
      return ApiFailure(_mapDioError(e));
    } catch (e) {
      return ApiFailure(AppException(message: e.toString()));
    }
  }

  AppException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(message: 'Request timed out. Please retry.');

      case DioExceptionType.connectionError:
        return const AppException(message: 'No internet connection.');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final serverMessage =
            e.response?.data?['message'] as String? ?? 'Something went wrong.';
        return AppException(message: serverMessage, statusCode: statusCode);

      case DioExceptionType.cancel:
        return const AppException(message: 'Request was cancelled.');

      default:
        return AppException(message: e.message ?? 'Unexpected error.');
    }
  }
}