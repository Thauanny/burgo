import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../../domain/map_item.dart';
import '../../geometry/iso.dart';
import '../draw_helpers.dart';
import 'building_kit.dart' show outline;

/// Medidas de uma construção em tiles/alturas, calculadas uma vez para o telhado.
class RoofGeometry {
  RoofGeometry(this.b, {this.style = RoofStyle.tile, this.gableWall})
      : x = b.x.toDouble(),
        y = b.y.toDouble(),
        w = b.width.toDouble(),
        d = b.depth.toDouble(),
        h = Iso.height(b),
        rise = Iso.roofRise(b);

  final Building b;
  final double x, y, w, d, h, rise;

  /// Material do telhado (muda só a textura).
  final RoofStyle style;

  /// Cor da parede do oitão (triângulo da empena); por padrão a da construção.
  final Color? gableWall;

  /// Beiral que passa da parede.
  static const double eave = .16;

  Color get roofLine => shade(b.roofColor, -0.28);
  Color get wallLine => shade(b.wall, -0.3);
}

/// Fileiras de telhas entre a aresta do beiral ([a]→[b]) e a cumeeira ([c]←[d] pareadas a→c, b→d).
void shingleRows(Canvas cv, Offset a, Offset b, Offset c, Offset d, Color roof,
    {int rows = 4}) {
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = shade(roof, -.1);
  for (var i = 1; i < rows; i++) {
    final t = i / rows;
    cv.drawLine(Offset.lerp(a, c, t)!, Offset.lerp(b, d, t)!, line);
  }
}


/// Material de cobertura: só muda a textura desenhada sobre a água do telhado.
enum RoofStyle { tile, thatch, slate }

Offset _q(Offset a, Offset b, Offset c, Offset d, double u, double v) =>
    Offset.lerp(Offset.lerp(a, b, u)!, Offset.lerp(c, d, u)!, v)!;

/// Textura de uma água de telhado. [a]→[b] é o beiral e [c]/[d] a cumeeira (a→c, b→d).
void roofSurface(Canvas cv, Offset a, Offset b, Offset c, Offset d, Color roof,
    RoofStyle style,
    {int rows = 5}) {
  final len = (b - a).distance;
  switch (style) {
    case RoofStyle.tile:
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = shade(roof, -.16);
      final cols = max(3, (len / 11).round());
      for (var r = 0; r < rows; r++) {
        final v0 = r / rows, v1 = (r + 1) / rows;
        if (r > 0) cv.drawLine(_q(a, b, c, d, 0, v0), _q(a, b, c, d, 1, v0), line);
        for (var k = 0; k <= cols; k++) {
          final u = (k + (r.isEven ? 0 : .5)) / cols;
          if (u > 1) continue;
          cv.drawLine(_q(a, b, c, d, u, v0), _q(a, b, c, d, u, v1),
              line..color = shade(roof, -.1));
        }
      }
      // cumeeira
      cv.drawLine(
          c, d, outline(shade(roof, -.22), 2.6)..strokeCap = StrokeCap.round);
    case RoofStyle.slate:
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = shade(roof, -.2);
      final cols = max(4, (len / 8).round());
      for (var r = 1; r < rows + 2; r++) {
        final v = r / (rows + 2);
        cv.drawLine(_q(a, b, c, d, 0, v), _q(a, b, c, d, 1, v), line);
      }
      for (var r = 0; r < rows + 2; r++) {
        final v0 = r / (rows + 2), v1 = (r + 1) / (rows + 2);
        for (var k = 0; k <= cols; k++) {
          final u = (k + (r.isEven ? 0 : .5)) / cols;
          if (u > 1) continue;
          cv.drawLine(_q(a, b, c, d, u, v0), _q(a, b, c, d, u, v1), line);
        }
      }
      cv.drawLine(c, d, outline(shade(roof, -.3), 2.4));
    case RoofStyle.thatch:
      // palha: feixes finos e irregulares, franja grossa no beiral e cumeeira amarrada
      final strands = max(10, (len / 4).round());
      for (var k = 0; k < strands; k++) {
        final u = (k + .5 + ((k * 37) % 7 - 3) * .06) / strands;
        final v1 = .55 + ((k * 53) % 9) / 22;
        cv.drawLine(
            _q(a, b, c, d, u.clamp(0, 1), .02),
            _q(a, b, c, d, (u + .015).clamp(0, 1), v1),
            Paint()
              ..strokeWidth = 1
              ..color = (k.isEven ? shade(roof, -.18) : shade(roof, .12))
                  .withValues(alpha: .7));
      }
      for (var r = 1; r < 4; r++) {
        cv.drawLine(
            _q(a, b, c, d, 0, r / 4.5),
            _q(a, b, c, d, 1, r / 4.5),
            Paint()
              ..strokeWidth = .8
              ..color = shade(roof, -.12).withValues(alpha: .55));
      }
      final fringe = Paint()
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = shade(roof, -.2);
      final n = max(8, (len / 3.5).round());
      for (var k = 0; k <= n; k++) {
        final p0 = _q(a, b, c, d, k / n, 0);
        cv.drawLine(p0, p0.translate(0, 3 + (k * 5 % 4)), fringe);
      }
      cv.drawLine(c, d, outline(shade(roof, -.3), 3.2));
  }
}

typedef RoofPainter = void Function(Canvas cv, RoofGeometry g);

/// Um desenhista por formato de telhado. Novo formato = nova entrada aqui.
final Map<RoofType, RoofPainter> roofPainters = {
  RoofType.flat: _flat,
  RoofType.pyramid: _pyramid,
  RoofType.gable: _gable,
};

void _flat(Canvas cv, RoofGeometry g) {
  const pt = Iso.pt;
  const e = RoofGeometry.eave;
  final (x, y, w, d, h) = (g.x, g.y, g.w, g.d, g.h);
  final roof = g.b.roofColor, roofLine = g.roofLine;
  fillPoly(
      cv,
      Iso.poly([
        pt(x - e, y + d + e, h),
        pt(x + w + e, y + d + e, h),
        pt(x + w + e, y + d + e, h - 5),
        pt(x - e, y + d + e, h - 5)
      ]),
      shade(roof, -0.12),
      line: roofLine);
  fillPoly(
      cv,
      Iso.poly([
        pt(x + w + e, y + d + e, h),
        pt(x + w + e, y - e, h),
        pt(x + w + e, y - e, h - 5),
        pt(x + w + e, y + d + e, h - 5)
      ]),
      shade(roof, -0.2),
      line: roofLine);
  fillPoly(
      cv,
      Iso.poly([
        pt(x - e, y - e, h),
        pt(x + w + e, y - e, h),
        pt(x + w + e, y + d + e, h),
        pt(x - e, y + d + e, h)
      ]),
      shade(roof, 0.08),
      line: roofLine);
  if (g.b.floors >= 3) {
    drawBox(cv, x + .3, y + .3, .35, .35, h, h + 8, const Color(0xFFB8BEC6));
  }
}

/// Visão de cima: o telhado inteiro aparece (os dois lados), não só as faces voltadas para a câmera isométrica.
void _pyramidTop(Canvas cv, RoofGeometry g) {
  const pt = Iso.pt;
  const e = RoofGeometry.eave;
  final (x, y, w, d, h) = (g.x, g.y, g.w, g.d, g.h);
  final roof = g.b.roofColor, line = g.roofLine;
  final apex = pt(x + w / 2, y + d / 2, h + g.rise);
  final a = pt(x - e, y - e, h),
      b = pt(x + w + e, y - e, h),
      c = pt(x + w + e, y + d + e, h),
      dd = pt(x - e, y + d + e, h);
  fillPoly(cv, Iso.poly([dd, c, apex]), shade(roof, -.02), line: line);
  fillPoly(cv, Iso.poly([c, b, apex]), shade(roof, -.14), line: line);
  fillPoly(cv, Iso.poly([b, a, apex]), shade(roof, -.22), line: line);
  fillPoly(cv, Iso.poly([a, dd, apex]), shade(roof, -.08), line: line);
  shingleRows(cv, dd, c, apex, apex, roof, rows: 4);
  shingleRows(cv, a, dd, apex, apex, shade(roof, -.08), rows: 4);
}

void _gableTop(Canvas cv, RoofGeometry g) {
  const pt = Iso.pt;
  const e = RoofGeometry.eave;
  final (x, y, w, d, h, rise) = (g.x, g.y, g.w, g.d, g.h, g.rise);
  final b = g.b, roof = b.roofColor, line = g.roofLine;
  const chimneyColor = Color(0xFFB5654F);
  if (b.width >= b.depth) {
    final ym = y + d / 2;
    final front = [
      pt(x - e, y + d + e, h),
      pt(x + w + e, y + d + e, h),
      pt(x + w + e, ym, h + rise),
      pt(x - e, ym, h + rise)
    ];
    final back = [
      pt(x - e, y - e, h),
      pt(x + w + e, y - e, h),
      pt(x + w + e, ym, h + rise),
      pt(x - e, ym, h + rise)
    ];
    fillPoly(cv, Iso.poly(back), shade(roof, -.2), line: line);
    fillPoly(cv, Iso.poly(front), roof, line: line);
    shingleRows(cv, front[0], front[1], front[3], front[2], roof, rows: 4);
    shingleRows(cv, back[0], back[1], back[3], back[2], shade(roof, -.2),
        rows: 4);
    if (b.chimney) {
      drawBox(cv, x + w * .3, ym - .11, .22, .22, h + rise - 6, h + rise + 10,
          chimneyColor);
    }
  } else {
    final xm = x + w / 2;
    final left = [
      pt(x - e, y - e, h),
      pt(x - e, y + d + e, h),
      pt(xm, y + d + e, h + rise),
      pt(xm, y - e, h + rise)
    ];
    final right = [
      pt(x + w + e, y - e, h),
      pt(x + w + e, y + d + e, h),
      pt(xm, y + d + e, h + rise),
      pt(xm, y - e, h + rise)
    ];
    fillPoly(cv, Iso.poly(left), roof, line: line);
    fillPoly(cv, Iso.poly(right), shade(roof, -.2), line: line);
    shingleRows(cv, left[0], left[1], left[3], left[2], roof, rows: 4);
    shingleRows(cv, right[0], right[1], right[3], right[2], shade(roof, -.2),
        rows: 4);
    if (b.chimney) {
      drawBox(cv, xm - .11, y + d * .3, .22, .22, h + rise - 6, h + rise + 10,
          chimneyColor);
    }
  }
}

void _pyramid(Canvas cv, RoofGeometry g) {
  if (Iso.isTopDown) return _pyramidTop(cv, g);
  const pt = Iso.pt;
  const e = RoofGeometry.eave;
  final (x, y, w, d, h) = (g.x, g.y, g.w, g.d, g.h);
  final roof = g.b.roofColor, roofLine = g.roofLine;
  final apex = pt(x + w / 2, y + d / 2, h + g.rise);
  fillPoly(
      cv,
      Iso.poly([pt(x - e, y + d + e, h), pt(x + w + e, y + d + e, h), apex]),
      roof,
      line: roofLine);
  fillPoly(
      cv,
      Iso.poly([pt(x + w + e, y + d + e, h), pt(x + w + e, y - e, h), apex]),
      shade(roof, -0.12),
      line: roofLine);
  roofSurface(cv, pt(x - e, y + d + e, h), pt(x + w + e, y + d + e, h), apex,
      apex, roof, g.style,
      rows: 5);
  roofSurface(cv, pt(x + w + e, y + d + e, h), pt(x + w + e, y - e, h), apex,
      apex, shade(roof, -.1), g.style,
      rows: 5);
}

void _gable(Canvas cv, RoofGeometry g) {
  if (Iso.isTopDown) return _gableTop(cv, g);
  const pt = Iso.pt;
  const e = RoofGeometry.eave;
  final (x, y, w, d, h, rise) = (g.x, g.y, g.w, g.d, g.h, g.rise);
  final b = g.b, roof = b.roofColor, wall = g.gableWall ?? b.wall;
  final roofLine = g.roofLine, wallLine = g.wallLine;
  const chimneyColor = Color(0xFFB5654F);
  if (b.width >= b.depth) {
    final ym = y + d / 2;
    final r1 = pt(x - e, ym, h + rise), r2 = pt(x + w + e, ym, h + rise);
    fillPoly(
        cv,
        Iso.poly(
            [pt(x + w, y + d, h), pt(x + w, y, h), pt(x + w, ym, h + rise)]),
        shade(wall, -0.1),
        line: wallLine);
    fillPoly(
        cv,
        Iso.poly(
            [pt(x - e, y + d + e, h), pt(x + w + e, y + d + e, h), r2, r1]),
        roof,
        line: roofLine);
    roofSurface(cv, pt(x - e, y + d + e, h), pt(x + w + e, y + d + e, h), r1,
        r2, roof, g.style);
    if (b.chimney) {
      drawBox(cv, x + w * .3, ym - .11, .22, .22, h + rise - 6, h + rise + 10,
          chimneyColor);
    }
  } else {
    final xm = x + w / 2;
    final r1 = pt(xm, y - e, h + rise), r2 = pt(xm, y + d + e, h + rise);
    fillPoly(
        cv,
        Iso.poly(
            [pt(x, y + d, h), pt(x + w, y + d, h), pt(xm, y + d, h + rise)]),
        wall,
        line: wallLine);
    fillPoly(
        cv,
        Iso.poly(
            [pt(x + w + e, y + d + e, h), pt(x + w + e, y - e, h), r1, r2]),
        shade(roof, -0.1),
        line: roofLine);
    roofSurface(cv, pt(x + w + e, y + d + e, h), pt(x + w + e, y - e, h), r2,
        r1, shade(roof, -.1), g.style);
    if (b.chimney) {
      drawBox(cv, xm - .11, y + d * .3, .22, .22, h + rise - 6, h + rise + 10,
          chimneyColor);
    }
  }
}
