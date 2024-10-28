import 'package:flutter/material.dart';
import 'models/meal.dart';

class MealDetailScreen extends StatelessWidget {
  final Meal meal;

  MealDetailScreen({required this.meal});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(meal.name),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.network(
                meal.thumbnail,
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
            SizedBox(height: 16.0),
            Text(
              'Ingredients',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            SizedBox(height: 8.0),
            ...meal.ingredients.map((ingredient) => Text(
                  '- $ingredient',
                  style: TextStyle(fontSize: 16, color: textColor),
                )),
          ],
        ),
      ),
    );
  }
}
