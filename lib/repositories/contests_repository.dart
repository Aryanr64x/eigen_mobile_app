import 'package:eigen_flutter/models/contest.dart';
import 'package:eigen_flutter/models/question.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/base_repository.dart';
import 'package:eigen_flutter/repositories/dio_client.dart';

class ContestsRepository with BaseRepository {
  Future<ApiResult<List<Contest>>> getContests() {
    return safeCall(
      () => DioClient.plain.get('/contests'),
      fromJson: (data) => (data as List)
          .map((e) => Contest.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

        Future<ApiResult<Contest>> getContest({
        required String token,
        required int id,
      }) {
        return safeCall(
          () => DioClient.authenticated(token).get('/contests/$id'),
          fromJson: (data) => Contest.fromJson(data as Map<String, dynamic>),
        );
      }

      Future<ApiResult<String>> canEnterContest({
        required String token,
        required int id,
      }) {
        return safeCall(
          () => DioClient.authenticated(token).get('/contests/$id/can-enter'),
          fromJson: (data) => (data as Map<String, dynamic>)['status'] as String,
        );
      }

      Future<ApiResult<void>> beginContest({
        required String token,
        required int id,
      }) {
        return safeCall(
          () => DioClient.authenticated(token).get('/contests/$id/begin'),
          fromJson: (_) {},
        );
      }

      Future<ApiResult<List<Question>>> getContestQuestions({
        required String token,
        required int id,
      }) {
        return safeCall(
          () => DioClient.authenticated(token).get('/contests/$id/questions'),
          fromJson: (data) => (data as List)
              .map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }

      Future<ApiResult<int>> submitContest({
  required String token,
  required int id,
  required Map<String, List<double>> answers, // ← String key not int
}) {
  return safeCall(
    () => DioClient.authenticated(token).post(
      '/contests/$id',
      data: {'answers': answers},
    ),
    fromJson: (data) => (data as Map<String, dynamic>)['score'] as int,
  );
}
}