import 'package:flutter/painting.dart';
import '../geometry/iso.dart';

/// Clareia (amt > 0) ou escurece (amt < 0) uma cor.
Color shade(Color col, double amt) {
  final h = HSLColor.fromColor(col);
  return h
      .withLightness((h.lightness + amt).clamp(0.0, 1.0).toDouble())
      .toColor();
}

/// Hash estável por tile, para variações visuais determinísticas.
int tileHash(int x, int y) => ((x * 73856093) ^ (y * 19349663)).abs();

/// Preenche um polígono e, opcionalmente, desenha o contorno.
void fillPoly(Canvas cv, Path p, Color fill, {Color? line, double lw = 1.4}) {
  cv.drawPath(p, Paint()..color = fill);
  if (line != null) {
    cv.drawPath(
      p,
      Paint()
        ..color = ink(line)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }
}

/// Caixa isométrica (duas faces laterais e o topo) entre as alturas [z0] e [z1].
void drawBox(Canvas cv, double x, double y, double sx, double sy, double z0,
    double z1, Color col) {
  const pt = Iso.pt;
  final line = shade(col, -0.3);
  fillPoly(
      cv,
      Iso.poly([
        pt(x, y + sy, z0),
        pt(x + sx, y + sy, z0),
        pt(x + sx, y + sy, z1),
        pt(x, y + sy, z1)
      ]),
      col,
      line: line,
      lw: 1);
  fillPoly(
      cv,
      Iso.poly([
        pt(x + sx, y + sy, z0),
        pt(x + sx, y, z0),
        pt(x + sx, y, z1),
        pt(x + sx, y + sy, z1)
      ]),
      shade(col, -0.12),
      line: line,
      lw: 1);
  fillPoly(
      cv,
      Iso.poly([
        pt(x, y, z1),
        pt(x + sx, y, z1),
        pt(x + sx, y + sy, z1),
        pt(x, y + sy, z1)
      ]),
      shade(col, 0.07),
      line: line,
      lw: 1);
}

const _ink = Color(0xFF4A3A2E);

/// Suaviza uma cor de contorno: mistura com tinta marrom e reduz o alpha, como nanquim fino
/// sobre aquarela. Linhas claras (esquadrias, brilhos) ficam como estão.
Color ink(Color c) {
  if (c.computeLuminance() > .6) return c;
  return Color.lerp(c, _ink, .5)!.withValues(alpha: .8);
}
