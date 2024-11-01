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
import 'search.dart';
import 'main.dart';

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
    Key? key,
    required this.onNavigateToFavorites,
    required this.darkModeEnabled,
    required this.isLoggedIn,
    required this.currentUserId,
    required this.onNavigateToSignIn,
    required this.onUpdateLoginStatus,
  }) : super(key: key);
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with RouteAware {
  String _searchQuery = "";
  List<Meal> _searchResults = [];
  Timer? _debounce;
  bool _isSearching = false;

  final FocusNode _focusNode = FocusNode();

  Meal? _meal1;
  Meal? _meal2;
  bool _isLoadingMeals = false;
  String _mealError = '';

  List<Map<String, dynamic>> _favoriteMeals = [];

  @override
  void initState() {
    super.initState();
    _fetchSuggestedMeals();
    _fetchFavoriteMeals();
  }

  @override
  void didUpdateWidget(covariant Home oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUserId != widget.currentUserId) {
      _fetchFavoriteMeals();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    _fetchFavoriteMeals();
  }

  Future<void> _fetchFavoriteMeals() async {
    if (widget.currentUserId != null) {
      final dbHelper = DatabaseHelper();
      List<Map<String, dynamic>> favoriteMealsData =
          await dbHelper.getFavorites(widget.currentUserId!);

      List<Map<String, dynamic>> firstTwoFavorites =
          favoriteMealsData.take(2).toList();

      setState(() {
        _favoriteMeals = firstTwoFavorites;
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

  void _updateSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchMeals(query);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _searchMeals(String query) async {
    setState(() {
      _isSearching = true;
    });

    final response = await http.get(Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/search.php?s=$query'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<Meal> meals = [];
      if (data['meals'] != null) {
        meals =
            List<Meal>.from(data['meals'].map((meal) => Meal.fromJson(meal)));
      }
      setState(() {
        _searchResults = meals;
        _isSearching = false;
      });
    } else {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Widget _buildMealCard(Meal meal) {
    final textColor = widget.darkModeEnabled ? Colors.white : Colors.black;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            _navigateToMealDetail(meal);
          },
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color:
                  widget.darkModeEnabled ? Colors.grey[800] : Colors.grey[300],
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

  Widget _buildFavoriteMealCard(Map<String, dynamic> mealData) {
    final textColor = widget.darkModeEnabled ? Colors.white : Colors.black;
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            String mealId = mealData['mealId'];
            Meal? meal = await _fetchMealDetails(mealId);
            if (meal != null) {
              _navigateToMealDetail(meal);
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
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color:
                  widget.darkModeEnabled ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: widget.darkModeEnabled ? Colors.white54 : Colors.black26,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.network(
                mealData['mealThumbnail'],
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
          width: 170,
          child: Text(
            mealData['mealName'],
            style: TextStyle(fontSize: 16, color: textColor),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
      ],
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

  void _onSearchSubmitted(String query) {
    _focusNode.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          query: query,
          currentUserId: widget.currentUserId,
        ),
      ),
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
                  onSubmitted: _onSearchSubmitted,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon:
                        Icon(Icons.search, color: textColor.withOpacity(0.7)),
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                  ),
                  style: TextStyle(color: textColor),
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
                    if (_meal1 != null)
                      _buildMealCard(_meal1!)
                    else
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
                          child: _isLoadingMeals
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.darkModeEnabled
                                          ? Colors.white
                                          : Colors.black),
                                )
                              : Text(
                                  _mealError.isNotEmpty ? 'Error' : 'Image 1',
                                  style: TextStyle(
                                      color: textColor.withOpacity(0.7)),
                                ),
                        ),
                      ),
                    if (_meal2 != null)
                      _buildMealCard(_meal2!)
                    else
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
                          child: _isLoadingMeals
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.darkModeEnabled
                                          ? Colors.white
                                          : Colors.black),
                                )
                              : Text(
                                  _mealError.isNotEmpty ? 'Error' : 'Image 2',
                                  style: TextStyle(
                                      color: textColor.withOpacity(0.7)),
                                ),
                        ),
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
                      _buildFavoriteMealCard(_favoriteMeals[0]),
                      if (_favoriteMeals.length > 1)
                        _buildFavoriteMealCard(_favoriteMeals[1]),
                      if (_favoriteMeals.length == 1) SizedBox(width: 170),
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
        if (_searchResults.isNotEmpty && _focusNode.hasFocus)
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
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  Meal meal = _searchResults[index];
                  return ListTile(
                    title: Text(
                      meal.name,
                      style: TextStyle(
                          color: widget.darkModeEnabled
                              ? Colors.white
                              : Colors.black),
                    ),
                    onTap: () {
                      _navigateToMealDetail(meal);
                      setState(() {
                        _searchQuery = "";
                        _searchResults = [];
                      });
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        if (_isSearching)
          Positioned(
            top: 64.0,
            left: 50.0,
            right: 50.0,
            child: Container(
              padding: EdgeInsets.all(16.0),
              color: widget.darkModeEnabled ? Colors.grey[800] : Colors.white,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      widget.darkModeEnabled ? Colors.white : Colors.black),
                ),
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
        key: ValueKey(_currentUserId),
        onNavigateToFavorites: _navigateToFavorites,
        darkModeEnabled: _darkModeEnabled,
        isLoggedIn: _isLoggedIn,
        currentUserId: _currentUserId,
        onNavigateToSignIn: _navigateToSignIn,
        onUpdateLoginStatus: _onLoginStatusChanged,
      ),
      MealPlan(
        currentUserId: _currentUserId,
      ),
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
              icon: Icon(
                Icons.shopping_cart,
                color: _darkModeEnabled ? Colors.white : Colors.black,
              ),
              onPressed: () => _onItemTapped(2),
            ),
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
