import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('memoria.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE memoria_polaroids (
        id TEXT PRIMARY KEY,
        image_path TEXT NOT NULL,
        output_image_path TEXT NOT NULL,
        language_code TEXT NOT NULL,
        selected_object_id TEXT,
        selected_word TEXT NOT NULL,
        secondary_script TEXT,
        transliteration TEXT,
        part_of_speech TEXT,
        difficulty_level TEXT,
        text_x REAL DEFAULT 0.5,
        text_y REAL DEFAULT 0.88,
        layout_id TEXT DEFAULT 'classic',
        is_favorite INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE memoria_detected_objects (
        id TEXT PRIMARY KEY,
        polaroid_id TEXT NOT NULL,
        label_en TEXT NOT NULL,
        target_word TEXT NOT NULL,
        secondary_script TEXT,
        transliteration TEXT,
        part_of_speech TEXT,
        difficulty_level TEXT,
        box_ymin INTEGER NOT NULL,
        box_xmin INTEGER NOT NULL,
        box_ymax INTEGER NOT NULL,
        box_xmax INTEGER NOT NULL,
        FOREIGN KEY (polaroid_id) REFERENCES memoria_polaroids (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
