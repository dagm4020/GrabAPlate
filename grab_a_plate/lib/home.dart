import 'package:flutter/material.dart';
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
      body: Center(
        child: Text(
          'List of Suggested Meals',
          style: TextStyle(fontSize: 18, color: textColor),
        ),
      ),
    );
  }
}

class Home extends StatelessWidget {
  final VoidCallback onNavigateToFavorites;
  final bool darkModeEnabled;

  Home({required this.onNavigateToFavorites, required this.darkModeEnabled});

  @override
  Widget build(BuildContext context) {
    final textColor = darkModeEnabled ? Colors.white : Colors.black;

    return Column(
      children: [
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: darkModeEnabled ? Colors.grey[700] : Colors.grey[100],
            borderRadius: BorderRadius.circular(30.0),
            border: Border.all(color: textColor.withOpacity(0.5), width: 0.5),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search, color: textColor.withOpacity(0.7)),
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
              contentPadding: EdgeInsets.symmetric(vertical: 10.0),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                          darkModeEnabled: darkModeEnabled),
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color:
                          darkModeEnabled ? Colors.grey[800] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                          color: darkModeEnabled
                              ? Colors.white54
                              : Colors.black26),
                    ),
                    child: Center(
                      child: Text(
                        "Image 1",
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text("Meal Name 1",
                      style: TextStyle(fontSize: 16, color: textColor)),
                ],
              ),
              Column(
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color:
                          darkModeEnabled ? Colors.grey[800] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                          color: darkModeEnabled
                              ? Colors.white54
                              : Colors.black26),
                    ),
                    child: Center(
                      child: Text(
                        "Image 2",
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text("Meal Name 2",
                      style: TextStyle(fontSize: 16, color: textColor)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 35.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Favorites',
                  style: TextStyle(fontSize: 20, color: textColor)),
              TextButton(
                onPressed: onNavigateToFavorites,
                child: Text('More...',
                    style: TextStyle(fontSize: 20, color: textColor)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color:
                          darkModeEnabled ? Colors.grey[800] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                          color: darkModeEnabled
                              ? Colors.white54
                              : Colors.black26),
                    ),
                    child: Center(
                      child: Text(
                        "Image 3",
                        style: TextStyle(color: textColor.withOpacity(0.7)),
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
                      color:
                          darkModeEnabled ? Colors.grey[800] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                          color: darkModeEnabled
                              ? Colors.white54
                              : Colors.black26),
                    ),
                    child: Center(
                      child: Text(
                        "Image 4",
                        style: TextStyle(color: textColor.withOpacity(0.7)),
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

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _screens.addAll([
      Home(
        onNavigateToFavorites: _navigateToFavorites,
        darkModeEnabled: _darkModeEnabled,
      ),
      MealPlan(),
      GroceryList(),
      Favorites(),
    ]);
  }

  Future<void> _loadDarkModePreference() async {
    final settings = await DatabaseHelper().getSettings();
    setState(() {
      _darkModeEnabled = settings['darkMode'] ?? false;
      _animationsOff = settings['animationsOff'] ?? false;
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

  void _goToSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (context) => Settings(
            animationsOff: _animationsOff,
            onAnimationsToggle: (value) {
              setState(() => _animationsOff = value);
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
                      "John Doe",
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
      body: PageView(
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
