import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/meal.dart';
import 'meal_detail_screen.dart';
import 'database_helper.dart';
import 'sign_in.dart';

class SuggestedMealsScreen extends StatefulWidget {
  final bool darkModeEnabled;
  final int? currentUserId;
  final Function(bool) onLoginStatusChanged;

  SuggestedMealsScreen({
    required this.darkModeEnabled,
    required this.currentUserId,
    required this.onLoginStatusChanged,
  });

  @override
  _SuggestedMealsScreenState createState() => _SuggestedMealsScreenState();
}

class _SuggestedMealsScreenState extends State<SuggestedMealsScreen> {
  late Future<List<Meal>> _futureMeals;
  Set<String> _favoritedMealIds = Set<String>();

  @override
  void initState() {
    super.initState();
    _futureMeals = _fetchSixRandomMeals();
    _loadFavorites();
  }

  @override
  void didUpdateWidget(covariant SuggestedMealsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUserId != oldWidget.currentUserId) {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    if (widget.currentUserId != null) {
      final favorites =
          await DatabaseHelper().getFavorites(widget.currentUserId!);
      setState(() {
        _favoritedMealIds =
            favorites.map((fav) => fav['mealId'] as String).toSet();
      });
    } else {
      setState(() {
        _favoritedMealIds.clear();
      });
    }
  }

  Future<List<Meal>> _fetchSixRandomMeals() async {
    List<Future<Meal>> fetchMealFutures =
        List.generate(6, (index) => _fetchRandomMeal());

    List<Meal> meals = await Future.wait(fetchMealFutures);

    return meals;
  }

  Future<Meal> _fetchRandomMeal() async {
    final response = await http
        .get(Uri.parse('https://www.themealdb.com/api/json/v1/1/random.php'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null && data['meals'].isNotEmpty) {
        return Meal.fromJson(data['meals'][0]);
      } else {
        throw Exception('No meal data found.');
      }
    } else {
      throw Exception('Failed to load meal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.darkModeEnabled ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: widget.darkModeEnabled ? Colors.black : Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Column(
          children: [
            AppBar(
              title: Text(
                'Suggested Meals',
                style: TextStyle(fontSize: 20, color: textColor),
              ),
              backgroundColor:
                  widget.darkModeEnabled ? Colors.black : Colors.white,
              iconTheme: IconThemeData(color: textColor),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 50.0),
              height: 2.0,
              color: textColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<List<Meal>>(
          future: _futureMeals,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      widget.darkModeEnabled ? Colors.white : Colors.black),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error fetching meals',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No suggested meals found.',
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
              );
            } else {
              List<Meal> suggestedMeals = snapshot.data!;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20.0,
                  mainAxisSpacing: 20.0,
                  childAspectRatio: 0.75,
                ),
                itemCount: suggestedMeals.length,
                itemBuilder: (context, index) {
                  Meal currentMeal = suggestedMeals[index];
                  String mealName = currentMeal.name;
                  String mealImageUrl = currentMeal.thumbnail;
                  String mealId = currentMeal.id;

                  bool isFavorited = _favoritedMealIds.contains(mealId);

                  return Column(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MealDetailScreen(meal: currentMeal),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 170,
                              decoration: BoxDecoration(
                                color: widget.darkModeEnabled
                                    ? Colors.grey[800]
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: widget.darkModeEnabled
                                      ? Colors.white54
                                      : Colors.black26,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: Image.network(
                                  mealImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,                             right: 4,                             child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              icon: Icon(
                                isFavorited
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                if (widget.currentUserId == null) {
                                                                    await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SignInScreen(
                                        onSignedIn: () {
                                          widget.onLoginStatusChanged(true);
                                          setState(() {
                                            _loadFavorites();
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                } else {
                                  if (isFavorited) {
                                    await DatabaseHelper().removeFavorite(
                                        widget.currentUserId!, mealId);
                                    setState(() {
                                      _favoritedMealIds.remove(mealId);
                                    });
                                  } else {
                                    await DatabaseHelper().insertFavorite({
                                      'userId': widget.currentUserId!,
                                      'mealId': mealId,
                                      'mealName': mealName,
                                      'category': currentMeal.category,
                                      'mealThumbnail': mealImageUrl,
                                    });
                                    setState(() {
                                      _favoritedMealIds.add(mealId);
                                    });
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        child: Text(
                          mealName,
                          style: TextStyle(fontSize: 16, color: textColor),
                          textAlign: TextAlign.center,
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
