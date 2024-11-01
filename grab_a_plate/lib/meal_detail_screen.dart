import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/meal.dart';
import 'database_helper.dart';
import 'sign_in.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';

class MealDetailScreen extends StatefulWidget {
  final Meal meal;
  final int? currentUserId;

  MealDetailScreen({
    required this.meal,
    required this.currentUserId,
  });

  @override
  _MealDetailScreenState createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  bool isFavorited = false;
  bool animationsOff = false;
  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
    _loadAnimationsSetting();
  }

  void _loadAnimationsSetting() async {
    final settings = await DatabaseHelper().getSettings();
    setState(() {
      animationsOff = settings['animationsOff'] == true;
    });
  }

  void _checkIfFavorited() async {
    if (widget.currentUserId != null) {
      bool favorited = await DatabaseHelper().isMealFavorited(
        widget.currentUserId!,
        widget.meal.id,
      );
      setState(() {
        isFavorited = favorited;
      });
    }
  }

  void _toggleFavorite() async {
    if (widget.currentUserId == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SignInScreen(
            onSignedIn: () {
              setState(() {
                _checkIfFavorited();
              });
            },
          ),
        ),
      );
      return;
    }

    if (isFavorited) {
      await DatabaseHelper().removeFavorite(
        widget.currentUserId!,
        widget.meal.id,
      );
      setState(() {
        isFavorited = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed from favorites')),
      );
    } else {
      await DatabaseHelper().insertFavorite({
        'userId': widget.currentUserId!,
        'mealId': widget.meal.id,
        'mealName': widget.meal.name,
        'category': widget.meal.category,
        'mealThumbnail': widget.meal.thumbnail,
      });
      setState(() {
        isFavorited = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to favorites')),
      );
    }
  }

  void _launchYoutubeVideo(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the video.'),
        ),
      );
    }
  }

  void _addToMealPlan() async {
    if (widget.currentUserId == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SignInScreen(
            onSignedIn: () {
              setState(() {});
            },
          ),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AddToMealPlanDialog(
          meal: widget.meal,
          currentUserId: widget.currentUserId!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.white;
    final textColor = Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 1,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return MarqueeIfNeeded(
              text: widget.meal.name,
              style: TextStyle(color: textColor, fontSize: 20),
              maxWidth: constraints.maxWidth - 80,
              animationsOff: animationsOff,
            );
          },
        ),
        centerTitle: true,
      ),
      body: Container(
        color: backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(0.0),
              child: Image.network(
                widget.meal.thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey,
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _toggleFavorite,
                    child: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                      size: 24.0,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _addToMealPlan,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.black),
                          ),
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.add,
                            color: Colors.black,
                            size: 24.0,
                          ),
                        ),
                      ),
                      SizedBox(width: 16.0),
                      GestureDetector(
                        onTap: () {
                          _launchYoutubeVideo(context, widget.meal.youtubeLink);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.black),
                          ),
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.black,
                            size: 24.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingredients',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                    SizedBox(height: 8.0),
                    ...widget.meal.ingredients.map((ingredient) => Text(
                          '• $ingredient',
                          style: TextStyle(fontSize: 16, color: textColor),
                        )),
                    SizedBox(height: 16.0),
                    Text(
                      'Instructions',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      widget.meal.instructions,
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarqueeIfNeeded extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double maxWidth;
  final bool animationsOff;
  const MarqueeIfNeeded({
    Key? key,
    required this.text,
    required this.style,
    required this.maxWidth,
    required this.animationsOff,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (animationsOff) {
      return Container(
        width: maxWidth,
        child: Text(
          text,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      if (text.length > 32) {
        return SizedBox(
          height: style.fontSize! + 4,
          child: Marquee(
            text: text,
            style: style,
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            blankSpace: 50.0,
            velocity: 30.0,
            pauseAfterRound: Duration(seconds: 1),
            startPadding: 0.0,
            accelerationDuration: Duration(seconds: 1),
            accelerationCurve: Curves.easeIn,
            decelerationDuration: Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
            fadingEdgeStartFraction: 0.1,
            fadingEdgeEndFraction: 0.1,
          ),
        );
      } else {
        return Text(
          text,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        );
      }
    }
  }
}

class AddToMealPlanDialog extends StatefulWidget {
  final Meal meal;
  final int currentUserId;

  AddToMealPlanDialog({required this.meal, required this.currentUserId});

  @override
  _AddToMealPlanDialogState createState() => _AddToMealPlanDialogState();
}

class _AddToMealPlanDialogState extends State<AddToMealPlanDialog> {
  DateTime selectedDate = DateTime.now();
  String selectedMealType = 'breakfast';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Add to Meal Plan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Select Date'),
            subtitle: Text('${DateFormat.yMd().format(selectedDate)}'),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(Duration(days: 1)),
                lastDate: DateTime.now().add(Duration(days: 30)),
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.black,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                      dialogBackgroundColor: Colors.white,
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                });
              }
            },
          ),
          DropdownButton<String>(
            value: selectedMealType,
            isExpanded: true,
            items: <String>['Breakfast', 'Lunch', 'Dinner'].map((String value) {
              return DropdownMenuItem<String>(
                value: value.toLowerCase(),
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedMealType = newValue!;
              });
            },
            dropdownColor: Colors.white,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
            iconEnabledColor: Colors.black,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            String dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
            Map<String, dynamic> mealPlan = {
              'userId': widget.currentUserId,
              'date': dateString,
              'mealType': selectedMealType,
              'mealId': widget.meal.id,
              'mealName': widget.meal.name,
              'mealThumbnail': widget.meal.thumbnail,
              'description': '',
            };

            final dbHelper = DatabaseHelper();
            Map<String, dynamic>? existingMealPlan = await dbHelper.getMealPlan(
              widget.currentUserId,
              dateString,
              selectedMealType,
            );

            if (existingMealPlan != null) {
              await dbHelper.updateMealPlan(
                widget.currentUserId,
                dateString,
                selectedMealType,
                mealPlan,
              );
            } else {
              await dbHelper.insertMealPlan(mealPlan);
            }

            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added to meal plan'),
              ),
            );
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
