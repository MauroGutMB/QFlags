import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qflags/game/flag_colors.dart';
import 'package:qflags/game/quiz_engine.dart';
import 'package:qflags/l10n/strings.dart';
import 'package:qflags/models/country.dart';
import 'package:qflags/models/game_mode.dart';

void main() {
  final countries = [
    for (var i = 0; i < 10; i++) Country(code: 'c$i', en: 'Country $i', pt: 'País $i'),
  ];

  test('cada pergunta tem 4 alternativas distintas incluindo a resposta', () {
    final engine = QuizEngine(countries, random: Random(1));
    for (var i = 0; i < 50; i++) {
      final q = engine.next();
      expect(q.options.length, GameMode.optionsPerQuestion);
      expect(q.options.toSet().length, GameMode.optionsPerQuestion);
      expect(q.options, contains(q.answer));
    }
  });

  test('respostas não se repetem até esgotar a lista', () {
    final engine = QuizEngine(countries, random: Random(2));
    final answers = {for (var i = 0; i < countries.length; i++) engine.next().answer};
    expect(answers.length, countries.length);
  });

  test('Memória: a bandeira verdadeira aparece uma vez entre as 4', () {
    final engine = QuizEngine(countries, random: Random(3));
    final fakes = [for (final d in [90.0, 180.0, 270.0]) ColorMatrix.hueRotation(d)];
    final q = engine.withLooks(engine.nextAnswer(), fakes);
    expect(q.looks!.length, GameMode.optionsPerQuestion);
    final right = [for (var i = 0; i < 4; i++) if (q.isCorrect(i)) i];
    expect(right, [q.realLook]);
    expect(q.looks![q.realLook!].isIdentity, isTrue);
  });

  test('todas as chaves do dicionário têm PT e EN', () {
    for (final key in Strings.keys) {
      expect(Strings.hasAllLanguages(key), isTrue, reason: key);
    }
  });

  test('tradução com parâmetros', () {
    expect(Strings.get('round', AppLang.pt, {'n': 3, 'total': 10}), 'Rodada 3/10');
    expect(Strings.get('round', AppLang.en, {'n': 3, 'total': 10}), 'Round 3/10');
  });
}
