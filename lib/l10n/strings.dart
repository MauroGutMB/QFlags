import 'package:flutter/widgets.dart';

import '../app_settings.dart';

enum AppLang { pt, en }

/// Dicionário com todos os textos do app nas duas línguas.
/// Cada chave guarda o texto em português e em inglês; a tela mostra
/// o idioma que estiver selecionado em [AppSettings].
class Strings {
  static const Map<String, Map<AppLang, String>> _dict = {
    'app_title': {AppLang.pt: 'QFlags', AppLang.en: 'QFlags'},
    'tagline': {
      AppLang.pt: 'Quantas bandeiras você conhece?',
      AppLang.en: 'How many flags do you know?',
    },
    'play': {AppLang.pt: 'Jogar', AppLang.en: 'Play'},
    'how_to_play': {AppLang.pt: 'Como Jogar', AppLang.en: 'How to Play'},
    'ranking': {AppLang.pt: 'Ranking', AppLang.en: 'Ranking'},
    'back': {AppLang.pt: 'Voltar', AppLang.en: 'Back'},
    'quit': {AppLang.pt: 'Sair', AppLang.en: 'Quit'},
    'change_language': {AppLang.pt: 'Mudar idioma', AppLang.en: 'Change language'},
    'dark_mode': {AppLang.pt: 'Modo escuro', AppLang.en: 'Dark mode'},
    'light_mode': {AppLang.pt: 'Modo claro', AppLang.en: 'Light mode'},

    // Modos
    'choose_mode': {AppLang.pt: 'Escolha o modo', AppLang.en: 'Choose a mode'},
    'mode_memory': {AppLang.pt: 'Memória', AppLang.en: 'Memory'},
    'mode_time_attack': {AppLang.pt: 'TimeAttack', AppLang.en: 'TimeAttack'},
    'mode_half_flag': {AppLang.pt: 'HalfFlag', AppLang.en: 'HalfFlag'},
    'mode_memory_sub': {
      AppLang.pt: 'Ache as cores certas · 10+ rodadas',
      AppLang.en: 'Spot the right colors · 10+ rounds',
    },
    'mode_time_attack_sub': {
      AppLang.pt: 'Bandeira → nome · 60 segundos',
      AppLang.en: 'Flag → name · 60 seconds',
    },
    'mode_half_flag_sub': {
      AppLang.pt: 'Meia bandeira → nome · 10+ rodadas',
      AppLang.en: 'Half flag → name · 10+ rounds',
    },

    // Como jogar
    'how_intro': {
      AppLang.pt: 'Toda pergunta tem 4 alternativas e apenas uma está certa. Escolha um modo:',
      AppLang.en: 'Every question has 4 options and only one is right. Pick a mode:',
    },
    'how_memory': {
      AppLang.pt: 'Você vê o nome de um país e 4 versões da bandeira dele. Só uma tem as cores certas — nas outras, as cores foram trocadas ou distorcidas. São 10 rodadas, 1 ponto por acerto.',
      AppLang.en: 'You see a country name and 4 versions of its flag. Only one has the right colors — the others had their colors swapped or distorted. 10 rounds, 1 point per right answer.',
    },
    'how_time_attack': {
      AppLang.pt: '60 segundos no relógio. Veja a bandeira e escolha o nome do país. Acerte o máximo que puder.',
      AppLang.en: '60 seconds on the clock. See the flag and pick the country name. Get as many as you can.',
    },
    'how_half_flag': {
      AppLang.pt: 'Só metade da bandeira aparece. Descubra de qual país ela é. 10 rodadas.',
      AppLang.en: 'Only half of the flag is shown. Guess which country it belongs to. 10 rounds.',
    },
    'how_bonus': {
      AppLang.pt: 'Bônus: na Memória e no HalfFlag, quem acerta todas as rodadas ganha mais 10 (10/10 → 20, 20/20 → 30...), até acabarem as bandeiras.',
      AppLang.en: 'Bonus: in Memory and HalfFlag, get every round right and you earn 10 more (10/10 → 20, 20/20 → 30...), until the flags run out.',
    },
    'how_outro': {
      AppLang.pt: 'No fim da partida, digite seu nome para entrar no Ranking.',
      AppLang.en: 'At the end of a game, type your name to enter the Ranking.',
    },

    // Partida
    'round': {AppLang.pt: 'Rodada {n}/{total}', AppLang.en: 'Round {n}/{total}'},
    'points_short': {AppLang.pt: '{n} pts', AppLang.en: '{n} pts'},
    'find_real_flag': {AppLang.pt: 'Encontre a bandeira verdadeira', AppLang.en: 'Find the real flag'},
    'which_country': {AppLang.pt: 'De qual país é esta bandeira?', AppLang.en: 'Which country is this?'},
    'which_half': {AppLang.pt: 'De qual país é esta metade?', AppLang.en: 'Which country is this half from?'},
    'correct': {AppLang.pt: 'Correto!', AppLang.en: 'Correct!'},
    'perfect_bonus': {AppLang.pt: 'Perfeito! +{n} rodadas', AppLang.en: 'Perfect! +{n} rounds'},
    'wrong_colors': {AppLang.pt: 'Cores erradas!', AppLang.en: 'Wrong colors!'},
    'wrong': {AppLang.pt: 'Errado! Era {name}', AppLang.en: 'Wrong! It was {name}'},
    'flag_option': {AppLang.pt: 'Opção {n}', AppLang.en: 'Option {n}'},

    // Resultado
    'game_over': {AppLang.pt: 'fim de jogo', AppLang.en: 'game over'},
    'points': {AppLang.pt: 'pontos', AppLang.en: 'points'},
    'stats': {AppLang.pt: '{c} acertos · {w} erros', AppLang.en: '{c} right · {w} wrong'},
    'your_name': {AppLang.pt: 'Seu nome para o Ranking', AppLang.en: 'Your name for the Ranking'},
    'name_hint': {AppLang.pt: 'Digite seu nome', AppLang.en: 'Type your name'},
    'name_required': {AppLang.pt: 'Digite um nome para salvar', AppLang.en: 'Type a name to save'},
    'save_score': {AppLang.pt: 'Salvar pontuação', AppLang.en: 'Save score'},
    'saved': {AppLang.pt: 'Pontuação salva!', AppLang.en: 'Score saved!'},
    'see_ranking': {AppLang.pt: 'Ver ranking', AppLang.en: 'See ranking'},
    'play_again': {AppLang.pt: 'Jogar de novo', AppLang.en: 'Play again'},
    'home': {AppLang.pt: 'Início', AppLang.en: 'Home'},

    // Ranking
    'ranking_empty': {
      AppLang.pt: 'Ninguém jogou este modo ainda.\nSeja o primeiro!',
      AppLang.en: 'Nobody has played this mode yet.\nBe the first!',
    },
  };

  static String get(String key, AppLang lang, [Map<String, Object>? params]) {
    var text = _dict[key]?[lang] ?? key;
    params?.forEach((k, v) => text = text.replaceAll('{$k}', '$v'));
    return text;
  }

  static Iterable<String> get keys => _dict.keys;

  static bool hasAllLanguages(String key) =>
      AppLang.values.every((l) => _dict[key]?.containsKey(l) ?? false);
}

extension TrContext on BuildContext {
  AppLang get lang => SettingsScope.of(this).lang;

  String tr(String key, [Map<String, Object>? params]) =>
      Strings.get(key, lang, params);
}
