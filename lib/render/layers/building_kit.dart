import 'dart:math';
import 'package:flutter/painting.dart';
import '../../domain/map_item.dart';
import '../../geometry/iso.dart';
import '../draw_helpers.dart';

/// Medidas de uma construção e conversões das faces para a tela.
/// Face esquerda: ao longo de x, em y+depth. Face direita: ao longo de y (de frente para trás), em x+width.
class Geo {
  Geo(this.b)
      : x = b.x.toDouble(),
        y = b.y.toDouble(),
        w = b.width.toDouble(),
        d = b.depth.toDouble(),
        h = Iso.height(b);

  /// Caixa arbitrária (partes de uma construção maior), mantendo o [b] original.
  Geo.box(this.b, this.x, this.y, this.w, this.d, this.h);

  final Building b;
  final double x, y, w, d, h;

  Offset left(double u, double z) => Iso.pt(x + u, y + d, z);
  Offset right(double u, double z) => Iso.pt(x + w, y + d - u, z);

  Path leftFace([double z0 = 0, double? z1]) =>
      Iso.poly([left(0, z0), left(w, z0), left(w, z1 ?? h), left(0, z1 ?? h)]);
  Path rightFace([double z0 = 0, double? z1]) => Iso.poly(
      [right(0, z0), right(d, z0), right(d, z1 ?? h), right(0, z1 ?? h)]);
}

/// Cor de parede/pedra: mistura [base] com cinza para parecer pedra.
Color stoneOf(Color base,
        {double amount = .7, Color tone = const Color(0xFFC9C5BC)}) =>
    Color.lerp(base, tone, amount)!;

final Paint _outline = Paint()
  ..style = PaintingStyle.stroke
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

Paint outline(Color c, [double w = 1.2]) => _outline
  ..color = ink(c)
  ..strokeWidth = w;

/// Preenche um polígono com degradê vertical sutil (mais claro em cima) e contorno.
void shadedFace(Canvas cv, Path p, Color base,
    {Color? line, double lw = 1.2, double top = .06, double bottom = -.07}) {
  final r = p.getBounds();
  cv.drawPath(
    p,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [shade(base, top), shade(base, bottom)],
      ).createShader(r),
  );
  if (line != null) cv.drawPath(p, outline(line, lw));
}

/// Sombra de contato escura na base de uma face (dá peso à construção).
void groundContact(Canvas cv, Geo g) {
  final p = Iso.poly([
    g.left(0, 0),
    g.left(g.w, 0),
    g.right(0, 0),
    g.right(g.d, 0),
    g.right(g.d, -1),
    g.left(g.w, -3),
    g.left(0, -1)
  ]);
  cv.drawPath(p, Paint()..color = const Color.fromRGBO(0, 0, 0, 0.10));
}

enum WallTexture { plain, brick, timber, stone, planks, glass, panels }

/// Desenha linhas de textura nas duas faces.
void wallTexture(Canvas cv, Geo g, WallTexture t, Color wall,
    {double z0 = 0, double? z1}) {
  final top = z1 ?? g.h;
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = shade(wall, -.12);
  void faceLines(
      Offset Function(double, double) f, double len, bool rightSide) {
    switch (t) {
      case WallTexture.plain:
        break;
      case WallTexture.brick:
        var row = 0;
        for (var z = z0 + 5; z < top; z += 5, row++) {
          cv.drawLine(f(0, z), f(len, z), line);
        }
        row = 0;
        for (var z = z0; z < top; z += 5, row++) {
          for (var u = (row.isEven ? .0 : .08); u < len; u += .16) {
            cv.drawLine(f(u, z), f(u, min(z + 5, top)),
                line..color = shade(wall, -.08));
          }
        }
      case WallTexture.stone:
        var row = 0;
        for (var z = z0 + 7; z < top; z += 7, row++) {
          cv.drawLine(f(0, z), f(len, z), line);
        }
        row = 0;
        for (var z = z0; z < top; z += 7, row++) {
          for (var u = (row.isEven ? .1 : .27); u < len; u += .34) {
            cv.drawLine(f(u, z), f(u, min(z + 7, top)), line);
          }
        }
      case WallTexture.planks:
        for (var u = .12; u < len; u += .12) {
          cv.drawLine(f(u, z0), f(u, top), line..color = shade(wall, -.1));
        }
      case WallTexture.timber:
        final beam = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF6B4A33);
        final floors = max(1, ((top - z0) / Iso.floorH).round());
        final fh = (top - z0) / floors;
        for (var fl = 0; fl <= floors; fl++) {
          cv.drawLine(f(0, z0 + fl * fh), f(len, z0 + fl * fh), beam);
        }
        for (var u = 0.0; u <= len + .01; u += 1) {
          cv.drawLine(f(u, z0), f(u, top), beam);
        }
        for (var fl = 0; fl < floors; fl++) {
          for (var u = 0.0; u < len - .2; u += 1) {
            final a = f(u, z0 + fl * fh), b2 = f(u + 1, z0 + (fl + 1) * fh);
            cv.drawLine(a, b2, beam..strokeWidth = 1.4);
          }
        }
      case WallTexture.glass:
        final floors = max(1, ((top - z0) / Iso.floorH).round());
        final fh = (top - z0) / floors;
        for (var fl = 0; fl < floors; fl++) {
          final za = z0 + fl * fh + 3, zb = z0 + (fl + 1) * fh - 3;
          final q = Iso.poly(
              [f(.04, za), f(len - .04, za), f(len - .04, zb), f(.04, zb)]);
          cv.drawPath(
              q, Paint()..color = shade(wall, .1).withValues(alpha: .55));
          cv.drawLine(
              f(.04, zb),
              f(len * .6, zb),
              Paint()
                ..color = const Color(0x55FFFFFF)
                ..strokeWidth = 1.4);
        }
        for (var u = 0.0; u <= len + .01; u += .5) {
          cv.drawLine(f(u, z0), f(u, top), line..color = shade(wall, -.2));
        }
      case WallTexture.panels:
        for (var z = z0 + Iso.floorH; z < top - .1; z += Iso.floorH) {
          cv.drawLine(f(0, z), f(len, z), line..color = shade(wall, -.1));
        }
        for (var u = 1.0; u < len; u += 1) {
          cv.drawLine(f(u, z0), f(u, top), line..color = shade(wall, -.07));
        }
    }
  }

  faceLines(g.left, g.w, false);
  faceLines(g.right, g.d, true);
}

enum WindowStyle { rect, arched, shuttered, slit, strip }

/// Janelas em todos os andares das duas faces. [skipDoorAt] pula o tile da porta no térreo.
void windows(
  Canvas cv,
  Geo g, {
  WindowStyle style = WindowStyle.rect,
  int? skipDoorAt,
  Color glass = const Color(0xFFA9DCEB),
  Color rightGlass = const Color(0xFF8FC6D8),
  Color frame = const Color(0xFFFFF8EA),
  Color shutter = const Color(0xFF5E7FA8),
  double zOffset = 9,
  double height = 11,
  int firstFloor = 0,
  int? lastFloor,
}) {
  const fh = Iso.floorH;
  void one(
      Offset Function(double, double) f, double uc, double z0, Color fill) {
    final hw = style == WindowStyle.slit
        ? .07
        : (style == WindowStyle.strip ? .4 : .17);
    final z1 = z0 + height;
    final pts = <Offset>[f(uc - hw, z0), f(uc + hw, z0), f(uc + hw, z1)];
    if (style == WindowStyle.arched || style == WindowStyle.slit) {
      pts.add(f(uc + hw, z1 + 2));
      pts.add(f(uc, z1 + 4.5));
      pts.add(f(uc - hw, z1 + 2));
    }
    pts.add(f(uc - hw, z1));
    final path = Iso.poly(pts);
    if (style == WindowStyle.shuttered) {
      for (final sgn in [-1, 1]) {
        final a = uc + sgn * (hw + .02), bq = uc + sgn * (hw + .11);
        cv.drawPath(Iso.poly([f(a, z0), f(bq, z0), f(bq, z1), f(a, z1)]),
            Paint()..color = shutter);
      }
    }
    cv.drawPath(path, Paint()..color = fill);
    cv.drawPath(path, outline(frame, 1.3));
    if (style == WindowStyle.rect ||
        style == WindowStyle.shuttered ||
        style == WindowStyle.arched) {
      cv.drawLine(f(uc, z0), f(uc, z1), outline(frame, .8));
    }
  }

  for (var fl = firstFloor; fl < (lastFloor ?? g.b.floors); fl++) {
    final z0 = fl * fh + zOffset;
    for (var i = 0; i < g.b.width; i++) {
      if (fl == 0 && i == skipDoorAt) continue;
      one(g.left, i + .5, z0, glass);
    }
    for (var i = 0; i < g.b.depth; i++) {
      one(g.right, i + .5, z0, rightGlass);
    }
  }
}

/// Porta na face esquerda, no tile [tileIndex].
void door(Canvas cv, Geo g, int tileIndex,
    {Color color = const Color(0xFF8A5A3C),
    bool arched = true,
    double hgt = 19,
    double halfW = .2}) {
  final uc = tileIndex + .5;
  final pts = <Offset>[
    g.left(uc - halfW, 0),
    g.left(uc + halfW, 0),
    g.left(uc + halfW, hgt)
  ];
  if (arched) {
    pts.add(g.left(uc + halfW * .6, hgt + 3));
    pts.add(g.left(uc, hgt + 4.5));
    pts.add(g.left(uc - halfW * .6, hgt + 3));
  }
  pts.add(g.left(uc - halfW, hgt));
  final p = Iso.poly(pts);
  cv.drawPath(p, Paint()..color = color);
  cv.drawPath(p, outline(shade(color, -.28), 1.2));
  cv.drawCircle(g.left(uc + halfW * .5, hgt * .45), 1,
      Paint()..color = const Color(0xFFF2C94C));
}

/// Cilindro vertical com sombreamento horizontal, centrado em ([cx], [cy]) da grade, raio em tiles.
void cylinder(Canvas cv, double cx, double cy, double radius, double z0,
    double z1, Color base,
    {Color? line, bool cap = true, double capShade = .08, double courses = 0}) {
  final c0 = Iso.pt(cx, cy, z0), c1 = Iso.pt(cx, cy, z1);
  final (rx, ry) = Iso.ellipse(radius);
  final body = Path()
    ..moveTo(c0.dx - rx, c0.dy)
    ..lineTo(c1.dx - rx, c1.dy)
    ..arcTo(Rect.fromCenter(center: c1, width: rx * 2, height: ry * 2), pi, -pi,
        false)
    ..lineTo(c0.dx + rx, c0.dy)
    ..arcTo(Rect.fromCenter(center: c0, width: rx * 2, height: ry * 2), 0, pi,
        false)
    ..close();
  cv.drawPath(
    body,
    Paint()
      ..shader = LinearGradient(
              colors: [shade(base, .09), base, shade(base, -.14)],
              stops: const [0, .45, 1])
          .createShader(Rect.fromLTRB(c0.dx - rx, c1.dy, c0.dx + rx, c0.dy)),
  );
  final edge = line ?? shade(base, -.3);
  cv.drawPath(body, outline(edge, 1.2));
  if (courses > 0) {
    final joint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = shade(base, -.14);
    for (var z = z0 + courses; z < z1 - 1; z += courses) {
      cv.drawArc(
          Rect.fromCenter(
              center: Iso.pt(cx, cy, z), width: rx * 2, height: ry * 2),
          0,
          pi,
          false,
          joint);
    }
  }
  if (cap) {
    final top = Rect.fromCenter(center: c1, width: rx * 2, height: ry * 2);
    cv.drawOval(top, Paint()..color = shade(base, capShade));
    cv.drawOval(top, outline(edge, 1.2));
  }
}

/// Cone sobre um cilindro (telhado de torre).
void cone(Canvas cv, double cx, double cy, double radius, double z0,
    double rise, Color base,
    {Color? line}) {
  final c0 = Iso.pt(cx, cy, z0), apex = Iso.pt(cx, cy, z0 + rise);
  final (rx, ry) = Iso.ellipse(radius);
  final p = Path()
    ..moveTo(c0.dx - rx, c0.dy)
    ..lineTo(apex.dx, apex.dy)
    ..lineTo(c0.dx + rx, c0.dy)
    ..arcTo(Rect.fromCenter(center: c0, width: rx * 2, height: ry * 2), 0, pi,
        false)
    ..close();
  cv.drawPath(
    p,
    Paint()
      ..shader = LinearGradient(
              colors: [shade(base, .1), base, shade(base, -.16)],
              stops: const [0, .45, 1])
          .createShader(
              Rect.fromLTRB(c0.dx - rx, apex.dy, c0.dx + rx, c0.dy + ry)),
  );
  cv.drawPath(p, outline(line ?? shade(base, -.3), 1.2));
}

/// Coroa de ameias em volta do topo de uma torre redonda (castelo, muralha).
void crown(
    Canvas cv, double cx, double cy, double radius, double z, Color stone) {
  cylinder(cv, cx, cy, radius + .06, z, z + 3, shade(stone, .04));
  for (var i = 0; i < 8; i++) {
    final a = i * pi / 4;
    drawBox(cv, cx + cos(a) * radius - .05, cy + sin(a) * radius - .05, .1, .1,
        z + 3, z + 8, stone);
  }
}

/// Ameias (merlões) ao longo de uma aresta horizontal entre dois pontos da grade.
void crenels(Canvas cv, double x0, double y0, double x1, double y1, double z,
    Color stone,
    {int count = 5}) {
  for (var i = 0; i < count; i++) {
    final t = (i + .5) / count;
    final px = x0 + (x1 - x0) * t, py = y0 + (y1 - y0) * t;
    drawBox(cv, px - .06, py - .06, .12, .12, z, z + 5, stone);
  }
}

/// Bandeira que balança com o vento (animada por [time]).
void flag(Canvas cv, Offset base, double poleHeight, Color color, double time,
    {double phase = 0}) {
  final top = base.translate(0, -poleHeight);
  cv.drawLine(base, top, outline(const Color(0xFF5A4636), 1.6));
  final w = sin(time * 3 + phase) * 2.5;
  final p = Path()
    ..moveTo(top.dx, top.dy)
    ..quadraticBezierTo(
        top.dx + 8, top.dy + 1 + w, top.dx + 16, top.dy + 3 + w * 1.4)
    ..lineTo(top.dx + 15, top.dy + 10 + w)
    ..quadraticBezierTo(top.dx + 8, top.dy + 9 + w * .6, top.dx, top.dy + 9)
    ..close();
  cv.drawPath(p, Paint()..color = color);
  cv.drawPath(p, outline(shade(color, -.3), 1));
}
