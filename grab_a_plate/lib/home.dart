import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/meal.dart';

import 'meal_detail_screen.dart';

import 'meal_plan.dart';
import 'grocery_list.dart';
import 'favorites.dart';
import 'settings.dart';
import 'database_helper.dart';

class SlideTransitionPageRoute extends PageRouteBuilder {
  final Widget page;
  SlideTransitionPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

class SuggestedMealsScreen extends StatelessWidget {
  final bool darkModeEnabled;
  SuggestedMealsScreen({required this.darkModeEnabled});

  @override
  Widget build(BuildContext context) {
    final textColor = darkModeEnabled ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: darkModeEnabled ? Colors.black : Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Column(
          children: [
            AppBar(
              title: Text(
                'Suggested Meals',
                style: TextStyle(fontSize: 20, color: textColor),
              ),
              backgroundColor: darkModeEnabled ? Colors.black : Colors.white,
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
          future: _fetchSixRandomMeals(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      darkModeEnabled ? Colors.white : Colors.black),
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
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
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

                  return Column(
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
                            color: darkModeEnabled
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: darkModeEnabled
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
}

class Home extends StatefulWidget {
  final VoidCallback onNavigateToFavorites;
  final bool darkModeEnabled;
  final bool isLoggedIn; 

  Home({
    required this.onNavigateToFavorites,
    required this.darkModeEnabled,
    required this.isLoggedIn, 
  });

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<String> _allMeals = [
    "Spicy Arrabiata Penne",
    "Chicken Alfredo",
    "Beef Stroganoff",
    "Spaghetti Bolognese",
    "Grilled Salmon",
    "Vegetable Stir Fry",
    "Shrimp Tacos",
    "Spicy Tuna Roll",
    "Margherita Pizza",
    "Caesar Salad",
  ];

  String _searchQuery = "";
  List<String> _filteredMeals = [];

  final FocusNode _focusNode = FocusNode();

  Meal? _meal1;
  Meal? _meal2;
  bool _isLoadingMeals = false;
  String _mealError = '';

  @override
  void initState() {
    super.initState();
    _filteredMeals = [];
    _fetchSuggestedMeals();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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

  Future<void> _fetchSuggestedMeals() async {
    setState(() {
      _isLoadingMeals = true;
      _mealError = '';
    });

    try {
      final meal1 = await _fetchRandomMeal();
      final meal2 = await _fetchRandomMeal();

      setState(() {
        _meal1 = meal1;
        _meal2 = meal2;
        _isLoadingMeals = false;
      });
    } catch (e) {
      setState(() {
        _mealError = e.toString();
        _isLoadingMeals = false;
      });
      print("Error fetching meals: $e");
    }
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (_searchQuery.isEmpty) {
        _filteredMeals = [];
      } else {
        _filteredMeals = _allMeals
            .where((meal) =>
                meal.toLowerCase().contains(_searchQuery.toLowerCase()))
            .take(5)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.darkModeEnabled ? Colors.white : Colors.black;

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(
                    horizontal: 50.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: widget.darkModeEnabled
                      ? Colors.grey[700]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(30.0),
                  border:
                      Border.all(color: textColor.withOpacity(0.5), width: 0.5),
                ),
                child: TextField(
                  focusNode: _focusNode,
                  onChanged: _updateSearch,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon:
                        Icon(Icons.search, color: textColor.withOpacity(0.7)),
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                  ),
                ),
              ),
              if (_filteredMeals.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 50.0),
                  decoration: BoxDecoration(
                    color: widget.darkModeEnabled
                        ? Colors.grey[800]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: textColor.withOpacity(0.5)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredMeals.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          _filteredMeals[index],
                          style: TextStyle(
                              color: widget.darkModeEnabled
                                  ? Colors.white
                                  : Colors.black),
                        ),
                        onTap: () {
                          print("Selected Meal: ${_filteredMeals[index]}");
                        },
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Suggested Meals',
                        style: TextStyle(fontSize: 20, color: textColor)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          SlideTransitionPageRoute(
                            page: SuggestedMealsScreen(
                                darkModeEnabled: widget.darkModeEnabled),
                          ),
                        );
                      },
                      child: Text('More...',
                          style: TextStyle(fontSize: 20, color: textColor)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_meal1 != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MealDetailScreen(meal: _meal1!),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              color: widget.darkModeEnabled
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(
                                  color: widget.darkModeEnabled
                                      ? Colors.white54
                                      : Colors.black26),
                            ),
                            child: _isLoadingMeals
                                ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          widget.darkModeEnabled
                                              ? Colors.white
                                              : Colors.black),
                                    ),
                                  )
                                : _mealError.isNotEmpty
                                    ? Center(
                                        child: Text(
                                          'Error',
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 16),
                                        ),
                                      )
                                    : _meal1 != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            child: Image.network(
                                              _meal1!.thumbnail,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              "Image 1",
                                              style: TextStyle(
                                                  color: textColor
                                                      .withOpacity(0.7)),
                                            ),
                                          ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 170,
                          child: Text(
                            _meal1 != null ? _meal1!.name : "Meal Name 1",
                            style: TextStyle(fontSize: 16, color: textColor),
                            textAlign: TextAlign.center,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_meal2 != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MealDetailScreen(meal: _meal2!),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              color: widget.darkModeEnabled
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(
                                  color: widget.darkModeEnabled
                                      ? Colors.white54
                                      : Colors.black26),
                            ),
                            child: _isLoadingMeals
                                ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          widget.darkModeEnabled
                                              ? Colors.white
                                              : Colors.black),
                                    ),
                                  )
                                : _mealError.isNotEmpty
                                    ? Center(
                                        child: Text(
                                          'Error',
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 16),
                                        ),
                                      )
                                    : _meal2 != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            child: Image.network(
                                              _meal2!.thumbnail,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              "Image 2",
                                              style: TextStyle(
                                                  color: textColor
                                                      .withOpacity(0.7)),
                                            ),
                                          ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 170,
                          child: Text(
                            _meal2 != null ? _meal2!.name : "Meal Name 2",
                            style: TextStyle(fontSize: 16, color: textColor),
                            textAlign: TextAlign.center,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoadingMeals ? null : _fetchSuggestedMeals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.1),
                ),
                child: Text('Refresh Suggested Meals'),
              ),
              SizedBox(height: 35.0),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Favorites',
                        style: TextStyle(fontSize: 20, color: textColor)),
                    TextButton(
                      onPressed: widget.onNavigateToFavorites,
                      child: Text('More...',
                          style: TextStyle(fontSize: 20, color: textColor)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: widget.darkModeEnabled
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                                color: widget.darkModeEnabled
                                    ? Colors.white54
                                    : Colors.black26),
                          ),
                          child: Center(
                            child: Text(
                              "Image 3",
                              style:
                                  TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text("Favorite 1",
                            style: TextStyle(fontSize: 16, color: textColor)),
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: widget.darkModeEnabled
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                                color: widget.darkModeEnabled
                                    ? Colors.white54
                                    : Colors.black26),
                          ),
                          child: Center(
                            child: Text(
                              "Image 4",
                              style:
                                  TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text("Favorite 2",
                            style: TextStyle(fontSize: 16, color: textColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_filteredMeals.isNotEmpty)
          Positioned(
            top: 64.0,
            left: 50.0,
            right: 50.0,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8.0),
              color: widget.darkModeEnabled ? Colors.grey[800] : Colors.white,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredMeals.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _filteredMeals[index],
                      style: TextStyle(
                          color: widget.darkModeEnabled
                              ? Colors.white
                              : Colors.black),
                    ),
                    onTap: () {
                      print("Selected Meal: ${_filteredMeals[index]}");
                      setState(() {
                        _searchQuery = "";
                        _filteredMeals = [];
                      });
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _animationsOff = false;
  bool _darkModeEnabled = false;
  final List<Widget> _screens = [];
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

Future<void> _loadDarkModePreference() async {
    final settings = await DatabaseHelper().getSettings();
    setState(() {
      _darkModeEnabled = settings['darkMode'] ?? false;
      _animationsOff = settings['animationsOff'] ?? false;
      _isLoggedIn = settings['isLoggedIn'] ?? false; 
      _screens.addAll([
        Home(
          onNavigateToFavorites: _navigateToFavorites,
          darkModeEnabled: _darkModeEnabled,
          isLoggedIn: _isLoggedIn,
        ),
        MealPlan(),
        GroceryList(),
        Favorites(),
      ]);
    });
  }

  void _navigateToFavorites() {
    _onItemTapped(3);
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    if (!_animationsOff) {
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      _pageController.jumpToPage(index);
    }
  }

void _goToSettings() async {

  await Navigator.of(context)
      .push(MaterialPageRoute(
        builder: (context) => Settings(
          animationsOff: _animationsOff,
          onAnimationsToggle: (value) {
            setState(() => _animationsOff = value);
          },
          isLoggedIn: _isLoggedIn, 
          onLoginStatusChanged: (value) {
            setState(() => _isLoggedIn = value);
          },
        ),
      ))
      .then((_) => _loadDarkModePreference());
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkModeEnabled ? Colors.black : Colors.white,
            appBar: PreferredSize(
        preferredSize: Size.fromHeight(130.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: _darkModeEnabled ? Colors.black : Colors.white,
              title: GestureDetector(
                onTap: _goToSettings,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.black, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 20,
                            color:
                                _darkModeEnabled ? Colors.black : Colors.black),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _isLoggedIn ? "John Doe" : "Sign In",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color:
                            _darkModeEnabled ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 50.0),
              height: 2.0,
              color: _darkModeEnabled ? Colors.white60 : Colors.black54,
            ),
          ],
        ),
      ),
      body: _screens.isEmpty
          ? Center(child: CircularProgressIndicator())
          : PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              children: _screens),
      bottomNavigationBar: BottomAppBar(
        color: _darkModeEnabled ? Colors.black : Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                icon: Icon(Icons.home,
                    color: _darkModeEnabled ? Colors.white : Colors.black),
                onPressed: () => _onItemTapped(0)),
            IconButton(
                icon: Icon(Icons.food_bank,
                    color: _darkModeEnabled ? Colors.white : Colors.black),
                onPressed: () => _onItemTapped(1)),
            IconButton(
                icon: Icon(Icons.list,
                    color: _darkModeEnabled ? Colors.white : Colors.black),
                onPressed: () => _onItemTapped(2)),
            IconButton(
                icon: Icon(Icons.favorite,
                    color: _darkModeEnabled ? Colors.white : Colors.black),
                onPressed: () => _onItemTapped(3)),
          ],
        ),
      ),
    );
  }
}
