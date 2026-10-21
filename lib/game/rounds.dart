import 'dart:math';

/// Rodadas da Memória e do HalfFlag. A partida começa com [block] rodadas;
/// quem completa todas sem errar ganha mais [block], e assim por diante
/// (10/10 → 20, 20/20 → 30...), até acabarem as bandeiras ([max]).
class Rounds {
  Rounds({required this.block, required this.max}) : total = min(block, max);

  final int block;
  final int max;

  /// Rodada atual, começando em 1.
  int current = 1;

  /// Rodadas liberadas até agora.
  int total;

  bool get isLast => current >= total;

  /// Registra a resposta da rodada atual; [errors] é o total de erros da
  /// partida até aqui. Devolve quantas rodadas foram liberadas (0 se nenhuma).
  int answered({required int errors}) {
    if (!isLast || errors > 0 || total >= max) return 0;
    final extra = min(block, max - total);
    total += extra;
    return extra;
  }

  void next() => current++;
}
