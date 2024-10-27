import 'package:flutter/material.dart';
import 'meal_plan.dart';
import 'grocery_list.dart';
import 'favorites.dart';
import 'settings.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(); // To control page transitions
  int _currentIndex = 0;

  bool _isDarkMode = false;
  bool _animationsOff = false;

  final List<Widget> _screens = [
    Container(color: Colors.white, child: Home()),       // White background for Home
    Container(color: Colors.white, child: MealPlan()),   // White background for Meal Plan
    Container(color: Colors.white, child: GroceryList()), // White background for Grocery List
    Container(color: Colors.white, child: Favorites()),  // White background for Favorites
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (!_animationsOff) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 500), // Animation duration
        curve: Curves.easeInOut, // Smooth curve for animation
      );
    } else {
      // If animations are off, change the page without animation
      _pageController.jumpToPage(index);
    }
  }

  void _goToSettings() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => Settings(
        isDarkMode: _isDarkMode,
        animationsOff: _animationsOff,
        onDarkModeToggle: (value) {
          setState(() {
            _isDarkMode = value;
          });
        },
        onAnimationsToggle: (value) {
          setState(() {
            _animationsOff = value;
          });
        },
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (_animationsOff) {
          return child; // No animation if toggled off
        }

        const begin = Offset(0.0, 1.0); // Start from bottom
        const end = Offset.zero; // End at the current position
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80.0, // Increased app bar height
        backgroundColor: _isDarkMode ? Colors.black : Colors.white, // Dark mode handling
        title: GestureDetector(
          onTap: _goToSettings,
          child: Row(
            children: [
              CircleAvatar(
                child: Icon(Icons.person, color: _isDarkMode ? Colors.white : Colors.black), // Default user silhouette
              ),
              SizedBox(width: 8),
              Text(
                "John Doe",
                style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black), // Set text color to black
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController, // Use PageController for swipe animation
        physics: NeverScrollableScrollPhysics(), // Disable swipe gesture
        children: _screens,
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white, // Set bottom navigation bar color to white
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home, color: _isDarkMode ? Colors.white : Colors.black),
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              icon: Icon(Icons.food_bank, color: _isDarkMode ? Colors.white : Colors.black),
              onPressed: () => _onItemTapped(1),
            ),
            IconButton(
              icon: Icon(Icons.list, color: _isDarkMode ? Colors.white : Colors.black),
              onPressed: () => _onItemTapped(2),
            ),
            IconButton(
              icon: Icon(Icons.favorite, color: _isDarkMode ? Colors.white : Colors.black),
              onPressed: () => _onItemTapped(3),
            ),
          ],
        ),
      ),
    );
  }
}

// Home widget
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Home Screen', style: TextStyle(fontSize: 24)),
    );
  }
}
