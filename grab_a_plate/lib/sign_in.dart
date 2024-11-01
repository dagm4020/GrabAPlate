import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'home.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onSignedIn;

  SignInScreen({required this.onSignedIn});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _signInUsernameController =
      TextEditingController();
  final TextEditingController _signInPasswordController =
      TextEditingController();

  final TextEditingController _createFirstNameController =
      TextEditingController();
  final TextEditingController _createLastNameController =
      TextEditingController();
  final TextEditingController _createAgeController = TextEditingController();
  final TextEditingController _createEmailController = TextEditingController();
  final TextEditingController _createUsernameController =
      TextEditingController();
  final TextEditingController _createPasswordController =
      TextEditingController();

  bool _isSigningIn = false;
  bool _isCreatingAccount = false;
  String _error = '';

  bool _isCreateAccount = false;

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _error = '';
    });

    String username = _signInUsernameController.text.trim();
    String password = _signInPasswordController.text.trim();

    if (username.isNotEmpty && password.isNotEmpty) {
      final user = await DatabaseHelper().getUser(username, password);

      if (user != null) {
        await DatabaseHelper().updateSettings(
          isLoggedIn: true,
          currentUserId: user['id'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${user['firstName']}!'),
            duration: Duration(seconds: 2),
          ),
        );

        widget.onSignedIn();

        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _error = 'Invalid username or password.';
        });
      }
    } else {
      setState(() {
        _error = 'Please enter both username and password.';
      });
    }

    setState(() {
      _isSigningIn = false;
    });
  }

  Future<void> _createAccount() async {
    setState(() {
      _isCreatingAccount = true;
      _error = '';
    });

    String firstName = _createFirstNameController.text.trim();
    String lastName = _createLastNameController.text.trim();
    String ageText = _createAgeController.text.trim();
    String email = _createEmailController.text.trim();
    String username = _createUsernameController.text.trim();
    String password = _createPasswordController.text.trim();

    if (firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        ageText.isNotEmpty &&
        email.isNotEmpty &&
        username.isNotEmpty &&
        password.isNotEmpty) {
      int? age = int.tryParse(ageText);
      if (age == null || age <= 0) {
        setState(() {
          _error = 'Please enter a valid age.';
        });
      } else {
        final db = DatabaseHelper();
        final existingUserByUsername = await db.getUserByUsername(username);
        final existingUserByEmail = await db.getUserByEmail(email);

        if (existingUserByUsername != null) {
          setState(() {
            _error = 'Username already exists.';
          });
        } else if (existingUserByEmail != null) {
          setState(() {
            _error = 'Email already exists.';
          });
        } else {
          await DatabaseHelper().insertUser({
            'firstName': firstName,
            'lastName': lastName,
            'age': age,
            'email': email,
            'username': username,
            'password': password,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account created successfully! Please sign in.'),
              duration: Duration(seconds: 2),
            ),
          );

          setState(() {
            _isCreateAccount = false;
          });
        }
      }
    } else {
      setState(() {
        _error = 'Please fill in all fields.';
      });
    }

    setState(() {
      _isCreatingAccount = false;
    });
  }

  void _switchToCreateAccount() {
    setState(() {
      _isCreateAccount = true;
      _error = '';
    });
  }

  void _switchToSignIn() {
    setState(() {
      _isCreateAccount = false;
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Sign In / Create Account"),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child:
              _isCreateAccount ? _buildCreateAccountForm() : _buildSignInForm(),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              _error,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        Text(
          "Sign In",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        TextField(
          controller: _signInUsernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _signInPasswordController,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
          obscureText: true,
        ),
        SizedBox(height: 20),
        OutlinedButton(
          onPressed: _isSigningIn ? null : _signIn,
          child: _isSigningIn
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                )
              : Text("Sign In"),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 15),
            foregroundColor: Colors.blueAccent,
            side: BorderSide(color: Colors.blueAccent),
          ),
        ),
        TextButton(
          onPressed: _switchToCreateAccount,
          child: Text("Don't have an account? Create one"),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              _error,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        Text(
          "Create Account",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        TextField(
          controller: _createFirstNameController,
          decoration: InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _createLastNameController,
          decoration: InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _createAgeController,
          decoration: InputDecoration(
            labelText: 'Age',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 20),
        TextField(
          controller: _createEmailController,
          decoration: InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 20),
        TextField(
          controller: _createUsernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _createPasswordController,
          decoration: InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
          obscureText: true,
        ),
        SizedBox(height: 20),
        OutlinedButton(
          onPressed: _isCreatingAccount ? null : _createAccount,
          child: _isCreatingAccount
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                )
              : Text("Create Account"),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 15),
            foregroundColor: Colors.blueAccent,
            side: BorderSide(color: Colors.blueAccent),
          ),
        ),
        TextButton(
          onPressed: _switchToSignIn,
          child: Text("Already have an account? Sign In"),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blueAccent,
          ),
        ),
      ],
    );
  }
}
