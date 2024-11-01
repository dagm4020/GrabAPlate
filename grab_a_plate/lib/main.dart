import 'package:flutter/material.dart';
import 'home.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grab A Plate',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(), // this should point to homescreen
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
    );
  }
}

