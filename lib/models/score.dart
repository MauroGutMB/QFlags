import 'game_mode.dart';

class Score {
  const Score({
    this.id,
    required this.name,
    required this.mode,
    required this.points,
    required this.createdAt,
  });

  factory Score.fromMap(Map<String, Object?> map) => Score(
        id: map['id'] as int?,
        name: map['name'] as String,
        mode: GameMode.values.byName(map['mode'] as String),
        points: map['points'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  final int? id;
  final String name;
  final GameMode mode;
  final int points;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'mode': mode.name,
        'points': points,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
