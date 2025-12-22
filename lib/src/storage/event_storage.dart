import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/event.dart';
import '../exceptions/tracker_exceptions.dart';

/// SQLite-based storage for events
class EventStorage {
  static const String _databaseName = 'nds_track_events.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'events';

  Database? _database;
  bool _isInitialized = false;

  /// Initialize the database
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      _isInitialized = true;
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to initialize database',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        properties TEXT NOT NULL,
        userId TEXT,
        timestamp INTEGER NOT NULL,
        retryCount INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Create index for efficient queries
    await db.execute('''
      CREATE INDEX idx_timestamp ON $_tableName(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_status ON $_tableName(status)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
  }

  /// Ensure database is initialized
  void _ensureInitialized() {
    if (!_isInitialized || _database == null) {
      throw const TrackerStorageException('Database not initialized');
    }
  }

  /// Save a single event
  Future<void> saveEvent(Event event) async {
    _ensureInitialized();

    try {
      final data = event.toDbJson();
      data['createdAt'] = DateTime.now().millisecondsSinceEpoch;

      await _database!.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to save event: ${event.id}',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Save multiple events in a batch
  Future<void> saveEvents(List<Event> events) async {
    if (events.isEmpty) return;

    _ensureInitialized();

    try {
      final batch = _database!.batch();
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final event in events) {
        final data = event.toDbJson();
        data['createdAt'] = now;

        batch.insert(
          _tableName,
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to save batch of ${events.length} events',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get events by status
  Future<List<Event>> getEventsByStatus(
    EventStatus status, {
    int? limit,
  }) async {
    _ensureInitialized();

    try {
      final statusStr = status.toString().split('.').last;
      final results = await _database!.query(
        _tableName,
        where: 'status = ?',
        whereArgs: [statusStr],
        orderBy: 'timestamp ASC',
        limit: limit,
      );

      return results.map((json) => Event.fromJson(json)).toList();
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to get events by status: $status',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get oldest pending events up to limit
  Future<List<Event>> getPendingEvents({int? limit}) async {
    return getEventsByStatus(EventStatus.pending, limit: limit);
  }

  /// Get all events
  Future<List<Event>> getAllEvents() async {
    _ensureInitialized();

    try {
      final results = await _database!.query(
        _tableName,
        orderBy: 'timestamp ASC',
      );

      return results.map((json) => Event.fromJson(json)).toList();
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to get all events',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update event status
  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    _ensureInitialized();

    try {
      final statusStr = status.toString().split('.').last;
      await _database!.update(
        _tableName,
        {'status': statusStr},
        where: 'id = ?',
        whereArgs: [eventId],
      );
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to update event status: $eventId',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update event retry count
  Future<void> updateEventRetryCount(String eventId, int retryCount) async {
    _ensureInitialized();

    try {
      await _database!.update(
        _tableName,
        {'retryCount': retryCount},
        where: 'id = ?',
        whereArgs: [eventId],
      );
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to update event retry count: $eventId',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete a single event by ID
  Future<void> deleteEvent(String eventId) async {
    _ensureInitialized();

    try {
      await _database!.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [eventId],
      );
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to delete event: $eventId',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete multiple events by IDs
  Future<void> deleteEvents(List<String> eventIds) async {
    if (eventIds.isEmpty) return;

    _ensureInitialized();

    try {
      final batch = _database!.batch();

      for (final id in eventIds) {
        batch.delete(
          _tableName,
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      await batch.commit(noResult: true);
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to delete batch of ${eventIds.length} events',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete events by status
  Future<int> deleteEventsByStatus(EventStatus status) async {
    _ensureInitialized();

    try {
      final statusStr = status.toString().split('.').last;
      return await _database!.delete(
        _tableName,
        where: 'status = ?',
        whereArgs: [statusStr],
      );
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to delete events by status: $status',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete old events (older than specified timestamp)
  Future<int> deleteOldEvents(int olderThanTimestamp) async {
    _ensureInitialized();

    try {
      return await _database!.delete(
        _tableName,
        where: 'timestamp < ?',
        whereArgs: [olderThanTimestamp],
      );
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to delete old events',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get total event count
  Future<int> getEventCount() async {
    _ensureInitialized();

    try {
      final result = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to get event count',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get event count by status
  Future<int> getEventCountByStatus(EventStatus status) async {
    _ensureInitialized();

    try {
      final statusStr = status.toString().split('.').last;
      final result = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE status = ?',
        [statusStr],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to get event count by status: $status',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear all events from storage
  Future<void> clear() async {
    _ensureInitialized();

    try {
      await _database!.delete(_tableName);
    } catch (e, stackTrace) {
      throw TrackerStorageException(
        'Failed to clear all events',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      try {
        await _database!.close();
        _database = null;
        _isInitialized = false;
      } catch (e, stackTrace) {
        throw TrackerStorageException(
          'Failed to close database',
          originalError: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  /// Check if storage is initialized
  bool get isInitialized => _isInitialized;
}

