import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehicle.dart';

/// Gère la connexion à la base SQLite et toutes les opérations CRUD
/// sur la table `vehicles`. Implémenté en singleton pour n'avoir
/// qu'une seule instance de base de données ouverte dans l'app.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  static const String _tableName = 'vehicles';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vehicules_app.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firstname TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        dimension_length_meters REAL,
        dimension_width_meters REAL,
        color TEXT,
        notes TEXT
      )
    ''');
  }

  /// Récupère tous les véhicules, triés par nom.
  Future<List<Vehicle>> getAllVehicles() async {
    final db = await database;
    final result = await db.query(_tableName, orderBy: 'name COLLATE NOCASE ASC');
    return result.map((map) => Vehicle.fromMap(map)).toList();
  }

  /// Récupère un véhicule par son id.
  Future<Vehicle?> getVehicleById(int id) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Vehicle.fromMap(result.first);
  }

  /// Insère un nouveau véhicule et retourne son id généré.
  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    return db.insert(
      _tableName,
      vehicle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Met à jour un véhicule existant (identifié par son id).
  Future<int> updateVehicle(Vehicle vehicle) async {
    if (vehicle.id == null) {
      throw ArgumentError('Impossible de mettre à jour un véhicule sans id');
    }
    final db = await database;
    return db.update(
      _tableName,
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  /// Supprime un véhicule par son id.
  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
