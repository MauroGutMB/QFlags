import 'dart:math';
import 'dart:typed_data';

/// Cor RGB com canais de 0 a 255.
typedef Rgb = ({double r, double g, double b});

Rgb rgb(num r, num g, num b) => (r: r.toDouble(), g: g.toDouble(), b: b.toDouble());

const Rgb _white = (r: 255.0, g: 255.0, b: 255.0);

double _distance(Rgb p, Rgb q) {
  final dr = p.r - q.r, dg = p.g - q.g, db = p.b - q.b;
  return sqrt(dr * dr + dg * dg + db * db);
}

double _chroma(Rgb c) => max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));

/// Pixels RGBA (não pré-multiplicados) de uma imagem.
class RgbaImage {
  RgbaImage(this.width, this.height, this.pixels)
      : assert(pixels.length == width * height * 4);

  final int width;
  final int height;
  final Uint8List pixels;

  bool isOpaque(int x, int y) =>
      x >= 0 && y >= 0 && x < width && y < height && pixels[(y * width + x) * 4 + 3] == 255;

  Rgb colorAt(int x, int y) {
    final i = (y * width + x) * 4;
    return rgb(pixels[i], pixels[i + 1], pixels[i + 2]);
  }
}

/// Matriz 3x3 aplicada às cores (r, g, b) de cada pixel.
///
/// Todas as matrizes usadas aqui são lineares e mantêm o branco: assim o
/// brilho, a sombra e a moldura da imagem (que misturam a cor com branco
/// ou preto) continuam iguais aos da bandeira original.
class ColorMatrix {
  const ColorMatrix(this.values);

  /// Valores linha a linha.
  final List<double> values;

  static const identity = ColorMatrix([1, 0, 0, 0, 1, 0, 0, 0, 1]);

  bool get isIdentity {
    for (var i = 0; i < 9; i++) {
      if ((values[i] - identity.values[i]).abs() > 1e-9) return false;
    }
    return true;
  }

  /// Gira o matiz (mesma fórmula do `hue-rotate` do CSS).
  factory ColorMatrix.hueRotation(double degrees) {
    final a = degrees * pi / 180, c = cos(a), s = sin(a);
    return ColorMatrix([
      0.213 + c * 0.787 - s * 0.213, 0.715 - c * 0.715 - s * 0.715, 0.072 - c * 0.072 + s * 0.928,
      0.213 - c * 0.213 + s * 0.143, 0.715 + c * 0.285 + s * 0.140, 0.072 - c * 0.072 - s * 0.283,
      0.213 - c * 0.213 - s * 0.787, 0.715 - c * 0.715 + s * 0.715, 0.072 + c * 0.928 + s * 0.072,
    ]);
  }

  /// Troca os canais: [r], [g] e [b] dizem de qual canal (0, 1 ou 2) vem cada um.
  factory ColorMatrix.channels(int r, int g, int b) {
    final v = List<double>.filled(9, 0);
    v[r] = 1;
    v[3 + g] = 1;
    v[6 + b] = 1;
    return ColorMatrix(v);
  }

  /// A menor alteração da identidade que leva cada cor de [from] na cor de
  /// mesma posição em [to]. Retorna null quando as cores de [from] são
  /// quase dependentes entre si (a matriz ficaria instável).
  static ColorMatrix? mapping(List<Rgb> from, List<Rgb> to) {
    assert(from.length == to.length && from.length <= 3);
    List<double> vec(Rgb c) => [c.r / 255, c.g / 255, c.b / 255];
    final u = [for (final c in from) vec(c)];
    final v = [for (final c in to) vec(c)];
    final m = u.length;

    // L = I + (V - U) · (UᵀU)⁻¹ · Uᵀ  →  L·u = v para cada par.
    final gram = [
      for (var i = 0; i < m; i++) [for (var j = 0; j < m; j++) _dot(u[i], u[j])],
    ];
    var normProduct = 1.0;
    for (final ui in u) {
      normProduct *= _dot(ui, ui);
    }
    final inverse = _invert(gram);
    if (inverse == null || normProduct == 0 || inverse.det / normProduct < 0.02) return null;

    final values = List<double>.filled(9, 0);
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        var sum = r == c ? 1.0 : 0.0;
        for (var i = 0; i < m; i++) {
          for (var j = 0; j < m; j++) {
            sum += (v[i][r] - u[i][r]) * inverse.matrix[i][j] * u[j][c];
          }
        }
        values[r * 3 + c] = sum;
      }
    }
    if (values.any((x) => x.abs() > 6)) return null;
    return ColorMatrix(values);
  }

  Rgb apply(Rgb c) => rgb(
        values[0] * c.r + values[1] * c.g + values[2] * c.b,
        values[3] * c.r + values[4] * c.g + values[5] * c.b,
        values[6] * c.r + values[7] * c.g + values[8] * c.b,
      );

  /// No formato 4x5 do `ColorFilter.matrix` do Flutter (alfa intacto).
  List<double> toFilterMatrix() => [
        values[0], values[1], values[2], 0, 0,
        values[3], values[4], values[5], 0, 0,
        values[6], values[7], values[8], 0, 0,
        0, 0, 0, 1, 0,
      ];
}

double _dot(List<double> a, List<double> b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

/// Inversa por Gauss-Jordan, junto com o determinante.
({List<List<double>> matrix, double det})? _invert(List<List<double>> a) {
  final n = a.length;
  final m = [
    for (var i = 0; i < n; i++) [...a[i], for (var j = 0; j < n; j++) i == j ? 1.0 : 0.0],
  ];
  var det = 1.0;
  for (var col = 0; col < n; col++) {
    var pivot = col;
    for (var row = col + 1; row < n; row++) {
      if (m[row][col].abs() > m[pivot][col].abs()) pivot = row;
    }
    if (m[pivot][col].abs() < 1e-12) return null;
    if (pivot != col) {
      final tmp = m[pivot];
      m[pivot] = m[col];
      m[col] = tmp;
      det = -det;
    }
    final p = m[col][col];
    det *= p;
    for (var j = 0; j < 2 * n; j++) {
      m[col][j] /= p;
    }
    for (var row = 0; row < n; row++) {
      if (row == col) continue;
      final f = m[row][col];
      for (var j = 0; j < 2 * n; j++) {
        m[row][j] -= f * m[col][j];
      }
    }
  }
  return (matrix: [for (final row in m) row.sublist(n)], det: det);
}

/// Todas as bandeiras do conjunto têm o mesmo efeito de brilho: na linha y,
/// uma cor lisa c aparece como  a(y)·c + b(y)  (a metade de cima é clareada
/// e a de baixo, levemente escurecida). Com a(y) e b(y) dá para recuperar
/// as cores lisas de qualquer bandeira.
class GlossTemplate {
  GlossTemplate(this.a, this.b);

  final Float64List a;
  final Float64List b;

  /// Sem brilho nenhum (útil em testes).
  factory GlossTemplate.none(int height) =>
      GlossTemplate(Float64List(height)..fillRange(0, height, 1), Float64List(height));

  /// Mede o brilho numa coluna onde [black] é preta (pixel = b) e [white]
  /// é branca (pixel = 255·a + b).
  factory GlossTemplate.measure({
    required RgbaImage black,
    required RgbaImage white,
    required int column,
  }) {
    final height = black.height;
    final a = Float64List(height)..fillRange(0, height, 1);
    final b = Float64List(height);
    for (var y = 0; y < height; y++) {
      if (!black.isOpaque(column, y) || !white.isOpaque(column, y)) continue;
      final k = black.colorAt(column, y), w = white.colorAt(column, y);
      b[y] = (k.r + k.g + k.b) / 3;
      a[y] = ((w.r + w.g + w.b) / 3 - b[y]) / 255;
    }
    return GlossTemplate(a, b);
  }

  /// Cor lisa de um pixel da linha [y], ou null se o brilho ali for forte demais.
  Rgb? flatten(Rgb pixel, int y) {
    final ay = a[y], by = b[y];
    if (ay < 0.2) return null;
    double f(double v) => ((v - by) / ay).clamp(0.0, 255.0);
    return rgb(f(pixel.r), f(pixel.g), f(pixel.b));
  }
}

/// Uma cor da bandeira e a fração da área que ela ocupa.
class PaletteColor {
  const PaletteColor(this.color, this.share);

  final Rgb color;
  final double share;

  /// Branco, preto e cinzas ficam fixos nas matrizes; só as cores "de verdade" trocam.
  bool get isChromatic => _chroma(color) >= 60;
}

class _Cluster {
  _Cluster(Rgb c, this.count)
      : _r = c.r * count,
        _g = c.g * count,
        _b = c.b * count;

  double _r, _g, _b;
  int count;

  Rgb get mean => rgb(_r / count, _g / count, _b / count);

  void add(Rgb c, [int n = 1]) {
    _r += c.r * n;
    _g += c.g * n;
    _b += c.b * n;
    count += n;
  }
}

/// Cores principais da bandeira (sem o brilho), da maior área para a menor.
List<PaletteColor> extractPalette(
  RgbaImage image,
  GlossTemplate gloss, {
  double minShare = 0.02,
  double mergeDistance = 40,
}) {
  // Agrupa as cores lisas em caixas de 8 níveis por canal.
  final bins = <int, _Cluster>{};
  var total = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      // Só o miolo: a moldura tem um relevo próprio que não segue o brilho.
      if (!image.isOpaque(x, y) ||
          !image.isOpaque(x - 3, y) ||
          !image.isOpaque(x + 3, y) ||
          !image.isOpaque(x, y - 3) ||
          !image.isOpaque(x, y + 3)) {
        continue;
      }
      final flat = gloss.flatten(image.colorAt(x, y), y);
      if (flat == null) continue;
      final key = (flat.r ~/ 8) << 10 | (flat.g ~/ 8) << 5 | (flat.b ~/ 8);
      final bin = bins[key];
      bin == null ? bins[key] = _Cluster(flat, 1) : bin.add(flat);
      total++;
    }
  }
  if (total == 0) return const [];

  // Junta caixas parecidas, começando pelas mais populosas.
  final sorted = bins.values.toList()..sort((p, q) => q.count.compareTo(p.count));
  final clusters = <_Cluster>[];
  for (final bin in sorted) {
    _Cluster? nearest;
    var best = double.infinity;
    for (final c in clusters) {
      final d = _distance(c.mean, bin.mean);
      if (d < best) {
        best = d;
        nearest = c;
      }
    }
    if (nearest != null && best <= mergeDistance) {
      nearest.add(bin.mean, bin.count);
    } else {
      clusters.add(_Cluster(bin.mean, bin.count));
    }
  }

  final candidates = [
    for (final c in clusters)
      if (c.count / total >= minShare) PaletteColor(c.mean, c.count / total),
  ]..sort((p, q) => q.share.compareTo(p.share));

  // Descarta "cores" que são só a mistura de duas maiores (a borda suavizada
  // entre elas, como entre as estrelas e o azul dos EUA).
  final palette = <PaletteColor>[];
  for (final p in candidates) {
    final isBlend = palette.any(
      (a) => palette.any((b) => !identical(a, b) && _isBlend(p.color, a.color, b.color)),
    );
    if (!isBlend) palette.add(p);
  }
  return palette;
}

bool _isBlend(Rgb p, Rgb a, Rgb b) {
  final abR = b.r - a.r, abG = b.g - a.g, abB = b.b - a.b;
  final len2 = abR * abR + abG * abG + abB * abB;
  if (len2 == 0) return false;
  final t = ((p.r - a.r) * abR + (p.g - a.g) * abG + (p.b - a.b) * abB) / len2;
  if (t <= 0.05 || t >= 0.95) return false;
  return _distance(p, rgb(a.r + t * abR, a.g + t * abG, a.b + t * abB)) < 20;
}

/// Cores comuns em bandeiras, usadas para pintar uma cor da bandeira de outra.
const List<Rgb> _flagColors = [
  (r: 206.0, g: 17.0, b: 38.0), // vermelho
  (r: 0.0, g: 56.0, b: 168.0), // azul
  (r: 0.0, g: 122.0, b: 61.0), // verde
  (r: 252.0, g: 209.0, b: 22.0), // amarelo
  (r: 255.0, g: 130.0, b: 0.0), // laranja
  (r: 108.0, g: 172.0, b: 228.0), // azul-claro
  (r: 0.0, g: 0.0, b: 0.0), // preto
];

/// Escolhe [count] matrizes que deixam a bandeira com as cores erradas,
/// bem diferentes da original e entre si. Prioridade: trocar duas cores da
/// própria bandeira, depois pintar uma cor de outra, e por fim distorcer o
/// matiz ou trocar os canais RGB.
List<ColorMatrix> pickDistractors(
  RgbaImage image,
  List<PaletteColor> palette,
  Random random, {
  int count = 3,
}) {
  // Só cores com área relevante entram nas trocas (detalhes de brasão não).
  final chromatic = [
    for (final p in palette)
      if (p.isChromatic && p.share >= 0.05) p.color,
  ].take(3).toList();

  final swaps = <ColorMatrix>[];
  for (var i = 0; i < chromatic.length; i++) {
    for (var j = i + 1; j < chromatic.length; j++) {
      final m = ColorMatrix.mapping(
        [chromatic[i], chromatic[j], _white],
        [chromatic[j], chromatic[i], _white],
      );
      if (m != null) swaps.add(m);
    }
  }

  final recolors = <ColorMatrix>[];
  for (var i = 0; i < min(2, chromatic.length); i++) {
    final keep = [
      for (var j = 0; j < chromatic.length; j++)
        if (j != i) chromatic[j],
    ].take(1);
    for (final target in _flagColors) {
      // O alvo precisa ser outra cor de verdade, não um tom parecido.
      if (palette.any((p) => _perceived(p.color, target) < 230)) continue;
      final m = ColorMatrix.mapping(
        [chromatic[i], ...keep, _white],
        [target, ...keep, _white],
      );
      if (m != null) recolors.add(m);
    }
  }

  final distortions = [
    for (final degrees in const [60.0, 120.0, 180.0, 240.0, 300.0]) ColorMatrix.hueRotation(degrees),
    ColorMatrix.channels(1, 2, 0),
    ColorMatrix.channels(2, 0, 1),
    ColorMatrix.channels(0, 2, 1),
    ColorMatrix.channels(2, 1, 0),
    ColorMatrix.channels(1, 0, 2),
  ];

  swaps.shuffle(random);
  recolors.shuffle(random);
  distortions.shuffle(random);
  final candidates = [...swaps, ...recolors, ...distortions];

  // Avalia cada candidata nos pixels da bandeira (amostrados).
  final original = _samplePixels(image);
  final evaluated = <({ColorMatrix matrix, Float64List pixels, double change})>[];
  for (final m in candidates) {
    final (pixels, clipped) = _transform(original, m);
    // Muita cor estourando o limite 0–255 apaga o brilho e denuncia a falsa.
    if (clipped > 15) continue;
    evaluated.add((matrix: m, pixels: pixels, change: _difference(original, pixels)));
  }

  final picked = <({ColorMatrix matrix, Float64List pixels, double change})>[];
  for (final minChange in const [0.12, 0.06, 0.03, 0.0]) {
    for (final c in evaluated) {
      if (picked.length == count) break;
      if (picked.contains(c) || c.change <= 0 || c.change < minChange) continue;
      if (picked.any((p) => _difference(p.pixels, c.pixels) < max(minChange, 0.005))) continue;
      picked.add(c);
    }
    if (picked.length == count) break;
  }

  final result = [for (final p in picked) p.matrix];
  // Garantia: nunca devolve menos que [count].
  for (var degrees = 90.0; result.length < count; degrees += 90) {
    result.add(ColorMatrix.hueRotation(degrees));
  }
  return result;
}

/// Um a cada 2 pixels opacos em cada direção, como (r, g, b) seguidos.
Float64List _samplePixels(RgbaImage image) {
  final values = <double>[];
  for (var y = 0; y < image.height; y += 2) {
    for (var x = 0; x < image.width; x += 2) {
      if (!image.isOpaque(x, y)) continue;
      final i = (y * image.width + x) * 4;
      values
        ..add(image.pixels[i].toDouble())
        ..add(image.pixels[i + 1].toDouble())
        ..add(image.pixels[i + 2].toDouble());
    }
  }
  return Float64List.fromList(values);
}

/// Aplica a matriz e devolve os pixels resultantes e o quanto, em média,
/// cada canal passou do limite 0–255.
(Float64List, double) _transform(Float64List pixels, ColorMatrix m) {
  final v = m.values;
  final out = Float64List(pixels.length);
  var clipped = 0.0;
  for (var i = 0; i < pixels.length; i += 3) {
    final r = pixels[i], g = pixels[i + 1], b = pixels[i + 2];
    for (var k = 0; k < 3; k++) {
      final raw = v[k * 3] * r + v[k * 3 + 1] * g + v[k * 3 + 2] * b;
      final value = raw.clamp(0.0, 255.0);
      clipped += (raw - value).abs();
      out[i + k] = value;
    }
  }
  return (out, pixels.isEmpty ? 0 : clipped / pixels.length);
}

/// Fração dos pixels cuja cor mudou de forma visível.
double _difference(Float64List a, Float64List b) {
  final n = a.length ~/ 3;
  if (n == 0) return 0;
  var changed = 0;
  for (var i = 0; i < a.length; i += 3) {
    final d = _redmean(a[i], a[i + 1], a[i + 2], b[i], b[i + 1], b[i + 2]);
    if (d > 80) changed++;
  }
  return changed / n;
}

double _perceived(Rgb p, Rgb q) => _redmean(p.r, p.g, p.b, q.r, q.g, q.b);

/// Distância "redmean": aproximação barata da diferença de cor percebida.
double _redmean(double r1, double g1, double b1, double r2, double g2, double b2) {
  final rm = (r1 + r2) / 2;
  final dr = r1 - r2, dg = g1 - g2, db = b1 - b2;
  return sqrt((2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db);
}
