import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum GameMode {
  /// Mostra o nome, o jogador escolhe a bandeira. 10 rodadas.
  memory(titleKey: 'mode_memory', subtitleKey: 'mode_memory_sub', rounds: 10),

  /// Mostra a bandeira, o jogador escolhe o nome. 60 segundos.
  timeAttack(
    titleKey: 'mode_time_attack',
    subtitleKey: 'mode_time_attack_sub',
    timeLimit: Duration(seconds: 60),
  ),

  /// Mostra metade da bandeira, o jogador escolhe o nome. 10 rodadas.
  halfFlag(titleKey: 'mode_half_flag', subtitleKey: 'mode_half_flag_sub', rounds: 10);

  const GameMode({
    required this.titleKey,
    required this.subtitleKey,
    this.rounds,
    this.timeLimit,
  });

  final String titleKey;
  final String subtitleKey;

  /// Rodadas iniciais; acertando todas, ganha mais esse tanto (ver Rounds).
  final int? rounds;
  final Duration? timeLimit;

  static const optionsPerQuestion = 4;

  /// No modo Memória as alternativas são bandeiras; nos outros, nomes.
  bool get optionsAreFlags => this == GameMode.memory;

  Color accent(QColors c) => switch (this) {
        GameMode.memory => c.memory,
        GameMode.timeAttack => c.timeAttack,
        GameMode.halfFlag => c.halfFlag,
      };

  IconData get icon => switch (this) {
        GameMode.memory => Icons.psychology_outlined,
        GameMode.timeAttack => Icons.timer_outlined,
        GameMode.halfFlag => Icons.vertical_split_outlined,
      };
}
