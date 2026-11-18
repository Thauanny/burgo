import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../../geometry/iso.dart';
import '../draw_helpers.dart';
import 'prop_renderer.dart';

/// Objetos de feira e de fazenda, em polígonos com tábuas, aros, palha e detalhes:
/// barraca de feira, caixote, barril, monte de feno e carroça.
final Map<PropType, PropDrawer> marketDrawers = {
  PropType.stall: _stall,
  PropType.crate: _crate,
  PropType.barrel: _barrel,
  PropType.hay: _hay,
  PropType.cart: _cart,
};

/// Altura (em unidades da cena) que cada objeto alcança: usada para recortar quem passa atrás.
const Map<PropType, double> propHeights = {
  PropType.stall: 40,
  PropType.crate: 24,
  PropType.barrel: 20,
  PropType.hay: 24,
  PropType.cart: 26,
};

Paint _f(Color c) => Paint()..color = c;
Paint _l(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

void _poly(Canvas cv, List<Offset> pts, Color col, {Color? line, double lw = .9}) {
  final p = Iso.poly(pts);
  cv.drawPath(p, _f(col));
  if (line != null) cv.drawPath(p, _l(ink(line), lw));
}

/// Caixa de tábuas: três faces com degradê de luz, juntas das tábuas e moldura.
void _planks(Canvas cv, double x, double y, double w, double d, double z0, double z1, Color wood,
    {int rows = 3, bool frame = true}) {
  final line = shade(wood, -.4);
  final left = [Iso.pt(x, y + d, z0), Iso.pt(x + w, y + d, z0), Iso.pt(x + w, y + d, z1), Iso.pt(x, y + d, z1)];
  final right = [Iso.pt(x + w, y + d, z0), Iso.pt(x + w, y, z0), Iso.pt(x + w, y, z1), Iso.pt(x + w, y + d, z1)];
  final top = [Iso.pt(x, y, z1), Iso.pt(x + w, y, z1), Iso.pt(x + w, y + d, z1), Iso.pt(x, y + d, z1)];
  _poly(cv, left, shade(wood, .02), line: line);
  _poly(cv, right, shade(wood, -.14), line: line);
  _poly(cv, top, shade(wood, .14), line: line);
  final joint = _l(shade(wood, -.28), .7);
  for (var i = 1; i < rows; i++) {
    final z = z0 + (z1 - z0) * i / rows;
    cv.drawLine(Iso.pt(x, y + d, z), Iso.pt(x + w, y + d, z), joint);
    cv.drawLine(Iso.pt(x + w, y + d, z), Iso.pt(x + w, y, z), joint);
  }
  for (var i = 1; i < 3; i++) {
    cv.drawLine(Iso.pt(x, y + d * i / 3, z1), Iso.pt(x + w, y + d * i / 3, z1), joint);
  }
  if (frame) {
    // moldura escura nas quinas
    final edge = _l(shade(wood, -.35), 1.6);
    cv.drawLine(Iso.pt(x, y + d, z0), Iso.pt(x, y + d, z1), edge);
    cv.drawLine(Iso.pt(x + w, y + d, z0), Iso.pt(x + w, y + d, z1), edge);
    cv.drawLine(Iso.pt(x + w, y, z0), Iso.pt(x + w, y, z1), edge);
  }
}

// ---------------------------------------------------------------- barraca de feira
/// Barraca de feira: balcão de tábuas com mercadoria (frutas, panos, potes), quatro postes e
/// toldo listrado inclinado com babado; uma placa pendurada com o que se vende.
void _stall(PropContext c) {
  final cv = c.cv, hs = c.hs;
  final cx = c.cx, cy = c.cy;
  const wood = Color(0xFFB08458), post = Color(0xFF7A5234);
  const stripes = [
    (Color(0xFFC8402F), Color(0xFFF4ECDA)),
    (Color(0xFF3F6FB5), Color(0xFFF4ECDA)),
    (Color(0xFF4F8F48), Color(0xFFEDE0B8)),
    (Color(0xFFD9A441), Color(0xFF8E3B2A)),
  ];
  final (cA, cB) = stripes[hs % stripes.length];
  cv.drawOval(Rect.fromCenter(center: c.o.translate(4, 3), width: 50, height: 22), c.shadow);
  const x0 = -.42, x1 = .42, y0 = -.34, y1 = .34;
  // postes de trás
  for (final px in [x0 + .03, x1 - .05]) {
    drawBox(cv, cx + px, cy + y0, .05, .05, 0, 38, post);
  }
  // balcão
  _planks(cv, cx + x0 + .04, cy - .1, x1 - x0 - .08, .36, 0, 13, wood, rows: 3);
  // tampo com saliência
  drawBox(cv, cx + x0 + .01, cy - .13, x1 - x0 - .02, .42, 13, 15, shade(wood, .1));
  // mercadoria em cima do balcão
  final goods = hs % 3;
  for (var i = 0; i < 4; i++) {
    final gx = cx + x0 + .14 + i * .18, gy = cy + .02;
    final b = Iso.pt(gx, gy, 15);
    switch ((goods + i) % 3) {
      case 0: // cesto de frutas
        cv.drawOval(Rect.fromCenter(center: b, width: 11, height: 5), _f(const Color(0xFF8A6B3A)));
        for (final (dx, dy, col) in const [(-2.5, -1.5, Color(0xFFD9484A)), (2.0, -1.8, Color(0xFFE6A23A)), (0.0, -3.5, Color(0xFF6DAF5A))]) {
          cv.drawCircle(b.translate(dx, dy), 2.2, _f(col));
          cv.drawCircle(b.translate(dx - .6, dy - .6), .7, _f(const Color(0xAAFFFFFF)));
        }
      case 1: // rolo de pano
        final col = [const Color(0xFF6A2E5A), const Color(0xFF3F6FB5), const Color(0xFFD9A441)][(hs + i) % 3];
        cv.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: b.translate(0, -2.5), width: 12, height: 5), const Radius.circular(2.5)), _f(col));
        cv.drawCircle(b.translate(-6, -2.5), 2.5, _f(shade(col, .2)));
        cv.drawCircle(b.translate(-6, -2.5), 2.5, _l(shade(col, -.35), .6));
      default: // pote de barro
        final p = Path()
          ..moveTo(b.dx - 3, b.dy)
          ..quadraticBezierTo(b.dx - 5, b.dy - 5, b.dx - 2, b.dy - 7)
          ..lineTo(b.dx + 2, b.dy - 7)
          ..quadraticBezierTo(b.dx + 5, b.dy - 5, b.dx + 3, b.dy)
          ..close();
        cv.drawPath(p, _f(const Color(0xFFB0603A)));
        cv.drawPath(p, _l(const Color(0xFF6E3A22), .6));
        cv.drawLine(b.translate(-3.4, -4), b.translate(3.4, -4), _l(const Color(0xFFE6C38A), .8));
    }
  }
  // sacos no chão, ao lado
  final sack = Iso.pt(cx + x1 - .08, cy + y1 - .02);
  final sp = Path()
    ..moveTo(sack.dx - 5, sack.dy)
    ..quadraticBezierTo(sack.dx - 6, sack.dy - 8, sack.dx - 1, sack.dy - 10)
    ..lineTo(sack.dx + 1, sack.dy - 10)
    ..quadraticBezierTo(sack.dx + 6, sack.dy - 8, sack.dx + 5, sack.dy)
    ..close();
  cv.drawPath(sp, _f(const Color(0xFFD8C49A)));
  cv.drawPath(sp, _l(const Color(0xFF8A7650), .7));
  cv.drawLine(sack.translate(-2, -9), sack.translate(2, -9), _l(const Color(0xFF8A7650), 1));
  // toldo inclinado listrado (alto atrás, baixo na frente)
  const zBack = 40.0, zFront = 31.0;
  const ax0 = x0 - .06, ax1 = x1 + .06, ay0 = y0 - .06, ay1 = y1 + .1;
  const n = 6;
  for (var i = 0; i < n; i++) {
    final u0 = ax0 + (ax1 - ax0) * i / n, u1 = ax0 + (ax1 - ax0) * (i + 1) / n;
    final col = i.isEven ? cA : cB;
    _poly(cv, [Iso.pt(cx + u0, cy + ay0, zBack), Iso.pt(cx + u1, cy + ay0, zBack), Iso.pt(cx + u1, cy + ay1, zFront), Iso.pt(cx + u0, cy + ay1, zFront)],
        col);
  }
  _poly(cv, [Iso.pt(cx + ax0, cy + ay0, zBack), Iso.pt(cx + ax1, cy + ay0, zBack), Iso.pt(cx + ax1, cy + ay1, zFront), Iso.pt(cx + ax0, cy + ay1, zFront)],
      const Color(0x00000000), line: shade(cA, -.4), lw: 1);
  // sombra do lado direito do toldo (lateral)
  _poly(cv, [Iso.pt(cx + ax1, cy + ay0, zBack), Iso.pt(cx + ax1, cy + ay1, zFront), Iso.pt(cx + ax1, cy + ay1, zFront - 4), Iso.pt(cx + ax1, cy + ay0, zBack - 4)],
      shade(cA, -.25), line: shade(cA, -.45), lw: .7);
  // babado em festões na frente
  for (var i = 0; i < n; i++) {
    final u0 = ax0 + (ax1 - ax0) * i / n, u1 = ax0 + (ax1 - ax0) * (i + 1) / n;
    final a = Iso.pt(cx + u0, cy + ay1, zFront), b = Iso.pt(cx + u1, cy + ay1, zFront);
    final mid = Offset.lerp(a, b, .5)!.translate(0, 4.5);
    final fest = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx, mid.dy + 2, b.dx, b.dy)
      ..close();
    cv.drawPath(fest, _f(i.isEven ? cA : cB));
    cv.drawPath(fest, _l(shade(cA, -.4), .6));
  }
  // postes da frente (por cima do balcão)
  for (final px in [x0 + .03, x1 - .05]) {
    drawBox(cv, cx + px, cy + y1 - .05, .05, .05, 0, 31, post);
  }
  // placa pendurada
  final s = Iso.pt(cx + x0 + .06, cy + ay1, zFront - 2);
  cv.drawLine(s, s.translate(0, 4), _l(const Color(0xFF3A2C2A), .7));
  cv.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: s.translate(0, 8), width: 9, height: 6), const Radius.circular(1)),
      _f(const Color(0xFFE6D2A8)));
  cv.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: s.translate(0, 8), width: 9, height: 6), const Radius.circular(1)),
      _l(const Color(0xFF6B4A33), .7));
  cv.drawCircle(s.translate(0, 8), 1.4, _f(cA));
}

// ---------------------------------------------------------------- caixote
/// Caixote de tábuas com moldura reforçada, travessa em X e pregos; às vezes outro em cima,
/// ou aberto com palha e maçãs.
void _crate(PropContext c) {
  final cv = c.cv, hs = c.hs, cx = c.cx, cy = c.cy;
  const wood = Color(0xFFC49A6C);
  c.shadowOval(c.o, 32, 15);
  void crate(double x, double y, double s, double z0, {bool open = false}) {
    final h = s * 36;
    _planks(cv, x, y, s, s, z0, z0 + h, wood, rows: 3);
    final brace = _l(shade(wood, -.3), 1.4);
    // travessa diagonal nas duas faces
    cv.drawLine(Iso.pt(x, y + s, z0 + 1), Iso.pt(x + s, y + s, z0 + h - 1), brace);
    cv.drawLine(Iso.pt(x + s, y + s, z0 + 1), Iso.pt(x + s, y, z0 + h - 1), brace);
    // pregos nas quinas
    final nail = _f(const Color(0xFF55585C));
    for (final p in [
      Iso.pt(x + .03, y + s, z0 + 2), Iso.pt(x + s - .03, y + s, z0 + 2), Iso.pt(x + .03, y + s, z0 + h - 2), Iso.pt(x + s - .03, y + s, z0 + h - 2),
      Iso.pt(x + s, y + s - .03, z0 + 2), Iso.pt(x + s, y + .03, z0 + h - 2),
    ]) {
      cv.drawCircle(p, .8, nail);
    }
    if (open) {
      // aberto: palha e maçãs no topo
      final t = Iso.pt(x + s / 2, y + s / 2, z0 + h);
      for (var i = 0; i < 7; i++) {
        final a = i * .9;
        cv.drawLine(t.translate(cos(a) * 4, sin(a) * 2), t.translate(cos(a) * 8, sin(a) * 3.5 - 2), _l(const Color(0xFFE6C260), .8));
      }
      for (final (dx, dy) in const [(-3.0, -1.0), (2.5, -.5), (0.0, -3.0)]) {
        cv.drawCircle(t.translate(dx, dy), 2.3, _f(const Color(0xFFC8402F)));
        cv.drawCircle(t.translate(dx - .7, dy - .7), .7, _f(const Color(0xAAFFFFFF)));
      }
    }
  }

  switch (hs % 3) {
    case 0: // dois caixotes empilhados
      crate(cx - .22, cy - .22, .44, 0);
      crate(cx - .14, cy - .2, .3, .44 * 36, open: true);
    case 1: // um caixote aberto
      crate(cx - .24, cy - .24, .48, 0, open: true);
    default: // dois lado a lado
      crate(cx - .3, cy - .3, .34, 0);
      crate(cx + .02, cy - .04, .3, 0, open: true);
  }
}

// ---------------------------------------------------------------- barril
/// Barril de aduelas com dois pares de aros de ferro, bojo no meio e tampa com tábuas e batoque.
void _barrel(PropContext c) {
  final cv = c.cv, cx = c.cx, cy = c.cy;
  const wood = Color(0xFF9A6B45), iron = Color(0xFF4A4A52);
  c.shadowOval(c.o, 24, 11);
  const h = 19.0;
  final (rx, ry) = Iso.ellipse(.17);
  final bulge = rx * 1.12;
  final b0 = Iso.pt(cx, cy, 0), b1 = Iso.pt(cx, cy, h), mid = Iso.pt(cx, cy, h / 2);
  final body = Path()
    ..moveTo(b0.dx - rx, b0.dy)
    ..quadraticBezierTo(mid.dx - bulge * 1.08, mid.dy, b1.dx - rx, b1.dy)
    ..lineTo(b1.dx + rx, b1.dy)
    ..quadraticBezierTo(mid.dx + bulge * 1.08, mid.dy, b0.dx + rx, b0.dy)
    ..arcTo(Rect.fromCenter(center: b0, width: rx * 2, height: ry * 2), 0, pi, false)
    ..close();
  cv.drawPath(body, _f(wood));
  // luz à esquerda, sombra à direita
  final lit = Path()
    ..moveTo(b0.dx - rx, b0.dy)
    ..quadraticBezierTo(mid.dx - bulge * 1.08, mid.dy, b1.dx - rx, b1.dy)
    ..lineTo(b1.dx - rx * .35, b1.dy)
    ..quadraticBezierTo(mid.dx - bulge * .4, mid.dy, b0.dx - rx * .35, b0.dy)
    ..close();
  cv.drawPath(lit, _f(shade(wood, .12)));
  final dark = Path()
    ..moveTo(b0.dx + rx * .45, b0.dy)
    ..quadraticBezierTo(mid.dx + bulge * .55, mid.dy, b1.dx + rx * .45, b1.dy)
    ..lineTo(b1.dx + rx, b1.dy)
    ..quadraticBezierTo(mid.dx + bulge * 1.08, mid.dy, b0.dx + rx, b0.dy)
    ..close();
  cv.drawPath(dark, _f(shade(wood, -.14)));
  // aduelas
  for (final u in [-.66, -.33, 0.0, .33, .66]) {
    final p = Path()
      ..moveTo(b0.dx + rx * u, b0.dy + ry * sqrt(1 - u * u) * .9)
      ..quadraticBezierTo(mid.dx + bulge * 1.08 * u, mid.dy + ry * sqrt(1 - u * u), b1.dx + rx * u, b1.dy + ry * sqrt(1 - u * u) * .9);
    cv.drawPath(p, _l(shade(wood, -.3), .6));
  }
  cv.drawPath(body, _l(shade(wood, -.45), 1));
  // aros
  for (final z in [3.0, 6.0, h - 6, h - 3]) {
    final p = Iso.pt(cx, cy, z);
    final w = rx + (bulge - rx) * (1 - ((z - h / 2).abs() / (h / 2))) * 1.1;
    cv.drawArc(Rect.fromCenter(center: p, width: w * 2, height: ry * 2), 0, pi, false, _l(iron, 1.6));
    cv.drawArc(Rect.fromCenter(center: p, width: w * 2, height: ry * 2), .3, .9, false, _l(const Color(0xFF8E959B), .6));
  }
  // tampa
  final lid = Rect.fromCenter(center: b1, width: rx * 2, height: ry * 2);
  cv.drawOval(lid, _f(shade(wood, .08)));
  cv.drawOval(lid, _l(iron, 1.2));
  for (final u in [-.4, 0.0, .4]) {
    cv.drawLine(b1.translate(rx * u - ry * .5, -ry * .6), b1.translate(rx * u + ry * .5, ry * .6), _l(shade(wood, -.2), .6));
  }
  cv.drawCircle(b1.translate(rx * .35, 0), 1.3, _f(const Color(0xFF5A3B2A)));
}

// ---------------------------------------------------------------- feno
/// Monte de feno em cúpula, com fios de palha soltos, uma faixa mais escura e, às vezes, um
/// forcado espetado.
void _hay(PropContext c) {
  final cv = c.cv, hs = c.hs;
  final o = c.o;
  const straw = Color(0xFFE6C260);
  c.shadowOval(o, 38, 16);
  final w = 17.0, h = 22.0 + (hs % 3) * 2;
  final mound = Path()
    ..moveTo(o.dx - w, o.dy)
    ..cubicTo(o.dx - w - 1, o.dy - h * .7, o.dx - w * .45, o.dy - h, o.dx, o.dy - h)
    ..cubicTo(o.dx + w * .45, o.dy - h, o.dx + w + 1, o.dy - h * .7, o.dx + w, o.dy)
    ..quadraticBezierTo(o.dx, o.dy + 7, o.dx - w, o.dy)
    ..close();
  cv.drawPath(mound, _f(straw));
  // lado da sombra e luz no topo
  cv.save();
  cv.clipPath(mound);
  cv.drawOval(Rect.fromCenter(center: o.translate(w * .7, -h * .2), width: w * 1.4, height: h * 1.8), _f(shade(straw, -.16)));
  cv.drawOval(Rect.fromCenter(center: o.translate(-w * .35, -h * .78), width: w * .9, height: h * .55), _f(shade(straw, .14)));
  // faixa de palha mais velha embaixo
  cv.drawRect(Rect.fromLTRB(o.dx - w - 2, o.dy - 5, o.dx + w + 2, o.dy + 8), _f(const Color(0x33986A20)));
  // fios de palha
  final r = Random(hs);
  for (var i = 0; i < 46; i++) {
    final px = o.dx + (r.nextDouble() * 2 - 1) * w * .95;
    final py = o.dy - r.nextDouble() * h;
    final a = -pi / 2 + (r.nextDouble() - .5) * 1.4;
    cv.drawLine(Offset(px, py), Offset(px + cos(a) * 4, py + sin(a) * 4),
        _l(i.isEven ? shade(straw, -.28) : shade(straw, .2), .7));
  }
  cv.restore();
  cv.drawPath(mound, _l(const Color(0xFF9A7A2E), 1));
  // fios soltos na borda e no chão
  for (var i = 0; i < 8; i++) {
    final a = pi + i * pi / 7;
    final p = o.translate(cos(a) * w * .95, sin(a) * h * .9 + (i.isEven ? 0 : 2));
    cv.drawLine(p, p.translate(cos(a) * 3, sin(a) * 3 - 1), _l(const Color(0xFFB8963F), .8));
  }
  for (var i = 0; i < 5; i++) {
    final p = o.translate(-w + i * 8.0 + 2, 3 + (i % 2) * 2);
    cv.drawLine(p, p.translate(4, -1), _l(const Color(0xFFD8B550), .8));
  }
  if (hs % 2 == 0) {
    // forcado espetado no monte
    final top = o.translate(w * .35, -h - 14), bottom = o.translate(w * .05, -h * .45);
    cv.drawLine(bottom, top, _l(const Color(0xFF3A2418), 2.4));
    cv.drawLine(bottom, top, _l(const Color(0xFF7A5234), 1.4));
    for (final dx in [-2.0, 0.0, 2.0]) {
      cv.drawLine(bottom.translate(dx * .6, 0), bottom.translate(dx - .8, 7), _l(const Color(0xFF8E959B), 1));
    }
  }
}

// ---------------------------------------------------------------- carroça
/// Carroça de fazenda: caixa de tábuas com grades laterais, duas rodas grandes de raios,
/// varais para o cavalo e carga (feno, sacos ou barril).
void _cart(PropContext c) {
  final cv = c.cv, hs = c.hs, cx = c.cx, cy = c.cy;
  const wood = Color(0xFF9A6B45), dark = Color(0xFF4E3524);
  c.shadowOval(c.o.translate(4, 2), 54, 22);
  const bx0 = -.36, bx1 = .3, by0 = -.2, by1 = .2, z0 = 9.0, z1 = 13.0;

  void wheel(double dy) {
    const r = .21, rz = 9.0;
    final ctrX = cx - .03, ctrY = cy + dy;
    Offset at(double a, [double k = 1]) => Iso.pt(ctrX + cos(a) * r * k, ctrY, rz + sin(a) * rz * k);
    final rim = Path();
    for (var i = 0; i <= 24; i++) {
      final p = at(i / 24 * 2 * pi);
      i == 0 ? rim.moveTo(p.dx, p.dy) : rim.lineTo(p.dx, p.dy);
    }
    rim.close();
    final inner = Path();
    for (var i = 0; i <= 24; i++) {
      final p = at(i / 24 * 2 * pi, .78);
      i == 0 ? inner.moveTo(p.dx, p.dy) : inner.lineTo(p.dx, p.dy);
    }
    inner.close();
    cv.drawPath(rim, _l(dark, 4.2));
    cv.drawPath(rim, _l(const Color(0xFF6B4A33), 2.6));
    cv.drawPath(rim, _l(const Color(0xFF55585C), .8)); // aro de ferro
    final hub = Iso.pt(ctrX, ctrY, rz);
    for (var i = 0; i < 8; i++) {
      cv.drawLine(hub, at(i / 8 * 2 * pi, .8), _l(const Color(0xFF6B4A33), 1.3));
    }
    cv.drawCircle(hub, 2.4, _f(const Color(0xFF55585C)));
    cv.drawCircle(hub, 1, _f(const Color(0xFFB8BCC4)));
  }

  wheel(by0 - .02); // roda de trás
  // varais (para o cavalo), saindo da frente
  for (final dy in [by0 + .04, by1 - .04]) {
    final a = Iso.pt(cx + bx1, cy + dy, z0 + 1), b = Iso.pt(cx + bx1 + .42, cy + dy, 3);
    cv.drawLine(a, b, _l(dark, 2.8));
    cv.drawLine(a, b, _l(wood, 1.7));
  }
  cv.drawLine(Iso.pt(cx + bx1 + .38, cy + by0 + .04, 4), Iso.pt(cx + bx1 + .38, cy + by1 - .04, 4), _l(dark, 1.4));
  // caixa da carroça
  _planks(cv, cx + bx0, cy + by0, bx1 - bx0, by1 - by0, z0, z1, wood, rows: 1);
  // carga
  switch (hs % 3) {
    case 0: // feno
      final t = Iso.pt(cx - .03, cy, z1);
      final pile = Path()
        ..moveTo(t.dx - 18, t.dy + 3)
        ..quadraticBezierTo(t.dx - 14, t.dy - 12, t.dx, t.dy - 13)
        ..quadraticBezierTo(t.dx + 14, t.dy - 12, t.dx + 18, t.dy + 3)
        ..close();
      cv.drawPath(pile, _f(const Color(0xFFE6C260)));
      final r = Random(hs);
      for (var i = 0; i < 20; i++) {
        final p = t.translate((r.nextDouble() * 2 - 1) * 14, -r.nextDouble() * 11);
        cv.drawLine(p, p.translate(2.5, -2.5), _l(i.isEven ? const Color(0xFFB8963F) : const Color(0xFFF2D88A), .7));
      }
      cv.drawPath(pile, _l(const Color(0xFF9A7A2E), .8));
    case 1: // sacos
      for (final (dx, dy) in const [(-.18, -.05), (.0, .04), (.14, -.06)]) {
        final b = Iso.pt(cx + dx, cy + dy, z1);
        final sp = Path()
          ..moveTo(b.dx - 6, b.dy)
          ..quadraticBezierTo(b.dx - 7, b.dy - 9, b.dx - 1, b.dy - 11)
          ..lineTo(b.dx + 1, b.dy - 11)
          ..quadraticBezierTo(b.dx + 7, b.dy - 9, b.dx + 6, b.dy)
          ..close();
        cv.drawPath(sp, _f(const Color(0xFFD8C49A)));
        cv.drawPath(sp, _l(const Color(0xFF8A7650), .7));
        cv.drawLine(b.translate(-2, -10), b.translate(2, -10), _l(const Color(0xFF8A7650), 1));
      }
    default: // barril deitado e caixote
      drawBox(cv, cx - .25, cy - .12, .2, .2, z1, z1 + 8, const Color(0xFFC49A6C));
      final b = Iso.pt(cx + .08, cy, z1 + 5);
      cv.drawOval(Rect.fromCenter(center: b, width: 18, height: 10), _f(const Color(0xFF9A6B45)));
      cv.drawOval(Rect.fromCenter(center: b, width: 18, height: 10), _l(const Color(0xFF4A4A52), 1.2));
      cv.drawOval(Rect.fromCenter(center: b.translate(6, 0), width: 5, height: 9), _f(shade(const Color(0xFF9A6B45), .1)));
  }
  // grades laterais (sobre a carga, do lado da frente)
  for (final dy in [by1]) {
    for (var i = 0; i <= 5; i++) {
      final u = bx0 + (bx1 - bx0) * i / 5;
      cv.drawLine(Iso.pt(cx + u, cy + dy, z1), Iso.pt(cx + u, cy + dy, z1 + 7), _l(dark, 1.8));
      cv.drawLine(Iso.pt(cx + u, cy + dy, z1), Iso.pt(cx + u, cy + dy, z1 + 7), _l(wood, 1));
    }
    cv.drawLine(Iso.pt(cx + bx0, cy + dy, z1 + 7), Iso.pt(cx + bx1, cy + dy, z1 + 7), _l(dark, 2.4));
    cv.drawLine(Iso.pt(cx + bx0, cy + dy, z1 + 7), Iso.pt(cx + bx1, cy + dy, z1 + 7), _l(shade(wood, .1), 1.4));
  }
  wheel(by1 + .02); // roda da frente
}
