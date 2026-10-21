import 'package:flutter_test/flutter_test.dart';
import 'package:qflags/game/rounds.dart';

/// Responde a rodada atual e devolve as rodadas ganhas.
int play(Rounds rounds, {required int errors}) {
  final extra = rounds.answered(errors: errors);
  if (!rounds.isLast) rounds.next();
  return extra;
}

void main() {
  test('10/10 sem erros libera mais 10 rodadas, 20/20 mais 10...', () {
    final rounds = Rounds(block: 10, max: 193);
    for (var i = 1; i < 10; i++) {
      expect(play(rounds, errors: 0), 0);
    }
    expect(rounds.current, 10);
    expect(play(rounds, errors: 0), 10);
    expect(rounds.total, 20);
    expect(rounds.current, 11);

    while (rounds.current < 20) {
      play(rounds, errors: 0);
    }
    expect(play(rounds, errors: 0), 10);
    expect(rounds.total, 30);
  });

  test('com algum erro a partida termina no fim do bloco', () {
    final rounds = Rounds(block: 10, max: 193);
    play(rounds, errors: 1); // errou a primeira
    while (!rounds.isLast) {
      play(rounds, errors: 1);
    }
    expect(rounds.current, 10);
    expect(rounds.answered(errors: 1), 0);
    expect(rounds.total, 10);
    expect(rounds.isLast, isTrue);
  });

  test('o bônus para no limite de bandeiras', () {
    final rounds = Rounds(block: 10, max: 25);
    final gained = <int>[];
    while (true) {
      final extra = rounds.answered(errors: 0);
      if (extra > 0) gained.add(extra);
      if (rounds.isLast) break;
      rounds.next();
    }
    expect(gained, [10, 5]); // 10 → 20 → 25
    expect(rounds.total, 25);
    expect(rounds.current, 25);
  });
}
