import 'package:flutter_db_app/model/film_note.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  
  static const String DB_NAME = 'films.db';
  static const String TABLE = "FilmNote";

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), DB_NAME);
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE $TABLE(id INTEGER PRIMARY KEY AUTOINCREMENT, image BLOB NULL, imageUrl TEXT NULL, title TEXT, genre TEXT, year TEXT)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute('ALTER TABLE $TABLE ADD COLUMN imageUrl TEXT NULL');
        }
      },
    );
  }


  Future<void> insertFilm(FilmNote note) async {
    final db = await database;
    await db.insert(
      TABLE,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<String> getDatabasePath() async {
    String path = join(await getDatabasesPath(), DB_NAME);
    print('Database path: $path');
    return path;
  }
  Future<List<FilmNote>> getFilms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(TABLE);

    return List.generate(maps.length, (i) {
      return FilmNote(
        id: maps[i]['id'],
        image: maps[i]['image'],
        imageUrl: maps[i]['imageUrl'],
        title: maps[i]['title'],
        genre: maps[i]['genre'],
        year: maps[i]['year'],
      );
    });
  }
  Future<FilmNote> getFilmById(int? id) async {
    final db = await database;
    var result = await db.query(TABLE, where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return FilmNote.fromMap(result.first);
    } else {
      throw Exception('Film not found');
    }
  }


  Future<void> updateFilm(FilmNote note) async {
    final db = await database;
    await db.update(
      TABLE,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteFilm(int? id) async {
    final db = await database;
    await db.delete(
      TABLE,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
