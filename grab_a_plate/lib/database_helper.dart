import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    Directory dataDirectory = await getApplicationDocumentsDirectory();
    print('DB Location: ${dataDirectory.path}');
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_settings.db');
    return await openDatabase(
      path,
      version: 4,       onCreate: (db, version) async {
                await db.execute('''
          CREATE TABLE SettingsPreference (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            darkMode INTEGER NOT NULL,
            animationsOff INTEGER NOT NULL,
            isLoggedIn INTEGER NOT NULL DEFAULT 0,
            currentUserId INTEGER
          )
        ''');

                await db.insert('SettingsPreference', {
          'darkMode': 0,
          'animationsOff': 0,
          'isLoggedIn': 0,
          'currentUserId': null,
        });

                await db.execute('''
          CREATE TABLE Users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            firstName TEXT NOT NULL,
            lastName TEXT NOT NULL,
            age INTEGER NOT NULL,
            email TEXT NOT NULL UNIQUE,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          )
        ''');

                await db.execute('''
          CREATE TABLE Categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');

                await db.execute('''
          CREATE TABLE FoodItems (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            measurementType TEXT NOT NULL,
            unitAbbreviation TEXT,
            quantity REAL,
            isChecked INTEGER NOT NULL,
            categoryId INTEGER NOT NULL,
            FOREIGN KEY (categoryId) REFERENCES Categories(id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
                    await db.execute('''
            ALTER TABLE SettingsPreference ADD COLUMN isLoggedIn INTEGER NOT NULL DEFAULT 0
          ''');
          await db.execute('''
            ALTER TABLE SettingsPreference ADD COLUMN currentUserId INTEGER
          ''');
        }

        if (oldVersion < 4) {
                    await db.execute('''
            CREATE TABLE Users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              firstName TEXT NOT NULL,
              lastName TEXT NOT NULL,
              age INTEGER NOT NULL,
              email TEXT NOT NULL UNIQUE,
              username TEXT NOT NULL UNIQUE,
              password TEXT NOT NULL
            )
          ''');
        }

              },
    );
  }

    Future<Map<String, dynamic>> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> settings =
        await db.query('SettingsPreference', where: 'id = 1');

    if (settings.isNotEmpty) {
      return {
        'darkMode': settings[0]['darkMode'] == 1,
        'animationsOff': settings[0]['animationsOff'] == 1,
        'isLoggedIn': settings[0]['isLoggedIn'] == 1,
        'currentUserId': settings[0]['currentUserId'],
      };
    } else {
      return {
        'darkMode': false,
        'animationsOff': false,
        'isLoggedIn': false,
        'currentUserId': null,
      };
    }
  }

    Future<void> updateSettings({
    bool? darkMode,
    bool? animationsOff,
    bool? isLoggedIn,
    int? currentUserId,
  }) async {
    final db = await database;
    Map<String, dynamic> updatedFields = {};

    if (darkMode != null) {
      updatedFields['darkMode'] = darkMode ? 1 : 0;
    }
    if (animationsOff != null) {
      updatedFields['animationsOff'] = animationsOff ? 1 : 0;
    }
    if (isLoggedIn != null) {
      updatedFields['isLoggedIn'] = isLoggedIn ? 1 : 0;
    }
    if (currentUserId != null) {
      updatedFields['currentUserId'] = currentUserId;
    } else if (currentUserId == null && isLoggedIn == false) {
            updatedFields['currentUserId'] = null;
    }

    await db.update(
      'SettingsPreference',
      updatedFields,
      where: 'id = ?',
      whereArgs: [1],     );
  }

    Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('Users', row);
  }

  Future<Map<String, dynamic>?> getUser(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> users = await db.query(
      'Users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (users.isNotEmpty) {
      return users.first;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> users = await db.query(
      'Users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (users.isNotEmpty) {
      return users.first;
    } else {
      return null;
    }
  }

    Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('Categories', row);
  }

  Future<List<Map<String, dynamic>>> queryAllCategories() async {
    final db = await database;
    return await db.query('Categories');
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
        return await db.delete('Categories', where: 'id = ?', whereArgs: [id]);
  }

    Future<int> insertFoodItem(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('FoodItems', row);
  }

  Future<List<Map<String, dynamic>>> queryFoodItemsByCategory(int categoryId) async {
    final db = await database;
    return await db.query('FoodItems', where: 'categoryId = ?', whereArgs: [categoryId]);
  }

  Future<int> updateFoodItem(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('FoodItems', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteFoodItem(int id) async {
    final db = await database;
    return await db.delete('FoodItems', where: 'id = ?', whereArgs: [id]);
  }
}
