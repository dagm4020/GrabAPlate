import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models/meal.dart';
import 'meal_detail_screen.dart';
import 'package:http/http.dart' as http;

class Favorites extends StatefulWidget {
  final bool darkModeEnabled;
  final int? currentUserId;

  Favorites({
    required this.darkModeEnabled,
    required this.currentUserId,
  });

  @override
  _FavoritesState createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  List<Map<String, dynamic>> _favoriteMeals = [];
  bool _isLoading = true;
  Set<String> _selectedCategories = {};
  List<String> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteMeals();
  }

  Future<void> _loadFavoriteMeals() async {
    if (widget.currentUserId != null) {
      final favorites =
          await DatabaseHelper().getFavorites(widget.currentUserId!);
      setState(() {
        _favoriteMeals = favorites;
        _isLoading = false;
        _allCategories = _getAllCategories(favorites);
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _getAllCategories(List<Map<String, dynamic>> meals) {
    Set<String> categories =
        meals.map((meal) => meal['category'] as String).toSet();
    return categories.toList();
  }

  Future<void> _removeFavorite(String mealId) async {
    if (widget.currentUserId != null) {
      await DatabaseHelper().removeFavorite(widget.currentUserId!, mealId);
      _loadFavoriteMeals();
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  ..._allCategories.map((category) {
                    bool isSelected = _selectedCategories.contains(category);
                    return CheckboxListTile(
                      title: Text(
                        category,
                        style: TextStyle(color: Colors.black),
                      ),
                      value: isSelected,
                      activeColor: Colors.black,
                      onChanged: (bool? value) {
                        setStateModal(() {
                          setState(() {
                            if (value == true) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        });
                      },
                    );
                  }).toList(),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategories.clear();
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredMeals() {
    if (_selectedCategories.isEmpty) {
      return _favoriteMeals;
    } else {
      return _favoriteMeals
          .where((meal) => _selectedCategories.contains(meal['category']))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.black;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          : widget.currentUserId == null
              ? Center(
                  child: Text(
                    'Please sign in to view favorites.',
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                )
              : _favoriteMeals.isEmpty
                  ? Center(
                      child: Text(
                        'No favorite meals yet.',
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                    )
                  : _buildFavoritesGrid(),
    );
  }

  Widget _buildFavoritesGrid() {
    List<Map<String, dynamic>> displayedMeals = _getFilteredMeals();

    if (displayedMeals.isEmpty) {
      return Center(
        child: Text(
          'No meals found for the selected filters.',
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20.0,
        mainAxisSpacing: 20.0,
        childAspectRatio: 0.75,
      ),
      itemCount: displayedMeals.length,
      itemBuilder: (context, index) {
        final favorite = displayedMeals[index];
        final mealId = favorite['mealId'];
        final mealName = favorite['mealName'];
        final mealThumbnail = favorite['mealThumbnail'];
        final category = favorite['category'];

        return Column(
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () async {
                    Meal? meal = await _fetchMealDetails(mealId);
                    if (meal != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MealDetailScreen(
                            meal: meal,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to load meal details.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: Colors.black26,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        mealThumbnail,
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
                  top: 4,
                  right: 4,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    icon: Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      await _removeFavorite(mealId);
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
                style: TextStyle(fontSize: 16, color: Colors.black),
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.black),
      elevation: 0,
      title: Row(
        children: [
          Icon(Icons.favorite, color: Colors.black),
          SizedBox(width: 8),
          Text(
            'Favorites',
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.filter_list, color: Colors.black),
          onPressed: () {
            _showFilterDialog();
          },
        ),
      ],
    );
  }

  Future<Meal?> _fetchMealDetails(String mealId) async {
    final response = await http.get(Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/lookup.php?i=$mealId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null && data['meals'].isNotEmpty) {
        return Meal.fromJson(data['meals'][0]);
      }
    }
    return null;
  }
}
