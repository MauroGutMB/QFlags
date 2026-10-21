import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
    for (var round = 1; round <= 10; round++) {
      expect(find.text('Rodada $round/10'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('option_0')));
      await _wait(tester, 300);
      if (round == 1) await _shot(tester, '05_memoria_resposta');
      await _wait(tester, 900);
      await tester.pumpAndSettle();
    }

    // Resultado → salvar → ranking.
    expect(find.text('Salvar pontuação'), findsOneWidget);
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
