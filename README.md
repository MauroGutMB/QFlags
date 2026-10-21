# QFlags

Jogo mobile em Flutter para adivinhar bandeiras (bandeiras de [ssenegas/flutter_flags_quiz](https://github.com/ssenegas/flutter_flags_quiz)).

- **Modos** (sempre 4 alternativas):
  - **Memória**: a mesma bandeira 4 vezes, só uma com as cores certas; nas outras as cores foram trocadas entre si, pintadas de outra cor ou distorcidas. 10 rodadas.
  - **TimeAttack**: bandeira → nome, 60 segundos.
  - **HalfFlag**: meia bandeira → nome, 10 rodadas.
- **Ranking** salvo em SQLite (`sqflite`), separado por modo.
- **Tema** claro/escuro e **idioma** PT/EN (dicionário em `lib/l10n/strings.dart`), lembrados entre aberturas.

## Rodar

```bash
flutter pub get
flutter run                                   # celular/emulador
flutter test                                  # testes unitários
flutter test integration_test -d linux        # fluxo completo no desktop
```

## Estrutura

```
lib/
  main.dart               app, tema e idioma
  app_settings.dart       preferências (tema, idioma, último nome)
  l10n/strings.dart       dicionário PT/EN
  theme/app_theme.dart    paleta clara/escura
  models/                 Country, GameMode, Score
  data/                   países (JSON) e ranking (SQLite)
  game/quiz_engine.dart   sorteio das perguntas
  game/flag_colors.dart   cores falsas do modo Memória (paleta + matrizes de cor)
  game/flag_looks.dart    carrega os pixels das bandeiras para o flag_colors
  screens/                início, como jogar, modos, partida, resultado, ranking
  widgets/common.dart     botões, pílulas, bandeira
assets/
  data/countries.json     193 países com nome em PT e EN
  flags/                  bandeiras 128x128
```

## Como as cores falsas são geradas (modo Memória)

1. As imagens têm o mesmo efeito de brilho em todas as bandeiras (metade de cima clareada, de baixo escurecida). Ele é medido uma vez (Bélgica = preto, Japão = branco) e descontado para achar as **cores lisas** de cada bandeira.
2. As cores principais viram uma **paleta** (cores com menos de 2% da área e misturas de borda são ignoradas).
3. Cada versão falsa é uma **matriz de cor 3x3** que mantém branco e preto: trocar duas cores da paleta, pintar uma cor de outra (vermelho, azul, verde, amarelo, laranja, azul-claro, preto) ou girar o matiz/trocar canais RGB.
4. As candidatas são aplicadas aos pixels e só ficam as que mudam bastante a bandeira e são diferentes entre si.

Como a matriz é linear e mantém o branco, brilho, sombra e moldura ficam idênticos nas 4 versões: não dá para achar a verdadeira pelo acabamento, só pelas cores. Na tela, a matriz é aplicada com `ColorFilter.matrix` (inclusive a verdadeira, com a identidade).
