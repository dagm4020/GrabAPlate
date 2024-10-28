import 'package:flutter/material.dart';
import 'database_helper.dart';

class Favorites extends StatefulWidget {
  @override
  _FavoritesState createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final settings = await DatabaseHelper().getSettings();
    setState(() {
      _darkModeEnabled = settings['darkMode'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _darkModeEnabled ? Colors.black : Colors.white,
      child: Center(
        child: Text(
          'Favorites Screen',
          style: TextStyle(
            fontSize: 24,
            color: _darkModeEnabled ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
