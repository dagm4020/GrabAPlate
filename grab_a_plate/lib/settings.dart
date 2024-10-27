import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  final bool isDarkMode;
  final bool animationsOff;
  final ValueChanged<bool> onDarkModeToggle;
  final ValueChanged<bool> onAnimationsToggle;

  Settings({
    required this.isDarkMode,
    required this.animationsOff,
    required this.onDarkModeToggle,
    required this.onAnimationsToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          children: [
            ListTile(
              title: Text(
                'Preferences',
                style: TextStyle(fontSize: 18), // Removed bold
              ),
              trailing: Icon(Icons.arrow_forward_ios), // Added arrow to the right
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PreferencesScreen(
                    isDarkMode: isDarkMode,
                    animationsOff: animationsOff,
                    onDarkModeToggle: onDarkModeToggle,
                    onAnimationsToggle: onAnimationsToggle,
                  ),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PreferencesScreen extends StatefulWidget {
  final bool isDarkMode;
  final bool animationsOff;
  final ValueChanged<bool> onDarkModeToggle;
  final ValueChanged<bool> onAnimationsToggle;

  PreferencesScreen({
    required this.isDarkMode,
    required this.animationsOff,
    required this.onDarkModeToggle,
    required this.onAnimationsToggle,
  });

  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late bool _isDarkMode;
  late bool _animationsOff;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _animationsOff = widget.animationsOff;
  }

  // Toggle Dark Mode
  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
      widget.onDarkModeToggle(value);
    });
  }

  // Toggle Animations
  void _toggleAnimations(bool value) {
    setState(() {
      _animationsOff = value;
      widget.onAnimationsToggle(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Preferences"),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            ListTile(
              title: Text('Dark Mode'),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
              ),
            ),
            ListTile(
              title: Text('Turn Off Animations'),
              trailing: Switch(
                value: _animationsOff,
                onChanged: _toggleAnimations,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Go back to settings
              },
              child: Text("Save Preferences"),
            ),
          ],
        ),
      ),
    );
  }
}
