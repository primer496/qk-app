class Sport {
  final String id;
  final String name;
  final double caloriesPerHour;

  Sport({
    required this.id,
    required this.name,
    required this.caloriesPerHour,
  });

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      id: json['id'] as String,
      name: json['name'] as String,
      caloriesPerHour: (json['calories_per_hour'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories_per_hour': caloriesPerHour,
    };
  }
}