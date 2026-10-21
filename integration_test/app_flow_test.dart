import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qflags/game/flag_colors.dart';
import 'package:qflags/main.dart' as app;

/// Percorre o app inteiro: idioma, Como Jogar, os 3 modos, salvar no
/// ranking (SQLite) e modo escuro.
///
/// Rodar no desktop:  flutter test integration_test -d linux
/// Para salvar prints de cada tela:  --dart-define=SHOTS_DIR=/caminho
const _shotsDir = String.fromEnvironment('SHOTS_DIR');

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump();
  if (_shotsDir.isEmpty) return;
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final image = await layer.toImage(Offset.zero & tester.view.physicalSize);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File('$_shotsDir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
}

/// Posição da bandeira verdadeira no modo Memória: a única desenhada com a
/// matriz identidade.
int _realOption(WidgetTester tester) {
  final identity = ColorFilter.matrix(ColorMatrix.identity.toFilterMatrix());
  for (var i = 0; i < 4; i++) {
    final filtered = tester.widget<ColorFiltered>(find.descendant(
      of: find.byKey(ValueKey('option_$i')),
      matching: find.byType(ColorFiltered),
    ));
    if (filtered.colorFilter == identity) return i;
  }
  throw StateError('bandeira verdadeira não encontrada');
}

Future<void> _wait(WidgetTester tester, int ms) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fluxo completo do QFlags', (tester) async {
    app.main();
    await _wait(tester, 2500);
    await tester.pumpAndSettle();

    // Garante português e tema claro.
    if (find.text('Jogar').evaluate().isEmpty) {
      await tester.tap(find.text('EN · PT'));
      await tester.pumpAndSettle();
    }
    if (find.byTooltip('Modo claro').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Modo claro'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Jogar'), findsOneWidget);
    await _shot(tester, '01_home_claro');

    await tester.tap(find.text('Como Jogar'));
    await tester.pumpAndSettle();
    await _shot(tester, '02_como_jogar');
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    // Memória: 10 rodadas.
    await tester.tap(find.text('Jogar'));
    await tester.pumpAndSettle();
    await _shot(tester, '03_modos');
    await tester.tap(find.text('Memória'));
    await tester.pumpAndSettle();
    await _wait(tester, 500);
    await _shot(tester, '04_memoria');
    // Acerta as 10: ganha mais 10 rodadas.
    for (var round = 1; round <= 10; round++) {
      expect(find.text('Rodada $round/10'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('option_${_realOption(tester)}')));
      await _wait(tester, 300);
      if (round == 1) await _shot(tester, '05_memoria_resposta');
      if (round == 10) {
        expect(find.text('Perfeito! +10 rodadas'), findsOneWidget);
        expect(find.text('Rodada 10/20'), findsOneWidget);
        await _shot(tester, '05b_memoria_bonus');
      }
      await _wait(tester, round == 10 ? 1600 : 900);
      await tester.pumpAndSettle();
    }
    // Erra a 11ª de propósito: sem bônus, a partida acaba na 20ª.
    for (var round = 11; round <= 20; round++) {
      expect(find.text('Rodada $round/20'), findsOneWidget);
      final real = _realOption(tester);
      await tester.tap(find.byKey(ValueKey('option_${round == 11 ? (real + 1) % 4 : real}')));
      await _wait(tester, 1200);
      await tester.pumpAndSettle();
    }

    // Resultado (19 acertos, 1 erro) → salvar → ranking.
    expect(find.text('Salvar pontuação'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);
    expect(find.text('19 acertos · 1 erros'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Tester');
    await _shot(tester, '06_resultado');
    await tester.tap(find.text('Salvar pontuação'));
    await _wait(tester, 500);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver ranking'));
    await tester.pumpAndSettle();
    expect(find.text('Tester'), findsWidgets);
    await _shot(tester, '07_ranking');
    // Ranking → seleção de modos → início.
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    // Inglês + escuro.
    await tester.tap(find.text('PT · EN'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Dark mode'));
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget);
    await _shot(tester, '08_home_dark_en');

    // TimeAttack: algumas respostas e sai.
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TimeAttack'));
    await _wait(tester, 600);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('option_1')));
      await _wait(tester, 250);
      if (i == 2) await _shot(tester, '09_time_attack');
      await _wait(tester, 400);
    }
    await tester.tap(find.byTooltip('Quit'));
    await tester.pumpAndSettle();

    // HalfFlag em português e claro de novo.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EN · PT'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Modo claro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jogar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HalfFlag'));
    await _wait(tester, 600);
    await tester.pumpAndSettle();
    expect(find.text('De qual país é esta metade?'), findsOneWidget);
    await _shot(tester, '10_half_flag');
  });
}
