import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'settings.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE SettingsPreference (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          darkMode INTEGER NOT NULL,
          animationsOff INTEGER NOT NULL
        )
      ''');

        await db.insert('SettingsPreference', {
          'darkMode': 0,
          'animationsOff': 0,
        });

        await db.execute('''
        CREATE TABLE Categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          displayOrder INTEGER NOT NULL
        )
      ''');

        await db.execute('''
        CREATE TABLE Foods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          measurement TEXT NOT NULL,
          catId INTEGER NOT NULL,
          FOREIGN KEY (catId) REFERENCES Categories(id) ON DELETE CASCADE
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''
          CREATE TABLE IF NOT EXISTS SettingsPreference (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            darkMode INTEGER NOT NULL,
            animationsOff INTEGER NOT NULL
          )
        ''');

          await db.insert(
            'SettingsPreference',
            {'darkMode': 0, 'animationsOff': 0},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          await db.execute('''
          CREATE TABLE IF NOT EXISTS Categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            displayOrder INTEGER NOT NULL
          )
        ''');

          await db.execute('''
          CREATE TABLE IF NOT EXISTS Foods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            measurement TEXT NOT NULL,
            catId INTEGER NOT NULL,
            FOREIGN KEY (catId) REFERENCES Categories(id) ON DELETE CASCADE
          )
        ''');
        }
      },
    );
  }

  Future<int> addCategory(String name, int displayOrder) async {
    final db = await database;

    await resetAutoIncrementIfEmpty('Categories');

    int id = await db.insert('Categories', {
      'name': name,
      'displayOrder': displayOrder,
    });

    return id;
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return await db.query('Categories', orderBy: 'displayOrder ASC');
  }

  Future<int> addFood(String name, String measurement, int categoryId) async {
    final db = await database;
    return await db.insert(
      'Foods',
      {
        'name': name,
        'measurement': measurement,
        'catId': categoryId,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getFoodsByCategory(int categoryId) async {
    final db = await database;
    return await db.query(
      'Foods',
      where: 'catId = ?',
      whereArgs: [categoryId],
    );
  }

// Method to delete a category and shift rows up
  Future<void> deleteCategoryAndShift(int categoryId) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'Categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      await txn.rawUpdate('''
      UPDATE Categories
      SET id = id - 1
      WHERE id > ?
    ''', [categoryId]);

      await txn.rawUpdate(
          'UPDATE sqlite_sequence SET seq = (SELECT MAX(id) FROM Categories) WHERE name = "Categories"');

      await txn.rawUpdate('''
      UPDATE Foods
      SET categoryId = categoryId - 1
      WHERE categoryId > ?
    ''', [categoryId]);
    });
  }

  Future<void> deleteFoodAndShift(int foodId) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'Foods',
        where: 'id = ?',
        whereArgs: [foodId],
      );

      await txn.rawUpdate('''
      UPDATE Foods
      SET id = id - 1
      WHERE id > ?
    ''', [foodId]);

      await txn.rawUpdate(
          'UPDATE sqlite_sequence SET seq = (SELECT MAX(id) FROM Foods) WHERE name = "Foods"');
    });
  }

  Future<void> deleteCategory(int categoryId) async {
    final db = await database;

    await db.delete(
      'Foods',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );

    await db.delete(
      'Categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<void> resetAutoIncrementIfEmpty(String tableName) async {
    final db = await database;

    List<Map<String, dynamic>> rows = await db.query(tableName);
    if (rows.isEmpty) {
      await db
          .execute('DELETE FROM sqlite_sequence WHERE name = ?', [tableName]);
    }
  }

  Future<void> resetAutoIncrement() async {
    final db = await database;

    await db.execute("DELETE FROM sqlite_sequence WHERE name='Categories'");

    await db.execute("DELETE FROM sqlite_sequence WHERE name='Foods'");
  }

  Future<void> deleteFood(int foodId) async {
    final db = await database;
    await db.delete(
      'Foods',
      where: 'id = ?',
      whereArgs: [foodId],
    );
  }

  Future<void> updateCategoryOrder(int categoryId, int newOrder) async {
    final db = await database;
    await db.update(
      'Categories',
      {'displayOrder': newOrder},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllFoods() async {
    final db = await this.database;
    return await db.query('Foods');
  }

  Future<void> deleteAllData() async {
    final db = await database;

    await db.delete('Foods');

    await db.delete('Categories');
  }

  Future<void> updateSettings(
      {required bool darkMode, required bool animationsOff}) async {
    final db = await database;
    await db.update(
      'SettingsPreference',
      {
        'darkMode': darkMode ? 1 : 0,
        'animationsOff': animationsOff ? 1 : 0,
      },
      where: 'id = 1',
    );
  }

  Future<Map<String, bool>> getSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> settings =
        await db.query('SettingsPreference', where: 'id = 1');

    if (settings.isNotEmpty) {
      return {
        'darkMode': settings[0]['darkMode'] == 1,
        'animationsOff': settings[0]['animationsOff'] == 1,
      };
    } else {
      return {'darkMode': false, 'animationsOff': false};
    }
  }
}
