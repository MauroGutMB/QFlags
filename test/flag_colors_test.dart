import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qflags/game/flag_colors.dart';

final green = rgb(16, 148, 82);
final red = rgb(222, 16, 24);
final white = rgb(255, 255, 255);
final black = rgb(0, 0, 0);

void expectColor(Rgb actual, Rgb expected, {double tolerance = 0.5}) {
  expect(actual.r, closeTo(expected.r, tolerance));
  expect(actual.g, closeTo(expected.g, tolerance));
  expect(actual.b, closeTo(expected.b, tolerance));
}

/// Imagem opaca a partir de uma função de cor por pixel.
RgbaImage paint(int width, int height, Rgb Function(int x, int y) colorAt) {
  final pixels = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final c = colorAt(x, y);
      final i = (y * width + x) * 4;
      pixels
        ..[i] = c.r.round()
        ..[i + 1] = c.g.round()
        ..[i + 2] = c.b.round()
        ..[i + 3] = 255;
    }
  }
  return RgbaImage(width, height, pixels);
}

/// Bandeira tricolor vertical, com uma faixa de 3 px de cor misturada entre
/// a 1ª e a 2ª cor (como a borda suavizada das imagens reais).
RgbaImage tricolor(Rgb a, Rgb b, Rgb c) => paint(60, 40, (x, _) {
      if (x >= 19 && x <= 21) return rgb((a.r + b.r) / 2, (a.g + b.g) / 2, (a.b + b.b) / 2);
      return x < 20 ? a : (x < 40 ? b : c);
    });

final italy = tricolor(green, white, red);
final japan = paint(60, 40, (x, y) => (x - 30) * (x - 30) + (y - 20) * (y - 20) < 120 ? red : white);

void main() {
  group('ColorMatrix', () {
    test('mapping leva cada cor na cor pedida e mantém o branco', () {
      final swap = ColorMatrix.mapping([green, red, white], [red, green, white])!;
      expectColor(swap.apply(green), red);
      expectColor(swap.apply(red), green);
      expectColor(swap.apply(white), white);
      expectColor(swap.apply(black), black);
    });

    test('mapping recusa cores quase dependentes', () {
      expect(ColorMatrix.mapping([red, rgb(222, 18, 26), white], [green, red, white]), isNull);
    });

    test('rotação de matiz e troca de canais mantêm branco e preto', () {
      for (final m in [ColorMatrix.hueRotation(123), ColorMatrix.channels(2, 0, 1)]) {
        expectColor(m.apply(white), white, tolerance: 1);
        expectColor(m.apply(black), black);
      }
      expect(ColorMatrix.channels(0, 1, 2).isIdentity, isTrue);
      expect(ColorMatrix.hueRotation(90).isIdentity, isFalse);
    });

    test('formato do ColorFilter tem alfa intacto e sem deslocamento', () {
      final f = ColorMatrix.hueRotation(90).toFilterMatrix();
      expect(f.length, 20);
      expect([f[3], f[4], f[8], f[9], f[13], f[14]], everyElement(0));
      expect(f.sublist(15), [0, 0, 0, 1, 0]);
    });
  });

  test('GlossTemplate recupera a cor lisa sob o brilho', () {
    // Brilho da metade de cima: mistura com branco; de baixo: escurece um pouco.
    double a(int y) => y < 20 ? 0.5 + y * 0.02 : 1 - (y - 20) * 0.003;
    double b(int y) => y < 20 ? 255 * (0.5 - y * 0.02) : 0;
    Rgb gloss(Rgb c, int y) => rgb(a(y) * c.r + b(y), a(y) * c.g + b(y), a(y) * c.b + b(y));

    final template = GlossTemplate.measure(
      black: paint(30, 40, (_, y) => gloss(black, y)),
      white: paint(30, 40, (_, y) => gloss(white, y)),
      column: 10,
    );
    for (final y in [0, 10, 19, 20, 39]) {
      expectColor(template.flatten(gloss(green, y), y)!, green, tolerance: 2);
    }
  });

  group('extractPalette', () {
    test('acha as 3 cores da Itália e ignora a borda misturada', () {
      final palette = extractPalette(italy, GlossTemplate.none(italy.height));
      expect(palette.length, 3);
      final colors = palette.map((p) => p.color).toList();
      for (final expected in [green, white, red]) {
        expect(colors.any((c) => (c.r - expected.r).abs() + (c.g - expected.g).abs() < 6), isTrue);
      }
      expect(palette.where((p) => p.isChromatic).length, 2); // branco não conta
    });
  });

  group('pickDistractors', () {
    List<ColorMatrix> pick(RgbaImage image, int seed) => pickDistractors(
          image,
          extractPalette(image, GlossTemplate.none(image.height)),
          Random(seed),
        );

    test('Itália: 3 versões falsas, uma delas com verde e vermelho trocados', () {
      for (var seed = 0; seed < 10; seed++) {
        final fakes = pick(italy, seed);
        expect(fakes.length, 3);
        expect(fakes.any((m) => m.isIdentity), isFalse);
        expect(
          fakes.any((m) {
            final g = m.apply(green), r = m.apply(red);
            return (g.r - red.r).abs() < 3 && (r.g - green.g).abs() < 3;
          }),
          isTrue,
        );
      }
    });

    test('Japão (uma cor só): ainda gera 3 versões diferentes entre si', () {
      for (var seed = 0; seed < 10; seed++) {
        final fakes = pick(japan, seed);
        expect(fakes.length, 3);
        final discs = [for (final m in fakes) m.apply(red)];
        for (var i = 0; i < discs.length; i++) {
          // o disco muda de cor de verdade...
          expect((discs[i].r - red.r).abs() + (discs[i].g - red.g).abs() + (discs[i].b - red.b).abs(),
              greaterThan(80));
          // ...e o fundo continua branco.
          expectColor(fakes[i].apply(white), white, tolerance: 1);
          for (var j = i + 1; j < discs.length; j++) {
            final d = (discs[i].r - discs[j].r).abs() +
                (discs[i].g - discs[j].g).abs() +
                (discs[i].b - discs[j].b).abs();
            expect(d, greaterThan(60));
          }
        }
      }
    });
  });
}
