import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'sign_in.dart';

class Settings extends StatefulWidget {
  final bool animationsOff;
  final ValueChanged<bool> onAnimationsToggle;
  final bool isLoggedIn;
  final ValueChanged<bool> onLoginStatusChanged;
  Settings({
    required this.animationsOff,
    required this.onAnimationsToggle,
    required this.isLoggedIn,
    required this.onLoginStatusChanged,
  });

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _darkModeEnabled = false;
  bool _animationsOff = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

Future<void> _loadSettings() async {
  final settings = await DatabaseHelper().getSettings();
  bool isLoggedIn = settings['isLoggedIn'] ?? false;

  if (isLoggedIn) {
    int? userId = settings['currentUserId'];
    if (userId != null) {
      final user = await DatabaseHelper().getUserById(userId);
      if (user != null) {
        setState(() {
          _isLoggedIn = true;
        });
      } else {
                await DatabaseHelper().updateSettings(
          isLoggedIn: false,
          currentUserId: null,
        );
        setState(() {
          _isLoggedIn = false;
        });
      }
    } else {
            await DatabaseHelper().updateSettings(
        isLoggedIn: false,
        currentUserId: null,
      );
      setState(() {
        _isLoggedIn = false;
      });
    }
  } else {
    setState(() {
      _isLoggedIn = false;
    });
  }

  setState(() {
    _darkModeEnabled = settings['darkMode'] ?? false;
    _animationsOff = settings['animationsOff'] ?? false;
  });
}

  Future<void> _saveSettings() async {
    await DatabaseHelper().updateSettings(
      darkMode: _darkModeEnabled,
      animationsOff: _animationsOff,
      isLoggedIn: _isLoggedIn,
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

  void _updateLoginStatus(bool value) {
    setState(() {
      _isLoggedIn = value;
    });
    widget.onLoginStatusChanged(value);
    _saveSettings();
  }

  void _navigateToSignIn() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SignInScreen(
          onSignedIn: () {
            _updateLoginStatus(true);
          },
        ),
      ),
    );
  }

void _signOut() async {
  await DatabaseHelper().updateSettings(
    isLoggedIn: false,
    currentUserId: null,
  );
  setState(() {
    _isLoggedIn = false;
  });
  widget.onLoginStatusChanged(false);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('You have been signed out.'),
      duration: Duration(seconds: 2),
    ),
  );
  Navigator.of(context).pop(); }

void _resetUserDatabase() async {
  bool confirm = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Reset User Database'),
      content: Text(
          'Are you sure you want to delete all user data? This action cannot be undone.'),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: Text('Delete', style: TextStyle(color: Colors.red)),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await DatabaseHelper().deleteAllUsers();
    await DatabaseHelper().updateSettings(
      isLoggedIn: false,
      currentUserId: null,
    );
    setState(() {
      _isLoggedIn = false;
    });
    widget.onLoginStatusChanged(false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All user data has been deleted.'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black),
        ),
        backgroundColor: _darkModeEnabled ? Colors.black : Colors.white,
        iconTheme:
            IconThemeData(color: _darkModeEnabled ? Colors.white : Colors.black),
      ),
      body: Container(
        color: _darkModeEnabled ? Colors.black : Colors.white,
        child: ListView(
          children: [
            if (!_isLoggedIn)
              ListTile(
                title: Text(
                  'Sign In',
                  style: TextStyle(
                      fontSize: 18,
                      color: _darkModeEnabled ? Colors.white : Colors.black),
                ),
                trailing: Icon(Icons.login,
                    color: _darkModeEnabled ? Colors.white : Colors.black),
                onTap: _navigateToSignIn,
              ),
            if (_isLoggedIn)
              ListTile(
                title: Text(
                  'Sign Out',
                  style: TextStyle(
                      fontSize: 18,
                      color: _darkModeEnabled ? Colors.white : Colors.black),
                ),
                trailing: Icon(Icons.logout,
                    color: _darkModeEnabled ? Colors.white : Colors.black),
                onTap: _signOut,
              ),
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
            if (_isLoggedIn)
              ListTile(
                title: Text(
                  'Reset User Database',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
                trailing: Icon(Icons.delete_forever, color: Colors.red),
                onTap: _resetUserDatabase,
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

  Future<void> _savePreferences() async {
    await DatabaseHelper().updateSettings(
      darkMode: _darkModeEnabled,
      animationsOff: _animationsOff,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Preferences",
          style: TextStyle(color: _darkModeEnabled ? Colors.white : Colors.black),
        ),
        backgroundColor: _darkModeEnabled ? Colors.black : Colors.white,
        iconTheme:
            IconThemeData(color: _darkModeEnabled ? Colors.white : Colors.black),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePreferences,
              child: Text("Save Preferences"),
            ),
          ],
        ),
      ),
    );
  }
}
