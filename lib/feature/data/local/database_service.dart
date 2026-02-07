import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/app_usage_stats.dart';

/// Service for managing SQLite database operations for statistics
/// Handles historical app usage data and block attempts
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  /// Get database instance, initialize if needed
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with tables and indexes
  Future<Database> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, 'app_blocker.db');

    return await openDatabase(
      path,
      version: 2, // ✨ Increment version to trigger onUpgrade
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all database tables
  Future<void> _createTables(Database db, int version) async {
    // Table for daily app usage snapshots
    await db.execute('''
      CREATE TABLE daily_app_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        usage_time_millis INTEGER NOT NULL,
        open_count INTEGER NOT NULL DEFAULT 0, -- ✨ NEW
        block_attempts INTEGER NOT NULL DEFAULT 0, -- ✨ NEW
        date TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(package_name, date)
      )
    ''');

    // Table for daily block attempts aggregate
    await db.execute('''
      CREATE TABLE daily_block_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total_attempts INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(date)
      )
    ''');

    // Create indexes for performance
    await db.execute(
      'CREATE INDEX idx_daily_usage_date ON daily_app_usage(date)',
    );
    await db.execute(
      'CREATE INDEX idx_daily_usage_package_date ON daily_app_usage(package_name, date)',
    );
    await db.execute(
      'CREATE INDEX idx_block_attempts_date ON daily_block_attempts(date)',
    );

    // Clean up old data on initialization
    await _cleanupOldData(db);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute(
        'ALTER TABLE daily_app_usage ADD COLUMN open_count INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE daily_app_usage ADD COLUMN block_attempts INTEGER NOT NULL DEFAULT 0',
      );
      print(
        'Database upgraded to version 2: Added open_count and block_attempts columns',
      );
    }
  }

  /// Save or update daily usage snapshot for multiple apps
  Future<void> saveDailyUsageSnapshot(
    List<AppUsageStats> stats,
    String date,
  ) async {
    final db = await database;
    final batch = db.batch();

    for (final stat in stats) {
      batch.insert('daily_app_usage', {
        'package_name': stat.packageName,
        'app_name': stat.appName,
        'usage_time_millis': stat.totalTimeInMillis,
        'open_count': stat.openCount, // ✨ NEW
        'block_attempts': stat.blockAttempts, // ✨ NEW
        'date': date,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Get usage stats for a specific date
  Future<List<AppUsageStats>> getDailyUsage(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_app_usage',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'usage_time_millis DESC',
    );

    return maps
        .map(
          (map) => AppUsageStats(
            packageName: map['package_name'] as String,
            appName: map['app_name'] as String,
            totalTimeInMillis: map['usage_time_millis'] as int,
            openCount: map['open_count'] as int? ?? 0, // ✨ NEW
            blockAttempts: map['block_attempts'] as int? ?? 0, // ✨ NEW
            date: DateTime.parse(date),
          ),
        )
        .toList();
  }

  /// Get usage stats for a date range
  Future<List<AppUsageStats>> getUsageRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_app_usage',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, usage_time_millis DESC',
    );

    return maps
        .map(
          (map) => AppUsageStats(
            packageName: map['package_name'] as String,
            appName: map['app_name'] as String,
            totalTimeInMillis: map['usage_time_millis'] as int,
            openCount: map['open_count'] as int? ?? 0, // ✨ NEW
            blockAttempts: map['block_attempts'] as int? ?? 0, // ✨ NEW
            date: DateTime.parse(map['date'] as String),
          ),
        )
        .toList();
  }

  /// Get aggregated usage by dates (returns map of date -> stats list)
  Future<Map<String, List<AppUsageStats>>> getUsageByDates(
    List<String> dates,
  ) async {
    await database;
    final Map<String, List<AppUsageStats>> result = {};

    for (final date in dates) {
      final stats = await getDailyUsage(date);
      result[date] = stats;
    }

    return result;
  }

  /// Get total usage time for a date range (in milliseconds)
  Future<int> getTotalUsageForDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(usage_time_millis) as total
      FROM daily_app_usage
      WHERE date >= ? AND date <= ?
    ''',
      [startDate, endDate],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get top N apps for a date range
  Future<List<AppUsageStats>> getTopAppsForDateRange(
    String startDate,
    String endDate,
    int limit,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        package_name,
        app_name,
        SUM(usage_time_millis) as total_time,
        SUM(open_count) as total_opens, -- ✨ NEW
        SUM(block_attempts) as total_blocks -- ✨ NEW
      FROM daily_app_usage
      WHERE date >= ? AND date <= ?
      GROUP BY package_name, app_name
      ORDER BY total_time DESC
      LIMIT ?
    ''',
      [startDate, endDate, limit],
    );

    return maps
        .map(
          (map) => AppUsageStats(
            packageName: map['package_name'] as String,
            appName: map['app_name'] as String,
            totalTimeInMillis: map['total_time'] as int,
            openCount: map['total_opens'] as int? ?? 0, // ✨ NEW
            blockAttempts: map['total_blocks'] as int? ?? 0, // ✨ NEW
            date: DateTime.parse(endDate),
          ),
        )
        .toList();
  }

  /// Find peak day (highest total usage) in a date range
  Future<String?> getPeakDayInRange(String startDate, String endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT date, SUM(usage_time_millis) as total
      FROM daily_app_usage
      WHERE date >= ? AND date <= ?
      GROUP BY date
      ORDER BY total DESC
      LIMIT 1
    ''',
      [startDate, endDate],
    );

    if (result.isEmpty) return null;
    return result.first['date'] as String?;
  }

  /// Save or update daily block attempts total
  Future<void> saveDailyBlockAttempts(int totalAttempts, String date) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('daily_block_attempts', {
      'date': date,
      'total_attempts': totalAttempts,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get block attempts for a specific date
  Future<int> getDailyBlockAttempts(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_block_attempts',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isEmpty) return 0;
    return maps.first['total_attempts'] as int;
  }

  /// Get total block attempts for a date range
  Future<int> getBlockAttemptsForDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(total_attempts) as total
      FROM daily_block_attempts
      WHERE date >= ? AND date <= ?
    ''',
      [startDate, endDate],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Clean up data older than 90 days
  Future<void> cleanupOldData() async {
    final db = await database;
    await _cleanupOldData(db);
  }

  Future<void> _cleanupOldData(Database db) async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
    final dateStr = _formatDate(cutoffDate);

    await db.delete('daily_app_usage', where: 'date < ?', whereArgs: [dateStr]);

    await db.delete(
      'daily_block_attempts',
      where: 'date < ?',
      whereArgs: [dateStr],
    );
  }

  /// Format DateTime to YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
