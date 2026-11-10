import 'dart:math';
import 'dart:ui';
import 'package:flutter/painting.dart' show Alignment, HSVColor, LinearGradient;
import '../../domain/city_types.dart';
import '../draw_helpers.dart';
import 'building_kit.dart' show cylinder;
import 'prop_renderer.dart';

/// Objetos de vila e fantasia: caixotes, barris, feno, carroça, estandartes, estátuas, lápides.
final Map<PropType, PropDrawer> villageDrawers = {
  PropType.crate: _crate,
  PropType.barrel: _barrel,
  PropType.hay: _hay,
  PropType.cart: _cart,
  PropType.banner: _banner,
  PropType.statue: _statue,
  PropType.grave: _grave,
  PropType.dungeonEntrance: _dungeonEntrance,
  PropType.lantern: _lantern,
  PropType.toro: _toro,
  PropType.torii: _torii,
  PropType.elfLamp: _elfLamp,
  PropType.mountain: _mountain,
  PropType.skyIsle: _skyIsle,
  PropType.mesa: _mesa,
  PropType.giantFlower: _giantFlower,
  PropType.fairyLight: _fairyLight,
  PropType.eclipse: _eclipse,
  PropType.ruin: _ruin,
};

void _crate(PropContext c) {
  c.shadowOval(c.o, 30, 15);
  const wood = Color(0xFFC9A074);
  c.box(-.2, -.2, .4, .4, 0, 14, wood);
  c.box(.02, -.1, .26, .26, 14, 22, shade(wood, -.05));
  c.cv.drawLine(
      c.at(-.2, .2, 3), c.at(.2, .2, 11), c.stroke(shade(wood, -.3), 1.2));
}

void _barrel(PropContext c) {
  c.shadowOval(c.o, 22, 11);
  cylinder(c.cv, c.cx, c.cy, .17, 0, 17, const Color(0xFF9A6B45));
  for (final z in [4.0, 12.0]) {
    final p = c.at(0, 0, z);
    c.cv.drawOval(Rect.fromCenter(center: p, width: 21, height: 9),
        c.stroke(const Color(0xFF5A4636), 1.4));
  }
}

void _hay(PropContext c) {
  c.shadowOval(c.o, 30, 14);
  cylinder(c.cv, c.cx, c.cy, .24, 0, 16, const Color(0xFFE6C260),
      cap: true, capShade: .05);
  final top = c.at(0, 0, 16);
  c.cv.drawOval(Rect.fromCenter(center: top, width: 21, height: 9).deflate(3),
      c.stroke(const Color(0xFFB8963F), 1));
  c.cv.drawLine(
      c.at(-.2, 0, 6), c.at(.2, 0, 6), c.stroke(const Color(0xFFB8963F), 1));
}

void _cart(PropContext c) {
  c.shadowOval(c.o, 44, 20);
  const wood = Color(0xFF9A6B45);
  c.box(-.3, -.18, .6, .36, 8, 14, wood);
  c.box(-.3, -.18, .6, .05, 14, 20, shade(wood, .05));
  c.box(-.3, .13, .6, .05, 14, 20, shade(wood, .05));
  for (final dy in [-.2, .2]) {
    final p = c.at(-.05, dy, 8);
    c.cv.drawCircle(p, 8, c.fill(const Color(0xFF6B4A33)));
    c.cv.drawCircle(p, 8, c.stroke(const Color(0xFF3B2A1E), 1.4));
    c.cv.drawCircle(p, 2, c.fill(const Color(0xFFC9A074)));
  }
  final h = c.at(.3, 0, 10);
  c.cv.drawLine(h, h.translate(12, 6), c.stroke(wood, 2.4));
}

void _banner(PropContext c) {
  c.shadowOval(c.o, 14, 7);
  final base = c.o, top = c.o.translate(0, -46);
  c.cv.drawLine(base, top, c.stroke(const Color(0xFF5A4636), 2.4));
  final sway = sin(c.time * 2 + c.phase) * 2.5;
  final color = const [
    Color(0xFFC8402F),
    Color(0xFF3F6FB5),
    Color(0xFF6B3FA0),
    Color(0xFFD9A441)
  ][c.hs % 4];
  final p = Path()
    ..moveTo(top.dx + 1, top.dy + 2)
    ..lineTo(top.dx + 16, top.dy + 2 + sway * .3)
    ..lineTo(top.dx + 16 + sway, top.dy + 24)
    ..lineTo(top.dx + 8 + sway * 1.2, top.dy + 30)
    ..lineTo(top.dx + 1, top.dy + 24)
    ..close();
  c.cv.drawPath(p, c.fill(color));
  c.cv.drawPath(p, c.stroke(shade(color, -.3), 1.2));
  c.cv.drawCircle(
      top.translate(8.5 + sway * .5, 13), 3, c.fill(const Color(0xFFF2D27A)));
}

void _statue(PropContext c) {
  c.shadowOval(c.o, 30, 15);
  const stone = Color(0xFFCFC9BE);
  c.box(-.2, -.2, .4, .4, 0, 12, stone);
  final b = c.at(0, 0, 12);
  c.cv.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: b.translate(0, -11), width: 11, height: 22),
          const Radius.circular(4)),
      c.fill(shade(stone, -.03)));
  c.cv.drawCircle(b.translate(0, -26), 5, c.fill(shade(stone, .03)));
  c.cv.drawLine(b.translate(7, -8), b.translate(7, -30),
      c.stroke(const Color(0xFFB9B3A8), 2));
  c.cv.drawLine(b.translate(4, -22), b.translate(10, -22),
      c.stroke(const Color(0xFFB9B3A8), 1.6));
  c.cv.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: b.translate(-6, -12), width: 6, height: 12),
          const Radius.circular(3)),
      c.fill(const Color(0xFF7C8FA6)));
}

void _grave(PropContext c) {
  c.shadowOval(c.o, 26, 12);
  c.cv.drawOval(
      Rect.fromCenter(center: c.o.translate(0, 2), width: 24, height: 10),
      c.fill(const Color(0xFF7A6A52)));
  final base = c.o.translate(0, 0);
  final p = RRect.fromRectAndCorners(
      Rect.fromLTWH(base.dx - 6, base.dy - 20, 12, 20),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6));
  c.cv.drawRRect(p, c.fill(const Color(0xFFA9ADB0)));
  c.cv.drawRRect(p, c.stroke(const Color(0xFF6B7075), 1.2));
  c.cv.drawLine(base.translate(0, -16), base.translate(0, -8),
      c.stroke(const Color(0xFF6B7075), 1.4));
  c.cv.drawLine(base.translate(-3, -13), base.translate(3, -13),
      c.stroke(const Color(0xFF6B7075), 1.4));
}

/// Entrada de masmorra: arco de pedra com escada descendo para a escuridão, tocha acesa e uma seta
/// pulsando para baixo, para ser vista de longe no piso de cima.
void _dungeonEntrance(PropContext c) {
  const stone = Color(0xFFB4AEA2);
  c.shadowOval(c.o, 46, 22);
  // base de pedra e a boca escura
  c.box(-.42, -.38, .84, .76, 0, 5, shade(stone, -.05));
  final mouth = Path()
    ..moveTo(c.at(-.22, .38, 5).dx, c.at(-.22, .38, 5).dy)
    ..lineTo(c.at(.22, .38, 5).dx, c.at(.22, .38, 5).dy)
    ..lineTo(c.at(.22, .38, 24).dx, c.at(.22, .38, 24).dy)
    ..quadraticBezierTo(c.at(0, .38, 34).dx, c.at(0, .38, 34).dy,
        c.at(-.22, .38, 24).dx, c.at(-.22, .38, 24).dy)
    ..close();
  c.cv.drawPath(mouth, c.fill(const Color(0xFF14101A)));
  c.cv.drawPath(mouth, c.stroke(shade(stone, -.3), 1.6));
  // degraus descendo
  for (var i = 0; i < 3; i++) {
    final z = 5.0 - i * 1.6;
    c.cv.drawLine(c.at(-.2, .38, z + 1), c.at(.2, .38, z + 1),
        c.stroke(const Color(0xFF5A5560), 1.4));
  }
  // pilares do arco
  c.box(-.36, .3, .14, .14, 5, 28, stone);
  c.box(.22, .3, .14, .14, 5, 28, stone);
  // tocha à direita, com chama animada
  final torch = c.at(.34, .1, 20);
  c.cv.drawLine(c.at(.34, .1, 6), torch, c.stroke(const Color(0xFF6B4A33), 2));
  final flick = .8 + .2 * sin(c.time * 9 + c.phase);
  c.cv.drawCircle(torch.translate(0, -3), 15 * flick,
      c.fill(const Color.fromRGBO(255, 170, 70, .18)));
  c.cv.drawCircle(
      torch.translate(0, -3), 3.4 * flick, c.fill(const Color(0xFFFFB347)));
  // seta para baixo, pulsando acima da entrada
  final bob = sin(c.time * 3 + c.phase) * 3;
  final tip = c.o.translate(0, -52 + bob);
  final arrow = Path()
    ..moveTo(tip.dx - 7, tip.dy - 8)
    ..lineTo(tip.dx + 7, tip.dy - 8)
    ..lineTo(tip.dx, tip.dy + 4)
    ..close();
  c.cv.drawPath(arrow, c.fill(const Color(0xFFE0A93B)));
  c.cv.drawPath(arrow, c.stroke(const Color(0xFF2B2A33), 1.4));
}

/// Lanterna medieval: poste de madeira com um braço e a lanterna de vela pendurada.
void _lantern(PropContext c) {
  c.shadowOval(c.o, 12, 6);
  const wood = Color(0xFF6B4A33);
  final top = c.o.translate(0, -40);
  c.cv.drawLine(c.o, top, c.stroke(wood, 3.4));
  c.cv.drawLine(top, top.translate(10, 0), c.stroke(wood, 2.6));
  c.cv.drawLine(top.translate(10, 0), top.translate(10, 4),
      c.stroke(const Color(0xFF3A3A44), 1.2));
  final box =
      Rect.fromCenter(center: top.translate(10, 10), width: 8, height: 11);
  final flick = .8 + .2 * sin(c.time * 7 + c.phase);
  c.cv.drawCircle(
      box.center, 16 * flick, c.fill(const Color.fromRGBO(255, 190, 90, .16)));
  c.cv.drawRect(
      box,
      c.fill(Color.lerp(
          const Color(0xFFFFD27A), const Color(0xFFFFF0B8), flick - .6)!));
  c.cv.drawRect(box, c.stroke(const Color(0xFF3A3A44), 1.4));
  c.cv.drawLine(box.topLeft + const Offset(0, 5),
      box.topRight + const Offset(0, 5), c.stroke(const Color(0xFF3A3A44), 1));
}

/// Lanterna de pedra japonesa (tōrō): base, pilar, caixa de luz acesa e telhadinho.
void _toro(PropContext c) {
  c.shadowOval(c.o, 22, 11);
  const stone = Color(0xFFB9B6AE);
  c.box(-.13, -.13, .26, .26, 0, 3, shade(stone, -.05));
  cylinder(c.cv, c.cx, c.cy, .05, 3, 15, stone);
  c.box(-.16, -.16, .32, .32, 15, 18, shade(stone, .03));
  c.box(-.11, -.11, .22, .22, 18, 27, stone);
  final w = c.at(0, .11, 22);
  c.cv.drawRect(Rect.fromCenter(center: w, width: 6, height: 6),
      c.fill(const Color(0xFFFFD680)));
  c.box(-.2, -.2, .4, .4, 27, 30, shade(stone, -.08));
  c.box(-.1, -.1, .2, .2, 30, 34, shade(stone, -.04));
}

/// Portal torii: dois pilares vermelhos, travessa curva preta no topo e uma barra abaixo.
void _torii(PropContext c) {
  c.shadowOval(c.o, 46, 16);
  const red = Color(0xFFC0392B);
  for (final dx in [-.42, .42]) {
    cylinder(c.cv, c.cx + dx, c.cy, .06, 0, 46, red);
  }
  c.box(-.46, -.04, .92, .08, 33, 37, red);
  c.box(-.58, -.08, 1.16, .16, 45, 49, const Color(0xFF2B2B2B));
  c.box(-.5, -.06, 1.0, .12, 49, 52, const Color(0xFFC0392B));
}

/// Lâmpada élfica: haste branca e fina com um bulbo de luz verde que respira.
void _elfLamp(PropContext c) {
  c.shadowOval(c.o, 18, 9);
  const ivory = Color(0xFFF1EEE2);
  cylinder(c.cv, c.cx, c.cy, .035, 0, 30, ivory);
  c.cv.drawOval(Rect.fromCenter(center: c.at(0, 0, 14), width: 9, height: 4),
      c.fill(const Color(0xFF6DAF5A)));
  final top = c.at(0, 0, 36);
  final pulse = .5 + .5 * sin(c.time * 1.6 + c.phase);
  c.cv.drawCircle(
      top, 11, c.fill(Color.fromRGBO(190, 255, 190, .16 + .12 * pulse)));
  c.cv.drawCircle(top, 5, c.fill(const Color(0xFFCFF5B8)));
  c.cv.drawCircle(top, 5, c.stroke(const Color(0xFF7FBF6A), 1));
}

/// Montanha: dois ou três picos de rocha com luz e sombra, encostas com veios, pé verde com
/// arbustos e neve irregular no topo. Altura e forma mudam por objeto, então várias juntas
/// formam uma cordilheira. Serve para qualquer sistema.
void _mountain(PropContext c) {
  final h = 58.0 + (c.hs % 5) * 10;
  final w = 34.0 + (c.hs % 3) * 5;
  final base = c.o.translate(0, 8);
  c.cv.drawOval(Rect.fromCenter(center: base.translate(6, 2), width: w * 2.4, height: w * .7),
      c.fill(const Color.fromRGBO(0, 0, 0, .13)));
  const light = Color(0xFFA39C8F), dark = Color(0xFF6E685F), ink = Color(0xFF4A453E);
  void peak(Offset foot, double ph, double pw, double lean) {
    final top = foot.translate(lean, -ph);
    final mid = foot.translate(lean * .3 + 2, 4);
    final left = Path()
      ..moveTo(foot.dx - pw, foot.dy)
      ..lineTo(foot.dx - pw * .45, foot.dy - ph * .45)
      ..lineTo(top.dx, top.dy)
      ..lineTo(mid.dx, mid.dy)
      ..close();
    final right = Path()
      ..moveTo(foot.dx + pw, foot.dy)
      ..lineTo(foot.dx + pw * .5, foot.dy - ph * .4)
      ..lineTo(top.dx, top.dy)
      ..lineTo(mid.dx, mid.dy)
      ..close();
    final rect = Rect.fromLTRB(foot.dx - pw, top.dy, foot.dx + pw, foot.dy);
    c.cv.drawPath(left, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [shade(light, .06), light]).createShader(rect));
    c.cv.drawPath(right, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [shade(dark, .04), shade(dark, -.05)]).createShader(rect));
    // veios da rocha
    final vein = c.stroke(shade(dark, -.12), .8);
    for (var k = 1; k <= 3; k++) {
      final f = k / 4;
      final a = Offset.lerp(top, foot.translate(-pw * .7, 0), f)!;
      c.cv.drawLine(a, a.translate(6, 7), vein);
      final b2 = Offset.lerp(top, foot.translate(pw * .7, 0), f)!;
      c.cv.drawLine(b2, b2.translate(-5, 8), vein);
    }
    // neve recortada
    final sn = ph * .3;
    final snow = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(top.dx - pw * .3, top.dy + sn)
      ..lineTo(top.dx - pw * .16, top.dy + sn * .72)
      ..lineTo(top.dx - pw * .05, top.dy + sn * 1.05)
      ..lineTo(top.dx + pw * .08, top.dy + sn * .7)
      ..lineTo(top.dx + pw * .2, top.dy + sn * .95)
      ..lineTo(top.dx + pw * .28, top.dy + sn * .78)
      ..close();
    c.cv.drawPath(snow, c.fill(const Color(0xFFF7F9FA)));
    c.cv.drawLine(top, top.translate(pw * .22, sn * .82), c.stroke(const Color(0xFFD6DEE4), 1));
    c.cv.drawPath(left, c.stroke(ink, 1));
    c.cv.drawPath(right, c.stroke(ink, 1));
  }

  // picos de trás (menores) e o da frente
  if (c.hs % 3 != 0) peak(base.translate(-w * .55, -6), h * .62, w * .62, 3);
  if (c.hs % 2 == 0) peak(base.translate(w * .6, -5), h * .55, w * .55, -2);
  peak(base, h, w, (c.hs % 7 - 3) * 1.5);
  // pé verde com arbustos
  final foot = Path()
    ..moveTo(base.dx - w * 1.05, base.dy)
    ..quadraticBezierTo(base.dx - w * .4, base.dy - h * .2, base.dx, base.dy - h * .12)
    ..quadraticBezierTo(base.dx + w * .5, base.dy - h * .22, base.dx + w * 1.05, base.dy)
    ..quadraticBezierTo(base.dx, base.dy + 8, base.dx - w * 1.05, base.dy)
    ..close();
  c.cv.drawPath(foot, c.fill(const Color(0xFF6E9A55)));
  c.cv.drawPath(foot, c.stroke(const Color(0xFF4E7A3A), .9));
  for (final (dx, dy) in const [(-.6, -.06), (-.2, -.1), (.35, -.08), (.7, -.03)]) {
    c.cv.drawCircle(base.translate(dx * w, dy * h), 3.2, c.fill(const Color(0xFF4F8A45)));
  }
}

/// Ilhota flutuante: rocha pontuda por baixo, gramado e uma árvore, balançando devagar.
void _skyIsle(PropContext c) {
  final bob = sin(c.time * .6 + c.phase) * 3;
  final o = c.o.translate(0, -26 + bob);
  final s = .8 + (c.hs % 3) * .2;
  c.cv.drawOval(Rect.fromCenter(center: c.o.translate(0, 18), width: 30 * s, height: 10 * s),
      c.fill(const Color.fromRGBO(40, 60, 80, .12)));
  final rock = Path()
    ..moveTo(o.dx - 18 * s, o.dy)
    ..lineTo(o.dx + 18 * s, o.dy)
    ..lineTo(o.dx + 6 * s, o.dy + 14 * s)
    ..lineTo(o.dx + 1, o.dy + 30 * s)
    ..lineTo(o.dx - 7 * s, o.dy + 12 * s)
    ..close();
  c.cv.drawPath(rock, c.fill(const Color(0xFF8C7A66)));
  c.cv.drawPath(rock, c.stroke(const Color(0xFF5A4C3E), 1));
  c.cv.drawOval(Rect.fromCenter(center: o, width: 38 * s, height: 13 * s),
      c.fill(const Color(0xFF7FB35E)));
  c.cv.drawOval(Rect.fromCenter(center: o, width: 38 * s, height: 13 * s),
      c.stroke(const Color(0xFF4E7A3A), 1));
  final trunk = o.translate(3, -2);
  c.cv.drawLine(trunk, trunk.translate(0, -10 * s), c.stroke(const Color(0xFF6B4A33), 2));
  c.cv.drawCircle(trunk.translate(0, -15 * s), 8 * s, c.fill(const Color(0xFF5DA05E)));
  c.cv.drawCircle(trunk.translate(-2, -17 * s), 5 * s, c.fill(const Color(0xFF79B86A)));
}

/// Rocha vermelha do deserto: coluna de arenito em camadas, alta e de topo irregular. Várias
/// juntas formam as mesas e pilares em volta de Smokestone.
void _mesa(PropContext c) {
  const rock = Color(0xFFB0674A);
  final h = 46.0 + (c.hs % 6) * 11;
  c.box(-.5, -.5, 1, 1, 0, h, rock);
  final line = c.stroke(const Color(0xFF7A4532), .9);
  for (var z = 9.0; z < h - 4; z += 9 + (c.hs % 3).toDouble()) {
    c.cv.drawLine(c.at(-.5, .5, z), c.at(.5, .5, z), line);
    c.cv.drawLine(c.at(.5, .5, z), c.at(.5, -.5, z), line);
  }
  // topo com mato seco
  final top = c.at(0, 0, h);
  c.cv.drawCircle(top.translate(-4, -1), 2.2, c.fill(const Color(0xFF9A8A4A)));
  c.cv.drawCircle(top.translate(5, 1), 1.8, c.fill(const Color(0xFF8A7A3E)));
}

/// Flor gigante: caule curvo, folhas e corola de cor fora do comum (muda por objeto).
void _giantFlower(PropContext c) {
  const petals = [
    Color(0xFFE85D9A), Color(0xFF8F6BE8), Color(0xFFF2B43C), Color(0xFF4FC3C9),
    Color(0xFFF26B4A),
  ];
  final col = petals[c.hs % petals.length];
  final h = 30.0 + (c.hs % 4) * 7;
  final sway = sin(c.time * 1.2 + c.phase) * 2;
  c.shadowOval(c.o, 16, 7);
  final top = c.o.translate(sway + (c.hs % 3 - 1) * 4, -h);
  final stem = Path()
    ..moveTo(c.o.dx, c.o.dy)
    ..quadraticBezierTo(c.o.dx - 6, c.o.dy - h * .5, top.dx, top.dy);
  c.cv.drawPath(stem, c.stroke(const Color(0xFF3F8F48), 2.4));
  c.cv.drawOval(Rect.fromCenter(center: c.o.translate(-5, -h * .35), width: 10, height: 4),
      c.fill(const Color(0xFF5DB36B)));
  for (var i = 0; i < 6; i++) {
    final a = i * pi / 3 + c.phase;
    c.cv.drawOval(
        Rect.fromCenter(
            center: top.translate(cos(a) * 6, sin(a) * 4), width: 10, height: 7),
        c.fill(col));
  }
  c.cv.drawCircle(top, 3.4, c.fill(const Color(0xFFFFE27A)));
}

/// Luz de fada: orbe que flutua, pisca e muda de cor devagar.
void _fairyLight(PropContext c) {
  final t = c.time * .8 + c.phase;
  final p = c.o.translate(sin(t * 1.3) * 6, -24 + sin(t * 2.1) * 6);
  final hue = (c.hs * 47 + c.time * 30) % 360;
  final col = HSVColor.fromAHSV(1, hue, .45, 1).toColor();
  final pulse = .5 + .5 * sin(t * 3);
  c.cv.drawCircle(p, 10, c.fill(col.withValues(alpha: .18 + .12 * pulse)));
  c.cv.drawCircle(p, 3.2, c.fill(col));
  c.cv.drawCircle(p, 1.4, c.fill(const Color(0xFFFFFFFF)));
}

/// O Eclipse: orbe negro sobre um pedestal de concreto, com um anel de luz que pulsa.
void _eclipse(PropContext c) {
  c.shadowOval(c.o, 30, 12);
  c.box(-.3, -.3, .6, .6, 0, 6, const Color(0xFFB8BBBC));
  final center = c.at(0, 0, 26);
  final pulse = .5 + .5 * sin(c.time * 1.4);
  c.cv.drawOval(Rect.fromCenter(center: center, width: 46, height: 14),
      c.fill(Color.fromRGBO(255, 214, 140, .18 + .2 * pulse)));
  c.cv.drawCircle(center, 15, c.fill(const Color(0xFF14161A)));
  c.cv.drawCircle(center.translate(-5, -5), 4, c.fill(const Color(0xFF3A3F48)));
  c.cv.drawOval(Rect.fromCenter(center: center, width: 40, height: 10),
      c.stroke(Color.fromRGBO(255, 226, 160, .6 + .4 * pulse), 1.6));
}

/// Ruína: pedaço de muro de pedra quebrado, com o topo irregular e pedras caídas ao lado.
void _ruin(PropContext c) {
  c.shadowOval(c.o, 30, 12);
  const stone = Color(0xFFA9A395);
  final h = 10.0 + (c.hs % 4) * 5;
  final along = c.hs.isEven;
  if (along) {
    c.box(-.42, -.08, .3, .16, 0, h, stone);
    c.box(-.1, -.08, .26, .16, 0, h * .55, shade(stone, -.04));
    c.box(.18, -.08, .2, .16, 0, h * .3, stone);
  } else {
    c.box(-.08, -.42, .16, .3, 0, h, stone);
    c.box(-.08, -.1, .16, .26, 0, h * .55, shade(stone, -.04));
  }
  for (final (dx, dy) in const [(.25, .3), (-.3, .25), (.1, -.35)]) {
    c.box(dx - .06, dy - .06, .12, .12, 0, 3, shade(stone, -.08));
  }
  final moss = c.fill(const Color(0xFF6E9A55));
  c.cv.drawCircle(c.at(-.3, 0, h).translate(2, 1), 2.4, moss);
}
