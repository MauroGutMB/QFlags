import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/country_repository.dart';
import '../game/flag_colors.dart';
import '../game/flag_looks.dart';
import '../game/quiz_engine.dart';
import '../l10n/strings.dart';
import '../models/game_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'result_screen.dart';

/// Uma partida de qualquer um dos três modos.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum _OptionState { idle, correct, wrong, dimmed }

class _GameScreenState extends State<GameScreen> {
  final _random = Random();
  late final QuizEngine _engine =
      QuizEngine(CountryRepository.instance.countries, random: _random);
  late int _secondsLeft = widget.mode.timeLimit?.inSeconds ?? 0;

  /// Pergunta na tela (null enquanto a primeira carrega).
  Question? _question;

  /// A próxima pergunta já vai sendo preparada enquanto o jogador responde.
  late Future<Question> _upcoming;

  int _round = 1;
  int _correct = 0;
  int _wrong = 0;
  int? _picked;
  bool _finished = false;
  Timer? _clock;
  Timer? _advance;

  GameMode get _mode => widget.mode;

  @override
  void initState() {
    super.initState();
    _upcoming = _prepare();
    _showUpcoming();
    if (_mode.timeLimit != null) {
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) _finish();
      });
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _advance?.cancel();
    super.dispose();
  }

  Future<Question> _prepare() async {
    if (!_mode.optionsAreFlags) return _engine.next();

    // Memória: a mesma bandeira 4 vezes, 3 delas com as cores trocadas.
    final answer = _engine.nextAnswer();
    List<ColorMatrix> fakes;
    try {
      fakes = await FlagLooks.instance.distractorsFor(answer, _random);
    } catch (error) {
      debugPrint('Falha ao gerar cores falsas de ${answer.code}: $error');
      fakes = [for (final d in const [90.0, 180.0, 270.0]) ColorMatrix.hueRotation(d)];
    }
    return _engine.withLooks(answer, fakes);
  }

  Future<void> _showUpcoming() async {
    final question = await _upcoming;
    if (!mounted || _finished) return;
    setState(() {
      if (_question != null) _round++;
      _question = question;
      _picked = null;
    });
    _upcoming = _prepare();
  }

  void _pick(int index) {
    final question = _question;
    if (question == null || _picked != null || _finished) return;
    final right = question.isCorrect(index);
    setState(() {
      _picked = index;
      right ? _correct++ : _wrong++;
    });
    right ? HapticFeedback.selectionClick() : HapticFeedback.mediumImpact();
    final delay = _mode == GameMode.timeAttack ? 500 : 1000;
    _advance = Timer(Duration(milliseconds: delay), _nextQuestion);
  }

  void _nextQuestion() {
    if (_finished) return;
    final rounds = _mode.rounds;
    if (rounds != null && _round >= rounds) {
      _finish();
      return;
    }
    _showUpcoming();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _clock?.cancel();
    _advance?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(mode: _mode, correct: _correct, wrong: _wrong),
      ),
    );
  }

  _OptionState _stateOf(Question question, int index) {
    if (_picked == null) return _OptionState.idle;
    if (question.isCorrect(index)) return _OptionState.correct;
    if (index == _picked) return _OptionState.wrong;
    return _OptionState.dimmed;
  }

  double get _progress {
    final limit = _mode.timeLimit;
    if (limit != null) return _secondsLeft / limit.inSeconds;
    final done = _round - 1 + (_picked != null ? 1 : 0);
    return done / _mode.rounds!;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = _mode.accent(c);
    final question = _question;
    return QScreen(
      child: Column(
        children: [
          _header(c, accent),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              color: accent,
              backgroundColor: c.track,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: question == null
                ? Center(child: CircularProgressIndicator(color: accent))
                : _mode.optionsAreFlags
                    ? _flagOptionsBody(c, question)
                    : _nameOptionsBody(c, question),
          ),
          SizedBox(
            height: 44,
            child: Center(child: question == null ? null : _feedback(c, question)),
          ),
        ],
      ),
    );
  }

  Widget _header(QColors c, Color accent) {
    final Widget center = _mode.timeLimit != null
        ? Pill(
            text: '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
            icon: Icons.timer_outlined,
            background: _secondsLeft <= 10 ? c.wrong : accent,
            foreground: c.onAccent,
            fontSize: 20,
          )
        : Text(
            context.tr('round', {'n': _round, 'total': _mode.rounds!}),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.muted),
          );
    return Row(
      children: [
        CircleIconButton(
          icon: Icons.close,
          tooltip: context.tr('quit'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(child: Center(child: center)),
        Pill(
          text: context.tr('points_short', {'n': _correct}),
          background: accent,
          foreground: c.onAccent,
        ),
      ],
    );
  }

  Widget _feedback(QColors c, Question question) {
    final picked = _picked;
    if (picked == null) return const SizedBox.shrink();
    final right = question.isCorrect(picked);
    return Text(
      right
          ? context.tr('correct')
          : _mode.optionsAreFlags
              ? context.tr('wrong_colors')
              : context.tr('wrong', {'name': question.answer.name(context.lang)}),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: right ? c.correct : c.wrong,
      ),
    );
  }

  /// Memória: nome do país em cima e a mesma bandeira 4 vezes em grade 2x2,
  /// só uma com as cores certas.
  Widget _flagOptionsBody(QColors c, Question question) {
    final looks = question.looks!;
    Widget cell(int i) => Expanded(
          child: _OptionTile(
            key: ValueKey('option_$i'),
            state: _stateOf(question, i),
            semanticLabel: context.tr('flag_option', {'n': i + 1}),
            onTap: () => _pick(i),
            child: LayoutBuilder(
              builder: (_, box) => FlagImage(
                country: question.answer,
                // A imagem já tem margem transparente; pode ocupar o quadro todo.
                size: min(box.maxWidth, box.maxHeight),
                colors: looks[i],
              ),
            ),
          ),
        );
    return Column(
      children: [
        _card(
          c,
          Column(
            children: [
              Text(context.tr('find_real_flag'), style: TextStyle(fontSize: 14, color: c.muted)),
              const SizedBox(height: 8),
              Text(
                question.answer.name(context.lang),
                textAlign: TextAlign.center,
                style: display(32, color: c.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Column(
            children: [
              Expanded(child: Row(children: [cell(0), const SizedBox(width: 12), cell(1)])),
              const SizedBox(height: 12),
              Expanded(child: Row(children: [cell(2), const SizedBox(width: 12), cell(3)])),
            ],
          ),
        ),
      ],
    );
  }

  /// TimeAttack e HalfFlag: bandeira (inteira ou metade) e 4 nomes.
  Widget _nameOptionsBody(QColors c, Question question) {
    final half = _mode == GameMode.halfFlag;
    return Column(
      children: [
        Expanded(
          child: _card(
            c,
            Column(
              children: [
                Text(
                  context.tr(half ? 'which_half' : 'which_country'),
                  style: TextStyle(fontSize: 14, color: c.muted),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, box) {
                      final size = min(min(box.maxWidth, box.maxHeight), 220.0);
                      final flag = FlagImage(country: question.answer, size: size, half: half);
                      if (!half) return Center(child: flag);
                      return Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            flag,
                            Container(
                              width: size / 2,
                              height: size * .7,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: c.border, width: 2),
                                borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(10),
                                ),
                              ),
                              child: Text('?', style: display(34, color: c.muted)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (final (i, option) in question.options.indexed) ...[
          SizedBox(
            height: 56,
            child: _OptionTile(
              key: ValueKey('option_$i'),
              state: _stateOf(question, i),
              onTap: () => _pick(i),
              child: Text(
                option.name(context.lang),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _card(QColors c, Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.track),
        ),
        child: child,
      );
}

/// Alternativa clicável que muda de cor quando a resposta é revelada.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.state,
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });

  final _OptionState state;
  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, border, fg, width) = switch (state) {
      _OptionState.correct => (c.correctBg, c.correct, c.correctText, 3.0),
      _OptionState.wrong => (c.wrongBg, c.wrong, c.wrongText, 3.0),
      _OptionState.idle || _OptionState.dimmed => (c.surface, c.border, c.text, 2.0),
    };
    return Semantics(
      button: true,
      label: semanticLabel,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: state == _OptionState.dimmed ? .5 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: width),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: state == _OptionState.idle ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: DefaultTextStyle.merge(style: TextStyle(color: fg), child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
