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
import 'sign_in.dart';
import 'suggested_meals.dart'; 
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

class Home extends StatefulWidget {
  final VoidCallback onNavigateToFavorites;
  final bool darkModeEnabled;
  final bool isLoggedIn;
  final int? currentUserId;
  final VoidCallback onNavigateToSignIn;
  final Function(bool) onUpdateLoginStatus;

  Home({
    required this.onNavigateToFavorites,
    required this.darkModeEnabled,
    required this.isLoggedIn,
    required this.currentUserId,
    required this.onNavigateToSignIn,
    required this.onUpdateLoginStatus,
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

      List<Meal> _favoriteMeals = [];

  @override
  void initState() {
    super.initState();
    _filteredMeals = [];
    _fetchSuggestedMeals();
    _fetchFavoriteMeals();   }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchFavoriteMeals() async {
    if (widget.currentUserId != null) {
      final dbHelper = DatabaseHelper();
      List<Map<String, dynamic>> favoriteMealsData =
          await dbHelper.getFavoriteMealsByUserId(widget.currentUserId!);
      List<Meal> favoriteMeals =
          favoriteMealsData.map((mealData) => Meal.fromMap(mealData)).toList();

      setState(() {
        _favoriteMeals = favoriteMeals;
      });
    } else {
      setState(() {
        _favoriteMeals = [];
      });
    }
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

  Widget _buildMealCard(Meal meal) {
  final textColor = widget.darkModeEnabled ? Colors.white : Colors.black;
  return Column(
    children: [
      GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MealDetailScreen(meal: meal),
            ),
          );
        },
        child: Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            color: widget.darkModeEnabled ? Colors.grey[800] : Colors.grey[300],
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: widget.darkModeEnabled ? Colors.white54 : Colors.black26,
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
      ),
      SizedBox(height: 8),
      Container(
        width: 170,
        child: Text(
          meal.name,
          style: TextStyle(fontSize: 16, color: textColor),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
      ),
    ],
  );
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
                              darkModeEnabled: widget.darkModeEnabled,
                              currentUserId: widget.currentUserId,
                              onLoginStatusChanged: widget.onUpdateLoginStatus,
                            ),
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
                    Text(
                      'Your Favorites',
                      style: TextStyle(fontSize: 20, color: textColor),
                    ),
                    TextButton(
                      onPressed: widget.onNavigateToFavorites,
                      child: Text(
                        'More...',
                        style: TextStyle(fontSize: 20, color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (_favoriteMeals.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_favoriteMeals.length > 0)
                        _buildMealCard(_favoriteMeals[0]),
                      if (_favoriteMeals.length > 1)
                        _buildMealCard(_favoriteMeals[1]),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Text(
                    'No favorite meals yet.',
                    style: TextStyle(fontSize: 16, color: textColor),
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
  int _currentIndex = 0;
  bool _animationsOff = false;
  bool _darkModeEnabled = false;
  bool _isLoggedIn = false;
  String? _userName;
  int? _currentUserId;

  final PageController _pageController = PageController();
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper().getSettings();
    bool isLoggedIn = settings['isLoggedIn'] ?? false;
    bool darkMode = settings['darkMode'] ?? false;
    bool animationsOff = settings['animationsOff'] ?? false;

    if (isLoggedIn) {
      int? userId = settings['currentUserId'];
      if (userId != null) {
        final user = await DatabaseHelper().getUserById(userId);
        if (user != null) {
          setState(() {
            _userName = '${user['firstName']} ${user['lastName']}';
            _isLoggedIn = true;
            _currentUserId = userId;
          });
        } else {
                    await DatabaseHelper().updateSettings(
            isLoggedIn: false,
            currentUserId: null,
          );
          setState(() {
            _isLoggedIn = false;
            _userName = null;
            _currentUserId = null;
          });
        }
      } else {
                await DatabaseHelper().updateSettings(
          isLoggedIn: false,
          currentUserId: null,
        );
        setState(() {
          _isLoggedIn = false;
          _userName = null;
          _currentUserId = null;
        });
      }
    } else {
      setState(() {
        _isLoggedIn = false;
        _userName = null;
        _currentUserId = null;
      });
    }

    setState(() {
      _darkModeEnabled = darkMode;
      _animationsOff = animationsOff;
    });

        _initializeScreens();
  }

  void _initializeScreens() {
    _screens = [
      Home(
        onNavigateToFavorites: _navigateToFavorites,
        darkModeEnabled: _darkModeEnabled,
        isLoggedIn: _isLoggedIn,
        currentUserId: _currentUserId,
        onNavigateToSignIn: _navigateToSignIn,
        onUpdateLoginStatus: _onLoginStatusChanged,
      ),
      MealPlan(),
      GroceryList(),
      Favorites(
        darkModeEnabled: _darkModeEnabled,
        currentUserId: _currentUserId,
      ),
    ];
  }

  void _navigateToFavorites() {
    _onItemTapped(3);
  }

  void _onSignedIn() {
    setState(() {
      _isLoggedIn = true;
    });
    _loadSettings();
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

  void _onLoginStatusChanged(bool isLoggedIn) {
    setState(() {
      _isLoggedIn = isLoggedIn;
      if (_isLoggedIn) {
        _loadSettings();
      } else {
        _userName = null;
        _currentUserId = null;
        _loadSettings();
      }
    });
  }

  Future<void> _loadUserName() async {
    final settings = await DatabaseHelper().getSettings();
    int? userId = settings['currentUserId'];
    if (userId != null) {
      final user = await DatabaseHelper().getUserById(userId);
      if (user != null) {
        setState(() {
          _userName = '${user['firstName']} ${user['lastName']}';
        });
      }
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
            onLoginStatusChanged: _onLoginStatusChanged,
          ),
        ))
        .then((_) => _loadSettings());
  }

  void _navigateToSignIn() async {
    await Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => SignInScreen(
              onSignedIn: () {
                _onLoginStatusChanged(true);
              },
            ),
          ),
        )
        .then((_) => _loadSettings());
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
                onTap: () {
                  if (_isLoggedIn) {
                    _goToSettings();
                  } else {
                    _navigateToSignIn();
                  }
                },
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
                      _isLoggedIn && _userName != null ? _userName! : "Sign In",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: _darkModeEnabled ? Colors.white : Colors.black,
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
