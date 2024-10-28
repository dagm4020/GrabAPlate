import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class MealPlan extends StatefulWidget {
  @override
  _MealPlanState createState() => _MealPlanState();
}

class _MealPlanState extends State<MealPlan> {
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
    final backgroundColor = _darkModeEnabled ? Colors.black : Colors.white;
    final textColor = _darkModeEnabled ? Colors.white : Colors.black;

    final double placeholderHeight = 115.0;

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
              child: SevenDayCalendar(),
            ),
            SizedBox(height: 45.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Breakfast',
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
              padding:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
              child: Container(
                height: placeholderHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey[600],
                      ),
                    ),
                    Positioned(
                      top: 8.0,
                      right: 8.0,
                      child: HeartToggleButton(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0, top: 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Description',
                  style: TextStyle(fontSize: 12, color: textColor),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Lunch',
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
              padding:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
              child: Container(
                height: placeholderHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey[600],
                      ),
                    ),
                    Positioned(
                      top: 8.0,
                      right: 8.0,
                      child: HeartToggleButton(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0, top: 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Description',
                  style: TextStyle(fontSize: 12, color: textColor),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Dinner',
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
              padding:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20.0),
              child: Container(
                height: placeholderHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey[600],
                      ),
                    ),
                    Positioned(
                      top: 8.0,
                      right: 8.0,
                      child: HeartToggleButton(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0, top: 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Description',
                  style: TextStyle(fontSize: 12, color: textColor),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeartToggleButton extends StatefulWidget {
  @override
  _HeartToggleButtonState createState() => _HeartToggleButtonState();
}

class _HeartToggleButtonState extends State<HeartToggleButton> {
  bool isHeartClicked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isHeartClicked = !isHeartClicked;
        });
      },
      child: isHeartClicked
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2.0),
                color: Colors.white,
              ),
              padding: EdgeInsets.all(5.0),
              child: Icon(
                Icons.add,
                color: Colors.black,
                size: 16,
              ),
            )
          : Icon(
              Icons.favorite,
              color: Colors.red,
              size: 24,
            ),
    );
  }
}

class SevenDayCalendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateFormat('MMMM').format(now);

    List<Widget> dayWidgets = [];
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dayOfWeek = DateFormat.E().format(date);
      final dayNumber = date.day;

      dayWidgets.add(
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            minimumSize: Size(40, 50),
            backgroundColor:
                date.day == now.day ? Colors.blueAccent : Colors.grey[200],
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
      );
    }

    return Column(
      children: [
        Text(
          month,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayWidgets,
        ),
      ],
    );
  }
}
