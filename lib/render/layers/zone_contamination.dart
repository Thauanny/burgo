import 'dart:math';
import 'dart:ui';

import '../../domain/city_types.dart';
import '../../systems/art_profile.dart';
import '../draw_helpers.dart';
import 'prop_renderer.dart';

/// Árvores, arbustos e flores (o que a área especial "contamina" na vegetação).
const _plants = {
  PropType.tree,
  PropType.pine,
  PropType.sakura,
  PropType.bush,
  PropType.giantFlower,
};

/// Animais (o que a área especial contamina na fauna).
const _animals = {
  PropType.cow,
  PropType.sheep,
  PropType.chicken,
  PropType.dog,
  PropType.horse,
};

/// O objeto muda dentro da área especial deste efeito?
bool isContaminable(PropType t, ZoneEffect e) =>
    (e == ZoneEffect.stormRift ||
        e == ZoneEffect.loopField ||
        e == ZoneEffect.wildMotes) &&
    (_plants.contains(t) || _animals.contains(t));

/// Desenha o objeto do jeito da área especial em que ele está:
/// - **Tormenta** (stormRift): árvores mortas e retorcidas, de galhos nus e veios vermelhos;
///   animais meio mortos-vivos (pele cinza-esverdeada, olhos vermelhos, brasas rubras).
/// - **Loop** (loopField): árvores energizadas, com faíscas azuis e pegando fogo no alto; os
///   animais morrem (carcaça caída, fumaça).
/// - **D&D** (wildMotes, magia selvagem / travessia feérica): plantas tingidas de violeta e
///   turquesa, brilhando, com faíscas de magia; animais tocados pelas fadas, flutuando
///   num halo de luz.
void paintContaminated(PropContext c, PropType type, ZoneEffect effect, PropDrawer normal) {
  final plant = _plants.contains(type);
  switch (effect) {
    case ZoneEffect.stormRift:
      plant ? _deadTree(c, type) : _undead(c, normal);
    case ZoneEffect.loopField:
      plant ? _energized(c, normal) : _carcass(c, type);
    case ZoneEffect.wildMotes:
      plant ? _feyPlant(c, normal) : _feyAnimal(c, normal);
    default:
      normal(c);
  }
}

Rect _area(PropContext c) => Rect.fromCenter(center: c.o.translate(0, -26), width: 110, height: 110);

ColorFilter _matrix(double sat, double r, double g, double b) {
  final s = sat, i = 1 - s;
  const lr = .2126, lg = .7152, lb = .0722;
  return ColorFilter.matrix([
    (i * lr + s) * r, i * lg * r, i * lb * r, 0, 0,
    i * lr * g, (i * lg + s) * g, i * lb * g, 0, 0,
    i * lr * b, i * lg * b, (i * lb + s) * b, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

// ---------------------------------------------------------------- Tormenta
void _deadTree(PropContext c, PropType type) {
  final cv = c.cv, o = c.o;
  c.shadowOval(o, 26, 12);
  const bark = Color(0xFF3A2C2A), vein = Color(0xFFB0202E);
  if (type == PropType.bush || type == PropType.giantFlower) {
    final p = c.stroke(bark, 1.6);
    for (var i = 0; i < 5; i++) {
      final a = -pi / 2 + (i - 2) * .45;
      cv.drawLine(o, o.translate(cos(a) * 11, sin(a) * 11 - 2), p);
    }
    cv.drawCircle(o.translate(0, -4), 1.8, c.fill(vein));
    return;
  }
  final h = 34.0 + (c.hs % 3) * 6;
  final lean = (c.hs % 5 - 2) * 1.5;
  final trunk = Path()
    ..moveTo(o.dx - 3.5, o.dy)
    ..quadraticBezierTo(o.dx - 1 + lean, o.dy - h * .5, o.dx + lean, o.dy - h)
    ..lineTo(o.dx + 1.6 + lean, o.dy - h)
    ..quadraticBezierTo(o.dx + 2 + lean, o.dy - h * .5, o.dx + 3.5, o.dy)
    ..close();
  cv.drawPath(trunk, c.fill(bark));
  // galhos nus e retorcidos
  final branch = c.stroke(bark, 1.8);
  for (final (f, dir, len) in const [(.45, -1.0, 12.0), (.6, 1.0, 14.0), (.78, -1.0, 9.0), (.9, 1.0, 8.0)]) {
    final p0 = o.translate(lean * f, -h * f);
    final p1 = p0.translate(dir * len, -len * .5);
    cv.drawLine(p0, p1, branch);
    cv.drawLine(p1, p1.translate(dir * 4, -5), c.stroke(bark, 1.1));
    cv.drawLine(p1, p1.translate(dir * 5, 2), c.stroke(bark, 1.1));
  }
  // veios rubros pulsando
  final pulse = .5 + .5 * c.osc(1);
  cv.drawLine(o.translate(0, -4), o.translate(lean * .5, -h * .6),
      c.stroke(Color.fromRGBO(220, 40, 55, .5 + .4 * pulse), 1));
  cv.drawCircle(o.translate(lean, -h), 3.5, c.fill(Color.fromRGBO(200, 30, 45, .25 + .3 * pulse)));
}

void _undead(PropContext c, PropDrawer normal) {
  final cv = c.cv;
  cv.saveLayer(_area(c), Paint()..colorFilter = _matrix(.15, .78, .95, .72));
  normal(c);
  cv.restore();
  // olhos vermelhos e brasas da Tormenta subindo
  final eye = c.o.translate(6, -16);
  final pulse = .6 + .4 * c.osc(1);
  cv.drawCircle(eye, 3.5, Paint()..color = Color.fromRGBO(255, 40, 50, .25 * pulse));
  cv.drawCircle(eye, 1.4, Paint()..color = Color.fromRGBO(255, 60, 60, pulse));
  for (var i = 0; i < 3; i++) {
    final ph = c.particle(i, 3);
    cv.drawCircle(c.o.translate(-6 + i * 6.0, -10 - ph * 22), 1.3,
        Paint()..color = Color.fromRGBO(230, 40, 50, 1 - ph));
  }
}

// ---------------------------------------------------------------- Loop
void _energized(PropContext c, PropDrawer normal) {
  final cv = c.cv;
  cv.saveLayer(_area(c), Paint()..colorFilter = _matrix(.55, .82, .86, .95));
  normal(c);
  cv.restore();
  final top = c.o.translate(0, -34);
  // chamas no alto da copa
  for (var i = 0; i < 3; i++) {
    final ph = c.particle(i, 3);
    final p = top.translate(-6 + i * 6.0 + sin(ph * 6) * 1.5, -ph * 12);
    cv.drawCircle(p, 4.2 * (1 - ph) + 1, Paint()..color = Color.fromRGBO(255, 150, 40, (1 - ph) * .85));
    cv.drawCircle(p, 2 * (1 - ph), Paint()..color = Color.fromRGBO(255, 230, 120, 1 - ph));
  }
  // arcos elétricos azuis piscando
  if (c.osc(3, c.phase) > .2) {
    final arc = Paint()
      ..color = const Color(0xFF9FE0FF)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(c.o.dx - 10, c.o.dy - 14);
    for (var k = 1; k <= 5; k++) {
      path.lineTo(c.o.dx - 10 + k * 4, c.o.dy - 14 - k * 4 + (k.isEven ? 4 : -3));
    }
    cv.drawPath(path, arc);
    cv.drawCircle(c.o.translate(10, -34), 6, Paint()..color = const Color.fromRGBO(140, 210, 255, .3));
  }
}

void _carcass(PropContext c, PropType type) {
  final cv = c.cv, o = c.o;
  c.shadowOval(o, 30, 10);
  final small = type == PropType.chicken;
  final body = small ? const Color(0xFFD8D2C6) : const Color(0xFF8E8780);
  final w = small ? 9.0 : 18.0, h = small ? 5.0 : 8.0;
  final rect = Rect.fromCenter(center: o.translate(0, -4), width: w * 2, height: h * 2);
  cv.drawOval(rect, c.fill(body));
  cv.drawOval(rect, c.stroke(shade(body, -.3), 1));
  // patas para cima
  final leg = c.stroke(shade(body, -.35), 1.6);
  for (final dx in small ? const [-2.0, 2.0] : const [-9.0, -3.0, 4.0, 10.0]) {
    cv.drawLine(o.translate(dx, -4 - h * .6), o.translate(dx + 1, -4 - h - 6), leg);
  }
  // olho em X
  final eye = o.translate(w * .8, -6);
  final x = c.stroke(const Color(0xFF2B2A33), 1);
  cv.drawLine(eye.translate(-1.5, -1.5), eye.translate(1.5, 1.5), x);
  cv.drawLine(eye.translate(-1.5, 1.5), eye.translate(1.5, -1.5), x);
  // fumaça de queimado
  for (var i = 0; i < 3; i++) {
    final ph = c.particle(i, 3);
    cv.drawCircle(o.translate(sin(ph * 5 + i) * 3, -10 - ph * 22), 3 + ph * 5,
        Paint()..color = Color.fromRGBO(90, 90, 95, (1 - ph) * .35));
  }
}

// ---------------------------------------------------------------- D&D (magia selvagem)
void _motes(PropContext c, Offset center, double spread) {
  for (var i = 0; i < 5; i++) {
    final ph = c.particle(i, 5);
    final a = i * 1.3 + c.phase;
    final p = center.translate(cos(a + ph * 2) * spread, -ph * 26 + sin(a) * 4);
    final hue = (c.hs * 31 + i * 60 + c.cycle * 360) % 360;
    final col = HSVColorLite.toColor(hue, .55, 1);
    cv(c).drawCircle(p, 4, Paint()..color = col.withValues(alpha: (1 - ph) * .25));
    cv(c).drawCircle(p, 1.4, Paint()..color = col.withValues(alpha: 1 - ph));
  }
}

Canvas cv(PropContext c) => c.cv;

void _feyPlant(PropContext c, PropDrawer normal) {
  final shift = c.hs.isEven;
  c.cv.saveLayer(_area(c),
      Paint()..colorFilter = shift ? _matrix(1.2, 1.05, .7, 1.35) : _matrix(1.1, .6, 1.05, 1.15));
  normal(c);
  c.cv.restore();
  final pulse = .5 + .5 * c.osc(1);
  c.cv.drawCircle(c.o.translate(0, -28), 22,
      Paint()..color = Color.fromRGBO(190, 140, 255, .08 + .08 * pulse));
  _motes(c, c.o.translate(0, -26), 14);
}

void _feyAnimal(PropContext c, PropDrawer normal) {
  final lift = 6 + c.osc(1) * 3;
  c.shadowOval(c.o, 26, 10);
  c.cv.save();
  c.cv.translate(0, -lift);
  c.cv.saveLayer(_area(c), Paint()..colorFilter = _matrix(1.1, .9, .85, 1.25));
  normal(c);
  c.cv.restore();
  c.cv.restore();
  c.cv.drawOval(Rect.fromCenter(center: c.o.translate(0, -10 - lift), width: 46, height: 26),
      Paint()..color = const Color.fromRGBO(200, 160, 255, .16));
  _motes(c, c.o.translate(0, -14 - lift), 12);
}

/// Conversão HSV→cor sem depender de `package:flutter/painting`.
abstract final class HSVColorLite {
  static Color toColor(double h, double s, double v) {
    final c = v * s, x = c * (1 - ((h / 60) % 2 - 1).abs()), m = v - c;
    final (r, g, b) = switch (h ~/ 60) {
      0 => (c, x, 0.0),
      1 => (x, c, 0.0),
      2 => (0.0, c, x),
      3 => (0.0, x, c),
      4 => (x, 0.0, c),
      _ => (c, 0.0, x),
    };
    return Color.fromARGB(255, ((r + m) * 255).round(), ((g + m) * 255).round(), ((b + m) * 255).round());
  }
}
