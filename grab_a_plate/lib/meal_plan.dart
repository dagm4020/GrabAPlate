import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';
import 'meal_detail_screen.dart';
import 'models/meal.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealPlan extends StatefulWidget {
  final int? currentUserId;

  MealPlan({required this.currentUserId});

  @override
  _MealPlanState createState() => _MealPlanState();
}

class _MealPlanState extends State<MealPlan> {
  bool _darkModeEnabled = false;
  DateTime selectedDate = DateTime.now();
  Map<String, Map<String, dynamic>> mealPlans = {};

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _loadMealPlans();
  }

  Future<void> _loadDarkModePreference() async {
    final settings = await DatabaseHelper().getSettings();
    setState(() {
      _darkModeEnabled = settings['darkMode'] ?? false;
    });
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

  Future<void> _loadMealPlans() async {
    if (widget.currentUserId == null) {
      setState(() {
        mealPlans = {};
      });
      return;
    }

    String dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
    List<Map<String, dynamic>> meals =
        await DatabaseHelper().getMealPlans(widget.currentUserId!, dateString);

    Map<String, Map<String, dynamic>> plans = {};

    for (var meal in meals) {
      String mealType = meal['mealType'];
      plans[mealType] = meal;
    }

    setState(() {
      mealPlans = plans;
    });
  }

  Widget _buildMealPlanSection(String mealType) {
    final textColor = _darkModeEnabled ? Colors.white : Colors.black;
    Map<String, dynamic>? mealData = mealPlans[mealType];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {},
              child: Text(
                mealType[0].toUpperCase() + mealType.substring(1),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  color: textColor,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
          child: mealData != null
              ? GestureDetector(
                  onTap: () async {
                    Meal? meal = await _fetchMealDetails(mealData['mealId']);
                    if (meal != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MealDetailScreen(
                            meal: meal,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to load meal details.'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 115.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _darkModeEnabled
                          ? Colors.grey[800]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.network(
                            mealData['mealThumbnail'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 115.0,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[600],
                                  size: 50,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Container(
                  height: 115.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        _darkModeEnabled ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20.0, top: 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              mealData != null
                  ? mealData['mealName']
                  : 'Add a food to see it here',
              style: TextStyle(fontSize: 12, color: textColor),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        SizedBox(height: 10.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _darkModeEnabled ? Colors.black : Colors.white;
    final textColor = _darkModeEnabled ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          backgroundColor: backgroundColor,
          iconTheme: IconThemeData(color: textColor),
          elevation: 0,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 10.0),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: Text(
                  'Meal Planner',
                  style: TextStyle(
                    fontSize: 20,
                    color: textColor,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Center(
              child: SevenDayCalendar(
                selectedDate: selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                  _loadMealPlans();
                },
              ),
            ),
            SizedBox(height: 45.0),
            _buildMealPlanSection('breakfast'),
            _buildMealPlanSection('lunch'),
            _buildMealPlanSection('dinner'),
          ],
        ),
      ),
    );
  }
}

class SevenDayCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  SevenDayCalendar({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    List<Widget> dayWidgets = [];
    for (int i = 0; i < 14; i++) {
      final date = now.add(Duration(days: i));
      final dayOfWeek = DateFormat('EEE').format(date);
      final dayNumber = date.day;

      bool isSelected = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;

      dayWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: TextButton(
            onPressed: () {
              onDateSelected(date);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              minimumSize: Size(40, 50),
              backgroundColor:
                  isSelected ? Colors.blueAccent : Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayOfWeek,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                SizedBox(height: 2.0),
                Text(
                  '$dayNumber',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Text(
          DateFormat('MMMM').format(selectedDate),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10.0),
        Container(
          height: 80,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: dayWidgets,
            ),
          ),
        ),
      ],
    );
  }
}
