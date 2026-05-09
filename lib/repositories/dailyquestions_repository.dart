import 'package:eigen_flutter/models/day_status.dart';
import 'package:eigen_flutter/models/question.dart';
import 'package:eigen_flutter/models/submission_result.dart';
import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/base_repository.dart';
import 'package:eigen_flutter/repositories/dio_client.dart';


class QuestionsRepository with BaseRepository {
  Future<ApiResult<Question>> getDailyQuestion() {
    return safeCall(
      () => DioClient.plain.get('/questions/daily'),
      fromJson: (data) => Question.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<List<Question>>> getAllQuestions() {
    return safeCall(
      () => DioClient.plain.get('/questions/all'),
      fromJson: (data) => (data as List)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResult<Question>> getQuestion({required String id}) {
    return safeCall(
      () => DioClient.plain.get('/questions/$id'),
      fromJson: (data) => Question.fromJson(data as Map<String, dynamic>),
    );
  }


    Future<ApiResult<SubmissionResult>> submitAnswer({
    required String token,
    required String questionId,
    required List<double?> answers,
  }) {
    return safeCall(
      () => DioClient.authenticated(token).post(
        '/questions/$questionId/answer',
        data: {'answers': answers},
      ),
      fromJson: (data) => SubmissionResult.fromJson(data as Map<String, dynamic>),
    );
  }


  Future<ApiResult<List<DayStatus>>> getMonthStatus({
    required String token,
    required String month, // "2026-05"
  }) {
    return safeCall(
      () => DioClient.authenticated(token).get('/questions/month-status/$month'),
      fromJson: (data) => (data as List)
          .map((e) => DayStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }


  Future<ApiResult<String>> getQuestionIdByDate({
  required String token,
  required String dateString, // "2026-05-09"
}) {
  return safeCall(
    () => DioClient.authenticated(token).post(
      '/questions/get-daily-question-by-datestring',
      data: {'datestring': dateString},
    ),
    fromJson: (data) => (data as Map<String, dynamic>)['question_id'].toString(),
  );
}


}