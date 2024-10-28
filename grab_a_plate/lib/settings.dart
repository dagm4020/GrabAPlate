import 'package:flutter/material.dart';
import 'database_helper.dart';

class Settings extends StatefulWidget {
  final bool animationsOff;
  final ValueChanged<bool> onAnimationsToggle;

  Settings({
    required this.animationsOff,
    required this.onAnimationsToggle,
  });

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _darkModeEnabled = false;
  bool _animationsOff = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper().getSettings();
    setState(() {
      _darkModeEnabled = settings['darkMode'] ?? false;
      _animationsOff = settings['animationsOff'] ?? false;
    });
  }

  Future<void> _saveSettings() async {
    await DatabaseHelper().updateSettings(
      darkMode: _darkModeEnabled,
      animationsOff: _animationsOff,
    );
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkModeEnabled = value;
    });
  }

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
        title: Text(
          "Settings",
          style:
              TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black),
        ),
        backgroundColor: _darkModeEnabled ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
            color: _darkModeEnabled ? Colors.white : Colors.black),
      ),
      body: Container(
        color: _darkModeEnabled ? Colors.black : Colors.white,
        child: ListView(
          children: [
            ListTile(
              title: Text(
                'Preferences',
                style: TextStyle(
                    fontSize: 18,
                    color: _darkModeEnabled ? Colors.white : Colors.black),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  color: _darkModeEnabled ? Colors.white : Colors.black),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PreferencesScreen(
                    darkMode: _darkModeEnabled,
                    animationsOff: _animationsOff,
                    onDarkModeToggle: _toggleDarkMode,
                    onAnimationsToggle: _toggleAnimations,
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
  final bool darkMode;
  final bool animationsOff;
  final ValueChanged<bool> onDarkModeToggle;
  final ValueChanged<bool> onAnimationsToggle;

  PreferencesScreen({
    required this.darkMode,
    required this.animationsOff,
    required this.onDarkModeToggle,
    required this.onAnimationsToggle,
  });

  @override
  _PreferencesScreenState createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late bool _darkModeEnabled;
  late bool _animationsOff;

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = widget.darkMode;
    _animationsOff = widget.animationsOff;
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _darkModeEnabled = value;
      widget.onDarkModeToggle(value);
    });
  }

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
        title: Text(
          "Preferences",
          style:
              TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black),
        ),
        backgroundColor: _darkModeEnabled ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
            color: _darkModeEnabled ? Colors.white : Colors.black),
      ),
      body: Container(
        color: _darkModeEnabled ? Colors.black : Colors.white,
        child: Column(
          children: [
            ListTile(
              title: Text('Dark Mode',
                  style: TextStyle(
                      color: _darkModeEnabled ? Colors.white : Colors.black)),
              trailing: Switch(
                value: _darkModeEnabled,
                onChanged: _toggleDarkMode,
              ),
            ),
            ListTile(
              title: Text('Turn Off Animations',
                  style: TextStyle(
                      color: _darkModeEnabled ? Colors.white : Colors.black)),
              trailing: Switch(
                value: _animationsOff,
                onChanged: _toggleAnimations,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper().updateSettings(
                  darkMode: _darkModeEnabled,
                  animationsOff: _animationsOff,
                );
                Navigator.of(context).pop();
              },
              child: Text("Save Preferences"),
            ),
          ],
        ),
      ),
    );
  }
}
