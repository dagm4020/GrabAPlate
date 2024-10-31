import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/meal.dart';

class MealDetailScreen extends StatelessWidget {
  final Meal meal;

  MealDetailScreen({required this.meal});

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

  @override
  Widget build(BuildContext context) {
        final backgroundColor = Colors.white;
    final textColor = Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(meal.name),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(color: textColor, fontSize: 20),
        elevation: 1,       ),
      body: Container(
        color: backgroundColor,         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        ClipRRect(
              borderRadius: BorderRadius.circular(0.0),
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
                        Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
              child: GestureDetector(
                onTap: () {
                  _launchYoutubeVideo(context, meal.youtubeLink);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,                     shape: BoxShape.rectangle,
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
                    ...meal.ingredients.map((ingredient) => Text(
                          'o $ingredient',
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
                      meal.instructions,
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
