import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/game_mode.dart';
import '../models/score.dart';

/// Ranking salvo em SQLite (tabela `scores`).
class RankingDb {
  RankingDb._();
  static final instance = RankingDb._();

  Database? _db;

  Future<Database> get _database async =>
      _db ??= await openDatabase(
        p.join(await getDatabasesPath(), 'qflags.db'),
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE scores (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              mode TEXT NOT NULL,
              points INTEGER NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_scores_mode ON scores (mode, points DESC)');
        },
      );

  Future<int> insert(Score score) async =>
      (await _database).insert('scores', score.toMap());

  /// Melhores pontuações do modo, empate desempatado por quem fez primeiro.
  Future<List<Score>> top(GameMode mode, {int limit = 20}) async {
    final rows = await (await _database).query(
      'scores',
      where: 'mode = ?',
      whereArgs: [mode.name],
      orderBy: 'points DESC, created_at ASC',
      limit: limit,
    );
    return rows.map(Score.fromMap).toList();
  }
}
