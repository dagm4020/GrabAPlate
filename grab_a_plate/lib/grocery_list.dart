import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dart:async';

class GroceryList extends StatefulWidget {
  @override
  _GroceryListState createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  bool _darkModeEnabled = false;
  List<String> categories = [];
  List<bool> _expandedStates = [];
  Map<int, List<Map<String, dynamic>>> foodItems = {};
  Map<String, int> categoryIds = {};
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPrintingDatabase() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _printDatabaseContents();
    });
  }

  Future<void> _printDatabaseContents() async {
    try {
      final dbHelper = DatabaseHelper();
      final categories = await dbHelper.getCategories();
      final foods = await dbHelper.getAllFoods();

      if (categories.isNotEmpty) {
        print("Categories:");
        for (var category in categories) {
          print(category);
        }
      } else {
        print("No categories found.");
      }

      if (foods.isNotEmpty) {
        print("Foods:");
        for (var food in foods) {
          print(food);
        }
      } else {
        print("No foods found.");
      }
    } catch (e) {
      print("Error while printing database contents: $e");
    }
  }

  void _clearDatabaseOnStart() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteAllData();
  }

  @override
  void initState() {
    super.initState();
    /*_clearDatabaseOnStart();     */
    _loadDarkModePreference();
    _loadCategoriesAndFoods();
    _startPrintingDatabase();
    _loadCategoriesAndFoods();
  }

  Future<void> _loadDarkModePreference() async {
    final settings = await DatabaseHelper().getSettings();
    setState(() {
      _darkModeEnabled = settings['darkMode'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _darkModeEnabled ? Colors.black : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: _darkModeEnabled ? Colors.white : Colors.black,
                ),
                SizedBox(width: 8.0),
                Text(
                  'Shopping List',
                  style: TextStyle(
                    fontSize: 24,
                    color: _darkModeEnabled ? Colors.white : Colors.black,
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    _showPopupMenu(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.0),
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.all(3.0),
                    child: Icon(
                      Icons.add,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _buildCategorySection(categories[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCategoriesAndFoods() async {
    final dbHelper = DatabaseHelper();

    final categoriesData = await dbHelper.getCategories();

    setState(() {
      categories =
          categoriesData.map((category) => category['name'] as String).toList();
      _expandedStates = List<bool>.filled(categories.length, false);
    });

    final Map<int, List<Map<String, dynamic>>> tempFoodItems = {};
    for (var category in categoriesData) {
      final categoryId = category['id'];
      final foodsData = await dbHelper.getFoodsByCategory(categoryId);
      tempFoodItems[categoryId] = foodsData;
    }

    setState(() {
      foodItems = tempFoodItems;
    });
  }

  void _showPopupMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset buttonPosition = button.localToGlobal(Offset.zero);

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx + 50,
        buttonPosition.dy + 55,
        buttonPosition.dx,
        buttonPosition.dy,
      ),
      items: [
        _buildPopupMenuItem('Produce', 'Fruits and vegetables.'),
        _buildPopupMenuItem('Meats', 'Beef, pork, lamb, poultry.'),
        _buildPopupMenuItem('Seafood', 'Fish and shellfish.'),
        _buildPopupMenuItem('Dairy', 'Milk, cheese, yogurt.'),
        _buildPopupMenuItem('Grains', 'Rice, wheat, oats, quinoa.'),
        _buildPopupMenuItem('Legumes', 'Beans, lentils, peas.'),
        _buildPopupMenuItem(
            'Nuts and Seeds', 'Almonds, walnuts, sunflower seeds.'),
        _buildPopupMenuItem('Fats and Oils', 'Olive oil, butter, avocado.'),
        _buildPopupMenuItem(
            'Herbs and Spices', 'Fresh and dried herbs, spices for flavoring.'),
        _buildPopupMenuItem('Sweets and Snacks', 'Candies, cookies, chips.'),
        _buildPopupMenuItem('Custom', 'Your own custom items.'),
      ],
      elevation: 8.0,
      color: Colors.white,
    ).then((selectedItem) async {
      if (selectedItem != null && selectedItem == 'Custom') {
        _showCustomCategoryDialog(context);
      } else if (selectedItem != null && !categories.contains(selectedItem)) {
        final dbHelper = DatabaseHelper();
        int categoryId =
            await dbHelper.addCategory(selectedItem, categories.length);

        setState(() {
          categories.add(selectedItem);
          categoryIds[selectedItem] = categoryId;
          _expandedStates.add(false);
        });
      } else if (selectedItem != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$selectedItem is already created'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showCustomCategoryDialog(BuildContext context) {
    final TextEditingController customCategoryController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Enter Custom Category'),
          content: TextField(
            controller: customCategoryController,
            decoration: InputDecoration(hintText: 'Enter category name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String customCategory = customCategoryController.text.trim();
                if (customCategory.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You need to enter at least one character'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (categories.contains(customCategory)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$customCategory already exists'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  setState(() {
                    categories.add(customCategory);
                    _expandedStates.add(false);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String title, String description) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
          ),
          Tooltip(
            message: description,
            child: Icon(
              Icons.add,
              size: 20.0,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String category, int index) {
    if (index < 0 || index >= categories.length) {
      return SizedBox.shrink();
    }

    final categoryId = categoryIds[category];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index == 0) Divider(thickness: 2, color: Colors.black),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  if (categoryId != null) {
                    _showAddFoodDialog(context, categoryId);
                  }
                },
                color: Colors.black,
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                child: Transform.rotate(
                  angle: _expandedStates.isNotEmpty &&
                          index < _expandedStates.length
                      ? (_expandedStates[index] ? 0 : 3.14)
                      : 0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: () {
                      setState(() {
                        if (_expandedStates.isNotEmpty &&
                            index < _expandedStates.length) {
                          _expandedStates[index] = !_expandedStates[index];
                        }
                      });
                    },
                    color: Colors.black,
                  ),
                ),
              ),
              if (_expandedStates.isNotEmpty &&
                  index < _expandedStates.length &&
                  _expandedStates[index])
                Container(
                  color: Colors.grey[300],
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      if (categoryId != null) {
                        _showConfirmationDialog(categoryId, index);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Unable to delete the category.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
        if (_expandedStates.isNotEmpty &&
            index < _expandedStates.length &&
            _expandedStates[index])
          SizedBox(height: 5),
        if (categoryId != null && foodItems.containsKey(categoryId))
          ...foodItems[categoryId]!.map((food) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
              child: Row(
                children: [
                  Checkbox(
                    value: false,
                    onChanged: (value) {},
                  ),
                  Text('${food['name']} (${food['measurement']})'),
                ],
              ),
            );
          }).toList(),
        Divider(thickness: 2, color: Colors.black),
      ],
    );
  }

  void _showAddFoodDialog(BuildContext context, int? categoryId) {
    if (categoryId == null) {
      return;
    }

    final TextEditingController foodController = TextEditingController();
    String? selectedMeasurement;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Add Food to Category $categoryId'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: foodController,
                decoration: InputDecoration(hintText: 'Enter food name'),
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
                hint: Text(selectedMeasurement ?? 'Select measurement'),
                value: selectedMeasurement,
                dropdownColor: Colors.white,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    selectedMeasurement = newValue;
                  }
                },
                items: <String>[
                  'Cup',
                  'Pt',
                  'Qt',
                  'Gal',
                  'Lb',
                  'Oz',
                  'G',
                  'Pcs',
                  'Tbsp',
                  'Serv'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
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
            TextButton(
              onPressed: () async {
                String foodName = foodController.text.trim();
                if (foodName.isNotEmpty && selectedMeasurement != null) {
                  final dbHelper = DatabaseHelper();
                  await dbHelper.addFood(
                    foodName,
                    selectedMeasurement!,
                    categoryId,
                  );
                  Navigator.of(context).pop();
                  setState(() {
                    _loadCategoriesAndFoods();
                  });
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showMeasurementOptionsDialog(BuildContext context,
      String measurementType, TextEditingController foodController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Select $measurementType Measurement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (measurementType == 'Volume') ...[
                _buildMeasurementOption(context, 'Cup', foodController),
                _buildMeasurementOption(context, 'Pt', foodController),
                _buildMeasurementOption(context, 'Qt', foodController),
                _buildMeasurementOption(context, 'Gal', foodController),
              ] else if (measurementType == 'Weight') ...[
                _buildMeasurementOption(context, 'Lb', foodController),
                _buildMeasurementOption(context, 'Oz', foodController),
                _buildMeasurementOption(context, 'G', foodController),
              ] else if (measurementType == 'Count') ...[
                _buildMeasurementOption(context, 'Pcs', foodController),
              ] else if (measurementType == 'Serving Size') ...[
                _buildMeasurementOption(context, 'Tbsp', foodController),
                _buildMeasurementOption(context, 'Serv', foodController),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMeasurementOption(BuildContext context, String measurement,
      TextEditingController foodController) {
    return ListTile(
      title: Text(measurement),
      onTap: () {
        Navigator.of(context).pop();
        _showAddFoodDialogWithMeasurement(context, measurement, foodController);
      },
    );
  }

  void _showAddFoodDialogWithMeasurement(BuildContext context,
      String measurement, TextEditingController foodController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Add Food'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: foodController,
                decoration: InputDecoration(hintText: 'Enter food name'),
              ),
              SizedBox(height: 10),
              Text('Measurement: $measurement'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String foodName = foodController.text.trim();
                if (foodName.isNotEmpty) {
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showVolumeOptionsDialog(
      BuildContext context, TextEditingController foodController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Select Volume Measurement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMeasurementOption(context, 'Cup', foodController),
              _buildMeasurementOption(context, 'Pt', foodController),
              _buildMeasurementOption(context, 'Qt', foodController),
              _buildMeasurementOption(context, 'Gal', foodController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showWeightOptionsDialog(
      BuildContext context, TextEditingController foodController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Select Weight Measurement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMeasurementOption(context, 'Lb', foodController),
              _buildMeasurementOption(context, 'Oz', foodController),
              _buildMeasurementOption(context, 'G', foodController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showServingSizeOptionsDialog(
      BuildContext context, TextEditingController foodController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Select Serving Size Measurement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMeasurementOption(context, 'Tbsp', foodController),
              _buildMeasurementOption(context, 'Serv', foodController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _addNewCategory(String categoryName) async {
    final dbHelper = DatabaseHelper();
    int categoryId =
        await dbHelper.addCategory(categoryName, categories.length);
    setState(() {
      categories.add(categoryName);
      categoryIds[categoryName] = categoryId;
    });

    await _loadCategoriesAndFoods();
  }

  void _showConfirmationDialog(int categoryId, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this category?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final dbHelper = DatabaseHelper();
                await dbHelper.deleteCategory(categoryId);
                Navigator.of(context).pop();
                await _loadCategoriesAndFoods();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
