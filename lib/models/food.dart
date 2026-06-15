class Food {
  final String id;
  final String name;
  final double caloriesPer100g;
  final String category;

  Food({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.category,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      caloriesPer100g: (json['calories_per_100g'] as num).toDouble(),
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories_per_100g': caloriesPer100g,
      'category': category,
    };
  }
}