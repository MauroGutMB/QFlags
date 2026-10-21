import 'dart:math';

import '../models/country.dart';
import '../models/game_mode.dart';
import 'flag_colors.dart';

class Question {
  const Question({required this.answer, this.options = const [], this.looks, this.realLook});

  final Country answer;

  /// TimeAttack e HalfFlag: [GameMode.optionsPerQuestion] países, a resposta entre eles.
  final List<Country> options;

  /// Memória: versões de cor da bandeira da resposta.
  final List<ColorMatrix>? looks;

  /// Memória: posição da versão verdadeira em [looks].
  final int? realLook;

  bool isCorrect(int index) => looks != null ? index == realLook : options[index] == answer;
}

/// Sorteia perguntas sem repetir a resposta dentro da mesma partida.
class QuizEngine {
  QuizEngine(this._countries, {Random? random}) : _random = random ?? Random() {
    if (_countries.length < GameMode.optionsPerQuestion) {
      throw ArgumentError('São necessários ao menos ${GameMode.optionsPerQuestion} países');
    }
    _refill();
  }

  final List<Country> _countries;
  final Random _random;
  final List<Country> _pool = [];

  void _refill() => _pool
    ..clear()
    ..addAll(_countries)
    ..shuffle(_random);

  Country nextAnswer() {
    if (_pool.isEmpty) _refill();
    return _pool.removeLast();
  }

  /// Pergunta com 4 países como alternativas.
  Question next() {
    final answer = nextAnswer();

    final distractors = <Country>{};
    while (distractors.length < GameMode.optionsPerQuestion - 1) {
      final c = _countries[_random.nextInt(_countries.length)];
      if (c != answer) distractors.add(c);
    }

    final options = [answer, ...distractors]..shuffle(_random);
    return Question(answer: answer, options: options);
  }

  /// Pergunta do modo Memória: as [fakes] com a bandeira verdadeira numa
  /// posição sorteada entre elas.
  Question withLooks(Country answer, List<ColorMatrix> fakes) {
    final realLook = _random.nextInt(fakes.length + 1);
    return Question(
      answer: answer,
      looks: [...fakes]..insert(realLook, ColorMatrix.identity),
      realLook: realLook,
    );
  }
}
