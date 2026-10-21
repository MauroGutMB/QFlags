import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../models/country.dart';
import 'flag_colors.dart';

/// Gera as versões de cores falsas de uma bandeira para o modo Memória.
class FlagLooks {
  FlagLooks._();
  static final instance = FlagLooks._();

  GlossTemplate? _gloss;

  /// 3 matrizes que deixam a bandeira de [country] com as cores erradas.
  Future<List<ColorMatrix>> distractorsFor(Country country, Random random) async {
    final gloss = _gloss ??= await _measureGloss();
    final image = await _decode(country.flagAsset);
    return pickDistractors(image, extractPalette(image, gloss), random);
  }

  /// O brilho é o mesmo em todas as bandeiras do conjunto; medimos na coluna
  /// 20, onde a Bélgica é preta e o Japão é branco.
  Future<GlossTemplate> _measureGloss() async => GlossTemplate.measure(
        black: await _decode('assets/flags/be.png'),
        white: await _decode('assets/flags/jp.png'),
        column: 20,
      );

  Future<RgbaImage> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    final result = RgbaImage(image.width, image.height, bytes!.buffer.asUint8List());
    image.dispose();
    codec.dispose();
    return result;
  }
}
