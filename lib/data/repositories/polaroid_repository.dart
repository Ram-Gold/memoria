import 'package:sqflite/sqflite.dart';
import '../../domain/models/detected_object.dart';
import '../../domain/models/polaroid.dart';
import '../db/database_helper.dart';

class PolaroidRepository {
  final DatabaseHelper _dbHelper;

  PolaroidRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<void> savePolaroid(Polaroid polaroid) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.insert(
        'memoria_polaroids',
        polaroid.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final obj in polaroid.detectedObjects) {
        await txn.insert(
          'memoria_detected_objects',
          obj.toDbMap(polaroid.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Polaroid>> getAllPolaroids() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'memoria_polaroids',
      orderBy: 'created_at DESC',
    );

    final polaroids = <Polaroid>[];
    for (final row in results) {
      final polId = row['id']?.toString() ?? '';
      final objectRows = await db.query(
        'memoria_detected_objects',
        where: 'polaroid_id = ?',
        whereArgs: [polId],
      );

      final objects = objectRows.map((o) => DetectedObject.fromDbMap(o)).toList();
      polaroids.add(Polaroid.fromDbMap(row, objects: objects));
    }

    return polaroids;
  }

  Future<Polaroid?> getPolaroidById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'memoria_polaroids',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final objectRows = await db.query(
      'memoria_detected_objects',
      where: 'polaroid_id = ?',
      whereArgs: [id],
    );

    final objects = objectRows.map((o) => DetectedObject.fromDbMap(o)).toList();
    return Polaroid.fromDbMap(results.first, objects: objects);
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await _dbHelper.database;
    await db.update(
      'memoria_polaroids',
      {'is_favorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePolaroid(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'memoria_polaroids',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
