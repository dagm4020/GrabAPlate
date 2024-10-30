import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dart:async';

enum MeasurementType { Volume, Weight, Count }

class FoodItem {
  int? id;   final String name;
  final MeasurementType measurementType;
  final String? unitAbbreviation;
  final double? quantity;
  bool isChecked;
  Timer? deletionTimer;

  FoodItem({
    this.id,
    required this.name,
    required this.measurementType,
    this.unitAbbreviation,
    this.quantity,
    this.isChecked = false,
    this.deletionTimer,
  });

    Map<String, dynamic> toMap(int categoryId) {
    return {
      'id': id,
      'name': name,
      'measurementType': measurementType.toString().split('.').last,
      'unitAbbreviation': unitAbbreviation,
      'quantity': quantity,
      'isChecked': isChecked ? 1 : 0,
      'categoryId': categoryId,
    };
  }

    factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      measurementType: MeasurementType.values.firstWhere(
          (e) => e.toString() == 'MeasurementType.${map['measurementType']}'),
      unitAbbreviation: map['unitAbbreviation'],
      quantity: map['quantity'],
      isChecked: map['isChecked'] == 1,
    );
  }
}

class Category {
  int? id;   final String name;
  final List<FoodItem> items;

  Category({
    this.id,
    required this.name,
    List<FoodItem>? items,
  }) : items = items ?? [];

    Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

    factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
    );
  }
}

class GroceryList extends StatefulWidget {
  @override
  _GroceryListState createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  bool _darkModeEnabled = false;

    final GlobalKey _plusButtonKey = GlobalKey();

    OverlayEntry? _overlayEntry;

    List<Category> _categories = [];

    final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _loadCategoriesAndItems();
  }

    Future<void> _loadDarkModePreference() async {
    final settings = await _dbHelper.getSettings();
    setState(() {
      _darkModeEnabled = settings['darkMode'] ?? false;
    });
  }

    Future<void> _loadCategoriesAndItems() async {
    final categoriesData = await _dbHelper.queryAllCategories();
    List<Category> categories = [];

    for (var categoryMap in categoriesData) {
      Category category = Category.fromMap(categoryMap);

            final itemsData =
          await _dbHelper.queryFoodItemsByCategory(category.id!);
      category.items
          .addAll(itemsData.map((itemMap) => FoodItem.fromMap(itemMap)));

      categories.add(category);
    }

    setState(() {
      _categories = categories;
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

    void _showDropdown() {
        if (_overlayEntry != null) return;

    final RenderBox renderBox =
        _plusButtonKey.currentContext!.findRenderObject() as RenderBox;
    final Size buttonSize = renderBox.size;
    final Offset buttonPosition = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeOverlay();
        },
        child: Stack(
          children: [
            Positioned(
              top: buttonPosition.dy + buttonSize.height + 5.0,
                            right: MediaQuery.of(context).size.width -
                  (buttonPosition.dx + buttonSize.width),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200.0,                   decoration: BoxDecoration(
                    color: Colors.white,                     borderRadius: BorderRadius.circular(10.0),                     boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 300.0,                     ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDropdownButton('Produce'),
                          _buildDropdownButton('Meats'),
                          _buildDropdownButton('Seafood'),
                          _buildDropdownButton('Dairy'),
                          _buildDropdownButton('Grains'),
                          _buildDropdownButton('Legumes'),
                          _buildDropdownButton('Nuts and Seeds'),
                          _buildDropdownButton('Fats and Oils'),
                          _buildDropdownButton('Herbs and Spices'),
                          _buildDropdownButton('Sweets and Snacks'),
                          _buildDropdownButton('Custom'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context)!.insert(_overlayEntry!);
  }

    void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

    Widget _buildDropdownButton(String title) {
    return InkWell(
      onTap: () {
        _handleDropdownSelection(title);
        _removeOverlay();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black,             fontSize: 16.0,
          ),
        ),
      ),
    );
  }

    void _handleDropdownSelection(String selection) {
    if (selection == 'Custom') {
      _showCustomCategoryDialog();
    } else {
      _addCategory(selection);
    }
  }

    void _showCustomCategoryDialog() {
    final TextEditingController _customCategoryController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              Colors.white,           title: Text('Enter Custom Category'),
          content: TextField(
            controller: _customCategoryController,
            decoration: InputDecoration(
              hintText: 'Enter category name',
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                String customCategory =
                    _customCategoryController.text.trim();
                if (customCategory.isNotEmpty) {
                  _addCategory(customCategory);
                  Navigator.of(context).pop(); 
                                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('$customCategory added as a custom category'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a category name'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

    void _addCategory(String categoryName) async {
        if (_categories.any((category) => category.name == categoryName)) {
            ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$categoryName already exists.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

        int categoryId = await _dbHelper.insertCategory({'name': categoryName});

    setState(() {
      _categories.add(Category(id: categoryId, name: categoryName));
    });
  }

    void _onAddButtonPressed() {
    _showDropdown();
  }

    void _showAddFoodItemDialog(Category category) {
    final TextEditingController _foodNameController = TextEditingController();
    final TextEditingController _quantityController = TextEditingController();
    MeasurementType? _selectedMeasurementType;
    String? _selectedUnit;
    String? _measurementAbbreviation;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,           title: Text('Add Food Item'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
                            List<String> volumeOptions = [
                'Tablespoon (tbsp)',
                'Cup (c)',
                'Pint (pt)',
                'Quart (qt)',
                'Gallon (gal)'
              ];
              List<String> weightOptions = ['Ounce (oz)', 'Pound (lb)'];
              
              List<String> currentOptions = [];

              if (_selectedMeasurementType == MeasurementType.Volume) {
                currentOptions = volumeOptions;
              } else if (_selectedMeasurementType == MeasurementType.Weight) {
                currentOptions = weightOptions;
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _foodNameController,
                      decoration: InputDecoration(
                        labelText: 'Food Name',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<MeasurementType>(
                      decoration: InputDecoration(
                        labelText: 'Measurement Type',
                        filled: true,
                        fillColor: Colors.white,                       ),
                      dropdownColor: Colors.white,                       value: _selectedMeasurementType,
                      items: MeasurementType.values.map((MeasurementType type) {
                        return DropdownMenuItem<MeasurementType>(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (MeasurementType? newValue) {
                        setState(() {
                          _selectedMeasurementType = newValue;
                          _selectedUnit = null;                           _measurementAbbreviation = null;
                        });
                      },
                    ),
                    if (_selectedMeasurementType != null &&
                        _selectedMeasurementType != MeasurementType.Count)
                      Column(
                        children: [
                          SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Select Unit',
                              filled: true,
                              fillColor: Colors.white,                             ),
                            dropdownColor: Colors.white,                             value: _selectedUnit,
                            items: currentOptions.map((String unit) {
                              String abbreviation = unit.contains('(')
                                  ? unit
                                      .split('(')
                                      .last
                                      .replaceAll(')', '')
                                      .trim()
                                  : unit.trim();
                              return DropdownMenuItem<String>(
                                value: abbreviation,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedUnit = newValue;
                                                                _measurementAbbreviation = newValue;
                              });
                            },
                          ),
                          if (_measurementAbbreviation != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(
                                'Selected Unit: $_measurementAbbreviation',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black54),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                String foodName = _foodNameController.text.trim();
                String quantityText = _quantityController.text.trim();
                double? quantity = double.tryParse(quantityText);

                if (foodName.isNotEmpty &&
                    _selectedMeasurementType != null &&
                    quantity != null) {
                  if (_selectedMeasurementType != MeasurementType.Count &&
                      _measurementAbbreviation == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please select a unit'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  if (_selectedMeasurementType == MeasurementType.Count) {
                    _measurementAbbreviation = 'pcs';
                  }

                                    FoodItem newItem = FoodItem(
                    name: foodName,
                    measurementType: _selectedMeasurementType!,
                    unitAbbreviation: _measurementAbbreviation,
                    quantity: quantity,
                  );

                                    int itemId = await _dbHelper.insertFoodItem(
                      newItem.toMap(category.id!));

                  newItem.id = itemId;

                  setState(() {
                    category.items.add(newItem);
                  });
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$foodName added to ${category.name}'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Please enter food name, quantity, and measurement type'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

    void _deleteCategory(Category category) async {
    await _dbHelper.deleteCategory(category.id!);

    setState(() {
      _categories.remove(category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _darkModeEnabled
          ? Colors.black
          : Colors.white,       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: [
                                Icon(
                  Icons.shopping_cart,
                  color: _darkModeEnabled ? Colors.white : Colors.black,
                  size: 24.0,
                ),
                SizedBox(width: 8.0), 
                                Text(
                  'Shopping List',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _darkModeEnabled ? Colors.white : Colors.black,
                  ),
                ),
                Spacer(), 
                                GestureDetector(
                  key: _plusButtonKey,                   onTap: _onAddButtonPressed,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.0),
                      color: Colors.white,
                    ),
                    padding:
                        EdgeInsets.all(6.0),                     child: Icon(
                      Icons.add,
                      color: Colors.black,
                      size: 16.0,                       semanticLabel: 'Add new item',                     ),
                  ),
                ),
              ],
            ),
          ),

                    Divider(
            thickness: 1.0,
            color: _darkModeEnabled ? Colors.white54 : Colors.grey,
            indent: 0,             endIndent: 0,           ),

                    Expanded(
            child: Container(
              margin: EdgeInsets.all(20.0),               decoration: BoxDecoration(
                color: Colors.white,                 borderRadius: BorderRadius.circular(20.0),                 border: Border.all(
                  color: Colors.black,                   width: 1.0,                 ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,                     blurRadius: 10.0,                     offset: Offset(0, 4),                   ),
                ],
              ),
              child: _categories.isEmpty
                  ? Center(
                      child: Text(
                        'Your pantry must be full right now...',
                        style: TextStyle(
                          fontSize: 16.5,
                          color: _darkModeEnabled
                              ? Colors.black87
                              : Colors.black87,                         ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        return CategoryRow(
                          category: _categories[index],
                          darkModeEnabled: _darkModeEnabled,
                          onAddPressed: () {
                            _showAddFoodItemDialog(_categories[index]);
                          },
                          onDeleteCategory: () {
                            _deleteCategory(_categories[index]);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryRow extends StatefulWidget {
  final Category category;
  final bool darkModeEnabled;
  final VoidCallback onAddPressed;
  final VoidCallback onDeleteCategory;

  CategoryRow({
    required this.category,
    required this.darkModeEnabled,
    required this.onAddPressed,
    required this.onDeleteCategory,
  });

  @override
  _CategoryRowState createState() => _CategoryRowState();
}

class _CategoryRowState extends State<CategoryRow>
    with SingleTickerProviderStateMixin {
  bool _isDeleteMode = false;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

    final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-0.6, 0.0),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
      if (_isDeleteMode) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _confirmDeleteCategory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Category'),
          backgroundColor: Colors.white,
          content: Text(
              'Are you sure you want to delete "${widget.category.name}" and all its items?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDeleteCategory();
              },
            ),
          ],
        );
      },
    );
  }

    void _deleteFoodItem(FoodItem item, int index) async {
    await _dbHelper.deleteFoodItem(item.id!);

    setState(() {
      widget.category.items.removeAt(index);
    });
  }

    void _updateFoodItem(FoodItem item) async {
    await _dbHelper.updateFoodItem(item.id!, {
      'isChecked': item.isChecked ? 1 : 0,
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
                Container(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,             borderRadius:
                BorderRadius.circular(10.0),             boxShadow: [
              BoxShadow(
                color: Colors.black12,                 blurRadius: 5.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
                            Expanded(
                child: Text(
                  widget.category.name,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
                            Container(
                width: 96,                 child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                                        SlideTransition(
                      position: _offsetAnimation,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                                                    IconButton(
                            icon: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 24.0,
                              semanticLabel:
                                  'Add items to ${widget.category.name}',
                            ),
                            onPressed: widget.onAddPressed,
                          ),
                                                    IconButton(
                            icon: AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return RotationTransition(
                                  turns: child.key == ValueKey('arrow_forward')
                                      ? Tween<double>(begin: 1, end: 0)
                                          .animate(animation)
                                      : Tween<double>(begin: 0, end: 1)
                                          .animate(animation),
                                  child: child,
                                );
                              },
                              child: Icon(
                                _isDeleteMode
                                    ? Icons.arrow_forward_ios
                                    : Icons.arrow_back_ios,
                                key: ValueKey(_isDeleteMode
                                    ? 'arrow_forward'
                                    : 'arrow_back'),
                                color: Colors.black,
                                size: 16.0,                                 semanticLabel: _isDeleteMode
                                    ? 'Exit delete mode'
                                    : 'Enter delete mode',
                              ),
                            ),
                            onPressed: _toggleDeleteMode,
                          ),
                        ],
                      ),
                    ),
                                        IgnorePointer(
                      ignoring: !_isDeleteMode,
                      child: FadeTransition(
                        opacity: _opacityAnimation,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 24.0,
                              semanticLabel: 'Delete category',
                            ),
                            onPressed:
                                _isDeleteMode ? _confirmDeleteCategory : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
                Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],             borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10.0),
              bottomRight: Radius.circular(10.0),
            ),
          ),
          child: Column(
            children: widget.category.items.asMap().entries.map((entry) {
              int index = entry.key;
              FoodItem foodItem = entry.value;
              return FoodItemRow(
                foodItem: foodItem,
                onItemChanged: () {
                  setState(() {});                   _updateFoodItem(foodItem);
                },
                onDelete: () {
                  _deleteFoodItem(foodItem, index);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class FoodItemRow extends StatefulWidget {
  final FoodItem foodItem;
  final VoidCallback onItemChanged;
  final VoidCallback onDelete; 
  FoodItemRow({
    required this.foodItem,
    required this.onItemChanged,
    required this.onDelete,
  });

  @override
  _FoodItemRowState createState() => _FoodItemRowState();
}

class _FoodItemRowState extends State<FoodItemRow> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();     super.dispose();
  }

  void _handleCheckboxChange(bool? newValue) {
    setState(() {
      widget.foodItem.isChecked = newValue ?? false;

      widget.onItemChanged(); 
      if (widget.foodItem.isChecked) {
                _timer = Timer(Duration(seconds: 5), () {
                    if (widget.foodItem.isChecked) {
            widget.onDelete();           }
        });
      } else {
                _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Transform.scale(
        scale: 1.2,
        child: Checkbox(
          value: widget.foodItem.isChecked,
          onChanged: _handleCheckboxChange,
          shape: CircleBorder(),
        ),
      ),
      title: Text(
        widget.foodItem.name,
        style: TextStyle(
          decoration:
              widget.foodItem.isChecked ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: Text(
        widget.foodItem.quantity != null
            ? '${widget.foodItem.quantity} ${widget.foodItem.unitAbbreviation ?? ''}'
            : '',
        style: TextStyle(
          decoration:
              widget.foodItem.isChecked ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}
