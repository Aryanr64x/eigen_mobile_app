class Contest {
  final int id;
  final DateTime createdAt;
  final DateTime startTime;
  final DateTime endTime;
  final int duration;
  final int questionsCount;
  final int participantsCount;
  final String name;
  final bool processed;

  const Contest({
    required this.id,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.questionsCount,
    required this.participantsCount,
    required this.name,
    required this.processed,
  });

  factory Contest.fromJson(Map<String, dynamic> json) => Contest(
        id: json['id'] as int,                            
        createdAt: DateTime.parse(json['created_at'] as String),
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: DateTime.parse(json['end_time'] as String),
        duration: (json['duration'] as num).toInt(),
        questionsCount: (json['questions_count'] as num).toInt(),
        participantsCount: (json['participants_count'] as num? ?? 0).toInt(),
        name: (json['name'] as String?) ?? 'Unnamed Contest',
        processed: (json['processed'] as bool?) ?? false,
      );

  ContestStatus get status {
    final now = DateTime.now().toUtc();
    if (now.isBefore(startTime)) return ContestStatus.upcoming;
    if (now.isAfter(endTime)) return ContestStatus.past;
    return ContestStatus.live;
  }
}

enum ContestStatus { live, upcoming, past }