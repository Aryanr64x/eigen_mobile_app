class BlankResult {
  final int blankOrder;
  final double? submitted;
  final bool isCorrect;

  const BlankResult({
    required this.blankOrder,
    required this.submitted,
    required this.isCorrect,
  });

  factory BlankResult.fromJson(Map<String, dynamic> json) => BlankResult(
        blankOrder: json['blank_order'] as int,
        submitted: (json['submitted'] as num?)?.toDouble(),
        isCorrect: json['is_correct'] as bool,
      );
}

class SubmissionResult {
  final String questionId;
  final bool allCorrect;
  final List<BlankResult> results;

  const SubmissionResult({
    required this.questionId,
    required this.allCorrect,
    required this.results,
  });

  factory SubmissionResult.fromJson(Map<String, dynamic> json) =>
      SubmissionResult(
        questionId: json['question_id'].toString(),
        allCorrect: json['all_correct'] as bool,
        results: (json['results'] as List)
            .map((e) => BlankResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}