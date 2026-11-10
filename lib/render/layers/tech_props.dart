import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../draw_helpers.dart';
import 'building_kit.dart' show cylinder, cone;
import 'prop_renderer.dart';

/// Objetos tecnológicos: robôs, postes de energia, antenas, carros, drones...
final Map<PropType, PropDrawer> techDrawers = {
  PropType.robot: _robot,
  PropType.powerPole: _powerPole,
  PropType.dish: _dish,
  PropType.waterTower: _waterTower,
  PropType.car: _car,
  PropType.drone: _drone,
  PropType.vending: _vending,
};

/// Gyrobot: corpo redondo, olho que varre e pernas finas, meio enferrujado.
void _robot(PropContext c) {
  final w = c.wander(.12, .3);
  final base = c.at(w.dx, w.dy);
  c.shadowOval(base, 30, 14);
  const metal = Color(0xFFB9C0C4), rust = Color(0xFFB5654F);
  final step = sin(c.time * 2 + c.phase) * 2;
  for (final dx in [-7.0, 0.0, 7.0]) {
    final foot = base.translate(dx + (dx == 0 ? -step : step) * .3, 0);
    c.cv.drawLine(foot.translate(dx * .2, -13), foot,
        c.stroke(const Color(0xFF6A727B), 2));
  }
  final body = base.translate(0, -24);
  c.cv.drawOval(
      Rect.fromCenter(center: body, width: 30, height: 26), c.fill(metal));
  c.cv.drawOval(Rect.fromCenter(center: body, width: 30, height: 26),
      c.stroke(const Color(0xFF6A727B), 1.4));
  c.cv.drawOval(
      Rect.fromCenter(center: body.translate(-6, 5), width: 9, height: 6),
      c.fill(rust));
  c.cv.drawArc(Rect.fromCenter(center: body, width: 22, height: 18), pi * 1.15,
      pi * .7, false, c.stroke(const Color(0xFFE5EAEC), 2));
  final eye = body.translate(sin(c.time * 1.2 + c.phase) * 4, -1);
  c.cv.drawCircle(eye, 5, c.fill(const Color(0xFF2B3138)));
  final glow = .6 + .4 * sin(c.time * 3);
  c.cv.drawCircle(eye, 2.4, c.fill(Color.fromRGBO(255, 120, 60, glow)));
  c.cv.drawLine(body.translate(0, -13), body.translate(0, -19),
      c.stroke(const Color(0xFF6A727B), 1.4));
  c.cv.drawCircle(body.translate(0, -20), 1.8, c.fill(const Color(0xFFE8504A)));
}

void _powerPole(PropContext c) {
  c.shadowOval(c.o, 12, 6);
  const wood = Color(0xFF7A5A40);
  c.cv.drawLine(c.o, c.o.translate(0, -62), c.stroke(wood, 3.6));
  for (final (z, half) in [(54.0, 15.0), (44.0, 11.0)]) {
    c.cv.drawLine(c.o.translate(-half, -z), c.o.translate(half, -z + half * .5),
        c.stroke(wood, 2.4));
    for (final s in [-1, 1]) {
      c.cv.drawCircle(c.o.translate(s * half, -z + (s > 0 ? half * .5 : 0) - 2),
          1.6, c.fill(const Color(0xFFD9E3E8)));
    }
  }
  // fios caindo em curva pelas pontas
  final wire = c.stroke(const Color(0xFF3B4048), 1);
  for (final dy in [0.0, 10.0]) {
    final a = c.o.translate(-15 + dy * .3, -54 + dy),
        b = c.o.translate(-44, -40 + dy);
    c.cv.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(
              (a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + 8, b.dx, b.dy),
        wire);
    final a2 = c.o.translate(15 - dy * .3, -46 + dy),
        b2 = c.o.translate(44, -34 + dy);
    c.cv.drawPath(
        Path()
          ..moveTo(a2.dx, a2.dy)
          ..quadraticBezierTo(
              (a2.dx + b2.dx) / 2, (a2.dy + b2.dy) / 2 + 8, b2.dx, b2.dy),
        wire);
  }
}

void _dish(PropContext c) {
  c.shadowOval(c.o, 24, 11);
  cylinder(c.cv, c.cx, c.cy, .12, 0, 14, const Color(0xFF9AA3AD));
  final a = sin(c.time * .5 + c.phase);
  final center = c.o.translate(0, -26);
  final r = Rect.fromCenter(
      center: center, width: 30 * (.55 + .45 * a.abs()), height: 22);
  c.cv.drawOval(r, c.fill(const Color(0xFFEFF2F3)));
  c.cv.drawOval(r, c.stroke(const Color(0xFF8D9AA3), 1.4));
  c.cv.drawOval(r.deflate(4), c.fill(const Color(0xFFD0D8DC)));
  c.cv.drawLine(center, center.translate(a * 8, -12),
      c.stroke(const Color(0xFF6A727B), 1.4));
  c.cv.drawCircle(
      center.translate(a * 8, -12), 1.8, c.fill(const Color(0xFFE8504A)));
}

void _waterTower(PropContext c) {
  c.shadowOval(c.o, 36, 17);
  const leg = Color(0xFF6A727B);
  for (final (dx, dy) in [(-.3, -.3), (.3, -.3), (-.3, .3), (.3, .3)]) {
    c.cv.drawLine(c.at(dx, dy), c.at(dx * .6, dy * .6, 46), c.stroke(leg, 2.2));
  }
  c.cv.drawLine(c.at(-.3, .3, 14), c.at(.3, -.3, 30), c.stroke(leg, 1));
  c.cv.drawLine(c.at(.3, .3, 14), c.at(-.3, -.3, 30), c.stroke(leg, 1));
  cylinder(c.cv, c.cx, c.cy, .4, 46, 70, const Color(0xFFA8B7C2));
  cone(c.cv, c.cx, c.cy, .46, 70, 12, const Color(0xFF7A8A96));
  c.cv.drawLine(
      c.at(0, .4, 52), c.at(0, .4, 64), c.stroke(const Color(0xFF6E7A84), 1));
}

void _car(PropContext c) {
  c.shadowOval(c.o, 50, 22);
  const colors = [
    Color(0xFFD94B4B),
    Color(0xFF4F8FD9),
    Color(0xFFE6C34A),
    Color(0xFF59B889),
    Color(0xFFB9BFC4),
    Color(0xFFC96B3A)
  ];
  final col = colors[c.hs % colors.length];
  const len = .62, wid = .3;
  for (final (dx, dy) in [(-.2, -.15), (.14, -.15), (-.2, .13), (.14, .13)]) {
    c.box(dx, dy, .12, .05, 0, 6, const Color(0xFF2E3238));
  }
  c.box(-len / 2, -wid / 2, len, wid, 4, 12, col);
  c.box(-.18, -.12, .34, .24, 12, 20, const Color(0xFF9DD3E8));
  c.box(-.2, -.13, .38, .26, 18, 21, shade(col, .05));
  c.cv.drawCircle(c.at(len / 2, -.08, 8), 1.6, c.fill(const Color(0xFFFFE9A0)));
}

void _drone(PropContext c) {
  final bob = sin(c.time * 2.4 + c.phase) * 3;
  final shadowC = c.o.translate(0, 2);
  c.cv.drawOval(
      Rect.fromCenter(center: shadowC, width: 22 - bob, height: 10), c.shadow);
  final body = c.o.translate(0, -38 + bob);
  c.cv.drawOval(Rect.fromCenter(center: body, width: 18, height: 10),
      c.fill(const Color(0xFF3A4452)));
  c.cv.drawOval(Rect.fromCenter(center: body, width: 18, height: 10),
      c.stroke(const Color(0xFF8CA0B8), 1));
  for (final dx in [-12.0, 12.0]) {
    final rot = body.translate(dx, -3);
    final spin = (c.time * 40 + dx).floor().isEven ? 1.0 : .85;
    c.cv.drawOval(Rect.fromCenter(center: rot, width: 15 * spin, height: 4),
        c.fill(const Color(0x88CFE3F2)));
    c.cv.drawLine(body.translate(dx * .4, -1), rot,
        c.stroke(const Color(0xFF5A6678), 1.2));
  }
  final glow = .5 + .5 * sin(c.time * 5 + c.phase);
  c.cv.drawCircle(body.translate(0, 3), 6,
      c.fill(Color.fromRGBO(67, 224, 255, .15 * glow)));
  c.cv.drawCircle(body.translate(0, 3), 2, c.fill(const Color(0xFF43E0FF)));
}

void _vending(PropContext c) {
  c.shadowOval(c.o, 22, 11);
  final col =
      const [Color(0xFFE8504A), Color(0xFF43A3E8), Color(0xFFE8B84A)][c.hs % 3];
  c.box(-.16, -.14, .32, .28, 0, 34, shade(col, -.1));
  final glow = .7 + .3 * sin(c.time * 6 + c.phase);
  final panel = Path()
    ..moveTo(c.at(-.14, .14, 6).dx, c.at(-.14, .14, 6).dy)
    ..lineTo(c.at(.16, .14, 6).dx, c.at(.16, .14, 6).dy)
    ..lineTo(c.at(.16, .14, 28).dx, c.at(.16, .14, 28).dy)
    ..lineTo(c.at(-.14, .14, 28).dx, c.at(-.14, .14, 28).dy)
    ..close();
  c.cv.drawPath(
      panel, Paint()..color = const Color(0xFFFFF3C4).withValues(alpha: glow));
  c.cv.drawPath(panel, c.stroke(const Color(0xFF3A4452), 1));
  c.cv.drawCircle(
      c.at(0, .15, 18), 14, c.fill(Color.fromRGBO(255, 230, 150, .10 * glow)));
}
