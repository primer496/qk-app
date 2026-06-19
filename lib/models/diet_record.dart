/// 饮食记录数据模型
class DietRecord {
  final String id;
  final String foodId;
  final String foodName;
  final String foodCategory;
  final double caloriesPer100g;
  final double weightGrams;
  final double totalCalories;
  final String mealType;
  final DateTime date;

  DietRecord({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.foodCategory,
    required this.caloriesPer100g,
    required this.weightGrams,
    required this.totalCalories,
    required this.mealType,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodId': foodId,
      'foodName': foodName,
      'foodCategory': foodCategory,
      'caloriesPer100g': caloriesPer100g,
      'weightGrams': weightGrams,
      'totalCalories': totalCalories,
      'mealType': mealType,
      'date': date.toIso8601String(),
    };
  }

  factory DietRecord.fromJson(Map<String, dynamic> json) {
    return DietRecord(
      id: json['id'] as String,
      foodId: json['foodId'] as String,
      foodName: json['foodName'] as String,
      foodCategory: json['foodCategory'] as String,
      caloriesPer100g: (json['caloriesPer100g'] as num).toDouble(),
      weightGrams: (json['weightGrams'] as num).toDouble(),
      totalCalories: (json['totalCalories'] as num).toDouble(),
      mealType: json['mealType'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}