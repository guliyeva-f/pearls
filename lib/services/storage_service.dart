import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/quote.dart';

class StorageService {
  static Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'pearls.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE quotes (
            id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            tags TEXT NOT NULL DEFAULT '',
            isFavourite INTEGER NOT NULL DEFAULT 0,
            date TEXT,
            rowOrder INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<List<Quote>> loadQuotes() async {
    final db = await _database;
    final maps = await db.query('quotes', orderBy: 'rowOrder DESC');
    return maps.map(_fromDbMap).toList();
  }

  Future<void> addQuote(Quote quote) async {
    final db = await _database;
    final maxOrder =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT MAX(rowOrder) FROM quotes'),
        ) ??
        -1;
    await db.insert(
      'quotes',
      _toDbMap(quote, maxOrder + 1),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addQuotes(List<Quote> quotes) async {
    final db = await _database;
    final maxOrder =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT MAX(rowOrder) FROM quotes'),
        ) ??
        -1;
    final batch = db.batch();
    for (int i = 0; i < quotes.length; i++) {
      batch.insert(
        'quotes',
        _toDbMap(quotes[i], maxOrder + 1 + i),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateQuote(Quote updated) async {
    final db = await _database;
    await db.update(
      'quotes',
      {
        'text': updated.text,
        'tags': updated.tags.join(','),
        'isFavourite': updated.isFavourite ? 1 : 0,
        'date': updated.date?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [updated.id],
    );
  }

  Map<String, dynamic> _toDbMap(Quote q, int order) {
    return {
      'id': q.id,
      'text': q.text,
      'tags': q.tags.join(','),
      'isFavourite': q.isFavourite ? 1 : 0,
      'date': q.date?.toIso8601String(),
      'rowOrder': order,
    };
  }

  Quote _fromDbMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as String,
      text: map['text'] as String,
      tags: (map['tags'] as String).isEmpty
          ? []
          : (map['tags'] as String).split(','),
      isFavourite: (map['isFavourite'] as int) == 1,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String)
          : null,
    );
  }
}
