class Meal {
  final String name;
  final String thumbnail;
  final List<String> ingredients;

  Meal({
    required this.name,
    required this.thumbnail,
    required this.ingredients,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      String? ingredient = json['strIngredient$i'];
      String? measure = json['strMeasure$i'];
      if (ingredient != null &&
          ingredient.trim().isNotEmpty &&
          measure != null &&
          measure.trim().isNotEmpty) {
        ingredients.add('$measure ${ingredient.trim()}');
      } else if (ingredient != null && ingredient.trim().isNotEmpty) {
        ingredients.add(ingredient.trim());
      }
    }

    return Meal(
      name: json['strMeal'] ?? 'No Name',
      thumbnail: json['strMealThumb'] ?? '',
      ingredients: ingredients,
    );
  }
}
