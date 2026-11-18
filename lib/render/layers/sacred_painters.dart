import 'dart:math';
import 'package:flutter/painting.dart';
import '../../domain/era.dart';
import '../../domain/map_item.dart';
import '../../geometry/iso.dart';
import '../draw_helpers.dart';
import 'building_kit.dart';

/// Época do lugar que está sendo desenhado. A camada de construções define antes de desenhar,
/// e a igreja muda de cara com ela (gótica na fantasia medieval, branca de torre fina no Loop).
Era buildingEra = Era.medieval;

const _gold = Color(0xFFE6C35A), _goldDark = Color(0xFFA8842C), _ink = Color(0xFF2B2A33);

Paint _f(Color c) => Paint()..color = c;
Paint _l(Color c, double w) => outline(c, w);

void _poly(Canvas cv, List<Offset> pts, Color c, {Color? line, double lw = 1.1}) {
  final p = Iso.poly(pts);
  cv.drawPath(p, _f(c));
  cv.drawPath(p, _l(line ?? shade(c, -.35), lw));
}

// ================================================================ templo do panteão
/// Símbolo do deus do templo, escolhido pelo nome (Marah, Khalmyr, Azgher, Lena, Valkaria,
/// Tanna-Toh, Lin-Wu, Allihanna, Wynna; em D&D, Lathander, Selûne, Tyr, Tymora, Mystra...).
enum _Holy { sun, heart, scales, moon, star, book, leaf, flame }

_Holy _holyOf(Building b) {
  final n = b.name.toLowerCase();
  if (n.contains('marah') || n.contains('lena') || n.contains('donzela')) return _Holy.heart;
  if (n.contains('khalmyr') || n.contains('tyr') || n.contains('justi')) return _Holy.scales;
  if (n.contains('azgher') || n.contains('lathander') || n.contains('sol')) return _Holy.sun;
  if (n.contains('selûne') || n.contains('selune') || n.contains('lua') || n.contains('tenebra')) return _Holy.moon;
  if (n.contains('valkaria') || n.contains('wynna') || n.contains('mystra') || n.contains('arcan')) return _Holy.star;
  if (n.contains('tanna') || n.contains('oghma') || n.contains('saber') || n.contains('bibliot')) return _Holy.book;
  if (n.contains('allihanna') || n.contains('silvanus') || n.contains('chauntea') || n.contains('floresta')) return _Holy.leaf;
  if (n.contains('thyatis') || n.contains('kossuth') || n.contains('fogo') || n.contains('mausol') || n.contains('tumba')) return _Holy.flame;
  return _Holy.values[b.id % _Holy.values.length];
}

void _holySymbol(Canvas cv, Offset c, double r, _Holy h) {
  final gold = _f(_gold), line = _l(_goldDark, .9);
  switch (h) {
    case _Holy.sun:
      for (var i = 0; i < 12; i++) {
        final a = i * pi / 6;
        cv.drawLine(c.translate(cos(a) * r * .55, sin(a) * r * .55), c.translate(cos(a) * r, sin(a) * r), _l(_gold, 1.4));
      }
      cv.drawCircle(c, r * .5, gold);
      cv.drawCircle(c, r * .5, line);
    case _Holy.heart:
      final p = Path()
        ..moveTo(c.dx, c.dy + r * .8)
        ..cubicTo(c.dx - r * 1.2, c.dy - r * .1, c.dx - r * .5, c.dy - r * .95, c.dx, c.dy - r * .35)
        ..cubicTo(c.dx + r * .5, c.dy - r * .95, c.dx + r * 1.2, c.dy - r * .1, c.dx, c.dy + r * .8)
        ..close();
      cv.drawPath(p, _f(const Color(0xFFE0707A)));
      cv.drawPath(p, line);
    case _Holy.scales:
      cv.drawLine(c.translate(0, -r * .9), c.translate(0, r * .8), _l(_gold, 1.4));
      cv.drawLine(c.translate(-r, -r * .5), c.translate(r, -r * .5), _l(_gold, 1.4));
      for (final d in [-1.0, 1.0]) {
        cv.drawArc(Rect.fromCenter(center: c.translate(d * r * .8, r * .05), width: r * .8, height: r * .6), 0, pi, true, gold);
      }
    case _Holy.moon:
      final p = Path.combine(PathOperation.difference, Path()..addOval(Rect.fromCircle(center: c, radius: r * .8)),
          Path()..addOval(Rect.fromCircle(center: c.translate(r * .35, -r * .2), radius: r * .7)));
      cv.drawPath(p, _f(const Color(0xFFE8ECF4)));
      cv.drawPath(p, _l(const Color(0xFF8E98AC), .9));
    case _Holy.star:
      final p = Path();
      for (var i = 0; i < 10; i++) {
        final a = -pi / 2 + i * pi / 5;
        final rr = i.isEven ? r : r * .42;
        final q = c.translate(cos(a) * rr, sin(a) * rr);
        i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
      }
      p.close();
      cv.drawPath(p, gold);
      cv.drawPath(p, line);
    case _Holy.book:
      cv.drawRect(Rect.fromCenter(center: c.translate(-r * .45, 0), width: r * .85, height: r * 1.2), _f(const Color(0xFFF2EAD8)));
      cv.drawRect(Rect.fromCenter(center: c.translate(r * .45, 0), width: r * .85, height: r * 1.2), _f(const Color(0xFFF2EAD8)));
      cv.drawRect(Rect.fromCenter(center: c, width: r * 1.8, height: r * 1.2), line);
      cv.drawLine(c.translate(0, -r * .6), c.translate(0, r * .6), line);
    case _Holy.leaf:
      final p = Path()
        ..moveTo(c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - r * 1.1, c.dy, c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + r * 1.1, c.dy, c.dx, c.dy + r)
        ..close();
      cv.drawPath(p, _f(const Color(0xFF6DAF5A)));
      cv.drawPath(p, _l(const Color(0xFF3B6E36), .9));
      cv.drawLine(c.translate(0, r), c.translate(0, -r * .7), _l(const Color(0xFF3B6E36), .7));
    case _Holy.flame:
      final p = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + r, c.dy, c.dx + r * .4, c.dy + r * .8)
        ..quadraticBezierTo(c.dx, c.dy + r, c.dx - r * .4, c.dy + r * .8)
        ..quadraticBezierTo(c.dx - r, c.dy, c.dx, c.dy - r)
        ..close();
      cv.drawPath(p, _f(const Color(0xFFE8703A)));
      cv.drawPath(p, _l(const Color(0xFF9E3F2C), .9));
  }
}

/// Templo do panteão (Tormenta20, D&D, fantasia): escadaria de três degraus, pórtico de
/// colunas, frontão triangular com o símbolo do deus, cela de pedra com nichos e portas de
/// bronze, braseiros na entrada e, nos templos grandes, cúpula com lanterna dourada.
void paintTemple(Canvas cv, Building b, double t) {
  final x = b.x.toDouble(), y = b.y.toDouble(), w = b.width.toDouble(), d = b.depth.toDouble();
  final stone = Color.lerp(b.wall, const Color(0xFFE6DDC9), .65)!;
  final marble = Color.lerp(stone, const Color(0xFFF8F4EA), .5)!;
  final holy = _holyOf(b);
  final big = b.width >= 3 && b.depth >= 3;
  // ---- escadaria
  for (var i = 0; i < 3; i++) {
    final k = i * .07;
    drawBox(cv, x + k, y + k, w - k * 2, d - k * 2, i * 2.6, (i + 1) * 2.6, shade(stone, -.04 - i * .02));
  }
  const zb = 7.8; // topo da escadaria
  final hgt = 22.0 + b.floors * 9;
  final portico = min(.7, d * .28);
  final yF = y + d - .16; // linha das colunas
  // ---- cela (corpo do templo)
  final cx0 = x + .2, cx1 = x + w - .2, cy0 = y + .2, cy1 = y + d - portico - .12;
  final cella = Geo.box(b, cx0, cy0, cx1 - cx0, cy1 - cy0, hgt);
  shadedFace(cv, cella.leftFace(zb), stone, line: shade(stone, -.35), lw: 1.3);
  shadedFace(cv, cella.rightFace(zb), shade(stone, -.1), line: shade(stone, -.35), lw: 1.3);
  wallTexture(cv, cella, WallTexture.stone, stone);
  // nichos altos com vitral âmbar nas laterais
  for (var u = .35; u < (cy1 - cy0) - .2; u += .55) {
    final pts = [cella.right(u - .1, zb + 6), cella.right(u + .1, zb + 6), cella.right(u + .1, hgt - 9), cella.right(u, hgt - 5), cella.right(u - .1, hgt - 9)];
    _poly(cv, pts, const Color(0xFFE8B44E), line: shade(stone, -.4), lw: 1);
    cv.drawLine(cella.right(u, zb + 6), cella.right(u, hgt - 6), _l(const Color(0xFFB07A2A), .6));
  }
  // portas de bronze no fundo do pórtico
  final dc = (cx1 - cx0) / 2;
  _poly(cv, [cella.left(dc - .22, zb), cella.left(dc + .22, zb), cella.left(dc + .22, zb + 17), cella.left(dc, zb + 22), cella.left(dc - .22, zb + 17)],
      const Color(0xFF8A5A2C), line: _ink, lw: 1.2);
  cv.drawLine(cella.left(dc, zb), cella.left(dc, zb + 21), _l(const Color(0xFF5A3A1C), 1));
  for (final u in [dc - .1, dc + .1]) {
    cv.drawCircle(cella.left(u, zb + 9), 1.1, _f(_gold));
  }
  // ---- colunas do pórtico (frente) e da lateral direita
  final cols = max(4, (b.width * 2) + 1);
  for (var i = 0; i < cols; i++) {
    final u = x + .2 + (w - .4) * i / (cols - 1);
    cylinder(cv, u, yF, .075, zb, hgt, marble, courses: 0, capShade: .12);
    // capitel
    drawBox(cv, u - .1, yF - .1, .2, .2, hgt - 2.5, hgt, shade(marble, .04));
  }
  // ---- entablamento sobre tudo (friso com triglifos)
  final ex0 = x + .1, ey0 = y + .12, ew = w - .2, ed = d - .2;
  drawBox(cv, ex0, ey0, ew, ed, hgt, hgt + 6, shade(marble, -.02));
  for (var u = .18; u < ew; u += .3) {
    cv.drawLine(Iso.pt(ex0 + u, ey0 + ed, hgt + 1), Iso.pt(ex0 + u, ey0 + ed, hgt + 5), _l(shade(marble, -.3), 1.2));
  }
  final zr = hgt + 6;
  if (big) {
    // cela de teto plano com balaustrada, pequeno frontão só sobre o pórtico e cúpula no meio
    final pz0 = ey0 + ed - portico - .1;
    final rise = 6 + w * 3;
    final xm = ex0 + ew / 2;
    _poly(cv, [Iso.pt(ex0, pz0, zr), Iso.pt(ex0, ey0 + ed, zr), Iso.pt(xm, ey0 + ed, zr + rise), Iso.pt(xm, pz0, zr + rise)], shade(b.roofColor, -.12));
    _poly(cv, [Iso.pt(xm, pz0, zr + rise), Iso.pt(xm, ey0 + ed, zr + rise), Iso.pt(ex0 + ew, ey0 + ed, zr), Iso.pt(ex0 + ew, pz0, zr)], b.roofColor);
    _pediment(cv, ex0, ex0 + ew, ey0 + ed, zr, rise, marble, b.roofColor, holy);
    // cúpula de bronze esverdeado
    final dcx = (cx0 + cx1) / 2, dcy = (cy0 + cy1) / 2;
    final rad = min(w, d) * .27;
    cylinder(cv, dcx, dcy, rad, zr, zr + 9, marble, capShade: .1);
    for (var i = 0; i < 8; i++) {
      final a = pi * .1 + i * pi * .8 / 7;
      cv.drawLine(Iso.pt(dcx + cos(a) * rad, dcy + sin(a) * rad, zr + 1), Iso.pt(dcx + cos(a) * rad, dcy + sin(a) * rad, zr + 8), _l(shade(marble, -.3), .9));
    }
    final c = Iso.pt(dcx, dcy, zr + 9);
    final (rx, ry) = Iso.ellipse(rad * 1.02);
    final domeH = rad * 46;
    final dome = Path()
      ..moveTo(c.dx - rx, c.dy)
      ..cubicTo(c.dx - rx, c.dy - domeH * .7, c.dx - rx * .45, c.dy - domeH, c.dx, c.dy - domeH)
      ..cubicTo(c.dx + rx * .45, c.dy - domeH, c.dx + rx, c.dy - domeH * .7, c.dx + rx, c.dy)
      ..arcTo(Rect.fromCenter(center: c, width: rx * 2, height: ry * 2), 0, pi, false)
      ..close();
    const patina = Color(0xFF5FA08E);
    cv.drawPath(
        dome,
        Paint()
          ..shader = LinearGradient(colors: [shade(patina, .16), patina, shade(patina, -.2)])
              .createShader(Rect.fromLTRB(c.dx - rx, c.dy - domeH, c.dx + rx, c.dy)));
    cv.drawPath(dome, _l(shade(patina, -.45), 1.2));
    for (final k in [-.55, 0.0, .55]) {
      final p = Path()
        ..moveTo(c.dx + rx * k, c.dy + ry * .8 * sqrt(1 - k * k))
        ..quadraticBezierTo(c.dx + rx * k * .9, c.dy - domeH * .55, c.dx, c.dy - domeH);
      cv.drawPath(p, _l(shade(patina, -.25), .8));
    }
    // lanterna e símbolo no alto
    final top = c.translate(0, -domeH);
    cv.drawRect(Rect.fromCenter(center: top.translate(0, -4), width: 6, height: 7), _f(marble));
    cv.drawRect(Rect.fromCenter(center: top.translate(0, -4), width: 6, height: 7), _l(_ink, .8));
    cv.drawLine(top.translate(0, -8), top.translate(0, -14), _l(_goldDark, 1.4));
    _holySymbol(cv, top.translate(0, -18), 4.5, holy);
  } else {
    // telhado de duas águas (cumeeira de frente para trás), com frontão na fachada
    final rise = 7 + w * 6;
    final xm = ex0 + ew / 2;
    _poly(cv, [Iso.pt(ex0, ey0, zr), Iso.pt(ex0, ey0 + ed, zr), Iso.pt(xm, ey0 + ed, zr + rise), Iso.pt(xm, ey0, zr + rise)], shade(b.roofColor, -.12));
    _poly(cv, [Iso.pt(xm, ey0, zr + rise), Iso.pt(xm, ey0 + ed, zr + rise), Iso.pt(ex0 + ew, ey0 + ed, zr), Iso.pt(ex0 + ew, ey0, zr)], b.roofColor);
    for (var v = .3; v < ed; v += .3) {
      cv.drawLine(Iso.pt(xm, ey0 + v, zr + rise), Iso.pt(ex0 + ew, ey0 + v, zr), _l(shade(b.roofColor, -.18), .8));
    }
    _pediment(cv, ex0, ex0 + ew, ey0 + ed, zr, rise, marble, b.roofColor, holy);
    // acrotério dourado no topo do frontão
    _holySymbol(cv, Iso.pt(xm, ey0 + ed, zr + rise).translate(0, -7), 4, holy);
  }
  // ---- braseiros acesos dos dois lados da escadaria
  for (final bx in [x + .1, x + w - .1]) {
    final base = Iso.pt(bx, y + d + .05, 0);
    for (final a in [-1.0, 0.0, 1.0]) {
      cv.drawLine(base.translate(a * 3, 0), base.translate(a * 1.4, -11), _l(_ink, 1.4));
    }
    cv.drawOval(Rect.fromCenter(center: base.translate(0, -12), width: 11, height: 5), _f(const Color(0xFF5A4A3A)));
    cv.drawOval(Rect.fromCenter(center: base.translate(0, -12), width: 11, height: 5), _l(_ink, .8));
    final flame = Path()
      ..moveTo(base.dx - 4, base.dy - 13)
      ..quadraticBezierTo(base.dx - 3, base.dy - 21, base.dx, base.dy - 25)
      ..quadraticBezierTo(base.dx + 3, base.dy - 21, base.dx + 4, base.dy - 13)
      ..close();
    cv.drawPath(flame, _f(const Color(0xFFF08A3A)));
    cv.drawPath(flame.shift(const Offset(0, 3)), _f(const Color(0xFFFFE08A)));
  }
}

/// Frontão triangular na fachada (plano y = [yF]): moldura, tímpano colorido e o símbolo.
void _pediment(Canvas cv, double x0, double x1, double yF, double z, double rise, Color marble, Color accent, _Holy holy) {
  final xm = (x0 + x1) / 2;
  _poly(cv, [Iso.pt(x0, yF, z), Iso.pt(x1, yF, z), Iso.pt(xm, yF, z + rise)], marble, line: shade(marble, -.4), lw: 1.3);
  final inset = (x1 - x0) * .12;
  _poly(cv, [Iso.pt(x0 + inset, yF, z + 2), Iso.pt(x1 - inset, yF, z + 2), Iso.pt(xm, yF, z + rise - 3.5)],
      Color.lerp(accent, const Color(0xFF2F4F7A), .45)!, line: shade(marble, -.3), lw: .9);
  final c = Iso.pt(xm, yF, z + rise * .38);
  _holySymbol(cv, c, min(7.0, rise * .22), holy);
}

// ================================================================ igreja
/// Igreja: gótica nos cenários medievais; branca de madeira, com torre e flecha fina, nos
/// cenários modernos (as igrejas suecas das ilhas Mälaren e as americanas de Mercer).
void paintChurch(Canvas cv, Building b, double t) {
  if (buildingEra == Era.medieval) return _gothic(cv, b);
  _whiteChurch(cv, b);
}

/// Igreja branca: nave de tábuas pintadas, telhado íngreme escuro, janelas altas em arco,
/// torre na frente com campanário de venezianas, relógio e flecha com cruz.
void _whiteChurch(Canvas cv, Building b) {
  final g = Geo(b);
  const white = Color(0xFFF4F1EA);
  final roof = Color.lerp(b.roofColor, const Color(0xFF3E4248), .6)!;
  final hgt = g.h;
  shadedFace(cv, g.leftFace(), white, line: const Color(0xFF9A968C), lw: 1.3);
  shadedFace(cv, g.rightFace(), shade(white, -.1), line: const Color(0xFF9A968C), lw: 1.3);
  // tábuas horizontais (clapboard)
  for (var z = 4.0; z < hgt - 1; z += 3.4) {
    cv.drawLine(g.left(0, z), g.left(g.w, z), _l(const Color(0xFFD8D3C8), .6));
    cv.drawLine(g.right(0, z), g.right(g.d, z), _l(const Color(0xFFCFC9BD), .6));
  }
  // base de pedra
  _poly(cv, [g.left(0, 0), g.left(g.w, 0), g.left(g.w, 4), g.left(0, 4)], const Color(0xFFA39C90));
  _poly(cv, [g.right(0, 0), g.right(g.d, 0), g.right(g.d, 4), g.right(0, 4)], const Color(0xFF8E887C));
  // janelas altas em arco na lateral
  for (var u = .5; u < g.d - .2; u += .8) {
    _poly(cv, [g.right(u - .12, 8), g.right(u + .12, 8), g.right(u + .12, hgt - 9), g.right(u, hgt - 5), g.right(u - .12, hgt - 9)],
        const Color(0xFF9FC3D9), line: const Color(0xFF6E6A62), lw: 1);
    cv.drawLine(g.right(u, 8), g.right(u, hgt - 6), _l(white, .8));
  }
  // telhado íngreme (cumeeira de frente para trás)
  final x = b.x.toDouble(), y = b.y.toDouble(), w = b.width.toDouble(), d = b.depth.toDouble();
  final rise = 16 + w * 12;
  final xm = x + w / 2;
  const e = .12;
  _poly(cv, [Iso.pt(x - e, y - e, hgt), Iso.pt(x - e, y + d + e, hgt), Iso.pt(xm, y + d + e, hgt + rise), Iso.pt(xm, y - e, hgt + rise)], shade(roof, -.12));
  _poly(cv, [Iso.pt(xm, y - e, hgt + rise), Iso.pt(xm, y + d + e, hgt + rise), Iso.pt(x + w + e, y + d + e, hgt), Iso.pt(x + w + e, y - e, hgt)], roof);
  for (var v = .25; v < d; v += .25) {
    cv.drawLine(Iso.pt(xm, y + v, hgt + rise), Iso.pt(x + w + e, y + v, hgt), _l(shade(roof, -.2), .7));
  }
  // empena da fachada (frente), branca
  _poly(cv, [Iso.pt(x, y + d, hgt), Iso.pt(x + w, y + d, hgt), Iso.pt(xm, y + d, hgt + rise - 2)], white, line: const Color(0xFF9A968C), lw: 1.2);
  final rose = Iso.pt(xm, y + d, hgt + rise * .35);
  cv.drawCircle(rose, 4, _f(const Color(0xFF9FC3D9)));
  cv.drawCircle(rose, 4, _l(const Color(0xFF6E6A62), 1));
  // torre na frente, no meio da fachada
  const tw = .62;
  final tx = xm - tw / 2, ty = y + d - tw * .6;
  final th = hgt + rise * .55 + 14;
  final tower = Geo.box(b, tx, ty, tw, tw, th);
  shadedFace(cv, tower.leftFace(), white, line: const Color(0xFF9A968C), lw: 1.3);
  shadedFace(cv, tower.rightFace(), shade(white, -.1), line: const Color(0xFF9A968C), lw: 1.3);
  for (var z = 4.0; z < th - 1; z += 3.4) {
    cv.drawLine(tower.left(0, z), tower.left(tw, z), _l(const Color(0xFFD8D3C8), .5));
  }
  // porta da frente na torre, com degraus
  drawBox(cv, tx - .05, ty + tw - .02, tw + .1, .14, 0, 2.4, const Color(0xFFA39C90));
  _poly(cv, [tower.left(tw / 2 - .14, 0), tower.left(tw / 2 + .14, 0), tower.left(tw / 2 + .14, 15), tower.left(tw / 2, 19), tower.left(tw / 2 - .14, 15)],
      const Color(0xFF7A3A2E), line: _ink, lw: 1.1);
  // relógio
  final clock = tower.left(tw / 2, th - 22);
  cv.drawCircle(clock, 4.6, _f(const Color(0xFFFFFDF5)));
  cv.drawCircle(clock, 4.6, _l(_ink, 1));
  cv.drawLine(clock, clock.translate(0, -3), _l(_ink, .8));
  cv.drawLine(clock, clock.translate(2.4, .6), _l(_ink, .8));
  // campanário com venezianas
  final bz = th;
  const bh = 14.0;
  final belfry = Geo.box(b, tx + .04, ty + .04, tw - .08, tw - .08, bz + bh);
  shadedFace(cv, belfry.leftFace(bz), white, line: const Color(0xFF9A968C), lw: 1.2);
  shadedFace(cv, belfry.rightFace(bz), shade(white, -.1), line: const Color(0xFF9A968C), lw: 1.2);
  for (final face in [belfry.left, belfry.right]) {
    const span = tw - .08;
    _poly(cv, [face(span * .25, bz + 2), face(span * .75, bz + 2), face(span * .75, bz + bh - 4), face(span * .5, bz + bh - 1.5), face(span * .25, bz + bh - 4)],
        const Color(0xFF3E4248), line: const Color(0xFF6E6A62), lw: .8);
    for (var z = bz + 4; z < bz + bh - 4; z += 2.4) {
      cv.drawLine(face(span * .27, z), face(span * .73, z), _l(const Color(0xFF6E727A), .6));
    }
  }
  // flecha fina e alta com cruz
  final apex = Iso.pt(tx + tw / 2, ty + tw / 2, bz + bh + 40);
  _poly(cv, [Iso.pt(tx, ty + tw, bz + bh), Iso.pt(tx + tw, ty + tw, bz + bh), apex], shade(roof, .05));
  _poly(cv, [Iso.pt(tx + tw, ty + tw, bz + bh), Iso.pt(tx + tw, ty, bz + bh), apex], shade(roof, -.1));
  cv.drawLine(apex, apex.translate(0, -9), _l(_gold, 1.6));
  cv.drawLine(apex.translate(-3, -6), apex.translate(3, -6), _l(_gold, 1.6));
}

/// Igreja gótica de pedra: nave com contrafortes e pináculos, vitrais coloridos ogivais,
/// portal ogival, rosácea, torre com flecha e cruz.
void _gothic(Canvas cv, Building b) {
  final g = Geo(b);
  final wall = Color.lerp(b.wall, const Color(0xFFE4DAC6), .55)!;
  shadedFace(cv, g.leftFace(), wall, line: shade(wall, -.35), lw: 1.4);
  shadedFace(cv, g.rightFace(), shade(wall, -.1), line: shade(wall, -.35), lw: 1.4);
  wallTexture(cv, g, WallTexture.stone, wall);
  const glass = [Color(0xFF4F6FB0), Color(0xFFB0303A), Color(0xFFE6C35A), Color(0xFF4F8F5A)];
  void lancet(Offset Function(double, double) f, double uc, double z0, double z1, int i, {double hw = .13}) {
    final p = [f(uc - hw, z0), f(uc + hw, z0), f(uc + hw, z1), f(uc + hw * .55, z1 + 6), f(uc, z1 + 11), f(uc - hw * .55, z1 + 6), f(uc - hw, z1)];
    _poly(cv, p, glass[i % 4], line: const Color(0xFFEFE7D8), lw: 1.2);
    cv.drawLine(f(uc, z0), f(uc, z1 + 8), _l(const Color(0xFFEFE7D8), .7));
    cv.drawLine(f(uc - hw, (z0 + z1) / 2), f(uc + hw, (z0 + z1) / 2), _l(const Color(0xFFEFE7D8), .7));
  }

  void buttress(Offset Function(double, double) f, double u, Color c) {
    final top = g.h - 6;
    _poly(cv, [f(u - .06, 0), f(u + .06, 0), f(u + .06, top), f(u - .06, top + 4)], shade(c, -.06));
    // pináculo
    _poly(cv, [f(u - .06, top + 4), f(u + .06, top), f(u, top + 14)], shade(c, .05));
  }

  final door = (b.width - 1) ~/ 2;
  for (var i = 0; i < b.width; i++) {
    if (i == door) continue;
    lancet(g.left, i + .5, 9, 24, i);
  }
  for (var i = 0; i < b.depth; i++) {
    lancet(g.right, i + .5, 9, 24, i + 2);
  }
  for (var i = 1; i < b.width; i++) {
    buttress(g.left, i.toDouble(), wall);
  }
  for (var i = 1; i < b.depth; i++) {
    buttress(g.right, i.toDouble(), shade(wall, -.1));
  }
  final dc = door + .5;
  _poly(cv, [g.left(dc - .27, 0), g.left(dc + .27, 0), g.left(dc + .27, 17), g.left(dc + .13, 25), g.left(dc, 29), g.left(dc - .13, 25), g.left(dc - .27, 17)],
      const Color(0xFF4A3225), line: const Color(0xFFEFE7D8), lw: 1.6);
  // telhado de ardósia
  final x = b.x.toDouble(), y = b.y.toDouble(), w = b.width.toDouble(), d = b.depth.toDouble(), h = g.h;
  final rise = 14 + min(w, d) * 10;
  final roof = Color.lerp(b.roofColor, const Color(0xFF4A5160), .55)!;
  if (b.width >= b.depth) {
    final ym = y + d / 2;
    _poly(cv, [Iso.pt(x - .1, y - .1, h), Iso.pt(x + w + .1, y - .1, h), Iso.pt(x + w + .1, ym, h + rise), Iso.pt(x - .1, ym, h + rise)], shade(roof, -.15));
    _poly(cv, [Iso.pt(x - .1, y + d + .1, h), Iso.pt(x + w + .1, y + d + .1, h), Iso.pt(x + w + .1, ym, h + rise), Iso.pt(x - .1, ym, h + rise)], roof);
    _poly(cv, [Iso.pt(x + w, y + d, h), Iso.pt(x + w, y, h), Iso.pt(x + w, ym, h + rise)], shade(wall, -.1), lw: 1.2);
    final rose = Iso.pt(x + w, ym, h + rise * .4);
    cv.drawCircle(rose, 5, _f(glass[1]));
    cv.drawCircle(rose, 5, _l(const Color(0xFFEFE7D8), 1.4));
  } else {
    final xm = x + w / 2;
    _poly(cv, [Iso.pt(x - .1, y - .1, h), Iso.pt(x - .1, y + d + .1, h), Iso.pt(xm, y + d + .1, h + rise), Iso.pt(xm, y - .1, h + rise)], roof);
    _poly(cv, [Iso.pt(x + w + .1, y - .1, h), Iso.pt(x + w + .1, y + d + .1, h), Iso.pt(xm, y + d + .1, h + rise), Iso.pt(xm, y - .1, h + rise)], shade(roof, -.15));
    _poly(cv, [Iso.pt(x, y + d, h), Iso.pt(x + w, y + d, h), Iso.pt(xm, y + d, h + rise)], wall, lw: 1.2);
    final rose = Iso.pt(xm, y + d, h + rise * .4);
    cv.drawCircle(rose, 5, _f(glass[1]));
    cv.drawCircle(rose, 5, _l(const Color(0xFFEFE7D8), 1.4));
  }
  // torre na frente, à esquerda, com flecha e cruz
  final sx = x + .02, sy = y + d - .95;
  final sh = h + 52;
  final tw = Geo.box(b, sx, sy, .93, .93, sh);
  shadedFace(cv, tw.leftFace(), wall, line: shade(wall, -.35), lw: 1.4);
  shadedFace(cv, tw.rightFace(), shade(wall, -.1), line: shade(wall, -.35), lw: 1.4);
  wallTexture(cv, tw, WallTexture.stone, wall);
  lancet(tw.left, .465, sh - 18, sh - 8, 0, hw: .19);
  lancet(tw.right, .465, sh - 18, sh - 8, 2, hw: .19);
  for (final (u, v) in const [(0.0, .93), (.93, .93), (.93, 0.0)]) {
    final p = Iso.pt(sx + u, sy + v, sh);
    _poly(cv, [p.translate(-2, 0), p.translate(0, -10), p.translate(2, 0)], shade(wall, .05), lw: .8);
  }
  final apex = Iso.pt(sx + .46, sy + .46, sh + 66);
  _poly(cv, [Iso.pt(sx - .04, sy + .97, sh), Iso.pt(sx + .97, sy + .97, sh), apex], roof);
  _poly(cv, [Iso.pt(sx + .97, sy + .97, sh), Iso.pt(sx + .97, sy - .04, sh), apex], shade(roof, -.14));
  cv.drawLine(apex, apex.translate(0, -10), _l(_gold, 1.8));
  cv.drawLine(apex.translate(-3, -7), apex.translate(3, -7), _l(_gold, 1.8));
}
