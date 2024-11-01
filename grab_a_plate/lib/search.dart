import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/meal.dart';
import 'meal_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String query;
  final int? currentUserId;

  SearchScreen({required this.query, required this.currentUserId});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Meal> _meals = [];
  int _currentPage = 1;
  int _mealsPerPage = 6;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchMeals();
  }

    Future<void> _fetchMeals() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/search.php?s=${widget.query}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Meal> meals = [];
      if (data['meals'] != null) {
        meals = List<Meal>.from(data['meals'].map((meal) => Meal.fromJson(meal)));
      }
      setState(() {
        int startIndex = (_currentPage - 1) * _mealsPerPage;
        int endIndex = startIndex + _mealsPerPage;
        if (startIndex >= meals.length) {
          _hasMore = false;
        } else {
          _meals.addAll(meals.sublist(
              startIndex, endIndex > meals.length ? meals.length : endIndex));
          _currentPage++;
          if (endIndex >= meals.length) {
            _hasMore = false;
          }
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
    }
  }

  Widget _buildMealCard(Meal meal) {
    return GestureDetector(
      onTap: () {
        _navigateToMealDetail(meal);
      },
      child: Column(
        children: [
          Container(
            width: 170,
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
                meal.thumbnail,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: 170,
            child: Text(
              meal.name,
              style: TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,               overflow: TextOverflow.ellipsis,             ),
          ),
        ],
      ),
    );
  }

  void _navigateToMealDetail(Meal meal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MealDetailScreen(
          meal: meal,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (!_hasMore) {
      return SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: _fetchMeals,
        child: Text('Load More'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(color: textColor, fontSize: 20),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: _isLoading && _meals.isEmpty
          ? Center(
              child: CircularProgressIndicator(),
            )
          : _meals.isEmpty
              ? Center(
                  child: Text(
                    'No meals found.',
                    style: TextStyle(fontSize: 18, color: textColor),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      GridView.builder(
                        padding: EdgeInsets.all(16.0),
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _meals.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16.0,
                          crossAxisSpacing: 16.0,
                          childAspectRatio: 0.75,
                        ),
                        itemBuilder: (context, index) {
                          return _buildMealCard(_meals[index]);
                        },
                      ),
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      _buildLoadMoreButton(),
                    ],
                  ),
                ),
    );
  }
}
