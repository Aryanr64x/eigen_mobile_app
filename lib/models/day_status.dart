class DayStatus {
  final String day;   // "01", "02", ...
  final String status; // "solved", "unsolved", "partially_solved"

  const DayStatus({required this.day, required this.status});

  factory DayStatus.fromJson(Map<String, dynamic> json) => DayStatus(
        day: json['day'] as String,
        status: json['status'] as String,
      );
}