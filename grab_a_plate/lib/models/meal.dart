class Meal {
  final String name;
  final String thumbnail;
  final List<String> ingredients;
  final String id;
  final String category;
  final String instructions;
  final String youtubeLink;

  Meal({
    required this.name,
    required this.thumbnail,
    required this.ingredients,
    required this.id,
    required this.category,
    required this.instructions,
    required this.youtubeLink,
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
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? 'No Name',
      category: json['strCategory'] ?? 'Unknown',
      thumbnail: json['strMealThumb'] ?? '',
      ingredients: ingredients,
      instructions: json['strInstructions'] ?? '',
      youtubeLink: json['strYoutube'] ?? '',
    );
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    List<String> ingredients = [];
    if (map['ingredients'] != null) {
      ingredients = map['ingredients']
          .split(',')
          .map((ingredient) => ingredient.trim())
          .toList();
    }

    return Meal(
      id: map['id'] ?? '',
      name: map['name'] ?? 'No Name',
      category: map['category'] ?? 'Unknown',
      thumbnail: map['thumbnail'] ?? '',
      ingredients: ingredients,
      instructions: map['instructions'] ?? '',
      youtubeLink: map['youtubeLink'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'thumbnail': thumbnail,
      'ingredients': ingredients.join(', '),
      'instructions': instructions,
      'youtubeLink': youtubeLink,
    };
  }
}
