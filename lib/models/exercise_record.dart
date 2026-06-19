class ExerciseRecord {
  final String id;
  final String sportId;
  final String sportName;
  final int durationMinutes;
  final double caloriesBurned;
  final DateTime date;

  ExerciseRecord({
    required this.id,
    required this.sportId,
    required this.sportName,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sportId': sportId,
      'sportName': sportName,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'date': date.toIso8601String(),
    };
  }

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseRecord(
      id: json['id'] as String,
      sportId: json['sportId'] as String,
      sportName: json['sportName'] as String,
      durationMinutes: json['durationMinutes'] as int,
      caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}