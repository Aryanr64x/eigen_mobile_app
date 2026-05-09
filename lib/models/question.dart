import 'package:eigen_flutter/repositories/api_result.dart';
import 'package:eigen_flutter/repositories/base_repository.dart';
import 'package:eigen_flutter/repositories/dio_client.dart';
import 'package:flutter/material.dart';

class Question {
  final String id;
  final String title;
  final String body;
  final int blanksCount;
  final int? contestId;
  final String topics;
  final int difficulty;

  const Question({
    required this.id,
    required this.title,
    required this.body,
    required this.blanksCount,
    this.contestId,
    required this.topics,
    required this.difficulty,
  });
  factory Question.fromJson(Map<String, dynamic> json) {
    debugPrint('Question JSON: $json');
    return Question(
        id: json['id'].toString(),
        title: json['title'] as String,
        body: json['body'] as String,
        blanksCount: json['blanks_count'] as int,
        contestId: json['contest_id'] as int?,
        topics: json['topics'] as String,
        difficulty: json['difficulty'] as int,
      );

  }
}