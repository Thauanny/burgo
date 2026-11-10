import 'dart:math';
import 'dart:ui';
import '../../domain/city_types.dart';
import '../draw_helpers.dart';
import 'prop_renderer.dart';

/// Objetos de fazenda, água e deserto: espantalho, cacto, doca, barco, aeronave, trator.
final Map<PropType, PropDrawer> farmDrawers = {
  PropType.scarecrow: _scarecrow,
  PropType.cactus: _cactus,
  PropType.dock: _dock,
  PropType.boat: _boat,
  PropType.airship: _airship,
  PropType.freighter: _freighter,
  PropType.tractor: _tractor,
};

void _scarecrow(PropContext c) {
  c.shadowOval(c.o, 16, 8);
  const wood = Color(0xFF7A5638);
  final base = c.o;
  c.cv.drawLine(base, base.translate(0, -30), c.stroke(wood, 2.4));
  c.cv.drawLine(
      base.translate(-11, -22), base.translate(11, -22), c.stroke(wood, 2.2));
  final sway = sin(c.time * 1.5 + c.phase) * 1.5;
  final shirt = Path()
    ..moveTo(base.dx - 7, base.dy - 25)
    ..lineTo(base.dx + 7, base.dy - 25)
    ..lineTo(base.dx + 5 + sway, base.dy - 12)
    ..lineTo(base.dx - 5 + sway, base.dy - 12)
    ..close();
  c.cv.drawPath(shirt, c.fill(const Color(0xFFC8573F)));
  c.cv.drawPath(shirt, c.stroke(const Color(0xFF8E3F2E), 1));
  c.cv.drawCircle(base.translate(0, -32), 5, c.fill(const Color(0xFFE9D9A8)));
  final hat = Path()
    ..moveTo(base.dx - 8, base.dy - 35)
    ..lineTo(base.dx + 8, base.dy - 35)
    ..lineTo(base.dx + 4, base.dy - 43)
    ..lineTo(base.dx - 4, base.dy - 43)
    ..close();
  c.cv.drawPath(hat, c.fill(const Color(0xFF6B4A33)));
  c.cv.drawLine(base.translate(-11, -22), base.translate(-13, -16 + sway),
      c.stroke(const Color(0xFFE2C46A), 1.2));
  c.cv.drawLine(base.translate(11, -22), base.translate(13, -16 - sway),
      c.stroke(const Color(0xFFE2C46A), 1.2));
}

void _cactus(PropContext c) {
  c.shadowOval(c.o, 20, 9);
  const green = Color(0xFF6FAE6A);
  final b = c.o;
  final trunk = RRect.fromRectAndRadius(
      Rect.fromLTRB(b.dx - 4, b.dy - 26, b.dx + 4, b.dy),
      const Radius.circular(4));
  c.cv.drawRRect(trunk, c.fill(green));
  c.cv.drawRRect(trunk, c.stroke(const Color(0xFF3F7A45)));
  for (final s in [-1, 1]) {
    final armY = b.dy - (s < 0 ? 12 : 17);
    final arm = Path()
      ..moveTo(b.dx + s * 4, armY)
      ..lineTo(b.dx + s * 10, armY)
      ..lineTo(b.dx + s * 10, armY - 9);
    c.cv.drawPath(arm, c.stroke(green, 5));
  }
  c.cv.drawLine(b.translate(-1, -22), b.translate(-1, -6),
      c.stroke(const Color(0xFF8DC689), 1));
  if (c.hs % 3 == 0) {
    c.cv.drawCircle(b.translate(0, -27), 2, c.fill(const Color(0xFFF2A0BC)));
  }
}

void _dock(PropContext c) {
  const wood = Color(0xFF9A7650);
  final top = c.topFace(-.5, -.5, 1, 1, 3);
  c.cv.drawPath(c.topFace(-.5, -.5, 1, 1, 0), c.fill(const Color(0x33000000)));
  c.box(-.5, -.5, 1, 1, 0, 3, wood);
  c.cv.drawPath(top, c.stroke(const Color(0xFF5E4630), 1));
  for (var u = -.3; u < .5; u += .25) {
    c.cv.drawLine(
        c.at(u, -.5, 3), c.at(u, .5, 3), c.stroke(const Color(0xFF6B5238), 1));
  }
  for (final (dx, dy) in const [(-.45, .45), (.45, .45), (.45, -.45)]) {
    c.cv.drawLine(c.at(dx, dy, 3), c.at(dx, dy, 14),
        c.stroke(const Color(0xFF5A4636), 2.4));
  }
}

void _boat(PropContext c) {
  final bob = sin(c.time * 1.6 + c.phase) * 1.8;
  final o = c.o.translate(0, bob);
  c.cv.drawOval(
      Rect.fromCenter(center: c.o.translate(0, 3), width: 46, height: 18),
      c.fill(const Color(0x331A4A5A)));
  const wood = Color(0xFF9A6B45);
  final hull = Path()
    ..moveTo(o.dx - 22, o.dy - 6)
    ..quadraticBezierTo(o.dx - 16, o.dy + 6, o.dx, o.dy + 6)
    ..quadraticBezierTo(o.dx + 16, o.dy + 6, o.dx + 22, o.dy - 6)
    ..close();
  c.cv.drawPath(hull, c.fill(wood));
  c.cv.drawPath(hull, c.stroke(const Color(0xFF5A3F28), 1.4));
  c.cv.drawLine(o.translate(0, -6), o.translate(0, -34),
      c.stroke(const Color(0xFF6B4A33), 2));
  final sail = Path()
    ..moveTo(o.dx + 1, o.dy - 33)
    ..quadraticBezierTo(o.dx + 16 + sin(c.time * 2 + c.phase) * 1.5, o.dy - 20,
        o.dx + 1, o.dy - 8)
    ..close();
  c.cv.drawPath(sail, c.fill(const Color(0xFFF4EEDC)));
  c.cv.drawPath(sail, c.stroke(const Color(0xFFB9AF92), 1));
}

/// Vintagenave de Arton: casco de madeira com balão, flutuando e balançando.
void _airship(PropContext c) {
  final bob = sin(c.time * .9 + c.phase) * 3;
  final base = c.o.translate(0, -34 + bob);
  c.cv.drawOval(
      Rect.fromCenter(center: c.o.translate(0, 4), width: 40, height: 16),
      c.shadow);
  final balloon =
      Rect.fromCenter(center: base.translate(0, -16), width: 50, height: 28);
  c.cv.drawOval(balloon, c.fill(const Color(0xFFE9C9A0)));
  c.cv.drawOval(balloon, c.stroke(const Color(0xFF8A6B4C), 1.2));
  for (var i = -2; i <= 2; i++) {
    c.cv.drawLine(
        balloon.center.translate(i * 8.0, -13),
        balloon.center.translate(i * 4.0, 13),
        c.stroke(const Color(0xFFB98D5A), 1));
  }
  c.cv.drawLine(base.translate(-12, -6), base.translate(-9, 3),
      c.stroke(const Color(0xFF6B4A33), 1));
  c.cv.drawLine(base.translate(12, -6), base.translate(9, 3),
      c.stroke(const Color(0xFF6B4A33), 1));
  final hull = Path()
    ..moveTo(base.dx - 14, base.dy + 2)
    ..lineTo(base.dx + 14, base.dy + 2)
    ..lineTo(base.dx + 9, base.dy + 10)
    ..lineTo(base.dx - 9, base.dy + 10)
    ..close();
  c.cv.drawPath(hull, c.fill(const Color(0xFF8A5E3C)));
  c.cv.drawPath(hull, c.stroke(const Color(0xFF4F3623), 1.2));
  final fin = base.translate(15, 6);
  final spin = sin(c.time * 14) * 3;
  c.cv.drawLine(fin.translate(0, -3 - spin), fin.translate(0, 3 + spin),
      c.stroke(const Color(0xFF6B4A33), 1.6));
}

/// Cargueiro flutuante dos anos 80 alternativos (como na arte de Simon Stålenhag): casco
/// cinza e comprido, ponte de comando, contêineres empilhados e propulsores azuis, pairando
/// devagar sobre o campo.
void _freighter(PropContext c) {
  final bob = sin(c.time * .7 + c.phase) * 3;
  final z = 42 + bob;
  const hull = Color(0xFFB9C0C4);
  // sombra grande no chão
  c.cv.drawOval(
      Rect.fromCenter(center: c.o.translate(0, 6), width: 84, height: 30),
      Paint()..color = const Color.fromRGBO(0, 0, 0, .16));
  // brilho dos propulsores no chão
  c.cv.drawOval(
      Rect.fromCenter(center: c.o.translate(0, 4), width: 40, height: 14),
      Paint()..color = const Color.fromRGBO(120, 200, 255, .14));
  // casco, faixa e ponte de comando
  c.box(-.72, -.3, 1.44, .6, z, z + 11, hull);
  c.box(-.72, -.3, 1.44, .6, z + 3, z + 5, const Color(0xFF8E4A3A));
  c.box(-.72, -.24, .42, .48, z + 11, z + 22, const Color(0xFF8FA0AA));
  final win = c.at(-.52, .24, z + 17);
  c.cv.drawRect(Rect.fromCenter(center: win, width: 11, height: 4),
      Paint()..color = const Color(0xFFFFE08A));
  // contêineres
  const boxes = [Color(0xFFB4553A), Color(0xFFD9A441), Color(0xFF3F8F8A)];
  for (var i = 0; i < 3; i++) {
    c.box(-.22 + i * .3, -.22, .27, .44, z + 11, z + 21, boxes[i]);
  }
  // propulsores com brilho azul que pulsa
  final glow = .55 + .25 * sin(c.time * 5 + c.phase);
  for (final dx in [-.5, .5]) {
    final p = c.at(dx, 0, z - 2);
    c.cv.drawCircle(p.translate(0, 3), 11,
        Paint()..color = Color.fromRGBO(110, 190, 255, .22 * glow));
    c.cv.drawCircle(p.translate(0, 2), 4.5,
        Paint()..color = Color.fromRGBO(190, 230, 255, glow));
  }
  // luzes de posição
  c.cv.drawCircle(c.at(.72, -.3, z + 6), 1.6,
      Paint()..color = const Color(0xFFFF5A4A));
  c.cv.drawCircle(c.at(.72, .3, z + 6), 1.6,
      Paint()..color = const Color(0xFF7CFF8A));
}

void _tractor(PropContext c) {
  c.shadowOval(c.o, 44, 20);
  const body = Color(0xFF4F8A4F);
  c.box(-.22, -.14, .46, .28, 6, 14, body);
  c.box(-.2, -.12, .22, .24, 14, 24, shade(body, .05));
  c.box(-.2, -.12, .22, .24, 22, 24, const Color(0xFF2E3A2E));
  for (final (dx, dy, r) in const [(-.18, .16, 9.0), (.2, .14, 6.0)]) {
    final p = c.at(dx, dy, r);
    c.cv.drawCircle(p, r, c.fill(const Color(0xFF2B2B2B)));
    c.cv.drawCircle(p, r * .45, c.fill(const Color(0xFFC9B24A)));
  }
  final pipe = c.at(.18, 0, 14);
  c.cv.drawLine(
      pipe, pipe.translate(0, -8), c.stroke(const Color(0xFF444444), 2));
  final puff = (c.time * 1.2 + c.phase) % 1;
  c.cv.drawCircle(pipe.translate(sin(puff * 6) * 2, -10 - puff * 10),
      2 + puff * 3, c.fill(Color.fromRGBO(200, 200, 200, (1 - puff) * .5)));
}
